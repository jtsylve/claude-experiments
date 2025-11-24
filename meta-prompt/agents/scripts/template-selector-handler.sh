#!/usr/bin/env bash
# Purpose: State machine for template-selector agent with integrated classification
# Inputs: XML input via stdin containing user_task, suggested_template (optional), confidence (optional)
# Outputs: Instructions with classification result
# Architecture: Incorporates template-selector.sh logic directly (no external bash calls needed)

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../scripts/common.sh"

# Setup plugin root
setup_plugin_root

TEMPLATE_DIR="${CLAUDE_PLUGIN_ROOT}/templates"

# Confidence thresholds and calculation constants
CONFIDENCE_THRESHOLD=70
BORDERLINE_MIN=60
STRONG_INDICATOR_BASE=75
SUPPORTING_KEYWORD_BONUS=8
ONE_KEYWORD_CONFIDENCE=35
TWO_KEYWORD_CONFIDENCE=60
THREE_KEYWORD_CONFIDENCE=75

# Regex patterns for strong indicators
PATTERN_CODE="refactor|codebase|implement|fix|update|modify|create|build|reorganize|improve|enhance|transform|optimize|rework|revamp|refine|polish|modernize|clean|streamline"
PATTERN_COMPARISON="compare|classify|check|same|different|verify|determine|match|matches|equivalent|equals?|similar|duplicate|identical"
PATTERN_TEST="tests?|spec|testing|unittest"
PATTERN_REVIEW="review|feedback|critique|analyze|assess|evaluate|examine|inspect|scrutinize|audit|scan|survey|vet|investigate|appraise"
PATTERN_DOCUMENTATION="documentation|readme|docstring|docs|document|write.*(comment|docstring|documentation|guide|instruction)|author.*(documentation|instruction|guide)"
PATTERN_EXTRACTION="extract|parse|pull|retrieve|mine|harvest|collect|scrape|distill|gather|isolate|obtain|sift|fish|pluck|glean|cull|unearth|dredge|winnow"

# Parse XML input from command-line argument (BSD/macOS compatible)
read_xml_input() {
    local xml_input="$1"

    # Validate input provided
    if [ -z "$xml_input" ]; then
        echo "Error: No input provided. Usage: $0 '<xml-input>'" >&2
        exit 1
    fi

    # Extract values using sed (BSD-compatible)
    local user_task=$(echo "$xml_input" | sed -n 's/.*<user_task>\(.*\)<\/user_task>.*/\1/p')
    local suggested_template=$(echo "$xml_input" | sed -n 's/.*<suggested_template>\(.*\)<\/suggested_template>.*/\1/p')
    local confidence=$(echo "$xml_input" | sed -n 's/.*<confidence>\(.*\)<\/confidence>.*/\1/p')

    # Validate required fields
    if [ -z "$user_task" ]; then
        echo "Error: Missing required field: user_task" >&2
        exit 1
    fi

    # Set defaults for optional fields
    suggested_template="${suggested_template:-}"
    confidence="${confidence:-}"

    # Validate confidence is a number if provided
    if [ -n "$confidence" ] && ! [[ "$confidence" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid confidence value: $confidence (must be integer)" >&2
        exit 1
    fi

    # Export for use by other functions
    export USER_TASK="$user_task"
    export SUGGESTED_TEMPLATE="$suggested_template"
    export SUGGESTED_CONFIDENCE="${confidence:-}"
}

# Convert text to lowercase
to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Count keyword matches
count_matches() {
    local text="$1"
    shift

    local IFS='|'
    local pattern="$*"

    echo "$text" | grep -oiE "\b($pattern)\b" 2>/dev/null | wc -l | tr -d ' '
}

# Pre-compute strong indicators
compute_strong_indicators() {
    local text="$1"

    if echo "$text" | grep -qiE "\b($PATTERN_CODE)\b"; then
        HAS_STRONG_CODE=1
    else
        HAS_STRONG_CODE=0
    fi

    if echo "$text" | grep -qiE "\b($PATTERN_COMPARISON)\b"; then
        HAS_STRONG_COMPARISON=1
    else
        HAS_STRONG_COMPARISON=0
    fi

    if echo "$text" | grep -qiE "\b($PATTERN_TEST)\b"; then
        HAS_STRONG_TEST=1
    else
        HAS_STRONG_TEST=0
    fi

    if echo "$text" | grep -qiE "\b($PATTERN_REVIEW)\b"; then
        HAS_STRONG_REVIEW=1
    else
        HAS_STRONG_REVIEW=0
    fi

    if echo "$text" | grep -qiE "\b($PATTERN_DOCUMENTATION)\b"; then
        HAS_STRONG_DOCUMENTATION=1
    else
        HAS_STRONG_DOCUMENTATION=0
    fi

    if echo "$text" | grep -qiE "\b($PATTERN_EXTRACTION)\b"; then
        HAS_STRONG_EXTRACTION=1
    else
        HAS_STRONG_EXTRACTION=0
    fi
}

# Check if category has strong indicator
has_strong_indicator() {
    local category="$1"

    case "$category" in
        "code")
            return $((1 - HAS_STRONG_CODE))
            ;;
        "comparison")
            return $((1 - HAS_STRONG_COMPARISON))
            ;;
        "test")
            return $((1 - HAS_STRONG_TEST))
            ;;
        "review")
            return $((1 - HAS_STRONG_REVIEW))
            ;;
        "documentation")
            return $((1 - HAS_STRONG_DOCUMENTATION))
            ;;
        "extraction")
            return $((1 - HAS_STRONG_EXTRACTION))
            ;;
        *)
            return 1
            ;;
    esac
}

