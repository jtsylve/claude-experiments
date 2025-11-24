# Testing Guide for Meta-Prompt Infrastructure

This guide covers both automated and manual testing for the meta-prompt plugin.

## Automated Validation Tests

Run the automated test suite to verify all configurations and script functionality:

```bash
./meta-prompt/commands/scripts/test-validation.sh
```

### What the automated tests verify:

1. **Environment Setup** - CLAUDE_PLUGIN_ROOT is set correctly
2. **Script Accessibility** - Handler scripts exist and are executable
3. **Directory Access** - Templates directories are readable
4. **Bash Tool Execution** - Scripts execute correctly with valid inputs
5. **Read Tool Access** - Template files can be read
6. **Security Path Restrictions** - Path patterns match allowed patterns
7. **Configuration Verification** - Frontmatter has correct allowed-tools syntax

**Expected Result:** All tests should pass with green checkmarks.

---

## Manual Integration Tests

These tests validate that the tool restrictions work correctly within Claude Code's permission system.

### Test 1: `/prompt` Command - Return Only Mode

**Purpose:** Verify the prompt command can generate optimized prompts

**Steps:**
1. Run: `/prompt "refactor my code" --return-only`
2. Verify the command executes without permission errors
3. Verify output includes an optimized prompt
4. Verify the prompt is optimized but NOT executed (--return-only flag)

**Expected Behavior:**
- ✅ Command executes successfully
- ✅ No permission denied errors
- ✅ Returns optimized prompt without executing

---

### Test 2: `/prompt` Command - Direct Execution

**Purpose:** Verify the prompt command can execute tasks

**Steps:**
1. Run: `/prompt --compare "Compare TypeScript and Flow type systems"`
2. Verify the command:
   - Selects appropriate template (code-comparison)
   - Generates optimized prompt
   - Executes the task
3. Verify no permission errors occur

**Expected Behavior:**
- ✅ Template selected correctly
- ✅ Task executes successfully
- ✅ No permission denied errors
- ✅ Returns task results

---

### Test 3: Template Selection Agent

**Purpose:** Verify the template-selector agent works correctly

**Steps:**
1. Use the system to classify various tasks
2. Verify correct template selection for:
   - Code review tasks → code-review
   - Testing tasks → test-generation
   - Documentation tasks → documentation-generator
3. Verify no permission errors

**Expected Behavior:**
- ✅ Template classification accuracy > 90%
- ✅ No permission denied errors
- ✅ Appropriate template selected for each task type

---

### Test 4: Security - Unauthorized Access Prevention

**Purpose:** Verify restricted paths prevent access to unauthorized files/commands

**Test 4a: Unauthorized Bash Command**
1. Try to execute a command other than the allowed scripts
2. Expected: Permission denied error

**Test 4b: Unauthorized File Read**
1. Try to read a file outside `templates/` or `guides/`
2. Expected: Permission denied error

**Test 4c: Unauthorized Script Path**
1. Try to execute a script outside `commands/scripts/`
2. Expected: Permission denied error

**Expected Behavior:**
- ✅ All unauthorized access attempts are blocked
- ✅ Clear permission error messages are shown

---

## Test Checklist

- [x] Verify `/prompt` command works in return-only mode
- [x] Verify `/prompt` command can execute tasks
- [x] Verify template selection works correctly
- [x] Confirm security restrictions prevent unauthorized access

---

## Cross-Platform Testing

### macOS/Linux
```bash
export CLAUDE_PLUGIN_ROOT="/Users/joe/src/claude-experiments/meta-prompt"
./meta-prompt/commands/scripts/test-validation.sh
```

### Windows (if supported in future)
```powershell
$env:CLAUDE_PLUGIN_ROOT="C:\Users\joe\src\claude-experiments\meta-prompt"
bash ./meta-prompt/commands/scripts/test-validation.sh
```

**Note:** Windows path normalization for `CLAUDE_PLUGIN_ROOT` is a known issue (see GitHub #11984). A temporary workaround has been implemented using hardcoded paths - see docs/infrastructure.md for details. Test scripts automatically derive the plugin root from their location, so manual setting of CLAUDE_PLUGIN_ROOT is optional for testing.

---

## Troubleshooting

### Test Failures

**Issue:** Script not executable
```bash
chmod +x meta-prompt/commands/scripts/*.sh
```

**Issue:** CLAUDE_PLUGIN_ROOT not set
```bash
export CLAUDE_PLUGIN_ROOT="$(pwd)/meta-prompt"
```

**Issue:** Permission denied in integration tests
- Verify the frontmatter syntax in `.md` files matches the expected format
- Ensure `${CLAUDE_PLUGIN_ROOT}` is expanded correctly
- Check that glob patterns (`*`, `**`) are correctly specified

### Common Issues

1. **Path separator issues on Windows** - Use forward slashes in patterns even on Windows
2. **Environment variable not set** - Ensure CLAUDE_PLUGIN_ROOT is set before running tests
3. **Script permissions** - All `.sh` files must have execute permissions

---

## Success Criteria

All tests pass when:

1. ✅ Automated test suite shows all tests passing
2. ✅ All manual integration tests complete without permission errors
3. ✅ Unauthorized access attempts are properly blocked
4. ✅ All scripts execute with correct outputs
5. ✅ Template files are accessible as expected

---

## CI/CD Integration (Future)

Consider adding the automated test suite to CI/CD:

```yaml
# Example GitHub Actions workflow
- name: Run validation tests
  run: |
    export CLAUDE_PLUGIN_ROOT="${{ github.workspace }}/meta-prompt"
    ./meta-prompt/commands/scripts/test-validation.sh
```

---

## Reporting Issues

If tests fail or you encounter permission issues:

1. Run the automated test suite and capture output
2. Note which specific test failed
3. Check CLAUDE_PLUGIN_ROOT is set correctly
4. Verify file permissions and paths
5. Report with full error messages and environment details
