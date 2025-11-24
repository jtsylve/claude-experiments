# Claude Experiments

A curated marketplace for Claude Code plugins featuring state machine-based prompt optimization and developer productivity tools.

## What is This?

This repository is a Claude Code plugin marketplace that provides tools to reduce LLM token consumption and improve prompt engineering workflows through deterministic preprocessing and specialized LLM agents. Plugins in this marketplace help you work more efficiently with Claude by optimizing how prompts are constructed and executed.

## Installation

Install this marketplace in Claude Code:

```bash
/plugin install jtsylve/claude-experiments
```

Once installed, all plugins in this marketplace will be available for use in your Claude Code environment.

## Available Plugins

### meta-prompt (v1.0.0)

**State machine-based optimization infrastructure achieving 40-60% token reduction through deterministic preprocessing and template-based routing.**

The meta-prompt plugin implements a state machine architecture with three specialized LLM agents that work together to optimize prompt execution. The system uses deterministic bash scripts for orchestration (zero tokens) and invokes LLM agents only for targeted work: template selection, prompt optimization, and task execution.

#### Architecture

- **State Machine:** Deterministic bash orchestration with zero-token overhead
- **Template Selector Agent:** Lightweight classifier for automatic template detection (Haiku model)
- **Prompt Optimizer Agent:** Extracts variables and populates templates (Sonnet model)
- **Template Executor Agent:** Executes optimized prompts with domain-specific skills (Sonnet model)

#### Key Features

- **Token Reduction:** 40-60% overall, 100% for orchestration
- **Classification Accuracy:** 90%+ for hybrid template routing
- **Performance:** <100ms deterministic overhead
- **Templates:** Domain-specific templates covering common development patterns
- **Zero-Token Orchestration:** State machine routing eliminates LLM orchestration costs
- **Specialized Agents:** Three focused agents for selection, optimization, and execution
- **Hybrid Classification:** Keyword-based routing with LLM fallback for edge cases

#### Commands

- `/prompt <task>` - Optimize and execute a prompt with automatic template selection
- `/prompt --template=<name> <task>` - Use a specific template (--code, --review, --test, --docs, --extract, --compare, --custom)
- `/prompt --plan <task>` - Create execution plan and get approval before running
- `/prompt --return-only <task>` - Generate optimized prompt without executing

#### Templates Included

| Template | Use Cases | Key Variables |
|----------|-----------|---------------|
| code-refactoring | Modify code, fix bugs, implement features | TASK_REQUIREMENTS, TARGET_PATTERNS |
| code-review | Security audits, quality analysis, feedback | PATHS, REVIEW_FOCUS, LANGUAGE_CONVENTIONS |
| test-generation | Generate unit tests, test suites, coverage | CODE_CONTEXT, FOCUS_AREAS, TEST_FRAMEWORK |
| documentation-generator | API docs, READMEs, docstrings, user guides | TARGET_FILES, DOCUMENTATION_STYLE, AUDIENCE |
| data-extraction | Extract data from logs, JSON, HTML, text | INPUT_SOURCE, EXTRACTION_PATTERN, FORMAT |
| code-comparison | Compare code snippets, check equivalence | FIRST_CODE, SECOND_CODE, COMPARISON_FOCUS |
| custom | Novel tasks (LLM fallback) | TASK_DESCRIPTION |

#### Template Variables

Each template uses specific variables that are automatically extracted from your task description:

- **code-refactoring:** TASK_REQUIREMENTS, TARGET_PATTERNS
- **code-review:** PATHS, REVIEW_FOCUS, LANGUAGE_CONVENTIONS
- **test-generation:** CODE_CONTEXT, FOCUS_AREAS, TEST_FRAMEWORK
- **documentation-generator:** TARGET_FILES, DOCUMENTATION_STYLE, AUDIENCE
- **data-extraction:** INPUT_SOURCE, EXTRACTION_PATTERN, FORMAT
- **code-comparison:** FIRST_CODE, SECOND_CODE, COMPARISON_FOCUS
- **custom:** TASK_DESCRIPTION

#### Quick Start

```bash
# Auto-detect template and execute
/prompt "Analyze security vulnerabilities in the authentication module"

# Use explicit template with planning mode
/prompt --review --plan "Check code for security issues"

# Generate tests with specific template
/prompt --test "Generate pytest tests for user service"

# Create optimized prompt without executing
/prompt --code --return-only "Refactor user service to use dependency injection"
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
