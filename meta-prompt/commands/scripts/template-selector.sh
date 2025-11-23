#!/usr/bin/env bash
# Purpose: Classify tasks and route to appropriate templates
# Inputs: $@=task_description (all arguments joined with spaces)
#         Note: Multi-word descriptions should be quoted or passed as multiple args
#         Examples:
#           ./template-selector.sh "Refactor the code"
#           ./template-selector.sh Refactor the code  (equivalent to above)
# Outputs: template_name confidence (e.g., "code-refactoring 75")
# Accuracy target: 90%+

set -euo pipefail

# Confidence thresholds (0-100)
# NOTE: These values were initially determined by Claude during development and may need
# empirical tuning based on real-world usage patterns. Consider adjusting based on:
# - Template selection accuracy metrics from logs/template-selections.jsonl
# - User feedback on mis-classifications
# - Trade-off between keyword routing speed vs LLM fallback accuracy
#
# Routing thresholds (0-100)
# CONFIDENCE_THRESHOLD (70%): Minimum confidence to use keyword-selected template directly
# BORDERLINE_MIN (60%): Lower bound for hybrid routing - triggers LLM fallback for verification
# BORDERLINE_MAX (69%): Upper bound for borderline range (used for validation only)
#   Note: The actual borderline range is [BORDERLINE_MIN, CONFIDENCE_THRESHOLD), but we define
#   BORDERLINE_MAX for documentation and to validate that CONFIDENCE_THRESHOLD = BORDERLINE_MAX + 1
CONFIDENCE_THRESHOLD=70
BORDERLINE_MIN=60
BORDERLINE_MAX=69

# Confidence calculation constants (0-100)
# These values were empirically determined during development and tuned for accuracy
STRONG_INDICATOR_BASE=75      # Base confidence when strong indicator found
SUPPORTING_KEYWORD_BONUS=8    # Confidence added per supporting keyword (when strong indicator present)
ONE_KEYWORD_CONFIDENCE=35     # Confidence with 1 supporting keyword (no strong indicator)
TWO_KEYWORD_CONFIDENCE=60     # Confidence with 2 supporting keywords (no strong indicator)
THREE_KEYWORD_CONFIDENCE=75   # Confidence with 3+ supporting keywords (no strong indicator)

# Validate threshold relationships
# These checks ensure the borderline range (60-69%) is correctly configured
if [ $BORDERLINE_MIN -ge $BORDERLINE_MAX ]; then
    echo "Error: BORDERLINE_MIN ($BORDERLINE_MIN) must be less than BORDERLINE_MAX ($BORDERLINE_MAX)" >&2
    exit 1
fi

if [ $BORDERLINE_MAX -ge $CONFIDENCE_THRESHOLD ]; then
    echo "Error: BORDERLINE_MAX ($BORDERLINE_MAX) must be less than CONFIDENCE_THRESHOLD ($CONFIDENCE_THRESHOLD)" >&2
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Log directory and file
LOG_DIR="${SCRIPT_DIR}/../../logs"
LOG_FILE="${LOG_DIR}/template-selections.jsonl"
LOG_WARNING_SHOWN=false

# Privacy Notice:
# Logs use deterministic SHA-256 hashing to anonymize task descriptions.
# While this prevents direct recovery of task content, logs should still be
# treated as sensitive data. Do not share logs publicly as:
# - Common/guessable tasks could be reverse-engineered via dictionary attacks
# - Hash values could reveal usage patterns over time
# - Combined with other data, hashes might be correlatable to users
# See docs/design-decisions.md (AD-007) for full privacy analysis.

# Create log directory if it doesn't exist
mkdir -p "${LOG_DIR}" 2>/dev/null || true

# Regex patterns for strong indicators (extracted for maintainability)
# Each pattern matches whole words only using word boundary assertions
PATTERN_CODE="refactor|codebase|implement|fix|update|modify|create|build|reorganize|improve|enhance|transform|optimize|rework|revamp|refine|polish|modernize|clean|streamline"
PATTERN_FUNCTION="functions?|apis?|tools?"
PATTERN_COMPARISON="compare|classify|check|same|different|verify|determine|match|matches|equivalent|equals?|similar|duplicate|identical"
PATTERN_TEST="tests?|spec|testing|unittest"
PATTERN_REVIEW="review|feedback|critique|analyze|assess|evaluate|examine|inspect|scrutinize|audit|scan|survey|vet|investigate|appraise"
PATTERN_DOCUMENTATION="documentation|readme|docstring|docs|document|write.*(comment|docstring|documentation|guide|instruction)|author.*(documentation|instruction|guide)"
PATTERN_EXTRACTION="extract|parse|pull|retrieve|mine|harvest|collect|scrape|distill|gather|isolate|obtain|sift|fish|pluck|glean|cull|unearth|dredge|winnow"

# Portable hash function (supports both shasum and sha256sum)
compute_hash() {
    local input="$1"
    if command -v shasum &>/dev/null; then
        printf %s "$input" | shasum -a 256 | cut -d' ' -f1 | cut -c1-16
    elif command -v sha256sum &>/dev/null; then
        printf %s "$input" | sha256sum | cut -d' ' -f1 | cut -c1-16
    else
        # Fallback: use simple checksum if neither is available
        printf %s "$input" | cksum | cut -d' ' -f1
    fi
}

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

    # Count matches using word boundaries (prevents boundary chars from being consumed)
    echo "$text" | grep -oiE "\b($pattern)\b" | wc -l | tr -d ' '
}

