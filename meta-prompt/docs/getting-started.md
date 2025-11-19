# Getting Started in 5 Minutes

Welcome! This guide will get you up and running with the meta-prompt optimization infrastructure in just 5 minutes.

---

## What You'll Learn

- How to use the `/prompt` command to optimize and execute tasks
- How to use the `/create-prompt` command to generate optimized prompts
- How the system saves you 40-60% in token consumption
- Where to go next for advanced usage

---

## Prerequisites Check

Before starting, verify you have:

```bash
# Check Bash version (need 4.0+)
bash --version
# Should show: GNU bash, version 4.x or higher

# Verify you're in the project directory
ls commands/
# Should show: prompt.md, create-prompt.md, scripts/
```

If scripts aren't executable:
```bash
chmod +x commands/scripts/*.sh
```

---

## Step 1: Your First Command (1 minute)

Let's start with a simple task using `/prompt`:

```bash
/prompt "Compare Python and JavaScript for web development"
```

**What happens:**
1. The bash handler script parses your request (0 tokens)
2. The task is classified as "simple-classification" (0 tokens)
3. Variables are extracted: ITEM1="Python", ITEM2="JavaScript" (0 tokens)
4. Template is loaded and processed (minimal tokens)
5. LLM executes the optimized prompt

**Result:** Instead of consuming ~300 tokens for orchestration + ~1500 for prompt generation, you consume only ~20 tokens for template retrieval.

**Token savings: ~1780 tokens (~93% reduction)**

---

## Step 2: Understanding Token Savings (1 minute)

Let's see what happened behind the scenes. Run the classification manually:

```bash
DEBUG=1 commands/scripts/template-selector.sh "Compare Python and JavaScript for web development"
```

**Expected output:**
```
simple-classification
Confidence: 85%
Threshold: 70%
```

This shows:
- **Template selected:** simple-classification
- **Confidence:** 85% (well above the 70% threshold)
- **Tokens consumed:** 0 (deterministic bash script)

Without this system, Claude Code would use LLM tokens to:
1. Parse the command
2. Decide which template to use
3. Generate the template
4. Substitute variables

Now it's all done with bash scripts (zero tokens).

---

## Step 3: Create a Prompt Without Executing (1 minute)

Sometimes you want to see the optimized prompt without executing it:

```bash
/prompt "Refactor authentication module to use JWT tokens" --return-only
```

The `--return-only` flag tells the system to:
1. Generate the optimized prompt
2. Return it to you for review
3. NOT execute it automatically

This is useful when:
- You want to review the prompt before execution
- You want to save the prompt for later use
- You're experimenting with different formulations

---

## Step 4: Generate Custom Prompts (1 minute)

For tasks that don't match existing templates, use `/create-prompt`:

```bash
/create-prompt "Write a haiku about programming"
```

**What happens:**
1. Classifier checks all templates (0 tokens)
2. No template matches (confidence < 70%)
3. Falls back to "custom" template
4. LLM generates a custom-tailored prompt

**Result:** You get full LLM flexibility when needed, but save tokens on 90%+ of routine tasks.

---

## Step 5: Explore Available Templates (1 minute)

Six templates cover common patterns:

### 1. Simple Classification
**Use for:** Comparing two items, checking equivalence
```bash
/create-prompt "Are TypeScript and Flow the same type system?"
```

### 2. Document Q&A
**Use for:** Answering questions with citations
```bash
/create-prompt "Extract all dates mentioned in this document: [document text]"
```

### 3. Code Refactoring
**Use for:** Modifying code, fixing bugs, adding features
```bash
/create-prompt "Add error handling to the user registration function"
```

### 4. Function Calling
**Use for:** Using APIs or tools to complete tasks
```bash
/create-prompt "Use the weather API to get forecast for San Francisco"
```

### 5. Interactive Dialogue
**Use for:** Creating tutors, customer support bots
```bash
/create-prompt "Act as a Python tutor helping with list comprehensions"
```

### 6. Custom (Fallback)
**Use for:** Novel tasks that don't fit other templates
- Automatically selected when confidence < 70%
- Full LLM prompt engineering

---

## Validation and Testing

Check that everything is working:

```bash
# Validate all templates
commands/scripts/validate-templates.sh
```

