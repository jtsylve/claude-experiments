# Testing Guide for Meta-Prompt Tool Restrictions

This guide covers both automated and manual testing for the restricted tool permissions implemented in PR #13.

## Automated Validation Tests

Run the automated test suite to verify all configurations and script functionality:

```bash
./meta-prompt/commands/scripts/test-validation.sh
```

### What the automated tests verify:

1. **Environment Setup** - CLAUDE_PLUGIN_ROOT is set correctly
2. **Script Accessibility** - All three bash scripts exist and are executable
3. **Directory Access** - Templates and guides directories are readable
4. **Bash Tool Execution** - All three scripts execute correctly with valid inputs
5. **Read Tool Access** - Template and guide files can be read
6. **Security Path Restrictions** - Path patterns match allowed patterns
7. **Configuration Verification** - Frontmatter has correct allowed-tools syntax

**Expected Result:** All 25 tests should pass with green checkmarks.

---

## Manual Integration Tests

These tests validate that the tool restrictions work correctly within Claude Code's permission system.

### Test 1: `/meta-prompt:prompt` Command

**Purpose:** Verify the prompt command can execute prompt-handler.sh

**Steps:**
1. Run: `/meta-prompt:prompt "refactor my code" --return-only`
2. Verify the command executes without permission errors
3. Verify output includes instructions to use the Task tool
4. Verify the prompt is optimized but NOT executed (--return-only flag)

**Expected Behavior:**
- ✅ Bash tool successfully executes `prompt-handler.sh`
- ✅ No permission denied errors
- ✅ Output contains "DO NOT execute - just return the prompt"

---

### Test 2: `/meta-prompt:create-prompt` Command

**Purpose:** Verify create-prompt can access template scripts and files

**Steps:**
1. Run: `/meta-prompt:create-prompt "write a code review assistant"`
2. Verify the command can:
   - Execute `template-selector.sh` (should select "code-review" template)
   - Execute `template-processor.sh`
   - Read template files from `templates/`
   - Read guide files from `guides/`
3. Verify no permission errors occur

**Expected Behavior:**
- ✅ Bash tool executes both template-selector.sh and template-processor.sh
- ✅ Read tool accesses template files (e.g., code-review.md)
- ✅ Read tool accesses guide files (e.g., engineering-guide.md)
- ✅ No permission denied errors
- ✅ Returns a properly formatted prompt based on the template

---

### Test 3: Prompt Optimizer Agent

**Purpose:** Verify the prompt-optimizer agent can call `/meta-prompt:create-prompt`

**Steps:**
1. Launch the prompt-optimizer agent:
   ```
   Use Task tool with subagent_type="meta-prompt:prompt-optimizer"
   ```
2. In the agent, request: "Create a prompt for data extraction"
3. Verify the agent successfully calls `/meta-prompt:create-prompt`
4. Verify no permission errors

**Expected Behavior:**
- ✅ Agent can use SlashCommand tool with `/meta-prompt:create-prompt:*`
- ✅ No permission denied errors
- ✅ Successfully generates optimized prompt

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

## Test Checklist from PR #13

- [x] Verify prompt-optimizer agent can still call `/meta-prompt:create-prompt` commands
- [x] Verify create-prompt command can access template scripts and files
- [x] Verify prompt command can execute prompt-handler.sh
- [x] Confirm restricted paths prevent unauthorized access to other files/commands

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

1. ✅ Automated test suite shows 25/25 tests passing
2. ✅ All manual integration tests complete without permission errors
3. ✅ Unauthorized access attempts are properly blocked
4. ✅ All scripts execute with correct outputs
5. ✅ Template and guide files are accessible as expected

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
