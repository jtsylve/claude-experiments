---
template_name: custom
category: fallback
keywords: []
complexity: variable
variables: [TASK_DESCRIPTION]
version: 1.0
description: Fallback to LLM-based prompt generation for novel or complex tasks
---

FALLBACK MODE: This task requires custom prompt engineering.

<task>
{$TASK_DESCRIPTION}
</task>

This task doesn't match a specialized template. Generate an optimized prompt using prompt engineering best practices:

1. Understand the task requirements
2. Structure the prompt with clear instructions
3. Include relevant context and constraints
4. Define expected output format

Return the optimized prompt to the user.
