#!/usr/bin/env bash
# Purpose: Load templates and substitute variables
# Inputs: $1=template_name, $2+=variable_values (as key=value pairs)
# Outputs: Processed template ready for execution

set -euo pipefail

# Setup: Set CLAUDE_PLUGIN_ROOT if not already set
# TEMPORARY: For Windows compatibility, fallback to script-based location or hardcoded path
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    # Try to derive from script location (commands/scripts/ -> 2 levels up)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -d "$SCRIPT_DIR/../../templates" ]; then
        CLAUDE_PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    else
        # Fallback to hardcoded path for standard installation
        CLAUDE_PLUGIN_ROOT="$HOME/.claude/plugins/marketplaces/claude-experiments/meta-prompt"
    fi
fi

TEMPLATE_DIR="${CLAUDE_PLUGIN_ROOT}/templates"

# Function: Load template file
load_template() {
    local template_name="$1"
    local template_path="$TEMPLATE_DIR/${template_name}.md"

    if [ ! -f "$template_path" ]; then
        echo "ERROR: Template not found: $template_path" >&2
        return 1
    fi

    cat "$template_path"
}

# Function: Extract variables from template
extract_variables() {
    local template="$1"
    # Find all {$VARIABLE} patterns
    local vars=$(echo "$template" | grep -oE '\{\$[A-Z_][A-Z0-9_]*\}' 2>/dev/null || true)
    if [ -z "$vars" ] && echo "$template" | grep -q '^\-\-\-$'; then
        # Template has YAML frontmatter but no variables - this is valid
        return 0
    fi
    echo "$vars" | sort -u | sed 's/[{}$]//g'
}

# Function: Escape special characters in variable values
escape_value() {
    local value="$1"
    # Escape backslashes first, then dollar signs, backticks, and double quotes
    printf '%s\n' "$value" | sed 's/\\/\\\\/g; s/\$/\\$/g; s/`/\\`/g; s/"/\\"/g'
}

# Function: Substitute variables in template
substitute_variables() {
    local template="$1"
    shift

    # Process each key=value pair
    for arg in "$@"; do
        if [[ "$arg" =~ ^([A-Z_][A-Z0-9_]*)=(.*)$ ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local var_value_raw="${BASH_REMATCH[2]}"

            # Escape special characters to prevent injection
            local var_value=$(escape_value "$var_value_raw")

            # Replace {$VAR_NAME} with escaped value
            template="${template//\{\$${var_name}\}/$var_value}"
        else
            echo "ERROR: Invalid variable format: $arg (expected VAR_NAME=value)" >&2
            return 1
        fi
    done

    echo "$template"
}

# Function: Process default values for optional variables
# Note: Default values cannot contain closing braces. If a default value needs
# to contain a closing brace, it should be escaped or documented as a limitation.
process_defaults() {
    local template="$1"
    local iteration_count=0
    local max_iterations=100

    # Extract all variables with defaults and their values
    # Pattern matches {$VAR_NAME:default_value} where default_value cannot contain }
    # This is a safe limitation as closing braces are rarely needed in defaults
    while [[ "$template" =~ \{\$([A-Z_][A-Z0-9_]*):([^}]*)\} ]]; do
        # Prevent infinite loops
        iteration_count=$((iteration_count + 1))
        if [ $iteration_count -gt $max_iterations ]; then
            echo "ERROR: Maximum iterations ($max_iterations) exceeded in process_defaults. Possible infinite loop." >&2
            return 1
        fi

        local var_name="${BASH_REMATCH[1]}"
        local default_value="${BASH_REMATCH[2]}"

        # Escape special characters in default value for sed replacement string
        # Must escape sed metacharacters: & (backreference), / (delimiter), \ (escape), ( and ) (grouping)
        # and shell metacharacters: $ (variable), ` (command substitution), " (quoting) to prevent injection
        local escaped_default=$(printf '%s\n' "$default_value" | sed 's/[\\&/()$`"]/\\&/g')

        # The sed pattern below matches {$VAR} and {$VAR:default}
        # We use single quotes and concatenate the variable name for clarity and portability
        template=$(echo "$template" | sed -E 's/\{\$'"${var_name}"'(:[^}]*)?\}/'"${escaped_default}"'/g')
    done

    echo "$template"
}

# Function: Validate template (check for unreplaced variables)
validate_template() {
    local template="$1"

    # Check for any remaining {$VARIABLE} patterns (without defaults)
    local unreplaced=$(echo "$template" | grep -oE '\{\$[A-Z_][A-Z0-9_]*\}' || true)

    if [ -n "$unreplaced" ]; then
        echo "ERROR: Template has unreplaced variables:" >&2
        echo "$unreplaced" | sed 's/[{}$]//g' >&2
        return 1
    fi

    return 0
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <template_name> [VAR1=value1] [VAR2=value2] ..." >&2
        echo "" >&2
        echo "Example: $0 simple-classification ITEM1='apple' ITEM2='orange' CLASSIFICATION_CRITERIA='same fruit'" >&2
        return 1
    fi

    local template_name="$1"
    shift

    # Load template
    local template
    template=$(load_template "$template_name") || return 1

    # Substitute variables if provided
    if [ $# -gt 0 ]; then
        template=$(substitute_variables "$template" "$@") || return 1
    fi

    # Process default values for any remaining optional variables
    template=$(process_defaults "$template")

    # Validate that all required variables have been replaced
    validate_template "$template" || return 1

    # Output processed template
    echo "$template"
}

# Run main function
main "$@"
