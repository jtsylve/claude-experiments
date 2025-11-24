#!/usr/bin/env bash
# Purpose: State machine for prompt-optimizer agent with integrated template processing
# Inputs: XML input via stdin containing user_task, template, execution_mode
# Outputs: Instructions with template content and variable extraction guidance
# Architecture: Incorporates template-processor.sh logic directly (no external bash calls needed)

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../scripts/common.sh"

# Setup plugin root
setup_plugin_root

TEMPLATE_DIR="${CLAUDE_PLUGIN_ROOT}/templates"

# Parse XML input from command-line argument (supports multiline content)
read_xml_input() {
    local xml_input="$1"

    # Validate input provided
    if [ -z "$xml_input" ]; then
        echo "Error: No input provided. Usage: $0 '<xml-input>'" >&2
        exit 1
    fi

    # Extract required fields using common functions
    local user_task
    user_task=$(require_xml_field "$xml_input" "user_task" "auto") || exit 1

    local template
    template=$(require_xml_field "$xml_input" "template") || {
        echo "Error: Template selection must be done before calling prompt-optimizer." >&2
        exit 1
    }

    # Extract optional field with default
    local execution_mode
    execution_mode=$(optional_xml_field "$xml_input" "execution_mode" "direct")

    # Validate execution_mode
    if [ "$execution_mode" != "plan" ] && [ "$execution_mode" != "direct" ]; then
        echo "Error: Invalid execution_mode: $execution_mode (must be 'plan' or 'direct')" >&2
        exit 1
    fi

    # Export safely (without sanitization for USER_TASK to preserve content, but sanitize for output)
    export USER_TASK="$user_task"
    export TEMPLATE="$template"
    export EXECUTION_MODE="$execution_mode"
}

# Map template name to skill name
get_skill_for_template() {
    local template=$1
    
    case "$template" in
        code-refactoring)
            echo "meta-prompt:code-refactoring"
            ;;
        code-review)
            echo "meta-prompt:code-review"
            ;;
        test-generation)
            echo "meta-prompt:test-generation"
            ;;
        documentation-generator)
            echo "meta-prompt:documentation-generator"
            ;;
        data-extraction)
            echo "meta-prompt:data-extraction"
            ;;
        code-comparison)
            echo "meta-prompt:code-comparison"
            ;;
        custom)
            echo "none"
            ;;
        *)
            echo "none"
            ;;
    esac
}

# Load template file with improved error messages
load_template() {
    local template_name="$1"
    local template_path="$TEMPLATE_DIR/${template_name}.md"

    # Check if file exists
    if [ ! -f "$template_path" ]; then
        echo "Error: Template file not found: $template_path" >&2
        echo "" >&2
        echo "Available templates in $TEMPLATE_DIR:" >&2
        if [ -d "$TEMPLATE_DIR" ]; then
            ls -1 "$TEMPLATE_DIR"/*.md 2>/dev/null | sed 's/.*\//  - /' | sed 's/\.md$//' >&2 || echo "  (none found)" >&2
        else
            echo "  Error: Template directory does not exist: $TEMPLATE_DIR" >&2
        fi
        echo "" >&2
        echo "Requested template: $template_name" >&2
        return 1
    fi

    # Check if file is readable
    if [ ! -r "$template_path" ]; then
        echo "Error: Template file not readable: $template_path" >&2
        echo "Check file permissions." >&2
        return 1
    fi

    # Check if file is non-empty
    if [ ! -s "$template_path" ]; then
        echo "Error: Template file is empty: $template_path" >&2
        echo "Template files must contain prompt content." >&2
        return 1
    fi

    cat "$template_path"
}

# Extract variables from template content
extract_variables() {
    local template="$1"
    # Find all {$VARIABLE} and {$VARIABLE:default} patterns
    # Output format: VARIABLE (required) or VARIABLE:default (optional)
    echo "$template" | grep -oE '\{\$[A-Z_][A-Z0-9_]*(:[^}]*)?\}' 2>/dev/null | sort -u | sed 's/[{}$]//g' || true
}

# Escape special characters for output
escape_for_output() {
    local value="$1"
    # Escape for safe display in instructions (including $ for heredoc safety)
    printf '%s\n' "$value" | sed 's/\\/\\\\/g; s/\$/\\$/g; s/`/\\`/g; s/"/\\"/g'
}

# Generate instructions for processing the template
generate_instructions() {
    local sanitized_task=$(sanitize_input "$USER_TASK")
    local skill=$(get_skill_for_template "$TEMPLATE")

    # Load template content
    local template_content
    template_content=$(load_template "$TEMPLATE") || {
        echo "Error: Failed to load template '$TEMPLATE'" >&2
        exit 1
    }

    # Extract variables from template
    local variables
    variables=$(extract_variables "$template_content")

    # Escape template content for safe output
    local escaped_template=$(escape_for_output "$template_content")

    # Parse variables into required and optional lists
    local required_vars=""
    local optional_vars=""

    while IFS= read -r var; do
        if [ -z "$var" ]; then
            continue
        fi

        if [[ "$var" == *:* ]]; then
            # Variable has default value (optional)
            local var_name="${var%%:*}"
            # Note: default value is preserved in template, not extracted here
            if [ -n "$optional_vars" ]; then
                optional_vars="$optional_vars, $var_name"
            else
                optional_vars="$var_name"
            fi
        else
            # No default value (required)
            if [ -n "$required_vars" ]; then
                required_vars="$required_vars, $var"
            else
                required_vars="$var"
            fi
        fi
    done <<< "$variables"

    cat <<EOF
Template: $TEMPLATE (already selected)
Skill: $skill
Execution mode: $EXECUTION_MODE

TASK: Extract variables from the user task and substitute them into the template.

User task: $sanitized_task

## Template Variables

$(if [ -n "$required_vars" ]; then echo "Required: $required_vars"; fi)
$(if [ -n "$optional_vars" ]; then echo "Optional: $optional_vars"; fi)
$(if [ -z "$required_vars" ] && [ -z "$optional_vars" ]; then echo "This template has no variables."; fi)

## Instructions

1. **Extract variable values** from the user task:
   - Analyze the user task to identify values for each variable
   - Required variables must have values
   - Optional variables can use their defaults if not specified in the task
   - Use AskUserQuestion if any required information is unclear

2. **Substitute variables** in the template:
   - Replace each {\\\$VARIABLE} or {\\\$VARIABLE:default} with its value
   - For optional variables without values, use their default
   - Ensure all {\\\$...} patterns are replaced

3. **Output the result** in this XML format:

\`\`\`xml
<prompt_optimizer_result>
<template>$TEMPLATE</template>
<skill>$skill</skill>
<execution_mode>$EXECUTION_MODE</execution_mode>
<optimized_prompt>
[Insert the complete processed template here with all variables substituted]
</optimized_prompt>
</prompt_optimizer_result>
\`\`\`

## Template Content

\`\`\`
$escaped_template
\`\`\`

IMPORTANT:
- The <optimized_prompt> must contain the COMPLETE template with ALL variables replaced
- Do NOT include the YAML frontmatter (lines between ---) in the final output
- Ensure no {\\\$VARIABLE} patterns remain in the output
EOF
}

# Main function
main() {
    # Check for command-line argument
    if [ $# -eq 0 ]; then
        echo "Error: No input provided. Usage: $0 '<xml-input>'" >&2
        exit 1
    fi

    # Read and parse XML input from first argument
    read_xml_input "$1"

    # Generate and output instructions
    generate_instructions
}

# Run main function
main "$@"
