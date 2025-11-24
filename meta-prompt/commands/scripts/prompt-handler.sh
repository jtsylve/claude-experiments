#!/usr/bin/env bash
# Purpose: State machine for /prompt command orchestration
# Inputs: Structured XML via stdin OR command-line args for initial state
# Outputs: Next instruction for /prompt command
# Architecture: State machine that guides /prompt through:
#   - Without --plan: optimizer → executor → done
#   - With --plan: optimizer → Plan agent → executor → done

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../scripts/common.sh"

# Detect current state from input
detect_state() {
    local input="$1"

    if echo "$input" | grep -q "<template_selector_result>"; then
        echo "post_template_selector"
    elif echo "$input" | grep -q "<prompt_optimizer_result>"; then
        echo "post_optimizer"
    elif echo "$input" | grep -q "<plan_result>"; then
        echo "post_plan"
    elif echo "$input" | grep -q "<template_executor_result>"; then
        echo "final"
    else
        # Initial state (command-line args or initial XML)
        echo "initial"
    fi
}

# Parse flags from initial task description
# Sets global variables: RETURN_ONLY, PLAN, TEMPLATE, TEMPLATE_FLAG_SEEN, TASK_DESCRIPTION
parse_initial_flags() {
    local raw_input="$1"

    # Set global variables for use by handler functions
    RETURN_ONLY=false
    PLAN=false
    TEMPLATE=""
    TEMPLATE_FLAG_SEEN=false

    # Parse all flags from the beginning of the input
    while true; do
        case "$raw_input" in
            --template=*)
                if [ "$TEMPLATE_FLAG_SEEN" = true ]; then
                    echo "Error: Multiple template flags specified." >&2
                    exit 1
                fi
                TEMPLATE="${raw_input#--template=}"
                TEMPLATE="${TEMPLATE%% *}"
                raw_input="${raw_input#--template=$TEMPLATE}"
                raw_input="${raw_input# }"
                TEMPLATE_FLAG_SEEN=true
                ;;
            --code\ *|--code)
                if [ "$TEMPLATE_FLAG_SEEN" = true ]; then
                    echo "Error: Multiple template flags specified." >&2
                    exit 1
                fi
                TEMPLATE="code-refactoring"
                TEMPLATE_FLAG_SEEN=true
                raw_input="${raw_input#--code}"
                raw_input="${raw_input# }"
                ;;
            --refactor\ *|--refactor)
                if [ "$TEMPLATE_FLAG_SEEN" = true ]; then
                    echo "Error: Multiple template flags specified." >&2
                    exit 1
                fi
                TEMPLATE="code-refactoring"
                TEMPLATE_FLAG_SEEN=true
                raw_input="${raw_input#--refactor}"
                raw_input="${raw_input# }"
                ;;
            --review\ *|--review)
                if [ "$TEMPLATE_FLAG_SEEN" = true ]; then
                    echo "Error: Multiple template flags specified." >&2
                    exit 1
                fi
                TEMPLATE="code-review"
                TEMPLATE_FLAG_SEEN=true
                raw_input="${raw_input#--review}"
                raw_input="${raw_input# }"
                ;;
            --test\ *|--test)
                if [ "$TEMPLATE_FLAG_SEEN" = true ]; then
                    echo "Error: Multiple template flags specified." >&2
                    exit 1
                fi
                TEMPLATE="test-generation"
                TEMPLATE_FLAG_SEEN=true
                raw_input="${raw_input#--test}"
                raw_input="${raw_input# }"
                ;;
            --docs\ *|--docs)
                if [ "$TEMPLATE_FLAG_SEEN" = true ]; then
                    echo "Error: Multiple template flags specified." >&2
                    exit 1
                fi
                TEMPLATE="documentation-generator"
                TEMPLATE_FLAG_SEEN=true
                raw_input="${raw_input#--docs}"
                raw_input="${raw_input# }"
                ;;
            --documentation\ *|--documentation)
                if [ "$TEMPLATE_FLAG_SEEN" = true ]; then
                    echo "Error: Multiple template flags specified." >&2
                    exit 1
                fi
                TEMPLATE="documentation-generator"
                TEMPLATE_FLAG_SEEN=true
                raw_input="${raw_input#--documentation}"
                raw_input="${raw_input# }"
                ;;
            --extract\ *|--extract)
                if [ "$TEMPLATE_FLAG_SEEN" = true ]; then
                    echo "Error: Multiple template flags specified." >&2
                    exit 1
                fi
                TEMPLATE="data-extraction"
                TEMPLATE_FLAG_SEEN=true
                raw_input="${raw_input#--extract}"
                raw_input="${raw_input# }"
                ;;
            --compare\ *|--compare)
                if [ "$TEMPLATE_FLAG_SEEN" = true ]; then
                    echo "Error: Multiple template flags specified." >&2
                    exit 1
                fi
                TEMPLATE="code-comparison"
                TEMPLATE_FLAG_SEEN=true
                raw_input="${raw_input#--compare}"
                raw_input="${raw_input# }"
                ;;
            --comparison\ *|--comparison)
                if [ "$TEMPLATE_FLAG_SEEN" = true ]; then
                    echo "Error: Multiple template flags specified." >&2
                    exit 1
                fi
                TEMPLATE="code-comparison"
                TEMPLATE_FLAG_SEEN=true
                raw_input="${raw_input#--comparison}"
                raw_input="${raw_input# }"
                ;;
            --custom\ *|--custom)
                if [ "$TEMPLATE_FLAG_SEEN" = true ]; then
                    echo "Error: Multiple template flags specified." >&2
                    exit 1
                fi
                TEMPLATE="custom"
                TEMPLATE_FLAG_SEEN=true
                raw_input="${raw_input#--custom}"
                raw_input="${raw_input# }"
                ;;
            --return-only\ *|--return-only)
                RETURN_ONLY=true
                raw_input="${raw_input#--return-only}"
                raw_input="${raw_input# }"
                ;;
            --plan\ *|--plan)
                PLAN=true
                raw_input="${raw_input#--plan}"
                raw_input="${raw_input# }"
                ;;
            *)
                # No more flags, break out of loop
                break
                ;;
        esac
    done

    # Validate template name if provided
    if [ -n "$TEMPLATE" ]; then
        case "$TEMPLATE" in
            code-refactoring|code-review|test-generation|documentation-generator|data-extraction|code-comparison|custom)
                # Valid template
                ;;
            *)
                echo "Error: Invalid template name: $TEMPLATE" >&2
                exit 1
                ;;
        esac
    fi

    # Normalize whitespace and set global TASK_DESCRIPTION
    raw_input=$(echo "$raw_input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]][[:space:]]*/ /g')

    TASK_DESCRIPTION="$raw_input"
}

