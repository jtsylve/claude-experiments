# Glossary

Key terminology used in the meta-prompt optimization infrastructure.

---

## Core Concepts

### Deterministic Preprocessor
A bash script that makes routing and processing decisions without consuming LLM tokens. Deterministic means the same input always produces the same output, enabling zero-token orchestration.

**Example:** `template-selector.sh` classifies tasks using keyword matching (deterministic) instead of LLM analysis (non-deterministic).

**Related:** Architectural pattern (AD-001)

---

### Template
A pre-built prompt pattern with variable placeholders that can be reused for similar tasks. Templates eliminate the need for LLM-based prompt generation.

**Example:** The `code-comparison` template handles comparison tasks like "Compare Python and JavaScript".

**File location:** `templates/*.md`

---

### Template Match Rate
The percentage of tasks that successfully route to templates (vs. falling back to custom LLM generation). Target: 90%+

**Calculation:** (Templates selected / Total tasks) × 100

**Current status:** 90%+ based on test suite

---

### Confidence Threshold
The minimum confidence score (default: 70%) required to use a template instead of falling back to custom LLM generation.

**Why 70%:** Balances token savings with classification accuracy. Lower threshold = more savings but more misclassifications. Higher threshold = fewer savings but higher accuracy.

**Location:** `template-selector.sh:10`

---

### Classification
The process of analyzing a task description and routing it to the appropriate template category using keyword matching and confidence scoring.

**Algorithm:**
1. Extract keywords from task
2. Match against template keywords
3. Calculate confidence score
4. Select template if confidence ≥ 70%

**Script:** `commands/scripts/template-selector.sh`

---

### Confidence Score
A percentage (0-100%) indicating how well a task matches a template. Calculated by:
- Strong indicators: 75% base confidence
- Supporting keywords: +8% each
- Maximum: capped at 100%

**Example:** "Refactor the authentication code" → code-refactoring template, 91% confidence

---

### Variable Substitution
The process of replacing `{$VARIABLE}` placeholders in templates with actual values provided by the user or extracted from the task.

**Example:**
```
Template: "Compare {$ITEM1} and {$ITEM2}"
After substitution: "Compare Python and JavaScript"
```

**Script:** `commands/scripts/template-processor.sh`

---

## Template Components

### YAML Frontmatter
Metadata section at the top of template files, enclosed in `---` delimiters. Contains configuration like template name, keywords, variables, and version.

**Format:**
```yaml
---
template_name: code-comparison
category: comparison
keywords: [compare, classify, similar]
complexity: simple
variables: [ITEM1, ITEM2]
version: 1.0
---
```

---

### Strong Indicator
A keyword that provides 75% base confidence when matched. These are high-signal words that strongly indicate a specific template.

**Examples:**
- "refactor" → code-refactoring
- "sentiment" → sentiment-analysis
- "tutor" → interactive-dialogue

**vs. Supporting Keywords:** Supporting keywords only add 8% each, requiring multiple matches for high confidence.

---

### Supporting Keyword
A keyword that adds 8% confidence when matched. These are context words that support classification but aren't sufficient alone.

**Examples:**
- "code", "function", "file" for code-refactoring
- "document", "question", "cite" for document-qa

**Usage:** Need multiple supporting keywords to reach 70% threshold without a strong indicator.

---

### Template Body
The main content of a template file, containing the prompt structure with `{$VARIABLE}` placeholders that get substituted during processing.

**Example:**
```markdown
You are checking whether two items match.

<item1>
{$ITEM1}
</item1>

<item2>
{$ITEM2}
</item2>

Analyze whether these items match...
```

---

### Category
A broad grouping of related templates. Used for organization and naming conventions.

**Current categories:**
- `comparison`: Comparing items (code-comparison)
- `analysis`: Analyzing documents or data (document-qa)
- `development`: Code-related tasks (code-refactoring)
- `conversation`: Interactive agents (interactive-dialogue)
- `fallback`: Novel tasks (custom)

---

## System Components

### Slash Command
A user-facing command in Claude Code that starts with `/`. This project implements two: `/prompt` and `/create-prompt`.

**Usage:**
```bash
/prompt "task description"
/create-prompt "task description"
```

**Implementation:** Markdown files in `commands/`

---

### Agent
An LLM-powered subprocess that handles complex tasks autonomously. This project uses `meta-prompt:prompt-optimizer` for novel cases.

**vs. Deterministic Scripts:** Agents consume tokens, scripts don't. Use scripts when possible, agents when necessary.

**Location:** `agents/meta-prompt:prompt-optimizer.md`

---

### Orchestration
The process of coordinating multiple steps in a workflow. Traditional approach uses LLM tokens; optimized approach uses bash scripts.

**Token savings:** 100% of orchestration overhead (300 tokens per workflow)

---

