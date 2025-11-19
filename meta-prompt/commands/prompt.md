---
name: prompt
description: Optimize a prompt and optionally execute it in a fresh context
argument-hint: <task or prompt to optimize> [--return-only]
model: claude-sonnet-4-5-20250929
allowed-tools: [Task, Bash]
---

You will use deterministic bash orchestration to handle this request efficiently.

<task_description>
{$TASK_DESCRIPTION}
</task_description>

## Purpose

This command has been optimized to eliminate LLM orchestration overhead through deterministic bash preprocessing. The orchestration script handles all decision logic, reducing token consumption to near-zero for this routing layer.

## Process

1. Execute the orchestration script to generate instructions:
   - Run: `${CLAUDE_PLUGIN_ROOT}/commands/scripts/prompt-handler.sh "{$TASK_DESCRIPTION}"`
   - The script will parse arguments and determine execution mode
   - It will output precise instructions for you to follow
   - **Error Handling**: If the script fails or doesn't exist, fall back to using the Task tool with `subagent_type="meta-prompt:prompt-optimizer"` directly

2. Follow the instructions from the script output exactly

3. Present results to the user as directed by the script

## Fallback Strategy

If the bash orchestration script fails for any reason:
- Use the Task tool with `subagent_type="meta-prompt:prompt-optimizer"`
- Pass the task description and any flags (--return-only) in the prompt
- The meta-prompt:prompt-optimizer agent will handle the request using the full LLM-based approach

This deterministic approach eliminates orchestration overhead while maintaining all functionality.
