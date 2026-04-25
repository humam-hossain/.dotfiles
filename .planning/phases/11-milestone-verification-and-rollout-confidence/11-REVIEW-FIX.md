---
phase: 11-milestone-verification-and-rollout-confidence
fixed_at: 2026-04-24T00:00:00Z
review_path: .planning/phases/11-milestone-verification-and-rollout-confidence/11-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 11: Code Review Fix Report

**Fixed at:** 2026-04-24
**Source review:** `.planning/phases/11-milestone-verification-and-rollout-confidence/11-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 7
- Fixed: 7
- Skipped: 0

## Fixed Issues

### WR-01: SMOKE_FAIL written to cwd but checked in REPORT_DIR — diagnostic path mismatch

**Files modified:** `scripts/nvim-validate.sh`
**Commit:** fc1a563
**Applied fix:** Two changes made to `cmd_smoke`: (1) the embedded Lua `io.open` call changed from `io.open('SMOKE_FAIL', 'w')` to `io.open(os.getenv('SMOKE_FAIL_PATH') or 'SMOKE_FAIL', 'w')` so the write path is driven by an env var; (2) the nvim invocation prefixed with `SMOKE_FAIL_PATH="$REPORT_DIR/SMOKE_FAIL"` so Neovim inherits the correct absolute path matching the shell-side check. This aligns the write and read sides, ensures failed plugin names are surfaced to stderr, and eliminates the stray `SMOKE_FAIL` file at repo root.

---

### WR-02: Wrong Go module path for shfmt install hint

**Files modified:** `scripts/nvim-validate.sh`
**Commit:** c2909ed
**Applied fix:** Corrected the `["shfmt"]` entry in `TOOL_HINTS` from `mvdan.cc/sh/cmd/shfmt` to `mvdan.cc/sh/v3/cmd/shfmt`, matching the correct v3 module path documented in the README and ensuring the WARN output gives users a working install command.

---

### IN-01: eval without double-quoting in zprofile — command injection surface

**Files modified:** `.config/.zprofile`
**Commit:** bf17949
**Applied fix:** Wrapped the command substitution in double quotes: changed `eval $(gnome-keyring-daemon ...)` to `eval "$(gnome-keyring-daemon ...)"` to prevent word-splitting of the daemon's output before `eval` processes it.

---

### IN-02: pacman -Sy without -u in arch/nvim.sh — partial upgrade risk

**Files modified:** `arch/nvim.sh`
**Commit:** 7a9e464
**Applied fix:** Added a two-line comment above the first `pacman -Sy` invocation explaining that `-Sy` without `-u` is intentional in this targeted install script and that the caller is responsible for running `pacman -Syu` beforehand. The pacman command itself was left unchanged (preferred over adding `-u` to avoid an unattended full-system upgrade).

---

### IN-03: Stale TODO comment in project.lua

**Files modified:** `.config/nvim/lua/plugins/project.lua`
**Commit:** c9a30dd
**Applied fix:** Replaced `--- TODO: Project scoping - project.nvim ---` with a two-line doc comment: `-- project.nvim: use pattern-only detection to avoid vim.lsp.buf_get_clients() / -- deprecation warnings on Neovim 0.12+.`

---

### IN-04: Missing list item number in README smoke checklist

**Files modified:** `.config/nvim/README.md`
**Commit:** 06f6789
**Applied fix:** Restored the missing `5` in the ordered list item (`. **Split close**` → `5. **Split close**`) and removed the stray trailing `>` from the keymap (`<leader>xs>` → `<leader>xs`).

---

### IN-05: Validation table in README lists incomplete `all` subcommand sequence

**Files modified:** `.config/nvim/README.md`
**Commit:** 83335f5
**Applied fix:** Updated the `all` row in the Validation Commands table to read `Run startup → sync → smoke → health → checkhealth → keymaps → formats in order (fail fast)`, matching the actual `cmd_all` implementation and the Validation Harness section of the same README.

---

_Fixed: 2026-04-24_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