**Expected output:**
```
=== Template Validation ===
Validating: simple-classification
  ✓ Has valid frontmatter
  ✓ Has required fields
  [... more checks ...]
PASSED: simple-classification
[... 5 more templates ...]

=== Summary ===
Total templates: 6
Passed: 6
Failed: 0
```

Run integration tests:

```bash
commands/scripts/test-integration.sh
```

**Expected output:**
```
Total Tests: 31
Passed: 31
Failed: 0
✓ ALL TESTS PASSED!
```

---

## How It Saves Tokens

### Traditional Approach (No Optimization)

```
User: /prompt "Compare apples and oranges"
↓
LLM orchestration (300 tokens)
↓
LLM template generation (1500 tokens)
↓
LLM executes task (1000 tokens)
= TOTAL: 2800 tokens
```

### Optimized Approach (This System)

```
User: /prompt "Compare apples and oranges"
↓
Bash script orchestration (0 tokens)
↓
Bash template selection (0 tokens)
↓
Bash variable substitution (0 tokens)
↓
LLM executes task (1000 tokens)
= TOTAL: 1000 tokens

SAVINGS: 1800 tokens (64% reduction)
```

---

## Common Patterns

### Pattern 1: Quick Comparisons
```bash
/prompt "Compare REST and GraphQL APIs"
```
→ Uses simple-classification template (3 variables)

### Pattern 2: Document Analysis
```bash
/prompt "What are the main points in this article? [paste article]"
```
→ Uses document-qa template (2 variables)

### Pattern 3: Code Tasks
```bash
/prompt "Refactor this function to be more modular: [paste code]"
```
→ Uses code-refactoring template (2 variables)

### Pattern 4: Interactive Agents
```bash
/prompt "Create a SQL tutor that uses the Socratic method"
```
→ Uses interactive-dialogue template (4 variables)

---

## Troubleshooting

### Issue: "Permission denied" when running scripts

**Solution:**
```bash
chmod +x commands/scripts/*.sh
```

### Issue: Template always returns "custom"

**Solution:** Check debug output to see confidence scores
```bash
DEBUG=1 commands/scripts/template-selector.sh "your task here"
```

If confidence is consistently low, the keywords might need adjustment. See [Template Authoring Guide](template-authoring.md).

### Issue: "Template not found" error

**Solution:** Verify templates exist
```bash
ls templates/
# Should show: simple-classification.md, document-qa.md, etc.
```

### Issue: Tests failing

**Solution:** Run validation first
```bash
commands/scripts/validate-templates.sh
# Fix any reported issues before running tests
```

---

## Next Steps

### Learn More

- **Understand the system:** Read [Architecture Overview](architecture-overview.md)
- **See practical examples:** Browse [Examples](examples.md)
- **Create your own templates:** Follow [Template Authoring Guide](template-authoring.md)
- **Modify scripts:** See [Script Development Guide](script-development.md)

### Advanced Usage

- **Adjust confidence threshold:** See design-decisions.md:AD-004
- **Add new templates:** See template-authoring.md
- **Monitor token savings:** See infrastructure.md:Monitoring
- **Integrate with CI/CD:** See infrastructure.md:Continuous Integration

### Contributing

Want to improve the system? See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Pull request process
- Code review guidelines
- Testing requirements

---

## Quick Reference Card

### Commands
```bash
# Execute optimized prompt
/prompt "task description"

# Generate prompt without executing
/prompt "task description" --return-only

# Create optimized prompt
/create-prompt "task description"
```

### Validation
```bash
# Validate templates
commands/scripts/validate-templates.sh

# Run tests
commands/scripts/test-integration.sh

# Debug classification
DEBUG=1 commands/scripts/template-selector.sh "task"
```

### File Locations
```
commands/prompt.md              # /prompt command
commands/create-prompt.md       # /create-prompt command
commands/scripts/               # Processing scripts
templates/                      # Template library
docs/                                   # Documentation
```

---

## Summary

**You've learned:**
- ✓ How to use `/prompt` and `/create-prompt` commands
- ✓ How the system saves 40-60% in token consumption
- ✓ Which templates exist and when they're used
- ✓ How to validate and test the system
- ✓ Where to go for advanced usage

**Time invested:** 5 minutes
**Token savings unlocked:** 40-60% on all future tasks

Happy optimizing! 🎉
