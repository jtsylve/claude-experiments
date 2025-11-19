# Migration and Upgrade Guide

Guide for upgrading the meta-prompt infrastructure between versions.

---

## Table of Contents

1. [Versioning Policy](#versioning-policy)
2. [Checking Current Version](#checking-current-version)
3. [Version 1.0 (Current)](#version-10-current)
4. [Future Migrations](#future-migrations)
5. [Breaking vs Non-Breaking Changes](#breaking-vs-non-breaking-changes)
6. [Rollback Procedures](#rollback-procedures)
7. [Compatibility Matrix](#compatibility-matrix)

---

## Versioning Policy

This project follows **Semantic Versioning (semver)** - `MAJOR.MINOR.PATCH`

### Version Numbers

**MAJOR version (X.0.0):** Breaking changes
- Template variable names changed
- Script interfaces modified
- Configuration format updated
- Requires manual migration

**MINOR version (1.X.0):** New features, backwards compatible
- New templates added
- New keywords added to existing templates
- Enhanced functionality
- No migration needed

**PATCH version (1.0.X):** Bug fixes
- Error corrections
- Documentation updates
- Performance improvements
- No migration needed

### Version Locations

**System version:** README.md:170 ("Current Version: 1.0")

**Template versions:** Individual template frontmatter
```yaml
---
template_name: simple-classification
version: 1.0
---
```

**Script versions:** Documented in commit history (no version field in files)

---

## Checking Current Version

### Check System Version

```bash
# View README version
grep "Current Version" README.md

# Expected: Current Version: 1.0
```

### Check Template Versions

```bash
# Check specific template
grep "version:" templates/simple-classification.md

# Check all templates
for template in templates/*.md; do
    echo "$(basename $template): $(grep 'version:' $template)"
done
```

### Check Script Versions

```bash
# View git history for scripts
git log --oneline -- commands/scripts/

# View specific script changes
git log -p commands/scripts/template-selector.sh
```

---

## Version 1.0 (Current)

### Initial Release Features

**Released:** 2025-11-18
**Status:** Production Ready

**Includes:**
- 6 templates (simple-classification, document-qa, code-refactoring, function-calling, interactive-dialogue, custom)
- 5 bash scripts (prompt-handler, template-selector, template-processor, validate-templates, test-integration)
- Classification system with 90%+ accuracy
- Comprehensive documentation suite
- Full test coverage (31 tests)

**Installation:**
```bash
# Clone repository
git clone <repository-url> meta-prompt
cd meta-prompt

# Make scripts executable
chmod +x commands/scripts/*.sh

# Validate
commands/scripts/validate-templates.sh
commands/scripts/test-integration.sh
```

**No migration needed** - this is the initial release

---

## Version 1.1 (Upcoming)

### Migrating from 1.0 to 1.1

**Released:** TBD
**Status:** In Development

### Breaking Changes

**1. Agent Reference Namespacing**
- **Old:** `subagent_type="prompt-optimizer"`
- **New:** `subagent_type="meta-prompt:prompt-optimizer"`
- **Reason:** Required by Claude Code plugin marketplace namespacing system
- **Migration Required:** Yes - Update all Task tool calls

**2. Model Reference Update**
- **Old:** `model: sonnet`
- **New:** `model: claude-sonnet-4-5-20250929`
- **Impact:** Commands and agents now use explicit model version
- **Migration Required:** No - handled automatically in plugin files

**3. Environment Variable Dependency**
- **New Requirement:** `${CLAUDE_PLUGIN_ROOT}` must be set
- **Impact:** Scripts will fail with clear error if not set
- **Migration Required:** No - environment variable is automatically provided by Claude Code

### Migration Steps

**1. Update Agent References**

If you have any custom scripts or commands that invoke the prompt-optimizer agent:

```bash
# OLD (will fail)
Task tool with subagent_type="prompt-optimizer"

# NEW (correct)
Task tool with subagent_type="meta-prompt:prompt-optimizer"
```

**2. Verify Environment**

The `${CLAUDE_PLUGIN_ROOT}` environment variable is automatically set by Claude Code when running commands. If you're testing scripts manually outside of Claude Code, set it manually:

```bash
export CLAUDE_PLUGIN_ROOT=/path/to/meta-prompt
./commands/scripts/template-processor.sh simple-classification ITEM1='test' ...
```

**Windows Path Handling:**

All scripts now include automatic path normalization for Windows environments. The shared `utils.sh` library handles:
- Converting backslashes to forward slashes
- Converting Windows drive letters (C: → /c/)
- Using `cygpath` when available (Git Bash, Cygwin)

This means you can set `CLAUDE_PLUGIN_ROOT` with Windows paths and they will be automatically converted:

```bash
# Windows Git Bash - both formats work
export CLAUDE_PLUGIN_ROOT='C:\Users\name\meta-prompt'  # Auto-converted to /c/Users/name/meta-prompt
export CLAUDE_PLUGIN_ROOT='/c/Users/name/meta-prompt'  # Already in correct format

# Windows WSL
export CLAUDE_PLUGIN_ROOT='/mnt/c/Users/name/meta-prompt'  # Works as-is
```

**3. Validate Migration**

```bash
# Run integration tests
cd meta-prompt
CLAUDE_PLUGIN_ROOT=$(pwd) commands/scripts/test-integration.sh

# Expected: All 38 tests pass
```

**4. Test Commands**

```bash
# Test /prompt command
/prompt "Refactor authentication module"

# Test /create-prompt command
/create-prompt "Compare two code implementations"
```

### Non-Breaking Changes

**Added:**
- MIT License with copyright notices
- Environment variable validation for improved error messages
- CHANGELOG.md for tracking version history
- Shared `utils.sh` library for cross-platform compatibility
- Windows path normalization (Git Bash, Cygwin support)

**Improved:**
- Scripts now provide clear error messages when `${CLAUDE_PLUGIN_ROOT}` is not set
- Automatic path conversion for Windows environments
- Documentation updated across all files
- Author information standardized
- Test suite expanded to include utility function tests and edge cases (38 total tests)

### Rollback from 1.1 to 1.0

If you encounter issues after upgrading:

```bash
# Revert to v1.0
git checkout v1.0

# Or revert specific files
git checkout v1.0 -- meta-prompt/
```

**Note:** After rolling back, agent references with `meta-prompt:` prefix will fail. Use `prompt-optimizer` instead.

---

## Future Migrations

This section will be updated as new versions are released.

### Example: Migrating from 1.0 to 2.0 (Future)

**Note:** This is a hypothetical example for illustration purposes.

**Breaking Changes:**
- Template variable naming convention changed
- Confidence threshold moved to configuration file
- New required field in YAML frontmatter

**Migration Steps:**

**1. Backup Current Version**
```bash
# Create backup branch
git checkout -b backup-v1.0

# Tag current state
git tag v1.0-backup
```

**2. Update Repository**
```bash
git checkout main
git pull origin main
git checkout v2.0  # Or latest release tag
```

**3. Update Templates** (if custom templates exist)
```bash
# Rename variables (example)
# OLD: {$INPUT_TEXT}
# NEW: {$TEXT_INPUT}

# Add new required field
# Add to frontmatter: migration_version: 2.0
```

**4. Update Configuration**
```bash
# Create config file (example)
cat > config.yml <<EOF
confidence_threshold: 70
classification_version: 2.0
EOF
```

**5. Validate Migration**
```bash
commands/scripts/validate-templates.sh
commands/scripts/test-integration.sh
```

**6. Test Manually**
```bash
/create-prompt "test task description"
# Verify correct template selection and processing
```

---

## Breaking vs Non-Breaking Changes

### Breaking Changes (Require Migration)

**Template Changes:**
- ❌ Variable renamed: `{$OLD_NAME}` → `{$NEW_NAME}`
- ❌ Variable removed: `{$REMOVED_VAR}`
- ❌ New required variable added
- ❌ Template file moved to different directory

**Script Changes:**
- ❌ Script renamed or moved
- ❌ Command-line argument format changed
- ❌ Output format changed
- ❌ Required bash version increased

**Configuration Changes:**
- ❌ settings.json structure changed
- ❌ Newrequired configuration file
- ❌ Permission model changed

### Non-Breaking Changes (No Migration)

**Template Changes:**
- ✅ New optional variable added (with default)
- ✅ Template body improved (instructions clearer)
- ✅ Examples added or updated
- ✅ Keywords added (improves classification)

**Script Changes:**
- ✅ New optional flag added
- ✅ Performance improvements
- ✅ Bug fixes
- ✅ Better error messages

**Configuration Changes:**
- ✅ New optional setting added
- ✅ Default values updated

**Documentation:**
- ✅ All documentation updates are non-breaking

---

## Rollback Procedures

### Rollback to Previous Version

**If upgrade fails or causes issues:**

**1. Identify Target Version**
```bash
# List available versions
git tag

# View commits
git log --oneline
```

**2. Rollback Files**
```bash
# Option A: Revert to tag
git checkout v1.0

# Option B: Revert specific commit
git checkout <commit-hash>

# Option C: Create new branch from old version
git checkout -b rollback-to-v1.0 v1.0
```

**3. Restore Scripts**
```bash
# Make scripts executable again
chmod +x commands/scripts/*.sh
```

**4. Validate Rollback**
```bash
commands/scripts/validate-templates.sh
commands/scripts/test-integration.sh
```

**5. Test Functionality**
```bash
/create-prompt "test task"
# Verify system works as expected
```

### Rollback Individual Components

**Rollback single template:**
```bash
git checkout v1.0 -- templates/simple-classification.md
```

**Rollback single script:**
```bash
git checkout v1.0 -- commands/scripts/template-selector.sh
```

**Rollback configuration:**
```bash
git checkout v1.0 -- .claude-plugin/settings.json
```

### When to Rollback

**Immediate rollback (P0 - do immediately):**
- ❌ Error rate >10%
- ❌ Critical functionality broken
- ❌ Security vulnerability in new version
- ❌ Data corruption or loss

**Planned rollback (P1 - schedule within 24 hours):**
- ⚠️ Token reduction below 20% (significant regression)
- ⚠️ Classification accuracy <75%
- ⚠️ Performance >500ms (5x regression)
- ⚠️ Unresolvable bugs affecting 20%+ of use cases

**Consider staying on new version:**
- ✅ Minor issues that can be fixed quickly
- ✅ Issues affecting <5% of use cases
- ✅ Performance regression <50ms
- ✅ Workarounds available

---

## Compatibility Matrix

### Version Compatibility

| Component | 1.0 | 1.1 (future) | 2.0 (future) |
|-----------|-----|--------------|--------------|
| Bash 4.0+ | ✅ Required | ✅ Required | ⚠️ May require 4.2+ |
| Claude Code CLI | ✅ Latest | ✅ Latest | ✅ Latest |
| Git 2.0+ | ✅ Required | ✅ Required | ✅ Required |
| macOS | ✅ Supported | ✅ Supported | ✅ Supported |
| Linux | ✅ Supported | ✅ Supported | ✅ Supported |
| WSL | ✅ Supported | ✅ Supported | ✅ Supported |
| Windows Git Bash | ✅ Supported (v1.1+) | ✅ Supported | ✅ Supported |
| Windows Cygwin | ✅ Supported (v1.1+) | ✅ Supported | ✅ Supported |

### Template Version Compatibility

| Template Version | System Version | Status |
|------------------|----------------|--------|
| 1.0 | 1.0 | ✅ Fully compatible |
| 1.1 (future) | 1.0 | ⚠️ New features unavailable |
| 1.0 | 1.1 (future) | ✅ Backwards compatible |
| 2.0 (future) | 1.x | ❌ Breaking changes |
| 1.x | 2.0 (future) | ⚠️ May work with warnings |

### Cross-Version Template Mixing

**Can I use v1.0 and v2.0 templates together?**
- ✅ Yes, if template-processor supports both
- ⚠️ Check frontmatter for `min_version` field
- ❌ Not recommended for production

**Best practice:** Keep all templates on same major version

---

## Migration Checklist

### Pre-Migration

- [ ] Read release notes for new version
- [ ] Identify breaking changes
- [ ] Backup current version (`git tag backup`)
- [ ] Document custom modifications
- [ ] Test in non-production environment first

### Migration

- [ ] Update repository to new version
- [ ] Update custom templates (if needed)
- [ ] Update configuration files (if needed)
- [ ] Update permissions in settings.json (if needed)
- [ ] Make scripts executable: `chmod +x commands/scripts/*.sh`

### Post-Migration

- [ ] Run validation: `validate-templates.sh`
- [ ] Run tests: `test-integration.sh`
- [ ] Manual testing: `/create-prompt "test task"`
- [ ] Monitor error rates for 24-48 hours
- [ ] Update team documentation
- [ ] Train team on new features (if applicable)

### Rollback Plan

- [ ] Document rollback steps beforerecipe upgrading
- [ ] Keep backup branch available for 1 week
- [ ] Set rollback threshold criteria
- [ ] Assign rollback decision authority

---

## Migration Support

### Getting Help

**Before migrating:**
1. Read release notes thoroughly
2. Review breaking changes list
3. Check migration guide (this document)
4. Test in isolated environment

**During migration:**
1. Follow checklist step-by-step
2. Don't skip validation steps
3. Keep detailed notes of changes made

**After migration:**
1. Monitor system for 48 hours
2. Document any issues encountered
3. Share feedback with maintainers

### Reporting Migration Issues

**Create an issue with:**
- Source version (migrating from)
- Target version (migrating to)
- Steps taken
- Error messages or unexpected behavior
- Environment details (OS, bash version)

### Migration Timeline

**Recommended migration schedule:**
- **PATCH versions:** Migrate within 1 week
- **MINOR versions:** Migrate within 1 month
- **MAJOR versions:** Plan 2-4 weeks for migration

**Allow extra time for:**
- Custom template updates
- Team training
- Rollback contingency

---

## Best Practices

### Before Upgrading

1. **Test First:** Always test in non-production environment
2. **Read Changelog:** Understand what's changing
3. **Backup:** Create backups before upgrading
4. **Plan Downtime:** Schedule upgrades during low-usage periods

### During Upgrade

1. **Follow Steps:** Don't skip checklist items
2. **Validate Each Step:** Run tests after each major change
3. **Document:** Keep notes of custom modifications
4. **Stay Calm:** If something breaks, you have rollback plan

### After Upgrade

1. **Monitor:** Watch error rates and performance
2. **Gradual Rollout:** Consider A/B testing for major versions
3. **Gather Feedback:** Ask team about new version
4. **Keep Backup:** Maintain rollback capability for 1 week

---

## Deprecation Policy

### Feature Deprecation

**Warning Period:** Minimum 1 MINOR version before removal

**Example:**
- v1.1: Feature marked deprecated (warning in logs)
- v1.2: Feature still works (warning continues)
- v2.0: Feature removed (breaking change)

### Template Deprecation

**Low-Usage Templates** (<5% selection rate):
1. Mark as deprecated in docs
2. Keep functional for 2 MINOR versions
3. Remove in next MAJOR version
4. Merge functionality into related template

**Migration path provided:** Instructions for replacing deprecated template

---

## Frequently Asked Questions

**Q: How do I know if a new version has breaking changes?**
A: Check the MAJOR version number. If it changed (1.x → 2.x), there are breaking changes. Read release notes for details.

**Q: Can I skip versions (e.g., 1.0 → 1.5)?**
A: Yes for MINOR versions. For MAJOR versions, review all intermediate breaking changes.

**Q: What if I have custom templates?**
A: Custom templates may need updates for MAJOR versions. Check release notes for template format changes.

**Q: How long is each version supported?**
A: Latest MAJOR version + previous MAJOR version receive updates. Older versions are unsupported.

**Q: Can I stay on an old version?**
A: Yes, but you'll miss bug fixes, security updates, and new features. Migration is recommended.

---

**Document Version:** 1.0
**Last Updated:** 2025-11-18
**Next Review:** With each major release
