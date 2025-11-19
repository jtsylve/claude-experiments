# Changelog

All notable changes to the meta-prompt plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-01-XX

### Added
- MIT License with copyright notice
- Environment variable validation in bash scripts to prevent silent failures
- `CLAUDE_PLUGIN_ROOT` validation in `template-processor.sh` and `validate-templates.sh`
- **Windows path normalization:** Shared `utils.sh` library for cross-platform path handling
  - Automatic conversion of Windows paths (backslashes) to Unix-style (forward slashes)
  - Support for Windows drive letters (C: → /c/)
  - Uses `cygpath` when available (Git Bash, Cygwin)
  - Enables seamless operation on Windows Git Bash and Cygwin environments
- New utility functions in `utils.sh`:
  - `normalize_path()`: Convert Windows paths to Unix format
  - `init_plugin_root()`: Validate and normalize CLAUDE_PLUGIN_ROOT (returns normalized path, does not modify global state)
  - `get_script_dir()`: Get absolute path to script directory (utility function for future use)
- Expanded test suite to 38 tests (from 31), including:
  - Utility function tests (path normalization, init_plugin_root)
  - Edge case tests (mixed slashes, paths with spaces, trailing slashes)
  - cygpath fallback behavior validation

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
- **Command prompts updated to normalize paths before using CLAUDE_PLUGIN_ROOT**
  - `/prompt` and `/create-prompt` commands now normalize paths using `utils.sh` before invoking scripts
  - Ensures Windows paths are converted to Unix format before being passed to bash scripts or tools
  - Critical for cross-platform compatibility in Claude Code environment
- Scripts now use shared `utils.sh` library for consistent path handling and environment validation
  - `template-processor.sh` and `validate-templates.sh` updated to use `init_plugin_root()`
  - `test-integration.sh` updated to normalize CLAUDE_PLUGIN_ROOT at startup
  - Ensures consistent behavior across all scripts

### Fixed
- Integration test suite updated to reference correct agent file path (`agents/prompt-optimizer.md`)
- Bash scripts no longer use fragile `cd` and `dirname` logic for path resolution
- **Windows path compatibility:** Scripts now handle Windows-style paths (backslashes) correctly
  - Fixes issues with `CLAUDE_PLUGIN_ROOT` on Windows Git Bash and Cygwin
  - Automatic path conversion prevents bash path resolution errors

## [1.0.0] - Previous Release

Initial release with template-based prompt optimization infrastructure.
