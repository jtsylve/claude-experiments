---
name: create-prompt
description: Create expert-level prompt templates for Claude Code with best practices, examples, and structured output
argument-hint: <task description>
model: sonnet
allowed-tools: [Bash, Read]
---

You will create expert-level prompt templates using an intelligent template routing system.

<task_description>
{$ARGUMENTS}
</task_description>

## Process

**Step 1: Template Selection**

Execute the template selector to determine the best template:
```bash
commands/scripts/template-selector.sh "{$ARGUMENTS}"
```

**Error Handling**: If the script fails or is not available, fall back to `custom` template and use the full LLM-based prompt engineering process below.

This will return one of:
- `code-refactoring` - For code modification tasks
- `document-qa` - For document analysis with citations
- `function-calling` - For tasks using provided functions/tools
- `interactive-dialogue` - For conversational agents, tutors, support
- `simple-classification` - For comparison or classification tasks
- `custom` - For novel tasks requiring LLM-based prompt engineering

**Step 2: Route Based on Selection**

If the script returns anything OTHER than `custom`:
1. Read the selected template using the Read tool:
   - Use: Read tool with path `templates/<template-name>.md` (relative to plugin root)
   - Or bash: `cat templates/<template-name>.md`
2. Examine the template's required variables (in the YAML frontmatter)
3. Extract appropriate values from the task description using these heuristics:
   - **ITEM1, ITEM2**: Look for nouns, quoted strings, or entities to compare
   - **CLASSIFICATION_CRITERIA**: Extract the comparison criteria or question
   - **DOCUMENT**: Identify document content, path, or reference
   - **QUESTION**: Extract the interrogative statement or information request
   - **CODE_LOCATION**: Identify file paths, class names, or function names
   - **TASK_REQUIREMENTS**: Extract what needs to be done (action verbs and objectives)
   - **TARGET_PATTERNS**: Identify patterns to find (functions, classes, regex, file types)
4. Use the template processor to substitute variables:
   ```bash
   commands/scripts/template-processor.sh <template-name> VAR1='value1' VAR2='value2' ...
   ```
5. Return the processed template as the final prompt
6. DO NOT invoke any LLM processing - just return the template

If the script returns `custom`:
1. Use the comprehensive prompt engineering instructions below
2. Follow all best practices to craft a custom prompt
3. Return the crafted prompt

## Comprehensive Prompt Engineering Guide (for custom templates only)

You are an expert in writing prompt templates for Claude Code, Anthropic's official CLI tool. Today you will be writing instructions for an AI assistant working in the Claude Code environment. The assistant has access to specialized tools for file operations, code search, task management, and more.

I will explain a task to you. You will write instructions that direct the assistant on how to accomplish the task consistently, accurately, and correctly, following modern Claude Code best practices.

### Output Format Overview

Your response should contain three sections:
1. **<Inputs>**: 1-3 variables in UPPER_SNAKE_CASE wrapped in {$VARIABLE_NAME} syntax
2. **<Instructions Structure>**: Brief plan of instruction organization (optional for simple tasks)
3. **<Instructions>**: The complete prompt template following best practices

### Core Principles & Best Practices

#### Variable Declaration
- **Quantity**: Use 1-3 variables (prefer 1-2)
- **Naming**: UPPER_SNAKE_CASE format, 3-20 characters
- **Syntax**: First use: `{$VARIABLE_NAME}`, later references: without braces
- **Demarcation**: Wrap in XML tags: `<tag>{$VARIABLE_NAME}</tag>`
- **Placement**: Variables with lengthy values come BEFORE instructions that use them

#### Task Complexity Classification
```
Simple (≤3 steps, 1 input, linear logic):
  - No scratchpad/thinking tags needed
  - Minimal structure

Intermediate (4-7 steps, 2-3 inputs, some conditionals):
  - Consider <scratchpad> for planning
  - Clear step-by-step structure

Complex (>7 steps, multiple inputs, complex reasoning):
  - Use <inner_monologue> or <thinking> tags
  - Consider TodoWrite for tracking
  - Include error handling
```

#### Output Structure Rules
- Justification ALWAYS comes BEFORE final answer/score
- Specify output tag names explicitly (e.g., "write answer in <answer> tags")
- For structured output, define the XML schema clearly

#### Claude Code Tool Usage

**When task involves file operations:**
- Read before Edit/Write (ALWAYS)
- Use specialized tools: Read (not cat), Edit (not sed), Glob (not find), Grep (not grep command)
- Never create unnecessary files (especially .md, README)
- Prefer editing existing files over creating new ones

**When task involves codebase exploration:**
- Use Task tool with subagent_type="Explore"
- Specify thoroughness: "quick", "medium", or "very thorough"

**When task has multiple independent steps:**
- Instruct: "make multiple tool calls in parallel in a single response"

**When task is complex (3+ steps):**
- Instruct: "use TodoWrite to track progress"
- One task in_progress at a time
- Mark completed only when fully done

#### Communication Guidelines
- Concise, CLI-appropriate tone
- Direct text output (never bash echo or code comments)
- No emojis unless task requires them
- Use `file_path:line_number` for code references
- GitHub-flavored markdown supported

#### Security & Quality
- Prevent: command injection, XSS, SQL injection, OWASP top 10
- Delete unused code completely (no comments/underscores)
- Fix insecure code immediately

### Quality Validation Checklist

Before finalizing your prompt, verify:

#### Structure
□ All variables declared in <Inputs> are used in <Instructions>
□ Variables with lengthy values placed BEFORE instructions using them
□ Output format specified with explicit XML tags
□ Instructions follow logical progression

#### Completeness
□ Error handling included for failure scenarios
□ Edge cases addressed (empty input, invalid data)
□ Success criteria clearly defined

#### Determinism
□ No subjective terms ("minimal", "appropriate", "simple", "complex" without definition)
□ Explicit conditions for optional elements
□ Clear decision criteria provided
□ Numeric thresholds specified where applicable

#### Claude Code Specific (if applicable)
□ Tool usage patterns demonstrated
□ File operation best practices included (Read before Edit)
□ TodoWrite integrated for complex tasks (3+ steps)
□ Parallel tool usage mentioned for independent operations
□ Specialized tools specified (not bash alternatives)

#### Efficiency
□ No redundant instructions
□ Variables used efficiently (no unnecessary duplicates)
□ Examples condensed to essential patterns only
□ Token usage optimized (concise but clear)

### Meta-Instructions

**Understanding Your Role:**
You are writing a prompt template, not completing the task. When you use {$VARIABLE_NAME} syntax, it will be substituted with actual values provided by users.

**Variable Handling:**
- Declare once with {$VARIABLE_NAME}, reference later without braces/dollar sign
- Wrap in XML tags for clear boundaries
- Example: `<document>{$DOCUMENT}</document>` then "analyze the document..."

**When to Include Planning Tags:**
- Simple tasks (≤3 steps): omit scratchpad/thinking tags
- Complex tasks (>7 steps): use <scratchpad>, <thinking>, or <inner_monologue>
- File operations: consider TodoWrite for tracking

**Tool Usage Reminders:**
- File operations: mention Read before Edit, specialized tools over bash
- Codebase exploration: mention Task tool with Explore subagent
- Multiple independent steps: mention parallel tool calls
- Keep tone concise and CLI-appropriate

Now, write the prompt template for this task:

<Task>
{$ARGUMENTS}
</Task>
