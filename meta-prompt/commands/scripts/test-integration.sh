#!/bin/bash
# End-to-End Integration Test Suite
# Tests all components of the optimization implementation

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

# Helper: Run test
run_test() {
    local test_name="$1"
    local test_command="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} $test_name"

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "  ${RED}✗ FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Helper: Run test with output check
run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} $test_name"

    local output=$(eval "$test_command" 2>&1)
    if echo "$output" | grep -q "$expected_pattern"; then
        echo -e "  ${GREEN}✓ PASSED${NC} (matched: $expected_pattern)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "  ${RED}✗ FAILED${NC} (expected pattern: $expected_pattern)"
        echo "  Output: $output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo -e "${YELLOW}=====================================${NC}"
echo -e "${YELLOW}  LLM Optimization Integration Tests${NC}"
echo -e "${YELLOW}=====================================${NC}"
echo ""

# ===== PHASE 1: Script Existence Tests =====
echo -e "${YELLOW}Phase 1: Script Existence${NC}"

run_test "prompt-handler.sh exists and is executable" \
    "[ -x \${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh ]"

run_test "template-selector.sh exists and is executable" \
    "[ -x \${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh ]"

run_test "template-processor.sh exists and is executable" \
    "[ -x \${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh ]"

run_test "validate-templates.sh exists and is executable" \
    "[ -x \${CLAUDE_PLUGIN_ROOT}/commands/scripts/validate-templates.sh ]"

run_test "utils.sh exists and is executable" \
    "[ -x \${CLAUDE_PLUGIN_ROOT}/commands/scripts/utils.sh ]"

echo ""

# ===== PHASE 2: Template Validation =====
echo -e "${YELLOW}Phase 2: Template Validation${NC}"

run_test_with_output "All templates pass validation" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/validate-templates.sh" \
    "Passed: 6"

run_test "code-refactoring template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/code-refactoring.md ]"

run_test "document-qa template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/document-qa.md ]"

run_test "function-calling template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/function-calling.md ]"

run_test "interactive-dialogue template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/interactive-dialogue.md ]"

run_test "simple-classification template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/simple-classification.md ]"

run_test "custom template exists" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/templates/custom.md ]"

echo ""

# ===== PHASE 2B: Error Handling Tests =====
echo -e "${YELLOW}Phase 2B: Error Handling${NC}"

run_test_with_output "Handles missing template gracefully" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh nonexistent" \
    "Template not found"

run_test_with_output "Template processor requires template name" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh" \
    "Usage"

run_test_with_output "Template selector handles empty input" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh ''" \
    "custom"

run_test_with_output "Prompt handler handles special characters safely" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh 'Task with \$SPECIAL and \`backticks\`'" \
    "user_task"

run_test_with_output "Template processor handles special characters in values" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh simple-classification ITEM1='test\$var' ITEM2='back\`tick' CLASSIFICATION_CRITERIA='criteria'" \
    "test"

echo ""

# ===== PHASE 2C: Utility Function Tests =====
echo -e "${YELLOW}Phase 2C: Utility Functions${NC}"

# Test path normalization with Unix paths (should pass through unchanged)
run_test_with_output "Normalize Unix path (no change)" \
    "source \${CLAUDE_PLUGIN_ROOT}/commands/scripts/utils.sh && normalize_path '/home/user/test'" \
    "/home/user/test"

# Test path normalization with backslashes
run_test_with_output "Normalize path with backslashes" \
    "source \${CLAUDE_PLUGIN_ROOT}/commands/scripts/utils.sh && normalize_path 'C:\\\\Users\\\\test'" \
    "/c/Users/test"

# Test that init_plugin_root validates and returns normalized path
run_test_with_output "init_plugin_root returns normalized path" \
    "source \${CLAUDE_PLUGIN_ROOT}/commands/scripts/utils.sh && init_plugin_root" \
    "/home/user/claude-experiments/meta-prompt"

# Test edge case: mixed slashes (forward and backward)
run_test_with_output "Normalize path with mixed slashes" \
    "source \${CLAUDE_PLUGIN_ROOT}/commands/scripts/utils.sh && normalize_path 'C:/Users\\\\test/folder'" \
    "/c/Users/test/folder"