# Pre-compute strong indicators for all categories in a single pass (optimized)
# Sets global variables: HAS_STRONG_CODE, HAS_STRONG_FUNCTION, etc.
compute_strong_indicators() {
    local text="$1"

    # Check all patterns and store results in variables (using word boundaries)
    if echo "$text" | grep -qiE "\b($PATTERN_CODE)\b"; then
        HAS_STRONG_CODE=1
    else
        HAS_STRONG_CODE=0
    fi

    if echo "$text" | grep -qiE "\b($PATTERN_FUNCTION)\b"; then
        HAS_STRONG_FUNCTION=1
    else
        HAS_STRONG_FUNCTION=0
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

# Check if task contains strong indicator keywords (worth 75% confidence alone)
# Now uses pre-computed results from compute_strong_indicators()
has_strong_indicator() {
    local category="$1"

    case "$category" in
        "code")
            return $((1 - HAS_STRONG_CODE))
            ;;
        "function")
            return $((1 - HAS_STRONG_FUNCTION))
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

# Classify task and return template name with confidence
classify_task() {
    local task_description="$1"
    local task_lower=$(to_lowercase "$task_description")

    # Pre-compute strong indicators for all categories (optimization: single pass)
    compute_strong_indicators "$task_lower"

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

    # Calculate confidence scores using configured constants
    calculate_confidence() {
        local category=$1
        local supporting_count=$2

        # Check for strong indicator first (uses pre-computed results)
        if has_strong_indicator "$category"; then
            # Strong indicator gives base confidence, each supporting keyword adds bonus
            local confidence=$((STRONG_INDICATOR_BASE + supporting_count * SUPPORTING_KEYWORD_BONUS))
            [ $confidence -gt 100 ] && confidence=100
            echo $confidence
        else
            # No strong indicator: supporting keywords only
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

    # Hybrid routing logic:
    # - High confidence (70%+): Use selected template directly
    # - Borderline (60-69%): Use selected template (caller triggers LLM verification)
    # - Low confidence (<60%): Use custom template
    if [ $max_confidence -lt $BORDERLINE_MIN ]; then
        selected_template="custom"
        max_confidence=0
    fi

    # Log the selection decision
    if [ "${ENABLE_LOGGING:-1}" = "1" ]; then
        # Create task hash for privacy (handles newlines and special chars safely)
        local task_hash
        task_hash=$(compute_hash "$task_description")

        # Create log entry with all confidence scores
        # Note: Using single-line format to prevent log injection from newlines in task descriptions
        local log_entry
        log_entry="{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"task_hash\":\"$task_hash\",\"selected_template\":\"$selected_template\",\"confidence\":$max_confidence,\"confidences\":{\"code\":$code_confidence,\"function\":$function_confidence,\"comparison\":$comparison_confidence,\"test\":$test_confidence,\"review\":$review_confidence,\"documentation\":$documentation_confidence,\"extraction\":$extraction_confidence}}"

        # Append to log file with error handling and race condition protection
        # Use flock for atomic writes to prevent corruption from concurrent instances
        (
            # Try to acquire exclusive lock (timeout after 1 second)
            if command -v flock &>/dev/null && flock -w 1 200; then
                echo "$log_entry" >> "${LOG_FILE}" 2>/dev/null
            else
                # Fallback: write without lock if flock unavailable or times out
                echo "$log_entry" >> "${LOG_FILE}" 2>/dev/null
            fi
        ) 200>>"${LOG_FILE}.lock" 2>/dev/null || {
            # Show one-time warning on first logging failure to alert users
            if [ "$LOG_WARNING_SHOWN" = "false" ]; then
                echo "Warning: Failed to write to log file ${LOG_FILE} (disk space, permissions, or file corruption)" >&2
                echo "         Logging will continue to be attempted but errors will be silent" >&2
                echo "         Set ENABLE_LOGGING=0 to disable logging" >&2
                LOG_WARNING_SHOWN=true
            fi
            # In debug mode, show every failure
            if [ "${DEBUG:-0}" = "1" ]; then
                echo "Debug: Log write failed for entry with confidence $max_confidence" >&2
            fi
        }
    fi

    # Output: template_name confidence
    echo "$selected_template $max_confidence"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <task_description>" >&2
        echo "" >&2
        echo "The task description can be quoted or passed as multiple arguments." >&2
        echo "Multiple arguments will be joined with spaces." >&2
        echo "" >&2
        echo "Examples:" >&2
        echo "  $0 'Refactor the authentication module to use JWT tokens'" >&2
        echo "  $0 Refactor the authentication module to use JWT tokens" >&2
        echo "" >&2
        echo "Output: <template-name> <confidence>" >&2
        echo "  e.g., code-refactoring 75" >&2
        return 1
    fi

    local task_description="$*"
    local result=$(classify_task "$task_description")
    local template_name=$(echo "$result" | cut -d' ' -f1)
    local confidence=$(echo "$result" | cut -d' ' -f2)

    # Validate parsed output
    if [ -z "$template_name" ] || [ -z "$confidence" ]; then
        echo "Error: Failed to parse template selector output" >&2
        echo "custom 0"
        return 1
    fi

    # Validate confidence is a number
    if ! [[ "$confidence" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid confidence value: $confidence" >&2
        echo "custom 0"
        return 1
    fi

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
