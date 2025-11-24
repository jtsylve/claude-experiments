# Data Extraction

Extract specific information from unstructured/semi-structured data with completeness and accuracy.

## Common Patterns

| Type | Pattern | Validation |
|------|---------|------------|
| Email | `user@domain.ext` | Has `@` and `.` after @ |
| URL | `http(s)://domain...` | Valid protocol and domain |
| Date | ISO, US, EU, timestamp | Valid ranges (month 1-12) |
| Phone | Various formats | 7-15 digits |
| IP | IPv4: `x.x.x.x`, IPv6 | Octets 0-255 |
| Key-Value | `key=value`, `key: value` | Handle quoted/nested |

## Process

1. **Analyze:** Format, delimiters, variations, headers to skip
2. **Extract:** Match all instances, capture context, handle partial matches
3. **Clean:** Trim, normalize (dates to ISO, phones to digits), validate
4. **Format:** Consistent fields, proper escaping, sort/dedupe if needed

## Output Formats

**JSON:** `{"results": [...], "summary": {"total": N, "unique": N}}`

**CSV:** Headers + rows

**Markdown:** Table with headers

**Plain:** Bullet list

## Principles

- **Complete:** Extract ALL matches, don't stop early
- **Accurate:** Preserve exact values, maintain case
- **Handle edge cases:** Missing → null, malformed → flag, duplicates → note

## Output Structure

```
[Extracted data]

## Summary
- Total: X
- Unique: Y
- Issues: Z

## Notes
- Line 42: Partial match "user@" (missing domain)
```
