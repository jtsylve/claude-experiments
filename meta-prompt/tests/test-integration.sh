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

# Helper: Run test
# Note: Uses eval for test command execution with CONTROLLED inputs only.
# All test commands are hardcoded in this file (no user input).
# Safe patterns: file existence checks, grep patterns, etc.
run_test() {
    local test_name="$1"
    local test_command="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # shellcheck disable=SC2086
    if eval "$test_command" > /dev/null 2>&1; then
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
# Note: Uses eval for test command execution with CONTROLLED inputs only.
# All test commands are hardcoded in this file (no user input).
run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # shellcheck disable=SC2086
    local output=$(eval "$test_command" 2>&1 || true)

    if echo "$output" | grep -qE "$expected_pattern"; then
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

run_test "Correct number of templates exist (7)" \
    "[ \$(find \${CLAUDE_PLUGIN_ROOT}/templates -name '*.md' -type f ! -name 'README.md' | wc -l | tr -d ' ') -eq 7 ]"

run_test_with_output "All templates pass validation" \
    "\${CLAUDE_PLUGIN_ROOT}/tests/validate-templates.sh" \
    "Passed: 7"

run_test "code-refactoring template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/code-refactoring.md ]"

run_test "code-review template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/code-review.md ]"

run_test "test-generation template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/test-generation.md ]"

run_test "documentation-generator template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/documentation-generator.md ]"

run_test "data-extraction template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/data-extraction.md ]"

run_test "code-comparison template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/code-comparison.md ]"

run_test "custom template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/custom.md ]"

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
    "spawn_template_selector"

run_test_with_output "prompt-handler handles --code flag" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh '--code Fix bug'" \
    "code-refactoring"

run_test_with_output "prompt-handler handles special characters" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh 'Fix \\\$var and \`cmd\`'" \
    "user_task"

run_test_with_output "template-selector-handler classifies tasks" \
    "\${CLAUDE_PLUGIN_ROOT}/agents/scripts/template-selector-handler.sh '<template_selector_request><user_task>Refactor the code</user_task></template_selector_request>'" \
    "code-refactoring"

run_test_with_output "prompt-optimizer-handler loads templates" \
    "\${CLAUDE_PLUGIN_ROOT}/agents/scripts/prompt-optimizer-handler.sh '<prompt_optimizer_request><user_task>Fix bug</user_task><template>code-refactoring</template><execution_mode>direct</execution_mode></prompt_optimizer_request>'" \
    "Template: code-refactoring"

echo ""

# ===== PHASE 7: Documentation =====
echo -e "${YELLOW}Phase 7: Documentation Files${NC}"

run_test "README.md exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/README.md ]"

run_test "architecture-refactoring.md exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/docs/architecture-refactoring.md ]"

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
