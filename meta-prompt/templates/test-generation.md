---
template_name: test-generation
category: testing
keywords: [test, spec, testing, unittest, coverage, jest, pytest, junit, mocha, test case, test suite, edge case]
complexity: intermediate
variables: [CODE_TO_TEST]
optional_variables: [TEST_FRAMEWORK, TEST_SCOPE]
version: 1.2
description: Generate comprehensive test cases
variable_descriptions:
  CODE_TO_TEST: "Code needing test coverage (function, class, module)"
  TEST_FRAMEWORK: "Testing framework (Jest, pytest, JUnit, etc.). Default: inferred"
  TEST_SCOPE: "What to test (edge cases, happy path, integration). Default: comprehensive"
---

Generate tests for:

<code>{$CODE_TO_TEST}</code>
<framework>{$TEST_FRAMEWORK:inferred from project}</framework>
<scope>{$TEST_SCOPE:comprehensive coverage}</scope>

## Process

1. **Analyze code:** inputs, outputs, side effects, dependencies, edge cases

2. **Plan coverage:**
   - Happy path (normal operation)
   - Edge cases (null, empty, boundaries)
   - Error conditions (invalid inputs, exceptions)
   - Integration points (mock external dependencies)

3. **Generate tests** following:
   - Clear names: `should return X when Y`
   - AAA pattern: Arrange, Act, Assert
   - One assertion per test
   - Test isolation (no shared state)

## Output

Complete, runnable test code with:
- Describe/context blocks for organization
- Mocks for external dependencies
- Setup/teardown where needed
