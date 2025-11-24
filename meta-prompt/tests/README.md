# Meta-Prompt Test Suite

This directory contains the test suite for the meta-prompt plugin, updated for the new agent-based architecture.

## Test Files

### Unit Tests (Handler Scripts)

These test individual handler scripts directly via bash:

- **`test-template-selector-handler.sh`** - Tests template classification logic
  - Classification accuracy across all template types
  - Confidence calculation (high/borderline/low)
  - Edge cases and special characters
  - ~25 tests covering classification scenarios

- **`test-prompt-optimizer-handler.sh`** - Tests template loading and variable extraction
  - Template loading for all template types
  - Skill mapping (template → skill)
  - Variable extraction instructions
  - Execution mode handling (plan/direct)
  - Error handling for missing/invalid templates
  - ~15 tests covering template processing

- **`test-prompt-handler.sh`** - Tests state machine orchestration
  - Initial state handling (with/without template flags)
  - Template auto-selection flow
  - Explicit template specification
  - Flag parsing (--code, --review, --plan, --return-only, etc.)
  - State transitions (initial → selector → optimizer → executor)
  - Special character handling
  - ~30 tests covering state machine logic

### Integration Tests

- **`test-integration.sh`** - Tests file structure and basic integration
  - Verifies all required files exist and are executable
  - Validates templates
  - Tests agent definitions
  - Tests skills
  - Basic handler functionality
  - ~50 tests covering installation verification

### Validation Tests

- **`test-validation.sh`** - Tests tool permission restrictions (requires Claude Code environment)
- **`validate-templates.sh`** - Validates template file structure and variables
- **`verify-documentation-counts.sh`** - Verifies documentation consistency

### Test Runner

- **`run-all-tests.sh`** - Runs all test suites and provides a summary

## Running Tests

### Run All Tests

```bash
./tests/run-all-tests.sh
```

### Run Individual Test Suites

```bash
# Integration tests (file structure, installation)
./tests/test-integration.sh

# State machine tests
./tests/test-prompt-handler.sh

# Classification tests
./tests/test-template-selector-handler.sh

# Template processing tests
./tests/test-prompt-optimizer-handler.sh
```

### Run from Plugin Root

```bash
# Set environment variable
export CLAUDE_PLUGIN_ROOT=/path/to/meta-prompt

# Run tests
./tests/run-all-tests.sh
```

## Test Architecture

The new test suite matches the new agent-based architecture:

### Architecture
```
Handler scripts called by agents:
- XML input → handler.sh → instructions output
- Handlers are implementation details, tested via bash
```

**Test Files:**
- `test-template-selector-handler.sh` - Tests classification handler
- `test-prompt-optimizer-handler.sh` - Tests optimizer handler
- `test-prompt-handler.sh` - Tests state machine handler
- `test-integration.sh` - Integration tests

## Test Coverage

| Component | Test File | Coverage |
|-----------|-----------|----------|
| Template classification | test-template-selector-handler.sh | Classification logic, confidence calculation |
| Template processing | test-prompt-optimizer-handler.sh | Template loading, variable extraction |
| State machine | test-prompt-handler.sh | State transitions, flag parsing |
| File structure | test-integration.sh | Installation verification |
| Templates | validate-templates.sh | Template validation |

## Adding New Tests

### Adding Tests to Existing Suite

Edit the appropriate test file and add new test cases using the `run_test` helper:

```bash
run_test "Test description" \
    "command or expression to test" \
    "expected pattern in output"
```

### Creating a New Test Suite

1. Create a new file: `test-<component>.sh`
2. Follow the structure of existing test files
3. Make it executable: `chmod +x test-<component>.sh`
4. Add it to `run-all-tests.sh`

## Test Helpers

All test files include standard helpers:

- `run_test(name, command)` - Run a test expecting success
- `run_test_with_output(name, command, pattern)` - Run test and check output
- `run_error_test(name, command, error_pattern)` - Run test expecting error
- Color output: `GREEN`, `RED`, `YELLOW`, `BLUE`, `NC`

## CI/CD Integration

To run tests in CI:

```bash
export CLAUDE_PLUGIN_ROOT=$PWD
./tests/run-all-tests.sh
```

Expected exit codes:
- `0` - All tests passed
- `1` - One or more tests failed

## Troubleshooting

### Tests Fail with "command not found"

Ensure `CLAUDE_PLUGIN_ROOT` is set:
```bash
export CLAUDE_PLUGIN_ROOT=/path/to/meta-prompt
```

### Handler Scripts Not Found

Verify file structure:
```bash
ls -la commands/scripts/prompt-handler.sh
ls -la agents/scripts/*-handler.sh
ls -la scripts/common.sh
```

### Tests Pass Locally but Fail in CI

Check file permissions:
```bash
chmod +x commands/scripts/*.sh
chmod +x agents/scripts/*.sh
chmod +x tests/*.sh
```

## Handler Testing

The handlers expect XML input via stdin, not command-line arguments. See existing test files for examples of how to test them.
