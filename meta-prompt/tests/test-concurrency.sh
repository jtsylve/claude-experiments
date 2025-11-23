#!/usr/bin/env bash
# Concurrency Test for Template Selector
# Validates that concurrent executions don't corrupt the log file

set -euo pipefail

# ANSI colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELECTOR="${CLAUDE_PLUGIN_ROOT:-${SCRIPT_DIR}/..}/commands/scripts/template-selector.sh"
LOG_DIR="${CLAUDE_PLUGIN_ROOT:-${SCRIPT_DIR}/..}/logs"
LOG_FILE="${LOG_DIR}/template-selections.jsonl"

echo -e "${YELLOW}=====================================${NC}"
echo -e "${YELLOW}  Concurrency Test${NC}"
echo -e "${YELLOW}=====================================${NC}"
echo ""

# Clean up log file before test
rm -f "${LOG_FILE}" "${LOG_FILE}.lock"
mkdir -p "${LOG_DIR}"

# Test concurrent execution
echo -e "${BLUE}Testing concurrent execution (10 parallel instances)...${NC}"

# Run 10 instances in parallel
for i in {1..10}; do
    (
        "$SELECTOR" "Refactor the authentication module $i" > /dev/null
    ) &
done

# Wait for all background jobs to complete
wait

# Verify log file integrity
echo ""
echo -e "${BLUE}Verifying log file integrity...${NC}"

if [ ! -f "${LOG_FILE}" ]; then
    echo -e "${RED}✗ FAILED${NC} - Log file was not created"
    exit 1
fi

# Count lines in log file
line_count=$(wc -l < "${LOG_FILE}" | tr -d ' ')

echo -n "Log entries created: $line_count (expected: 10) - "
if [ "$line_count" -eq 10 ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "Some log entries may have been lost or corrupted"
    exit 1
fi

# Validate each line is valid JSON
echo -n "Validating JSONL format - "
invalid_lines=0

while IFS= read -r line; do
    if ! echo "$line" | jq empty 2>/dev/null; then
        invalid_lines=$((invalid_lines + 1))
    fi
done < "${LOG_FILE}"

if [ "$invalid_lines" -eq 0 ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "Found $invalid_lines invalid JSON lines"
    exit 1
fi

# Check for interleaved writes (corruption)
echo -n "Checking for write corruption - "
corruption_found=false

while IFS= read -r line; do
    # Check if line starts with { and ends with }
    if ! [[ "$line" =~ ^\{.*\}$ ]]; then
        corruption_found=true
        break
    fi
done < "${LOG_FILE}"

if [ "$corruption_found" = false ]; then
    echo -e "${GREEN}✓ PASSED${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "Log entries appear to be interleaved (race condition detected)"
    exit 1
fi

# Clean up
rm -f "${LOG_FILE}" "${LOG_FILE}.lock"

echo ""
echo -e "${GREEN}All concurrency tests passed!${NC}"
echo -e "The flock mechanism successfully prevented race conditions."
