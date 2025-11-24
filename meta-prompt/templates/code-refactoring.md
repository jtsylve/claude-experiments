---
template_name: code-refactoring
category: development
keywords: [refactor, code, file, function, class, codebase, modify, update, change, fix, implement, create]
complexity: complex
variables: [TASK_REQUIREMENTS]
optional_variables: [TARGET_PATTERNS]
version: 1.2
description: Refactor or modify code according to specific requirements
variable_descriptions:
  TASK_REQUIREMENTS: "What to do (e.g., 'Refactor auth to JWT', 'Fix memory leak')"
  TARGET_PATTERNS: "What code to find - file globs, function/class names, patterns"
---

Modify code according to these requirements:

<requirements>{$TASK_REQUIREMENTS}</requirements>

<targets>{$TARGET_PATTERNS:analyze codebase to find relevant code}</targets>

## Workflow

1. **Plan** with TodoWrite: search patterns → identify files → plan changes → plan tests

2. **For each file:**
   - Read first (always)
   - Edit existing files (Write only for new files)
   - Preserve exact indentation

3. **Execute:** Glob for files, Grep for patterns, parallelize independent calls

4. **Verify:** Run tests, check for breaking changes

## Rules
- Make only requested changes
- Delete unused code completely (no `_unused` prefixes)
- Avoid security vulnerabilities (injection, XSS, SQL injection)
- Follow existing code style