# Test edge case: path with spaces
run_test_with_output "Normalize path with spaces" \
    "source \${CLAUDE_PLUGIN_ROOT}/commands/scripts/utils.sh && normalize_path 'C:\\\\Program Files\\\\My App'" \
    "/c/Program Files/My App"

# Test edge case: path with trailing slash
run_test_with_output "Normalize path with trailing slash" \
    "source \${CLAUDE_PLUGIN_ROOT}/commands/scripts/utils.sh && normalize_path 'C:\\\\Users\\\\test\\\\'" \
    "/c/Users/test/"

echo ""

# ===== PHASE 3: Template Selection Tests =====
echo -e "${YELLOW}Phase 3: Template Selection Accuracy${NC}"

run_test_with_output "Classifies code refactoring correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Refactor the authentication module'" \
    "code-refactoring"

run_test_with_output "Classifies document Q&A correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Answer questions about this document'" \
    "document-qa"

run_test_with_output "Classifies function calling correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Use these API functions to fetch data'" \
    "function-calling"

run_test_with_output "Classifies dialogue correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Act as a tutor for students'" \
    "interactive-dialogue"

run_test_with_output "Classifies comparison correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Compare these two sentences'" \
    "simple-classification"

run_test_with_output "Falls back to custom for novel tasks" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Write a creative poem'" \
    "custom"

echo ""

# ===== PHASE 4: Template Processing Tests =====
echo -e "${YELLOW}Phase 4: Template Processing${NC}"

run_test_with_output "Template processor substitutes variables" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh simple-classification ITEM1='apple' ITEM2='orange' CLASSIFICATION_CRITERIA='fruit'" \
    "apple"

run_test_with_output "Template processor includes template content" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh simple-classification ITEM1='apple' ITEM2='orange' CLASSIFICATION_CRITERIA='fruit'" \
    "Begin your answer"

run_test_with_output "Template processor detects unreplaced variables" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh simple-classification ITEM1='apple'" \
    "unreplaced"

echo ""

# ===== PHASE 5: Prompt Handler Tests =====
echo -e "${YELLOW}Phase 5: Prompt Handler${NC}"

run_test_with_output "Prompt handler detects execution mode" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh 'Analyze security issues'" \
    "Optimize and execute"

run_test_with_output "Prompt handler detects return-only mode" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh 'Analyze security issues --return-only'" \
    "Create optimized prompt"

run_test_with_output "Prompt handler removes --return-only flag from task" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh 'Task description --return-only'" \
    "Task description"

echo ""

# ===== PHASE 6: File Modification Tests =====
echo -e "${YELLOW}Phase 6: Modified Command Files${NC}"

run_test_with_output "prompt.md references bash handler" \
    "cat \${CLAUDE_PLUGIN_ROOT}/commands/prompt.md" \
    "prompt-handler.sh"

run_test_with_output "create-prompt.md references template selector" \
    "cat \${CLAUDE_PLUGIN_ROOT}/commands/create-prompt.md" \
    "template-selector.sh"

run_test "prompt-optimizer agent is streamlined (<100 lines)" \
    "[ \$(wc -l < \${CLAUDE_PLUGIN_ROOT}/agents/prompt-optimizer.md | tr -d ' ') -lt 100 ]"

echo ""

# ===== SUMMARY =====
echo -e "${YELLOW}=====================================${NC}"
echo -e "${YELLOW}           Test Summary              ${NC}"
echo -e "${YELLOW}=====================================${NC}"
echo ""
echo "Total Tests:  $TOTAL_TESTS"
echo -e "${GREEN}Passed:       $PASSED_TESTS${NC}"
echo -e "${RED}Failed:       $FAILED_TESTS${NC}"
echo ""

PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
echo "Pass Rate:    $PASS_RATE%"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
    echo ""
    echo "The LLM optimization implementation is ready for deployment."
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    echo "Please review the failed tests above and fix any issues."
    exit 1
fi