# Handle initial state - spawn template-selector or prompt-optimizer
handle_initial_state() {
    parse_initial_flags "$1"
    local sanitized_task=$(sanitize_input "$TASK_DESCRIPTION")

    # If no template specified, spawn template-selector first
    if [ -z "$TEMPLATE" ]; then
        cat <<EOF
STATE: initial
NEXT_ACTION: spawn_template_selector

TODO_LIST:
1. [in_progress] Determine template
2. [pending] Optimize prompt
3. [pending] Execute task
4. [pending] Present results

Use the Task tool:
- subagent_type: "meta-prompt:template-selector"
- description: "Select template for task"
- prompt: "Select the best template for this task:

<template_selector_request>
<user_task>$sanitized_task</user_task>
</template_selector_request>

Follow your instructions to classify the task and return the result in XML format."

After receiving the result, pass it to the handler script along with the original flags:
~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh '<template_selector_result>...(full XML output)...</template_selector_result>
<original_task>$sanitized_task</original_task>
<plan_flag>$PLAN</plan_flag>
<return_only_flag>$RETURN_ONLY</return_only_flag>'
EOF
        return
    fi

    # Template already specified, proceed to optimizer
    # Determine execution mode
    local execution_mode="direct"
    if [ "$PLAN" = true ]; then
        execution_mode="plan"
    fi

    # Build template XML
    local template_xml="<template>$TEMPLATE</template>"

    # Check if return-only mode
    if [ "$RETURN_ONLY" = true ]; then
        cat <<EOF
STATE: initial
NEXT_ACTION: spawn_optimizer_return_only

TODO_LIST:
1. [in_progress] Optimize prompt
2. [pending] Present optimized prompt

Use the Task tool:
- subagent_type: "meta-prompt:prompt-optimizer"
- description: "Create optimized prompt"
- prompt: "Process this request and return an optimized prompt:

<prompt_optimizer_request>
<user_task>$sanitized_task</user_task>$template_xml
<execution_mode>$execution_mode</execution_mode>
</prompt_optimizer_request>

Follow your instructions to process the template and return the result in XML format."

After receiving the result, present the optimized prompt to the user (do not execute).
EOF
    else
        cat <<EOF
STATE: initial
NEXT_ACTION: spawn_optimizer

TODO_LIST:
1. [in_progress] Optimize prompt
2. [pending] Execute task
3. [pending] Present results

Use the Task tool:
- subagent_type: "meta-prompt:prompt-optimizer"
- description: "Create optimized prompt"
- prompt: "Process this request and return an optimized prompt:

<prompt_optimizer_request>
<user_task>$sanitized_task</user_task>$template_xml
<execution_mode>$execution_mode</execution_mode>
</prompt_optimizer_request>

Follow your instructions to process the template and return the result in XML format."

After receiving the result, pass it to the handler script to get the next instruction:
~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh '<prompt_optimizer_result>...(full XML output)...</prompt_optimizer_result>'
EOF
    fi
}

