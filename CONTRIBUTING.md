# Contributing to Claude Experiments

Thank you for your interest in contributing to Claude Experiments! This guide will help you get started whether you're contributing a new plugin, improving an existing plugin, or enhancing the marketplace infrastructure.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Contributing a New Plugin](#contributing-a-new-plugin)
3. [Contributing to Existing Plugins](#contributing-to-existing-plugins)
4. [Contributing to Marketplace Infrastructure](#contributing-to-marketplace-infrastructure)
5. [Development Workflow](#development-workflow)
6. [Pull Request Process](#pull-request-process)
7. [Plugin Standards](#plugin-standards)
8. [Testing Requirements](#testing-requirements)
9. [Documentation Standards](#documentation-standards)

---

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- Git 2.0+ installed
- Claude Code CLI (latest version)
- Text editor with markdown support
- Understanding of Claude Code plugin structure

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/jtsylve/claude-experiments
cd claude-experiments

# Explore the structure
ls -la
# Should see: .claude-plugin/, meta-prompt/, README.md, CONTRIBUTING.md
```

### Understand the Marketplace

Before contributing, familiarize yourself with:

1. **Marketplace structure** - See README.md
2. **Existing plugins** - Browse meta-prompt/ as an example
3. **Plugin requirements** - Read Plugin Standards section below

**Time investment:** 30-60 minutes for basic understanding

---

## Contributing a New Plugin

### Step 1: Propose Your Plugin

Before writing code, open an issue to discuss your plugin idea:

**Issue template:**
```markdown
## Plugin Proposal: [Plugin Name]

**Purpose:** What problem does this plugin solve?

**Target Users:** Who will use this plugin?

**Features:**
- Feature 1
- Feature 2
- Feature 3

**Similar Plugins:** Are there existing plugins with similar functionality?

**Differentiation:** If similar plugins exist, how is yours different/better?

**Implementation Plan:** Brief overview of your approach
```

**Why propose first?**
- Avoid duplicate work
- Get early feedback on approach
- Ensure plugin fits marketplace goals
- Discuss potential integration issues

### Step 2: Create Plugin Structure

```bash
# Create a new branch
git checkout -b plugin/your-plugin-name

# Create plugin directory structure
mkdir -p your-plugin-name/.claude-plugin
mkdir -p your-plugin-name/commands/scripts
mkdir -p your-plugin-name/agents
mkdir -p your-plugin-name/templates
mkdir -p your-plugin-name/docs

# Create required files
touch your-plugin-name/.claude-plugin/plugin.json
touch your-plugin-name/README.md
touch your-plugin-name/CONTRIBUTING.md
```

### Step 3: Create Plugin Manifest

Create `your-plugin-name/.claude-plugin/plugin.json`:

```json
{
  "name": "your-plugin-name",
  "description": "Clear, concise description of what your plugin does (1-2 sentences)",
  "version": "1.0.0",
  "author": {
    "name": "Your Name",
    "email": "your.email@example.com",
    "url": "https://your-website.com"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/username/repo"
  },
  "keywords": ["meta-prompting", "optimization", "relevant-keywords"],
  "license": "MIT"
}
```

**Required fields:**
- `name` - Kebab-case, alphanumeric + hyphens only
- `description` - Clear, concise (max 200 chars)
- `version` - Semantic versioning (major.minor.patch)
- `author.name` - Plugin author name

**Optional but recommended:**
- `author.email` - Contact email
- `author.url` - Website or GitHub profile
- `repository` - Source code location
- `keywords` - Search terms (3-5 recommended)
- `license` - License identifier

### Step 4: Implement Plugin Components

**Commands** (optional):
- Create `.md` files in `commands/`
- Add bash scripts in `commands/scripts/` if needed
- Follow command naming conventions (imperative verbs)

**Agents** (optional):
- Create agent definitions in `agents/`
- Use clear, descriptive names
- Include comprehensive system prompts

**Templates** (optional):
- Create template files in `templates/`
- Use frontmatter for metadata
- Include example usage

**Settings** (if needed):
- Create `.claude-plugin/settings.json`
- Define permissions explicitly
- Document all settings

### Step 5: Write Documentation

Create `your-plugin-name/README.md` with:

```markdown
# [Plugin Name]

Brief description (1-2 sentences)

## Installation

How to install your plugin (usually automatic via marketplace)

## Quick Start

Simple example showing core functionality

## Features

- Feature 1: Description
- Feature 2: Description
- Feature 3: Description

## Usage

### Command 1

Detailed usage instructions with examples

### Command 2

More examples

## Configuration

How to configure the plugin (if applicable)

## Examples

Real-world use cases

## Troubleshooting

Common issues and solutions

## Contributing

Link to your plugin's CONTRIBUTING.md

## License

License information
```

### Step 6: Update Marketplace Manifest

Edit `.claude-plugin/marketplace.json` to add your plugin:

```json
{
  "name": "claude-experiments",
  "description": "A curated marketplace for Claude Code meta-prompt optimization plugins",
  "owner": {
    "name": "Joe T. Sylve, Ph.D."
  },
  "plugins": [
    {
      "name": "meta-prompt",
      "source": "./meta-prompt",
      "description": "Reduce LLM token consumption by 40-60% through deterministic preprocessing"
    },
    {
      "name": "your-plugin-name",
      "source": "./your-plugin-name",
      "description": "Brief description of your plugin"
    }
  ]
}
```

### Step 7: Test Your Plugin

Before submitting:

```bash
# Validate plugin.json is valid JSON
cat your-plugin-name/.claude-plugin/plugin.json | python3 -m json.tool

# Test all commands work
# [specific testing based on your plugin]

# Verify documentation
# - All links work
# - Examples are accurate
# - Screenshots are included (if applicable)
```

### Step 8: Submit Pull Request

See [Pull Request Process](#pull-request-process) below.

---

## Contributing to Existing Plugins

To improve an existing plugin (like meta-prompt):

1. **Check the plugin's CONTRIBUTING.md** first
   - Example: `meta-prompt/CONTRIBUTING.md`
   - Each plugin may have specific guidelines

2. **Create a feature branch**
   ```bash
   git checkout -b improve/meta-prompt-feature-name
   ```

3. **Make your changes**
   - Follow the plugin's existing patterns
   - Maintain consistency with plugin style
   - Update relevant documentation

4. **Test thoroughly**
   - Run plugin's test suite
   - Validate all affected features
   - Test edge cases

5. **Submit PR to this repository**
   - Reference the plugin name in PR title
   - Follow plugin's testing checklist

---

## Contributing to Marketplace Infrastructure

Improving the marketplace itself (not individual plugins):

### Examples of Infrastructure Contributions

- Improving marketplace.json schema validation
- Adding CI/CD for plugin validation
- Creating plugin discovery tools
- Enhancing marketplace documentation
- Building plugin management utilities

### Process

1. **Open an issue first** to discuss the improvement
2. **Create a branch**: `git checkout -b infrastructure/improvement-name`
3. **Make changes** to marketplace-level files only:
   - `.claude-plugin/marketplace.json`
   - `README.md`
   - `CONTRIBUTING.md`
   - Any CI/CD scripts
4. **Test impact** on all existing plugins
5. **Submit PR** with clear explanation of benefits

---

## Development Workflow

### Branching Strategy

**Plugin contributions:**
```
plugin/new-plugin-name          # New plugins
improve/plugin-name-feature     # Improvements to existing plugins
fix/plugin-name-bug             # Bug fixes
```

**Infrastructure contributions:**
```
infrastructure/feature-name     # Marketplace improvements
docs/improvement                # Documentation updates
```

**Branch lifecycle:**
```
main (protected)
  ├── plugin/your-plugin ← You work here
  │   ├── Commit 1
  │   ├── Commit 2
  │   └── Commit 3
  └── Merge PR → main
```

### Commit Message Conventions

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `plugin:` New plugin or plugin feature
- `fix:` Bug fix
- `docs:` Documentation only
- `infra:` Marketplace infrastructure
- `test:` Adding or updating tests

**Scopes:**
- Plugin name (e.g., `meta-prompt`)
- `marketplace` for infrastructure changes
- `docs` for documentation

**Examples:**

```
plugin(sentiment-analyzer): Add new sentiment analysis plugin

- Plugin: sentiment-analyzer v1.0.0
- Commands: /analyze-sentiment
- Templates: sentiment-positive, sentiment-negative, sentiment-neutral
- Tested: All validation passes
- Documentation: Complete README and examples

This plugin fills a gap in the marketplace for text sentiment
analysis workflows commonly used in customer feedback analysis.
```

```
fix(meta-prompt): Correct confidence calculation for code category

The code-refactoring category was not counting "modify"
as a supporting keyword, causing misclassification.

Added "modify" to supporting keywords array.

Fixes #42
```

```
docs(marketplace): Update plugin contribution guidelines

- Clarified plugin.json required fields
- Added examples for each plugin component
- Improved testing checklist

Makes it easier for new contributors to add plugins.
```

---

## Pull Request Process

### Creating a Pull Request

1. **Push your branch:**
   ```bash
   git push origin plugin/your-plugin-name
   ```

2. **Create PR on GitHub**

3. **Use the PR template:**

```markdown
## Summary
Brief description of what this PR does

## Type of Change
- [ ] New plugin
- [ ] Plugin improvement
- [ ] Plugin bug fix
- [ ] Marketplace infrastructure
- [ ] Documentation

## Plugin Information (if applicable)
- **Plugin name:** your-plugin-name
- **Version:** 1.0.0
- **Author:** Your Name

## Changes
- Added sentiment-analysis plugin
- Includes /analyze-sentiment command
- Added 3 templates for different sentiment types
- Complete documentation and examples

## Testing
- [ ] Plugin.json is valid JSON
- [ ] All commands tested and working
- [ ] All templates validated
- [ ] Documentation complete and accurate
- [ ] Examples tested
- [ ] No conflicts with existing plugins

## Related Issues
Fixes #123
Related to #456

## Additional Notes
[Any additional context, screenshots, or notes]
```

### Review Process

**For new plugins:**
1. Initial review within 3 business days
2. Reviewers check:
   - Plugin quality and functionality
   - Documentation completeness
   - Security considerations
   - Marketplace fit
3. Address feedback
4. Final approval requires 1+ maintainer approval

**For plugin improvements:**
1. Initial review within 2 business days
2. May need plugin author approval too
3. Faster for bug fixes

**For infrastructure:**
1. Discussion in issue first
2. Review within 2 business days
3. Requires 2+ maintainer approvals

---

## Plugin Standards

### Required for All Plugins

1. **Valid plugin.json** with all required fields
2. **README.md** with:
   - Clear description
   - Installation/usage instructions
   - Examples
   - Troubleshooting
3. **Security considerations:**
   - Input sanitization for user data
   - Proper permissions in settings.json
   - No hardcoded secrets
4. **Working functionality:**
   - All advertised features work
   - No breaking errors
   - Graceful error handling

### Recommended for Quality Plugins

1. **CONTRIBUTING.md** for plugin-specific contributions
2. **Comprehensive documentation:**
   - Architecture overview
   - API reference
   - Multiple examples
3. **Tests** (if applicable):
   - Validation scripts
   - Integration tests
   - Example test outputs
4. **Version control:**
   - Semantic versioning
   - Changelog
   - Migration guides for breaking changes

### Security Requirements

**All plugins MUST:**
- Sanitize user input before processing
- Use whitelisted permissions in settings.json
- Not execute arbitrary user code without sandboxing
- Not access filesystem outside plugin directory without permission
- Not make network requests without disclosure
- Not store sensitive data insecurely

**Security review required for:**
- Bash script execution
- File system access
- Network requests
- External tool integration

---

## Testing Requirements

### For New Plugins

**Minimum testing:**
1. Plugin.json validation
   ```bash
   cat your-plugin-name/.claude-plugin/plugin.json | python3 -m json.tool
   ```

2. Functional testing of all features
   - Test each command
   - Verify all templates work
   - Test all agents respond correctly

3. Documentation accuracy
   - All examples work as shown
   - All links are valid
   - Screenshots are current

**Recommended testing:**
1. Edge case testing
2. Error handling verification
3. Performance testing (if performance-critical)
4. Cross-platform testing (macOS, Linux)

### For Plugin Improvements

**Required:**
1. All existing tests still pass
2. New tests for new functionality
3. Regression testing for bug fixes

### Test Documentation

Include in your PR:
- What you tested
- How you tested it
- Test results/output
- Any limitations or known issues

---

## Documentation Standards

### Writing Style

- **Clarity:** Write for beginners
- **Completeness:** Cover all features
- **Accuracy:** Only document what exists
- **Examples:** Show, don't just tell
- **Conciseness:** Be thorough but brief

### File Conventions

**Use relative paths from repository root:**
```markdown
✓ Good: meta-prompt/commands/prompt.md
✓ Good: your-plugin-name/README.md
✗ Bad: ../commands/prompt.md
✗ Bad: /Users/joe/project/file.sh
```

**Link to plugin-specific docs:**
```markdown
✓ Good: See [meta-prompt documentation](meta-prompt/README.md)
✓ Good: Check [template guide](meta-prompt/docs/template-authoring.md)
✗ Bad: See the meta-prompt docs
```

### Markdown Formatting

Follow standard markdown conventions:
- One H1 (`#`) per file (document title)
- Use H2 (`##`) for major sections
- Use H3 (`###`) for subsections
- Code blocks with language specification
- Tables for structured data
- Lists for sequential items

---

## Getting Help

### Resources

- **Marketplace README:** [README.md](README.md)
- **Example Plugin:** Browse [meta-prompt/](meta-prompt/)
- **Issues:** Search existing issues for similar questions

### Questions?

1. Check this CONTRIBUTING.md first
2. Review the plugin you're interested in
3. Search closed issues
4. Open a new issue with "Question:" prefix

### Reporting Bugs

**For plugin bugs:**
Create an issue with:
- Plugin name and version
- Clear description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Claude Code version)

**For marketplace bugs:**
Create an issue with:
- Description of the issue
- Impact on plugins
- Proposed solution (if any)

---

## Release Process

### For Plugin Authors

When releasing a new version of your plugin:

1. **Update version** in plugin.json (semantic versioning)
2. **Update CHANGELOG** (if you maintain one)
3. **Test thoroughly**
4. **Create PR** with version bump
5. **Tag release** after merge (maintainers will do this)

### For Marketplace Maintainers

1. Review and approve plugin PRs
2. Merge to main
3. Create git tags for new plugins: `plugin-name-v1.0.0`
4. Update marketplace version if infrastructure changed
5. Announce new plugins/versions

---

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Provide constructive feedback
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing private information
- Other unprofessional conduct

### Reporting

Report issues to the maintainers via:
- Private email (if available)
- GitHub issue with `conduct` label
- Direct message on relevant platforms

---

## Plugin Approval Criteria

Before a plugin is accepted, it must meet:

### Functional Criteria
- [ ] Solves a real problem
- [ ] Works as advertised
- [ ] Doesn't duplicate existing functionality (or improves upon it)
- [ ] Fits marketplace theme (meta-prompting, optimization, productivity)

### Quality Criteria
- [ ] Code is well-structured
- [ ] Documentation is complete
- [ ] Examples are helpful
- [ ] Error messages are clear
- [ ] Performance is acceptable

### Security Criteria
- [ ] No security vulnerabilities
- [ ] Proper input validation
- [ ] Appropriate permissions
- [ ] No hardcoded secrets
- [ ] Safe file/network operations

### Community Criteria
- [ ] Responsive to feedback
- [ ] Willing to maintain plugin
- [ ] Follows contribution guidelines
- [ ] Professional communication

---

## Thank You!

Your contributions make this marketplace better for everyone. Whether you're adding a new plugin, improving existing ones, or enhancing documentation, we appreciate your time and effort!

Questions? Open an issue or reach out to the maintainers.

Happy contributing!
