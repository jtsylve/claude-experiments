# Getting Started in 5 Minutes

Welcome! This guide will get you up and running with the meta-prompt optimization infrastructure in just 5 minutes.

---

## What You'll Learn

- How to use the `/prompt` command to optimize and execute tasks
- How the system saves you 40-60% in token consumption
- Where to go next for advanced usage

---

## Prerequisites Check

Before starting, verify you have:

```bash
# Check Bash version (need 4.0+)
bash --version
# Should show: GNU bash, version 4.x or higher

# Verify you're in the project directory
ls commands/
# Should show: prompt.md, create-prompt.md, scripts/
```

If scripts aren't executable:
```bash
chmod +x commands/scripts/*.sh tests/*.sh
```

---

## Step 1: Your First Command (1 minute)

Let's start with a simple task using `/prompt`:

```bash
/prompt "Compare Python and JavaScript for web development"
```

**What happens:**
1. The bash handler script parses your request (0 tokens)
2. The task is classified as "code-comparison" (0 tokens)
3. Variables are extracted: ITEM1="Python", ITEM2="JavaScript" (0 tokens)
4. Template is loaded and processed (minimal tokens)
5. LLM executes the optimized prompt

**Result:** Instead of consuming ~300 tokens for orchestration + ~1500 for prompt generation, you consume only ~20 tokens for template retrieval.

**Token savings: ~1780 tokens (~93% reduction)**

### Alternative: Explicit Template Selection

You can also explicitly select a template using flags:

```bash
/prompt --compare "Compare Python and JavaScript for web development"
```

This bypasses the auto-detection logic entirely and uses the specified template directly. Available flags: `--code`, `--refactor`, `--review`, `--test`, `--docs`, `--documentation`, `--extract`, `--compare`, `--comparison`, `--custom`.

---

## Step 2: Understanding Token Savings (1 minute)

The system uses intelligent template routing to save tokens:

- **Template selected:** code-comparison (based on task keywords)
- **Confidence scoring:** Automatic based on keyword matching
- **Tokens consumed for routing:** Minimal (deterministic routing for high-confidence matches)

Without this system, Claude Code would use LLM tokens to:
1. Parse the command
2. Decide which template to use
3. Generate the template
4. Substitute variables

With the meta-prompt system, routing is optimized through keyword matching and intelligent fallback.

---

## Step 3: Create a Prompt Without Executing (1 minute)

Sometimes you want to see the optimized prompt without executing it:

```bash
/prompt "Refactor authentication module to use JWT tokens" --return-only
```

The `--return-only` flag tells the system to:
1. Generate the optimized prompt
2. Return it to you for review
3. NOT execute it automatically

This is useful when:
- You want to review the prompt before execution
- You want to save the prompt for later use
- You're experimenting with different formulations

---

## Step 4: Handling Tasks Without Templates (1 minute)

For tasks that don't match existing templates, the system automatically routes to the `custom` template:

```bash
/prompt "Write a haiku about programming"
```

**What happens:**
1. Classifier checks all templates (0 tokens with keyword matching, or ~200-500 tokens if LLM fallback needed)
2. No template matches (confidence < 70%)
3. Automatically routes to "custom" template
4. LLM executes with full flexibility

**Result:** You get full LLM flexibility when needed, but save tokens on 90%+ of routine tasks.

---

## Step 5: Explore Available Templates (1 minute)

Six specialized templates plus one custom fallback cover software development workflows:

### 1. Code Comparison
**Use for:** Comparing code, configurations, or technical artifacts
```bash
/prompt --compare "Are these two functions semantically equivalent?"
```

### 2. Code Refactoring
**Use for:** Modifying code, fixing bugs, adding features
```bash
/prompt --code "Add error handling to the user registration function"
```

**Note:** Complex templates automatically guide sub-agents to use TodoWrite for tracking multi-step tasks. This ensures systematic progress and completion verification.

### 3. Test Generation
**Use for:** Generating comprehensive test suites including unit tests, edge cases, and integration tests

