#!/usr/bin/env bash
# Purpose: Deterministic input/output processing for template-executor agent
# Inputs: XML input containing skill and optimized_prompt
# Outputs: Instructions for Claude Code to execute
# Token reduction: Eliminates XML parsing, skill routing, and output formatting

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../scripts/common.sh"

# Parse XML input from command-line argument
read_xml_input() {
    local xml_input="$1"

    # Validate input provided
    if [ -z "$xml_input" ]; then
        echo "Error: No input provided. Usage: $0 '<xml-input>'" >&2
        exit 1
    fi

    # Extract values using sed (handles multiline content)
    local skill=$(echo "$xml_input" | sed -n 's/.*<skill>\(.*\)<\/skill>.*/\1/p')

    # Extract optimized_prompt (can be multiline)
    local optimized_prompt=$(echo "$xml_input" | sed -n '/<optimized_prompt>/,/<\/optimized_prompt>/p' | sed '1d;$d')

    # Validate required fields
    if [ -z "$optimized_prompt" ]; then
        echo "Error: Missing required field: optimized_prompt" >&2
        exit 1
    fi

    # Set defaults
    skill="${skill:-none}"

    # Export for use by other functions
    export SKILL="$skill"
    export OPTIMIZED_PROMPT="$optimized_prompt"
}

# Generate instructions
generate_instructions() {
    cat <<'INSTRUCTIONS_EOF'
You are a versatile execution agent that combines template-based prompts with domain-specific skills to accomplish tasks efficiently.

## Your Task

Execute the optimized prompt provided below, following these steps:

INSTRUCTIONS_EOF

    # Step 1: Load skill (if needed)
    if [ "$SKILL" != "none" ]; then
        cat <<EOF

### Step 1: Load Skill

Load the domain-specific skill to gain expertise:

\`\`\`
Skill: $SKILL
\`\`\`

The skill provides domain-specific best practices and guidance for task execution.

EOF
    else
        cat <<EOF

### Step 1: Skill Loading

No domain-specific skill required for this task (custom template).

EOF
    fi

    # Step 2: Execute Task
    cat <<'EOF'

### Step 2: Execute Task

**IMPORTANT: Use TodoWrite to communicate your tasks and track progress throughout execution.**

Execute the task following:

1. **TodoWrite for task tracking**:
   - Create a todo list IMMEDIATELY when you start if the task has multiple steps
   - Mark tasks as in_progress before starting them
   - Mark tasks as completed immediately after finishing them
   - Keep exactly ONE task in_progress at a time
   - Use todos to communicate what you're working on to the user

2. **Parallelization**:
   - Identify independent operations that can run in parallel
   - Make multiple tool calls in a single response when possible
   - Chain dependent operations sequentially using && or multiple messages

3. **The optimized prompt's instructions** (provided below) - Your specific requirements

4. **The loaded skill's guidance** (if any) - Domain best practices and expertise

5. **Tool usage best practices**:
   - Use specialized tools (Read/Edit/Write) not bash for file operations
   - Never use placeholders - ask user if information is missing

### General Guidelines

**Code Modifications:**
- ALWAYS Read files before editing
- Use Edit for existing files, Write only for new files
- Preserve exact indentation
- Delete unused code completely (no comments or underscores)
- Avoid security vulnerabilities (injection, XSS, etc.)

**Analysis Tasks:**
- Be thorough and systematic
- Provide specific, actionable feedback
- Include examples and context
- Structure output clearly

**Quality Standards:**
- Follow existing conventions in the codebase
- Keep solutions simple and focused
- Make only requested changes (avoid over-engineering)
- Test changes when appropriate

EOF

    # Step 3: Output format
    cat <<'EOF'

### Step 3: Return Results

After completing the task, return your results in this XML format:

```xml
<template_executor_result>
<status>completed|failed|partial</status>
<summary>
Brief summary of what was accomplished
</summary>
<details>
Detailed results, changes made, files modified, etc.
</details>
</template_executor_result>
```

---

## Your Optimized Prompt

Below is the optimized prompt containing your specific task instructions:

EOF

    # Output the optimized prompt
    echo "$OPTIMIZED_PROMPT"
}

# Main function
main() {
    # Check for command-line argument
    if [ $# -eq 0 ]; then
        echo "Error: No input provided. Usage: $0 '<xml-input>'" >&2
        exit 1
    fi

    # Read and parse XML input from first argument
    read_xml_input "$1"

    # Generate and output instructions
    generate_instructions
}

# Run main function
main "$@"
