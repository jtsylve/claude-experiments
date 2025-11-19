# Changelog

All notable changes to the meta-prompt plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-01-XX

### Added
- MIT License with copyright notice
- Environment variable validation in bash scripts to prevent silent failures
- `CLAUDE_PLUGIN_ROOT` validation in `template-processor.sh` and `validate-templates.sh`

### Changed
- **BREAKING:** Agent references now use fully-qualified names (`meta-prompt:prompt-optimizer` instead of `prompt-optimizer`)
  - All `Task` tool calls must use `subagent_type="meta-prompt:prompt-optimizer"`
  - This change is required by the Claude Code plugin marketplace namespacing system
  - Migration: Update any code or scripts that reference the agent to use the fully-qualified name
- Model references updated from `sonnet` to explicit model ID `claude-sonnet-4-5-20250929`
  - Ensures consistent behavior with specific model version
  - Future updates: Consider updating to newer model versions as they become available
- Author information standardized to "Joe T. Sylve, Ph.D." across all files
- All script paths updated to use `${CLAUDE_PLUGIN_ROOT}` environment variable instead of relative paths
  - Improves portability and reliability when scripts are invoked from different directories
  - Scripts will now fail fast with clear error messages if `CLAUDE_PLUGIN_ROOT` is not set

### Fixed
- Integration test suite updated to reference correct agent file path (`agents/prompt-optimizer.md`)
- Bash scripts no longer use fragile `cd` and `dirname` logic for path resolution

## [1.0.0] - Previous Release

Initial release with template-based prompt optimization infrastructure.
