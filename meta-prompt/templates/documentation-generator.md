---
template_name: documentation-generator
category: generation
keywords: [document, documentation, docs, readme, api doc, docstring, comment, guide, reference, explain code]
complexity: intermediate
variables: [CODE_OR_CONTENT]
optional_variables: [DOC_TYPE, AUDIENCE]
version: 1.2
description: Generate documentation from code or technical content
variable_descriptions:
  CODE_OR_CONTENT: "Code/content to document (functions, classes, APIs, modules)"
  DOC_TYPE: "Type of docs (API reference, README, docstrings, user guide, tech spec). Default: appropriate format"
  AUDIENCE: "Target audience (developers, internal team, end users). Default: developers"
---

Create documentation for:

<content>{$CODE_OR_CONTENT}</content>
<type>{$DOC_TYPE:appropriate format for content}</type>
<audience>{$AUDIENCE:developers}</audience>

## Process

1. **Analyze:** purpose, key components, use cases, complexity

2. **Structure** based on type:
   - **API Reference:** overview, auth, endpoints/functions, params, returns, errors, examples
   - **README:** description, install, quick start, usage, config
   - **Docstrings:** summary, params with types, returns, exceptions, example
   - **User Guide:** intro, prerequisites, step-by-step, troubleshooting

3. **Write** with:
   - Active voice ("Returns" not "Is returned")
   - Concrete, runnable examples
   - All parameters and return values documented
   - Edge cases and errors noted

## Output

Documentation with clear headings, consistent formatting, code examples, and appropriate depth for audience.
