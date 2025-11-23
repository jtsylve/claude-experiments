#!/usr/bin/env bash
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
TEMPLATE=""

# Parse all flags from the beginning of the input
# Continue parsing until we hit a non-flag argument
while true; do
    case "$RAW_TASK_DESCRIPTION" in
        --code\ *|--code)
            TEMPLATE="code-refactoring"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION#--code}"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION# }"
            ;;
        --refactor\ *|--refactor)
            TEMPLATE="code-refactoring"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION#--refactor}"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION# }"
            ;;
        --review\ *|--review)
            TEMPLATE="code-review"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION#--review}"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION# }"
            ;;
        --test\ *|--test)
            TEMPLATE="test-generation"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION#--test}"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION# }"
            ;;
        --docs\ *|--docs)
            TEMPLATE="documentation-generator"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION#--docs}"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION# }"
            ;;
        --documentation\ *|--documentation)
            TEMPLATE="documentation-generator"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION#--documentation}"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION# }"
            ;;
        --extract\ *|--extract)
            TEMPLATE="data-extraction"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION#--extract}"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION# }"
            ;;
        --compare\ *|--compare)
            TEMPLATE="code-comparison"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION#--compare}"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION# }"
            ;;
        --comparison\ *|--comparison)
            TEMPLATE="code-comparison"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION#--comparison}"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION# }"
            ;;
        --function\ *|--function)
            TEMPLATE="function-calling"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION#--function}"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION# }"
            ;;
        --custom\ *|--custom)
            TEMPLATE="custom"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION#--custom}"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION# }"
            ;;
        --return-only\ *|--return-only)
            RETURN_ONLY=true
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION#--return-only}"
            RAW_TASK_DESCRIPTION="${RAW_TASK_DESCRIPTION# }"
            ;;
        *)
            # No more flags, break out of loop
            break
            ;;
    esac
done

# Normalize whitespace
RAW_TASK_DESCRIPTION=$(echo "$RAW_TASK_DESCRIPTION" | xargs)

# Sanitize the task description after flag processing
TASK_DESCRIPTION=$(sanitize_input "$RAW_TASK_DESCRIPTION")

# Build template instruction based on whether a template flag was provided
TEMPLATE_INSTRUCTION=""
if [ -n "$TEMPLATE" ]; then
    TEMPLATE_INSTRUCTION="

IMPORTANT: The user has explicitly selected the '$TEMPLATE' template. Use this template directly - do NOT run template selection logic."
fi

# Generate instructions based on execution mode
if [ "$RETURN_ONLY" = true ]; then
    # Return-only mode: just create and return the optimized prompt
    cat <<EOF
Use the Task tool with the following parameters:

- subagent_type: "meta-prompt:prompt-optimizer"
- description: "Create optimized prompt"
- prompt: "The user needs an optimized prompt for this task:

<user_task>
$TASK_DESCRIPTION
</user_task>$TEMPLATE_INSTRUCTION

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

- subagent_type: "meta-prompt:prompt-optimizer"
- description: "Optimize and execute task"
- prompt: "The user needs help with this task:

<user_task>
$TASK_DESCRIPTION
</user_task>$TEMPLATE_INSTRUCTION

Your mission:
1. Use /create-prompt to craft an optimized prompt for this task
2. Review the prompt with me before execution
3. Once approved, execute the prompt in a NEW agent context (use Task tool with subagent_type=\"general-purpose\")
4. Return the execution results

Execute the task unless the user explicitly asks to review first."

After the agent completes, present the task results to the user.
EOF
fi
