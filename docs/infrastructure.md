# Infrastructure Documentation

**Project:** Meta-Prompt Infrastructure for Claude Code
**Version:** 1.0
**Last Updated:** 2025-11-18

---

## Table of Contents

### 🟢 Essential (Must Read)
1. [Environment Setup](#environment-setup) - Get started with installation
2. [Build and Deployment](#build-and-deployment) - Deploy and rollback procedures

### 🟡 Important (Read When Needed)
3. [Testing Infrastructure](#testing-infrastructure) - Running tests and validation
4. [Troubleshooting](#troubleshooting) - Common issues and solutions
5. [Configuration Management](#configuration-management) - Settings and permissions

### ⚪ Reference (Look Up As Needed)
6. [Directory Structure](#directory-structure) - Complete file tree
7. [Dependencies](#dependencies) - Required software
8. [Script API Reference](#script-api-reference) - Script interfaces and usage
9. [Monitoring and Maintenance](#monitoring-and-maintenance) - Ongoing operations
10. [Performance Optimization](#performance-optimization) - Tuning and scaling

---

## Directory Structure

### Complete File Tree

```

├── .claude/                                    # Claude Code configuration root
│   ├── settings.json                    # Permissions and configuration
│   │
│   ├── agents/                                # LLM agents
│   │   └── prompt-optimizer.md                # Prompt engineering agent (50 lines)
│   │
│   ├── commands/                              # Slash commands
│   │   ├── prompt.md                          # /prompt command (40 lines)
│   │   ├── create-prompt.md                   # /create-prompt command (196 lines)
│   │   │
│   │   └── scripts/                           # Deterministic processing scripts
│   │       ├── prompt-handler.sh              # /prompt orchestration (77 lines)
│   │       ├── template-selector.sh           # Task classification (194 lines)
│   │       ├── template-processor.sh          # Variable substitution (116 lines)
│   │       ├── validate-templates.sh          # Template validation (180 lines)
│   │       └── test-integration.sh            # Integration tests (240 lines)
│   │
│   ├── templates/                             # Template library
│   │   ├── simple-classification.md           # Comparison template (37 lines)
│   │   ├── document-qa.md                     # Document Q&A template (39 lines)
│   │   ├── code-refactoring.md                # Code modification template (64 lines)
│   │   ├── function-calling.md                # Function/API usage template (52 lines)
│   │   ├── interactive-dialogue.md            # Conversational agent template (38 lines)
│   │   └── custom.md                          # LLM fallback template (20 lines)
│   │
│
├── docs/                                      # Documentation
│   ├── architecture-overview.md               # System architecture
│   ├── design-decisions.md                    # Design rationale
│   └── infrastructure.md                      # This file
│
├── README.md                                  # Documentation index
│
├── .git/                                      # Git version control
│   ├── config                                 # Git configuration
│   ├── HEAD                                   # Current branch pointer
│   ├── objects/                               # Git object database
│   ├── refs/                                  # Branch and tag references
│   └── ...
│
└── .gitignore                                 # (To be created if needed)
```

### Directory Purposes

#### `.claude/`
**Purpose:** Root configuration directory for Claude Code integration
**Owner:** Claude Code CLI
**Contents:** All project-specific Claude Code configuration, commands, agents, and templates

#### `.claude/agents/`
**Purpose:** LLM agent definitions
**File Format:** Markdown with YAML frontmatter
**Count:** 1 agent (prompt-optimizer)
**Access:** Invoked via Task tool with `subagent_type` parameter

#### `.claude/commands/`
**Purpose:** Slash command definitions
**File Format:** Markdown with YAML frontmatter
**Count:** 2 commands (/prompt, /create-prompt)
**Access:** User invokes via `/command-name` syntax in Claude Code

#### `.claude/commands/scripts/`
**Purpose:** Deterministic processing scripts (bash)
**File Format:** Bash shell scripts (.sh)
**Permissions:** Executable (`chmod +x`)
**Execution:** Called from commands via Bash tool
**Token Cost:** Zero (deterministic execution)

#### `.claude/templates/`
**Purpose:** Pre-built prompt templates
**File Format:** Markdown with YAML frontmatter
**Count:** 6 templates
**Version:** Tracked in frontmatter (`version: 1.0`)
**Validation:** Via `validate-templates.sh`

#### `docs/`
**Purpose:** Project documentation
**File Format:** Markdown (GitHub-flavored)
**Audience:** Developers, maintainers, users
**Update Frequency:** On major changes, quarterly reviews

---

## Configuration Management

### settings.json

**Location:** `.claude/settings.json`

**Purpose:** Configure permissions for script execution and slash command usage

**Structure:**
```json
{
  "permissions": {
    "allow": [
      "SlashCommand(/create-prompt:*)",
      "Bash(.claude/commands/scripts/prompt-handler.sh:*)",
      "Bash(chmod:*)",
      "Bash(.claude/commands/scripts/template-processor.sh:*)",
      "Bash(.claude/commands/scripts/validate-templates.sh:*)",
      "Bash(DEBUG=1 .claude/commands/scripts/template-selector.sh:*)",
      "Bash(./commands/scripts/test-integration.sh)",
      "Bash(.claude/commands/scripts/template-selector.sh:*)",
      "Bash(commands/scripts/test-integration.sh:*)",
      "Bash(commands/scripts/template-processor.sh:*)",
      "Bash(.claude/commands/scripts/test-integration.sh)"
    ],
    "deny": [],
    "ask": []
  }
}
```

**Permission Categories:**

1. **allow:** Whitelist of permitted operations
   - Format: `"Tool(pattern:*)"` or `"Tool(path)"`
   - Wildcards supported for flexible matching
   - Scripts can run with any arguments (`*`)

2. **deny:** Blacklist of forbidden operations
   - Currently empty (using whitelist-only model)

3. **ask:** Operations requiring user confirmation
   - Currently empty (all permitted operations auto-approved)

**Security Model:**
- Whitelist-based (only explicitly allowed operations can execute)
- Script paths must match exactly or via pattern
- Prevents unauthorized script execution
- Can be version-controlled safely (no secrets)

**Modification Guidelines:**
- Add new scripts to `allow` list before deployment
- Use specific paths when possible (e.g., `.claude/commands/scripts/script-name.sh`)
- Include wildcard variants for different calling patterns
- Test permission changes before committing

---

### Template Configuration (YAML Frontmatter)

Each template contains configuration metadata in YAML frontmatter.

**Standard Fields:**

```yaml
---
template_name: <name>           # Required: Unique identifier (matches filename)
category: <category>            # Required: Broad category for grouping
keywords: [key1, key2, ...]    # Required: Classification keywords
complexity: <level>             # Required: simple | intermediate | complex
variables: [VAR1, VAR2, ...]   # Required: List of {$VARIABLE} placeholders
version: 1.0                    # Required: Semantic version (major.minor)
description: <text>             # Required: One-line description
variable_descriptions:          # Optional: Detailed variable explanations
  VAR1: "Explanation..."
  VAR2: "Explanation..."
---
```

**Field Descriptions:**

- **template_name:** Must match filename without .md extension
- **category:** Groups related templates (comparison, analysis, development, etc.)
- **keywords:** Array of words used for classification (see template-selector.sh)
- **complexity:** Indicates cognitive load (simple ≤3 steps, complex >7 steps)
- **variables:** List of all `{$VARIABLE}` placeholders in template body
- **version:** Semantic versioning for template evolution
- **description:** Brief summary of template purpose
- **variable_descriptions:** (Optional) Detailed explanations for each variable

**Version Semantics:**
- **Major (X.0):** Breaking changes (variables renamed, removed, or added)
- **Minor (1.X):** Non-breaking improvements (better instructions, examples)
- **Patch (1.0.X):** Bug fixes (typos, formatting, clarifications)

**Validation:**

Run validation before committing template changes:

```bash
.claude/commands/scripts/validate-templates.sh [template-name]
```

---

## Build and Deployment

### Build Process

This project has **no build step**. All components are interpreted at runtime:
- Bash scripts execute directly
- Markdown files loaded by Claude Code
- Templates processed on-demand

**Advantages:**
- Zero build time
- No compilation errors
- Instant deployment
- Simple rollback (git revert)

**Disadvantages:**
- No compile-time type checking
- Errors discovered at runtime
- Requires robust testing

### Deployment Process

#### Step 1: Pre-Deployment Validation

```bash
# Navigate to project root
cd .claude

# Validate all templates
./commands/scripts/validate-templates.sh

# Run integration tests
./commands/scripts/test-integration.sh

# Check for uncommitted changes
git status
```

**Success Criteria:**
- All templates pass validation (6/6 passed)
- All integration tests pass (30+ tests, 100% pass rate)
- Git working directory clean or changes intentional

#### Step 2: Version Control

```bash
# Stage changes
git add .claude/

# Commit with descriptive message
git commit -m "feat: Add new template for X pattern

- Template: new-template.md
- Classification keywords: keyword1, keyword2
- Variables: VAR1, VAR2
- Tested: validate-templates.sh, test-integration.sh

Co-Authored-By: Claude <noreply@anthropic.com>"

# Tag release (optional, for major changes)
git tag -a v1.1 -m "Release 1.1: Add new-template"

# Push to remote
git push origin main
git push --tags
```

#### Step 3: Deployment

**Local Development:**
- No deployment needed (changes take effect immediately in Claude Code)
- Restart Claude Code session if needed

**Team Deployment:**
- Team members pull latest changes: `git pull origin main`
- Changes take effect on next slash command invocation

**Production Deployment:**
- Same as team deployment (no separate production environment)
- Gradual rollout via feature flags (if needed)

### Rollback Procedures

#### Rollback Individual File

```bash
# Restore specific file from previous commit
git checkout HEAD~1 .claude/templates/template-name.md

# Commit rollback
git commit -m "rollback: Revert template-name.md to previous version"
```

#### Rollback Entire Release

```bash
# Find commit to revert to
git log --oneline

# Revert to specific commit
git revert <commit-hash>

# Or hard reset (use with caution)
git reset --hard <commit-hash>
git push --force origin main  # WARNING: Destructive
```

**Rollback Triggers:**

**Immediate Rollback (P0):**
- Error rate >10%
- Critical functionality broken
- Security vulnerability discovered

**Planned Rollback (P1):**
- Token reduction <20% (below target)
- Classification accuracy <75%
- Performance degradation >500ms

**Timeline:**
- Individual file rollback: <5 minutes
- Full release rollback: <15 minutes
- System-wide rollback: <1 hour

---

## Environment Setup

### Prerequisites

**Operating System:**
- macOS (primary target)
- Linux (Ubuntu, Debian, CentOS, etc.)
- Windows with WSL (Windows Subsystem for Linux)

**Required Software:**
- Bash 4.0 or higher
- Git
- Claude Code CLI (latest version)

**Standard Unix Utilities:**
- grep
- sed
- awk
- wc
- tr
- cut
- head
- tail
- sort

**Optional:**
- jq (for JSON processing, not currently used)

### Installation

#### Option 1: Clone Repository

```bash
# Clone repository
git clone <repository-url> claude-meta-prompt
cd claude-meta-prompt

# Make scripts executable
chmod +x .claude/commands/scripts/*.sh

# Validate installation
.claude/commands/scripts/validate-templates.sh
.claude/commands/scripts/test-integration.sh
```

#### Option 2: Manual Setup

```bash
# Create directory structure
mkdir -p .claude/{agents,commands/scripts,templates,docs}

# Copy files from this documentation
# (Files should be copied manually or via installation script)

# Make scripts executable
chmod +x .claude/commands/scripts/*.sh

# Validate setup
.claude/commands/scripts/validate-templates.sh
```

### Verification

```bash
# Check Bash version (must be 4.0+)
bash --version

# Verify scripts are executable
ls -l .claude/commands/scripts/*.sh

# Run validation
.claude/commands/scripts/validate-templates.sh

# Run integration tests
.claude/commands/scripts/test-integration.sh
```

**Expected Output:**
```
=== Template Validation ===
Validating: simple-classification
  ✓ Has valid frontmatter
  ✓ Has required field: template_name
  [... more checks ...]
PASSED: simple-classification

[... 5 more templates ...]

=== Summary ===
Total templates: 6
Passed: 6
Failed: 0
```

### Configuration

#### 1. Update settings.json

Ensure all scripts are in the `allow` list:

```json
{
  "permissions": {
    "allow": [
      "Bash(.claude/commands/scripts/prompt-handler.sh:*)",
      "Bash(.claude/commands/scripts/template-selector.sh:*)",
      "Bash(.claude/commands/scripts/template-processor.sh:*)",
      "Bash(.claude/commands/scripts/validate-templates.sh:*)",
      "Bash(.claude/commands/scripts/test-integration.sh:*)"
    ]
  }
}
```

#### 2. Test Slash Commands

```bash
# In Claude Code CLI
/prompt "Analyze security issues in authentication module"
/create-prompt "Compare two sentences for semantic similarity"
```

#### 3. Enable Debug Mode (Optional)

```bash
# Set DEBUG environment variable for verbose output
DEBUG=1 .claude/commands/scripts/template-selector.sh "Your task description"
```

**Debug Output Example:**
```
simple-classification
Confidence: 85%
Threshold: 70%
```

---

## Dependencies

### Runtime Dependencies

| Dependency | Version | Required | Purpose | Availability |
|------------|---------|----------|---------|--------------|
| **Bash** | 4.0+ | Yes | Script execution | Pre-installed (macOS, Linux) |
| **grep** | Any | Yes | Pattern matching | Standard Unix |
| **sed** | Any | Yes | Stream editing | Standard Unix |
| **awk** | Any | Yes | Text processing | Standard Unix |
| **wc** | Any | Yes | Word/line counting | Standard Unix |
| **tr** | Any | Yes | Character translation | Standard Unix |
| **cut** | Any | Yes | Field extraction | Standard Unix |
| **Git** | 2.0+ | Yes | Version control | Usually pre-installed |
| **jq** | 1.6+ | No | JSON processing | Optional (not currently used) |

### Development Dependencies

| Tool | Purpose | Installation |
|------|---------|--------------|
| **Markdown linter** | Validate markdown syntax | `npm install -g markdownlint-cli` |
| **shellcheck** | Bash script linting | `brew install shellcheck` (macOS) |
| **shfmt** | Bash script formatting | `brew install shfmt` (macOS) |

### Dependency Management

**Philosophy:** Minimize dependencies to reduce installation friction and maximize portability.

**Adding New Dependencies:**

1. **Evaluate Necessity:** Is this truly needed, or can we use standard tools?
2. **Check Availability:** Is it pre-installed on macOS/Linux?
3. **Document Requirement:** Update this file and README
4. **Update Permissions:** Add to settings.json if needed
5. **Test Across Platforms:** Verify on macOS, Linux, WSL

**Dependency Update Policy:**

- Pin specific versions in documentation (e.g., "Bash 4.0+")
- Test on oldest supported version
- Document breaking changes between versions
- Provide fallback implementations when possible

---

## Testing Infrastructure

### Test Suite Organization

**Location:** `.claude/commands/scripts/test-integration.sh`

**Test Phases:**

1. **Phase 1: Script Existence** (4 tests)
   - Verify all scripts exist and are executable
   - Quick sanity check before running functional tests

2. **Phase 2: Template Validation** (7 tests)
   - All templates pass validation
   - Each template file exists
   - Validates structure and metadata

3. **Phase 2B: Error Handling** (5 tests)
   - Missing template gracefully handled
   - Empty input handled
   - Special characters sanitized
   - Invalid arguments rejected

4. **Phase 3: Template Selection Accuracy** (6 tests)
   - Classification for each category
   - Fallback to custom for novel tasks
   - Confidence scoring validation

5. **Phase 4: Template Processing** (3 tests)
   - Variable substitution works
   - Template content preserved
   - Unreplaced variables detected

6. **Phase 5: Prompt Handler** (3 tests)
   - Execution mode detection
   - Return-only mode detection
   - Flag removal from task description

7. **Phase 6: File Modification** (3 tests)
   - Commands reference correct scripts
   - Agent is streamlined (<100 lines)

**Total Tests:** 31 tests across 7 phases

### Running Tests

#### Run All Tests

```bash
.claude/commands/scripts/test-integration.sh
```

**Expected Output:**
```
=====================================
  LLM Optimization Integration Tests
=====================================

Phase 1: Script Existence
[TEST 1] prompt-handler.sh exists and is executable
  ✓ PASSED
[... 30 more tests ...]

=====================================
           Test Summary
=====================================

Total Tests:  31
Passed:       31
Failed:       0

Pass Rate:    100%

✓ ALL TESTS PASSED!

The LLM optimization implementation is ready for deployment.
```

#### Run Individual Test Categories

```bash
# Extract specific phase from test script
sed -n '/Phase 1:/,/Phase 2:/p' .claude/commands/scripts/test-integration.sh | bash
```

#### Debug Failed Tests

```bash
# Run with verbose output
bash -x .claude/commands/scripts/test-integration.sh
```

### Test Coverage

**Code Coverage:**
- Script existence: 100%
- Template validation: 100%
- Classification accuracy: 6/6 categories
- Error handling: 5 error scenarios
- Security: Special character injection

**Edge Cases Tested:**
- Empty input
- Missing files
- Invalid arguments
- Special characters (`$`, `` ` ``, `\`)
- Long task descriptions
- Flag parsing (`--return-only`)

**Not Tested (Future Work):**
- Concurrent script execution
- Extremely long input (>10KB)
- Binary data in input
- Template versioning conflicts

### Continuous Integration

**Recommended CI/CD Integration:**

```yaml
# Example GitHub Actions workflow
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Make scripts executable
        run: chmod +x .claude/commands/scripts/*.sh
      - name: Validate templates
        run: .claude/commands/scripts/validate-templates.sh
      - name: Run integration tests
        run: .claude/commands/scripts/test-integration.sh
```

**Pre-Commit Hook:**

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run tests before allowing commit
.claude/commands/scripts/validate-templates.sh
if [ $? -ne 0 ]; then
    echo "Template validation failed. Commit aborted."
    exit 1
fi

.claude/commands/scripts/test-integration.sh
if [ $? -ne 0 ]; then
    echo "Integration tests failed. Commit aborted."
    exit 1
fi
```

---

## Monitoring and Maintenance

### Monitoring

**Key Metrics to Track:**

1. **Token Consumption**
   - Before optimization: ~1800 tokens/workflow
   - After optimization: ~720 tokens/workflow (target 50% reduction)
   - Measurement: Manual API usage tracking

2. **Template Selection Rate**
   - Target: 80%+ tasks route to templates (not custom)
   - Measurement: Count template vs. custom selections

3. **Classification Accuracy**
   - Target: 90%+ correct classifications
   - Measurement: Manual review of 100+ tasks
   - Test dataset: `.claude/tests/template-selection-dataset.txt` (to be created)

4. **Performance**
   - Target: <100ms total overhead
   - Measurement: Time script execution
   - Command: `time .claude/commands/scripts/template-selector.sh "task"`

5. **Error Rate**
   - Target: <2% errors
   - Measurement: Count script failures vs. total invocations

**Monitoring Implementation:**

Currently manual. Future improvements:
- Automated logging to file
- Dashboard for visualization
- Alerts on threshold violations

### Maintenance Schedule

**Daily:**
- No routine maintenance required

**Weekly:**
- Review error logs (if implemented)
- Monitor token consumption trends

**Monthly:**
- Review template usage statistics
- Identify frequently used custom patterns (candidates for new templates)
- Check for new keyword patterns emerging

**Quarterly:**
- Full template library review
- Update keywords based on usage patterns
- Template consolidation (merge similar templates)
- Performance optimization (if needed)
- Documentation updates
- Dependency updates

**Annually:**
- Major version planning
- Architecture review
- Technology stack evaluation

### Common Maintenance Tasks

#### Adding a New Template

1. **Create template file:**
   ```bash
   cp .claude/templates/custom.md .claude/templates/new-template.md
   ```

2. **Edit metadata and content:**
   - Update YAML frontmatter
   - Define variables
   - Write template body

3. **Add classification keywords:**
   ```bash
   # Edit template-selector.sh
   # Add keywords to appropriate category
   ```

4. **Validate:**
   ```bash
   .claude/commands/scripts/validate-templates.sh new-template
   ```

5. **Test:**
   ```bash
   # Add test case to test-integration.sh
   # Run full test suite
   .claude/commands/scripts/test-integration.sh
   ```

6. **Document:**
   - Update architecture-overview.md (template count)
   - Update this file (if new category)
   - Commit with descriptive message

#### Updating Template Keywords

1. **Analyze classification misses:**
   - Review tasks that went to custom instead of template
   - Identify common words/patterns

2. **Update template-selector.sh:**
   ```bash
   # Locate keyword arrays (lines 83-87)
   # Add new keywords to appropriate category
   ```

3. **Test classification:**
   ```bash
   DEBUG=1 .claude/commands/scripts/template-selector.sh "test task description"
   ```

4. **Run full test suite:**
   ```bash
   .claude/commands/scripts/test-integration.sh
   ```

5. **Commit changes:**
   ```bash
   git commit -m "feat: Add keywords for improved classification

   - Added keywords: keyword1, keyword2
   - Improves classification for X pattern
   - Tested with 10+ examples"
   ```

#### Adjusting Confidence Threshold

1. **Measure current accuracy:**
   - Create test dataset of 100+ tasks
   - Run classifier on all tasks
   - Calculate accuracy

2. **Experiment with threshold:**
   ```bash
   # Edit template-selector.sh line 10
   CONFIDENCE_THRESHOLD=70  # Try 60, 70, 80, 90
   ```

3. **Re-run accuracy tests:**
   - Measure precision (correct / total selected)
   - Measure recall (correct / total should be selected)
   - Find optimal balance

4. **Document decision:**
   - Update design-decisions.md with new threshold
   - Include accuracy metrics and rationale

#### Deprecating a Template

1. **Identify low-usage template:**
   - Review usage statistics
   - Confirm <5% selection rate

2. **Merge into similar template:**
   - Combine keywords
   - Generalize template body
   - Update variables if needed

3. **Update classification:**
   - Remove old template's keywords from selector
   - Add to remaining template's keywords

4. **Archive old template:**
   ```bash
   git mv .claude/templates/old-template.md .claude/templates/archived/
   ```

5. **Update tests and documentation:**
   - Remove from test-integration.sh
   - Update architecture-overview.md
   - Update this file

### Troubleshooting

#### Issue: Script Permission Denied

**Symptom:** `Permission denied` error when running script

**Cause:** Script not executable

**Solution:**
```bash
chmod +x .claude/commands/scripts/*.sh
```

#### Issue: Template Not Found

**Symptom:** `ERROR: Template not found: /path/to/template.md`

**Cause:** Template file missing or path incorrect

**Solution:**
```bash
# Verify template exists
ls -l .claude/templates/template-name.md

# Check script is looking in correct directory
echo "SCRIPT_DIR=$SCRIPT_DIR"
echo "TEMPLATE_DIR=$TEMPLATE_DIR"
```

#### Issue: Variable Not Replaced

**Symptom:** `ERROR: Template has unreplaced variables`

**Cause:** Variable not provided to template-processor.sh

**Solution:**
```bash
# Check template's required variables
grep "variables:" .claude/templates/template-name.md

# Provide all required variables
.claude/commands/scripts/template-processor.sh template-name VAR1='value1' VAR2='value2'
```

#### Issue: Classification Always Returns "custom"

**Symptom:** All tasks classified as custom, no templates used

**Cause:** Keywords don't match or confidence threshold too high

**Solution:**
```bash
# Debug classification
DEBUG=1 .claude/commands/scripts/template-selector.sh "your task description"

# Check confidence scores
# Adjust threshold or keywords as needed
```

#### Issue: Bash Version Too Old

**Symptom:** `syntax error near unexpected token` or associative array errors

**Cause:** Bash version <4.0

**Solution:**
```bash
# Check version
bash --version

# Update bash (macOS)
brew install bash

# Update bash (Linux)
sudo apt-get install bash

# Set as default (if needed)
chsh -s /usr/local/bin/bash  # macOS
chsh -s /bin/bash            # Linux
```

---

## Security Considerations

### Input Validation

All user input is sanitized before processing:

**Escape Sequences:**
- Backslashes (`\`) → `\\`
- Dollar signs (`$`) → `\$`
- Backticks (`` ` ``) → `` \` ``
- Quotes (`"`) → `\"`

**Validation Functions:**
- `sanitize_input()` in prompt-handler.sh
- `escape_value()` in template-processor.sh

### Script Execution Permissions

**Whitelist-Based Security:**
- Only scripts in `settings.json` can execute
- Paths must match exactly or via approved patterns
- No arbitrary script execution allowed

**File Permissions:**
- Scripts owned by user (not root)
- Executable only by owner (`-rwx------` or `-rwxr-xr-x`)
- No world-writable files

### Template Security

**Content Validation:**
- No execution of user-provided code
- Variables substituted as strings only (no eval)
- XML tag balance checked (prevents injection)

**Version Control:**
- All templates versioned in Git
- Changes require review before merge
- Rollback available if issues found

### Secrets Management

**No Secrets in Repository:**
- Configuration files contain no API keys
- No credentials in templates
- Environment variables for sensitive data (if needed)

**Best Practices:**
- Never commit `.env` files
- Use Git secrets scanning
- Review diffs before pushing

---

## Backup and Recovery

### Backup Strategy

**Git-Based Backups:**
- Entire project backed up via Git commits
- Remote repository serves as primary backup
- Branches for feature development

**Recommended Remote Backup:**
```bash
# Add remote repository
git remote add origin <repository-url>

# Push regularly
git push origin main

# Push tags for releases
git push --tags
```

### Recovery Procedures

#### Recover Deleted File

```bash
# Find when file was deleted
git log --all --full-history -- .claude/templates/deleted-file.md

# Restore from specific commit
git checkout <commit-hash> -- .claude/templates/deleted-file.md
```

#### Recover from Corrupted State

```bash
# Discard all local changes
git reset --hard HEAD

# Pull latest from remote
git pull origin main
```

#### Recover from Accidental Push

```bash
# Revert specific commit
git revert <commit-hash>
git push origin main

# Or force reset (use with extreme caution)
git reset --hard <good-commit-hash>
git push --force origin main
```

---

## Performance Optimization

### Current Performance

| Operation | Current | Target | Status |
|-----------|---------|--------|--------|
| Script execution | <10ms | <10ms | Met |
| Classification | <50ms | <50ms | Met |
| Template processing | <20ms | <20ms | Met |
| Template loading | <20ms | <20ms | Met |
| **Total overhead** | **<100ms** | **<100ms** | **Met** |

### Future Optimizations

**If Performance Degrades:**

1. **Template Caching:**
   - Load all templates into memory at startup
   - Reduces I/O from <20ms to <1ms per template

2. **Compiled Regex:**
   - Pre-compile regex patterns
   - Reduces classification from <50ms to <10ms

3. **Parallel Classification:**
   - Score all categories simultaneously
   - Reduces classification from <50ms to <20ms

4. **Binary Execution:**
   - Rewrite critical paths in Go/Rust
   - Reduces total overhead from <100ms to <10ms

**Trigger Points:**
- Template load > 50ms → Implement caching
- Classification > 100ms → Optimize regex or parallelize
- Total overhead > 150ms → Consider compiled approach

---

## Script API Reference

### Overview

This section documents the API for each bash script, including inputs, outputs, exit codes, and usage examples.

---

### prompt-handler.sh

**Purpose:** Orchestrate `/prompt` command workflow

**Location:** `.claude/commands/scripts/prompt-handler.sh`

**Synopsis:**
```bash
prompt-handler.sh <task_description> [flags]
```

**Input Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `$1` | string | Yes | Task description from user |
| `$2` | string | No | Optional flags (e.g., `--return-only`) |

**Output Format:**
```
Instructions for Claude Code to execute
(Formatted text on stdout)
```

**Exit Codes:**
| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Generic error |

**Example Usage:**
```bash
# Execution mode
.claude/commands/scripts/prompt-handler.sh "Analyze security issues"

# Return-only mode
.claude/commands/scripts/prompt-handler.sh "Refactor code" --return-only
```

**Key Functions:**
- `sanitize_input()`: Escapes dangerous characters from user input

**Dependencies:** None (pure bash)

---

### template-selector.sh

**Purpose:** Classify tasks and select appropriate template

**Location:** `.claude/commands/scripts/template-selector.sh`

**Synopsis:**
```bash
[DEBUG=1] template-selector.sh <task_description>
```

**Input Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `$1` | string | Yes | Task description to classify |
| `DEBUG` | env var | No | Set to `1` for verbose output |

**Output Format:**

**Standard mode:**
```
template-name
```

**Debug mode (DEBUG=1):**
```
template-name
Confidence: 85%
Threshold: 70%
```

**Exit Codes:**
| Code | Meaning |
|------|---------|
| `0` | Success (template found) |
| `1` | Error (invalid input) |

**Example Usage:**
```bash
# Normal usage
template=$(.claude/commands/scripts/template-selector.sh "Compare Python and JavaScript")
echo "$template"  # Output: simple-classification

# Debug mode
DEBUG=1 .claude/commands/scripts/template-selector.sh "Refactor authentication module"
# Output:
# code-refactoring
# Confidence: 91%
# Threshold: 70%
```

**Algorithm:**
1. Normalize task to lowercase
2. Check for strong indicators (75% base confidence)
3. Count supporting keywords (8% each)
4. Select template with highest confidence ≥ 70%
5. Return "custom" if no template meets threshold

**Configuration:**
- `CONFIDENCE_THRESHOLD`: Line 10 (default: 70)
- Keyword arrays: Lines 83-166

**Key Functions:**
- `score_category()`: Calculate confidence for template category

---

### template-processor.sh

**Purpose:** Load template and substitute variables

**Location:** `.claude/commands/scripts/template-processor.sh`

**Synopsis:**
```bash
template-processor.sh <template_name> [VAR1=value1 VAR2=value2 ...]
```

**Input Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `$1` | string | Yes | Template name (without .md) |
| `$2+` | key=value | Yes | Variable assignments |

**Output Format:**
```
Processed template with substituted variables
(Full template content on stdout)
```

**Exit Codes:**
| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Template not found |
| `2` | Unreplaced variables remain |

**Example Usage:**
```bash
# Simple classification example
.claude/commands/scripts/template-processor.sh simple-classification \
    ITEM1='Python' \
    ITEM2='JavaScript' \
    CLASSIFICATION_CRITERIA='execution model'

# Code refactoring example
.claude/commands/scripts/template-processor.sh code-refactoring \
    TASK_REQUIREMENTS='Add error handling' \
    TARGET_PATTERNS='api/routes/*.js'
```

**Variable Syntax:**
- Template: `{$VARIABLE_NAME}`
- Command line: `VARIABLE_NAME='value'`

**Security Features:**
- Escapes: `\`, `$`, `` ` ``, `"`
- Prevents command injection
- Validates all variables replaced

**Key Functions:**
- `escape_value()`: Security escaping for variable values

---

### validate-templates.sh

**Purpose:** Validate template structure and metadata

**Location:** `.claude/commands/scripts/validate-templates.sh`

**Synopsis:**
```bash
validate-templates.sh [template_name]
```

**Input Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `$1` | string | No | Specific template name (validates all if omitted) |

**Output Format:**
```
=== Template Validation ===
Validating: template-name
  ✓ Has valid frontmatter
  ✓ Has required field: template_name
  [... more checks ...]
PASSED: template-name

=== Summary ===
Total templates: 6
Passed: 6
Failed: 0
```

**Exit Codes:**
| Code | Meaning |
|------|---------|
| `0` | All validations passed |
| `1` | One or more validations failed |

**Example Usage:**
```bash
# Validate all templates
.claude/commands/scripts/validate-templates.sh

# Validate specific template
.claude/commands/scripts/validate-templates.sh simple-classification
```

**Validation Checks:**
- ✓ YAML frontmatter present
- ✓ Required fields exist (template_name, category, keywords, etc.)
- ✓ Variables declared match variables used
- ✓ XML tags balanced
- ✓ Template has non-empty content

---

### test-integration.sh

**Purpose:** Run comprehensive integration test suite

**Location:** `.claude/commands/scripts/test-integration.sh`

**Synopsis:**
```bash
test-integration.sh
```

**Input Parameters:**
None (all tests are predefined)

**Output Format:**
```
=====================================
  LLM Optimization Integration Tests
=====================================

Phase 1: Script Existence
[TEST 1] prompt-handler.sh exists and is executable
  ✓ PASSED
[... 30 more tests ...]

=====================================
           Test Summary
=====================================

Total Tests:  31
Passed:       31
Failed:       0

✓ ALL TESTS PASSED!
```

**Exit Codes:**
| Code | Meaning |
|------|---------|
| `0` | All tests passed |
| `1` | One or more tests failed |

**Example Usage:**
```bash
# Run full test suite
.claude/commands/scripts/test-integration.sh

# Run with verbose bash debugging
bash -x .claude/commands/scripts/test-integration.sh
```

**Test Phases:**
1. Script Existence (4 tests)
2. Template Validation (7 tests)
3. Error Handling (5 tests)
4. Template Selection Accuracy (6 tests)
5. Template Processing (3 tests)
6. Prompt Handler (3 tests)
7. File Modifications (3 tests)

**Total Tests:** 31

**Test Functions:**
- `run_test()`: Execute test and check exit code
- `run_test_with_output()`: Execute test and check output content

---

## References

### Related Documentation

- **Architecture Overview:** `docs/architecture-overview.md`
- **Design Decisions:** `docs/design-decisions.md`
- **Documentation Index:** `README.md`
- **Implementation Plan:** `.claude/OPTIMIZATION_IMPLEMENTATION_PLAN.md`

### External Resources

- **Claude Code Documentation:** https://docs.anthropic.com/claude-code
- **Bash Scripting Guide:** https://www.gnu.org/software/bash/manual/
- **YAML Specification:** https://yaml.org/spec/
- **Semantic Versioning:** https://semver.org/

---

**Document Status:** Complete
**Review Date:** 2025-11-18
**Next Review:** 2026-02-18 (Quarterly)
