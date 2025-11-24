#!/usr/bin/env bash
# Integration Tests for Meta-Prompt Plugin
# Tests installation, file structure, and basic functionality
# For detailed unit tests, see test-*-handler.sh files

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

# ============================================================================
# Test Helper Functions
# ============================================================================
#
# SECURITY NOTE: Test Command Construction
# ----------------------------------------
# All test commands MUST be hardcoded strings defined in this file.
# NEVER construct test commands from user input or external sources.
#
# Safe patterns:
#   ✓ Hardcoded commands with variables from this script's environment
#   ✓ Commands using ${CLAUDE_PLUGIN_ROOT} for path construction
#   ✓ String literals for test data
#
# Unsafe patterns:
#   ✗ Commands built from user input or external files
#   ✗ Dynamic command construction from untrusted sources
#   ✗ Interpolation of unvalidated variables
#
# The bash -c execution method is safer than eval, but both require
# careful input validation. By restricting all commands to hardcoded
# strings in this test file, we eliminate injection risks entirely.
# ============================================================================

# Helper: Run test
# Executes test command using bash -c for safer execution than eval.
# All test commands are hardcoded in this file (no user input).
# Safe patterns: file existence checks, grep patterns, etc.
#
# Note on variable expansion: bash -c properly expands ${VARIABLES} because
# when we pass "$test_command" in double quotes, bash performs variable
# expansion before passing the string to bash -c, which then executes it.
run_test() {
    local test_name="$1"
    local test_command="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # Use bash -c instead of eval for safer command execution
    # shellcheck disable=SC2086
    if bash -c "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Helper: Run test with output check
# Executes test command using bash -c for safer execution than eval.
# All test commands are hardcoded in this file (no user input).
#
# Note on variable expansion: bash -c properly expands ${VARIABLES} because
# when we pass "$test_command" in double quotes, bash performs variable
# expansion before passing the string to bash -c, which then executes it.
run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # Use bash -c instead of eval for safer command execution
    # Capture both stdout and stderr for pattern matching
    # shellcheck disable=SC2086
    local command_output=$(bash -c "$test_command" 2>&1 || true)

    if echo "$command_output" | grep -qE "$expected_pattern"; then
        echo -e "${GREEN}✓${NC} $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name (expected: $expected_pattern)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo -e "${YELLOW}================================================${NC}"
echo -e "${YELLOW}  Meta-Prompt Integration Tests${NC}"
echo -e "${YELLOW}================================================${NC}"
echo ""

# ===== PHASE 1: File Structure Tests =====
echo -e "${YELLOW}Phase 1: File Structure${NC}"

# Core scripts
run_test "prompt-handler.sh exists and is executable" \
    "[ -x \${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh ]"

run_test "common.sh exists and is readable" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/scripts/common.sh ]"

# Agent handler scripts
run_test "prompt-optimizer-handler.sh exists and is executable" \
    "[ -x \${CLAUDE_PLUGIN_ROOT}/agents/scripts/prompt-optimizer-handler.sh ]"

run_test "template-selector-handler.sh exists and is executable" \
    "[ -x \${CLAUDE_PLUGIN_ROOT}/agents/scripts/template-selector-handler.sh ]"

run_test "template-executor-handler.sh exists and is executable" \
    "[ -x \${CLAUDE_PLUGIN_ROOT}/agents/scripts/template-executor-handler.sh ]"

# Validation scripts
run_test "validate-templates.sh exists and is executable" \
    "[ -x \${CLAUDE_PLUGIN_ROOT}/tests/validate-templates.sh ]"

run_test "verify-installation.sh exists and is executable" \
    "[ -x \${CLAUDE_PLUGIN_ROOT}/commands/scripts/verify-installation.sh ]"

echo ""

# ===== PHASE 2: Template Validation =====
echo -e "${YELLOW}Phase 2: Template Files${NC}"

# Dynamically count expected templates and verify they match validation count
# This makes the test maintainable when templates are added/removed
# EXPECTED_TEMPLATES: Update this list when adding/removing templates
EXPECTED_TEMPLATES=(
    "code-refactoring"
    "code-review"
    "test-generation"
    "documentation-generator"
    "data-extraction"
    "code-comparison"
    "custom"
)
EXPECTED_COUNT="${#EXPECTED_TEMPLATES[@]}"

