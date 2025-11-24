#!/usr/bin/env bash
# Unit Tests for Prompt Handler (State Machine)
# Tests the prompt-handler.sh state machine logic
# This is the core orchestrator for the /prompt command

set -euo pipefail

# ANSI colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Setup: Set CLAUDE_PLUGIN_ROOT if not already set
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    export CLAUDE_PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

HANDLER="${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh"

# Helper: Check if output contains expected content
check_output_contains() {
    local output="$1"
    local expected_pattern="$2"
    echo "$output" | grep -q "$expected_pattern"
}

# Helper: Run test with command line args (initial state)
run_test_initial() {
    local test_name="$1"
    local task_args="$2"
    local expected_pattern="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} $test_name"

    local output=$("$HANDLER" "$task_args" 2>&1)

    if check_output_contains "$output" "$expected_pattern"; then
        echo -e "  ${GREEN}✓ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "  ${RED}✗ FAILED${NC} - Expected pattern not found: $expected_pattern"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Helper: Run test with XML input as argument
run_test_xml() {
    local test_name="$1"
    local xml_input="$2"
    local expected_pattern="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} $test_name"

    local output=$("$HANDLER" "$xml_input" 2>&1)

    if check_output_contains "$output" "$expected_pattern"; then
        echo -e "  ${GREEN}✓ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "  ${RED}✗ FAILED${NC} - Expected pattern not found: $expected_pattern"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo -e "${YELLOW}================================================${NC}"
echo -e "${YELLOW}  Prompt Handler State Machine Tests${NC}"
echo -e "${YELLOW}================================================${NC}"
echo ""

# ===== PHASE 1: Initial State - Template Auto-Selection =====
echo -e "${YELLOW}Phase 1: Initial State - Template Auto-Selection${NC}"

run_test_initial "Spawns template-selector when no template flag" \
    "Fix the bug in auth" \
    "spawn_template_selector"

run_test_initial "Includes user task in selector spawn" \
    "Fix the bug in auth" \
    "<user_task>Fix the bug in auth</user_task>"

echo ""

# ===== PHASE 2: Initial State - Explicit Template =====
echo -e "${YELLOW}Phase 2: Initial State - Explicit Template${NC}"

run_test_initial "Spawns prompt-optimizer with --code flag" \
    "--code Fix the bug" \
    "spawn_optimizer"

run_test_initial "Includes template in optimizer spawn with --code" \
    "--code Fix the bug" \
    "<template>code-refactoring</template>"

run_test_initial "Handles --review flag" \
    "--review Check the code" \
    "code-review"

run_test_initial "Handles --test flag" \
    "--test Write tests" \
    "test-generation"

run_test_initial "Handles --docs flag" \
    "--docs Document API" \
    "documentation-generator"

run_test_initial "Handles --template=custom" \
    "--template=custom Do novel task" \
    "<template>custom</template>"

echo ""

# ===== PHASE 3: Flag Handling =====
echo -e "${YELLOW}Phase 3: Flag Handling${NC}"

run_test_initial "Handles --plan flag" \
    "--code --plan Fix bug" \
    "<execution_mode>plan</execution_mode>"

run_test_initial "Handles --return-only flag" \
    "--code --return-only Fix bug" \
    "spawn_optimizer_return_only"

run_test_initial "Handles combined flags" \
    "--review --plan Check code" \
    "<execution_mode>plan</execution_mode>"

echo ""

# ===== PHASE 4: Post-Template-Selector State =====
echo -e "${YELLOW}Phase 4: Post-Template-Selector State${NC}"

run_test_xml "Processes template-selector result" \
    "<template_selector_result><selected_template>code-refactoring</selected_template><confidence>75</confidence></template_selector_result>
<original_task>Fix bug</original_task>
<plan_flag>false</plan_flag>
<return_only_flag>false</return_only_flag>" \
    "spawn_optimizer"

run_test_xml "Includes selected template in optimizer spawn" \
    "<template_selector_result><selected_template>test-generation</selected_template><confidence>80</confidence></template_selector_result>
<original_task>Write tests</original_task>
<plan_flag>false</plan_flag>
<return_only_flag>false</return_only_flag>" \
    "<template>test-generation</template>"

run_test_xml "Handles plan flag from selector" \
    "<template_selector_result><selected_template>code-review</selected_template><confidence>75</confidence></template_selector_result>
<original_task>Review code</original_task>
<plan_flag>true</plan_flag>
<return_only_flag>false</return_only_flag>" \
    "<execution_mode>plan</execution_mode>"

echo ""

# ===== PHASE 5: Post-Optimizer State =====
echo -e "${YELLOW}Phase 5: Post-Optimizer State${NC}"

run_test_xml "Spawns template-executor for direct execution" \
    "<prompt_optimizer_result><template>code-refactoring</template><skill>meta-prompt:code-refactoring</skill><execution_mode>direct</execution_mode><optimized_prompt>Test prompt</optimized_prompt></prompt_optimizer_result>" \
    "spawn_template_executor"

run_test_xml "Spawns Plan agent for plan mode" \
    "<prompt_optimizer_result><template>code-review</template><skill>meta-prompt:code-review</skill><execution_mode>plan</execution_mode><optimized_prompt>Test prompt</optimized_prompt></prompt_optimizer_result>" \
    "spawn_plan_agent"

run_test_xml "Includes skill in executor spawn" \
    "<prompt_optimizer_result><template>test-generation</template><skill>meta-prompt:test-generation</skill><execution_mode>direct</execution_mode><optimized_prompt>Test prompt</optimized_prompt></prompt_optimizer_result>" \
    "meta-prompt:test-generation"

echo ""

# ===== PHASE 6: Post-Plan State =====
echo -e "${YELLOW}Phase 6: Post-Plan State${NC}"

run_test_xml "Detects post_plan state from plan result" \
    "<plan_result><skill>meta-prompt:code-review</skill><optimized_prompt>Test prompt</optimized_prompt></plan_result>" \
    "STATE: post_plan"

run_test_xml "Spawns template-executor after Plan agent" \
    "<plan_result><skill>meta-prompt:code-review</skill><optimized_prompt>Test prompt</optimized_prompt></plan_result>" \
    "spawn_template_executor"

run_test_xml "Includes skill in executor spawn after plan" \
    "<plan_result><skill>meta-prompt:test-generation</skill><optimized_prompt>Test prompt</optimized_prompt></plan_result>" \
    "meta-prompt:test-generation"

echo ""

# ===== PHASE 7: Final State =====
echo -e "${YELLOW}Phase 7: Final State${NC}"

run_test_xml "Detects final state from executor result" \
    "<template_executor_result><status>completed</status><summary>Done</summary></template_executor_result>" \
    "NEXT_ACTION: done"

echo ""

# ===== PHASE 8: Special Characters & Edge Cases =====
echo -e "${YELLOW}Phase 8: Special Characters & Edge Cases${NC}"

run_test_initial "Handles special characters in task" \
    'Fix \$variable and `command`' \
    "user_task"

run_test_initial "Handles quotes in task" \
    "Review the \"main\" function" \
    "main"

run_test_initial "Handles apostrophes" \
    "Fix user's auth so it doesn't break" \
    "doesn't"

echo ""

# ===== PHASE 9: Error Handling & Negative Tests =====
echo -e "${YELLOW}Phase 9: Error Handling & Negative Tests${NC}"

# Test multiple template flags (should error)
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} Rejects multiple template flags"
output=$("$HANDLER" "--code --review test task" 2>&1) || true
if echo "$output" | grep -qi "Error.*template"; then
    echo -e "  ${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${RED}✗ FAILED${NC} - Should reject multiple template flags"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

echo ""

# ===== Summary =====
echo -e "${YELLOW}=== Summary ===${NC}"
echo -e "Total tests: $TOTAL_TESTS"
if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    exit 1
fi
