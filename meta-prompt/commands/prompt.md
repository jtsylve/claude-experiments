---
name: prompt
description: Optimize a prompt using templates and execute with specialized skills
argument-hint: [--template=<name>] [--code|--refactor|--review|--test|--docs|--documentation|--extract|--compare|--comparison|--custom] [--plan] [--return-only] <task description>
allowed-tools: [Task, TodoWrite, Bash(~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh:*)]
---

Execute tasks using optimized prompts with domain-specific skills.

<task>{$TASK_DESCRIPTION}</task>

## Process

1. **Call handler** with the task:
   ```bash
   ~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh "{$TASK_DESCRIPTION}"
   ```

2. **Parse XML response** from handler:
   - Extract `<todos>` and call TodoWrite with the todo items
   - Extract `<task_tool>` for subagent parameters
   - Check `<next_action>` and `<final_action>` for flow control

3. **Update TodoWrite** from `<todos>`:
   Parse each `<todo status="..." content="..." activeForm="..."/>` and call TodoWrite with the array

4. **Execute based on `<next_action>`:**
   - If spawning subagent: Use Task tool with `<subagent_type>`, `<description>`, `<prompt>`
   - Pass subagent XML results back to handler via `<next_handler_call>`
   - If `<final_action>` present: execute that action (present_results, present_optimized_prompt)

5. **Loop until `<next_action>done</next_action>`**

6. **Present results** to user when complete.
