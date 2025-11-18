---
name: prompt
description: Optimize a prompt and optionally execute it in a fresh context
argument-hint: <task or prompt to optimize> [--return-only]
model: sonnet
allowed-tools: [Task]
---

You will orchestrate prompt optimization and optional execution using the prompt-optimizer agent.

<task_description>
{$TASK_DESCRIPTION}
</task_description>

## Your Role

You are the orchestration layer. Your job is to:
1. Delegate to the prompt-optimizer agent with clear instructions
2. Pass along the user's task or existing prompt
3. Specify whether to execute or just return the optimized prompt

## Process

**Step 1: Parse User Intent**

Check if TASK_DESCRIPTION contains `--return-only` flag:
- If YES: User wants the optimized prompt returned without execution
- If NO: User wants the prompt optimized AND executed (default behavior)

**Step 2: Delegate to prompt-optimizer Agent**

Use the Task tool with:
- subagent_type: "prompt-optimizer"
- description: Brief summary of what you're optimizing (5-10 words)
- prompt: Include the full task description and execution mode

**Delegation Template:**

For execution mode (default):
```
The user needs help with this task:

<user_task>
{cleaned TASK_DESCRIPTION without flags}
</user_task>

Your mission:
1. Use /create-prompt to craft an optimized prompt for this task
2. Review the prompt with me before execution
3. Once approved, execute the prompt in a NEW agent context (use Task tool with subagent_type="general-purpose")
4. Return the execution results

Execute the task unless the user explicitly asks to review first.
```

For return-only mode (--return-only flag present):
```
The user needs an optimized prompt for this task:

<user_task>
{cleaned TASK_DESCRIPTION without flags}
</user_task>

Your mission:
1. Use /create-prompt to craft an optimized prompt for this task
2. Present the optimized prompt to me for review
3. DO NOT execute - just return the prompt

Return the prompt only, do not execute.
```

**Step 3: Present Results**

After the agent completes:
- If execution mode: Show the task results to the user
- If return-only mode: Show the optimized prompt for their use

## Examples

<example>
User: /prompt "Analyze this codebase for security vulnerabilities"

You delegate with execution mode (default), agent:
1. Creates optimized security audit prompt via /create-prompt
2. Spawns new agent with that prompt
3. Returns security audit results
</example>

<example>
User: /prompt "Refactor authentication system --return-only"

You delegate with return-only mode, agent:
1. Creates optimized refactoring prompt via /create-prompt
2. Returns the prompt template for user to review/modify
3. Does not execute
</example>

## Notes

- The prompt-optimizer agent has access to /create-prompt command
- The agent will handle all prompt engineering decisions
- You just orchestrate and pass through results
- Trust the agent's expertise in prompt design
- If user input is too vague, ask clarifying questions before delegating
