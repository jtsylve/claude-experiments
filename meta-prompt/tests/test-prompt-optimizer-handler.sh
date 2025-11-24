#!/usr/bin/env bash
# Unit Tests for Prompt Optimizer Handler
# Tests the prompt-optimizer-handler.sh template loading and variable extraction
# This handler is called by the prompt-optimizer agent

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

HANDLER="${CLAUDE_PLUGIN_ROOT}/agents/scripts/prompt-optimizer-handler.sh"

# Helper: Create XML input for handler
create_xml_input() {
    local user_task="$1"
    local template="$2"
    local execution_mode="${3:-direct}"
    cat <<EOF
<prompt_optimizer_request>
<user_task>$user_task</user_task>
<template>$template</template>
<execution_mode>$execution_mode</execution_mode>
</prompt_optimizer_request>
EOF
}

# Helper: Check if output contains expected content
check_output_contains() {
    local output="$1"
    local expected_pattern="$2"
    echo "$output" | grep -q "$expected_pattern"
}

# Helper: Run test
run_test() {
    local test_name="$1"
    local user_task="$2"
    local template="$3"
    local expected_pattern="$4"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} $test_name"

    # Create XML input and pass as argument to handler
    local xml_input=$(create_xml_input "$user_task" "$template")
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

# Helper: Run test checking for error
run_error_test() {
    local test_name="$1"
    local user_task="$2"
    local template="$3"
    local expected_error="$4"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} $test_name"

    local xml_input=$(create_xml_input "$user_task" "$template")
    local output=$("$HANDLER" "$xml_input" 2>&1 || true)

    if check_output_contains "$output" "$expected_error"; then
        echo -e "  ${GREEN}✓ PASSED${NC} (error detected as expected)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "  ${RED}✗ FAILED${NC} - Expected error not found: $expected_error"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo -e "${YELLOW}================================================${NC}"
echo -e "${YELLOW}  Prompt Optimizer Handler Unit Tests${NC}"
echo -e "${YELLOW}================================================${NC}"
echo ""

# ===== PHASE 1: Template Loading Tests =====
echo -e "${YELLOW}Phase 1: Template Loading${NC}"

run_test "Loads code-refactoring template" \
    "Fix the bug in auth" \
    "code-refactoring" \
    "Template: code-refactoring"

run_test "Loads code-review template" \
    "Review this code" \
    "code-review" \
    "Template: code-review"

run_test "Loads test-generation template" \
    "Write tests" \
    "test-generation" \
    "Template: test-generation"

run_test "Loads custom template" \
    "Do something novel" \
    "custom" \
    "Template: custom"

echo ""

# ===== PHASE 2: Skill Mapping Tests =====
echo -e "${YELLOW}Phase 2: Skill Mapping${NC}"

run_test "Maps code-refactoring to correct skill" \
    "Refactor code" \
    "code-refactoring" \
    "Skill: meta-prompt:code-refactoring"

run_test "Maps code-review to correct skill" \
    "Review code" \
    "code-review" \
    "Skill: meta-prompt:code-review"

run_test "Maps custom to no skill" \
    "Novel task" \
    "custom" \
    "Skill: none"

echo ""

# ===== PHASE 3: Variable Extraction Instructions =====
echo -e "${YELLOW}Phase 3: Variable Extraction Instructions${NC}"

run_test "Provides variable extraction instructions" \
    "Fix the bug" \
    "code-refactoring" \
    "Extract variable values"

run_test "Lists required and optional variables" \
    "Review code" \
    "code-review" \
    "Template Variables"

run_test "Includes template content" \
    "Write tests" \
    "test-generation" \
    "Template Content"

echo ""

# ===== PHASE 4: Execution Mode Tests =====
echo -e "${YELLOW}Phase 4: Execution Mode${NC}"

run_test "Handles direct execution mode" \
    "Fix bug" \
    "code-refactoring" \
    "Execution mode: direct"

# Test with plan mode
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} Handles plan execution mode"
xml_input=$(create_xml_input "Fix bug" "code-refactoring" "plan")
output=$("$HANDLER" "$xml_input" 2>&1)
if check_output_contains "$output" "Execution mode: plan"; then
    echo -e "  ${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${RED}✗ FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

echo ""

# ===== PHASE 5: Error Handling Tests =====
echo -e "${YELLOW}Phase 5: Error Handling${NC}"

run_error_test "Rejects missing template" \
    "Fix bug" \
    "" \
    "Error: Missing required field: template"

run_error_test "Rejects invalid template" \
    "Fix bug" \
    "nonexistent-template" \
    "ERROR: Template not found"

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
