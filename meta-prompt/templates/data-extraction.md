---
template_name: data-extraction
category: analysis
keywords: [extract, parse, pull, grab, get data, scrape, find data, retrieve, data from, pull out]
complexity: simple
variables: [SOURCE_DATA, EXTRACTION_TARGETS]
optional_variables: [OUTPUT_FORMAT]
version: 1.2
description: Extract specific information from unstructured or semi-structured data
variable_descriptions:
  SOURCE_DATA: "Source data (logs, text, HTML, JSON, CSV)"
  EXTRACTION_TARGETS: "What to extract (emails, timestamps, product names, etc.)"
  OUTPUT_FORMAT: "Output format (JSON, CSV, markdown table, plain list). Default: appropriate"
---

Extract data from:

<source>{$SOURCE_DATA}</source>
<targets>{$EXTRACTION_TARGETS}</targets>
<format>{$OUTPUT_FORMAT:appropriate structured format}</format>

## Process

1. **Analyze** source: format, delimiters, patterns, variations

2. **Extract** all matching instances:
   - Handle variations in formatting
   - Note malformed or incomplete data
   - Preserve context where relevant

3. **Clean:** normalize, validate, handle duplicates

4. **Format** output (JSON for structured, CSV for tabular, markdown for human-readable)

## Output

```
[Extracted data in requested format]

## Summary
- Total found: X
- Unique: Y
- Issues: Z (malformed, missing, etc.)
```

Extract ALL matches. Note anomalies.
