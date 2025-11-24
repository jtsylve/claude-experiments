#!/usr/bin/env bash
# Unit Tests for Template Selector Handler
# Tests the template-selector-handler.sh classification logic
# This handler is called by the template-selector agent

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

HANDLER="${CLAUDE_PLUGIN_ROOT}/agents/scripts/template-selector-handler.sh"

# Helper: Create XML input for handler
create_xml_input() {
    local user_task="$1"
    cat <<EOF
<template_selector_request>
<user_task>$user_task</user_task>
</template_selector_request>
EOF
}

# Helper: Extract template from handler output
extract_template() {
    local output="$1"

    # First, check for "Classified template:" (appears in borderline/low confidence cases)
    if echo "$output" | grep -q "Classified template:"; then
        echo "$output" | grep "Classified template:" | sed 's/.*Classified template: \([a-z-]*\).*/\1/'
    # Then check for "Template:" line at start (from classification result)
    elif echo "$output" | grep -q "^Template:"; then
        echo "$output" | grep "^Template:" | sed 's/^Template: \([a-z-]*\).*/\1/'
    # Finally check for XML result, but avoid matching the example template
    elif echo "$output" | grep -q "DECISION: High confidence"; then
        echo "$output" | sed -n 's/.*<selected_template>\(.*\)<\/selected_template>.*/\1/p' | head -1
    else
        echo "custom"
    fi
}

# Helper: Extract confidence from handler output
extract_confidence() {
    local output="$1"
    # Check if output contains XML result (high confidence case)
    if echo "$output" | grep -q "<confidence>"; then
        echo "$output" | sed -n 's/.*<confidence>\([0-9]*\)<\/confidence>.*/\1/p'
    else
        # For borderline/low confidence, extract from "Confidence:" line
        echo "$output" | grep "Confidence:" | sed 's/.*Confidence: \([0-9]*\)%.*/\1/' || echo "0"
    fi
}

# Helper: Run test
run_test() {
    local test_name="$1"
    local task_description="$2"
    local expected_template="$3"
    local expected_confidence_min="$4"
    local expected_confidence_max="${5:-100}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} $test_name"

    # Create XML input and pass as argument to handler
    local xml_input=$(create_xml_input "$task_description")
    local output=$("$HANDLER" "$xml_input" 2>&1)

    local template=$(extract_template "$output")
    local confidence=$(extract_confidence "$output")

    local passed=true

    # Check template match
    if [ "$template" != "$expected_template" ]; then
        echo -e "  ${RED}✗ FAILED${NC} - Expected template: $expected_template, got: $template"
        passed=false
    fi

    # Check confidence range
    if [ -n "$confidence" ] && [ "$confidence" -ge 0 ]; then
        if [ "$confidence" -lt "$expected_confidence_min" ] || [ "$confidence" -gt "$expected_confidence_max" ]; then
            echo -e "  ${RED}✗ FAILED${NC} - Expected confidence: $expected_confidence_min-$expected_confidence_max, got: $confidence"
            passed=false
        fi
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

echo -e "${YELLOW}================================================${NC}"
echo -e "${YELLOW}  Template Selector Handler Unit Tests${NC}"
echo -e "${YELLOW}================================================${NC}"
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

echo ""

# ===== PHASE 2: Borderline Confidence Tests (60-69%) =====
echo -e "${YELLOW}Phase 2: Borderline Confidence Tests (60-69%)${NC}"

run_test "Two supporting keywords only" \
    "Look at the code class" \
    "code-refactoring" 60 69

run_test "Mixed signals" \
    "Show me the code and file" \
    "code-refactoring" 60 69

echo ""

# ===== PHASE 3: Low Confidence Tests (<60%) =====
echo -e "${YELLOW}Phase 3: Low Confidence Tests (<60%)${NC}"

run_test "Single supporting keyword" \
    "Look at the code" \
    "custom" 0 59

run_test "No matching keywords" \
    "Hello world" \
    "custom" 0 59

run_test "Generic task" \
    "Help me with this" \
    "custom" 0 59

echo ""

# ===== PHASE 4: Edge Cases =====
echo -e "${YELLOW}Phase 4: Edge Cases${NC}"

run_test "Empty description" \
    "" \
    "custom" 0 59

run_test "Special characters in task" \
    'Refactor the code with special chars: $var, `command`, "quoted"' \
    "code-refactoring" 70

echo ""

# ===== PHASE 5: Strong Indicator Tests =====
echo -e "${YELLOW}Phase 5: Strong Indicator Confidence${NC}"

run_test "Strong indicator alone = 75%" \
    "Refactor this" \
    "code-refactoring" 75 75

run_test "Strong indicator + supporting keywords" \
    "Refactor the code in the authentication module" \
    "code-refactoring" 75

echo ""

# ===== PHASE 6: Error Handling & Negative Tests =====
echo -e "${YELLOW}Phase 6: Error Handling & Negative Tests${NC}"

# Test empty task
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} Rejects empty task input"
xml_input="<template_selector_request><user_task></user_task></template_selector_request>"
output=$("$HANDLER" "$xml_input" 2>&1) || test_passed=$?
if [ "${test_passed:-0}" -ne 0 ] || echo "$output" | grep -qi "Error.*empty\|Error.*required\|Error.*Missing"; then
    echo -e "  ${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${RED}✗ FAILED${NC} - Should reject empty task"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test missing user_task field
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} Rejects missing user_task field"
xml_input="<template_selector_request><suggested_template>code-refactoring</suggested_template></template_selector_request>"
output=$("$HANDLER" "$xml_input" 2>&1) || test_passed=$?
if [ "${test_passed:-0}" -ne 0 ] || echo "$output" | grep -qi "Error.*user_task\|Error.*required\|Error.*Missing"; then
    echo -e "  ${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${RED}✗ FAILED${NC} - Should reject missing user_task"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test invalid confidence value
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} Rejects non-numeric confidence"
xml_input="<template_selector_request><user_task>test</user_task><confidence>not-a-number</confidence></template_selector_request>"
output=$("$HANDLER" "$xml_input" 2>&1) || test_passed=$?
if [ "${test_passed:-0}" -ne 0 ] || echo "$output" | grep -qi "Error.*confidence\|Error.*invalid\|Error.*integer"; then
    echo -e "  ${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${RED}✗ FAILED${NC} - Should reject non-numeric confidence"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test malformed XML
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} Handles malformed XML"
xml_input="<broken>unclosed tag"
output=$("$HANDLER" "$xml_input" 2>&1) || test_passed=$?
if [ "${test_passed:-0}" -ne 0 ] || echo "$output" | grep -qi "Error"; then
    echo -e "  ${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${RED}✗ FAILED${NC} - Should handle malformed XML"
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
