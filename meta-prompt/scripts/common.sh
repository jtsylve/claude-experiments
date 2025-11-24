#!/usr/bin/env bash
# Purpose: Shared utility functions for meta-prompt handler scripts
# Usage: Source this file in handler scripts
#   From agents/scripts/: . "$(dirname "$0")/../../scripts/common.sh"
#   From commands/scripts/: . "$(dirname "$0")/../../scripts/common.sh"

# Check bash version (require 3.2+ for macOS compatibility)
check_bash_version() {
    local required_major=3
    local required_minor=2
    local bash_version="${BASH_VERSION%%.*}"
    local bash_minor="${BASH_VERSION#*.}"
    bash_minor="${bash_minor%%.*}"

    if [ "$bash_version" -lt "$required_major" ] || \
       { [ "$bash_version" -eq "$required_major" ] && [ "$bash_minor" -lt "$required_minor" ]; }; then
        echo "Error: Bash $required_major.$required_minor or higher required (found $BASH_VERSION)" >&2
        echo "Please upgrade bash or use a compatible shell." >&2
        return 1
    fi
}

# Run version check when common.sh is sourced
check_bash_version || exit 1

# Sanitize input to prevent command injection
# Escapes backslashes, dollar signs, and backticks
sanitize_input() {
    local input="$1"
    # Escape backslashes first, then dollar signs and backticks
    printf '%s\n' "$input" | sed 's/\\/\\\\/g; s/\$/\\$/g; s/`/\\`/g'
}

# Escape XML special characters
# Escapes <, >, &, ", and ' for safe XML output
escape_xml() {
    local input="$1"
    printf '%s\n' "$input" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'\''/\&apos;/g'
}

# ============================================================================
# XML Parsing Functions
# ============================================================================
#
# LIMITATIONS:
# - These functions use sed for simple XML extraction and do NOT provide
#   full XML parsing capabilities
# - Assumes well-formed XML with properly matched opening/closing tags
# - Does NOT handle:
#   * XML namespaces
#   * Nested tags with the same name
#   * XML attributes
#   * CDATA sections
#   * XML entities beyond basic text
#   * Malformed or incomplete XML (will fail silently or return empty)
#
# WHEN TO USE:
# - For simple, predictable XML structures (like our agent communication)
# - When you control both the XML generation and parsing
#
# WHEN NOT TO USE:
# - For complex XML documents
# - For untrusted or external XML sources
# - When you need schema validation
#
# For complex XML parsing needs, consider using xmllint, xq, or jq alternatives.
# ============================================================================

# Extract a simple XML element value (single-line content only)
# Usage: extract_xml_value "<xml>content</xml>" "xml"
# Returns: "content"
# Note: Uses sed capture group to extract content between tags
#       Pattern: .*<tag>\(.*\)</tag>.*  where \(...\) captures the content
extract_xml_value() {
    local xml="$1"
    local element="$2"
    echo "$xml" | sed -n "s/.*<$element>\(.*\)<\/$element>.*/\1/p"
}

# Extract multiline XML element content
# Usage: extract_xml_multiline "<root><el>line1\nline2</el></root>" "el"
# Returns: "line1\nline2"
# Note: Two-step process:
#       1. sed -n '/<tag>/,/<\/tag>/p' prints lines from opening to closing tag
#       2. sed '1d;$d' deletes first and last line (the tag lines themselves)
extract_xml_multiline() {
    local xml="$1"
    local element="$2"
    echo "$xml" | sed -n "/<$element>/,/<\/$element>/p" | sed '1d;$d'
}

# Validate basic XML well-formedness for a specific tag
# Usage: validate_xml_tag "<xml>content</xml>" "xml"
# Returns: 0 if valid, 1 if malformed
validate_xml_tag() {
    local xml_input="$1"
    local tag_name="$2"

    # Check if opening tag exists
    if ! echo "$xml_input" | grep -q "<$tag_name>"; then
        return 1
    fi

    # Check if closing tag exists
    if ! echo "$xml_input" | grep -q "</$tag_name>"; then
        echo "Error: Malformed XML - missing closing tag: </$tag_name>" >&2
        return 1
    fi

    # Count opening and closing tags (basic check for balance)
    local open_count=$(echo "$xml_input" | grep -o "<$tag_name>" | wc -l | tr -d ' ')
    local close_count=$(echo "$xml_input" | grep -o "</$tag_name>" | wc -l | tr -d ' ')

    if [ "$open_count" -ne "$close_count" ]; then
        echo "Error: Malformed XML - unbalanced tags for: $tag_name (open=$open_count, close=$close_count)" >&2
        return 1
    fi

    return 0
}

# Parse XML tag with automatic detection of single-line vs multiline content
# Usage: parse_xml_tag "<xml>content</xml>" "xml" [multiline|auto]
# Returns: tag content, or empty string if not found
# Mode: multiline (force multiline), auto (detect, default)
#
# Auto-detection logic:
#   - Searches for pattern: <tag>content</tag> (all on one line)
#   - If found: treats as single-line and uses simple extraction
#   - If not found: treats as multiline and preserves internal formatting
parse_xml_tag() {
    local xml_input="$1"
    local tag_name="$2"
    local mode="${3:-auto}"

    # Validate XML structure first (ensures balanced tags)
    if ! validate_xml_tag "$xml_input" "$tag_name" 2>/dev/null; then
        return 1
    fi

    # Determine if content is multiline
    local is_multiline=false
    if [ "$mode" = "multiline" ]; then
        is_multiline=true
    elif [ "$mode" = "auto" ]; then
        # Check if opening and closing tags are on same line
        if echo "$xml_input" | grep -q "<$tag_name>.*</$tag_name>"; then
            is_multiline=false
        else
            is_multiline=true
        fi
    fi

    # Extract based on content type
    if [ "$is_multiline" = "true" ]; then
        extract_xml_multiline "$xml_input" "$tag_name"
    else
        extract_xml_value "$xml_input" "$tag_name"
    fi
}

