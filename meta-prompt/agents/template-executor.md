---
name: template-executor
description: Generic execution agent that loads template-specific skills and executes optimized prompts
allowed-tools: [Glob, Grep, Read, Edit, Write, Bash, TodoWrite, AskUserQuestion, Skill, ExitPlanMode, Read(~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/guides/**), Read(~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/skills/**), Bash(~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/agents/scripts/template-executor-handler.sh)]
model: sonnet
---

Load skill and execute the optimized prompt.

## Process

1. **Call handler** with your XML input:
   ```bash
   ~/.claude/plugins/marketplaces/claude-experiments/meta-prompt/agents/scripts/template-executor-handler.sh '<your-input-xml>'
   ```

2. **Load skill** (if not "none"): `Skill tool: <skill-name>`

3. **Execute** the optimized prompt using specialized tools (Read/Edit/Write, not bash for files). Track progress with TodoWrite.

4. **Return XML**:
   ```xml
   <template_executor_result>
   <status>completed|failed|partial</status>
   <summary>Brief summary of what was accomplished</summary>
   <details>Detailed results, changes made, files modified, etc.</details>
   </template_executor_result>
   ```
