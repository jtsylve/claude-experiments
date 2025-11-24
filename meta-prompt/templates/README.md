# Template Library

This directory contains pre-built prompt templates for common software development tasks.

## Available Templates

| Template | Variables | Use Cases |
|----------|-----------|-----------|
| **code-refactoring** | TASK_REQUIREMENTS, TARGET_PATTERNS (opt) | Modify code, fix bugs, add features, refactor |
| **code-review** | CODE_TO_REVIEW, REVIEW_FOCUS (opt), REVIEW_DEPTH (opt) | Security audits, quality analysis, code feedback |
| **test-generation** | CODE_TO_TEST, TEST_TYPE (opt), TEST_FRAMEWORK (opt) | Unit tests, test suites, edge cases, coverage |
| **documentation-generator** | CODE_OR_CONTENT, DOC_TYPE, AUDIENCE (opt) | API docs, READMEs, docstrings, guides |
| **data-extraction** | SOURCE, DATA_PATTERN, OUTPUT_FORMAT (opt) | Extract data from logs, JSON, HTML, text |
| **code-comparison** | ITEM1, ITEM2, CLASSIFICATION_CRITERIA | Compare code, configs, check equivalence |
| **custom** | TASK_DESCRIPTION | Novel tasks that don't fit standard templates |

## Template Structure

Each template file follows this structure:

```markdown
---
template_name: <name>
category: <category>
keywords: [keyword1, keyword2, ...]
complexity: <simple|intermediate|complex>
variables: [REQUIRED_VAR1, REQUIRED_VAR2]
optional_variables:
  OPTIONAL_VAR1: "default value"
  OPTIONAL_VAR2: "default value"
version: 1.0
description: <short description>
---

# Template Body

Task instructions with {$VARIABLE} placeholders and {$OPTIONAL_VAR:default value} optional variables.

...
```

## Variable Extraction Heuristics

When the prompt-optimizer agent extracts variables from user tasks, it follows these heuristics:

### Code Refactoring Variables

**TASK_REQUIREMENTS** (required):
- **Extract from:** Action verbs and objectives in the task description
- **Examples:**
  - "Fix the authentication bug" → TASK_REQUIREMENTS="Fix the authentication bug"
  - "Refactor user service to use dependency injection" → TASK_REQUIREMENTS="Refactor user service to use dependency injection"
  - "Add error handling to API endpoints" → TASK_REQUIREMENTS="Add error handling to API endpoints"
- **Pattern:** The main imperative statement describing what to do

**TARGET_PATTERNS** (optional):
- **Extract from:** Specific files, functions, classes, or patterns mentioned
- **Examples:**
  - "Fix bug in login.ts" → TARGET_PATTERNS="login.ts"
  - "Refactor UserService class" → TARGET_PATTERNS="UserService class"
  - "Update all API endpoints in src/api/" → TARGET_PATTERNS="API endpoints in src/api/"
- **Default:** "relevant code" (if not specified)
- **Pattern:** Nouns, file paths, class names, function names, code patterns

### Code Review Variables

**CODE_TO_REVIEW** (required):
- **Extract from:** File paths, code references, module names
- **Examples:**
  - "Review the authentication module" → CODE_TO_REVIEW="authentication module"
  - "Check src/api/users.ts for issues" → CODE_TO_REVIEW="src/api/users.ts"
  - "Review recent changes in UserService" → CODE_TO_REVIEW="UserService"
- **Pattern:** Direct object of the review action

**REVIEW_FOCUS** (optional):
- **Extract from:** Specific aspects mentioned (security, performance, etc.)
- **Examples:**
  - "Review for security vulnerabilities" → REVIEW_FOCUS="security vulnerabilities"
  - "Check code quality and maintainability" → REVIEW_FOCUS="code quality and maintainability"
- **Default:** "code quality, security, and best practices"

**REVIEW_DEPTH** (optional):
- **Extract from:** Depth indicators (quick, thorough, comprehensive)
- **Default:** "thorough"

### Test Generation Variables

**CODE_TO_TEST** (required):
- **Extract from:** Files, functions, classes, modules to test
- **Examples:**
  - "Generate tests for UserService" → CODE_TO_TEST="UserService"
  - "Write tests for src/utils/auth.ts" → CODE_TO_TEST="src/utils/auth.ts"
  - "Create test suite for authentication flow" → CODE_TO_TEST="authentication flow"
- **Pattern:** Noun phrases indicating what to test

**TEST_TYPE** (optional):
- **Extract from:** Test type keywords (unit, integration, e2e, edge cases)
- **Examples:**
  - "Write unit tests" → TEST_TYPE="unit tests"
  - "Generate edge case tests" → TEST_TYPE="edge case tests"
