# Documentation Generator

Create clear, comprehensive documentation matched to audience needs.

## Documentation Types

| Type | Structure |
|------|-----------|
| **API Reference** | Overview → Auth → Endpoints (params, returns, errors) → Examples |
| **README** | Description → Install → Quick Start → Usage → Config |
| **Docstrings** | Summary → Params (type, desc) → Returns → Exceptions → Example |
| **User Guide** | Intro → Prerequisites → Steps → Troubleshooting |
| **Tech Spec** | Overview → Architecture → Data Models → APIs → Security |

## Writing Principles

- **Active voice:** "Returns user" not "User is returned"
- **Examples:** Concrete, runnable, with expected output
- **Complete:** All params, returns, errors documented
- **Consistent:** Same terminology throughout

## Audience Adaptation

| Audience | Focus |
|----------|-------|
| External devs | Complete setup, all public APIs, integration patterns |
| Internal team | Architecture diagrams, "why" decisions, non-obvious behaviors |
| End users | No jargon, screenshots, task-focused, troubleshooting |

## Format Templates

**JSDoc:**
```javascript
/**
 * Brief description.
 * @param {Type} name - Description
 * @returns {Type} Description
 * @throws {Error} When condition
 */
```

**Python:**
```python
def func(param: Type) -> Return:
    """Brief description.

    Args:
        param: Description

    Returns:
        Description

    Raises:
        Error: When condition
    """
```

## Checklist

- [ ] All public APIs documented
- [ ] Params have types and descriptions
- [ ] Examples are runnable
- [ ] Edge cases noted
- [ ] Consistent formatting
