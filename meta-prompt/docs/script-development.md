# Script Development Guide

Guide for developers modifying or creating bash scripts in the meta-prompt infrastructure.

---

## Table of Contents

1. [Overview](#overview)
2. [Bash Version Requirements](#bash-version-requirements)
3. [Coding Standards](#coding-standards)
4. [Security Requirements](#security-requirements)
5. [Testing Strategies](#testing-strategies)
6. [Debugging Techniques](#debugging-techniques)
7. [Common Pitfalls](#common-pitfalls)
8. [Script Reference](#script-reference)

---

## Overview

The meta-prompt infrastructure uses bash scripts for deterministic preprocessing to achieve zero-token orchestration. All scripts follow strict standards for security, error handling, and maintainability.

### Why Bash?

- **Zero dependencies:** Pre-installed on all target platforms
- **Fast startup:** <10ms execution time
- **Native integration:** Claude Code uses bash for command execution
- **Portability:** Works on macOS, Linux, and WSL

See design-decisions.md:AD-002 for full rationale.

---

## Bash Version Requirements

### Minimum Version: 3.2+

All scripts in this project are compatible with Bash 3.2+, including the default bash shipped with macOS.

**Features used (all available in Bash 3.2):**
- `[[` conditional expressions (Bash 2.0+)
- Regex matching with `=~` operator (Bash 3.0+)
- BASH_REMATCH array (Bash 3.0+)
- String replacement `${var//pattern/replacement}` (Bash 3.1+)
- Here-strings `<<<` (Bash 3.0+)
- Indexed arrays (Bash 2.0+)

**Features NOT used (Bash 4+ only):**
- Associative arrays (`declare -A`)
- Case conversion (`${var^^}`, `${var,,}`)
- `readarray`/`mapfile` commands
- `**` globstar pattern
- `&>>` redirection operator

### Check Your Version

```bash
bash --version
# Should show: GNU bash, version 3.2 or higher
```

### Platform Compatibility

**macOS:**
- ✅ Default bash 3.2 works out-of-the-box (no Homebrew needed)
- macOS 10.5+ ships with bash 3.2.57
- No additional installation required

**Linux:**
- ✅ All distributions ship with bash 3.2+
- Ubuntu 18.04+: bash 4.4
- CentOS 7+: bash 4.2
- Debian 8+: bash 4.3

**Windows/WSL:**
- ✅ WSL ships with bash 4.4+
- ✅ Git Bash includes bash 3.2+
- PowerShell is NOT supported (different language)

---

## Coding Standards

### 1. Strict Error Handling

**Every script MUST start with:**

```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Flags explained:**
- `e`: Exit immediately on any error
- `u`: Treat undefined variables as errors
- `o pipefail`: Fail if any command in a pipeline fails

**Example:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# This will exit immediately if template doesn't exist
template_content=$(cat "/path/to/template.md")

# This will catch errors in pipeline
result=$(grep "pattern" file.txt | wc -l)
```

### 2. Variable Naming

**Convention: lowercase with underscores**

```bash
# Good
template_name="code-comparison"
confidence_score=85
task_description="$1"

# Bad
TemplateName="code-comparison"  # PascalCase
TEMPLATE_NAME="code-comparison"  # ALL_CAPS (reserved for env vars)
templatename="code-comparison"   # No separator
```

**Constants: UPPER_SNAKE_CASE**

```bash
readonly CONFIDENCE_THRESHOLD=70
readonly TEMPLATE_DIR="templates"
```

### 3. Function Definitions

```bash
# Good: lowercase, descriptive names
sanitize_input() {
    local input="$1"
    printf '%s\n' "$input" | sed 's/\\/\\\\/g; s/\$/\\$/g'
}

# Use local for function variables
score_category() {
    local category="$1"
    local task="$2"
    local score=0
    # ... calculation ...
    echo "$score"
}
```

### 4. Quoting

**Always quote variables to prevent word splitting:**

```bash
# Good
template_path="$TEMPLATE_DIR/$template_name.md"
if [ -f "$template_path" ]; then
    content=$(cat "$template_path")
fi

# Bad (will break with spaces)
template_path=$TEMPLATE_DIR/$template_name.md
if [ -f $template_path ]; then
    content=$(cat $template_path)
fi
```

### 5. Conditional Expressions

**Use `[[` for modern bash conditionals:**

```bash
# Good
if [[ "$confidence" -gt "$CONFIDENCE_THRESHOLD" ]]; then
    echo "$template_name"
fi

if [[ "$task" =~ refactor|modify|update ]]; then
    template="code-refactoring"
fi

# Acceptable for simple cases
if [ -f "$file" ]; then
    cat "$file"
fi
```

### 6. Comments

```bash
# Single-line comments for brief explanations
confidence=75

# Multi-line comments for complex logic
# This function calculates confidence by:
# 1. Checking for strong indicators (75% base)
# 2. Adding 8% for each supporting keyword
# 3. Returning the total score
calculate_confidence() {
    # ... implementation ...
}
```

### 7. Exit Codes

```bash
# Success
exit 0

# Generic error
exit 1

# Specific errors (document in comments)
exit 2  # Template not found
exit 3  # Invalid arguments
exit 4  # Confidence below threshold
```

---

## Security Requirements

### 1. Input Sanitization

**ALWAYS sanitize user input before use:**

```bash
sanitize_input() {
    local input="$1"
    # Escape backslashes, dollar signs, backticks, and quotes
    printf '%s\n' "$input" | sed 's/\\/\\\\/g; s/\$/\\$/g; s/`/\\`/g; s/"/\\"/g'
}

# Usage
user_input=$(sanitize_input "$1")
```

**Prevents:**
- Command injection via backticks: `` `rm -rf /` ``
- Variable expansion: `$HOME`, `${malicious}`
- Path traversal: `../../etc/passwd`

### 2. No eval

**NEVER use `eval` with user input:**

```bash
# DANGEROUS - DO NOT USE
eval "$user_input"

# Safe alternative: use functions or case statements
case "$user_input" in
    option1) action1 ;;
    option2) action2 ;;
    *) echo "Invalid option" ;;
esac
```

### 3. Whitelist Approach

**Validate inputs against known good values:**

```bash
# Good: whitelist valid templates
case "$template_name" in
    code-refactoring|code-review|test-generation|documentation-generator|function-calling|data-extraction|code-comparison|custom)
        template_path="$TEMPLATE_DIR/$template_name.md"
        ;;
    *)
        echo "ERROR: Invalid template: $template_name" >&2
        exit 1
        ;;
esac

# Bad: blacklist (easy to bypass)
if [[ "$input" == *"rm"* ]]; then
    echo "Blocked"
fi
```

### 4. File Path Validation

```bash
# Validate paths stay within allowed directory
validate_path() {
    local path="$1"
    local base_dir="$2"

    # Resolve to absolute path
    local abs_path=$(cd "$(dirname "$path")" && pwd)/$(basename "$path")

    # Check if within base directory
    if [[ "$abs_path" != "$base_dir"* ]]; then
        echo "ERROR: Path outside allowed directory" >&2
        exit 1
    fi
}
```

---

## Testing Strategies

### 1. Unit Testing Functions

**Test individual functions:**

```bash
# Test sanitization
test_sanitize() {
    local input='test$var `cmd` "quote"'
    local expected='test\$var \`cmd\` \"quote\"'
    local result=$(sanitize_input "$input")

    if [[ "$result" == "$expected" ]]; then
        echo "PASS: sanitize_input"
    else
        echo "FAIL: Expected: $expected, Got: $result"
        exit 1
    fi
}
```

### 2. Integration Testing

**Test full script workflows:**

```bash
# Test classification accuracy
test_classification() {
    local result=$(./template-selector.sh "Compare Python and JavaScript")
    if [[ "$result" == "code-comparison" ]]; then
        echo "PASS: Classification"
    else
        echo "FAIL: Expected code-comparison, got $result"
        exit 1
    fi
}
```

See `tests/test-integration.sh` for complete test suite.

### 3. Edge Case Testing

```bash
# Test empty input
test_empty_input() {
    ./template-selector.sh ""
    if [[ $? -ne 0 ]]; then
        echo "PASS: Empty input rejected"
    else
        echo "FAIL: Empty input should be rejected"
        exit 1
    fi
}

# Test special characters
test_special_chars() {
    ./template-processor.sh code-comparison \
        ITEM1='test$var' \
        ITEM2='back`tick`' \
        CLASSIFICATION_CRITERIA='quote"test'
    # Should not execute commands, should escape properly
}
```

---

## Debugging Techniques

### 1. Debug Mode (set -x)

```bash
# Enable debug output
set -x

# Or run script with debug
bash -x ./template-selector.sh "test task"

# Disable debug
set +x
```

**Output shows each command before execution:**
```
+ task_lower='test task'
+ grep -E 'compare|classify' <<< 'test task'
```

### 2. DEBUG Environment Variable

**Add debug logging to scripts:**

```bash
debug_log() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "DEBUG: $*" >&2
    fi
}

# Usage
debug_log "Template: $template_name, Confidence: $confidence%"
```

**Enable:**
```bash
DEBUG=1 ./template-selector.sh "test task"
```

### 3. Echo Statements

**Temporary debugging:**

```bash
echo "DEBUG: variable=$variable" >&2
echo "DEBUG: confidence=$confidence, threshold=$CONFIDENCE_THRESHOLD" >&2
```

**Note:** Use `>&2` to send to stderr, keeping stdout clean for script output.

### 4. Verbose Error Messages

```bash
# Bad
exit 1

# Good
echo "ERROR: Template file not found: $template_path" >&2
echo "Available templates:" >&2
ls "$TEMPLATE_DIR"/*.md >&2
exit 1
```

### 5. shellcheck Linting

**Install shellcheck:**
```bash
# macOS
brew install shellcheck

# Linux
sudo apt-get install shellcheck
```

**Run linter:**
```bash
shellcheck ./template-selector.sh

# Fix common issues:
# - Unquoted variables
# - Unused variables
# - Deprecated syntax
# - Potential errors
```

---

## Common Pitfalls

### Pitfall 1: Unquoted Variables

**Problem:**
```bash
file_path=/path/with spaces/file.txt
cat $file_path  # Breaks - interpreted as 3 arguments
```

**Solution:**
```bash
file_path="/path/with spaces/file.txt"
cat "$file_path"  # Works - single argument
```

### Pitfall 2: Word Splitting in Arrays

**Problem:**
```bash
files=$(ls *.md)  # String, not array
for file in $files; do  # Breaks on spaces
    echo "$file"
done
```

**Solution:**
```bash
# Use array
files=(*.md)
for file in "${files[@]}"; do
    echo "$file"
done

# Or read line by line
while IFS= read -r file; do
    echo "$file"
done < <(ls *.md)
```

### Pitfall 3: grep Exit Codes

**Problem:**
```bash
set -e
grep "pattern" file.txt  # Exits script if no match (exit code 1)
```

**Solution:**
```bash
# Option 1: Allow grep to fail
grep "pattern" file.txt || true

# Option 2: Check exit code
if grep -q "pattern" file.txt; then
    echo "Found"
else
    echo "Not found"
fi
```

### Pitfall 4: Command Substitution in Quotes

**Problem:**
```bash
message="Template: $(cat "$file")"  # Loads entire file
```

**Solution:**
```bash
# Only capture what you need
template_name=$(head -1 "$file")

# Or use here-strings for small data
message="Template: ${template_name}"
```

### Pitfall 5: Integer Comparison vs String

**Problem:**
```bash
if [[ "$confidence" > "$threshold" ]]; then  # String comparison!
    echo "High confidence"
fi
# "90" > "100" is true (lexicographic)
```

**Solution:**
```bash
if [[ "$confidence" -gt "$threshold" ]]; then  # Integer comparison
    echo "High confidence"
fi
```

---

## Script Reference

### prompt-handler.sh

**Purpose:** Orchestrates `/prompt` command workflow

**Input:**
- `$1`: Task description (required)
- `$2`: Flags like `--return-only` (optional)

**Output:** Instructions for Claude Code (stdout)

**Key Functions:**
- `sanitize_input()`: Escapes dangerous characters
- Detects execution mode vs return-only mode
- Generates instructions for meta-prompt:prompt-optimizer agent

**Location:** `commands/scripts/prompt-handler.sh`

### template-selector.sh

**Purpose:** Classify tasks and route to appropriate templates

**Input:**
- `$1`: Task description (required)

**Output:** Template name + confidence (if DEBUG=1)

**Key Functions:**
- `score_category()`: Calculate confidence for each template category
- Keyword matching with regex
- Confidence threshold comparison (70%)

**Algorithm:**
1. Convert task to lowercase
2. Check for strong indicators (75% base confidence)
3. Count supporting keywords (8% each)
4. Select highest confidence ≥ 70%
5. Return template name or "custom"

**Location:** `commands/scripts/template-selector.sh`

### template-processor.sh

**Purpose:** Load templates and substitute variables

**Input:**
- `$1`: Template name (required)
- `$2+`: VAR=value pairs (required)

**Output:** Processed template with substituted variables

**Key Functions:**
- `escape_value()`: Security escaping for variable values
- Variable extraction from arguments
- Substitution with `sed`
- Validation of unreplaced variables

**Location:** `commands/scripts/template-processor.sh`

### validate-templates.sh

**Purpose:** Validate template structure and metadata

**Input:**
- `$1`: Template name (optional - validates all if omitted)

**Output:** Validation results with pass/fail status

**Checks:**
- YAML frontmatter present
- Required fields exist
- Variables declared match variables used
- XML tags balanced
- Template has content

**Location:** `tests/validate-templates.sh`

### test-integration.sh

**Purpose:** Integration test suite

**Input:** None

**Output:** Test results (pass/fail for each test)

**Test Phases:**
1. Script existence (4 tests)
2. Template validation (7 tests)
3. Error handling (5 tests)
4. Template selection (6 tests)
5. Template processing (3 tests)
6. Prompt handler (3 tests)
7. File modifications (3 tests)

**Location:** `tests/test-integration.sh`

### verify-documentation-counts.sh

**Purpose:** Verify that documentation counts match actual file counts

**Input:** None

**Output:** Verification results showing matches/mismatches between documented and actual counts

**Checks:**
- Template count in README.md, getting-started.md, CONTRIBUTING.md
- Test count in getting-started.md, migration.md, infrastructure.md
- Actual template count (files in templates/)
- Actual test count (run_test calls in test-integration.sh)

**Usage:**
```bash
CLAUDE_PLUGIN_ROOT=/path/to/meta-prompt tests/verify-documentation-counts.sh
```

**Exit codes:**
- 0: All documentation counts are accurate
- 1: Documentation counts don't match actual counts or script error

**Location:** `tests/verify-documentation-counts.sh`

**Note:** Run this script before releases or after adding/removing templates or tests to ensure documentation stays synchronized with the codebase.

---

## Best Practices

### 1. Keep Scripts Focused

Each script should have a single responsibility:
- ✓ template-selector.sh: Classification only
- ✓ template-processor.sh: Substitution only
- ✗ Don't combine multiple responsibilities

### 2. Use Functions for Reusability

```bash
# Extract common logic into functions
calculate_score() {
    local category="$1"
    local task="$2"
    # ... scoring logic ...
    echo "$score"
}

# Call from multiple places
score_simple=$(calculate_score "code-comparison" "$task")
score_document=$(calculate_score "document-qa" "$task")
```

### 3. Document Complex Logic

```bash
# Complex regex or algorithm
# This pattern matches:
# - "refactor" at word boundaries (\b)
# - "modify", "update", "change", "fix"
# - Case-insensitive (via ${task,,})
if [[ "$task" =~ \brefactor\b|modify|update|change|fix ]]; then
    template="code-refactoring"
fi
```

### 4. Fail Fast

```bash
# Validate inputs early
if [[ -z "$1" ]]; then
    echo "ERROR: Task description required" >&2
    exit 1
fi

if [[ ! -f "$template_path" ]]; then
    echo "ERROR: Template not found: $template_path" >&2
    exit 1
fi
```

### 5. Consistent Output Format

```bash
# Good: Structured output
echo "$template_name"
[[ "${DEBUG:-0}" == "1" ]] && echo "Confidence: $confidence%" >&2

# Bad: Mixed formats
echo "The template is $template_name with confidence $confidence%"
```

---

## Additional Resources

- **Bash Manual:** https://www.gnu.org/software/bash/manual/
- **Bash Guide:** https://mywiki.wooledge.org/BashGuide
- **shellcheck:** https://www.shellcheck.net/
- **Google Shell Style Guide:** https://google.github.io/styleguide/shellguide.html

---

## Getting Help

**When modifying scripts:**
1. Read existing scripts for patterns
2. Run shellcheck for linting
3. Test with DEBUG=1 for verbose output
4. Run validation and integration tests
5. See [CONTRIBUTING.md](CONTRIBUTING.md) for support

---

**Document Version:** 1.0
**Last Updated:** 2025-11-18