- **Default:** "unit tests and edge cases"

**TEST_FRAMEWORK** (optional):
- **Extract from:** Framework names (Jest, pytest, JUnit, Mocha)
- **Default:** "the project's existing test framework"

### Documentation Generator Variables

**CODE_OR_CONTENT** (required):
- **Extract from:** What needs to be documented
- **Examples:**
  - "Document the UserService API" → CODE_OR_CONTENT="UserService API"
  - "Create README for the project" → CODE_OR_CONTENT="the project"
  - "Write docstrings for auth functions" → CODE_OR_CONTENT="auth functions"
- **Pattern:** The target of documentation

**DOC_TYPE** (required):
- **Extract from:** Documentation type keywords
- **Examples:**
  - "Write API documentation" → DOC_TYPE="API documentation"
  - "Create a README" → DOC_TYPE="README"
  - "Add inline comments" → DOC_TYPE="inline comments"
  - "Generate user guide" → DOC_TYPE="user guide"
- **Pattern:** Type of documentation requested

**AUDIENCE** (optional):
- **Extract from:** Audience indicators (developers, users, maintainers)
- **Default:** "developers who will use or maintain this code"

### Data Extraction Variables

**SOURCE** (required):
- **Extract from:** Data source (file, log, JSON, HTML, text)
- **Examples:**
  - "Extract emails from logs" → SOURCE="logs"
  - "Parse data from config.json" → SOURCE="config.json"
  - "Get timestamps from server logs" → SOURCE="server logs"
- **Pattern:** Source of data to extract from

**DATA_PATTERN** (required):
- **Extract from:** What to extract (emails, timestamps, usernames, etc.)
- **Examples:**
  - "Extract email addresses" → DATA_PATTERN="email addresses"
  - "Parse timestamps and error codes" → DATA_PATTERN="timestamps and error codes"
  - "Get all user IDs" → DATA_PATTERN="user IDs"
- **Pattern:** The data pattern or type to extract

**OUTPUT_FORMAT** (optional):
- **Extract from:** Desired output format (JSON, CSV, list)
- **Default:** "structured format (JSON or list)"

### Code Comparison Variables

**ITEM1** (required):
- **Extract from:** First item to compare
- **Examples:**
  - "Compare version A to version B" → ITEM1="version A"
  - "Check if 'foo' equals 'bar'" → ITEM1="'foo'"
  - "Compare old config and new config" → ITEM1="old config"
- **Pattern:** First noun, quoted string, or entity mentioned

**ITEM2** (required):
- **Extract from:** Second item to compare
- **Examples:**
  - "Compare version A to version B" → ITEM2="version B"
  - "Check if 'foo' equals 'bar'" → ITEM2="'bar'"
  - "Compare old config and new config" → ITEM2="new config"
- **Pattern:** Second noun, quoted string, or entity mentioned (often after "to", "and", "vs")

**CLASSIFICATION_CRITERIA** (required):
- **Extract from:** The comparison criteria or question
- **Examples:**
  - "Check if they're equivalent" → CLASSIFICATION_CRITERIA="equivalence"
  - "Determine if they do the same thing" → CLASSIFICATION_CRITERIA="functional equivalence"
  - "See if they're duplicates" → CLASSIFICATION_CRITERIA="duplication"
- **Pattern:** Interrogative statements or comparison criteria

### Custom Template Variables

**TASK_DESCRIPTION** (required):
- **Extract from:** The entire user task
- **Pattern:** Complete task description for novel/custom cases

## Adding New Templates

To add a new template:

1. **Create template file:** `templates/new-template.md`
2. **Define variables:** Add YAML frontmatter with `variables` and `optional_variables`
3. **Write template body:** Use `{$VARIABLE}` for required and `{$VARIABLE:default}` for optional
4. **Add keywords:** Update `template-selector-handler.sh` with classification keywords
5. **Create skill:** Add `skills/new-template.md` with domain expertise
6. **Update documentation:** Add to this README and main README.md
7. **Test:** Run `test-integration.sh` to verify

## Template Guidelines

**Good templates are:**
- **Focused:** Single, well-defined purpose
- **Reusable:** Applicable to multiple similar tasks
- **Efficient:** Minimize required variables
- **Clear:** Explicit instructions with examples
- **Validated:** Include success criteria and error handling

**Avoid:**
- **Over-generalization:** Templates too broad lose effectiveness
- **Too many variables:** More than 3-4 variables makes extraction complex
- **Ambiguous instructions:** Be explicit about expected behavior
- **Missing defaults:** Optional variables should have sensible defaults
