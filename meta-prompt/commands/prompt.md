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

1. Execute the orchestration script to generate instructions:
   - Run: `~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh "{$TASK_DESCRIPTION}"`
   - The script will parse arguments and determine execution mode
   - It will output precise instructions for you to follow
   - **Error Handling**: If the script fails or doesn't exist, fall back to using the Task tool with `subagent_type="meta-prompt:prompt-optimizer"` directly

2. Follow the instructions from the script output exactly

3. Present results to the user as directed by the script

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
- Use the Task tool with `subagent_type="meta-prompt:prompt-optimizer"`
- Pass the task description and any flags (--return-only, template flags) in the prompt
- The meta-prompt:prompt-optimizer agent will handle the request using the full LLM-based approach

This deterministic approach eliminates orchestration overhead while maintaining all functionality.
