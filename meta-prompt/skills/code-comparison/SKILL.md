# Code Comparison

Compare code implementations for equivalence, similarity, or differences with accurate classification.

## Comparison Dimensions

| Dimension | Question |
|-----------|----------|
| **Behavioral** | Same outputs for same inputs? Same side effects? |
| **Semantic** | Same intent/purpose? Same business logic? |
| **Syntactic** | Similar names, structure, formatting? |
| **Algorithmic** | Same approach? Same complexity (Big O)? |
| **Style** | Functional vs imperative? Recursive vs iterative? |

## Common Scenarios

| Scenario | Focus |
|----------|-------|
| Refactoring | Behavioral equivalence (must match) |
| Bug fix | Specific case differs, normal matches |
| API compat | Signature, returns, errors, side effects |
| Plagiarism | Structure, naming, logic patterns |

## Output Format

Start with **[YES]** or **[NO]** immediately.

Then provide justification with specific examples from both items.

## Analysis Checklist

- [ ] Inputs (same params, types?)
- [ ] Outputs (same returns?)
- [ ] Side effects (same state changes?)
- [ ] Error handling (same exceptions?)
- [ ] Edge cases (null, empty, boundary?)
- [ ] Performance (same complexity?)

## Example

```
[YES] Behaviorally equivalent

Both functions:
1. Return same results for all inputs
2. Handle null by returning empty array
3. Use same filtering logic

The refactoring improves readability (modern array methods) without changing behavior.
```

## Pitfalls

- Don't stop at surface differences (naming != different behavior)
- Check edge cases (factorial(-1) may differ)
- Consider context (Promise vs callback may be equivalent in modern Node)