# Calculate confidence for a category
calculate_confidence() {
    local category=$1
    local supporting_count=$2

    if has_strong_indicator "$category"; then
        local confidence=$((STRONG_INDICATOR_BASE + supporting_count * SUPPORTING_KEYWORD_BONUS))
        [ $confidence -gt 100 ] && confidence=100
        echo $confidence
    else
        if [ $supporting_count -eq 0 ]; then
            echo 0
        elif [ $supporting_count -eq 1 ]; then
            echo $ONE_KEYWORD_CONFIDENCE
        elif [ $supporting_count -eq 2 ]; then
            echo $TWO_KEYWORD_CONFIDENCE
        else
            echo $THREE_KEYWORD_CONFIDENCE
        fi
    fi
}

# Classify task and return template name with confidence
classify_task() {
    local task_description="$1"
    local task_lower=$(to_lowercase "$task_description")

    # Pre-compute strong indicators
    compute_strong_indicators "$task_lower"

    # Define supporting keywords
    local code_keywords=("code" "file" "class" "bug" "module" "system" "endpoint")
    local comparison_keywords=("sentence" "equal" "whether" "mean" "version" "duplicate" "similarity")
    local test_keywords=("coverage" "jest" "pytest" "junit" "mocha" "case" "suite" "edge" "unit" "generate")
    local review_keywords=("readability" "maintainability" "practices" "smell")
    local documentation_keywords=("comment" "guide" "reference" "explain" "api" "write" "function" "inline" "author" "instructions" "setup" "method")
    local extraction_keywords=("data" "scrape" "retrieve" "json" "html" "csv" "email" "address" "timestamp" "logs" "file")

    # Count matches
    local code_count=$(count_matches "$task_lower" "${code_keywords[@]}")
    local comparison_count=$(count_matches "$task_lower" "${comparison_keywords[@]}")
    local testgen_count=$(count_matches "$task_lower" "${test_keywords[@]}")
    local review_count=$(count_matches "$task_lower" "${review_keywords[@]}")
    local documentation_count=$(count_matches "$task_lower" "${documentation_keywords[@]}")
    local extraction_count=$(count_matches "$task_lower" "${extraction_keywords[@]}")

    # Calculate confidence scores
    local code_confidence=$(calculate_confidence "code" $code_count)
    local comparison_confidence=$(calculate_confidence "comparison" $comparison_count)
    local test_confidence=$(calculate_confidence "test" $testgen_count)
    local review_confidence=$(calculate_confidence "review" $review_count)
    local documentation_confidence=$(calculate_confidence "documentation" $documentation_count)
    local extraction_confidence=$(calculate_confidence "extraction" $extraction_count)

    # Find highest confidence
    local max_confidence=0
    local selected_template="custom"

    if [ $code_confidence -gt $max_confidence ]; then
        max_confidence=$code_confidence
        selected_template="code-refactoring"
    fi

    if [ $comparison_confidence -gt $max_confidence ]; then
        max_confidence=$comparison_confidence
        selected_template="code-comparison"
    fi

    if [ $test_confidence -gt $max_confidence ]; then
        max_confidence=$test_confidence
        selected_template="test-generation"
    fi

    if [ $review_confidence -gt $max_confidence ]; then
        max_confidence=$review_confidence
        selected_template="code-review"
    fi

    if [ $documentation_confidence -gt $max_confidence ]; then
        max_confidence=$documentation_confidence
        selected_template="documentation-generator"
    fi

    if [ $extraction_confidence -gt $max_confidence ]; then
        max_confidence=$extraction_confidence
        selected_template="data-extraction"
    fi

    # Set to custom if below borderline threshold
    if [ $max_confidence -lt $BORDERLINE_MIN ]; then
        selected_template="custom"
        max_confidence=0
    fi

    # Validate template file exists
    if [ "$selected_template" != "custom" ]; then
        local template_file="${TEMPLATE_DIR}/${selected_template}.md"
        if [ ! -f "$template_file" ]; then
            selected_template="custom"
            max_confidence=0
        fi
    fi

    # Output: template_name confidence
    echo "$selected_template $max_confidence"
}

