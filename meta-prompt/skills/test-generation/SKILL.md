# Test Generation

Create thorough, maintainable test suites covering happy paths, edge cases, and error handling.

## Test Design

| Principle | Application |
|-----------|-------------|
| Clear names | `should return X when Y` |
| AAA pattern | Arrange → Act → Assert |
| One behavior | Each test verifies one thing |
| Isolation | No shared state between tests |
| Specific asserts | `toEqual([1,2,3])` not `toBeTruthy()` |

## Coverage Checklist

- ✓ **Happy path:** Normal operation
- ✓ **Edge cases:** null, empty, 0, -1, MAX_INT, special chars
- ✓ **Errors:** Invalid inputs, missing params, exceptions
- ✓ **Integration:** External deps mocked

## Framework Quick Reference

| Framework | Structure | Assert | Mock |
|-----------|-----------|--------|------|
| **Jest** | `describe/it` | `expect().toBe/toEqual` | `jest.mock()` |
| **pytest** | `test_name()` | `assert x == y` | `mocker.patch()` |
| **JUnit** | `@Test` | `assertEquals()` | `@Mock` + Mockito |
| **Mocha** | `describe/it` | Chai `expect().to` | Sinon |
| **RSpec** | `describe/it` | `expect().to eq` | `allow().to receive` |
| **Go** | `TestName(t)` | `t.Error()` | Manual/testify |

## Mocking Strategy

**Mock:** API calls, DB, file system, time, external services

**Don't mock:** Simple data, pure functions, code under test

## Example Structure

```javascript
describe('UserService', () => {
  describe('createUser', () => {
    it('should create user with valid data', () => {
      // Arrange
      const data = { name: 'John', email: 'john@test.com' }
      // Act
      const user = createUser(data)
      // Assert
      expect(user.name).toBe('John')
    })

    it('should throw when email invalid', () => {
      expect(() => createUser({ email: 'bad' })).toThrow(ValidationError)
    })
  })
})
```
