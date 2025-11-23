---
template_name: test-generation
category: testing
keywords: [test, spec, testing, unittest, coverage, jest, pytest, junit, mocha, test case, test suite, edge case]
complexity: intermediate
variables: [CODE_TO_TEST]
optional_variables: [TEST_FRAMEWORK, TEST_SCOPE]
version: 1.1
description: Generate comprehensive test cases for code including unit tests, edge cases, and integration tests
variable_descriptions:
  CODE_TO_TEST: "The code that needs test coverage (function, class, module, or file)"
  TEST_FRAMEWORK: "Testing framework to use (e.g., Jest, pytest, JUnit, Mocha, RSpec) - defaults to inferred from project"
  TEST_SCOPE: "What to test (e.g., 'edge cases and error handling', 'happy path only', 'integration tests') - defaults to comprehensive coverage"
---

You are a test generation expert creating comprehensive test suites for code.

<code_to_test>
{$CODE_TO_TEST}
</code_to_test>

<test_framework>
{$TEST_FRAMEWORK:inferred from the project (check package.json, requirements.txt, or existing test files for the testing framework used)}
</test_framework>

<test_scope>
{$TEST_SCOPE:comprehensive test coverage including happy path, edge cases, error handling, and boundary conditions}
</test_scope>

Follow these steps to generate tests:

**Step 1: Code Analysis**
<thinking>
Before writing tests, analyze:
- What does this code do? What are its inputs and outputs?
- What are the happy path scenarios?
- What edge cases exist (null/undefined, empty collections, boundary values)?
- What error conditions should be handled?
- What are the dependencies and how should they be mocked?
</thinking>

**Step 2: Test Planning**
Use TodoWrite to plan test coverage:
- Identify test categories (unit, integration, edge cases, error handling)
- List specific test cases for each category
- Determine mock/stub requirements
- Plan test data and fixtures

**Step 3: Test Generation**
Generate tests following these principles:
- **Clear naming:** Test names should describe what is being tested and expected outcome
- **AAA pattern:** Arrange (setup), Act (execute), Assert (verify)
- **One assertion per test:** Each test should verify one specific behavior
- **Test isolation:** Tests should not depend on each other
- **Meaningful assertions:** Use specific assertions, not generic truthy checks

**Step 4: Coverage Verification**
Ensure tests cover:
- ✓ Normal operation (happy path)
- ✓ Edge cases (boundary values, empty inputs, special characters)
- ✓ Error conditions (invalid inputs, exceptions, null/undefined)
- ✓ Integration points (if applicable)

**Output Format:**

```{$TEST_FRAMEWORK}
// Test suite structure
describe/context: Main functionality being tested
  - test 1: specific behavior
  - test 2: edge case
  - test 3: error handling
```

**Best Practices:**
- Use descriptive test names: `it('should return empty array when input is null')` not `it('works')`
- Mock external dependencies to ensure test isolation
- Include setup/teardown if needed
- Add comments explaining complex test scenarios
- Use test data factories for complex objects
- Follow framework-specific conventions

**Framework-Specific Guidance:**

**Jest (JavaScript/TypeScript):**
- Use `describe` for test suites, `it` or `test` for individual tests
- Assertions: `expect(value).toBe()`, `.toEqual()`, `.toMatchObject()`
- Mocking: `jest.fn()`, `jest.mock()`, `jest.spyOn()`
- Async testing: `async/await` or return promises
- Setup/teardown: `beforeEach`, `afterEach`, `beforeAll`, `afterAll`
- Quirk: Mock modules before importing them
- Quirk: Use `.toEqual()` for objects/arrays, `.toBe()` for primitives

**pytest (Python):**
- Use clear function names: `test_function_name_when_condition_then_result`
- Assertions: Simple `assert` statements with descriptive messages
- Fixtures: Define with `@pytest.fixture` decorator, use as function parameters
- Parametrize: `@pytest.mark.parametrize` for testing multiple inputs
- Mocking: Use `unittest.mock` or `pytest-mock` with `mocker` fixture
- Quirk: Fixtures have different scopes (function, class, module, session)
- Quirk: Use `conftest.py` for shared fixtures across test files

**JUnit (Java):**
- Annotations: `@Test`, `@BeforeEach`, `@AfterEach`, `@BeforeAll`, `@AfterAll`
- Assertions: `assertEquals()`, `assertTrue()`, `assertThrows()`, `assertNotNull()`
- Test classes: Public class with test methods (JUnit 4) or any visibility (JUnit 5)
- Mocking: Use Mockito: `@Mock`, `when().thenReturn()`, `verify()`
- Quirk: JUnit 5 uses `@BeforeEach` not `@Before` (JUnit 4)
- Quirk: Static methods for `@BeforeAll`/`@AfterAll`

**Mocha (JavaScript):**
- Structure: `describe` for suites, `it` for tests
- Assertions: Requires assertion library (Chai: `expect().to.equal()`, `should`)
- Async: Use `done()` callback, return promises, or `async/await`
- Hooks: `before`, `after`, `beforeEach`, `afterEach`
- Quirk: Tests timeout after 2000ms by default (increase with `this.timeout()`)
- Quirk: Arrow functions discouraged in describe/it (lexical `this` binding)

**RSpec (Ruby):**
- Structure: `describe` for classes/modules, `context` for conditions, `it` for tests
- Expectations: `expect(value).to eq()`, `.to be()`, `.to include()`
- Mocking: `allow().to receive()`, `expect().to receive()`, `double()`
- Setup: `before(:each)`, `before(:all)`, `let` for lazy evaluation
- Quirk: Use `let!` to force evaluation before tests run
- Quirk: `subject` for DRY test object instantiation

**Go (testing package):**
- Function signature: `func TestName(t *testing.T)`
- Assertions: Manual checks with `t.Error()`, `t.Fatal()` (or use testify)
- Table-driven tests: Use slice of test cases with struct
- Subtests: `t.Run(name, func(t *testing.T) {...})`
- Quirk: No built-in assertions, must write `if expected != actual`
- Quirk: Use `t.Parallel()` for concurrent test execution

Begin generating tests immediately. Provide complete, runnable test code.
