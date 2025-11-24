# Contributing to Meta-Prompt Infrastructure

Thank you for your interest in contributing! This guide will help you get started.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Workflow](#development-workflow)
3. [Branching Strategy](#branching-strategy)
4. [Commit Message Conventions](#commit-message-conventions)
5. [Pull Request Process](#pull-request-process)
6. [Code Review Checklist](#code-review-checklist)
7. [Testing Requirements](#testing-requirements)
8. [Documentation Standards](#documentation-standards)

---

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- Bash 3.2+ installed (default on macOS works)
- Git 2.0+ installed
- Claude Code CLI (latest version)
- Text editor with markdown support

### Initial Setup

```bash
# Clone the repository
git clone <repository-url> meta-prompt
cd meta-prompt

# Make scripts executable
chmod +x commands/scripts/*.sh tests/*.sh

# Validate installation
tests/validate-templates.sh
tests/test-integration.sh

# Expected: All templates pass, all tests pass
```

### Understand the System

Before making changes, read:

1. **[README.md](README.md)** - Project overview
2. **[docs/architecture-overview.md](docs/architecture-overview.md)** - How it works
3. **[docs/design-decisions.md](docs/design-decisions.md)** - Why decisions were made
4. **[docs/infrastructure.md](docs/infrastructure.md)** - Operational details

**Time investment:** 1-2 hours for basic understanding

---

## Development Workflow

### Step 1: Create a Feature Branch

```bash
# Fetch latest changes
git fetch origin
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

### Step 2: Make Your Changes

**For adding a template:**
1. Create template file in `templates/`
2. Update classification keywords in `template-selector.sh`
3. Add test case to `test-integration.sh`
4. Update documentation (README.md, architecture-overview.md)

**For modifying scripts:**
1. Follow [Script Development Guide](docs/script-development.md)
2. Maintain strict error handling (`set -euo pipefail`)
3. Add input sanitization for user data
4. Update tests as needed

**For documentation:**
1. Use clear, concise language
2. Include examples
3. Update related documents
4. Check for broken links

### Step 3: Test Your Changes

```bash
# Validate templates
tests/validate-templates.sh

# Run integration tests
tests/test-integration.sh

# Test logging infrastructure
tests/test-logging.sh

# Test manually with debug mode
DEBUG=1 commands/scripts/template-selector.sh "test task"
```

**Success criteria:**
- All templates pass validation (7/7)
- All integration tests pass (53/53 or more)
- Manual testing confirms expected behavior

### Step 4: Update Documentation

**Required documentation updates:**

**If you added a template:**
- [ ] README.md (template list)
- [ ] docs/architecture-overview.md (template table)
- [ ] docs/examples.md (add example usage)

**If you modified scripts:**
- [ ] docs/script-development.md (if new patterns added)
- [ ] docs/architecture-overview.md (if architecture changed)

**If you changed classification:**
- [ ] docs/design-decisions.md (if threshold or algorithm changed)

### Step 5: Update Permissions (if needed)

If you added new scripts, update `.claude-plugin/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(commands/scripts/your-new-script.sh:*)"
    ]
  }
}
```

---

## Branching Strategy

### Branch Naming

**Feature branches:**
```
feature/add-sentiment-template
feature/improve-classification
feature/add-debugging-guide
```

**Bug fix branches:**
```
fix/template-validation-error
fix/confidence-calculation
fix/broken-link-in-docs
```

**Documentation branches:**
```
docs/update-contributing-guide
docs/add-examples
docs/fix-typos
```

### Branch Lifecycle

```
main (protected)
  ├── feature/your-feature ← You work here
  │   ├── Commit 1
  │   ├── Commit 2
  │   └── Commit 3
  └── Merge PR → main
```

**Rules:**
- Never commit directly to `main`
- Keep branches focused (one feature/fix per branch)
- Delete branches after merge
- Rebase on main before creating PR

---

## Commit Message Conventions

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat:** New feature
- **fix:** Bug fix
- **docs:** Documentation only
- **refactor:** Code change that neither fixes a bug nor adds a feature
- **test:** Adding or updating tests
- **chore:** Changes to build process or auxiliary tools

### Examples

**Good commit messages:**

```
feat(templates): Add sentiment-analysis template

- Template: sentiment-analysis.md
- Classification keywords: sentiment, emotion, feeling
- Variables: TEXT_TO_ANALYZE
- Tested: validate-templates.sh passes
- Integration test added (test-integration.sh:245)

This template covers a common pattern that previously
fell back to custom LLM generation. Expected usage:
15-20 times per week based on recent task logs.
```

```
fix(template-selector): Correct confidence calculation for code category

The code-refactoring category was not counting "modify"
as a supporting keyword, causing misclassification.

Added "modify" to supporting keywords array.

Fixes #42
```

```
docs(examples): Add code-refactoring example

Added detailed example showing:
- Input variables
- Classification process
- Token savings
- Expected workflow

Addresses feedback in issue #38
```

**Bad commit messages:**

```
updated stuff
```

```
fix bug
```

```
WIP
```

### Co-Authorship

If collaborating with Claude Code, add:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Pull Request Process

### Creating a Pull Request

1. **Push your branch:**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create PR on GitHub:**
   - Go to repository
   - Click "New Pull Request"
   - Select your branch
   - Fill out PR template

3. **PR Description Template:**

   ```markdown
   ## Summary
   Brief description of what this PR does

   ## Changes
   - Added sentiment-analysis template
   - Updated classification keywords
   - Added integration test
   - Updated documentation

   ## Testing
   - [ ] All templates pass validation
   - [ ] All integration tests pass (53/53)
   - [ ] Manual testing completed
   - [ ] Documentation updated

   ## Related Issues
   Fixes #42
   Related to #38

   ## Screenshots (if applicable)
   [Add screenshots of output, test results, etc.]
   ```

### PR Checklist

Before submitting, ensure:

- [ ] Code follows project style guidelines
- [ ] All tests pass locally
- [ ] Documentation updated
- [ ] Commit messages follow conventions
- [ ] No merge conflicts with main
- [ ] Branch is up to date with main
- [ ] Permissions updated in settings.json (if needed)

---

## Code Review Checklist

### For Reviewers

When reviewing PRs, check:

#### Functionality
- [ ] Changes work as described
- [ ] No breaking changes (or clearly documented if necessary)
- [ ] Edge cases handled

#### Code Quality
- [ ] Follows bash coding standards (script-development.md)
- [ ] Error handling present (`set -euo pipefail`)
- [ ] Variables quoted properly
- [ ] Functions have clear responsibilities

#### Security
- [ ] Input sanitization present
- [ ] No command injection vulnerabilities
- [ ] No use of `eval` with user input
- [ ] File paths validated

#### Testing
- [ ] All tests pass (validate-templates.sh, test-integration.sh)
- [ ] New tests added for new functionality
- [ ] Test coverage adequate
- [ ] Manual testing documented in PR

#### Documentation
- [ ] Code commented where necessary
- [ ] Documentation files updated
- [ ] Examples provided (if applicable)
- [ ] No broken links

#### Performance
- [ ] No performance regressions
- [ ] Keyword routing < 100ms (for deterministic scripts)
- [ ] Hybrid routing with LLM fallback acceptable for borderline cases (60-69% confidence)
- [ ] Token consumption not increased unnecessarily

### Approval Process

**Requirements for merge:**
- At least 1 approval from maintainer
- All tests passing
- No unresolved comments
- Documentation complete

**Timeline:**
- Initial review: Within 2 business days
- Follow-up reviews: Within 1 business day
- Merge: After approval + 24 hours (for final checks)

---

## Testing Requirements

### Automated Tests

**Run before every commit:**

```bash
# Validate all templates
tests/validate-templates.sh

# Run integration tests
tests/test-integration.sh
```

**Expected results:**
```
=== Template Validation ===
Total templates: 10+
Passed: 10+
Failed: 0

=== Integration Tests ===
Total Tests: 53+
Passed: 50+
Failed: 0
✓ ALL TESTS PASSED!
```

### Manual Testing

**For template changes:**

```bash
# Test classification
DEBUG=1 commands/scripts/template-selector.sh "example task"

# Test processing
commands/scripts/template-processor.sh template-name \
    VAR1='value1' VAR2='value2'

# Test end-to-end
/create-prompt "example task description"
```

### Test Coverage

New features must include tests:

**For new templates:**
- Validation test (automatic)
- Classification test (add to test-integration.sh Phase 3)
- Processing test (add to test-integration.sh Phase 4)

**For script modifications:**
- Unit tests for new functions
- Integration tests for workflows
- Edge case tests

---

## Documentation Standards

### Writing Style

- **Clarity:** Write for someone new to the project
- **Completeness:** Cover all major aspects
- **Accuracy:** Only document what exists
- **Examples:** Provide concrete examples
- **Conciseness:** Be thorough but brief

### File References

**Use relative paths from project root:**

```markdown
✓ Good: `commands/scripts/template-selector.sh`
✓ Good: `docs/architecture-overview.md`
✗ Bad: `../scripts/template-selector.sh`
✗ Bad: `/Users/joe/project/file.sh`
```

### Code References

**Include line numbers for specific locations:**

```markdown
✓ Good: `commands/scripts/template-selector.sh:83-166`
✓ Good: See template-processor.sh:37 for escaping logic
✗ Bad: See the template processor script
```

### Markdown Formatting

```markdown
# H1 for document title (only one per file)
## H2 for major sections
### H3 for subsections

**Bold** for emphasis
*Italic* for terms
`code` for inline code
```

Code blocks with language:
````markdown
```bash
chmod +x script.sh
```

```yaml
---
key: value
---
```
````

### Documentation Updates

**When to update:**
- Architecture changes → architecture-overview.md
- New patterns → examples.md, template-authoring.md
- Process changes → CONTRIBUTING.md

---

## Getting Help

### Resources

- **Documentation:** Start with [README.md](README.md)
- **Examples:** See [docs/examples.md](docs/examples.md)
- **Guides:** Browse [docs/](docs/) directory
- **Code:** Read existing scripts for patterns

### Questions?

1. Check existing documentation first
2. Search closed issues for similar questions
3. Open a new issue with "Question:" prefix
4. Tag as `question` label

### Reporting Bugs

**Create an issue with:**
- Clear description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, bash version)
- Relevant logs or error messages

### Suggesting Features

**Create an issue with:**
- Description of the feature
- Use case (why is this needed?)
- Proposed implementation (optional)
- Impact on existing functionality

---

## Release Process

### Versioning

We use semantic versioning (semver):
- **Major (X.0.0):** Breaking changes
- **Minor (1.X.0):** New features, backwards compatible
- **Patch (1.0.X):** Bug fixes

### Release Checklist

**For maintainers:**

1. Update version numbers
2. Update CHANGELOG.md
3. Run full test suite
4. Create git tag: `git tag -a v1.1.0 -m "Release 1.1.0"`
5. Push tag: `git push --tags`
6. Create GitHub release with notes

---

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Provide constructive feedback
- Focus on what's best for the project
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing private information
- Other unprofessional conduct

---

## License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

Copyright (c) 2025 Joe T. Sylve, Ph.D.

---

## Thank You!

Your contributions make this project better for everyone. We appreciate your time and effort!

Questions? Open an issue or reach out to the maintainers.

Happy contributing! 🎉
