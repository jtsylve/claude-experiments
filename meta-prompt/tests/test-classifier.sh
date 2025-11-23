#!/usr/bin/env bash
# Unit Tests for Template Classifier
# Tests confidence calculation, borderline scenarios, and edge cases

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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELECTOR="${CLAUDE_PLUGIN_ROOT:-${SCRIPT_DIR}/..}/commands/scripts/template-selector.sh"

# Helper: Run test
run_test() {
    local test_name="$1"
    local task_description="$2"
    local expected_template="$3"
    local expected_confidence_min="$4"
    local expected_confidence_max="${5:-100}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} $test_name"

    local result=$("$SELECTOR" "$task_description")
    local template=$(echo "$result" | cut -d' ' -f1)
    local confidence=$(echo "$result" | cut -d' ' -f2)

    local passed=true

    # Check template match
    if [ "$template" != "$expected_template" ]; then
        echo -e "  ${RED}✗ FAILED${NC} - Expected template: $expected_template, got: $template"
        passed=false
    fi

    # Check confidence range
    if [ "$confidence" -lt "$expected_confidence_min" ] || [ "$confidence" -gt "$expected_confidence_max" ]; then
        echo -e "  ${RED}✗ FAILED${NC} - Expected confidence: $expected_confidence_min-$expected_confidence_max, got: $confidence"
        passed=false
    fi

    if [ "$passed" = true ]; then
        echo -e "  ${GREEN}✓ PASSED${NC} (template: $template, confidence: $confidence)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo -e "${YELLOW}=====================================${NC}"
echo -e "${YELLOW}  Template Classifier Unit Tests${NC}"
echo -e "${YELLOW}=====================================${NC}"
echo ""

# ===== PHASE 1: High Confidence Tests (70%+) =====
echo -e "${YELLOW}Phase 1: High Confidence Tests (70%+)${NC}"

run_test "Code refactoring with strong indicator" \
    "Refactor the authentication module to use JWT tokens" \
    "code-refactoring" 70

run_test "Test generation with strong indicator" \
    "Write unit tests for the user service" \
    "test-generation" 70

run_test "Code review with strong indicator" \
    "Review the pull request for code quality issues" \
    "code-review" 70

run_test "Documentation generation with strong indicator" \
    "Write documentation for the API endpoints" \
    "documentation-generator" 70

run_test "Data extraction with strong indicator" \
    "Extract email addresses from the log file" \
    "data-extraction" 70

run_test "Code comparison with strong indicator" \
    "Compare these two implementations to see if they're equivalent" \
    "code-comparison" 70

# ===== PHASE 2: Borderline Confidence Tests (60-69%) =====
echo -e "${YELLOW}Phase 2: Borderline Confidence Tests (60-69%)${NC}"

run_test "Two supporting keywords only (no strong indicator)" \
    "Look at the code class" \
    "code-refactoring" 60 69

run_test "Mixed signals - multiple categories" \
    "Show me the code and file" \
    "code-refactoring" 60 69

# ===== PHASE 3: Low Confidence Tests (<60%) =====
echo -e "${YELLOW}Phase 3: Low Confidence Tests (<60%)${NC}"

run_test "Single supporting keyword only" \
    "Look at the code" \
    "custom" 0 59

run_test "No matching keywords" \
    "Hello world" \
    "custom" 0 59

run_test "Generic task with no clear category" \
    "Help me with this" \
    "custom" 0 59

# ===== PHASE 4: Edge Cases =====
echo -e "${YELLOW}Phase 4: Edge Cases${NC}"

run_test "Empty description" \
    "" \
    "custom" 0 59

run_test "Special characters in task" \
    'Refactor the code with special chars: $var, `command`, "quoted"' \
    "code-refactoring" 70

run_test "Multiline task description" \
    "$(printf 'Refactor the authentication\nmodule to use JWT\ntokens')" \
    "code-refactoring" 70

run_test "Very long task description" \
    "$(printf 'Refactor %.0s' {1..100})" \
    "code-refactoring" 70

run_test "Task with newlines and special characters" \
    "$(printf 'Review this code:\nif (x > 0) {\n  return \$var;\n}')" \
    "code-review" 70

# ===== PHASE 5: Category Disambiguation =====
echo -e "${YELLOW}Phase 5: Category Disambiguation${NC}"

run_test "Code vs Documentation - code wins" \
    "Refactor the code documentation generator" \
    "code-refactoring" 70

run_test "Test vs Review - test wins" \
    "Review the test suite and write more tests" \
    "test-generation" 70

run_test "Multiple strong indicators - highest confidence wins" \
    "Extract test data from the code and refactor it" \
    "code-refactoring" 70

# ===== PHASE 6: Confidence Calculation Accuracy =====
echo -e "${YELLOW}Phase 6: Confidence Calculation Accuracy${NC}"

run_test "Strong indicator + supporting keywords = high confidence" \
    "Refactor the code in the authentication module class file" \
    "code-refactoring" 75

run_test "Strong indicator alone = 75% minimum" \
    "Refactor this" \
    "code-refactoring" 75 75

run_test "Strong indicator + many supporting keywords = capped at 100%" \
    "Refactor the code file class module system endpoint" \
    "code-refactoring" 100 100

# ===== PHASE 7: Negative Test Cases =====
echo -e "${YELLOW}Phase 7: Negative Test Cases (Misleading Keywords)${NC}"

# Note: Keyword-based classifiers cannot understand negation semantics
# These tests verify current behavior rather than ideal behavior
run_test "Negation with keyword - 'don't refactor' (still matches refactor)" \
    "Don't refactor the code, just review it" \
    "code-refactoring" 70

run_test "Negation with keyword - 'not a test' (document wins with higher confidence)" \
    "This is not a test, just document the API" \
    "documentation-generator" 70

run_test "Keyword in different context - 'test environment' (refactor wins)" \
    "Refactor the test environment configuration" \
    "code-refactoring" 70

run_test "Strong indicator tie - 'extract documentation' (documentation checked first)" \
    "Extract the documentation string from files" \
    "documentation-generator" 75 75

# ===== PHASE 8: Boundary Value Tests =====
echo -e "${YELLOW}Phase 8: Boundary Value Tests (Exact Thresholds)${NC}"

run_test "Exactly at borderline minimum (60%)" \
    "code file" \
    "code-refactoring" 60 69

run_test "Just above borderline (70%+)" \
    "Refactor" \
    "code-refactoring" 75 75

run_test "Just below borderline (<60% becomes custom)" \
    "code" \
    "custom" 0 0

# ===== Summary =====
echo ""
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
