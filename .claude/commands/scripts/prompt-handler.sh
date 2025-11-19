#!/bin/bash
# Purpose: Deterministic orchestration for /prompt command
# Inputs: $1=task_description, $2=flags (optional)
# Outputs: Instructions for Claude Code to execute
# Token reduction: 100% (replaces 105-line LLM orchestration)

set -euo pipefail

# Sanitize input to prevent command injection
sanitize_input() {
    local input="$1"
    # Escape backslashes first, then dollar signs and backticks
    printf '%s\n' "$input" | sed 's/\\/\\\\/g; s/\$/\\$/g; s/`/\\`/g'
}

# Parse arguments
RAW_TASK_DESCRIPTION="$1"
RETURN_ONLY=false

# Check for --return-only flag and remove it
if [[ "$RAW_TASK_DESCRIPTION" =~ --return-only([[:space:]]|$) ]]; then
    RETURN_ONLY=true
    # Remove the flag from task description and normalize whitespace
    RAW_TASK_DESCRIPTION=$(echo "$RAW_TASK_DESCRIPTION" | sed 's/--return-only[[:space:]]*//g' | xargs)
fi

# Sanitize the task description after flag processing
TASK_DESCRIPTION=$(sanitize_input "$RAW_TASK_DESCRIPTION")

# Generate instructions based on execution mode
if [ "$RETURN_ONLY" = true ]; then
    # Return-only mode: just create and return the optimized prompt
    cat <<EOF
Use the Task tool with the following parameters:

- subagent_type: "prompt-optimizer"
- description: "Create optimized prompt"
- prompt: "The user needs an optimized prompt for this task:

<user_task>
$TASK_DESCRIPTION
</user_task>

Your mission:
1. Use /create-prompt to craft an optimized prompt for this task
2. Present the optimized prompt to me for review
3. DO NOT execute - just return the prompt

Return the prompt only, do not execute."

After the agent completes, present the optimized prompt to the user.
EOF
else
    # Execution mode: create prompt and execute it
    cat <<EOF
Use the Task tool with the following parameters:

- subagent_type: "prompt-optimizer"
- description: "Optimize and execute task"
- prompt: "The user needs help with this task:

<user_task>
$TASK_DESCRIPTION
</user_task>

Your mission:
1. Use /create-prompt to craft an optimized prompt for this task
2. Review the prompt with me before execution
3. Once approved, execute the prompt in a NEW agent context (use Task tool with subagent_type=\"general-purpose\")
4. Return the execution results

Execute the task unless the user explicitly asks to review first."

After the agent completes, present the task results to the user.
EOF
fi
