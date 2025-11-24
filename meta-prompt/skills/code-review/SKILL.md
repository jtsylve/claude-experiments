# Code Review

Provide constructive, actionable feedback on security, correctness, performance, and maintainability.

## Review Dimensions

| Dimension | Key Checks |
|-----------|------------|
| **Security** | Injection (SQL, XSS, command), auth gaps, data exposure, CORS, SSRF |
| **Correctness** | Logic errors, edge cases, race conditions, off-by-one |
| **Performance** | O(n²) loops, N+1 queries, memory leaks, missing indexes |
| **Readability** | Naming, nesting depth, magic numbers, DRY |
| **Error Handling** | Silent swallowing, missing cleanup, unhelpful messages |
| **Testability** | Tight coupling, hidden dependencies, side effects |

## Severity Levels

| Level | Criteria | Action |
|-------|----------|--------|
| 🔴 CRITICAL | Security vulns, data loss, crashes | Block merge |
| 🟠 HIGH | Bugs, performance issues | Fix before merge |
| 🟡 MEDIUM | Code smells, refactoring | Fix soon |
| 🟢 LOW | Style, alternatives | Optional |

## Output Format

```markdown
## Summary
[2-3 sentences: quality, strengths, concerns]

## 🔴 Critical Issues
**Location:** file.js:42
**Issue:** SQL injection
**Impact:** Data breach
**Fix:** Use parameterized query
\`\`\`js
// Before
db.query(`SELECT * FROM users WHERE id = ${id}`)
// After
db.query('SELECT * FROM users WHERE id = ?', [id])
\`\`\`

## 🟠 High Priority
[Same format]

## 🟡/🟢 Other
[Same format]

## ✅ Positive
[Good patterns observed]
```

## Principles

- Specific locations, not vague criticism
- Explain impact, not just what's wrong
- Code examples for fixes
- Balance criticism with recognition
