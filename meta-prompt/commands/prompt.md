---
name: prompt
description: Optimize a prompt using templates and execute with specialized skills
argument-hint: [--template=<name>] [--code|--refactor|--review|--test|--docs|--documentation|--extract|--compare|--comparison|--custom] [--plan] [--return-only] <task description>
allowed-tools: [Task, Bash(~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh:*)]
---

Execute tasks using optimized prompts with domain-specific skills.

<task>{$TASK_DESCRIPTION}</task>

## Process

1. **Call handler** with the task:
   ```bash
   ~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh "{$TASK_DESCRIPTION}"
   ```

2. **Parse handler output:**
   - Extract `TODO_LIST:` and use TodoWrite to track progress
   - Follow `NEXT_ACTION:` instructions exactly

3. **Loop until done:**
   - Spawn subagents as instructed by handler
   - Pass XML results back to handler
   - Update TodoWrite from new TODO_LIST
   - Continue until `NEXT_ACTION: done`

4. **Present results** to user when complete.
