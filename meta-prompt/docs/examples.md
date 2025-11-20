# Examples and Use Cases

This document provides 10 detailed examples showing how the meta-prompt optimization system works in practice, including token consumption comparisons.

---

## Table of Contents

1. [Example 1: Comparing Code Snippets (simple-classification)](#example-1-comparing-code-snippets)
2. [Example 2: Answering Questions from Documentation (document-qa)](#example-2-answering-questions-from-documentation)
3. [Example 3: Refactoring a Module (code-refactoring)](#example-3-refactoring-a-module)
4. [Example 4: Building an API Client (function-calling)](#example-4-building-an-api-client)
5. [Example 5: Creating a Tutor Bot (interactive-dialogue)](#example-5-creating-a-tutor-bot)
6. [Example 6: Generating Unit Tests (test-generation)](#example-6-generating-unit-tests)
7. [Example 7: Code Review for Security (code-review)](#example-7-code-review-for-security)
8. [Example 8: Generating API Documentation (documentation-generator)](#example-8-generating-api-documentation)
9. [Example 9: Extracting Data from Logs (data-extraction)](#example-9-extracting-data-from-logs)
10. [Example 10: Novel Task Requiring Custom Template](#example-10-novel-task-requiring-custom-template)

---

## Example 1: Comparing Code Snippets

### User Input

```bash
/create-prompt "Are these two functions semantically equivalent?"
```

### Classification Process

**Step 1: Template Selection**
```bash
# Behind the scenes (0 tokens consumed)
DEBUG=1 commands/scripts/template-selector.sh \
  "Are these two functions semantically equivalent?"
```

**Output:**
```
simple-classification
Confidence: 85%
Threshold: 70%
```

**Reasoning:**
- Keyword "equivalent" matches strong indicator for classification
- Keyword "two" indicates comparison
- Keyword "functions" adds supporting evidence
- Confidence: 75% (base) + 8% (supporting) = 83%

**Step 2: Variable Extraction**

The system extracts:
- `ITEM1`: (will be provided by user or inferred)
- `ITEM2`: (will be provided by user or inferred)
- `CLASSIFICATION_CRITERIA`: "semantic equivalence"

**Step 3: Template Processing**

Template loaded: `templates/simple-classification.md`

Variables substituted:
```markdown
You are checking whether two items match based on specific criteria.

<item1>
{user provides first function}
</item1>

<item2>
{user provides second function}
</item2>

<criteria>
semantic equivalence
</criteria>

[... rest of template ...]
```

### Token Consumption

| Approach | Tokens | Breakdown |
|----------|--------|-----------|
| **Without Optimization** | ~1800 | 300 (orchestration) + 1500 (template generation) |
| **With Optimization** | ~20 | 20 (template retrieval) |
| **Savings** | **1780 tokens** | **98.9% reduction** |

### Final Prompt Generated

```markdown
You are checking whether two items match based on specific criteria.

<item1>
function add(a, b) {
  return a + b;
}
</item1>

<item2>
const add = (a, b) => a + b;
</item2>

<criteria>
semantic equivalence
</criteria>

Analyze whether these two items match based on the criteria above.

**Instructions:**
- Begin your answer immediately with either "[YES]" or "[NO]"
- After your answer, you may provide a brief justification if helpful
- Be specific and direct in your analysis
```

### Expected LLM Response

```
[YES]
Both functions perform identical operations: they accept two parameters and return their sum. The first uses traditional function declaration syntax while the second uses ES6 arrow function syntax, but they are semantically equivalent.
```

---

## Example 2: Answering Questions from Documentation

### User Input

```bash
/create-prompt "What are the installation requirements mentioned in the README?"
```

### Classification Process

**Step 1: Template Selection**
```
document-qa
Confidence: 83%
```

**Reasoning:**
- "What are" matches question pattern
- "README" indicates document analysis
- "mentioned in" suggests citation needed
- Confidence: 75% (base) + 8% (document keyword) = 83%

**Step 2: Variable Extraction**

- `DOCUMENT`: README content (user will provide or system reads)
- `QUESTION`: "What are the installation requirements?"

### Token Consumption

| Approach | Tokens | Breakdown |
|----------|--------|-----------|
| **Without Optimization** | ~1800 | 300 + 1500 |
| **With Optimization** | ~20 | Template retrieval only |
| **Savings** | **1780 tokens** | **98.9% reduction** |

### Final Prompt Generated

```markdown
You will answer a question about a document with cited references.

<document>
[README.md content provided by user or read from file]
</document>

Question: What are the installation requirements?

Process:
1. Find exact quotes from the document most relevant to the question
2. Print quotes in numbered order (or "No relevant quotes" if none exist)
3. Answer the question, referencing quotes by bracketed numbers

[... rest of template ...]
```

### Expected LLM Response

```markdown
<Relevant Quotes>
<Quote> [1] "Bash 3.2 or higher" </Quote>
<Quote> [2] "Git" </Quote>
<Quote> [3] "Claude Code CLI (latest version)" </Quote>
<Quote> [4] "Standard Unix utilities: grep, sed, awk, wc, tr, cut" </Quote>
</Relevant Quotes>

<Answer>
The installation requirements are: [1] Bash version 3.2 or higher, [2] Git for version control, [3] the latest version of Claude Code CLI, and [4] standard Unix utilities including grep, sed, awk, wc, tr, and cut.
</Answer>
```

---

## Example 3: Refactoring a Module

### User Input

```bash
/create-prompt "Refactor the authentication module to use JWT tokens instead of sessions"
```

### Classification Process

**Step 1: Template Selection**
```
code-refactoring
Confidence: 91%
```

**Reasoning:**
- "Refactor" is strong indicator (75% base confidence)
- "module", "authentication", "use" are supporting keywords (+16%)
- Total: 91%

**Step 2: Variable Extraction**

- `TASK_REQUIREMENTS`: "Refactor to use JWT tokens instead of sessions"
- `TARGET_PATTERNS`: "authentication module"

### Token Consumption

| Approach | Tokens | Breakdown |
|----------|--------|-----------|
| **Without Optimization** | ~1800 | 300 + 1500 |
| **With Optimization** | ~25 | Template retrieval + slightly larger template |
| **Savings** | **1775 tokens** | **98.6% reduction** |

### Final Prompt Generated

```markdown
You are a code refactoring assistant helping modify code according to specific requirements.

<requirements>
Refactor to use JWT tokens instead of sessions
</requirements>

<target_patterns>
authentication module
</target_patterns>

Follow these steps:

1. Use TodoWrite to plan the work:
   - Search for target patterns
   - Identify files to modify
   - Plan implementation steps
   - Plan testing approach

2. For each file requiring changes:
   - ALWAYS Read the file first
   - Use Edit for modifications (never Write unless creating new files)
   - Maintain exact indentation from the Read output

3. Execute the changes:
   - Use Glob to find files by pattern
   - Use Grep to search for code patterns
   - Chain tools efficiently: Read → Edit → Bash (for testing)
   - Update TodoWrite as you progress

4. After making changes:
   - Run existing tests
   - Verify no breaking changes
   - Mark all todos as completed

[... rest of template ...]
```

### How This Helps

The template ensures the LLM:
- Uses TodoWrite to track progress
- Reads files before editing (avoiding errors)
- Uses proper tools (Glob, Grep) instead of bash commands
- Tests changes after implementation
- Follows security best practices

**Result:** Higher quality code changes with consistent workflow.

---

## Example 4: Building an API Client

### User Input

```bash
/create-prompt "Use the GitHub API to list all open issues in the anthropics/claude-code repository"
```

### Classification Process

**Step 1: Template Selection**
```
function-calling
Confidence: 83%
```

**Reasoning:**
- "Use the ... API" is strong indicator (75%)
- "GitHub API", "repository" are supporting keywords (+8%)
- Total: 83%

**Step 2: Variable Extraction**

- `TASK_DESCRIPTION`: "List all open issues in the anthropics/claude-code repository"
- `AVAILABLE_FUNCTIONS`: (system will identify available tools/APIs)

### Token Consumption

| Approach | Tokens | Breakdown |
|----------|--------|-----------|
| **Without Optimization** | ~1800 | 300 + 1500 |
| **With Optimization** | ~25 | Template retrieval |
| **Savings** | **1775 tokens** | **98.6% reduction** |

### Final Prompt Generated

```markdown
You are a research assistant equipped with function(s) to help complete tasks.

<available_functions>
github_api(endpoint, method, params)
  - endpoint: API endpoint path (e.g., "/repos/{owner}/{repo}/issues")
  - method: HTTP method (GET, POST, PUT, DELETE)
  - params: JSON object of query parameters
</available_functions>

<task>
List all open issues in the anthropics/claude-code repository
</task>

Rules:
- Do not modify or extend provided functions
- Only use functions provided
- Function arguments must be in listed order
- Output function calls as: <function_call>specific function</function_call>
- You'll receive: <function_result> in response

Use <scratchpad> to think before making function calls.

[... rest of template ...]
```

### Expected LLM Response

```markdown
<scratchpad>
To list open issues in anthropics/claude-code:
1. Call github_api with GET method on /repos/anthropics/claude-code/issues
2. Filter for state=open
3. Present the results
</scratchpad>

<function_call>
github_api(
  endpoint="/repos/anthropics/claude-code/issues",
  method="GET",
  params={"state": "open", "per_page": 100}
)
</function_call>

<function_result>
[
  {"number": 42, "title": "Feature request: Add dark mode", ...},
  {"number": 41, "title": "Bug: Template not found error", ...},
  ...
]
</function_result>

<answer>
Found 2 open issues in the anthropics/claude-code repository:

1. Issue #42: "Feature request: Add dark mode"
2. Issue #41: "Bug: Template not found error"

[... details ...]
</answer>
```

---

## Example 5: Creating a Tutor Bot

### User Input

```bash
/create-prompt "Create a Python tutor that helps beginners learn list comprehensions using the Socratic method"
```

### Classification Process

**Step 1: Template Selection**
```
interactive-dialogue
Confidence: 83%
```

**Reasoning:**
- "tutor" is strong indicator (75%)
- "Socratic method", "helps", "learn" are supporting (+8%)
- Total: 83%

**Step 2: Variable Extraction**

- `ROLE_DESCRIPTION`: "Python tutor specializing in list comprehensions"
- `CONTEXT`: "Teaching beginners"
- `RULES`: "Use Socratic method (ask questions, don't give direct answers)"
- `INITIAL_INPUT`: (from user's first interaction)

### Token Consumption

| Approach | Tokens | Breakdown |
|----------|--------|-----------|
| **Without Optimization** | ~1800 | 300 + 1500 |
| **With Optimization** | ~20 | Template retrieval |
| **Savings** | **1780 tokens** | **98.9% reduction** |

### Final Prompt Generated

```markdown
You will act as an interactive agent with a specific role.

<role>
Python tutor specializing in list comprehensions
</role>

<context>
Teaching beginners who are new to Python
</context>

<rules>
1. Use the Socratic method: ask guiding questions rather than giving direct answers
2. Encourage students to reason through problems
3. Provide hints when students are stuck
4. Celebrate small wins and progress
5. Use simple examples before complex ones
6. Never write the complete solution immediately
</rules>

Process:
1. Use <thinking> or <inner_monologue> tags to reason about your response
2. Provide your response in <response> tags

Key guidelines:
- Stay in character for the assigned role
- Follow all rules strictly
- Use reasoning tags for complex decisions
- Be helpful and encouraging

<initial_input>
I don't understand what list comprehensions are or why I should use them.
</initial_input>
```

### Expected LLM Response

```markdown
<thinking>
The student is at the very beginning - they don't know what list comprehensions are. I should:
1. Start with a simple example they can relate to
2. Ask them what they already know about lists
3. Guide them to discover the pattern themselves
This aligns with Socratic method.
</thinking>

<response>
Great question! Let's explore this together.

First, tell me: do you know how to create a list of numbers using a for loop? For example, how would you create a list of the first 5 even numbers (2, 4, 6, 8, 10)?

Take a moment to think about it or write out the code if you'd like.
</response>
```

---

## Example 6: Generating Unit Tests

### User Input

```bash
/create-prompt "Generate pytest tests for this authentication function"
```

### Classification Process

**Template Selected:** `test-generation`
**Confidence:** 83%

**Reasoning:**
- "tests" is a strong indicator for test-generation
- "pytest" adds supporting evidence (framework keyword)
- "generate" is a supporting keyword
- Confidence: 75% (base) + 8% (supporting) = 83%

### Token Consumption

| Approach | Tokens | Breakdown |
|----------|--------|-----------|
| **Without Optimization** | ~1600 | 250 (orchestration) + 1350 (template generation) |
| **With Optimization** | ~25 | 25 (template retrieval) |
| **Savings** | **1575 tokens** | **98.4% reduction** |

**Key Benefit:** Test generation prompts follow a consistent pattern, making them ideal for templating. The template ensures comprehensive coverage (unit tests, edge cases, error handling) without requiring LLM orchestration.

---

## Example 7: Code Review for Security

### User Input

```bash
/create-prompt "Review this authentication middleware for security issues"
```

### Classification Process

**Template Selected:** `code-review`
**Confidence:** 75%

**Reasoning:**
- "review" is a strong indicator for code-review
- "security" adds supporting evidence
- Clear focus on analysis rather than modification
- Confidence: 75% (base indicator)

### Token Consumption

| Approach | Tokens | Breakdown |
|----------|--------|-----------|
| **Without Optimization** | ~1700 | 300 (orchestration) + 1400 (template generation) |
| **With Optimization** | ~30 | 30 (template retrieval) |
| **Savings** | **1670 tokens** | **98.2% reduction** |

**Key Benefit:** Code review requires systematic analysis across multiple dimensions (security, performance, readability). The template provides a comprehensive framework without LLM overhead, ensuring consistent review quality.

---

## Example 8: Generating API Documentation

### User Input

```bash
/create-prompt "Generate API documentation for this user service module"
```

### Classification Process

**Template Selected:** `documentation-generator`
**Confidence:** 83%

**Reasoning:**
- "documentation" is a strong indicator
- "API" is a supporting keyword
- "generate" adds supporting evidence
- Confidence: 75% (base) + 8% (supporting) = 83%

### Token Consumption

| Approach | Tokens | Breakdown |
|----------|--------|-----------|
| **Without Optimization** | ~1550 | 200 (orchestration) + 1350 (template generation) |
| **With Optimization** | ~25 | 25 (template retrieval) |
| **Savings** | **1525 tokens** | **98.4% reduction** |

**Key Benefit:** Documentation generation is highly structured (functions, parameters, return values, examples). The template ensures completeness and consistency across all documentation types (API docs, READMEs, docstrings).

---

## Example 9: Extracting Data from Logs

### User Input

```bash
/create-prompt "Extract email addresses and timestamps from this error log"
```

### Classification Process

**Template Selected:** `data-extraction`
**Confidence:** 75%

**Reasoning:**
- "extract" is a strong indicator for data-extraction
- "data" is a supporting keyword (implicit in "email addresses")
- Clear extraction task
- Confidence: 75% (base indicator)

### Token Consumption

| Approach | Tokens | Breakdown |
|----------|--------|-----------|
| **Without Optimization** | ~1400 | 200 (orchestration) + 1200 (template generation) |
| **With Optimization** | ~20 | 20 (template retrieval) |
| **Savings** | **1380 tokens** | **98.6% reduction** |

**Key Benefit:** Data extraction tasks follow a consistent pattern (source, targets, format). The template handles various data formats (logs, JSON, HTML) and edge cases (missing data, malformed entries) without requiring LLM planning.

---

## Example 10: Novel Task Requiring Custom Template

### User Input

```bash
/create-prompt "Write a Shakespearean sonnet about debugging code, following iambic pentameter"
```

### Classification Process

**Step 1: Template Selection**
```
custom
Confidence: 0%
```

**Reasoning:**
- No keywords match existing templates
- "sonnet", "Shakespearean", "iambic pentameter" are creative writing terms
- System correctly identifies this as a novel task
- Falls back to custom template

**Step 2: LLM Prompt Generation**

Since no template matches, the system invokes `/create-prompt` with full prompt engineering instructions. The LLM analyzes the task and generates a custom-tailored prompt.

### Token Consumption

| Approach | Tokens | Breakdown |
|----------|--------|-----------|
| **Without Optimization** | ~1500 | Full LLM prompt engineering |
| **With Optimization** | ~1500 | Same (no template available) |
| **Savings** | **0 tokens** | **No savings (as expected for novel tasks)** |

### Why This Is Acceptable

The system is designed to:
- **Optimize common patterns** (90%+ of tasks) with templates
- **Gracefully fall back to LLM** for novel tasks (10% of tasks)
- **Never sacrifice quality** for token savings

In this case:
- A poetry composition task is genuinely novel
- No existing template covers creative writing
- The LLM is better suited to generate a custom prompt
- This is the right behavior

### Final Prompt Generated (by LLM)

The LLM in `/create-prompt` would generate something like:

```markdown
You are a creative writing assistant specializing in classical poetry forms.

Your task is to compose a Shakespearean sonnet about the experience of debugging code.

<requirements>
- 14 lines total
- Rhyme scheme: ABAB CDCD EFEF GG
- Iambic pentameter: 10 syllables per line, unstressed-stressed pattern
- Traditional sonnet structure:
  - Lines 1-12: Develop the theme
  - Lines 13-14: Concluding couplet with a twist or resolution
- Theme: Debugging code (the frustrations, triumphs, and humor)
</requirements>

<guidelines>
- Use programming terminology naturally within the poetic structure
- Maintain meter while incorporating technical concepts
- Balance technical accuracy with poetic beauty
- The volta (thematic turn) should occur around line 9
</guidelines>

Write the sonnet directly without preamble.
```

---

## Summary: Token Savings Across Examples

| Example | Template | Without Opt. | With Opt. | Savings | Reduction |
|---------|----------|--------------|-----------|---------|-----------|
| 1. Code comparison | simple-classification | 1800 | 20 | 1780 | 98.9% |
| 2. Document Q&A | document-qa | 1800 | 20 | 1780 | 98.9% |
| 3. Code refactoring | code-refactoring | 1800 | 25 | 1775 | 98.6% |
| 4. API client | function-calling | 1800 | 25 | 1775 | 98.6% |
| 5. Tutor bot | interactive-dialogue | 1800 | 20 | 1780 | 98.9% |
| 6. Novel task | custom (LLM) | 1500 | 1500 | 0 | 0% |
| **Average** | **-** | **1750** | **268** | **1482** | **84.7%** |

**Notes:**
- Assumes 90% template match rate (10% fall back to custom)
- Actual savings depend on specific tasks and usage patterns
- Example 6 shows graceful degradation for novel tasks

---

## Key Takeaways

### What Makes a Good Template Match

**High confidence (>80%):**
- Clear keyword matches (compare, refactor, document, tutor)
- Structural patterns (two items → comparison, questions → Q&A)
- Domain-specific terms (code, API, function → development templates)

**Medium confidence (70-80%):**
- Supporting keywords without strong indicators
- Ambiguous phrasing that could match multiple templates
- Novel variations of common patterns

**Low confidence (<70%):**
- No keyword matches
- Genuinely novel tasks
- Creative or artistic requests
- Multi-step workflows spanning multiple categories

### When Templates Save the Most Tokens

Templates provide maximum value for:
1. **Repetitive tasks** (daily code reviews, document analysis)
2. **Well-defined patterns** (comparisons, refactoring, Q&A)
3. **High-frequency operations** (running hundreds of times)

Templates provide less value for:
1. **One-off creative tasks**
2. **Highly specific or novel requests**
3. **Tasks requiring extensive context**

But the system handles both gracefully with the fallback mechanism.

---

## Experimenting with Your Own Tasks

Try classifying your common tasks:

```bash
# Test any task description
DEBUG=1 commands/scripts/template-selector.sh "your task here"
```

Questions to ask:
1. **What template was selected?**
2. **What's the confidence score?**
3. **Does it match your expectations?**

If tasks consistently mis-classify:
- See [Template Authoring Guide](template-authoring.md) to create new templates
- See design-decisions.md:AD-004 to adjust confidence threshold
- See infrastructure.md:Updating Template Keywords to refine classification

---

## Additional Resources

- **Template Library:** `templates/` directory
- **Classification Logic:** `commands/scripts/template-selector.sh:83-166`
- **Processing Logic:** `commands/scripts/template-processor.sh`
- **Validation:** `commands/scripts/validate-templates.sh`

**Next Steps:**
- Try `/prompt` with your own tasks
- Experiment with `DEBUG=1` to see classification
- Create custom templates for your frequent patterns
- Contribute successful patterns back to the project
