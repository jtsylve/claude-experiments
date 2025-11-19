#!/bin/bash
# Purpose: Shared utility functions for meta-prompt scripts
# Provides cross-platform path normalization and environment setup

# Normalize path to Unix-style (handles Windows paths in bash environments)
# Supports:
#   - Git Bash on Windows (uses cygpath if available)
#   - WSL (paths already Unix-style)
#   - Cygwin (uses cygpath)
#   - Linux/macOS (paths already Unix-style)
#
# Args:
#   $1 - Path to normalize (may contain backslashes or Windows drive letters)
# Returns:
#   Normalized Unix-style path
normalize_path() {
    local path="$1"

    # If path is empty, return empty
    if [ -z "$path" ]; then
        echo ""
        return 0
    fi

    # If cygpath is available (Git Bash, Cygwin), use it for proper conversion
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -u "$path" 2>/dev/null || echo "$path"
        return 0
    fi

    # Fallback: manual conversion for environments without cygpath
    # 1. Convert backslashes to forward slashes
    # 2. Handle Windows drive letters (C: -> /c/ for Git Bash compatibility)
    # 3. Collapse multiple consecutive slashes into single slash
    local normalized="$path"
    normalized=$(echo "$normalized" | sed 's|\\|/|g')

    # Convert Windows drive letter format (C:/ -> /c/)
    # This works for Git Bash which expects /c/ style paths
    if echo "$normalized" | grep -qE '^[A-Za-z]:'; then
        normalized=$(echo "$normalized" | sed 's|^\([A-Za-z]\):|/\L\1|')
    fi

    # Collapse multiple consecutive forward slashes into single slash
    # This handles cases where Windows paths had escaped backslashes (\\)
    normalized=$(echo "$normalized" | sed 's|//*|/|g')

    echo "$normalized"
}

# Validate and normalize CLAUDE_PLUGIN_ROOT environment variable
# This function must be called at the start of scripts using CLAUDE_PLUGIN_ROOT
# Side effects:
#   - Exports normalized CLAUDE_PLUGIN_ROOT
#   - Exits with error if CLAUDE_PLUGIN_ROOT is not set
# Returns:
#   0 on success, 1 on failure
init_plugin_root() {
    # Check if CLAUDE_PLUGIN_ROOT is set
    if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
        echo "ERROR: CLAUDE_PLUGIN_ROOT environment variable is not set" >&2
        echo "This variable should be automatically set by Claude Code when running commands." >&2
        echo "If testing manually, set it to the plugin directory path:" >&2
        echo "  export CLAUDE_PLUGIN_ROOT=/path/to/meta-prompt" >&2
        return 1
    fi

    # Normalize the path for cross-platform compatibility
    local normalized_root
    normalized_root=$(normalize_path "${CLAUDE_PLUGIN_ROOT}")

    if [ -z "$normalized_root" ]; then
        echo "ERROR: Failed to normalize CLAUDE_PLUGIN_ROOT path" >&2
        return 1
    fi

    # Export the normalized version
    export CLAUDE_PLUGIN_ROOT="$normalized_root"

    # Verify the directory exists
    if [ ! -d "$CLAUDE_PLUGIN_ROOT" ]; then
        echo "ERROR: CLAUDE_PLUGIN_ROOT directory does not exist: $CLAUDE_PLUGIN_ROOT" >&2
        return 1
    fi

    return 0
}

# Get the absolute path to the script directory
# This is useful for scripts that need to reference other scripts in the same directory
# Returns:
#   Absolute path to the directory containing the calling script
get_script_dir() {
    local source="${BASH_SOURCE[1]}"
    local dir

    # Resolve symlinks
    while [ -h "$source" ]; do
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done

    dir="$(cd -P "$(dirname "$source")" && pwd)"
    echo "$dir"
}