# Handle post-template-selector state - spawn prompt-optimizer with selected template
handle_post_template_selector_state() {
    local selector_output="$1"

    # Extract values from XML using sed (BSD-compatible)
    local selected_template=$(echo "$selector_output" | sed -n 's/.*<selected_template>\(.*\)<\/selected_template>.*/\1/p')
    local original_task=$(echo "$selector_output" | sed -n 's/.*<original_task>\(.*\)<\/original_task>.*/\1/p')
    local plan_flag=$(echo "$selector_output" | sed -n 's/.*<plan_flag>\(.*\)<\/plan_flag>.*/\1/p')
    local return_only_flag=$(echo "$selector_output" | sed -n 's/.*<return_only_flag>\(.*\)<\/return_only_flag>.*/\1/p')

    # Sanitize for safe output
    local sanitized_task=$(sanitize_input "$original_task")

    # Determine execution mode
    local execution_mode="direct"
    if [ "$plan_flag" = "true" ]; then
        execution_mode="plan"
    fi

    # Build template XML
    local template_xml="<template>$selected_template</template>"

    # Check if return-only mode
    if [ "$return_only_flag" = "true" ]; then
        cat <<EOF
STATE: post_template_selector
NEXT_ACTION: spawn_optimizer_return_only

TODO_LIST:
1. [completed] Determine template
2. [in_progress] Optimize prompt
3. [pending] Present optimized prompt

Use the Task tool:
- subagent_type: "meta-prompt:prompt-optimizer"
- description: "Create optimized prompt"
- prompt: "Process this request and return an optimized prompt:

<prompt_optimizer_request>
<user_task>$sanitized_task</user_task>$template_xml
<execution_mode>$execution_mode</execution_mode>
</prompt_optimizer_request>

Follow your instructions to process the template and return the result in XML format."

After receiving the result, present the optimized prompt to the user (do not execute).
EOF
    else
        cat <<EOF
STATE: post_template_selector
NEXT_ACTION: spawn_optimizer

TODO_LIST:
1. [completed] Determine template
2. [in_progress] Optimize prompt
3. [pending] Execute task
4. [pending] Present results

Use the Task tool:
- subagent_type: "meta-prompt:prompt-optimizer"
- description: "Create optimized prompt"
- prompt: "Process this request and return an optimized prompt:

<prompt_optimizer_request>
<user_task>$sanitized_task</user_task>$template_xml
<execution_mode>$execution_mode</execution_mode>
</prompt_optimizer_request>

Follow your instructions to process the template and return the result in XML format."

After receiving the result, pass it to the handler script to get the next instruction:
~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh '<prompt_optimizer_result>...(full XML output)...</prompt_optimizer_result>'
EOF
    fi
}

