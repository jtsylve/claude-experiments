#!/usr/bin/env bash
# Purpose: Shared utility functions for meta-prompt handler scripts
# Usage: Source this file in handler scripts
#   From agents/scripts/: . "$(dirname "$0")/../../scripts/common.sh"
#   From commands/scripts/: . "$(dirname "$0")/../../scripts/common.sh"

# Sanitize input to prevent command injection
# Escapes backslashes, dollar signs, and backticks
sanitize_input() {
    local input="$1"
    # Escape backslashes first, then dollar signs and backticks
    printf '%s\n' "$input" | sed 's/\\/\\\\/g; s/\$/\\$/g; s/`/\\`/g'
}

# Extract a simple XML element value (single-line content only)
# Usage: extract_xml_value "<xml>content</xml>" "xml"
# Returns: "content"
extract_xml_value() {
    local xml="$1"
    local element="$2"
    echo "$xml" | sed -n "s/.*<$element>\(.*\)<\/$element>.*/\1/p"
}

# Extract multiline XML element content
# Usage: extract_xml_multiline "<root><el>line1\nline2</el></root>" "el"
# Returns: "line1\nline2"
extract_xml_multiline() {
    local xml="$1"
    local element="$2"
    echo "$xml" | sed -n "/<$element>/,/<\/$element>/p" | sed '1d;$d'
}

# Setup CLAUDE_PLUGIN_ROOT if not already set
# Tries script location first, then falls back to standard installation path
# This function should be called from handler scripts
setup_plugin_root() {
    if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
        # Get the calling script's directory
        local calling_script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"

        # Determine path to plugin root based on calling script location
        # Could be from agents/scripts/ or commands/scripts/
        local potential_root=""
        if [[ "$calling_script_dir" == */agents/scripts ]]; then
            # Called from agents/scripts/ -> go up 2 levels
            potential_root="$(cd "$calling_script_dir/../.." && pwd)"
        elif [[ "$calling_script_dir" == */commands/scripts ]]; then
            # Called from commands/scripts/ -> go up 2 levels
            potential_root="$(cd "$calling_script_dir/../.." && pwd)"
        fi

        # Validate the potential root has templates
        if [ -n "$potential_root" ] && [ -d "$potential_root/templates" ] && [ -f "$potential_root/templates/custom.md" ]; then
            CLAUDE_PLUGIN_ROOT="$potential_root"
        else
            # Fallback to hardcoded path for standard installation
            CLAUDE_PLUGIN_ROOT="$HOME/.claude/plugins/marketplaces/claude-experiments/meta-prompt"
        fi
        export CLAUDE_PLUGIN_ROOT
    fi
}
