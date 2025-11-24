#!/usr/bin/env bash
# Concurrent Execution Tests for meta-prompt handlers
# Tests that handlers can run concurrently without conflicts
# Exit: 0=success, 1=failure

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

PROMPT_HANDLER="${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh"
TEMPLATE_SELECTOR="${CLAUDE_PLUGIN_ROOT}/agents/scripts/template-selector-handler.sh"
PROMPT_OPTIMIZER="${CLAUDE_PLUGIN_ROOT}/agents/scripts/prompt-optimizer-handler.sh"

echo -e "${YELLOW}================================================${NC}"
echo -e "${YELLOW}  Concurrent Execution Tests${NC}"
echo -e "${YELLOW}================================================${NC}"
echo ""

# Helper: Run test
run_test() {
    local test_name="$1"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} $test_name"
}

# Helper: Pass test
pass_test() {
    echo -e "  ${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

# Helper: Fail test
fail_test() {
    local message="${1:-}"
    echo -e "  ${RED}✗ FAILED${NC}${message:+ - $message}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

# Test 1: Multiple prompt-handler instances
run_test "Multiple prompt-handler.sh instances run concurrently"

# Run 5 instances in parallel
pids=()
for i in {1..5}; do
    "$PROMPT_HANDLER" "Test task $i" > "/tmp/test-concurrent-$i.out" 2>&1 &
    pids+=($!)
done

# Wait for all to complete
all_passed=true
for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
        all_passed=false
    fi
done

# Check outputs
if [ "$all_passed" = true ]; then
    outputs_valid=true
    for i in {1..5}; do
        if [ ! -f "/tmp/test-concurrent-$i.out" ] || ! grep -q "Use the Task tool" "/tmp/test-concurrent-$i.out"; then
            outputs_valid=false
            break
        fi
    done

    if [ "$outputs_valid" = true ]; then
        pass_test
    else
        fail_test "Some outputs were invalid"
    fi
else
    fail_test "Some instances failed to complete"
fi

# Cleanup
rm -f /tmp/test-concurrent-*.out

# Test 2: Multiple template-selector instances
run_test "Multiple template-selector-handler.sh instances run concurrently"

pids=()
tasks=(
    "Refactor the code"
    "Review this PR"
    "Write unit tests"
    "Generate documentation"
    "Extract data from logs"
)

for i in {0..4}; do
    xml_input="<template_selector_request><user_task>${tasks[$i]}</user_task></template_selector_request>"
    "$TEMPLATE_SELECTOR" "$xml_input" > "/tmp/test-selector-$i.out" 2>&1 &
    pids+=($!)
done

# Wait for all to complete
all_passed=true
for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
        all_passed=false
    fi
done

# Check outputs contain expected templates
if [ "$all_passed" = true ]; then
    outputs_valid=true

    # Verify each output has valid content
    for i in {0..4}; do
        if [ ! -f "/tmp/test-selector-$i.out" ] || ! grep -q "template" "/tmp/test-selector-$i.out"; then
            outputs_valid=false
            break
        fi
    done

    if [ "$outputs_valid" = true ]; then
        pass_test
    else
        fail_test "Some outputs were invalid"
    fi
else
    fail_test "Some instances failed to complete"
fi

# Cleanup
rm -f /tmp/test-selector-*.out

# Test 3: Multiple prompt-optimizer instances
run_test "Multiple prompt-optimizer-handler.sh instances run concurrently"

pids=()
for i in {1..5}; do
    xml_input="<prompt_optimizer_request><user_task>Test task $i</user_task><template>custom</template><execution_mode>direct</execution_mode></prompt_optimizer_request>"
    "$PROMPT_OPTIMIZER" "$xml_input" > "/tmp/test-optimizer-$i.out" 2>&1 &
    pids+=($!)
done

# Wait for all to complete
all_passed=true
for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
        all_passed=false
    fi
done

# Check outputs
if [ "$all_passed" = true ]; then
    outputs_valid=true
    for i in {1..5}; do
        if [ ! -f "/tmp/test-optimizer-$i.out" ] || ! grep -q "Template: custom" "/tmp/test-optimizer-$i.out"; then
            outputs_valid=false
            break
        fi
    done

    if [ "$outputs_valid" = true ]; then
        pass_test
    else
        fail_test "Some outputs were invalid"
    fi
else
    fail_test "Some instances failed to complete"
fi

# Cleanup
rm -f /tmp/test-optimizer-*.out

# Test 4: Mixed handler types running concurrently
run_test "Different handler types run concurrently without conflicts"

# Run one of each handler type
"$PROMPT_HANDLER" "Mixed test 1" > /tmp/test-mixed-1.out 2>&1 &
pid1=$!

xml_selector="<template_selector_request><user_task>Mixed test 2</user_task></template_selector_request>"
"$TEMPLATE_SELECTOR" "$xml_selector" > /tmp/test-mixed-2.out 2>&1 &
pid2=$!

xml_optimizer="<prompt_optimizer_request><user_task>Mixed test 3</user_task><template>custom</template><execution_mode>direct</execution_mode></prompt_optimizer_request>"
"$PROMPT_OPTIMIZER" "$xml_optimizer" > /tmp/test-mixed-3.out 2>&1 &
pid3=$!

# Wait for all
all_passed=true
for pid in $pid1 $pid2 $pid3; do
    if ! wait "$pid"; then
        all_passed=false
    fi
done

# Verify outputs
if [ "$all_passed" = true ]; then
    if [ -f /tmp/test-mixed-1.out ] && [ -f /tmp/test-mixed-2.out ] && [ -f /tmp/test-mixed-3.out ]; then
        if grep -q "Use the Task tool" /tmp/test-mixed-1.out && \
           grep -q "template" /tmp/test-mixed-2.out && \
           grep -q "Template: custom" /tmp/test-mixed-3.out; then
            pass_test
        else
            fail_test "Output validation failed"
        fi
    else
        fail_test "Output files missing"
    fi
else
    fail_test "Some instances failed"
fi

# Cleanup
rm -f /tmp/test-mixed-*.out

echo ""

# Summary
echo -e "${YELLOW}=== Summary ===${NC}"
echo -e "Total tests: $TOTAL_TESTS"
if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${GREEN}All concurrent execution tests passed!${NC}"
    exit 0
else
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    exit 1
fi