# Determine scenario based on confidence level
get_scenario() {
    local confidence=$1

    if [ "$confidence" -ge 70 ]; then
        echo "high"
    elif [ "$confidence" -ge 60 ]; then
        echo "borderline"
    else
        echo "weak"
    fi
}

# Generate instructions based on scenario
generate_instructions() {
    # Run classification
    local result=$(classify_task "$USER_TASK")
    local template_name=$(echo "$result" | cut -d' ' -f1)
    local confidence=$(echo "$result" | cut -d' ' -f2)

    # Sanitize for output
    local sanitized_task=$(sanitize_input "$USER_TASK")

    # Determine scenario
    local scenario=$(get_scenario "$confidence")

    # Generate comparison note if suggested template differs
    local comparison_note=""
    if [ -n "$SUGGESTED_TEMPLATE" ] && [ "$template_name" != "$SUGGESTED_TEMPLATE" ]; then
        comparison_note="
Note: Classification selected '$template_name' instead of suggested '$SUGGESTED_TEMPLATE'"
    elif [ -n "$SUGGESTED_TEMPLATE" ]; then
        comparison_note="
Note: Classification agrees with suggested template '$SUGGESTED_TEMPLATE'"
    fi

    case "$scenario" in
        high)
            # High confidence (70%+): Accept classification directly
            cat <<EOF
CLASSIFICATION RESULT:
Template: $template_name
Confidence: $confidence%$comparison_note

DECISION: High confidence classification - accept directly.

Output the following XML immediately:

\`\`\`xml
<template_selector_result>
<selected_template>$template_name</selected_template>
<confidence>$confidence</confidence>
<reasoning>Keyword-based classification has high confidence ($confidence%) based on pattern matching.</reasoning>
</template_selector_result>
\`\`\`
EOF
            ;;
        borderline)
            # Borderline confidence (60-69%): Validate the classification
            cat <<EOF
CLASSIFICATION RESULT:
Template: $template_name
Confidence: $confidence% (borderline)$comparison_note

TASK: Validate if this classification is appropriate.

User task: $sanitized_task
Classified template: $template_name

Process:
1. Read the classified template file to understand its purpose:
   Read: ~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/templates/$template_name.md

2. Evaluate if the user task matches the template's use cases

3. Make your decision:
   - If it's a good match: Confirm the classification
   - If it's a poor match: Briefly evaluate 1-2 other likely templates and select the best one

Output your decision in this XML format:

\`\`\`xml
<template_selector_result>
<selected_template>template-name</selected_template>
<confidence>final-confidence-percentage</confidence>
<reasoning>1-2 sentence explanation</reasoning>
</template_selector_result>
\`\`\`
EOF
            ;;
        weak)
            # Weak/no confidence (<60%): Full evaluation
            cat <<EOF
CLASSIFICATION RESULT:
Template: $template_name
Confidence: $confidence% (low)$comparison_note

TASK: Evaluate the task against all templates and select the best match.

User task: $sanitized_task
Initial classification: $template_name (confidence: $confidence%)

Available templates:
1. code-refactoring - Modify code, fix bugs, add features, refactor
2. code-review - Security audits, quality analysis, code feedback
3. test-generation - Create tests, test suites, edge cases
4. documentation-generator - API docs, READMEs, docstrings, guides
5. data-extraction - Extract/parse data from logs, JSON, HTML, text
6. code-comparison - Compare code, check equivalence, classify similarities
7. custom - Novel tasks that don't fit standard templates

Process:
1. Consider the task type (development, analysis, generation, comparison, extraction)
2. Read relevant template files (1-3 templates that might match) to understand their scope
3. Select the best matching template or "custom" if none fit well

Output your decision in this XML format:

\`\`\`xml
<template_selector_result>
<selected_template>template-name</selected_template>
<confidence>final-confidence-percentage</confidence>
<reasoning>1-2 sentence explanation</reasoning>
</template_selector_result>
\`\`\`
EOF
            ;;
    esac
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
