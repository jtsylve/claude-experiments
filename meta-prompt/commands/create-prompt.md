---
name: create-prompt
description: Create expert-level prompt templates for Claude Code with best practices, examples, and structured output
argument-hint: <task description>
allowed-tools: [Bash(${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh:*), Bash(${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh:*), Read(${CLAUDE_PLUGIN_ROOT}/templates/**), Read(${CLAUDE_PLUGIN_ROOT}/guides/**)]
---

You will create expert-level prompt templates using an intelligent template routing system.

<task_description>
{$ARGUMENTS}
</task_description>

## Process

**Step 1: Template Selection**

Execute the template selector to determine the best template:
```bash
${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh "{$ARGUMENTS}"
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
   - Use: Read tool with path `${CLAUDE_PLUGIN_ROOT}/templates/<template-name>.md`
   - Or bash: `cat ${CLAUDE_PLUGIN_ROOT}/templates/<template-name>.md`
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
   ${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-processor.sh <template-name> VAR1='value1' VAR2='value2' ...
   ```
5. Return the processed template as the final prompt
6. DO NOT invoke any LLM processing - just return the template

If the script returns `custom`:
1. Load the comprehensive prompt engineering guide:
   ```bash
   cat ${CLAUDE_PLUGIN_ROOT}/guides/engineering-guide.md
   ```

   **Error Handling**: If the guide file is not available, fall back to using general prompt engineering best practices (clear instructions, specific examples, structured output format, error handling, and deterministic criteria).

2. Follow the engineering guide to craft a custom prompt
3. Return the crafted prompt
