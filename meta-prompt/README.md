# Meta-Prompt Infrastructure

**Reduce LLM token consumption by 40-60% through deterministic preprocessing and template-based routing.**

This project implements a meta-prompt optimization infrastructure for Claude Code that replaces LLM-based orchestration with shell scripts and pre-built templates, invoking the LLM only for actual creative and analytical work.

> **⚠️ PRE-RELEASE SOFTWARE**
>
> This project is preparing for its initial v1.0.0 release. While core functionality is complete and tested, the API and file structure may still change. Use in production environments at your own risk until v1.0.0 is officially released.

---

## Quick Start

```bash
# Optimize and execute a prompt (auto-detects template)
/prompt "Analyze security vulnerabilities in the authentication module"

# Explicitly select a template with flags
/prompt --review "Check this authentication middleware for security issues"
/prompt --code "Refactor user service to use dependency injection"
/prompt --test "Generate pytest tests for the user registration function"

# Create an optimized prompt without executing
/prompt --return-only "Refactor user service to use dependency injection"
/prompt --code --return-only "Fix the authentication bug"

# Plan mode for complex multi-step tasks
/prompt --plan "Refactor user service to use dependency injection"
```

**How it works:** Your task is classified into a template category (zero tokens), variables are substituted (zero tokens), and the LLM executes only the actual work. You can explicitly select templates using flags like `--code`, `--review`, `--test`, etc., or let the system auto-detect. Result: 40-60% token savings with improved template routing.

---

## Documentation

### Core Documentation

| Document | Purpose | Read this if... |
|----------|---------|----------------|
| [Getting Started](docs/getting-started.md) | 5-minute tutorial | You're new to the project |
| [Architecture Overview](docs/architecture-overview.md) | System design and flow | You want to understand how it works |
| [Design Decisions](docs/design-decisions.md) | Rationale for key choices | You want to know WHY decisions were made |
| [Infrastructure Guide](docs/infrastructure.md) | Setup and operations | You're setting up or maintaining the system |

### Specialized Guides

| Document | Purpose |
|----------|---------|
| [Template Authoring](docs/template-authoring.md) | Creating custom templates |
| [Script Development](docs/script-development.md) | Modifying bash scripts |
| [Glossary](docs/glossary.md) | Key terminology reference |
| [Contributing](CONTRIBUTING.md) | Contribution workflow |

---

## Key Features

- **Token Reduction:** 40-60% overall, 100% for orchestration
- **Classification Accuracy:** 90%+ for template routing with LLM fallback for edge cases
- **Performance:** <100ms for keyword routing (70%+ of tasks), +500ms-2s for LLM fallback (20% of tasks)
- **Templates:** 6 specialized templates + 1 custom fallback optimized for software development
- **Hybrid Routing:** Keyword-based classification with intelligent LLM fallback for borderline cases (60-69% confidence)
- **Security:** Input sanitization, whitelist-based permissions

---

## Quick Reference

### Essential Commands

> **Note:** These commands are for development and testing. Run from the `meta-prompt/` directory when working with a cloned repository.

```bash
# Validate all templates
tests/validate-templates.sh

# Run integration tests
tests/test-integration.sh

# Make scripts executable
chmod +x commands/scripts/*.sh tests/*.sh
```

### Project Structure

```
meta-prompt/
├── .claude-plugin/    # Plugin manifest and configuration
│   ├── plugin.json    # Plugin metadata
│   └── settings.json  # Permissions and settings
├── commands/          # /prompt slash command
│   └── scripts/       # State machine handler
├── agents/            # LLM agents and handler scripts
│   ├── *.md           # Agent definitions
│   └── scripts/       # Agent handler scripts
├── skills/            # Domain-specific skills
├── templates/         # 6 pre-built prompt templates
├── docs/              # Documentation suite
├── CONTRIBUTING.md    # Contribution guidelines
└── README.md          # This file - start here
```

### Performance Metrics

| Metric | Target | Status |
|--------|--------|--------|
| Token reduction | 40-60% | ✓ Met |
| Orchestration tokens | 0 | ✓ Met |
| Classification accuracy | 90%+ | ✓ Met |
| Keyword routing overhead | <100ms | ✓ Met (70%+ of tasks) |
| Hybrid routing (w/ LLM fallback) | Variable | ~500ms-2s (20% of tasks) |

---

## Installation

### As a Claude Code Plugin (Recommended)

Install from claude-experiments:

```bash
/plugin install jtsylve/claude-experiments
```

The meta-prompt plugin will be available immediately with the `/prompt` command.

**Windows Users:**
⚠️ **Temporary Limitation**: This version uses intelligent path detection with a fallback to the standard installation location (`~/.claude/plugins/marketplaces/claude-experiments/meta-prompt`) due to a Windows path normalization bug in Claude Code.

- The plugin will work correctly if installed via `/plugin install` to the standard location
- For development/custom installations, scripts derive the path from their location
- If you encounter path issues, run `meta-prompt/commands/scripts/verify-installation.sh` to diagnose
- WSL (Windows Subsystem for Linux) is recommended for the most reliable experience
- See [Infrastructure Guide - Troubleshooting](docs/infrastructure.md#windows-compatibility) for details

### For Development

```bash
# Clone the repository
git clone https://github.com/jtsylve/claude-experiments
cd claude-experiments/meta-prompt

# Make scripts executable
chmod +x commands/scripts/*.sh tests/*.sh

# Validate installation
tests/validate-templates.sh
tests/test-integration.sh
```

See [Infrastructure Guide](docs/infrastructure.md#environment-setup) for detailed setup instructions.

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Pull request process
- Code review checklist
- Testing requirements

**Quick checklist before submitting:**
- [ ] All templates pass validation
- [ ] Integration tests pass (`test-integration.sh`)
- [ ] Documentation updated
- [ ] Permissions updated in settings.json

---

## Templates

Six specialized templates plus one custom fallback optimized for software development workflows:

| Template | Use Cases | Flags |
|----------|-----------|-------|
| code-refactoring | Modify code, fix bugs, add features | `--code` \| `--refactor` |
| code-review | Security audits, quality analysis, feedback | `--review` |
| test-generation | Generate unit tests, test suites, edge cases | `--test` |
| documentation-generator | API docs, READMEs, docstrings, user guides | `--docs` \| `--documentation` |
| data-extraction | Extract data from logs, JSON, HTML, text | `--extract` |
| code-comparison | Compare code, configs, check equivalence | `--compare` \| `--comparison` |

### Template Selection

You can select templates in two ways:

1. **Automatic (default):** The system analyzes your task and selects the best template
2. **Explicit flags:** Use flags like `--code`, `--review`, `--test` to bypass auto-detection

Example: `/prompt --review "Check this code for security issues"`

See [Template Authoring Guide](docs/template-authoring.md) to create your own.

---

## Support

**Documentation:**
- Start with this README for overview
- See [Getting Started](docs/getting-started.md) for tutorial
- Browse [docs/](docs/) for specialized guides

**Troubleshooting:**
- See [Infrastructure Guide - Troubleshooting](docs/infrastructure.md#troubleshooting)
  - Note: Windows users should review the [hardcoded paths workaround](docs/infrastructure.md#issue-windows-compatibility---claude_plugin_root-path-normalization-claude-code-bug)
- Use `DEBUG=1` with scripts for verbose output
- Run validation and tests to diagnose issues

---

## Version

**Current Version:** Pre-release (targeting v1.0.0)
**Status:** Work in Progress - Not Stable
**Last Updated:** 2025-11-24

---

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

Copyright (c) 2025 Joe T. Sylve, Ph.D.
