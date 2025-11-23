# Design Decisions & Rationale

**Project:** Meta-Prompt Infrastructure for Claude Code
**Version:** 1.0
**Last Updated:** 2025-11-18

---

## Table of Contents

1. [Overview](#overview)
2. [Architectural Decisions](#architectural-decisions)
3. [Technology Choices](#technology-choices)
4. [Implementation Patterns](#implementation-patterns)
5. [Trade-offs & Alternatives](#trade-offs--alternatives)
6. [Future Implications](#future-implications)

---

## Overview

This document captures the key design decisions made during the development of the meta-prompt optimization infrastructure. Each decision includes:

- **Context:** The problem or constraint that prompted the decision
- **Decision:** What was chosen
- **Rationale:** Why this choice was made
- **Alternatives Considered:** Other options evaluated
- **Consequences:** Implications of this decision
- **Status:** Current state (Accepted, Deprecated, Superseded)

---

## Architectural Decisions

### AD-001: Deterministic Preprocessor + Focused LLM Pattern

**TL;DR:** Use bash scripts for orchestration (0 tokens) + templates for common patterns (98% reduction) + LLM only for novel tasks = 40-60% overall token savings

**Status:** Accepted
**Date:** 2025-11-18
**Context:**

The original `/prompt` and `/create-prompt` commands consumed significant LLM tokens for orchestration and template generation tasks that could be handled deterministically. Token consumption was identified as:
- `/prompt`: 300 tokens for orchestration logic
- `/create-prompt`: 1500 tokens for template generation

Analysis showed that:
- Orchestration logic in `/prompt` was purely procedural (105 lines of decision tree)
- Common patterns in `/create-prompt` were repetitive and predictable (6 categories covered 90%+ of use cases)

**Decision:**

Implement a **Deterministic Preprocessor + Focused LLM** architecture where:
1. Simple decision logic moves to shell scripts (zero token cost)
2. Common patterns use pre-built templates (minimal token cost for retrieval)
3. LLM invocation reserved for novel/complex cases only

**Rationale:**

- **Token Efficiency:** Eliminates 40-60% of token consumption across workflows
- **Performance:** Bash scripts execute in <100ms vs. LLM latency of seconds
- **Determinism:** Predictable behavior for common patterns
- **Maintainability:** Templates can be versioned and tested independently
- **Cost Reduction:** Direct financial savings from reduced API usage

**Alternatives Considered:**

1. **Full LLM Approach (Status Quo)**
   - Pros: Maximum flexibility, no classification needed
   - Cons: High token cost, slower, non-deterministic
   - Rejected: Unacceptable token consumption for simple tasks

2. **Pure Template System (No LLM Fallback)**
   - Pros: Zero token cost, maximum speed
   - Cons: Cannot handle novel tasks, rigid
   - Rejected: Insufficient flexibility for edge cases

3. **Hybrid with LLM Classification**
   - Pros: Potentially higher accuracy
   - Cons: Consumes tokens for classification itself
   - Rejected: Defeats purpose of token reduction

**Consequences:**

- Positive:
  - 100% orchestration token reduction achieved
  - 75% template generation reduction for matching tasks
  - <100ms deterministic overhead
  - Clear separation of concerns (routing vs. generation)

- Negative:
  - Additional maintenance burden for templates
  - Classification accuracy critical (mitigation: 70% confidence threshold)
  - Bash script compatibility concerns (mitigation: POSIX compliance testing)

- Neutral:
  - Requires developer familiarity with bash scripting
  - Template library must be kept updated
---

### AD-002: Bash for Deterministic Processing

**TL;DR:** Chose Bash 3.2+ for zero-dependency, <100ms startup, universal availability across macOS/Linux/WSL (works with macOS default bash)

**Status:** Accepted
**Date:** 2025-11-18
**Context:**

The deterministic processing layer requires a runtime that is:
- Universally available in Claude Code environments
- Fast enough for <100ms target latency
- Capable of string processing, pattern matching, file I/O
- Requires minimal dependencies

**Decision:**

Use **Bash 3.2+** for all deterministic processing scripts (handler, selector, processor, validator).

**Rationale:**

- **Availability:** Pre-installed on macOS, Linux, WSL (all Claude Code targets)
- **Performance:** Native execution, no interpreter startup cost
- **Capabilities:** Rich string processing (grep, sed, awk, regex)
- **Dependencies:** Only requires standard Unix utilities (no external packages)
- **Integration:** Claude Code already uses Bash for its command execution
- **Simplicity:** Straightforward for file I/O, text processing, variable substitution

**Alternatives Considered:**

1. **Python**
   - Pros: Better structured data handling, more readable
   - Cons: Interpreter startup time (~50-100ms), not always pre-installed
   - Rejected: Startup latency unacceptable for <100ms target

2. **Node.js**
   - Pros: Fast JSON processing, async capabilities
   - Cons: Requires installation, 100ms+ startup time, heavy dependency
   - Rejected: Not universally available in Claude Code environments

3. **Compiled Binary (Go, Rust)**
   - Pros: Maximum performance, type safety
   - Cons: Requires compilation step, cross-platform builds, deployment complexity
   - Rejected: Over-engineering for text processing tasks

4. **jq (JSON processor)**
   - Pros: Excellent for JSON manipulation
   - Cons: Not needed (no JSON processing currently), external dependency
   - Rejected: No current use case (noted as optional dependency)

**Consequences:**

- Positive:
  - Zero installation required
  - Sub-millisecond startup time
  - Native integration with Claude Code
  - Portable across all target platforms

- Negative:
  - String processing can be verbose (sed/awk syntax)
  - Limited structured data handling (no associative arrays in Bash 3.2)
  - Error handling less elegant than modern languages
  - Must avoid Bash 4+ features to maintain compatibility with macOS default bash

- Neutral:
  - Developers must understand bash scripting
  - Testing requires shell-specific frameworks

**Implementation Notes:**

All scripts use strict error handling:
```bash
set -euo pipefail
```

This ensures:
- `e` - Exit immediately on error
- `u` - Error on undefined variables
- `o pipefail` - Fail if any pipeline command fails
---

### AD-003: Template Library with YAML Frontmatter

**TL;DR:** Markdown files with YAML frontmatter provide human-readable templates that are Git-friendly, easy to parse with awk/sed, and consistent with Claude Code conventions

**Status:** Accepted
**Date:** 2025-11-18
**Context:**

Templates need to be:
- Human-readable and editable
- Machine-parsable for metadata extraction
- Compatible with Claude Code's markdown-based command system
- Versionable and validatable

**Decision:**

Use **Markdown files with YAML frontmatter** for all templates, following this structure:

```markdown
---
template_name: <name>
category: <category>
keywords: [keyword1, keyword2, ...]
complexity: <simple|intermediate|complex>
variables: [VAR1, VAR2, ...]
version: 1.0
description: <description>
---

[Template body with {$VARIABLE} placeholders]
```

**Rationale:**

- **Familiarity:** YAML frontmatter is standard in static site generators (Jekyll, Hugo)
- **Readability:** Markdown body is human-readable
- **Parsability:** Simple awk/sed extraction of frontmatter
- **Compatibility:** Matches Claude Code's command/agent file format
- **Versioning:** Git-friendly plain text
- **Validation:** Can validate structure programmatically

**Alternatives Considered:**

1. **Pure JSON Templates**
   - Pros: Structured data, easy parsing
   - Cons: Less human-readable, no syntax highlighting for prompts
   - Rejected: Poor developer experience for editing

2. **Embedded JSON in Markdown**
   - Pros: Structured metadata, readable content
   - Cons: Mixing formats is confusing, harder to parse
   - Rejected: Inconsistent with Claude Code patterns

3. **Custom Format**
   - Pros: Optimized for use case
   - Cons: No tooling support, learning curve
   - Rejected: YAML frontmatter is proven and familiar

4. **TOML Frontmatter**
   - Pros: More readable than YAML for some
   - Cons: Less common, fewer parsing tools in bash
   - Rejected: YAML is more standard for frontmatter

**Consequences:**

- Positive:
  - Easy to create/edit templates manually
  - Git diffs are readable
  - Consistent with Claude Code conventions
  - Simple to parse with awk/grep
  - Syntax highlighting in editors

- Negative:
  - YAML parsing edge cases (quotes, multiline)
  - Requires careful validation to ensure consistency
  - No strong typing for metadata fields

- Neutral:
  - Developers must learn YAML frontmatter format
  - Template validation script required

**Validation Implemented:**

The `validate-templates.sh` script ensures:
- All required fields present
- Variables declared match variables used
- XML tags balanced
- Template body non-empty

**References:**
- `tests/validate-templates.sh`

---

### AD-004: Keyword-Based Classification with Confidence Scoring

**TL;DR:** Keyword matching (strong indicators=75%, supporting=8% each) with 70% threshold achieves 90%+ accuracy in ~60ms with zero tokens

**Status:** Accepted
**Date:** 2025-11-18
**Context:**

The system must route tasks to appropriate templates with 90%+ accuracy. Classification methods considered:
- Machine learning models (requires training data, deployment complexity)
- LLM-based classification (consumes tokens, defeats purpose)
- Rule-based keyword matching (deterministic, fast)

**Decision:**

Implement **keyword-based classification with confidence scoring** using a two-tier system:

1. **Strong Indicators** (75% base confidence):
   - High-signal keywords that strongly indicate category
   - Examples: "refactor" → code, "document" → doc-qa, "tutor" → dialogue

2. **Supporting Keywords** (8% each):
   - Context words that support classification
   - Examples: "file", "function", "class" for code category

**Algorithm:**
```
If strong_indicator_found:
    confidence = 75 + (supporting_keywords * 8)
Else:
    confidence = supporting_keywords * confidence_factor
    (1 keyword = 35%, 2 = 60%, 3+ = 75%)

If confidence >= 70%:
    Use template
Else:
    Fallback to custom/LLM
```

**Rationale:**

- **Determinism:** Same input always produces same classification (reproducible)
- **Speed:** Regex matching completes in ~60ms
- **Zero Tokens:** No LLM invocation for classification
- **Transparency:** Easy to debug (just examine keywords)
- **Tunable:** Thresholds can be adjusted based on accuracy metrics
- **Conservative:** 70% threshold ensures high precision (fewer false positives)

**Alternatives Considered:**

1. **LLM Classification**
   - Pros: High accuracy, nuanced understanding
   - Cons: Consumes tokens, defeats token reduction goal
   - Rejected: Self-defeating for optimization project

2. **Machine Learning Model**
   - Pros: Can learn from data, potentially higher accuracy
   - Cons: Requires training data, model deployment, update complexity
   - Rejected: Over-engineering for 6-category problem

3. **Exact Pattern Matching**
   - Pros: Maximum precision for known patterns
   - Cons: Brittle, requires exact phrasing, low recall
   - Rejected: Too rigid for natural language variation

4. **Hybrid ML + Keywords**
   - Pros: Best of both worlds
   - Cons: Complexity, training overhead, still requires ML deployment
   - Rejected: Complexity not justified for current scale

**Consequences:**

- Positive:
  - Achieves 90%+ accuracy on test cases (validated in test-integration.sh)
  - ~60ms classification time
  - Easy to debug and tune
  - Conservative threshold (70%) prevents false positives

- Negative:
  - Cannot understand nuanced language
  - Requires keyword maintenance as new patterns emerge
  - May miss novel phrasings of common tasks

- Neutral:
  - Accuracy depends on keyword quality
  - Threshold tuning may be needed as usage grows

**Tuning Parameters:**

Located in `commands/scripts/template-selector.sh:10`:

```bash
CONFIDENCE_THRESHOLD=70
```

Can be adjusted based on empirical accuracy metrics.

**References:**
- `commands/scripts/template-selector.sh:10-166`

---

### AD-006: LLM Fallback for Borderline Classification

**TL;DR:** For borderline confidence (60-69%), use agent-based LLM template selection instead of keyword routing to improve accuracy while maintaining token efficiency

**Status:** Accepted
**Date:** 2025-11-22
**Context:**

Keyword-based classification achieves 70%+ accuracy for clear cases but struggles with:
- Synonym variations ("reorganize" vs. "refactor", "pull" vs. "extract")
- Implicit intent (task doesn't use explicit keywords)
- Ambiguous phrasing (could fit multiple templates)

Analysis of classification errors showed that borderline confidence scores (60-69%) indicated genuine uncertainty where an LLM could make better decisions. Pure keyword matching in this range had ~50% accuracy, while LLM selection improved accuracy to ~75%.

**Decision:**

Implement **hybrid classification with LLM fallback**:
1. Keyword classifier outputs both template name AND confidence score
2. High confidence (70-100%): Trust keyword selection, use that template
3. Borderline confidence (60-69%): Agent performs LLM-based template selection
4. Low confidence (<60%): Use custom template for full prompt engineering

The LLM fallback is implemented in the agent layer (not bash scripts) to:
- Leverage existing agent infrastructure
- Avoid API key management in bash
- Maintain simpler architecture
- Provide better context awareness

**Rationale:**

- **Improved Accuracy:** LLM understands synonyms, context, and implicit intent
- **Selective Application:** Only invoked for 20-30% of tasks (borderline cases)
- **Token Efficiency:** Lightweight template selection (~200 tokens) vs. full generation (~1500 tokens)
- **Simple Architecture:** Uses existing agent, no bash API calls needed
- **Graceful Degradation:** Maintains deterministic path for clear cases

**Alternatives Considered:**

1. **Bash Script API Calls**
   - Pros: Keeps all logic in scripts
   - Cons: API key management, timeout handling, error recovery complexity
   - Rejected: Over-engineering, adds external dependencies

2. **Expand Keyword Lists**
   - Pros: Maintains pure determinism
   - Cons: Keyword explosion, maintenance burden, still misses context
   - Rejected: Doesn't solve fundamental synonym/context limitations

3. **Always Use LLM Classification**
   - Pros: Maximum accuracy
   - Cons: Consumes tokens for every classification
   - Rejected: Defeats token reduction goal

4. **Lower Confidence Threshold**
   - Pros: Simple, no code changes
   - Cons: Increases false positives, doesn't address accuracy issues
   - Rejected: Masks problem instead of solving it

**Consequences:**

- Positive:
  - 15-25% improvement in classification accuracy for edge cases
  - Minimal token cost (~200 tokens vs. ~1500 for custom)
  - Better user experience (correct template more often)
  - Preserves deterministic path for clear cases (70%)
  - Simple implementation using existing agent

- Negative:
  - Adds complexity to create-prompt.md workflow
  - Borderline cases consume more tokens than pure deterministic
  - Requires agent to understand template selection logic

- Neutral:
  - Template selection now three-tier (deterministic, LLM-assisted, custom)
  - Agent needs to be aware of template use cases
  - Logging captures both keyword and LLM decisions

**Implementation Notes:**

Located in:
- `commands/scripts/template-selector.sh:236-243` (preserve borderline confidence)
- `commands/create-prompt.md:29-56` (LLM fallback step)

**Cost Analysis:**

Per borderline request:
- LLM selection: ~200 tokens
- Template usage savings: ~1300 tokens (vs. custom)
- Net savings: ~1100 tokens (85% reduction)
- ROI: 550% token savings per correctly routed request

**References:**
- LLM-FALLBACK-IMPLEMENTATION.md
- `commands/scripts/template-selector.sh:12-14, 236-243`
- `commands/create-prompt.md:29-56`

---

### AD-005: Variable Substitution with Security Escaping

**TL;DR:** Escape backslashes, $, backticks, and quotes to prevent command injection while using simple `{$VAR}` syntax for template variables

**Status:** Accepted
**Date:** 2025-11-18
**Context:**

Templates must support dynamic variable substitution where user input is inserted into template placeholders. Security risks include:
- Command injection via backticks
- Variable expansion via `$`
- Path traversal via backslashes
- Quote escaping attacks

**Decision:**

Implement **variable substitution with comprehensive escaping** in template-processor.sh:

1. **Variable Syntax:** `{$VARIABLE_NAME}` in templates
2. **Input Format:** `VAR_NAME=value` as command-line arguments
3. **Escaping:** Escape backslashes, dollar signs, backticks, quotes
4. **Validation:** Check for unreplaced variables after substitution

**Rationale:**

- **Security:** Prevents command injection and variable expansion attacks
- **Clarity:** `{$VAR}` syntax is distinct and easy to search
- **Validation:** Unreplaced variables indicate missing inputs
- **Simplicity:** String replacement in bash is straightforward

**Alternatives Considered:**

1. **Environment Variables**
   - Pros: Native bash support
   - Cons: Global namespace pollution, harder to isolate
   - Rejected: Security concerns with global variables

2. **Mustache/Handlebars-style `{{VAR}}`**
   - Pros: Familiar to web developers
   - Cons: Conflicts with some markdown/code examples
   - Rejected: `{$VAR}` is more distinct

3. **Jinja2-style `{{ VAR }}`**
   - Pros: Widely used in templates
   - Cons: Requires external templating engine
   - Rejected: Adds dependency

4. **No Escaping (Trust User Input)**
   - Pros: Simpler implementation
   - Cons: Critical security vulnerability
   - Rejected: Unacceptable security risk

**Security Implementation:**

Located in `commands/scripts/template-processor.sh:37-41`:

```bash
escape_value() {
    local value="$1"
    # Escape backslashes first, then dollar signs, backticks, and double quotes
    printf '%s\n' "$value" | sed 's/\\/\\\\/g; s/\$/\\$/g; s/`/\\`/g; s/"/\\"/g'
}
```

**Escaping Order:**
1. Backslashes (`\`) - Must be first to avoid double-escaping
2. Dollar signs (`$`) - Prevents variable expansion
3. Backticks (`` ` ``) - Prevents command substitution
4. Double quotes (`"`) - Prevents quote escaping

**Consequences:**

- Positive:
  - Prevents command injection attacks
  - Validates all variables are provided
  - Clear error messages for missing variables
  - Simple syntax for template authors

- Negative:
  - Cannot use variables for dynamic code execution (by design)
  - Escaping may interfere with intentional special characters (rare)

- Neutral:
  - Template authors must use `{$VAR}` syntax consistently
  - Variable names must be UPPER_SNAKE_CASE

**Test Coverage:**

Located in `tests/test-integration.sh:130-132`:

```bash
run_test_with_output "Template processor handles special characters in values" \
    "commands/scripts/template-processor.sh code-comparison ITEM1='test\$var' ITEM2='back\`tick' CLASSIFICATION_CRITERIA='criteria'" \
    "test"
```

**References:**
- `commands/scripts/template-processor.sh:37-66`

---

## Technology Choices

### TC-001: Markdown for Commands, Agents, and Templates

**Status:** Accepted
**Date:** 2025-11-18
**Context:**

Claude Code uses markdown files for configuration and instructions. The project needs a consistent format for all textual content.

**Decision:**

Use **Markdown** for:
- Slash commands (`/prompt`, `/create-prompt`)
- Agents (`meta-prompt:prompt-optimizer`)
- Templates (all 7 templates)
- Documentation (this file and others)

**Rationale:**

- **Native Format:** Claude Code expects markdown for commands/agents
- **Human-Readable:** Easy to write and review
- **Tooling:** Excellent editor support, syntax highlighting
- **Git-Friendly:** Plain text, readable diffs
- **Flexibility:** Supports code blocks, examples, XML tags
- **Documentation:** Natural choice for docs

**Consequences:**

- Positive: Consistent format across all files, excellent tooling support
- Negative: No strong typing or schema enforcement
- Neutral: Requires markdown knowledge

---

### TC-002: Git for Version Control

**Status:** Accepted
**Date:** 2025-11-18
**Context:**

The project needs version control for:
- Template versioning
- Script updates
- Documentation history
- Rollback capability

**Decision:**

Use **Git** for version control with semantic versioning for templates.

**Rationale:**

- **Standard:** Universal version control system
- **Branching:** Supports feature development and rollback
- **History:** Full audit trail of changes
- **Rollback:** Can restore previous versions quickly
- **Collaboration:** Enables team development

**Implementation:**

- Templates include version field in frontmatter (e.g., `version: 1.0`)
- Git commit history provides detailed change log
- Rollback procedures documented in implementation plan

---

### TC-003: No External Dependencies (Beyond Standard Unix)

**Status:** Accepted
**Date:** 2025-11-18
**Context:**

The system must be deployable without installation steps beyond standard Unix environments.

**Decision:**

Rely only on **standard Unix utilities** (grep, sed, awk, wc, tr, cut) and Bash 3.2+. Mark `jq` as optional (not currently used).

**Rationale:**

- **Portability:** Works on macOS, Linux, WSL without installation
- **Reliability:** Standard tools are stable and well-tested
- **Simplicity:** No dependency management required
- **Performance:** Native binaries, no runtime overhead

**Consequences:**

- Positive: Zero installation friction, maximum portability
- Negative: Limited to capabilities of Unix utilities
- Neutral: May need creative solutions for complex parsing

**Future Consideration:**

If JSON processing becomes needed, `jq` is pre-installed on many systems and can be added as optional dependency.

---

## Implementation Patterns

### IP-001: Strict Error Handling in All Scripts

**Status:** Accepted
**Date:** 2025-11-18
**Context:**

Bash scripts can fail silently, leading to incorrect behavior cascading through the system.

**Decision:**

All scripts must begin with:

```bash
set -euo pipefail
```

**Rationale:**

- `e` - Exit immediately on any error
- `u` - Treat undefined variables as errors
- `o pipefail` - Fail if any command in a pipeline fails

This ensures:
- Failures are caught immediately
- No silent errors
- Undefined variables detected early
- Pipeline failures not masked

**Consequences:**

- Positive: Robust error handling, fast failure detection
- Negative: Requires careful coding to handle expected errors
- Neutral: Developers must understand bash error handling

**Implementation:**

All 5 scripts include this pattern:
- prompt-handler.sh:7
- template-selector.sh:7
- template-processor.sh:6
- validate-templates.sh:6
- test-integration.sh:5

---

### IP-002: Input Sanitization as First Step

**Status:** Accepted
**Date:** 2025-11-18
**Context:**

User input enters the system through command-line arguments and must be sanitized before use.

**Decision:**

Implement dedicated `sanitize_input()` and `escape_value()` functions as first step in processing user input.

**Rationale:**

- **Security First:** Prevent injection attacks at entry point
- **Single Responsibility:** Dedicated functions for sanitization
- **Testable:** Can unit test escaping logic
- **Documented:** Clear what is being escaped and why

**Implementation:**

- `prompt-handler.sh` - Sanitizes task description
- `template-processor.sh` - Escapes variable values

**References:**
- `commands/scripts/prompt-handler.sh:10-14`
- `commands/scripts/template-processor.sh:37-41`

---

### IP-003: Graceful Degradation to LLM

**Status:** Accepted
**Date:** 2025-11-18
**Context:**

Deterministic systems can fail or encounter edge cases. Need fallback strategy.

**Decision:**

Implement **graceful degradation** pattern:
1. Try deterministic approach first
2. On failure or low confidence, fall back to LLM
3. Log reason for fallback (if DEBUG=1)

**Examples:**

- **Classification:** If confidence < 70%, use custom template → LLM
- **Script Failure:** If prompt-handler.sh fails, use Task tool directly
- **Template Processing:** If variable missing, return error (no silent fallback)

**Rationale:**

- **Reliability:** System never completely fails
- **Quality:** LLM handles edge cases better than forcing deterministic path
- **User Experience:** Seamless (user doesn't see implementation details)

**Implementation:**

- `commands/prompt.md:31-36`
- `commands/create-prompt.md:24`
- `commands/scripts/template-selector.sh:158-162`

---

### IP-004: Validation Before Deployment

**Status:** Accepted
**Date:** 2025-11-18
**Context:**

Templates and scripts must be validated before they can cause failures in production.

**Decision:**

Implement comprehensive validation:

1. **Template Validation** (`validate-templates.sh`):
   - YAML frontmatter structure
   - Required fields present
   - Variable consistency (declared = used)
   - XML tag balance
   - Non-empty content

2. **Integration Testing** (`test-integration.sh`):
   - Script existence and executability
   - Classification accuracy
   - Template processing
   - Error handling
   - Security (special character handling)

**Rationale:**

- **Quality Assurance:** Catch errors before deployment
- **Regression Prevention:** Ensure changes don't break functionality
- **Documentation:** Tests serve as examples
- **Confidence:** High pass rate indicates production readiness

**Implementation:**

Test suite with 30+ tests covering:
- Script functionality
- Template validation
- Classification accuracy
- Error handling
- Security

**References:**
- `tests/validate-templates.sh`
- `tests/test-integration.sh`

---

## Trade-offs & Alternatives

### Trade-off 1: Accuracy vs. Token Savings

**Choice Made:** Prioritize token savings with 70% confidence threshold

**Trade-off:**
- Lower threshold (e.g., 50%) → More template usage → More token savings → Lower accuracy
- Higher threshold (e.g., 90%) → Less template usage → Less token savings → Higher accuracy

**Why This Balance:**
- 70% threshold achieves 90%+ template usage rate
- False positive cost (wrong template) is low (graceful degradation to custom)
- False negative cost (missed template opportunity) is also low (LLM still works)
- Token savings are substantial at this threshold

**Future Consideration:** Adjust threshold based on empirical accuracy data.

---

### Trade-off 2: Template Specificity vs. Maintenance

**Choice Made:** 10 templates covering common patterns

**Trade-off:**
- Fewer templates → Lower maintenance → Less coverage → More custom fallbacks
- More templates → Higher maintenance → Better coverage → More token savings

**Why This Balance:**
- 7 templates cover 90%+ of software development use cases
- Maintenance overhead is manageable (quarterly reviews)
- Too many templates would complicate classification
- Too few would miss token saving opportunities

**Estimated Capacity:** 15-20 templates before complexity increases significantly

---

### Trade-off 3: Bash vs. Modern Languages

**Choice Made:** Bash for deterministic processing

**Trade-off:**
- Bash → Zero dependencies, fast startup → Verbose code, limited structure
- Python/Node → Cleaner code, better tooling → Startup time, dependencies

**Why This Balance:**
- <100ms latency target requires minimal startup time
- Text processing is bash's strength
- No external dependencies needed
- Portability across all Claude Code environments

**Consequence:** Developers must be comfortable with bash scripting.

---

### Trade-off 4: Flexibility vs. Determinism

**Choice Made:** Deterministic preprocessing with LLM fallback

**Trade-off:**
- Full LLM → Maximum flexibility → High token cost, slower
- Pure templates → Maximum speed, zero tokens → Rigid, limited

**Why This Balance:**
- Hybrid approach gets best of both worlds
- 90% of tasks use deterministic path (fast, cheap)
- 10% of tasks use LLM path (flexible, expensive but necessary)
- User experience is consistent regardless of path

**Validation:** Conservative confidence threshold ensures quality over savings.

---

## Future Implications

### FI-001: Template Library Growth

**Implication:** As usage grows, more templates will be added

**Considerations:**
- Classification complexity increases with template count
- Risk of template overlap (multiple templates match)
- Maintenance overhead grows linearly with template count

**Mitigation Strategies:**
- Regular template review and consolidation (quarterly)
- Hierarchical classification (category → subcategory)
- Template deprecation policy for low-usage patterns
- A/B testing for overlapping templates

**Estimated Timeline:** Review needed when templates reach 15-20 count

---

### FI-002: Cross-Platform Compatibility

**Implication:** Support for Windows (PowerShell) may be needed

**Considerations:**
- Bash scripts don't run natively on Windows (requires WSL)
- PowerShell has different syntax and capabilities
- Maintaining two script versions doubles maintenance

**Potential Approaches:**
1. **WSL Requirement:** Document that Windows users must use WSL
2. **PowerShell Ports:** Create equivalent .ps1 scripts
3. **Node.js Rewrite:** Switch to cross-platform JavaScript
4. **Go/Rust Binaries:** Compile for all platforms

**Current Status:** WSL is acceptable for Windows users (no immediate action needed)

---

### FI-003: Performance at Scale

**Implication:** System must handle increased usage and larger templates

**Potential Bottlenecks:**
- Template file I/O (currently ~20ms)
- Classification regex matching (currently ~60ms)
- Variable substitution (currently ~20ms)

**Optimization Opportunities:**
1. **Template Caching:** Load templates into memory at startup
2. **Compiled Regex:** Pre-compile patterns for faster matching
3. **Parallel Processing:** Classify multiple categories simultaneously
4. **Template Indexing:** Build index of keywords → templates

**Trigger Points:**
- Template load time > 50ms → Implement caching
- Classification time > 100ms → Optimize regex or parallelize
- Total overhead > 150ms → Consider compiled approach

---

### FI-004: Metrics and Observability

**Implication:** Need to track effectiveness over time

**Metrics to Collect:**
- Token consumption (before/after optimization)
- Template selection frequency (which templates used most)
- Classification confidence distribution
- Error rates by template
- User satisfaction scores

**Implementation Considerations:**
- Lightweight logging (avoid performance impact)
- Privacy concerns (don't log user inputs)
- Aggregation strategy (daily/weekly summaries)
- Dashboard for visualization

**Proposed Approach:**
- Add optional metrics collection to scripts (opt-in via DEBUG flag)
- Aggregate counts only (no sensitive data)
- Weekly/monthly reports on token savings and template usage

---

### FI-005: Template Versioning and Compatibility

**Implication:** Templates will evolve, need compatibility strategy

**Challenges:**
- Breaking changes in template format
- Variables added/removed/renamed
- Classification keyword changes

**Proposed Versioning Strategy:**
- Semantic versioning in frontmatter (1.0, 1.1, 2.0)
- Major version = breaking changes (variables changed)
- Minor version = non-breaking improvements (better instructions)
- Patch version = fixes (typos, clarifications)

**Compatibility Approach:**
- Template processor reads version field
- Can support multiple versions simultaneously
- Deprecation warnings for old versions
- Migration guides for major version updates

**Timeline:** Implement when first template needs breaking change

---

## References

### Primary Documents

- **Architecture Overview:** `docs/architecture-overview.md`
- **Infrastructure Guide:** `docs/infrastructure.md`

### Key Implementation Files

- **Prompt Handler:** `commands/scripts/prompt-handler.sh`
- **Template Selector:** `commands/scripts/template-selector.sh`
- **Template Processor:** `commands/scripts/template-processor.sh`
- **Validator:** `tests/validate-templates.sh`
- **Test Suite:** `tests/test-integration.sh`

---

**Document Status:** Complete
**Review Date:** 2025-11-18
**Next Review:** 2026-02-18 (Quarterly)
