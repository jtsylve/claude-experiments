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

Use the /create-prompt command to generate an optimized prompt for this task. The /create-prompt command has comprehensive prompt engineering guidance and will create a tailored solution.

After generating the prompt with /create-prompt, return it to the user.
