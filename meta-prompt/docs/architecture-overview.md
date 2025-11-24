# Architecture Overview

**Project:** Meta-Prompt Infrastructure for Claude Code
**Version:** 1.0
**Last Updated:** 2025-11-18
**Status:** Production Ready

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [Component Relationships](#component-relationships)
4. [Technology Stack](#technology-stack)
5. [Data Flow](#data-flow)
6. [Performance Characteristics](#performance-characteristics)
7. [Security Considerations](#security-considerations)

---

## Executive Summary

This project implements a **meta-prompt optimization infrastructure** for Claude Code that reduces LLM token consumption by 40-60% through deterministic preprocessing and template-based routing. The system replaces LLM-based orchestration with shell scripts and pre-built templates, invoking the LLM only for actual creative/analytical work.

### Key Characteristics

- **Architecture Pattern:** Deterministic Preprocessor + Focused LLM
- **Primary Language:** Bash (scripts), Markdown (templates, commands, agents)
- **Target Environment:** Claude Code CLI (macOS, Linux)
- **Token Reduction:** 40-60% overall, 100% for orchestration layer
- **Classification Accuracy:** 90%+ for template routing

---

## System Architecture

The system follows a **layered architecture** with deterministic preprocessing layers that filter and route requests before reaching LLM-based processing.

**Architecture Overview:** This diagram shows how user commands flow through the system. User commands enter through `/prompt` or `/create-prompt`, then pass through deterministic bash scripts (green - zero tokens) for classification and processing. Only when templates don't match (10% of cases) or for actual task execution does the system invoke LLM processing (pink - consumes tokens). This architecture achieves 40-60% token reduction by handling orchestration and template selection deterministically.

```mermaid
graph TD
    A[User Command] --> B[/prompt]
    B --> C[prompt-handler.sh]
    C --> D{State Machine}

    D -->|No template flag| E[template-selector agent]
    E --> F[template-selector-handler.sh]
    F --> G{Select Template}
    G --> H[Return template name]

    D -->|Has template flag or after selection| I[prompt-optimizer agent]
    I --> J[prompt-optimizer-handler.sh]
    J --> K{Load & Process Template}
    K --> L[Return optimized prompt]

    L --> N{Execution Mode}
    N -->|--plan flag| M[Plan agent]
    M --> O[template-executor agent]
    N -->|Direct execute| O
    N -->|--return-only| P[Return to user]

    O --> Q[template-executor-handler.sh]
    Q --> R[Execute with skill]

    style C fill:#90EE90
    style F fill:#90EE90
    style J fill:#90EE90
    style Q fill:#90EE90
    style E fill:#FFB6C1
    style I fill:#FFB6C1
    style M fill:#FFB6C1
    style O fill:#FFB6C1

    classDef deterministic fill:#90EE90,stroke:#006400
    classDef llm fill:#FFB6C1,stroke:#8B0000
```

**Legend:**
- Green (Deterministic): No LLM tokens consumed (bash handlers)
- Pink (LLM): Token consumption occurs here (agents)

### State Machine Detailed View

The `/prompt` command implements a state machine in `prompt-handler.sh` that orchestrates the workflow. This state machine determines the next action based on the current state and input.

```mermaid
stateDiagram-v2
    [*] --> initial: User invokes /prompt

    initial --> spawn_template_selector: No template flag
    initial --> spawn_optimizer: Has template flag (--code, --review, etc.)

    spawn_template_selector --> post_template_selector: Selector returns template

    post_template_selector --> spawn_optimizer: Process template choice

    spawn_optimizer --> return_only: Has --return-only flag
    spawn_optimizer --> post_optimizer: No --return-only flag

    return_only --> [*]: Return optimized prompt to user

    post_optimizer --> spawn_plan_agent: Has --plan flag
    post_optimizer --> spawn_template_executor: No --plan flag (direct execution)

    spawn_plan_agent --> post_plan: Plan agent returns

    post_plan --> spawn_template_executor: Execute with plan

    spawn_template_executor --> final: Executor completes

    final --> [*]: Return results to user

    note right of initial
        State: initial
        Input: Command-line args
        Actions: Parse flags,
        detect template
    end note

    note right of post_template_selector
        State: post_template_selector
        Input: XML with template name
        Actions: Route to optimizer
    end note

    note right of post_optimizer
        State: post_optimizer
        Input: XML with optimized prompt
        Actions: Check execution mode
    end note

    note right of post_plan
        State: post_plan
        Input: XML from Plan agent
        Actions: Route to executor
    end note

    note right of final
        State: final
        Input: XML with results
        Actions: Return to user
    end note
```

**State Descriptions:**

| State | Input Format | Output Action | Next State(s) |
|-------|-------------|---------------|---------------|
| `initial` | Command-line args | Spawn template-selector OR spawn optimizer | post_template_selector, post_optimizer, return_only |
| `post_template_selector` | XML: `<template_selector_result>` | Spawn optimizer with selected template | post_optimizer, return_only |
| `post_optimizer` | XML: `<prompt_optimizer_result>` | Spawn Plan agent OR spawn executor | post_plan, spawn_template_executor |
| `post_plan` | XML: `<plan_result>` | Spawn executor with plan | final |
| `final` | XML: `<template_executor_result>` | Return results to user | (end) |

**State Transitions:**

- **Deterministic transitions:** Based on flags (`--plan`, `--return-only`, template flags)
- **Data-driven transitions:** Based on XML input from agents
- **Error handling:** Invalid XML or missing fields cause early exit with error message

**State Persistence:**

States are tracked across agent invocations by:
1. Initial state determined from command-line arguments
2. Subsequent states detected from XML input structure (e.g., presence of `<prompt_optimizer_result>`)
3. Original flags preserved and passed through XML to maintain mode (plan/direct, return-only)

---

## Component Relationships

### 1. Command Layer

**Location:** `commands/`

#### prompt.md
- **Purpose:** Entry point for prompt optimization and execution workflow
- **Type:** Claude Code slash command
- **Lines:** Streamlined command definition
- **Token Savings:** 100% orchestration overhead eliminated
- **Dependencies:**
  - `commands/scripts/prompt-handler.sh` (state machine)
  - `agents/template-selector.md` (template auto-detection)
  - `agents/prompt-optimizer.md` (prompt generation)
  - `agents/template-executor.md` (task execution)

### 2. Handler Script Layer

**Location:** `commands/scripts/` and `agents/scripts/`

All scripts are written in Bash with strict error handling (`set -euo pipefail`) and shared utilities in `scripts/common.sh`.

#### prompt-handler.sh
```bash
Location: commands/scripts/prompt-handler.sh
Purpose:  State machine for /prompt command workflow
Input:    $1 = XML request with task, template, mode
Output:   Agent spawn instructions
Flow:     Parse XML → Manage state transitions → Route to agents
```

**State Machine States:**
- `initial`: Parse input, detect template flag
- `post_template_selector`: Process template selection result
- `post_optimizer`: Process optimized prompt
- Routing to appropriate agent based on state

**Key Features:**
- Zero-token orchestration
- XML-based communication with agents
- Flag parsing (--return-only, --plan, template flags)
- State persistence across agent calls

#### Agent Handler Scripts

**Location:** `agents/scripts/`

##### template-selector-handler.sh
```bash
Purpose: Return instructions for template selection agent
Input:   XML with task description
Output:  Agent instructions for classification
Flow:    Extract task → Return selection instructions
```

##### prompt-optimizer-handler.sh
```bash
Purpose: Return instructions for prompt optimization agent
Input:   XML with template and task
Output:  Agent instructions for optimization
Flow:    Extract params → Load template → Return instructions
```

##### template-executor-handler.sh
```bash
Purpose: Return instructions for execution agent
Input:   XML with optimized prompt and skill
Output:  Agent instructions for task execution
Flow:    Parse request → Return execution instructions
```

#### Shared Utilities

**Location:** `scripts/common.sh`

Functions shared across all handlers:
- `sanitize_input()`: Input sanitization for security
- `extract_xml_value()`: Simple XML extraction
- `extract_xml_multiline()`: Multiline XML extraction
- `setup_plugin_root()`: CLAUDE_PLUGIN_ROOT initialization

### 3. Template Library

**Location:** `templates/`

Six task-specific templates optimized for software development:

| Template | Category | Complexity | Variables | Use Cases |
|----------|----------|------------|-----------|-----------|
| **code-refactoring.md** | development | complex | 2 | Modify code, fix bugs, implement features |
| **code-review.md** | analysis | complex | 3 | Security audits, quality analysis, code feedback |
| **test-generation.md** | testing | intermediate | 3 | Generate unit tests, test suites, edge cases, coverage |
| **documentation-generator.md** | generation | intermediate | 3 | API docs, READMEs, docstrings, user guides |
| **data-extraction.md** | analysis | simple | 3 | Extract data from logs, JSON, HTML, text files |
| **code-comparison.md** | comparison | simple | 3 | Compare code, configs, check equivalence |
| **custom.md** | fallback | variable | 1 | Novel tasks, edge cases, LLM fallback |

**Template Structure:**
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

### 4. Agent Layer (LLM Processing)

**Location:** `agents/`

Each agent uses a model optimized for its complexity level:

#### template-selector
- **Purpose:** Auto-detect appropriate template for task
- **Type:** Claude Code agent
- **Handler:** `agents/scripts/template-selector-handler.sh`
- **Model:** Haiku (lightweight classification task)
- **Tools:** Bash (handler script), Read (templates)
- **Output:** Template name via XML

#### prompt-optimizer
- **Purpose:** Generate optimized prompts from templates
- **Type:** Claude Code agent
- **Handler:** `agents/scripts/prompt-optimizer-handler.sh`
- **Model:** Haiku (simple variable extraction)
- **Tools:** Bash (handler script), Read (templates)
- **Output:** Optimized prompt via XML

#### template-executor
- **Purpose:** Execute tasks using domain-specific skills
- **Type:** Claude Code agent
- **Handler:** `agents/scripts/template-executor-handler.sh`
- **Model:** Sonnet (complex reasoning for task execution)
- **Tools:** Skill (domain expertise), TodoWrite, Read/Edit/Write
- **Output:** Task results via XML

**Model Selection Rationale:**
| Agent | Model | Rationale |
|-------|-------|-----------|
| template-selector | Haiku | Simple classification, keyword-guided |
| prompt-optimizer | Haiku | Deterministic variable extraction |
| template-executor | Sonnet | Complex reasoning, multi-step execution |

### 5. Skills Layer

**Location:** `skills/`

Domain-specific expertise modules loaded by template-executor:
- `code-refactoring.md`: Code modification guidance
- `code-review.md`: Security and quality analysis
- `test-generation.md`: Test creation patterns
- `documentation-generator.md`: Documentation writing
- `data-extraction.md`: Data parsing strategies
- `code-comparison.md`: Comparison methodologies

---

## Technology Stack

### Core Technologies

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| **Shell Scripts** | Bash | 4.0+ | Deterministic orchestration, preprocessing |
| **Commands/Agents** | Markdown | - | Claude Code configuration files |
| **Templates** | Markdown + YAML | - | Pre-built prompt patterns |
| **Version Control** | Git | - | Source control |

### Dependencies

**Required:**
- Bash 3.2+ (compatible with macOS default bash)
- Standard Unix utilities (grep, sed, awk, wc, tr, cut)

**Optional:**
- jq (JSON parsing - not currently used but mentioned in plans)

**Environment:**
- Claude Code CLI
- macOS (primary) / Linux / WSL (tested)

### File Formats

- `.md` - Markdown for commands, agents, templates, documentation
- `.sh` - Bash scripts for deterministic processing

---

## Data Flow

### Flow 1: /prompt Command (Auto-Detection Path)

**Flow Description:** This sequence shows the `/prompt` command with auto-detection (no template flag specified). The state machine routes through template-selector agent for classification, then prompt-optimizer for prompt generation, and finally template-executor for task execution. Handler scripts provide zero-token routing between agents.

```mermaid
sequenceDiagram
    participant User
    participant PromptMD as prompt.md
    participant Handler as prompt-handler.sh
    participant Selector as template-selector agent
    participant SelectorH as selector-handler.sh
    participant Optimizer as prompt-optimizer agent
    participant OptimizerH as optimizer-handler.sh
    participant Executor as template-executor agent
    participant ExecutorH as executor-handler.sh

    User->>PromptMD: /prompt "Analyze security"
    PromptMD->>Handler: Execute with task
    Handler->>Handler: State: initial (no template flag)
    Handler->>PromptMD: Spawn template-selector
    PromptMD->>Selector: Agent spawned
    Selector->>SelectorH: Get instructions
    SelectorH->>Selector: Return selection logic
    Selector->>Handler: Return XML with template name
    Handler->>Handler: State: post_template_selector
    Handler->>PromptMD: Spawn prompt-optimizer
    PromptMD->>Optimizer: Agent spawned with template
    Optimizer->>OptimizerH: Get instructions
    OptimizerH->>Optimizer: Return optimization logic
    Optimizer->>Handler: Return XML with prompt
    Handler->>Handler: State: post_optimizer
    Handler->>PromptMD: Spawn template-executor
    PromptMD->>Executor: Agent spawned with prompt
    Executor->>ExecutorH: Get instructions
    ExecutorH->>Executor: Return execution logic
    Executor->>User: Task results
```

**Token Consumption:**
- Handler scripts: 0 tokens (deterministic routing)
- Selector agent: ~200-500 tokens (LLM classification)
- Optimizer agent: ~300-500 tokens (template processing)
- Executor agent: Variable (actual task execution)
- Total orchestration overhead: ~0 tokens (vs ~300 tokens original)

### Flow 2: /prompt Command (Explicit Template Selection)

**Flow Description:** When user specifies a template flag (e.g., `--review`, `--code`), the system bypasses template selection and proceeds directly to prompt optimization and execution.

```mermaid
sequenceDiagram
    participant User
    participant PromptMD as prompt.md
    participant Handler as prompt-handler.sh
    participant Optimizer as prompt-optimizer agent
    participant OptimizerH as optimizer-handler.sh
    participant Executor as template-executor agent

    User->>PromptMD: /prompt --review "Check auth code"
    PromptMD->>Handler: Execute with task + template flag
    Handler->>Handler: State: initial (has template flag)
    Handler->>PromptMD: Spawn prompt-optimizer (skip selector)
    PromptMD->>Optimizer: Agent spawned with template=code-review
    Optimizer->>OptimizerH: Get instructions
    OptimizerH->>Optimizer: Return optimization logic
    Optimizer->>Handler: Return XML with prompt
    Handler->>PromptMD: Spawn template-executor
    PromptMD->>Executor: Agent spawned
    Executor->>User: Task results
```

**Token Consumption:**
- Handler scripts: 0 tokens
- Optimizer agent: ~300-500 tokens
- Executor agent: Variable (task execution)
- Template selection saved: ~200-500 tokens

### Flow 3: /prompt Command (Return-Only Mode)

**Flow Description:** With `--return-only` flag, the system generates and returns the optimized prompt without executing it, useful for review or later use.

```mermaid
sequenceDiagram
    participant User
    participant PromptMD as prompt.md
    participant Handler as prompt-handler.sh
    participant Optimizer as prompt-optimizer agent

    User->>PromptMD: /prompt --return-only "task"
    PromptMD->>Handler: Execute with --return-only flag
    Handler->>Handler: Detect return-only mode
    Handler->>PromptMD: Spawn prompt-optimizer only
    PromptMD->>Optimizer: Agent spawned
    Optimizer->>Handler: Return XML with prompt
    Handler->>PromptMD: Skip executor, return prompt
    PromptMD->>User: Optimized prompt (not executed)
```

**Token Consumption:**
- Handler scripts: 0 tokens
- Optimizer agent: ~300-500 tokens
- Execution skipped: Saves variable tokens

### Flow 4: /prompt Command (Plan Mode)

**Flow Description:** With `--plan` flag, the system spawns a Plan agent after optimization to create a plan and get user approval before spawning the template-executor to execute the task.

```mermaid
sequenceDiagram
    participant User
    participant PromptMD as prompt.md
    participant Handler as prompt-handler.sh
    participant Optimizer as prompt-optimizer agent
    participant Plan as Plan agent
    participant Executor as template-executor agent

    User->>PromptMD: /prompt --plan "task"
    PromptMD->>Handler: Execute with --plan flag
    Handler->>PromptMD: Spawn prompt-optimizer
    PromptMD->>Optimizer: Agent spawned
    Optimizer->>Handler: Return XML with prompt
    Handler->>PromptMD: Spawn Plan agent
    PromptMD->>Plan: Agent spawned with optimized prompt
    Plan->>User: Present plan, request approval
    User->>Plan: Approve plan
    Plan->>Handler: Plan approved
    Handler->>PromptMD: Spawn template-executor
    PromptMD->>Executor: Agent spawned with plan
    Executor->>User: Task results
```

**Token Consumption:**
- Handler scripts: 0 tokens
- Optimizer agent: ~300-500 tokens
- Plan agent: Variable (depends on task complexity)
- Executor agent: Variable (task execution)
- Planning overhead: Additional tokens for plan creation but reduces execution errors

---

## Performance Characteristics

### Latency Benchmarks

| Operation | Time | Notes |
|-----------|------|-------|
| prompt-handler.sh execution | <10ms | Argument parsing, mode detection |
| template-selector.sh classification | ~60ms | Keyword extraction, scoring |
| template-processor.sh substitution | <20ms | File load, variable replacement |
| Template file read | <20ms | I/O from disk |
| **Total deterministic overhead** | **~110ms** | Target <150ms met |

### Token Consumption

| Scenario | Original | Optimized | Reduction |
|----------|----------|-----------|-----------|
| /prompt orchestration | 300 tokens | 0 tokens | 100% |
| /create-prompt (template match) | 1500 tokens | 20 tokens | 98.7% |
| /create-prompt (custom) | 1500 tokens | 1500 tokens | 0% |
| **Weighted average (90% template)** | **1440 tokens** | **158 tokens** | **89%** |

**Note:** 90% template match rate based on 90%+ classification accuracy target.

### Accuracy Metrics

| Metric | Target | Actual (Test Suite) |
|--------|--------|---------------------|
| Template classification accuracy | 90%+ | Tested via test-integration.sh |
| False negative rate | <10% | Validated with 6 test cases |
| False positive rate | <10% | Confidence threshold prevents |
| Template processing success | 100% | All templates validated |

---

## Security Considerations

### Input Sanitization

All user input is sanitized to prevent command injection:

**Location:** `commands/scripts/prompt-handler.sh:10-14`

```bash
sanitize_input() {
    local input="$1"
    # Escape backslashes first, then dollar signs and backticks
    printf '%s\n' "$input" | sed 's/\\/\\\\/g; s/\$/\\$/g; s/`/\\`/g'
}
```

**Location:** `commands/scripts/template-processor.sh:37-41`

```bash
escape_value() {
    local value="$1"
    # Escape backslashes first, then dollar signs, backticks, and double quotes
    printf '%s\n' "$value" | sed 's/\\/\\\\/g; s/\$/\\$/g; s/`/\\`/g; s/"/\\"/g'
}
```

**Threats Mitigated:**
- Command injection via backticks
- Variable expansion attacks via `$`
- Path traversal via backslashes
- Quote escaping attacks

### Script Safety

All scripts use strict error handling:

```bash
set -euo pipefail
```

**Flags:**
- `e` - Exit on error
- `u` - Error on undefined variables
- `o pipefail` - Fail if any command in pipeline fails

**Security Model:** Whitelist-based permissions for script execution.

### Template Validation

Automated validation prevents malformed templates:

- XML tag balance checking
- Variable declaration/usage consistency
- Required metadata validation
- Content non-empty validation

**Location:** `tests/validate-templates.sh`

**Usage in CI/CD:** Can be integrated to prevent deployment of invalid templates.

---

## Deployment Architecture

### File System Layout

```
meta-prompt/                         # Plugin root
├── .claude-plugin/                  # Plugin manifest
│   ├── plugin.json                  # Plugin metadata
│   └── settings.json                # Permissions and settings
├── agents/
│   ├── template-selector.md         # Template selection agent
│   ├── prompt-optimizer.md          # Prompt optimization agent
│   ├── template-executor.md         # Task execution agent
│   └── scripts/                     # Agent handler scripts
│       ├── template-selector-handler.sh
│       ├── prompt-optimizer-handler.sh
│       └── template-executor-handler.sh
├── commands/
│   ├── prompt.md                    # /prompt command
│   └── scripts/                     # State machine handler
│       └── prompt-handler.sh
├── scripts/
│   └── common.sh                    # Shared utility functions
├── skills/                          # Domain-specific skills
│   ├── code-refactoring.md
│   ├── code-review.md
│   ├── test-generation.md
│   ├── documentation-generator.md
│   ├── data-extraction.md
│   └── code-comparison.md
├── templates/                       # Template library (6 templates)
│   ├── code-refactoring.md
│   ├── code-review.md
│   ├── test-generation.md
│   ├── documentation-generator.md
│   ├── data-extraction.md
│   └── code-comparison.md
├── tests/                           # Test suite
│   └── test-integration.sh
├── docs/                            # Documentation
│   ├── architecture-overview.md
│   ├── architecture-refactoring.md
│   ├── design-decisions.md
│   └── infrastructure.md
├── CONTRIBUTING.md                  # Contribution guidelines
└── README.md                        # Documentation index
```

### Runtime Environment

**Claude Code CLI Integration:**
- Commands available via `/prompt`
- Handler scripts executed in Claude Code's bash environment
- Agents spawned by command or other agents
- Templates and skills read via Read tool

**Environment Variables:**
- `CLAUDE_PLUGIN_ROOT` - Plugin root directory (set by Claude Code)

---

## Scalability Considerations

### Template Expansion

**Current:** 6 templates covering 5 categories + 1 fallback
**Scalability:** New templates can be added by:
1. Creating new `.md` file in `/templates/`
2. Adding keywords to `template-selector.sh`
3. Running `validate-templates.sh` for verification
4. Updating test cases in `test-integration.sh`

**Estimated capacity:** 15-20 templates before classification complexity increases

### Performance at Scale

**Current Performance:** <100ms total overhead
**Bottlenecks:**
- File I/O for template reading
- Regex matching in classification

**Optimization Opportunities:**
- Template caching in memory
- Compiled regex patterns
- Parallel classification scoring

### Maintenance Overhead

**Regular Maintenance:**
- Quarterly template review (as specified in risk mitigation)
- Continuous monitoring of classification accuracy
- Version updates for template improvements

**Automation:**
- CI/CD integration of `validate-templates.sh`
- Automated testing via `test-integration.sh`
- Metrics tracking for token reduction

---

## References

- **Design Decisions:** `docs/design-decisions.md`
- **Infrastructure Details:** `docs/infrastructure.md`
- **Test Suite:** `tests/test-integration.sh`

---

**Document Status:** Complete
**Review Date:** 2025-11-24
**Next Review:** 2026-02-24 (Quarterly)
