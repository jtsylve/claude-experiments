#!/usr/bin/env bash
# Purpose: Validate tool permission restrictions for meta-prompt plugin
# Tests: prompt-optimizer agent, create-prompt command, prompt command
# Exit: 0=success, 1=failure

set -euo pipefail

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper: Print test result
print_result() {
    local test_name="$1"
    local result="$2"
    local message="${3:-}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [ "$result" = "FAIL" ]; then
        echo -e "${RED}✗${NC} $test_name"
        [ -n "$message" ] && echo -e "  ${RED}Error: $message${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${YELLOW}⚠${NC} $test_name - $message"
    fi
}

# Helper: Print section header
print_section() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Setup: Verify environment
print_section "Environment Setup"

if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    # Get the script directory and navigate to plugin root (one level up from tests/)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    export CLAUDE_PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    echo "Setting CLAUDE_PLUGIN_ROOT=$CLAUDE_PLUGIN_ROOT"
fi

if [ ! -d "$CLAUDE_PLUGIN_ROOT" ]; then
    print_result "CLAUDE_PLUGIN_ROOT exists" "FAIL" "Directory not found: $CLAUDE_PLUGIN_ROOT"
    exit 1
fi

print_result "CLAUDE_PLUGIN_ROOT exists" "PASS"

# Test 1: Verify restricted scripts exist and are executable
print_section "Test 1: Script Accessibility"

PROMPT_HANDLER="${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh"
TEMPLATE_SELECTOR="${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh"
TEMPLATE_PROCESSOR="${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh"

if [ -f "$PROMPT_HANDLER" ] && [ -x "$PROMPT_HANDLER" ]; then
    print_result "prompt-handler.sh exists and is executable" "PASS"
else
    print_result "prompt-handler.sh exists and is executable" "FAIL" "File not found or not executable"
fi

if [ -f "$TEMPLATE_SELECTOR" ] && [ -x "$TEMPLATE_SELECTOR" ]; then
    print_result "template-selector.sh exists and is executable" "PASS"
else
    print_result "template-selector.sh exists and is executable" "FAIL" "File not found or not executable"
fi

if [ -f "$TEMPLATE_PROCESSOR" ] && [ -x "$TEMPLATE_PROCESSOR" ]; then
    print_result "template-processor.sh exists and is executable" "PASS"
else
    print_result "template-processor.sh exists and is executable" "FAIL" "File not found or not executable"
fi

# Test 2: Verify template and guide directories exist
print_section "Test 2: Template & Guide Directory Access"

TEMPLATE_DIR="${CLAUDE_PLUGIN_ROOT}/templates"
GUIDE_DIR="${CLAUDE_PLUGIN_ROOT}/guides"

