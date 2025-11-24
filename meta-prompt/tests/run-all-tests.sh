#!/usr/bin/env bash
# Run All Meta-Prompt Tests
# Executes all test suites and provides a summary

set -euo pipefail

# ANSI colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Setup: Set CLAUDE_PLUGIN_ROOT if not already set
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    export CLAUDE_PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Helper: Run test suite
run_suite() {
    local suite_name="$1"
    local suite_script="$2"

    TOTAL_SUITES=$((TOTAL_SUITES + 1))

    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}Running: $suite_name${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if "$suite_script"; then
        echo ""
        echo -e "${GREEN}✓ Suite passed: $suite_name${NC}"
        PASSED_SUITES=$((PASSED_SUITES + 1))
        return 0
    else
        echo ""
        echo -e "${RED}✗ Suite failed: $suite_name${NC}"
        FAILED_SUITES=$((FAILED_SUITES + 1))
        return 1
    fi
}

echo -e "${BOLD}${YELLOW}================================================${NC}"
echo -e "${BOLD}${YELLOW}  Meta-Prompt Test Suite Runner${NC}"
echo -e "${BOLD}${YELLOW}================================================${NC}"
echo ""
echo "Plugin root: ${CLAUDE_PLUGIN_ROOT}"
echo ""

# Run all test suites
run_suite "Integration Tests" \
    "${CLAUDE_PLUGIN_ROOT}/tests/test-integration.sh"

run_suite "Prompt Handler Tests (State Machine)" \
    "${CLAUDE_PLUGIN_ROOT}/tests/test-prompt-handler.sh"

run_suite "Template Selector Handler Tests (Classification)" \
    "${CLAUDE_PLUGIN_ROOT}/tests/test-template-selector-handler.sh"

run_suite "Prompt Optimizer Handler Tests (Variable Extraction)" \
    "${CLAUDE_PLUGIN_ROOT}/tests/test-prompt-optimizer-handler.sh"

# Optional: test-validation.sh if it doesn't require special setup
if [ -f "${CLAUDE_PLUGIN_ROOT}/tests/test-validation.sh" ]; then
    echo ""
    echo -e "${YELLOW}Note: Skipping test-validation.sh (requires Claude Code environment)${NC}"
fi

# Final summary
echo ""
echo ""
echo -e "${BOLD}${YELLOW}================================================${NC}"
echo -e "${BOLD}${YELLOW}  Final Summary${NC}"
echo -e "${BOLD}${YELLOW}================================================${NC}"
echo ""
echo -e "Total test suites: $TOTAL_SUITES"

if [ $FAILED_SUITES -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ All test suites passed! ($PASSED_SUITES/$TOTAL_SUITES)${NC}"
    exit 0
else
    echo -e "${GREEN}Passed: $PASSED_SUITES${NC}"
    echo -e "${RED}${BOLD}Failed: $FAILED_SUITES${NC}"
    echo ""
    echo -e "${YELLOW}Re-run individual test suites for details:${NC}"
    echo "  - ./tests/test-integration.sh"
    echo "  - ./tests/test-prompt-handler.sh"
    echo "  - ./tests/test-template-selector-handler.sh"
    echo "  - ./tests/test-prompt-optimizer-handler.sh"
    exit 1
fi