# Handle post-optimizer state - spawn Plan or template-executor
handle_post_optimizer_state() {
    local optimizer_output="$1"

    # Extract values from XML using sed (BSD-compatible)
    local template=$(echo "$optimizer_output" | sed -n 's/.*<template>\(.*\)<\/template>.*/\1/p')
    local skill=$(echo "$optimizer_output" | sed -n 's/.*<skill>\(.*\)<\/skill>.*/\1/p')
    local execution_mode=$(echo "$optimizer_output" | sed -n 's/.*<execution_mode>\(.*\)<\/execution_mode>.*/\1/p')
    local optimized_prompt=$(echo "$optimizer_output" | sed -n 's/.*<optimized_prompt>\(.*\)<\/optimized_prompt>.*/\1/p')

    # Sanitize for safe output
    local sanitized_skill=$(sanitize_input "$skill")

    if [ "$execution_mode" = "plan" ]; then
        cat <<EOF
STATE: post_optimizer
NEXT_ACTION: spawn_plan_agent

TODO_LIST:
1. [completed] Optimize prompt
2. [in_progress] Create plan
3. [pending] Execute task
4. [pending] Present results

Use the Task tool:
- subagent_type: "Plan"
- description: "Create execution plan"
- prompt: "SKILL_TO_LOAD: $sanitized_skill

$optimized_prompt"

After the Plan agent completes and returns its plan, pass the result to the handler script:
~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/commands/scripts/prompt-handler.sh '<plan_result>
<skill>$sanitized_skill</skill>
<optimized_prompt>
$optimized_prompt
</optimized_prompt>
</plan_result>'
EOF
    else
        cat <<EOF
STATE: post_optimizer
NEXT_ACTION: spawn_template_executor

TODO_LIST:
1. [completed] Optimize prompt
2. [in_progress] Execute task
3. [pending] Present results

Use the Task tool:
- subagent_type: "meta-prompt:template-executor"
- description: "Execute task"
- prompt: "SKILL_TO_LOAD: $sanitized_skill

<template_executor_request>
<skill>$sanitized_skill</skill>
<optimized_prompt>
$optimized_prompt
</optimized_prompt>
</template_executor_request>

Follow your instructions to load the skill (if not 'none') and execute the task."

After the template-executor completes, present the results to the user.
EOF
    fi
}

# Handle post-plan state - spawn template-executor with the plan
handle_post_plan_state() {
    local plan_output="$1"

    # Extract values from XML using sed (BSD-compatible)
    local skill=$(echo "$plan_output" | sed -n 's/.*<skill>\(.*\)<\/skill>.*/\1/p')

    # Extract optimized_prompt (multiline content)
    local optimized_prompt=$(echo "$plan_output" | sed -n '/<optimized_prompt>/,/<\/optimized_prompt>/p' | sed '1d;$d')

    # Sanitize for safe output
    local sanitized_skill=$(sanitize_input "$skill")

    cat <<EOF
STATE: post_plan
NEXT_ACTION: spawn_template_executor

TODO_LIST:
1. [completed] Optimize prompt
2. [completed] Create plan
3. [in_progress] Execute task
4. [pending] Present results

Use the Task tool:
- subagent_type: "meta-prompt:template-executor"
- description: "Execute task"
- prompt: "SKILL_TO_LOAD: $sanitized_skill

<template_executor_request>
<skill>$sanitized_skill</skill>
<optimized_prompt>
$optimized_prompt
</optimized_prompt>
</template_executor_request>

Follow your instructions to load the skill (if not 'none') and execute the task."

After the template-executor completes, present the results to the user.
EOF
}

# Handle final state - just present results
handle_final_state() {
    cat <<EOF
STATE: final
NEXT_ACTION: done

TODO_LIST:
1. [completed] Optimize prompt
2. [completed] Execute task
3. [in_progress] Present results

Present the execution results to the user.
EOF
}

# Main state machine logic
main() {
    # Check if input is provided as command-line arg
    if [ $# -gt 0 ]; then
        # Use command-line args
        INPUT="$1"
        # Detect state from input
        STATE=$(detect_state "$INPUT")
    else
        # No input provided
        echo "Error: No input provided. Usage: $0 '<task description>'" >&2
        echo "   Or: $0 '<xml>'" >&2
        exit 1
    fi

    # Execute state handler
    case "$STATE" in
        initial)
            handle_initial_state "$INPUT"
            ;;
        post_template_selector)
            handle_post_template_selector_state "$INPUT"
            ;;
        post_optimizer)
            handle_post_optimizer_state "$INPUT"
            ;;
        post_plan)
            handle_post_plan_state "$INPUT"
            ;;
        final)
            handle_final_state
            ;;
        *)
            echo "Error: Unknown state: $STATE" >&2
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