### Token Reduction
The percentage decrease in token consumption achieved by using deterministic preprocessing instead of LLM-based orchestration and template generation.

**Current results:**
- Orchestration: 100% reduction (300 tokens saved)
- Template generation: 98% reduction (1480 tokens saved)
- Overall: 40-60% average reduction

---

## Technical Terms

### Bash 3.2+
The minimum version of the Bash shell required for this project. Works with the default bash shipped with macOS.

**Check version:** `bash --version`

**Features used:** `[[` conditionals, regex matching (`=~`), BASH_REMATCH, string replacement (`//`), here-strings, indexed arrays.

**Why 3.2+:** All required features are available in Bash 3.2, avoiding the need for Homebrew installation on macOS.

---

### Input Sanitization
The process of escaping or removing dangerous characters from user input to prevent command injection and other security vulnerabilities.

**Escaped characters:**
- Backslashes: `\` → `\\`
- Dollar signs: `$` → `\$`
- Backticks: `` ` `` → `` \` ``
- Quotes: `"` → `\"`

**Function:** `sanitize_input()` in prompt-handler.sh

---

### set -euo pipefail
A bash safety pattern that ensures scripts fail fast and catch errors early.

**Flags:**
- `e`: Exit immediately on error
- `u`: Treat undefined variables as errors
- `o pipefail`: Fail if any command in pipeline fails

**Usage:** Every script starts with this

---

### Associative Array
A bash data structure (hash map) that stores key-value pairs.

**Example:**
```bash
declare -A keywords=(
    [strong]="refactor|modify"
    [supporting]="code|function|file"
)
```

**Requirement:** Bash 4.0+

**Note:** Not currently used in this project to maintain Bash 3.2 compatibility.

---

### Exit Code
A number returned by a command or script indicating success (0) or failure (non-zero).

**Conventions:**
- `0`: Success
- `1`: Generic error
- `2-255`: Specific errors (documented per script)

**Check:** `echo $?` after running command

---

## Metrics and Performance

### Token Consumption
The number of tokens sent to and received from the LLM API. Each token costs money and contributes to latency.

**Typical values:**
- Orchestration (old): 300 tokens
- Template generation (old): 1500 tokens
- Template retrieval (new): 20 tokens

---

### Overhead
The additional time or resources required by the optimization infrastructure before LLM invocation.

**Target:** <100ms total
**Actual:**
- Script execution: <10ms
- Classification: ~60ms
- Template processing: <20ms
- Template loading: <20ms

---

### False Positive Rate
The percentage of tasks incorrectly classified to a template when they should have used custom LLM generation.

**Impact:** Task may not execute optimally but graceful degradation prevents failures.

**Target:** <10%

---

### False Negative Rate
The percentage of tasks that should match a template but fall back to custom LLM generation instead.

**Impact:** Missed token savings opportunity but functionality works correctly.

**Target:** <10%

---

## File Formats

### Markdown
A lightweight markup language used for all templates, commands, agents, and documentation.

**Extensions:** `.md`

**Advantages:** Human-readable, Git-friendly, excellent tooling support

---

### Shell Script
Executable bash programs that handle deterministic processing.

**Extensions:** `.sh`

**Requirements:** Must be executable (`chmod +x`)

**Standard header:**
```bash
#!/usr/bin/env bash
set -euo pipefail
```

---

### JSON
Data format used for configuration files.

**Usage:** `.claude-plugin/settings.json` for permissions

**Note:** Not used in templates (YAML frontmatter instead)

---

## Workflow Terms

### Graceful Degradation
The system's ability to fall back to LLM-based generation when templates don't match, ensuring functionality never fails due to classification errors.

**Example:** Novel task → 0% confidence → custom template → LLM generation

---

### Progressive Disclosure
Documentation strategy of presenting simple information first, with details available deeper in the document or in specialized guides.

**Example:** README provides overview, detailed architecture in architecture-overview.md

---

### Whitelist-Based Security
Security model where only explicitly allowed operations can execute. Opposite of blacklist (blocking specific bad things).

**Implementation:** `.claude-plugin/settings.json` permissions

---

## Abbreviations

### LLM
**Large Language Model** - AI systems like Claude that generate text based on prompts

---

### YAML
**YAML Ain't Markup Language** - Human-friendly data serialization format

---

### CLI
**Command Line Interface** - Text-based interface for interacting with programs

---

### ADR / TC / IP
**Architectural Decision Record / Technology Choice / Implementation Pattern** - Document categories in design-decisions.md

---

## Related Resources

- **[Architecture Overview](architecture-overview.md)** - System design
- **[Design Decisions](design-decisions.md)** - Decision rationale
- **[Template Authoring](template-authoring.md)** - Creating templates
- **[Script Development](script-development.md)** - Bash scripting guide

---

**Document Version:** 1.0
**Last Updated:** 2025-11-18
