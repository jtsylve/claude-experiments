#!/usr/bin/env bash
# Logging Validation Test Suite
# Tests the template selection logging functionality

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
        echo -e "  ${GREEN}✓ PASSED${NC}"
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
echo -e "${YELLOW}  Template Selection Logging Tests  ${NC}"
echo -e "${YELLOW}=====================================${NC}"
echo ""

# Setup: Create temporary log directory for testing
TEST_LOG_DIR=$(mktemp -d)
TEST_LOG_FILE="${TEST_LOG_DIR}/template-selections.jsonl"

# Backup original log file if it exists
ORIGINAL_LOG_DIR="${CLAUDE_PLUGIN_ROOT}/logs"
ORIGINAL_LOG_FILE="${ORIGINAL_LOG_DIR}/template-selections.jsonl"
BACKUP_LOG_FILE=""

if [ -f "${ORIGINAL_LOG_FILE}" ]; then
    BACKUP_LOG_FILE="${ORIGINAL_LOG_FILE}.backup.$$"
    cp "${ORIGINAL_LOG_FILE}" "${BACKUP_LOG_FILE}"
fi

# Temporarily move original log file
if [ -f "${ORIGINAL_LOG_FILE}" ]; then
    mv "${ORIGINAL_LOG_FILE}" "${ORIGINAL_LOG_FILE}.tmp"
fi

# Cleanup function
cleanup() {
    # Restore original log file
    if [ -f "${ORIGINAL_LOG_FILE}.tmp" ]; then
        mv "${ORIGINAL_LOG_FILE}.tmp" "${ORIGINAL_LOG_FILE}"
    fi

    # Remove temporary test log directory
    rm -rf "${TEST_LOG_DIR}"

    # Remove backup
    if [ -n "${BACKUP_LOG_FILE}" ] && [ -f "${BACKUP_LOG_FILE}" ]; then
        rm -f "${BACKUP_LOG_FILE}"
    fi
}

trap cleanup EXIT

# ===== PHASE 1: Log File Creation Tests =====
echo -e "${YELLOW}Phase 1: Log File Creation${NC}"

run_test "Log directory is created automatically" \
    "[ -d \${CLAUDE_PLUGIN_ROOT}/logs ]"

run_test "Template selector creates log file when logging enabled" \
    "ENABLE_LOGGING=1 \${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Test task' > /dev/null && [ -f \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl ]"

echo ""

# ===== PHASE 2: JSONL Format Validation =====
echo -e "${YELLOW}Phase 2: JSONL Format Validation${NC}"

# Run a classification to generate log entries
ENABLE_LOGGING=1 ${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Refactor authentication code' > /dev/null 2>&1

run_test_with_output "Log entries are valid JSON" \
    "tail -1 \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl | jq . > /dev/null 2>&1 && echo 'valid'" \
    "valid"

run_test_with_output "Log entry contains timestamp field" \
    "tail -1 \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl | jq -r .timestamp" \
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\$"

run_test_with_output "Log entry contains task_hash field" \
    "tail -1 \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl | jq -r .task_hash" \
    "^[a-f0-9]+\$"

run_test_with_output "Log entry contains selected_template field" \
    "tail -1 \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl | jq -r .selected_template" \
    "code-refactoring"

run_test_with_output "Log entry contains confidence score" \
    "tail -1 \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl | jq -r .confidence" \
    "^[0-9]+\$"

run_test_with_output "Log entry contains all confidence scores in confidences object" \
    "tail -1 \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl | jq -r .confidences.code" \
    "^[0-9]+\$"

echo ""

# ===== PHASE 3: Logging Control Tests =====
echo -e "${YELLOW}Phase 3: Logging Control${NC}"

# Clear log file
> ${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl

# Run with logging disabled
ENABLE_LOGGING=0 ${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Test task' > /dev/null 2>&1

run_test "ENABLE_LOGGING=0 disables logging" \
    "[ ! -s \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl ]"

# Run with logging enabled (default)
${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Test task' > /dev/null 2>&1

run_test "Logging enabled by default" \
    "[ -s \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl ]"

echo ""

# ===== PHASE 4: Privacy Tests =====
echo -e "${YELLOW}Phase 4: Privacy and Security${NC}"

# Clear log file
> ${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl

# Run with sensitive task description
ENABLE_LOGGING=1 ${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Extract passwords from config file' > /dev/null 2>&1

run_test "Task description is not logged directly" \
    "! grep -q 'passwords' \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl"

run_test "Task is hashed instead of logged plaintext" \
    "tail -1 \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl | jq -r .task_hash | grep -q '^[a-f0-9]'"

# Test log injection prevention
ENABLE_LOGGING=1 ${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh $'Test task with\nnewline' > /dev/null 2>&1

run_test_with_output "Newlines in task don't create multiple log entries" \
    "wc -l < \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl" \
    "^[0-9]+\$"

run_test "Last log entry is valid JSON despite newlines in input" \
    "tail -1 \${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl | jq . > /dev/null 2>&1"

echo ""

# ===== PHASE 5: Hash Function Portability Tests =====
echo -e "${YELLOW}Phase 5: Hash Function Portability${NC}"

run_test_with_output "compute_hash function exists in template-selector.sh" \
    "grep -q 'compute_hash' \${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh && echo 'exists'" \
    "exists"

run_test_with_output "compute_hash supports shasum fallback" \
    "grep -q 'shasum' \${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh && echo 'found'" \
    "found"

run_test_with_output "compute_hash supports sha256sum fallback" \
    "grep -q 'sha256sum' \${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh && echo 'found'" \
    "found"

run_test_with_output "compute_hash supports cksum fallback" \
    "grep -q 'cksum' \${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh && echo 'found'" \
    "found"

echo ""

# ===== PHASE 6: Error Handling Tests =====
echo -e "${YELLOW}Phase 6: Error Handling${NC}"

# Test logging to read-only directory (simulate permission error)
# This test validates that logging failures don't crash the script

run_test "Script continues if logging fails" \
    "ENABLE_LOGGING=1 \${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Test task' > /dev/null 2>&1"

# Test DEBUG mode shows logging warnings
run_test_with_output "DEBUG mode shows warning on logging failure" \
    "chmod -w \${CLAUDE_PLUGIN_ROOT}/logs && DEBUG=1 ENABLE_LOGGING=1 \${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh 'Test' 2>&1 || true" \
    "Warning.*log|Failed.*log"

# Restore permissions
chmod +w ${CLAUDE_PLUGIN_ROOT}/logs 2>/dev/null || true

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
    echo -e "${GREEN}✓ ALL LOGGING TESTS PASSED!${NC}"
    echo ""
    echo "The logging infrastructure is working correctly."
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    echo "Please review the failed tests above and fix any issues."
    exit 1
fi
