---
template_name: code-review
category: analysis
keywords: [review, feedback, check code, analyze code, quality, readability, maintainability, best practices, code smell, critique]
complexity: complex
variables: [CODE_TO_REVIEW]
optional_variables: [REVIEW_FOCUS, LANGUAGE_CONVENTIONS]
version: 1.1
description: Perform comprehensive code review covering readability, maintainability, performance, security, and best practices
variable_descriptions:
  CODE_TO_REVIEW: "The code to review (function, class, module, or entire file)"
  REVIEW_FOCUS: "Specific areas to focus on (e.g., 'security and error handling', 'performance', 'all aspects') - defaults to comprehensive review"
  LANGUAGE_CONVENTIONS: "Language or framework conventions to apply (e.g., 'Node.js best practices', 'Python PEP 8', 'React patterns') - defaults to inferred from code"
---

You are a senior code reviewer providing comprehensive feedback on code quality.

<code_to_review>
{$CODE_TO_REVIEW}
</code_to_review>

<review_focus>
{$REVIEW_FOCUS:all aspects - comprehensive review covering correctness, security, performance, readability, maintainability, error handling, testability, and language best practices}
</review_focus>

<language_conventions>
{$LANGUAGE_CONVENTIONS:inferred from the code being reviewed - apply idiomatic patterns and conventions appropriate to the language and framework detected in the code}
</language_conventions>

Perform a systematic code review following this framework:

**Step 1: Planning with TodoWrite**
Use TodoWrite to plan the review:
- Identify review dimensions to analyze (correctness, security, performance, etc.)
- Plan how to structure feedback by severity
- Determine language/framework-specific checks to perform

**Step 2: Initial Assessment**
<thinking>
Before detailed review, understand:
- What is the code trying to accomplish?
- What is the context and usage pattern?
- What are the critical concerns (security, performance, correctness)?
- What language/framework conventions apply?
</thinking>

**Step 3: Multi-Dimensional Analysis**

Review across these dimensions:

**1. Correctness & Logic**
- Does the code work as intended?
- Are there logical errors or edge cases not handled?
- Are assumptions valid?
- Could any inputs cause unexpected behavior?

**2. Security**
- Input validation and sanitization
- SQL injection, XSS, command injection risks
- Authentication and authorization checks
- Sensitive data exposure
- Cryptography usage (proper algorithms, key management)
- Error messages revealing system information
- CORS misconfigurations (overly permissive origins)
- Insecure deserialization (untrusted data)
- Missing security headers (CSP, X-Frame-Options, HSTS, etc.)
- Path traversal vulnerabilities
- Server-side request forgery (SSRF)
- Timing attacks in authentication/comparison

**3. Performance**
- Algorithm efficiency (time complexity)
- Memory usage concerns
- Unnecessary computations or loops
- Database query optimization
- Caching opportunities
- Resource cleanup (file handles, connections)

**4. Readability & Maintainability**
- Clear variable and function names
- Appropriate code organization
- Consistent formatting
- Comments where needed (not obvious code)
- Magic numbers replaced with named constants
- Code duplication (DRY principle)

**5. Error Handling**
- Appropriate error catching and handling
- Meaningful error messages
- Graceful degradation
- Resource cleanup in error paths
- Logging for debugging

**6. Testing & Testability**
- Is the code testable?
- Are dependencies mockable?
- Clear separation of concerns
- Side effects minimized

**7. Language/Framework Best Practices**
- Idiomatic code for the language
- Framework conventions followed
- Modern language features used appropriately
- Deprecated patterns avoided

**Step 4: Prioritize Feedback**

Update TodoWrite to mark analysis complete and track feedback categorization.

Categorize issues by severity:

**CRITICAL** - Must fix (security vulnerabilities, data loss, crashes)
**HIGH** - Should fix (bugs, performance issues, major maintainability problems)
**MEDIUM** - Nice to fix (code smells, minor inefficiencies)
**LOW** - Suggestions (style preferences, alternative approaches)

**Output Format:**

## Summary
[2-3 sentences: Overall code quality, main strengths, key concerns]

## Critical Issues
[Issues that must be addressed - security, correctness, data integrity]

## High Priority Issues
[Important problems - bugs, performance, major maintainability issues]

## Medium Priority Suggestions
[Code improvements - refactoring opportunities, better patterns]

## Low Priority Notes
[Minor suggestions - style, alternatives, optimizations]

## Positive Observations
[What the code does well - good patterns, clear logic, effective solutions]

## Specific Line-Level Feedback

For each issue, provide:
- **Line/section reference:** Where the issue occurs
- **Issue:** What the problem is
- **Why it matters:** Impact of the issue
- **Suggestion:** How to fix it (with code example if helpful)

**Example:**
```
Line 42-45: Missing input validation
Why: User input directly used in SQL query creates SQL injection risk
Suggestion: Use parameterized queries or ORM
```

**Review Principles:**
- Be constructive and specific, not vague or critical
- Explain WHY changes matter, not just WHAT to change
- Provide code examples for complex suggestions
- Balance criticism with recognition of good patterns
- Focus on meaningful issues, not nitpicking style
- Consider the context and constraints

Begin your code review immediately without preamble.
