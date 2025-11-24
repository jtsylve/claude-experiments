#!/usr/bin/env bash
# Purpose: Verify meta-prompt plugin installation
# Usage: ./verify-installation.sh
# Exits: 0 if installation is valid, 1 if issues found

set -euo pipefail

# ANSI colors (only use if terminal supports them)
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    NC=''
fi

# Setup: Set CLAUDE_PLUGIN_ROOT if not already set
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

echo -e "${YELLOW}Meta-Prompt Installation Verification${NC}"
echo "========================================"
echo ""
echo "Plugin root: $CLAUDE_PLUGIN_ROOT"
echo ""

# Track issues
ISSUES_FOUND=0

# Check if plugin root exists
if [ ! -d "$CLAUDE_PLUGIN_ROOT" ]; then
    echo -e "${RED}✗ ERROR: Plugin directory not found at: $CLAUDE_PLUGIN_ROOT${NC}"
    echo ""
    echo "Expected installation locations:"
    echo "  - Standard: ~/.claude/plugins/marketplaces/claude-experiments/meta-prompt"
    echo "  - Development: <repo-clone>/meta-prompt"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Plugin directory found${NC}"

# Check critical directories
DIRS=(
    "templates"
    "commands"
    "commands/scripts"
    "agents"
    "guides"
    "tests"
)

for dir in "${DIRS[@]}"; do
    if [ -d "$CLAUDE_PLUGIN_ROOT/$dir" ]; then
        echo -e "${GREEN}✓${NC} Directory exists: $dir"
    else
        echo -e "${RED}✗${NC} Missing directory: $dir"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
done

echo ""

# Check critical scripts
SCRIPTS=(
    "commands/scripts/prompt-handler.sh"
    "scripts/common.sh"
    "agents/scripts/prompt-optimizer-handler.sh"
    "agents/scripts/template-selector-handler.sh"
    "agents/scripts/template-executor-handler.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$CLAUDE_PLUGIN_ROOT/$script" ]; then
        if [ -x "$CLAUDE_PLUGIN_ROOT/$script" ]; then
            echo -e "${GREEN}✓${NC} Script exists and is executable: $script"
        else
            echo -e "${YELLOW}⚠${NC}  Script exists but not executable: $script"
            echo "   Run: chmod +x $CLAUDE_PLUGIN_ROOT/$script"
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
        fi
    else
        echo -e "${RED}✗${NC} Missing script: $script"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
done

echo ""

# Check templates (should have 6 templates + custom)
EXPECTED_TEMPLATES=(
    "code-refactoring.md"
    "code-review.md"
    "test-generation.md"
    "documentation-generator.md"
    "data-extraction.md"
    "code-comparison.md"
    "custom.md"
)

for template in "${EXPECTED_TEMPLATES[@]}"; do
    if [ -f "$CLAUDE_PLUGIN_ROOT/templates/$template" ]; then
        echo -e "${GREEN}✓${NC} Template exists: $template"
    else
        echo -e "${RED}✗${NC} Missing template: $template"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
done

echo ""

# Summary
echo "========================================"
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ Installation verified successfully!${NC}"
    echo ""
    echo "You can use the meta-prompt plugin with:"
    echo "  /prompt <task description>"
    echo "  /create-prompt <task description>"
    exit 0
else
    echo -e "${RED}✗ Found $ISSUES_FOUND issue(s) with installation${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Ensure the plugin is installed via: /plugin install jtsylve/claude-experiments"
    echo "  2. For development, run: chmod +x commands/scripts/*.sh tests/*.sh"
    echo "  3. See docs/infrastructure.md for detailed setup instructions"
    exit 1
fi
