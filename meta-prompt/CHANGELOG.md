# Changelog

All notable changes to the meta-prompt plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-01-XX

### Added
- MIT License with copyright notice
- Environment variable validation in bash scripts to prevent silent failures
- `CLAUDE_PLUGIN_ROOT` validation in `template-processor.sh` and `tests/validate-templates.sh`
- `tests/verify-documentation-counts.sh` script to validate that documentation counts match actual file counts, preventing future documentation drift
- **Template selection flags:** Users can now explicitly select templates using simple flags like `--code`, `--review`, `--test`, etc.
  - Flags must come before the task description (e.g., `/prompt --code Fix the bug`)
  - Available flags: `--code`, `--refactor`, `--review`, `--test`, `--docs`, `--documentation`, `--extract`, `--compare`, `--comparison`, `--function`, `--custom`
  - When a template flag is provided, auto-detection logic is completely bypassed
  - Flags can be combined with `--return-only` (e.g., `/prompt --code --return-only Fix the bug`)
  - Implementation in `prompt-handler.sh` lines 16-93
- **Optional template variables:** Templates now support optional variables with default values using `{$VARIABLE:default}` syntax
  - `template-processor.sh` now processes default values automatically
  - Both `{$VARIABLE:default}` and bare `{$VARIABLE}` references are replaced with the default value
  - Prevents template processing failures when not all variables can be extracted from vague task descriptions

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
- **Template updates (v1.0 → v1.1):** Multiple templates updated to make contextual variables optional
  - `code-review`: `REVIEW_FOCUS` and `LANGUAGE_CONVENTIONS` now optional (only `CODE_TO_REVIEW` required)
  - `code-refactoring`: `TARGET_PATTERNS` now optional (only `TASK_REQUIREMENTS` required)
  - `documentation-generator`: `DOC_TYPE` and `AUDIENCE` now optional (only `CODE_OR_CONTENT` required)
  - `test-generation`: `TEST_FRAMEWORK` and `TEST_SCOPE` now optional (only `CODE_TO_TEST` required)
  - `data-extraction`: `OUTPUT_FORMAT` now optional (only `SOURCE_DATA` and `EXTRACTION_TARGETS` required)
  - All optional variables provide sensible defaults (e.g., "inferred from code", "comprehensive coverage")

### Fixed
- **Template processing error handling:** `/create-prompt` now gracefully falls back to custom template when template-processor.sh fails
  - Previously, template processing failures would crash the entire prompt optimization flow
  - Now falls back to custom template crafting using the engineering guide
  - Ensures users always get an optimized prompt even when variable extraction fails
- Integration test suite updated to reference correct agent file path (`agents/prompt-optimizer.md`)
- Bash scripts no longer use fragile `cd` and `dirname` logic for path resolution
- Documentation inaccuracies corrected across 9 files:
  - Template count updated from 6 to 10 (test-generation, code-review, documentation-generator, data-extraction were present but undocumented)
  - Test count updated from 31/42 to 50 (reflecting actual test suite coverage)
  - All four previously undocumented templates now have complete documentation in getting-started.md with descriptions, variables, examples, and expected outputs
  - Template variables documented in README.md for all 10 templates
  - File tree diagrams updated in infrastructure.md to include all templates

## [1.0.0] - Previous Release

Initial release with template-based prompt optimization infrastructure.
