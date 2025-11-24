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
   Parse each `<todo status="..." content="..." activeForm="..."/>` and call TodoWrite with the array.

   **Example transformation:**
   ```xml
   <todos>
   <todo status="in_progress" content="Optimize prompt" activeForm="Optimizing prompt"/>
   <todo status="pending" content="Execute task" activeForm="Executing task"/>
   </todos>
   ```
   Becomes TodoWrite input:
   ```json
   [
     {"status": "in_progress", "content": "Optimize prompt", "activeForm": "Optimizing prompt"},
     {"status": "pending", "content": "Execute task", "activeForm": "Executing task"}
   ]
   ```

4. **Execute based on `<next_action>`:**
   - If spawning subagent: Use Task tool with `<subagent_type>`, `<description>`, `<prompt>`
   - Pass subagent XML results back to handler via `<next_handler_call>`
   - If `<final_action>` present: execute that action instead of looping

5. **Handle `<final_action>` values:**
   - `present_results`: Display the task execution results to the user
   - `present_optimized_prompt`: Display the optimized prompt to the user (for --return-only mode)

6. **Loop until `<next_action>done</next_action>`**

7. **Present results** to user when complete.
