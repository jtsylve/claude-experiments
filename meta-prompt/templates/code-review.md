---
template_name: code-review
category: analysis
keywords: [review, feedback, check code, analyze code, quality, readability, maintainability, best practices, code smell, critique]
complexity: complex
variables: []
optional_variables: [PATHS, REVIEW_FOCUS, LANGUAGE_CONVENTIONS]
version: 1.3
description: Perform comprehensive code review
variable_descriptions:
  PATHS: "Paths to review (files/directories). Default: uncommitted changes via git status"
  REVIEW_FOCUS: "Areas to focus on (e.g., 'security', 'performance'). Default: comprehensive"
  LANGUAGE_CONVENTIONS: "Language/framework conventions to apply. Default: inferred"
---

Review code for quality, security, and maintainability.

<paths>{$PATHS:}</paths>
<focus>{$REVIEW_FOCUS:comprehensive}</focus>
<conventions>{$LANGUAGE_CONVENTIONS:inferred from code}</conventions>

## Process

1. **Get code:** If `PATHS` is empty, use Bash to run `git status --porcelain` to list changed files, then `git diff` to view the changes

2. **Analyze** across dimensions: correctness, security, performance, readability, error handling, testability

3. **Categorize** by severity:
   - **CRITICAL**: Security vulnerabilities, data loss, crashes
   - **HIGH**: Bugs, performance issues, major maintainability
   - **MEDIUM**: Code smells, refactoring opportunities
   - **LOW**: Style, alternatives

## Output

```markdown
## Summary
[2-3 sentences on quality, strengths, concerns]

## Critical Issues
[Security, correctness issues with file:line, impact, fix]

## High Priority
[Bugs, performance with location and fix]

## Medium/Low
[Suggestions, improvements]

## Positive Observations
[Good patterns worth noting]
```

Provide specific line references and code examples for fixes.