This template creates runnable test code following framework-specific conventions (Jest, pytest, JUnit, Mocha, RSpec, Go testing). It analyzes your code to identify happy paths, edge cases, error conditions, and generates tests with proper setup/teardown, mocking, and assertions.

**Variables:**
- `CODE_TO_TEST`: The code that needs test coverage
- `TEST_FRAMEWORK`: Testing framework (Jest, pytest, JUnit, etc.)
- `TEST_SCOPE`: What to test (edge cases, happy path, integration tests)

**Example:**
```bash
/prompt --test "Generate pytest tests for the user registration function covering edge cases and error handling"
```

**Expected output:** Complete test suite with descriptive test names, proper assertions, mocking examples, and coverage of normal operation, edge cases, and error conditions.

### 4. Code Review
**Use for:** Comprehensive code analysis covering security, performance, maintainability, and best practices

This template performs systematic code review across seven dimensions: correctness, security (XSS, SQL injection, CSRF, etc.), performance, readability, error handling, testability, and language conventions. It categorizes issues by severity (Critical/High/Medium/Low) and provides specific, actionable feedback with code examples.

**Variables:**
- `PATHS`: File paths or directories to review (defaults to uncommitted changes if not specified)
- `REVIEW_FOCUS`: Specific areas (security, performance, all aspects)
- `LANGUAGE_CONVENTIONS`: Language/framework standards (PEP 8, Node.js patterns)

**Example:**
```bash
/prompt --review "Review this authentication middleware for security vulnerabilities and Node.js best practices"
```

**Expected output:** Structured review with severity-categorized issues, specific line references, explanations of why issues matter, and concrete suggestions with code examples.

### 5. Documentation Generator
**Use for:** Creating comprehensive documentation in various formats (API docs, READMEs, docstrings, user guides, technical specs)

This template generates documentation tailored to your audience (developers, end users, technical leads) with appropriate technical depth. It structures content based on documentation type (API reference, README, inline comments, user guide, or technical spec) and follows documentation best practices.

**Variables:**
- `CODE_OR_CONTENT`: The code or content to document
- `DOC_TYPE`: Documentation type (API reference, README, inline comments, user guide)
- `AUDIENCE`: Target audience (external developers, internal team, end users)

**Example:**
```bash
/prompt --docs "Generate API reference documentation for the payment processing endpoints targeting external developers"
```

**Expected output:** Complete documentation with clear structure, code examples, parameter tables, return value descriptions, error documentation, and appropriate technical depth for the audience.

### 6. Data Extraction
**Use for:** Extracting specific information from unstructured or semi-structured data (logs, text files, HTML, JSON, CSV)

This template pulls targeted data from raw sources and formats it according to your needs (JSON, CSV, markdown table, plain list). It handles common patterns (emails, URLs, dates, phone numbers, IPs), deals with malformed data gracefully, and provides summaries of extraction results.

**Variables:**
- `SOURCE_DATA`: The raw data to extract from
- `EXTRACTION_TARGETS`: What to extract (emails, timestamps, error codes, etc.)
- `OUTPUT_FORMAT`: Desired format (JSON, CSV, markdown table, plain list)

**Example:**
```bash
/prompt --extract "Extract all error messages and timestamps from this application log and format as JSON"
```

**Expected output:** Extracted data in the requested format, plus a summary with count of items extracted and notes about any anomalies or patterns discovered.

### 7. Custom (Fallback)
**Use for:** Novel tasks that don't fit other templates
- Automatically selected when confidence < 70%
- Full LLM prompt engineering

---

## Validation and Testing

Check that everything is working:

```bash
# Validate all templates
tests/validate-templates.sh
```

**Expected output:**
```
=== Template Validation ===
Validating: code-comparison
  ✓ Has valid frontmatter
  ✓ Has required fields
  [... more checks ...]
PASSED: code-comparison
[... 6 more templates ...]

=== Summary ===
Total templates: 7
Passed: 7
Failed: 0
```

Run integration tests:

```bash
tests/test-integration.sh
```

