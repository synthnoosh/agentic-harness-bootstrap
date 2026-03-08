# Phase 3: Verify

Validate all artifacts generated in Phase 2. Every generated or modified file must pass the checks below before the harness is considered complete.

---

## Step 1: Build Verification

If the repo has a build command (`build_cmd` from the repo profile):

1. Run the build command from the repository root.
2. Confirm it exits with code 0.
3. If it fails, determine whether the failure is pre-existing or caused by generated files.
   - Pre-existing: note in the report but do not block.
   - Caused by generation: fix the generated file and re-run.

If there is no build command (e.g., interpreted language with no compile step), skip and note as N/A.

---

## Step 2: Test Verification

If the repo has a test command (`test_cmd` from the repo profile):

1. Run the test command from the repository root.
2. Confirm all tests pass.
3. If tests fail, determine root cause:
   - Pre-existing failure: note in the report.
   - Caused by generation: this should not happen (generated files are documentation, not code), but investigate if it does.

If there is no test command, skip and note as N/A.

---

## Step 3: File Validation

For every file generated or modified in Phase 2:

### Markdown Files

- Confirm the file is valid Markdown (no unclosed code blocks, no broken link syntax).
- Confirm all headers follow a logical hierarchy (no skipped levels).
- Confirm code blocks specify a language where appropriate.

### YAML Files

- Parse the YAML and confirm it is syntactically valid.
- For CI workflow files, confirm required fields are present (e.g., `on`, `jobs` for GitHub Actions).

### Other Files

- Makefile: confirm tabs are used for indentation (not spaces).
- .editorconfig: confirm it follows INI-style syntax.
- JSON files: confirm valid JSON.

---

## Step 4: Cross-Reference Check

Validate internal consistency across generated files:

1. **Module names in ARCHITECTURE.md** — Every module listed in the module map must correspond to an actual directory in the repository.
2. **Commands in agent files** — Every build/test/lint command referenced in CLAUDE.md, AGENTS.md, and copilot-instructions.md must be the same and must be runnable.
3. **ADR references** — If ARCHITECTURE.md links to ADRs, confirm those ADR files exist.
4. **Path references** — Any file path mentioned in generated docs must exist in the repo.

---

## Step 5: Smoke Test

Read each generated agent instruction file and verify:

1. **CLAUDE.md**:
   - Contains build/test/lint commands.
   - Contains architecture summary.
   - Contains three-tier boundaries.
   - Contains harness evolution rules.

2. **AGENTS.md**:
   - Contains the same commands as CLAUDE.md.
   - Boundary rules use ALWAYS/ASK/NEVER prefixes.

3. **.github/copilot-instructions.md**:
   - Contains coding conventions.
   - Contains test expectations.

4. **ARCHITECTURE.md**:
   - Contains module map.
   - Contains dependency rules.
   - Greenfield: contains `<!-- EVOLVE -->` markers.

5. **docs/adr/001-adopt-harness-engineering.md**:
   - Follows the ADR template structure (Status, Context, Decision, Consequences).

---

## Step 6: Pre-commit Hook Verification

Verify the generated pre-commit configuration references valid commands:

1. Parse the pre-commit config file (`.lintstagedrc.json`, `.pre-commit-config.yaml`, or `grumphp.yml`).
2. Confirm each referenced command or hook is available in the project's toolchain.
3. Confirm the config file is syntactically valid.

---

## Step 7: Lint Config Verification

Verify the generated lint configuration is syntactically valid:

1. Parse the lint config file (`.eslintrc.json`, `ruff.toml`, `.golangci.yml`, or `phpstan.neon`) — confirm JSON/TOML/YAML parses without errors.
2. If the lint command is available, run `lint_cmd --help` or a dry-run to confirm the config is recognized.

---

## Step 8: Verification Script Smoke Test

Run the generated verification harness:

1. Execute `scripts/verify-harness.sh` from the repository root.
2. Confirm it exits with code 0.
3. If it fails, diagnose whether the failure is in the script itself or in a checked artifact, and fix accordingly.

---

## Step 9: Agent File Synchronization

Verify commands in all agent instruction files are consistent:

1. Extract build/test/lint commands from CLAUDE.md, AGENTS.md, and `.github/copilot-instructions.md`.
2. Confirm all three files reference the same commands with the same arguments.
3. Flag any discrepancies as errors.

---

## Step 10: Composite Command Check

Verify the composite `check` command works:

1. Run `make check` (or the equivalent task runner command — e.g., `npm run check`, `cargo make check`).
2. Confirm it runs format → lint → build → test in sequence and exits with code 0.
3. If the command fails, determine whether the failure is pre-existing or caused by generated configuration.

---

## Step 11: Monorepo Verification

If `monorepo` is true in the repo profile:

1. **Per-package profile consistency**: Verify each per-package agent file is consistent with the root-level agent files (shared conventions match, workspace commands are present at root).
2. **Cross-package dependency accuracy**: Verify cross-package dependencies documented in ARCHITECTURE.md match actual imports and workspace dependency declarations.
3. **Per-package commands**: Verify that commands listed in per-package agent files are runnable from the package directory.

---

## Step 12: Report

Produce a summary report with the following sections:

### Files Created

List every file that was created from scratch, with its path.

### Files Modified

List every file that existed and was merged/updated, noting what was added.

### Files Skipped

List any files that were skipped and why (e.g., "CI integration skipped — no CI provider configured").

### Issues Found

List any problems discovered during verification, their severity, and resolution:

- **Error**: Something that must be fixed (broken build, invalid YAML).
- **Warning**: Something that should be reviewed (potential drift, unusual pattern).
- **Info**: Informational note (pre-existing test failures, missing optional config).

### Recommendations

Suggest next steps for the engineer:

- Review three-tier boundaries and adjust to team preferences.
- Customize ARCHITECTURE.md with domain-specific details.
- Set up additional ADRs for pending architectural decisions.
- Run the full CI pipeline to confirm agent-lint job works.

---

## Verification Checklist

Use this checklist to confirm all verification steps are complete:

```markdown
## Verification Results

- [ ] **Build**: Runs successfully (or N/A)
- [ ] **Tests**: Pass (or N/A)
- [ ] **Markdown validity**: All .md files are well-formed
- [ ] **YAML validity**: All .yml/.yaml files parse correctly
- [ ] **Other file formats**: Makefile, .editorconfig, JSON all valid
- [ ] **Module cross-reference**: ARCHITECTURE.md modules match directories
- [ ] **Command consistency**: Same commands in all agent files
- [ ] **ADR references**: All referenced ADRs exist
- [ ] **Path references**: All referenced paths exist
- [ ] **CLAUDE.md smoke test**: All required sections present
- [ ] **AGENTS.md smoke test**: All required sections present
- [ ] **copilot-instructions.md smoke test**: All required sections present
- [ ] **ARCHITECTURE.md smoke test**: All required sections present
- [ ] **ADR-001 smoke test**: Follows template structure
- [ ] **Pre-commit hook config**: References valid commands
- [ ] **Lint config**: Parses without syntax errors
- [ ] **Verification script**: `scripts/verify-harness.sh` passes
- [ ] **Agent file synchronization**: Commands consistent across CLAUDE.md, AGENTS.md, copilot-instructions.md
- [ ] **Composite command**: `make check` (or equivalent) runs successfully
- [ ] **Monorepo consistency** (if applicable): Per-package profiles match root, cross-package deps match imports
- [ ] **Report generated**: Summary of created, modified, skipped files and issues
```

Mark each item as pass, fail, or N/A. Any failing item must be resolved before the harness is considered complete.
