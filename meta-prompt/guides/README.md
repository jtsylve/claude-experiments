# Guides Directory

This directory contains comprehensive reference guides used by the meta-prompt plugin commands.

## Purpose

Guides are extracted from command files to:
- Improve code organization and maintainability
- Enable reusability across multiple commands
- Allow independent updates without modifying command logic
- Reduce command file complexity

## Current Guides

### engineering-guide.md

Comprehensive prompt engineering guide for creating custom prompt templates. Used by the `create-prompt` command when crafting prompts for novel tasks that don't match predefined templates.

**Contents:**
- Output format specifications
- Core principles and best practices
- Task complexity classification
- Claude Code tool usage patterns
- Quality validation checklist

**Used by:** `/create-prompt` command (when template selector returns `custom`)

## Adding New Guides

When adding new guides:
1. Extract large embedded content (>50 lines) from command files
2. Place in this directory with descriptive filename
3. Update this README with guide purpose and usage
4. Reference from commands using: `cat ~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/guides/<guide-name>.md`
5. Add error handling/fallback behavior in the command
6. Add tests to verify guide loading in `commands/scripts/test-integration.sh`