run_test "Correct number of templates exist (${EXPECTED_COUNT})" \
    "[ \$(find \${CLAUDE_PLUGIN_ROOT}/templates -name '*.md' -type f ! -name 'README.md' | wc -l | tr -d ' ') -eq ${EXPECTED_COUNT} ]"

run_test_with_output "All templates pass validation" \
    "\${CLAUDE_PLUGIN_ROOT}/tests/validate-templates.sh" \
    "Passed: ${EXPECTED_COUNT}"

# Auto-generate template existence tests from EXPECTED_TEMPLATES array
# This eliminates redundancy and ensures tests stay in sync with the array
for template in "${EXPECTED_TEMPLATES[@]}"; do
    run_test "$template template exists" \
        "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/$template.md ]"
done

echo ""

# ===== PHASE 3: Agent Definitions =====
echo -e "${YELLOW}Phase 3: Agent Definition Files${NC}"

run_test "prompt-optimizer agent definition exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/agents/prompt-optimizer.md ]"

run_test "template-selector agent definition exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/agents/template-selector.md ]"

run_test "template-executor agent definition exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/agents/template-executor.md ]"

echo ""

# ===== PHASE 4: Skills =====
echo -e "${YELLOW}Phase 4: Skill Files${NC}"

run_test "code-refactoring skill exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/skills/code-refactoring/SKILL.md ]"

run_test "code-review skill exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/skills/code-review/SKILL.md ]"

run_test "test-generation skill exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/skills/test-generation/SKILL.md ]"

run_test "documentation-generator skill exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/skills/documentation-generator/SKILL.md ]"

run_test "data-extraction skill exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/skills/data-extraction/SKILL.md ]"

run_test "code-comparison skill exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/skills/code-comparison/SKILL.md ]"

echo ""

# ===== PHASE 5: Command Definitions =====
echo -e "${YELLOW}Phase 5: Command Files${NC}"

run_test "prompt command definition exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/commands/prompt.md ]"

echo ""

# ===== PHASE 6: Handler Functionality =====
echo -e "${YELLOW}Phase 6: Handler Basic Functionality${NC}"

run_test_with_output "prompt-handler handles no template (spawns selector)" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh 'Fix the bug'" \
    "NEXT_ACTION: spawn_template_selector"

run_test_with_output "prompt-handler handles --code flag" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh '--code Fix bug'" \
    "NEXT_ACTION: spawn_optimizer"

run_test_with_output "prompt-handler handles special characters (dollar/backtick)" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh 'Fix \\\$var and \`cmd\`'" \
    "<user_task>.*Fix.*var.*cmd.*</user_task>"

run_test_with_output "prompt-handler handles quotes and apostrophes" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh 'Fix \"quoted\" and '\"'\"'single'\"'\"' text'" \
    "<user_task>.*quoted.*single.*</user_task>"

run_test_with_output "prompt-handler handles XML special chars" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh 'Fix < and > and & symbols'" \
    "<user_task>.*</user_task>"

run_test_with_output "prompt-handler handles parentheses and brackets" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh 'Fix (bug) [in] {code}'" \
    "<user_task>.*bug.*in.*code.*</user_task>"

run_test_with_output "template-selector-handler classifies tasks" \
    "\${CLAUDE_PLUGIN_ROOT}/agents/scripts/template-selector-handler.sh '<template_selector_request><user_task>Refactor the code</user_task></template_selector_request>'" \
    "<selected_template>code-refactoring</selected_template>"

run_test_with_output "prompt-optimizer-handler loads templates" \
    "\${CLAUDE_PLUGIN_ROOT}/agents/scripts/prompt-optimizer-handler.sh '<prompt_optimizer_request><user_task>Fix bug</user_task><template>code-refactoring</template><execution_mode>direct</execution_mode></prompt_optimizer_request>'" \
    "^Template: code-refactoring( \\(already selected\\))?$"

