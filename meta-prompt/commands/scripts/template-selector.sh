#!/bin/bash
# Purpose: Classify tasks and route to appropriate templates
# Inputs: $1=task_description
# Outputs: template_name (or "custom")
# Accuracy target: 90%+

set -euo pipefail

# Confidence threshold (0-100)
CONFIDENCE_THRESHOLD=70

# Convert text to lowercase for case-insensitive matching
to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Count keyword matches in task description (optimized for performance)
count_matches() {
    local text="$1"
    shift

    # Build a single regex pattern with alternation for all keywords
    local IFS='|'
    local pattern="$*"

    # Count matches using a single grep call
    echo "$text" | grep -oiE "(^|[^a-z])($pattern)([^a-z]|$)" | wc -l | tr -d ' '
}

# Check if task contains strong indicator keywords (worth 75% confidence alone)
has_strong_indicator() {
    local text="$1"
    local category="$2"

    case "$category" in
        "code")
            if echo "$text" | grep -qiE "(^|[^a-z])(refactor|codebase|implement|fix|update|modify|create|build)([^a-z]|$)"; then
                return 0
            else
                return 1
            fi
            ;;
        "doc")
            if echo "$text" | grep -qiE "(^|[^a-z])(documents?|cite|quotes?|extract)([^a-z]|$)"; then
                return 0
            else
                return 1
            fi
            ;;
        "function")
            if echo "$text" | grep -qiE "(^|[^a-z])(functions?|apis?|tools?)([^a-z]|$)"; then
                return 0
            else
                return 1
            fi
            ;;
        "dialogue")
            if echo "$text" | grep -qiE "(^|[^a-z])(tutors?|dialogue|conversations?|conversational|agents?|support|teachers?)([^a-z]|$)"; then
                return 0
            else
                return 1
            fi
            ;;
        "classification")
            if echo "$text" | grep -qiE "(^|[^a-z])(compare|classify|check|same|different)([^a-z]|$)"; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# Classify task and return template name with confidence
classify_task() {
    local task_description="$1"
    local task_lower=$(to_lowercase "$task_description")

    # Define keywords for each category (supporting keywords)
    local code_keywords=("code" "file" "class" "bug" "module" "system" "endpoint")
    local doc_keywords=("question" "answer" "reference" "source" "paper")
    local function_keywords=("call" "invoke" "execute" "use" "available" "functions")
    local dialogue_keywords=("chat" "interactive" "teach" "socratic" "customer" "math")
    local classification_keywords=("sentence" "match" "equal" "whether" "mean")

    # Count supporting keyword matches for each category
    local code_count=$(count_matches "$task_lower" "${code_keywords[@]}")
    local doc_count=$(count_matches "$task_lower" "${doc_keywords[@]}")
    local function_count=$(count_matches "$task_lower" "${function_keywords[@]}")
    local dialogue_count=$(count_matches "$task_lower" "${dialogue_keywords[@]}")
    local classification_count=$(count_matches "$task_lower" "${classification_keywords[@]}")

    # Calculate confidence scores
    # Strong indicator alone = 75%, + supporting keywords increases confidence
    calculate_confidence() {
        local category=$1
        local supporting_count=$2

        # Check for strong indicator first
        if has_strong_indicator "$task_lower" "$category"; then
            # Strong indicator gives base 75%, each supporting keyword adds 8%
            local confidence=$((75 + supporting_count * 8))
            [ $confidence -gt 100 ] && confidence=100
            echo $confidence
        else
            # No strong indicator: supporting keywords only
            # 1 = 35%, 2 = 60%, 3+ = 75%
            if [ $supporting_count -eq 0 ]; then
                echo 0
            elif [ $supporting_count -eq 1 ]; then
                echo 35
            elif [ $supporting_count -eq 2 ]; then
                echo 60
            else
                echo 75
            fi
        fi
    }

    local code_confidence=$(calculate_confidence "code" $code_count)
    local doc_confidence=$(calculate_confidence "doc" $doc_count)
    local function_confidence=$(calculate_confidence "function" $function_count)
    local dialogue_confidence=$(calculate_confidence "dialogue" $dialogue_count)
    local classification_confidence=$(calculate_confidence "classification" $classification_count)

    # Find highest confidence
    local max_confidence=0
    local selected_template="custom"

    if [ $code_confidence -gt $max_confidence ]; then
        max_confidence=$code_confidence
        selected_template="code-refactoring"
    fi

    if [ $doc_confidence -gt $max_confidence ]; then
        max_confidence=$doc_confidence
        selected_template="document-qa"
    fi

    if [ $function_confidence -gt $max_confidence ]; then
        max_confidence=$function_confidence
        selected_template="function-calling"
    fi

    if [ $dialogue_confidence -gt $max_confidence ]; then
        max_confidence=$dialogue_confidence
        selected_template="interactive-dialogue"
    fi

    if [ $classification_confidence -gt $max_confidence ]; then
        max_confidence=$classification_confidence
        selected_template="simple-classification"
    fi

    # If confidence below threshold, use custom template
    if [ $max_confidence -lt $CONFIDENCE_THRESHOLD ]; then
        selected_template="custom"
        max_confidence=0
    fi

    # Output: template_name confidence
    echo "$selected_template $max_confidence"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <task_description>" >&2
        echo "" >&2
        echo "Example: $0 'Refactor the authentication module to use JWT tokens'" >&2
        return 1
    fi

    local task_description="$*"
    local result=$(classify_task "$task_description")
    local template_name=$(echo "$result" | cut -d' ' -f1)
    local confidence=$(echo "$result" | cut -d' ' -f2)

    # Output just the template name (for easy scripting)
    echo "$template_name"

    # Debug info to stderr (optional)
    if [ "${DEBUG:-0}" = "1" ]; then
        echo "Confidence: $confidence%" >&2
        echo "Threshold: $CONFIDENCE_THRESHOLD%" >&2
    fi
}

# Run main function
main "$@"
