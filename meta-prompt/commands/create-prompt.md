---
name: create-prompt
description: Create expert-level prompt templates for Claude Code with best practices, examples, and structured output
argument-hint: <task description>
allowed-tools: [Bash, Read(${CLAUDE_PLUGIN_ROOT}/templates/**), Read(${CLAUDE_PLUGIN_ROOT}/guides/**)]
---

You will create expert-level prompt templates using an intelligent template routing system.

<task_description>
{$ARGUMENTS}
</task_description>

## Process

**Step 1: Keyword-Based Template Selection**

Execute the keyword-based template selector to determine the best template:
```bash
${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh "{$ARGUMENTS}"
```

**Error Handling**: If the script fails or is not available, fall back to Step 2 directly.

The script outputs: `<template-name> <confidence>` (e.g., `code-refactoring 75`)

Parse both the template name and confidence score from the output.

**Step 2: Evaluate Confidence and Route Accordingly**

The script in Step 1 always outputs both the template name AND confidence score.
Your job as an LLM is to interpret the confidence and route accordingly:

**If confidence >= 70% (High Confidence):**
- The keyword-based classifier is confident in its selection
- Trust the keyword-selected template and proceed to Step 3

**If confidence 60-69% (Borderline - LLM Fallback):**
- The keyword-based classifier is uncertain
- Use your own judgment as an LLM to select the best template
- The keyword suggestion is provided as a hint, but you should verify it
- Consider the task description: `{$ARGUMENTS}`
- Available templates and their use cases:
   - `code-refactoring`: For modifying, updating, refactoring, fixing, building, creating, or implementing code changes (includes TodoWrite guidance for complex tasks)
   - `function-calling`: For tasks that use provided functions, APIs, or tools to accomplish goals
   - `code-comparison`: For comparing, classifying, checking similarity, or determining equivalence
   - `test-generation`: For creating tests, test cases, test suites, or validation scenarios (includes TodoWrite for test planning)
   - `code-review`: For reviewing code quality, security, maintainability, providing feedback or critique
   - `documentation-generator`: For creating documentation, README files, docstrings, guides, or technical writing
   - `data-extraction`: For extracting, parsing, retrieving, or mining data from text, logs, files, or structured formats
   - `custom`: For novel tasks that don't fit existing templates or require custom prompt engineering

   Note: Complex templates (code-refactoring, test-generation, code-review) include TodoWrite instructions to help sub-agents track progress through multi-step tasks.
- Select the BEST template based on your understanding of the task. If truly novel and doesn't fit any template well, select `custom`.
- Use this LLM-selected template instead of the keyword-based selection
- Continue to Step 3 with your selected template

**If confidence < 60% (Low Confidence):**
- The task likely doesn't fit standard templates
- Proceed to Step 3 with `custom` template

**Step 3: Route Based on Selection**

If the previous step returns anything OTHER than `custom`:
1. Read the selected template using the Read tool:
   - Use: Read tool with path `${CLAUDE_PLUGIN_ROOT}/templates/<template-name>.md`
2. Examine the template's required variables (in the YAML frontmatter)
   - Distinguish between `variables` (required) and `optional_variables` (optional with defaults)
   - Only required variables MUST be extracted from the task description
3. Extract appropriate values from the task description using these heuristics:
   - **ITEM1, ITEM2**: Look for nouns, quoted strings, or entities to compare
   - **CLASSIFICATION_CRITERIA**: Extract the comparison criteria or question
   - **DOCUMENT**: Identify document content, path, or reference
   - **QUESTION**: Extract the interrogative statement or information request
   - **CODE_LOCATION**: Identify file paths, class names, or function names
   - **TASK_REQUIREMENTS**: Extract what needs to be done (action verbs and objectives)
   - **TARGET_PATTERNS**: Identify patterns to find (functions, classes, regex, file types)
   - **CODE_TO_REVIEW, CODE_TO_TEST, CODE_OR_CONTENT**: Identify code, files, or content to process
   - For optional variables: only extract if clearly specified; omit otherwise to use defaults
4. Use the template processor to substitute variables:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh <template-name> VAR1='value1' VAR2='value2' ...
   ```

   **Error Handling**: If template-processor.sh fails:
   - Check the error message to understand why (missing required variables, template not found, etc.)
   - If required variables couldn't be extracted, fall back to the `custom` template path (go to Step 3 "If script returns custom")
   - If it's a different error, report it and fall back to `custom` template

5. If template processing succeeds, return the processed template as the final prompt
6. DO NOT invoke any LLM processing - just return the template

If the script returns `custom`:
1. Load the comprehensive prompt engineering guide:
   - Use: Read tool with path `${CLAUDE_PLUGIN_ROOT}/guides/engineering-guide.md`

   **Error Handling**: If the guide file is not available, fall back to using general prompt engineering best practices (clear instructions, specific examples, structured output format, error handling, and deterministic criteria).

2. Follow the engineering guide to craft a custom prompt
3. Return the crafted prompt
