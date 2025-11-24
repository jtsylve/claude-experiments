# Code Refactoring

Modify code with clean, secure, maintainable changes that precisely meet requirements.

## Workflow

1. **Discover:** Glob for files, Grep for patterns
2. **Read:** Always read before modifying
3. **Modify:** Edit existing (prefer over Write)
4. **Verify:** Run tests

## Rules

| Rule | Details |
|------|---------|
| Read first | Never modify unread files |
| Edit > Write | Use Edit for existing, Write only for new |
| Delete completely | No `_unused` prefixes or `// removed` comments |
| Match style | Follow existing conventions exactly |
| Minimal changes | Only what's requested |

## Security Checklist

**Prevent:**
- Command injection → Use arrays, not string interpolation: `exec('cmd', [args])`
- XSS → Use `textContent`, not `innerHTML`
- SQL injection → Use parameterized queries
- Path traversal → Validate with `path.basename()`

## Tool Usage

```
Glob: pattern: "**/*.js"           # Find files
Grep: pattern: "func", output_mode: "files_with_matches"  # Search
Read: file_path: "/path/file.js"   # Read before edit
Edit: file_path, old_string, new_string  # Modify
```

Parallelize independent Read calls. Chain sequentially: Read → Edit → Bash (test).

## Quality

- Three similar lines > premature abstraction
- Meaningful names, focused functions
- Comments only where logic isn't obvious
- Refactor only when explicitly requested
