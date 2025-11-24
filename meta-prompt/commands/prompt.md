---
name: prompt
description: Optimize a prompt using templates and execute with specialized skills
argument-hint: [--template=<name>] [--code|--refactor|--review|--test|--docs|--extract|--compare|--custom] [--plan] [--return-only] <task description>
allowed-tools: [Task, Bash(~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh:*)]
---

Optimize and execute tasks using template-based prompts with domain-specific skills.

<task_description>
{$TASK_DESCRIPTION}
</task_description>

## Architecture

This command uses a **state machine** approach where the handler script guides you through each step:

1. **Call handler** with user task → Get instruction to spawn prompt-optimizer
2. **Spawn prompt-optimizer** → Get optimized prompt
3. **Call handler** with optimizer result → Get instruction to spawn Plan (if --plan flag) or template-executor
4. **Spawn Plan agent** (if --plan) → Create plan and get user approval
5. **Spawn template-executor** → Execute the task
6. **Present results** to user

The handler script (`prompt-handler.sh`) is a state machine that determines the next action based on the current state.

## Process

### Step 1: Initial Call to Handler

Execute the handler script with the user's task:

```bash
~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh "{$TASK_DESCRIPTION}"
```

The handler will parse flags and return instructions for spawning the appropriate subagent.

**Supported Flags:**
- `--template=<name>` - Explicit template selection
- `--code`, `--refactor`, `--review`, `--test`, `--docs`, `--extract`, `--compare`, `--custom` - Template shortcuts
- `--plan` - Create plan before executing (uses Plan subagent)
- `--return-only` - Return optimized prompt without executing

### Step 2: Track Progress with TodoWrite

The handler output will include a `TODO_LIST:` section with the complete workflow steps. Use TodoWrite to create this list and track progress through the state machine.

**The handler provides deterministic logic - you translate it to todos.**

The TODO_LIST format from handler:
```
TODO_LIST:
1. [completed] Determine template
2. [in_progress] Optimize prompt
3. [pending] Execute task
4. [pending] Present results
```

Convert this to TodoWrite format by extracting:
- **content**: The task description (e.g., "Determine template")
- **status**: The status (completed/in_progress/pending)
- **activeForm**: Present continuous form (e.g., "Determining template")

**IMPORTANT**: Always use TodoWrite:
1. **After receiving handler output** - Parse TODO_LIST and call TodoWrite with the current state
2. **Before performing each action** - The handler already marks the right item as in_progress
3. **After completing each action** - Update only if the handler's next output changes the list

The handler manages state - you just reflect it with TodoWrite.

### Step 3: Follow Handler Instructions

The handler output will contain:
- `STATE:` Current state in the workflow
- `NEXT_ACTION:` What to do next
- `TODO_LIST:` Complete list of workflow steps (with status)
- Detailed instructions for spawning the appropriate subagent

Follow the instructions exactly as provided.

### Step 4: Loop Back to Handler (if needed)

After spawning a subagent and receiving its result:

1. If the result is XML (e.g., `<prompt_optimizer_result>`), pass it to the handler:
   ```bash
   ~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh '<xml-result>...</xml-result>'
   ```

2. Parse the TODO_LIST from the new handler output

3. Use TodoWrite to update the todo list with the new state

4. Follow the new instructions from the handler

5. Repeat until handler returns `NEXT_ACTION: done`

### Step 5: Present Final Results

When the workflow is complete (NEXT_ACTION: done):

1. Parse the TODO_LIST from handler output

2. Use TodoWrite to reflect the final state

3. Present the execution results to the user

## State Machine Flow

```
Initial State (user task + flags)
    ↓
[Handler: spawn prompt-optimizer]
    ↓
Prompt-Optimizer Agent
    ↓
Post-Optimizer State (optimizer XML result)
    ↓
[Handler: Check for --plan flag]
    ↓
    ├─ With --plan ──→ Plan Agent ──→ Template-Executor Agent
    │
    └─ Without --plan ──→ Template-Executor Agent
    ↓
Final State
    ↓
Present Results to User
```

## Template & Skill Mapping

| Template | Skill | Domain Expertise |
|----------|-------|------------------|
| code-refactoring | meta-prompt:code-refactoring | Code modifications, bug fixes, refactoring |
| code-review | meta-prompt:code-review | Security audits, quality analysis |
| test-generation | meta-prompt:test-generation | Test creation, coverage |
| documentation-generator | meta-prompt:documentation-generator | API docs, READMEs, docstrings |
| data-extraction | meta-prompt:data-extraction | Data parsing, extraction |
| code-comparison | meta-prompt:code-comparison | Code equivalence, comparison |
| custom | (none) | Novel tasks not matching templates |

## Benefits

- **State machine architecture** - Handler script orchestrates the entire flow
- **Simple agent logic** - /prompt just follows handler instructions
- **Zero-token routing** - All deterministic logic in bash
- **Template-based optimization** - Pre-built prompts for common tasks
- **Domain expertise** - Skills provide specialized knowledge
- **Direct execution by default** - Fast execution, optional planning with --plan flag
- **Flexible workflow** - Easy to extend with new states/agents

## Examples

**Simple refactoring with auto-detection:**
```
/prompt Fix the authentication bug in login.ts
```
→ Handler guides through: optimizer → template-executor → done

**Explicit code review with planning:**
```
/prompt --review --plan Check the security of auth module
```
→ Handler guides through: optimizer → Plan agent → template-executor → done

**Get optimized prompt without executing:**
```
/prompt --test --return-only Generate tests for the user service
```
→ Handler returns optimizer result, stops (no execution)

**Custom task for novel requirements:**
```
/prompt --custom Write a bash script that monitors system resources
```
→ Uses custom template, executes directly