**Expected output:**
```
Total Tests: 49
Passed: 49
Failed: 0
✓ ALL TESTS PASSED!
```

---

## How It Saves Tokens

### Traditional Approach (No Optimization)

```
User: /prompt "Compare apples and oranges"
↓
LLM orchestration (300 tokens)
↓
LLM template generation (1500 tokens)
↓
LLM executes task (1000 tokens)
= TOTAL: 2800 tokens
```

### Optimized Approach (This System)

```
User: /prompt "Compare apples and oranges"
↓
Bash script orchestration (0 tokens)
↓
Bash template selection (0 tokens)
↓
Bash variable substitution (0 tokens)
↓
LLM executes task (1000 tokens)
= TOTAL: 1000 tokens

SAVINGS: 1800 tokens (64% reduction)
```

---

## Common Patterns

### Pattern 1: Quick Comparisons
```bash
/prompt "Compare REST and GraphQL APIs"
```
→ Uses code-comparison template

### Pattern 2: Code Tasks
```bash
/prompt "Refactor this function to be more modular: [paste code]"
```
→ Uses code-refactoring template

### Pattern 3: Testing
```bash
/prompt "Generate pytest tests for the user authentication module"
```
→ Uses test-generation template

### Pattern 4: Documentation
```bash
/prompt "Create API documentation for the payment endpoints"
```
→ Uses documentation-generator template

---

## Troubleshooting

### Issue: "Permission denied" when running scripts

**Solution:**
```bash
chmod +x commands/scripts/*.sh tests/*.sh
```

### Issue: Template always returns "custom"

**Solution:** Try using explicit template flags to bypass auto-detection:
```bash
/prompt --code "your task here"
/prompt --review "your task here"
```

If auto-detection consistently fails for your use case, see [Template Authoring Guide](template-authoring.md) for customization options.

### Issue: "Template not found" error

**Solution:** Verify templates exist
```bash
ls templates/
# Should show: code-comparison.md, code-refactoring.md, etc.
```

### Issue: Tests failing

**Solution:** Run validation first
```bash
tests/validate-templates.sh
# Fix any reported issues before running tests
```

---

## Next Steps

### Learn More

- **Understand the system:** Read [Architecture Overview](architecture-overview.md)
- **Create your own templates:** Follow [Template Authoring Guide](template-authoring.md)
- **Modify scripts:** See [Script Development Guide](script-development.md)

### Advanced Usage

- **Adjust confidence threshold:** See design-decisions.md:AD-004
- **Add new templates:** See template-authoring.md
- **Monitor token savings:** See infrastructure.md:Monitoring
- **Integrate with CI/CD:** See infrastructure.md:Continuous Integration

### Contributing

Want to improve the system? See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Pull request process
- Code review guidelines
- Testing requirements

---

## Quick Reference Card

### Commands
```bash
# Execute optimized prompt (auto-detects template)
/prompt "task description"

# Execute with explicit template selection
/prompt --code "task description"
/prompt --review "task description"
/prompt --test "task description"

# Generate prompt without executing
/prompt --return-only "task description"
/prompt --code --return-only "task description"
```

### Available Template Flags
- `--code` or `--refactor` → code-refactoring
- `--review` → code-review
- `--test` → test-generation
- `--docs` or `--documentation` → documentation-generator
- `--extract` → data-extraction
- `--compare` or `--comparison` → code-comparison
- `--custom` → custom template

### Validation
```bash
# Validate templates
tests/validate-templates.sh

# Run tests
tests/test-integration.sh
```

### File Locations
```
commands/prompt.md              # /prompt command
commands/scripts/               # Processing scripts
templates/                      # Template library (6 specialized templates + 1 custom fallback)
docs/                           # Documentation
```

---

## Summary

**You've learned:**
- ✓ How to use the `/prompt` command for optimization and execution
- ✓ How the system saves 40-60% in token consumption
- ✓ Which templates exist and when they're used
- ✓ How to validate and test the system
- ✓ Where to go for advanced usage

**Time invested:** 5 minutes
**Token savings unlocked:** 40-60% on all future tasks