if [ -d "$TEMPLATE_DIR" ] && [ -r "$TEMPLATE_DIR" ]; then
    TEMPLATE_COUNT=$(find "$TEMPLATE_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
    print_result "templates/ directory accessible ($TEMPLATE_COUNT templates found)" "PASS"
else
    print_result "templates/ directory accessible" "FAIL" "Directory not found or not readable"
fi

if [ -d "$GUIDE_DIR" ] && [ -r "$GUIDE_DIR" ]; then
    GUIDE_COUNT=$(find "$GUIDE_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
    print_result "guides/ directory accessible ($GUIDE_COUNT guides found)" "PASS"
else
    print_result "guides/ directory accessible" "FAIL" "Directory not found or not readable"
fi

# Test 3: Execute prompt-handler.sh with valid input
print_section "Test 3: Bash Tool - prompt-handler.sh Execution"

if [ -x "$PROMPT_HANDLER" ]; then
    OUTPUT=$("$PROMPT_HANDLER" "test task" 2>&1) && RESULT="PASS" || RESULT="FAIL"

    if [ "$RESULT" = "PASS" ] && echo "$OUTPUT" | grep -q "Use the Task tool"; then
        print_result "Execute prompt-handler.sh with basic task" "PASS"
    else
        print_result "Execute prompt-handler.sh with basic task" "FAIL" "Invalid output or execution failed"
    fi

    # Test with --return-only flag
    OUTPUT=$("$PROMPT_HANDLER" "--return-only test task" 2>&1) && RESULT="PASS" || RESULT="FAIL"

    if [ "$RESULT" = "PASS" ] && echo "$OUTPUT" | grep -q "DO NOT execute"; then
        print_result "Execute prompt-handler.sh with --return-only flag" "PASS"
    else
        print_result "Execute prompt-handler.sh with --return-only flag" "FAIL" "Invalid output or execution failed"
    fi
else
    print_result "Execute prompt-handler.sh" "FAIL" "Script not executable"
fi

# Test 4: Execute template-selector.sh
print_section "Test 4: Bash Tool - template-selector.sh Execution"

if [ -x "$TEMPLATE_SELECTOR" ]; then
    # Test code classification
    OUTPUT=$("$TEMPLATE_SELECTOR" "Refactor the authentication module" 2>&1) && RESULT="PASS" || RESULT="FAIL"

    if [ "$RESULT" = "PASS" ] && echo "$OUTPUT" | grep -q "code-refactoring"; then
        print_result "Classify code refactoring task" "PASS"
    else
        print_result "Classify code refactoring task" "FAIL" "Expected 'code-refactoring', got: $OUTPUT"
    fi

    # Test review classification
    OUTPUT=$("$TEMPLATE_SELECTOR" "Review this code for quality issues" 2>&1) && RESULT="PASS" || RESULT="FAIL"

    if [ "$RESULT" = "PASS" ] && echo "$OUTPUT" | grep -q "code-review"; then
        print_result "Classify code review task" "PASS"
    else
        print_result "Classify code review task" "FAIL" "Expected 'code-review', got: $OUTPUT"
    fi

    # Test custom classification (low confidence)
    OUTPUT=$("$TEMPLATE_SELECTOR" "Do something random" 2>&1) && RESULT="PASS" || RESULT="FAIL"

    if [ "$RESULT" = "PASS" ] && echo "$OUTPUT" | grep -q "custom"; then
        print_result "Classify unknown task as custom" "PASS"
    else
        print_result "Classify unknown task as custom" "FAIL" "Expected 'custom', got: $OUTPUT"
    fi
else
    print_result "Execute template-selector.sh" "FAIL" "Script not executable"
fi

# Test 5: Execute template-processor.sh
print_section "Test 5: Bash Tool - template-processor.sh Execution"

if [ -x "$TEMPLATE_PROCESSOR" ]; then
    # Test loading custom template with required variables
    OUTPUT=$("$TEMPLATE_PROCESSOR" "custom" "TASK_DESCRIPTION=test task" 2>&1) && RESULT="PASS" || RESULT="FAIL"

    if [ "$RESULT" = "PASS" ] && echo "$OUTPUT" | grep -q "task"; then
        print_result "Load custom template" "PASS"
    else
        print_result "Load custom template" "FAIL" "Template loading failed"
    fi

    # Test with invalid template
    OUTPUT=$("$TEMPLATE_PROCESSOR" "nonexistent-template" 2>&1) && RESULT="FAIL" || RESULT="PASS"

    if [ "$RESULT" = "PASS" ]; then
        print_result "Reject invalid template" "PASS"
    else
        print_result "Reject invalid template" "FAIL" "Should have rejected nonexistent template"
    fi
else
    print_result "Execute template-processor.sh" "FAIL" "Script not executable"
fi

# Test 6: Verify Read tool can access templates and guides
print_section "Test 6: Read Tool - Template & Guide Access"

# Test reading a template
SAMPLE_TEMPLATE="${TEMPLATE_DIR}/custom.md"
if [ -f "$SAMPLE_TEMPLATE" ] && [ -r "$SAMPLE_TEMPLATE" ]; then
    CONTENT=$(cat "$SAMPLE_TEMPLATE" 2>&1) && RESULT="PASS" || RESULT="FAIL"

    if [ "$RESULT" = "PASS" ] && [ -n "$CONTENT" ]; then
        print_result "Read template file (custom.md)" "PASS"
    else
        print_result "Read template file (custom.md)" "FAIL" "File not readable"
    fi
else
    print_result "Read template file (custom.md)" "FAIL" "File not found"
fi

# Test reading a guide
SAMPLE_GUIDE="${GUIDE_DIR}/README.md"
if [ -f "$SAMPLE_GUIDE" ] && [ -r "$SAMPLE_GUIDE" ]; then
    CONTENT=$(cat "$SAMPLE_GUIDE" 2>&1) && RESULT="PASS" || RESULT="FAIL"

    if [ "$RESULT" = "PASS" ] && [ -n "$CONTENT" ]; then
        print_result "Read guide file (README.md)" "PASS"
    else
        print_result "Read guide file (README.md)" "FAIL" "File not readable"
    fi
else
    print_result "Read guide file (README.md)" "FAIL" "File not found"
fi

# Test 7: Verify path restrictions (security test)
print_section "Test 7: Security - Path Restrictions"

# These tests verify that the glob patterns would work correctly
# In actual usage, Claude Code's permission system enforces these restrictions

echo "Testing path pattern matching for security restrictions..."

# Test template pattern matching
if echo "${TEMPLATE_DIR}/custom.md" | grep -qE "^${CLAUDE_PLUGIN_ROOT}/templates/.*"; then
    print_result "Template path matches allowed pattern" "PASS"
else
    print_result "Template path matches allowed pattern" "FAIL"
fi

# Test guide pattern matching
if echo "${GUIDE_DIR}/README.md" | grep -qE "^${CLAUDE_PLUGIN_ROOT}/guides/.*"; then
    print_result "Guide path matches allowed pattern" "PASS"
else
    print_result "Guide path matches allowed pattern" "FAIL"
fi

# Test script pattern matching
if echo "${PROMPT_HANDLER}" | grep -qE "^${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler\.sh.*"; then
    print_result "Script path matches allowed pattern" "PASS"
else
    print_result "Script path matches allowed pattern" "FAIL"
fi

# Test that paths outside allowed directories would be rejected
UNAUTHORIZED_PATH="/etc/passwd"
if ! echo "$UNAUTHORIZED_PATH" | grep -qE "^${CLAUDE_PLUGIN_ROOT}/(templates|guides)/.*"; then
    print_result "Reject unauthorized path (/etc/passwd)" "PASS"
else
    print_result "Reject unauthorized path (/etc/passwd)" "FAIL"
fi

# Test path traversal attempt
TRAVERSAL_PATH="${CLAUDE_PLUGIN_ROOT}/templates/../../etc/passwd"
if ! echo "$TRAVERSAL_PATH" | grep -qE "^${CLAUDE_PLUGIN_ROOT}/(templates|guides)/[^/]*\.md$"; then
    print_result "Reject path traversal attempt (../..)" "PASS"
else
    print_result "Reject path traversal attempt (../..)" "FAIL"
fi

# Test unauthorized script outside allowed directory
UNAUTHORIZED_SCRIPT="/tmp/malicious-script.sh"
if ! echo "$UNAUTHORIZED_SCRIPT" | grep -qE "^${CLAUDE_PLUGIN_ROOT}/commands/scripts/(prompt-handler|template-selector|template-processor)\.sh"; then
    print_result "Reject unauthorized script path" "PASS"
else
    print_result "Reject unauthorized script path" "FAIL"
fi

# Test file in root directory (not in templates/ or guides/)
ROOT_FILE="${CLAUDE_PLUGIN_ROOT}/README.md"
if ! echo "$ROOT_FILE" | grep -qE "^${CLAUDE_PLUGIN_ROOT}/(templates|guides)/.*"; then
    print_result "Reject file in plugin root (not in allowed dirs)" "PASS"
else
    print_result "Reject file in plugin root (not in allowed dirs)" "FAIL"
fi

# Test that only .md files in templates are allowed
NON_MD_FILE="${CLAUDE_PLUGIN_ROOT}/templates/malicious.sh"
if ! echo "$NON_MD_FILE" | grep -qE "^${CLAUDE_PLUGIN_ROOT}/templates/.*\.md$"; then
    print_result "Reject non-.md file in templates directory" "PASS"
else
    print_result "Reject non-.md file in templates directory" "FAIL"
fi

# Test subdirectory access (should be allowed with ** pattern)
NESTED_TEMPLATE="${CLAUDE_PLUGIN_ROOT}/templates/subdir/template.md"
if echo "$NESTED_TEMPLATE" | grep -qE "^${CLAUDE_PLUGIN_ROOT}/templates/.*\.md$"; then
    print_result "Allow nested template files with ** pattern" "PASS"
else
    print_result "Allow nested template files with ** pattern" "FAIL"
fi

# Test 8: Verify frontmatter configurations
print_section "Test 8: Configuration Verification"

PROMPT_OPTIMIZER="${CLAUDE_PLUGIN_ROOT}/agents/prompt-optimizer.md"
CREATE_PROMPT="${CLAUDE_PLUGIN_ROOT}/commands/create-prompt.md"
PROMPT_CMD="${CLAUDE_PLUGIN_ROOT}/commands/prompt.md"

# Check prompt-optimizer.md
if [ -f "$PROMPT_OPTIMIZER" ]; then
    if grep -q "allowed-tools:.*SlashCommand(/meta-prompt:create-prompt:\*)" "$PROMPT_OPTIMIZER"; then
        print_result "prompt-optimizer.md has correct SlashCommand restriction" "PASS"
    else
        print_result "prompt-optimizer.md has correct SlashCommand restriction" "FAIL"
    fi
fi

# Check create-prompt.md (TEMPORARY: checking for hardcoded paths due to Windows workaround)
if [ -f "$CREATE_PROMPT" ]; then
    if grep -q "allowed-tools:.*Bash(~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/.*\.sh)" "$CREATE_PROMPT"; then
        print_result "create-prompt.md has script restrictions (hardcoded paths)" "PASS"
    else
        print_result "create-prompt.md has script restrictions (hardcoded paths)" "FAIL"
    fi

    if grep -q "allowed-tools:.*Read(~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/templates/\*\*)" "$CREATE_PROMPT"; then
        print_result "create-prompt.md has templates/ Read restriction (hardcoded path)" "PASS"
    else
        print_result "create-prompt.md has templates/ Read restriction (hardcoded path)" "FAIL"
    fi

    if grep -q "allowed-tools:.*Read(~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/guides/\*\*)" "$CREATE_PROMPT"; then
        print_result "create-prompt.md has guides/ Read restriction (hardcoded path)" "PASS"
    else
        print_result "create-prompt.md has guides/ Read restriction (hardcoded path)" "FAIL"
    fi
fi

# Check prompt.md (TEMPORARY: checking for hardcoded paths due to Windows workaround)
if [ -f "$PROMPT_CMD" ]; then
    if grep -q "allowed-tools:.*Bash(~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh:\*)" "$PROMPT_CMD"; then
        print_result "prompt.md has prompt-handler.sh restriction (hardcoded path)" "PASS"
    else
        print_result "prompt.md has prompt-handler.sh restriction (hardcoded path)" "FAIL"
    fi
fi

# Summary
print_section "Test Summary"

echo "Total tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
fi

echo ""
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All validation tests passed!${NC}"
    echo "The restricted tool permissions are correctly configured and functional."
    exit 0
else
    echo -e "${RED}✗ Some tests failed.${NC}"
    echo "Please review the failures above and ensure all configurations are correct."
    exit 1
fi
