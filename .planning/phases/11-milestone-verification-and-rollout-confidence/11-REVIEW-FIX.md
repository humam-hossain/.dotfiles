---
phase: 11-milestone-verification-and-rollout-confidence
fixed_at: 2026-04-24T00:00:00Z
review_path: .planning/phases/11-milestone-verification-and-rollout-confidence/11-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 11: Code Review Fix Report

**Fixed at:** 2026-04-24
**Source review:** .planning/phases/11-milestone-verification-and-rollout-confidence/11-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2 (WR-01, WR-02 — critical_warning scope)
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-01: SMOKE_FAIL written to cwd but checked in REPORT_DIR — diagnostic path mismatch

**Files modified:** `scripts/nvim-validate.sh`
**Commit:** fc1a563
**Applied fix:**
Two changes made to `cmd_smoke`:
1. The embedded Lua `io.open` call changed from `io.open('SMOKE_FAIL', 'w')` to `io.open(os.getenv('SMOKE_FAIL_PATH') or 'SMOKE_FAIL', 'w')` so the write path is driven by an env var.
2. The nvim invocation prefixed with `SMOKE_FAIL_PATH="$REPORT_DIR/SMOKE_FAIL"` so Neovim inherits the correct absolute path matching the shell-side check at line 410.

This aligns the write and read sides, ensures failed plugin names are surfaced to stderr via the diagnostic branch, and eliminates the stray `SMOKE_FAIL` file at repo root.

---

### WR-02: Wrong Go module path for shfmt install hint

**Files modified:** `scripts/nvim-validate.sh`
**Commit:** c2909ed
**Applied fix:**
Changed the `["shfmt"]` entry in `TOOL_HINTS` from:

```
go install mvdan.cc/sh/cmd/shfmt@latest  OR  :MasonInstall shfmt
```

to:

```
go install mvdan.cc/sh/v3/cmd/shfmt@latest  OR  :MasonInstall shfmt
```

This matches the correct v3 major-version module path used in the README and ensures the WARN output gives users a working install command.

---

_Fixed: 2026-04-24_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