run_test_with_output "template-executor-handler loads skills from new structure" \
    "\${CLAUDE_PLUGIN_ROOT}/agents/scripts/template-executor-handler.sh '<template_executor_request><skill>meta-prompt:code-review</skill><optimized_prompt>Test prompt</optimized_prompt><execution_mode>direct</execution_mode></template_executor_request>'" \
    "^Skill: meta-prompt:code-review$"

run_test_with_output "template-executor-handler rejects invalid skills" \
    "\${CLAUDE_PLUGIN_ROOT}/agents/scripts/template-executor-handler.sh '<template_executor_request><skill>meta-prompt:nonexistent-skill</skill><optimized_prompt>Test prompt</optimized_prompt><execution_mode>direct</execution_mode></template_executor_request>'" \
    "Error: Required skill.*not found"

echo ""

# ===== PHASE 7: Complex Scenario Tests =====
echo -e "${YELLOW}Phase 7: Complex Scenario Tests${NC}"

# Test template-selector with ambiguous task (should handle gracefully)
run_test_with_output "template-selector handles ambiguous task" \
    "\${CLAUDE_PLUGIN_ROOT}/agents/scripts/template-selector-handler.sh '<template_selector_request><user_task>Make the app better</user_task></template_selector_request>'" \
    "CLASSIFICATION RESULT:"

# Test template-selector with complex multi-intent task
run_test_with_output "template-selector handles complex task with multiple keywords" \
    "\${CLAUDE_PLUGIN_ROOT}/agents/scripts/template-selector-handler.sh '<template_selector_request><user_task>Refactor the authentication module and add unit tests for security</user_task></template_selector_request>'" \
    "code-refactoring|test-generation"

# Test prompt-optimizer with complex variable extraction
run_test_with_output "prompt-optimizer handles task with implicit variables" \
    "\${CLAUDE_PLUGIN_ROOT}/agents/scripts/prompt-optimizer-handler.sh '<prompt_optimizer_request><user_task>Review the payment processing code in src/payments for security vulnerabilities</user_task><template>code-review</template><execution_mode>direct</execution_mode></prompt_optimizer_request>'" \
    "Template: code-review"

# Test skills have sufficient content (tables, sections, examples)
run_test "code-refactoring skill has workflow section" \
    "grep -q '## Workflow' \${CLAUDE_PLUGIN_ROOT}/skills/code-refactoring/SKILL.md"

run_test "code-review skill has severity levels" \
    "grep -q 'CRITICAL\|HIGH\|MEDIUM' \${CLAUDE_PLUGIN_ROOT}/skills/code-review/SKILL.md"

run_test "test-generation skill has framework reference" \
    "grep -q 'Jest\|pytest\|JUnit' \${CLAUDE_PLUGIN_ROOT}/skills/test-generation/SKILL.md"

# Test model selection is correctly configured
run_test "template-selector uses haiku model" \
    "grep -q '^model: haiku' \${CLAUDE_PLUGIN_ROOT}/agents/template-selector.md"

run_test "prompt-optimizer uses sonnet model" \
    "grep -q '^model: sonnet' \${CLAUDE_PLUGIN_ROOT}/agents/prompt-optimizer.md"

run_test "template-executor uses sonnet model" \
    "grep -q '^model: sonnet' \${CLAUDE_PLUGIN_ROOT}/agents/template-executor.md"

echo ""

# ===== PHASE 8: Documentation =====
echo -e "${YELLOW}Phase 8: Documentation Files${NC}"

run_test "README.md exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/README.md ]"

echo ""

# ===== Summary =====
echo ""
echo -e "${YELLOW}=== Summary ===${NC}"
echo -e "Total tests: $TOTAL_TESTS"
if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${GREEN}All integration tests passed!${NC}"
    exit 0
else
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo ""
    echo -e "${YELLOW}Note:${NC} For detailed unit tests, run:"
    echo "  - test-template-selector-handler.sh"
    echo "  - test-prompt-optimizer-handler.sh"
    echo "  - test-prompt-handler.sh"
    exit 1
fi