# Validate required XML field and extract value
# Usage: require_xml_field "<xml>..." "field_name" [multiline|auto]
# Returns: field value on success, exits with error on failure
# Sets global variable: ${FIELD_NAME}_VALUE
require_xml_field() {
    local xml_input="$1"
    local field_name="$2"
    local mode="${3:-auto}"

    local value
    value=$(parse_xml_tag "$xml_input" "$field_name" "$mode") || {
        echo "Error: Missing required field: $field_name" >&2
        return 1
    }

    if [ -z "$value" ]; then
        echo "Error: Required field is empty: $field_name" >&2
        return 1
    fi

    echo "$value"
}

# Parse optional XML field with default value
# Usage: optional_xml_field "<xml>..." "field_name" "default_value" [multiline|auto]
# Returns: field value if present, default value otherwise
optional_xml_field() {
    local xml_input="$1"
    local field_name="$2"
    local default_value="$3"
    local mode="${4:-auto}"

    local value
    value=$(parse_xml_tag "$xml_input" "$field_name" "$mode") || {
        echo "$default_value"
        return 0
    }

    if [ -z "$value" ]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

# Sanitize and export variable safely
# Usage: safe_export "VAR_NAME" "value"
# Sanitizes value before exporting to environment
safe_export() {
    local var_name="$1"
    local value="$2"
    local sanitized_value

    sanitized_value=$(sanitize_input "$value")
    export "$var_name=$sanitized_value"
}

# Setup CLAUDE_PLUGIN_ROOT if not already set
# Tries script location first, then falls back to standard installation path
# This function should be called from handler scripts
#
# Resolution order:
#   1. Use existing CLAUDE_PLUGIN_ROOT env var if set
#   2. Detect from calling script location (works for dev and installed contexts)
#   3. Fall back to standard installation path: ~/.claude/plugins/...
#
# Validates that the resolved path contains required plugin structure
setup_plugin_root() {
    if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
        # Get the calling script's directory with error handling
        local calling_script_dir
        if ! calling_script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" 2>/dev/null && pwd)"; then
            echo "Error: Unable to determine calling script directory" >&2
            return 1
        fi

        # Determine path to plugin root based on calling script location
        # Could be from agents/scripts/ or commands/scripts/ or tests/
        local potential_root=""
        if [[ "$calling_script_dir" == */agents/scripts ]]; then
            # Called from agents/scripts/ -> go up 2 levels
            potential_root="$(cd "$calling_script_dir/../.." 2>/dev/null && pwd)" || potential_root=""
        elif [[ "$calling_script_dir" == */commands/scripts ]]; then
            # Called from commands/scripts/ -> go up 2 levels
            potential_root="$(cd "$calling_script_dir/../.." 2>/dev/null && pwd)" || potential_root=""
        elif [[ "$calling_script_dir" == */tests ]]; then
            # Called from tests/ -> go up 1 level
            potential_root="$(cd "$calling_script_dir/.." 2>/dev/null && pwd)" || potential_root=""
        fi

        # Validate the potential root has required structure
        if [ -n "$potential_root" ] && [ -d "$potential_root/templates" ] && [ -f "$potential_root/templates/custom.md" ]; then
            CLAUDE_PLUGIN_ROOT="$potential_root"
        else
            # Fallback to hardcoded path for standard installation
            CLAUDE_PLUGIN_ROOT="$HOME/.claude/plugins/marketplaces/claude-experiments/meta-prompt"
        fi
        export CLAUDE_PLUGIN_ROOT
    fi

    # Validate CLAUDE_PLUGIN_ROOT directory structure
    if [ ! -d "$CLAUDE_PLUGIN_ROOT" ]; then
        echo "Error: CLAUDE_PLUGIN_ROOT directory does not exist: $CLAUDE_PLUGIN_ROOT" >&2
        echo "Please ensure the meta-prompt plugin is properly installed." >&2
        echo "" >&2
        echo "To fix:" >&2
        echo "  - Set CLAUDE_PLUGIN_ROOT environment variable to the correct path" >&2
        echo "  - Or reinstall the plugin to: ~/.claude/plugins/marketplaces/claude-experiments/meta-prompt" >&2
        return 1
    fi

    if [ ! -d "$CLAUDE_PLUGIN_ROOT/templates" ]; then
        echo "Error: Templates directory not found: $CLAUDE_PLUGIN_ROOT/templates" >&2
        echo "Plugin directory structure may be corrupted. Please reinstall the plugin." >&2
        return 1
    fi

    if [ ! -f "$CLAUDE_PLUGIN_ROOT/templates/custom.md" ]; then
        echo "Error: Required template file not found: $CLAUDE_PLUGIN_ROOT/templates/custom.md" >&2
        echo "Plugin directory structure may be corrupted. Please reinstall the plugin." >&2
        return 1
    fi

    return 0
}
