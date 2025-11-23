# Migration Guide

This document helps users migrate from older versions of the meta-prompt plugin to the current version.

## Version 1.0.0 - Template Consolidation

### Overview

Version 1.0.0 consolidates templates from 10 to 7, removing underutilized templates and adding new ones optimized for software development workflows.

### Removed Templates

Three templates were removed in this version:

#### 1. `document-qa` → Use `custom` or `data-extraction`

**Removed:** `document-qa.md` (document question-answering with citations)

**Migration path:**
- **For extracting information from documents:** Use `data-extraction` template
  - Example: "Extract all API endpoints from the documentation"
- **For complex document analysis:** The task will automatically route to `custom` template with full LLM capabilities
  - Example: "Analyze the research paper and answer: What methodology did they use?"

**Why removed:** Low usage (<5% of tasks) and significant overlap with data-extraction and custom templates.

#### 2. `interactive-dialogue` → Use `custom`

**Removed:** `interactive-dialogue.md` (conversational agents, tutors, support bots)

**Migration path:**
- **All interactive dialogue tasks** will automatically route to `custom` template
- The `custom` template provides full LLM capabilities for conversational tasks
- Example: "Create a Socratic tutor that teaches Python" → Routes to `custom`

**Why removed:** Rare usage (<3% of tasks) and poor fit for deterministic template approach. Conversational agents require full LLM flexibility.

#### 3. `simple-classification` → Use `code-comparison`

**Removed:** `simple-classification.md` (general comparison and classification)

**Replaced by:** `code-comparison.md` (code-specific comparison)

**Migration path:**
- **For comparing code, configs, or technical artifacts:** Use `code-comparison` template
  - Example: "Compare these two functions for semantic equivalence" → Routes to `code-comparison`
- **For general classification tasks:** Routes to `custom` template
  - Example: "Classify these sentences by sentiment" → Routes to `custom`

**Why changed:** Refocused template to serve the primary use case (code comparison) which represents 90%+ of comparison tasks in software development workflows.

### New Templates

#### `code-comparison` (New)

**Purpose:** Compare code snippets, configurations, or technical artifacts

**Variables:**
- `ITEM1`: First code/config to compare
- `ITEM2`: Second code/config to compare
- `COMPARISON_CRITERIA`: What to compare (e.g., "semantic equivalence", "performance characteristics")

**Example tasks that route here:**
- "Compare these two implementations for performance"
- "Check if these config files are equivalent"
- "Determine if these functions do the same thing"

### Template Mapping Reference

| Old Template | New Template | Notes |
|--------------|--------------|-------|
| `simple-classification` | `code-comparison` | For code/config comparison |
| `simple-classification` | `custom` | For general classification |
| `document-qa` | `data-extraction` | For extracting structured data |
| `document-qa` | `custom` | For complex document analysis |
| `interactive-dialogue` | `custom` | All conversational tasks |
| `code-refactoring` | `code-refactoring` | ✓ No change |
| `test-generation` | `test-generation` | ✓ No change |
| `code-review` | `code-review` | ✓ No change |
| `documentation-generator` | `documentation-generator` | ✓ No change |
| `data-extraction` | `data-extraction` | ✓ No change |
| `custom` | `custom` | ✓ No change |

### How Templates Are Selected

The plugin uses **hybrid routing** to select templates:

1. **Keyword-based classification** analyzes your task description
2. **High confidence (70-100%):** Uses the keyword-selected template directly
3. **Borderline confidence (60-69%):** LLM verifies and selects best template
4. **Low confidence (<60%):** Routes to `custom` template with full LLM capabilities

This means most tasks will automatically route to the correct template without any changes to your workflow.

### Testing Your Migration

After upgrading, test your common workflows:

```bash
# Test a few common tasks from your workflow
/create-prompt "your typical task description"

# Enable debug mode to see routing decisions
DEBUG=1 ${CLAUDE_PLUGIN_ROOT}/commands/scripts/template-selector.sh "your task"

# Check the logs to see confidence scores
cat ${CLAUDE_PLUGIN_ROOT}/logs/template-selections.jsonl | tail -10
```

### Rollback Instructions

If you need to rollback to the previous version:

```bash
cd ${CLAUDE_PLUGIN_ROOT}
git checkout v0.9.0  # or whatever the previous version tag is
```

### Getting Help

If you encounter issues migrating:

1. Check the logs: `logs/template-selections.jsonl`
2. Run with debug: `DEBUG=1 commands/scripts/template-selector.sh "your task"`
3. Open an issue: https://github.com/jtsylve/claude-experiments/issues

### Breaking Changes Summary

- **Removed templates:** `document-qa`, `interactive-dialogue`, `simple-classification`
- **New template:** `code-comparison`
- **Automatic routing:** Most tasks will route correctly without changes
- **Custom fallback:** Tasks that don't fit existing templates automatically use `custom`

The consolidation improves focus on software development workflows while maintaining flexibility through the `custom` template and hybrid routing system.
