# Claude Experiments

A curated marketplace for Claude Code plugins focused on meta-prompt optimization and developer productivity.

## What is This?

This repository is a Claude Code plugin marketplace that provides tools to reduce LLM token consumption and improve prompt engineering workflows. Plugins in this marketplace help you work more efficiently with Claude by optimizing how prompts are constructed and executed.

## Installation

Install this marketplace in Claude Code:

```bash
/plugin install jtsylve/claude-experiments
```

Once installed, all plugins in this marketplace will be available for use in your Claude Code environment.

## Available Plugins

### meta-prompt (v1.0.0)

**Reduce LLM token consumption by 40-60% through deterministic preprocessing and template-based routing.**

The meta-prompt plugin replaces LLM-based orchestration with shell scripts and pre-built templates, invoking the LLM only for actual creative and analytical work. This results in significant token savings while maintaining full functionality.

#### Key Features

- **Token Reduction:** 40-60% overall, 100% for orchestration
- **Classification Accuracy:** 90%+ for template routing
- **Performance:** <100ms deterministic overhead
- **Templates:** 10 pre-built templates covering common patterns
- **Security:** Input sanitization, whitelist-based permissions

#### Commands

- `/prompt <task>` - Optimize and execute a prompt with automatic template selection
- `/prompt <task> --return-only` - Generate optimized prompt without executing
- `/create-prompt <task>` - Generate a custom-tailored prompt template

#### Templates Included

| Template | Use Cases | Variables |
|----------|-----------|-----------|
| simple-classification | Compare items, check equivalence | 3 |
| document-qa | Answer with citations, extract info | 2 |
| code-refactoring | Modify code, fix bugs, add features | 2 |
| function-calling | API usage, tool invocation | 2 |
| interactive-dialogue | Tutors, customer support bots | 4 |
| test-generation | Generate unit tests, test suites, edge cases | 3 |
| code-review | Security audits, quality analysis, feedback | 3 |
| documentation-generator | API docs, READMEs, docstrings, user guides | 3 |
| data-extraction | Extract data from logs, JSON, HTML, text | 3 |
| custom | Novel tasks (LLM fallback) | 1 |

#### Template Variables

Each template uses specific variables to customize behavior:

**simple-classification:** ITEM1, ITEM2, COMPARISON_CRITERIA
**document-qa:** DOCUMENT_CONTENT, QUESTION
**code-refactoring:** CODE_TO_REFACTOR, REFACTORING_GOAL
**function-calling:** API_DESCRIPTION, TASK_OBJECTIVE
**interactive-dialogue:** ROLE_DESCRIPTION, DOMAIN_EXPERTISE, INTERACTION_STYLE, USER_LEVEL
**test-generation:** CODE_TO_TEST, TEST_FRAMEWORK, TEST_SCOPE
**code-review:** CODE_TO_REVIEW, REVIEW_FOCUS, LANGUAGE_CONVENTIONS
**documentation-generator:** CODE_OR_CONTENT, DOC_TYPE, AUDIENCE
**data-extraction:** SOURCE_DATA, EXTRACTION_TARGETS, OUTPUT_FORMAT
**custom:** TASK_DESCRIPTION

#### Quick Start

```bash
# Optimize and execute a prompt
/prompt "Analyze security vulnerabilities in the authentication module"

# Create an optimized prompt without executing
/prompt "Refactor user service to use dependency injection" --return-only

# Generate a prompt template
/create-prompt "Compare two code snippets for semantic equivalence"
```

#### Performance Metrics

| Metric | Target | Status |
|--------|--------|--------|
| Token reduction | 40-60% | Met |
| Orchestration tokens | 0 | Met |
| Classification accuracy | 90%+ | Met |
| Deterministic overhead | <100ms | Met |

#### Documentation

See [meta-prompt/README.md](meta-prompt/README.md) for complete documentation including:
- Architecture overview
- Template authoring guide
- Script development guide
- Examples and use cases
- Contribution guidelines

## Contributing to the Marketplace

We welcome contributions of new plugins and improvements to existing ones!

### Adding a New Plugin

To propose a new plugin for this marketplace:

1. **Fork this repository** and create a new branch for your plugin
2. **Create a plugin directory** following the structure:
   ```
   your-plugin-name/
   ├── .claude-plugin/
   │   ├── plugin.json          # Plugin manifest
   │   └── settings.json         # Optional: permissions and settings
   ├── commands/                 # Slash commands (optional)
   ├── agents/                   # AI agents (optional)
   ├── templates/                # Prompt templates (optional)
   ├── skills/                   # Skills (optional)
   ├── README.md                 # Plugin documentation
   └── CONTRIBUTING.md           # Plugin contribution guidelines
   ```

3. **Create plugin.json** with required fields:
   ```json
   {
     "name": "your-plugin-name",
     "description": "Clear description of what your plugin does",
     "version": "1.0.0",
     "author": {
       "name": "Your Name"
     }
   }
   ```

4. **Update marketplace.json** to include your plugin:
   ```json
   {
     "plugins": [
       {
         "name": "your-plugin-name",
         "source": "./your-plugin-name",
         "description": "Brief description"
       }
     ]
   }
   ```

5. **Add comprehensive documentation** in your plugin's README.md:
   - What problem does it solve?
   - How to use it
   - Examples
   - Configuration options

6. **Test thoroughly** before submitting:
   - Validate all commands work
   - Test all templates and agents
   - Verify permissions are correct
   - Check documentation for clarity

7. **Submit a pull request** with:
   - Clear description of your plugin
   - Use cases and examples
   - Any dependencies or requirements
   - Testing results

### Plugin Requirements

All plugins in this marketplace must:

- Have a clear, focused purpose
- Include comprehensive documentation
- Follow security best practices (input sanitization, proper permissions)
- Include examples and use cases
- Be tested and validated before submission
- Have a semantic version number
- Include a CONTRIBUTING.md if accepting contributions

### Plugin Guidelines

**Good candidates for this marketplace:**
- Tools that optimize prompt engineering workflows
- Meta-prompting utilities and templates
- Developer productivity enhancements
- Token optimization tools
- Prompt analysis and debugging tools

**Not suitable for this marketplace:**
- Plugins unrelated to prompt optimization or meta-prompting
- Plugins with security vulnerabilities
- Plugins without proper documentation
- Plugins that duplicate existing functionality without improvement

## Marketplace Maintenance

This marketplace is maintained by the claude-experiments team. We review all pull requests and ensure:
- Code quality and security standards
- Documentation completeness
- Compatibility with Claude Code
- No conflicts with existing plugins

## Support

### For Plugin Users

If you have questions about using a plugin:
1. Check the plugin's README.md first
2. Look through existing issues in this repository
3. Open a new issue with the `question` label

### For Plugin Developers

If you're developing a plugin for this marketplace:
1. Read the full [CONTRIBUTING.md](CONTRIBUTING.md) guide
2. Review existing plugins as examples
3. Open an issue to discuss your plugin idea before implementing
4. Join discussions in pull requests and issues

### Reporting Issues

Found a bug or security issue?
1. Check if it's already reported
2. Create a new issue with:
   - Which plugin is affected
   - Steps to reproduce
   - Expected vs actual behavior
   - Your environment (OS, Claude Code version)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Joe T. Sylve, Ph.D.

Individual plugins may have their own licenses. Check each plugin's directory for license information.

## Version

**Marketplace Version:** 1.0.0
**Last Updated:** 2025-11-18

---

## Quick Links

- [meta-prompt Plugin Documentation](meta-prompt/README.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Marketplace Manifest](.claude-plugin/marketplace.json)
