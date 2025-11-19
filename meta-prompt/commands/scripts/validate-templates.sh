#!/usr/bin/env bash
# Purpose: Validate template files for syntax and completeness
# Inputs: Optional template name (validates all if not specified)
# Outputs: Validation results and errors

set -euo pipefail

# Validate required environment variables
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    echo "ERROR: CLAUDE_PLUGIN_ROOT environment variable is not set" >&2
    exit 1
fi

# Normalize path (convert backslashes to forward slashes for Windows/WSL)
CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT//\\//}"

TEMPLATE_DIR="${CLAUDE_PLUGIN_ROOT}/templates"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation results
TOTAL_TEMPLATES=0
PASSED_TEMPLATES=0
FAILED_TEMPLATES=0

# Function: Extract YAML frontmatter
extract_frontmatter() {
    local file="$1"
    # Extract content between --- markers
    awk '/^---$/{f=!f;next} f' "$file" | head -n 20
}

# Function: Extract template body (after frontmatter)
extract_body() {
    local file="$1"
    # Skip frontmatter and extract rest
    awk '/^---$/{c++} c==2{print; next} c>2' "$file"
}

# Function: Get variables from frontmatter
get_declared_variables() {
    local frontmatter="$1"
    echo "$frontmatter" | grep "^variables:" | sed 's/variables: \[\(.*\)\]/\1/' | tr ',' '\n' | sed 's/[][ ]//g'
}

# Function: Get variables used in body
get_used_variables() {
    local body="$1"
    echo "$body" | grep -oE '\{\$[A-Z_][A-Z0-9_]*\}' | sed 's/[{}$]//g' | sort -u
}

# Function: Validate single template
validate_template() {
    local template_file="$1"
    local template_name="$(basename "$template_file" .md)"
    local has_errors=false

    echo -e "${YELLOW}Validating: $template_name${NC}"

    # Check if file exists and is readable
    if [ ! -f "$template_file" ] || [ ! -r "$template_file" ]; then
        echo -e "  ${RED}✗${NC} File not found or not readable"
        return 1
    fi

    # Extract frontmatter and body
    local frontmatter=$(extract_frontmatter "$template_file")
    local body=$(extract_body "$template_file")

    # Check 1: Has valid frontmatter
    if [ -z "$frontmatter" ]; then
        echo -e "  ${RED}✗${NC} Missing YAML frontmatter"
        has_errors=true
    else
        echo -e "  ${GREEN}✓${NC} Has valid frontmatter"
    fi

    # Check 2: Required frontmatter fields
    for field in template_name category keywords complexity variables version description; do
        if echo "$frontmatter" | grep -q "^${field}:"; then
            echo -e "  ${GREEN}✓${NC} Has required field: $field"
        else
            echo -e "  ${RED}✗${NC} Missing required field: $field"
            has_errors=true
        fi
    done

    # Check 3: Variables declared vs used
    local declared_vars=$(get_declared_variables "$frontmatter")
    local used_vars=$(get_used_variables "$body")

    if [ -n "$declared_vars" ] && [ -n "$used_vars" ]; then
        # Check if all declared variables are used
        while IFS= read -r var; do
            if echo "$used_vars" | grep -q "^${var}$"; then
                echo -e "  ${GREEN}✓${NC} Variable declared and used: $var"
            else
                echo -e "  ${YELLOW}⚠${NC} Variable declared but not used: $var"
            fi
        done <<< "$declared_vars"

        # Check if all used variables are declared
        while IFS= read -r var; do
            if echo "$declared_vars" | grep -q "^${var}$"; then
                : # Already checked above
            else
                echo -e "  ${RED}✗${NC} Variable used but not declared: $var"
                has_errors=true
            fi
        done <<< "$used_vars"
    fi

    # Check 4: Balanced XML tags in body
    local opening_tags=$(echo "$body" | grep -oE '<[a-z_][a-z0-9_]*>' | sort)
    local closing_tags=$(echo "$body" | grep -oE '</[a-z_][a-z0-9_]*>' | sed 's|/||' | sort)

    if [ "$opening_tags" != "$closing_tags" ]; then
        echo -e "  ${YELLOW}⚠${NC} Potentially unbalanced XML tags"
    else
        echo -e "  ${GREEN}✓${NC} XML tags appear balanced"
    fi

    # Check 5: Template has content
    if [ -z "$body" ]; then
        echo -e "  ${RED}✗${NC} Template body is empty"
        has_errors=true
    else
        local line_count=$(echo "$body" | wc -l | tr -d ' ')
        echo -e "  ${GREEN}✓${NC} Template has content ($line_count lines)"
    fi

    # Return status
    if [ "$has_errors" = true ]; then
        echo -e "${RED}FAILED: $template_name${NC}\n"
        return 1
    else
        echo -e "${GREEN}PASSED: $template_name${NC}\n"
        return 0
    fi
}

# Main function
main() {
    echo -e "${YELLOW}=== Template Validation ===${NC}\n"

    if [ $# -eq 1 ]; then
        # Validate specific template
        local template_file="$TEMPLATE_DIR/$1.md"
        TOTAL_TEMPLATES=1
        if validate_template "$template_file"; then
            PASSED_TEMPLATES=1
        else
            FAILED_TEMPLATES=1
        fi
    else
        # Validate all templates
        for template_file in "$TEMPLATE_DIR"/*.md; do
            if [ -f "$template_file" ]; then
                TOTAL_TEMPLATES=$((TOTAL_TEMPLATES + 1))
                if validate_template "$template_file"; then
                    PASSED_TEMPLATES=$((PASSED_TEMPLATES + 1))
                else
                    FAILED_TEMPLATES=$((FAILED_TEMPLATES + 1))
                fi
            fi
        done
    fi

    # Print summary
    echo -e "${YELLOW}=== Summary ===${NC}"
    echo "Total templates: $TOTAL_TEMPLATES"
    echo -e "${GREEN}Passed: $PASSED_TEMPLATES${NC}"
    echo -e "${RED}Failed: $FAILED_TEMPLATES${NC}"

    # Exit with error if any failed
    if [ $FAILED_TEMPLATES -gt 0 ]; then
        return 1
    fi
    return 0
}

# Run main function
main "$@"
