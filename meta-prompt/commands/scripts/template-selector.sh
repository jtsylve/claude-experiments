#!/usr/bin/env bash
# Purpose: Classify tasks and route to appropriate templates
# Inputs: $1=task_description
# Outputs: template_name (or "custom")
# Accuracy target: 90%+

set -euo pipefail

# Confidence threshold (0-100)
CONFIDENCE_THRESHOLD=70

# Borderline confidence range for LLM fallback (60-69%)
BORDERLINE_MIN=60
BORDERLINE_MAX=69

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Log directory and file
LOG_DIR="${SCRIPT_DIR}/../../logs"
LOG_FILE="${LOG_DIR}/template-selections.jsonl"

# Create log directory if it doesn't exist
mkdir -p "${LOG_DIR}" 2>/dev/null || true

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
            if echo "$text" | grep -qiE "(^|[^a-z])(refactor|codebase|implement|fix|update|modify|create|build|reorganize|improve|enhance|transform|optimize|rework|revamp|refine|polish|modernize|clean|streamline)([^a-z]|$)"; then
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
        "comparison")
            if echo "$text" | grep -qiE "(^|[^a-z])(compare|classify|check|same|different|verify|determine|match|matches|equivalent|equals?|similar|duplicate|identical)([^a-z]|$)"; then
                return 0
            else
                return 1
            fi
            ;;
        "test")
            if echo "$text" | grep -qiE "(^|[^a-z])(tests?|spec|testing|unittest)([^a-z]|$)"; then
                return 0
            else
                return 1
            fi
            ;;
        "review")
            if echo "$text" | grep -qiE "(^|[^a-z])(review|feedback|critique|analyze|assess|evaluate|examine|inspect|scrutinize|audit|scan|survey|vet|investigate|appraise)([^a-z]|$)"; then
                return 0
            else
                return 1
            fi
            ;;
        "documentation")
            if echo "$text" | grep -qiE "(^|[^a-z])(documentation|readme|docstring|docs|document|write.*(comment|docstring|documentation|guide|instruction)|author.*(documentation|instruction|guide))([^a-z]|$)"; then
                return 0
            else
                return 1
            fi
            ;;
        "extraction")
            if echo "$text" | grep -qiE "(^|[^a-z])(extract|parse|pull|retrieve|mine|harvest|collect|scrape|distill|gather|isolate|obtain|sift|fish|pluck|glean|cull|unearth|dredge|winnow)([^a-z]|$)"; then
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
    local function_keywords=("call" "invoke" "execute" "use" "available" "functions")
    local comparison_keywords=("sentence" "equal" "whether" "mean" "version" "duplicate" "similarity")
    local test_keywords=("coverage" "jest" "pytest" "junit" "mocha" "case" "suite" "edge" "unit" "generate")
    local review_keywords=("quality" "readability" "maintainability" "practices" "smell" "analyze")
    local documentation_keywords=("docs" "comment" "guide" "reference" "explain" "api" "write" "function" "inline" "author" "instructions" "setup" "method")
    local extraction_keywords=("data" "scrape" "retrieve" "json" "html" "csv" "email" "address" "timestamp" "logs" "file")

    # Count supporting keyword matches for each category
    local code_count=$(count_matches "$task_lower" "${code_keywords[@]}")
    local function_count=$(count_matches "$task_lower" "${function_keywords[@]}")
    local comparison_count=$(count_matches "$task_lower" "${comparison_keywords[@]}")
    local testgen_count=$(count_matches "$task_lower" "${test_keywords[@]}")
    local review_count=$(count_matches "$task_lower" "${review_keywords[@]}")
    local documentation_count=$(count_matches "$task_lower" "${documentation_keywords[@]}")
    local extraction_count=$(count_matches "$task_lower" "${extraction_keywords[@]}")

    # Debug logging for keyword counts
    [ -n "${DEBUG:-}" ] && echo "Keyword counts: code=$code_count function=$function_count comparison=$comparison_count testgen=$testgen_count review=$review_count documentation=$documentation_count extraction=$extraction_count" >&2

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
    local function_confidence=$(calculate_confidence "function" $function_count)
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

    if [ $function_confidence -gt $max_confidence ]; then
        max_confidence=$function_confidence
        selected_template="function-calling"
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

    # If confidence below threshold, use custom template
    # Keep actual confidence for borderline detection (60-69%)
    if [ $max_confidence -lt $CONFIDENCE_THRESHOLD ]; then
        selected_template="custom"
        # Only set to 0 if truly low confidence (< 60%)
        if [ $max_confidence -lt $BORDERLINE_MIN ]; then
            max_confidence=0
        fi
    fi

    # Log the selection decision
    if [ "${ENABLE_LOGGING:-1}" = "1" ]; then
        # Create task hash for privacy
        local task_hash
        task_hash=$(echo -n "$task_description" | shasum -a 256 | cut -d' ' -f1 | cut -c1-16)

        # Create log entry with all confidence scores
        local log_entry
        log_entry=$(cat <<EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","task_hash":"$task_hash","selected_template":"$selected_template","confidence":$max_confidence,"confidences":{"code":$code_confidence,"function":$function_confidence,"comparison":$comparison_confidence,"test":$test_confidence,"review":$review_confidence,"documentation":$documentation_confidence,"extraction":$extraction_confidence}}
EOF
)
        # Append to log file
        echo "$log_entry" >> "${LOG_FILE}" 2>/dev/null || true
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

    # Output: template_name confidence
    echo "$template_name $confidence"

    # Debug info to stderr (optional)
    if [ "${DEBUG:-0}" = "1" ]; then
        echo "Confidence: $confidence%" >&2
        echo "Threshold: $CONFIDENCE_THRESHOLD%" >&2
    fi
}

# Run main function
main "$@"
