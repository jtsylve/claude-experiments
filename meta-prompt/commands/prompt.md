---
name: prompt
description: Optimize a prompt and optionally execute it in a fresh context
argument-hint: [--code|--refactor|--review|--test|--docs|--documentation|--extract|--compare|--comparison|--custom] [--return-only] <task or prompt to optimize>
allowed-tools: [Task, Bash(~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh:*)]
---

You will use deterministic bash orchestration to handle this request efficiently.

<task_description>
{$TASK_DESCRIPTION}
</task_description>

## Purpose

This command has been optimized to eliminate LLM orchestration overhead through deterministic bash preprocessing. The orchestration script handles all decision logic, reducing token consumption to near-zero for this routing layer.

## Process

1. Execute the orchestration script to invoke the agent:
   - Run: `~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh "{$TASK_DESCRIPTION}"`
   - The script will parse arguments and determine execution mode
   - It will output an agent invocation using `@agent-meta-prompt:prompt-optimizer` followed by the task context
   - **Error Handling**: If the script fails or doesn't exist:
     1. Notify the user: "The prompt-handler script failed. I can fall back to using the prompt-optimizer agent directly."
     2. Ask the user: "Would you like me to proceed with the fallback approach?"
     3. Only if approved, invoke `@agent-meta-prompt:prompt-optimizer` directly with the task description

2. The output from the script will invoke the prompt-optimizer agent directly (not as a subagent)

3. Present results to the user as directed by the agent

## Template Flags

The user can explicitly select a template by using one of these flags at the beginning of the command:

- `--code` or `--refactor` → code-refactoring template
- `--review` → code-review template
- `--test` → test-generation template
- `--docs` or `--documentation` → documentation-generator template
- `--extract` → data-extraction template
- `--compare` or `--comparison` → code-comparison template
- `--custom` → custom template (LLM-based prompt generation)

When a template flag is provided:
- The auto-detection logic is completely bypassed
- The specified template is used directly
- Flags must come before the task description
- Can be combined with `--return-only`

Example: `/prompt --code --return-only Fix the authentication bug`

## Fallback Strategy

If the bash orchestration script fails for any reason:
1. Notify the user of the error: "The orchestration script encountered an error: [error details]"
2. Explain the fallback option: "I can use the prompt-optimizer agent directly to handle your request using the full LLM-based approach."
3. Ask for confirmation: "Would you like me to proceed with this fallback?"
4. Only if approved:
   - Invoke the prompt-optimizer agent directly using `@agent-meta-prompt:prompt-optimizer`
   - Pass the task description and any flags (--return-only, template flags) in the prompt
   - The prompt-optimizer agent will handle the request

This deterministic approach eliminates orchestration overhead while maintaining all functionality.
