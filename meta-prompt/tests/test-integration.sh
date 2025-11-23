#!/usr/bin/env bash
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

# Setup: Set CLAUDE_PLUGIN_ROOT if not already set
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    # Get the script directory and navigate to plugin root (one level up from tests/)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    export CLAUDE_PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

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
    if echo "$output" | grep -Eq "$expected_pattern"; then
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
    "[ -x \${CLAUDE_PLUGIN_ROOT}/tests/validate-templates.sh ]"

echo ""

# ===== PHASE 2: Template Validation =====
echo -e "${YELLOW}Phase 2: Template Validation${NC}"

run_test "Correct number of templates exist" \
    "[ \$(find \${CLAUDE_PLUGIN_ROOT}/templates -name '*.md' -type f | wc -l | tr -d ' ') -eq 7 ]"

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

# ===== PHASE 2B: Engineering Guide Tests =====
echo -e "${YELLOW}Phase 2B: Engineering Guide${NC}"

run_test "engineering-guide.md exists and is readable" \
    "[ -f \${CLAUDE_PLUGIN_ROOT}/guides/engineering-guide.md ]"

run_test_with_output "create-prompt.md references engineering guide" \
    "cat \${CLAUDE_PLUGIN_ROOT}/commands/create-prompt.md" \
    "guides/engineering-guide.md"

run_test_with_output "engineering-guide.md has expected content" \
    "cat \${CLAUDE_PLUGIN_ROOT}/guides/engineering-guide.md" \
    "Comprehensive Prompt Engineering Guide"

echo ""

# ===== PHASE 2C: Error Handling Tests =====
echo -e "${YELLOW}Phase 2C: Error Handling${NC}"

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

run_test_with_output "Prompt handler handles apostrophes correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh \"Fix the code so it doesn't crash\"" \
    "doesn't crash"

run_test_with_output "Prompt handler handles double quotes correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh 'Review the \"main\" function'" \
    "main"

run_test_with_output "Prompt handler handles multiple apostrophes correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh \"Fix user's auth so it doesn't allow access\"" \
    "user's auth so it doesn't"

run_test_with_output "Template processor handles special characters in values" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh code-comparison ITEM1='test\$var' ITEM2='back\`tick' CLASSIFICATION_CRITERIA='criteria'" \
    "test"

echo ""

# ===== PHASE 3: Template Selection Tests =====
echo -e "${YELLOW}Phase 3: Template Selection Accuracy${NC}"

run_test_with_output "Classifies code refactoring correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Refactor the authentication module'" \
    "code-refactoring"

run_test_with_output "Classifies code review correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Review this code for security issues'" \
    "code-review"

run_test_with_output "Classifies test generation correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Generate pytest tests for this function'" \
    "test-generation"

run_test_with_output "Classifies documentation generation correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Generate API documentation for this module'" \
    "documentation-generator"

run_test_with_output "Classifies data extraction correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Extract email addresses from this log file'" \
    "data-extraction"

run_test_with_output "Classifies code comparison correctly" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Compare these two functions for equivalence'" \
    "code-comparison"

run_test_with_output "Falls back to custom for novel tasks" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Write a creative poem'" \
    "custom"

run_test_with_output "Falls back to custom for conversational tasks" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Act as a Socratic tutor for students'" \
    "custom"

echo ""

# ===== PHASE 3B: Hybrid Routing Confidence Tests =====
echo -e "${YELLOW}Phase 3B: Hybrid Routing Confidence Ranges${NC}"

# High confidence tests (70-100%): Should route directly without LLM fallback
run_test_with_output "High confidence: code refactoring (≥70%)" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Refactor authentication to use JWT tokens'" \
    "code-refactoring [7-9][0-9]"

run_test_with_output "High confidence: test generation (≥70%)" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Generate pytest tests with edge cases'" \
    "test-generation [7-9][0-9]"

run_test_with_output "High confidence: code review (≥70%)" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Review code for security vulnerabilities'" \
    "code-review [7-9][0-9]"

# Borderline confidence tests (60-69%): Should output confidence for LLM fallback
# These tasks have some signals but may benefit from LLM verification
# Note: With 2 supporting keywords (no strong indicator), confidence is typically 60%
# Using flexible range to account for keyword list changes
run_test_with_output "Borderline confidence: task with 2 supporting keywords outputs 60-69%" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'API reference' | awk '{print \$2}'" \
    "^(60|6[0-9])\$"

# Low confidence tests (<60%): Should route to custom with confidence 0
run_test_with_output "Low confidence: novel task routes to custom" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Write a haiku about recursion'" \
    "custom 0"

run_test_with_output "Low confidence: conversational task routes to custom" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Be a helpful assistant'" \
    "custom"

# Confidence output format validation
run_test_with_output "Output format: template name and confidence score" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Fix bug in parser'" \
    "^[a-z-]+ [0-9]+\$"

# Confidence threshold boundary testing
run_test_with_output "Strong indicators guarantee ≥75% confidence" \
    "DEBUG=1 \${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Refactor this code' 2>&1" \
    "Confidence: [7-9][0-9]%"

echo ""

# ===== PHASE 4: Template Processing Tests =====
echo -e "${YELLOW}Phase 4: Template Processing${NC}"

run_test_with_output "Template processor substitutes variables" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh code-comparison ITEM1='function a()' ITEM2='function b()' CLASSIFICATION_CRITERIA='semantic equivalence'" \
    "function a()"

run_test_with_output "Template processor includes template content" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh code-comparison ITEM1='code1' ITEM2='code2' CLASSIFICATION_CRITERIA='performance'" \
    "code1"

run_test_with_output "Template processor detects unreplaced variables" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh code-comparison ITEM1='code1'" \
    "unreplaced"

echo ""

# ===== PHASE 5: Prompt Handler Tests =====
echo -e "${YELLOW}Phase 5: Prompt Handler${NC}"

run_test_with_output "Prompt handler detects execution mode" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh 'Analyze security issues'" \
    "Optimize and execute"

run_test_with_output "Prompt handler detects return-only mode" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh '--return-only Analyze security issues'" \
    "Create optimized prompt"

run_test_with_output "Prompt handler removes --return-only flag from task" \
    "\${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh '--return-only Task description'" \
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
