#!/usr/bin/env bash
# Purpose: Verify documentation counts match actual template and test counts
# Inputs: None
# Outputs: Validation results showing any mismatches

set -euo pipefail

# Validate required environment variables
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    echo "ERROR: CLAUDE_PLUGIN_ROOT environment variable is not set" >&2
    exit 1
fi

TEMPLATE_DIR="${CLAUDE_PLUGIN_ROOT}/templates"
DOCS_DIR="${CLAUDE_PLUGIN_ROOT}/docs"
TEST_SCRIPT="${CLAUDE_PLUGIN_ROOT}/tests/test-integration.sh"
README_FILE="${CLAUDE_PLUGIN_ROOT}/../README.md"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function: Count actual templates (excluding custom fallback)
count_actual_templates() {
    find "$TEMPLATE_DIR" -name "*.md" -type f | wc -l | tr -d ' '
}

# Function: Count tests in test-integration.sh
count_actual_tests() {
    if [ ! -f "$TEST_SCRIPT" ]; then
        echo "0"
        return
    fi

    # Count test calls (run_test and run_test_with_output function calls)
    local count=$(grep -cE '^run_test' "$TEST_SCRIPT" 2>/dev/null || echo "0")
    echo "$count"
}

# Function: Extract template count from documentation file
extract_template_count() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "FILE_NOT_FOUND"
        return
    fi

    # Look for patterns like "10 templates" or "Templates: 10"
    local count=$(grep -oE '[0-9]+ (templates|pre-built templates)' "$file" | head -1 | grep -oE '[0-9]+' 2>/dev/null || echo "")

    # If not found, check for word form (Ten templates)
    if [ -z "$count" ]; then
        local word_count=$(grep -iE '(Ten|ten) templates' "$file" | head -1 2>/dev/null || echo "")
        if [ -n "$word_count" ]; then
            count="10"
        fi
    fi

    if [ -z "$count" ]; then
        echo "NOT_FOUND"
    else
        echo "$count"
    fi
}

# Function: Extract test count from documentation file
extract_test_count() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "FILE_NOT_FOUND"
        return
    fi

    # Look for patterns like "Total Tests: 48" or "48 tests" but not "Passed: X templates"
    local count=$(grep -oE '([Tt]otal [Tt]ests:|test coverage) *[0-9]+' "$file" | head -1 | grep -oE '[0-9]+' 2>/dev/null || echo "")

    # If not found, try looking for standalone mentions of test counts
    if [ -z "$count" ]; then
        count=$(grep -oE '(all |All )?[0-9]+ tests (pass|passed)' "$file" | head -1 | grep -oE '[0-9]+' 2>/dev/null || echo "")
    fi

    if [ -z "$count" ]; then
        echo "NOT_FOUND"
    else
        echo "$count"
    fi
}

# Function: Check if count matches expected value
check_count() {
    local description="$1"
    local actual="$2"
    local documented="$3"
    local file="$4"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [ "$documented" = "FILE_NOT_FOUND" ]; then
        echo -e "  ${YELLOW}⚠${NC} $description: File not found: $file"
        return 0
    elif [ "$documented" = "NOT_FOUND" ]; then
        echo -e "  ${YELLOW}⚠${NC} $description: Count not found in $file"
        return 0
    elif [ "$actual" = "$documented" ]; then
        echo -e "  ${GREEN}✓${NC} $description: $actual (matches $file)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description: Actual=$actual, Documented=$documented in $file"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Main function
main() {
    echo -e "${YELLOW}=== Documentation Count Verification ===${NC}\n"

    # Count actual files
    echo -e "${YELLOW}Counting actual files...${NC}"
    local actual_templates=$(count_actual_templates)
    local actual_tests=$(count_actual_tests)
    echo -e "  Actual templates: $actual_templates"
    echo -e "  Actual tests: $actual_tests\n"

    # Check template counts in documentation
    echo -e "${YELLOW}Verifying template counts in documentation...${NC}"

    # Check README.md
    local readme_templates=$(extract_template_count "$README_FILE")
    check_count "README.md template count" "$actual_templates" "$readme_templates" "$README_FILE"

    # Check meta-prompt/README.md
    local meta_readme="${CLAUDE_PLUGIN_ROOT}/README.md"
    local meta_readme_templates=$(extract_template_count "$meta_readme")
    check_count "meta-prompt/README.md template count" "$actual_templates" "$meta_readme_templates" "$meta_readme"

    # Check getting-started.md
    local getting_started="${DOCS_DIR}/getting-started.md"
    local gs_templates=$(extract_template_count "$getting_started")
    check_count "getting-started.md template count" "$actual_templates" "$gs_templates" "$getting_started"

    # Check CONTRIBUTING.md
    local contributing="${CLAUDE_PLUGIN_ROOT}/CONTRIBUTING.md"
    local contrib_templates=$(extract_template_count "$contributing")
    check_count "CONTRIBUTING.md template count" "$actual_templates" "$contrib_templates" "$contributing"

    echo ""

    # Check test counts in documentation
    echo -e "${YELLOW}Verifying test counts in documentation...${NC}"

    # Check getting-started.md
    local gs_tests=$(extract_test_count "$getting_started")
    check_count "getting-started.md test count" "$actual_tests" "$gs_tests" "$getting_started"

    # Check migration.md
    local migration="${DOCS_DIR}/migration.md"
    local migration_tests=$(extract_test_count "$migration")
    check_count "migration.md test count" "$actual_tests" "$migration_tests" "$migration"

    # Check infrastructure.md
    local infrastructure="${DOCS_DIR}/infrastructure.md"
    if [ -f "$infrastructure" ]; then
        local infra_tests=$(extract_test_count "$infrastructure")
        check_count "infrastructure.md test count" "$actual_tests" "$infra_tests" "$infrastructure"
    fi

    echo ""

    # Print summary
    echo -e "${YELLOW}=== Summary ===${NC}"
    echo "Total checks: $TOTAL_CHECKS"
    echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "${RED}Failed: $FAILED_CHECKS${NC}"

    if [ $TOTAL_CHECKS -eq 0 ]; then
        echo -e "\n${YELLOW}No checks performed. This might indicate an issue with the script.${NC}"
        return 1
    fi

    if [ $FAILED_CHECKS -gt 0 ]; then
        echo -e "\n${RED}Documentation counts do not match actual counts!${NC}"
        echo "Please update the following files to reflect:"
        echo "  - Actual templates: $actual_templates"
        echo "  - Actual tests: $actual_tests"
        return 1
    fi

    echo -e "\n${GREEN}All documentation counts are accurate!${NC}"
    return 0
}

# Run main function
main "$@"
