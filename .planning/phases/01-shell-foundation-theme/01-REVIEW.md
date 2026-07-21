---
phase: 01-shell-foundation-theme
status: issues
depth: standard
reviewed: 2026-07-21T11:56:17Z
reviewer: orchestrator-inline (gsd-code-reviewer rate-limited)
scope:
  - arch/quickshell.sh
  - .config/quickshell/modules/ii/sidebarLeft/aiChat/MessageCodeBlock.qml
  - .config/quickshell/modules/common/widgets/shapes/**
  - .config/quickshell/shell.qml (entry, wholesale)
summary:
  critical: 0
  warning: 3
  info: 2
---

# Phase 01 Code Review

**Scope:** Intentional phase changes (provisioning, hard-error fixes, entry wiring). Wholesale dots-hyprland tree reviewed only where phase-introduced risk is clear.

**Status:** issues (advisory — no Critical)

## Findings

### Warning

1. **`arch/quickshell.sh` — `symlink_config` uses `rm -rf "$QS_DST"`**
   - **Risk:** If `QS_DST` were ever a real directory with local edits (not a symlink), this deletes it without backup.
   - **Mitigation present:** Script documents single-directory symlink pattern; current home path is already a symlink to the repo.
   - **Suggestion:** Guard with `if [ -L "$QS_DST" ] || [ ! -e "$QS_DST" ]; then ...; else die "refusing to rm non-symlink"; fi`.

2. **`arch/quickshell.sh` — still installs `ddcutil` / configures i2c**
   - **Risk:** PROJECT.md documents ddcutil DDC/CI polling as iGPU crash risk; brightness is out of scope.
   - **Note:** Pre-existing provisioning intent for ddcutil group/module; Phase 1 plans did not remove it. Shell must not poll ddcutil (enforced by plan prohibitions, not by package absence).
   - **Suggestion:** Later phase or explicit decision to drop ddcutil/i2c from PACKAGES if never used.

3. **`MessageCodeBlock.qml` — save-to-file still shells out with interpolated content**
   - **Location:** save button `onClicked` → `bash -c` with `echo '…' > path`
   - **Risk:** Relies on `StringUtils.shellSingleQuoteEscape`; path/`segmentLang` less controlled. Pre-existing wholesale code; phase only removed SyntaxHighlighter import.
   - **Suggestion:** Prefer `FileView` / Qt file APIs without shell when AI chat is re-enabled.

### Info

1. **`generate_theme` SCSS→JSON converter** — robust enough for Material tokens; fails if `materialyoucolor` missing (correct fail-closed under `set -e`). System package install needs sudo/`yay` once.

2. **`Appearance.qml` lacks `m3primaryDim`** while generator emits `primary_dim` → MaterialThemeLoader warns at runtime; non-fatal. Add property or filter unknown keys in loader later.

## Positive

- Shapes module vendored completely (hard-crash root cause fixed).
- AI code blocks no longer hard-block shell load without KDE syntax-highlighting.
- `generate_theme` produces snake_case JSON matching MaterialThemeLoader/matugen contract.
- Entry `shell.qml` correctly calls `MaterialThemeLoader.reapplyTheme()` and loads panel families via LazyLoader.

## Recommendation

No Critical blockers for Phase 1 ship. Consider addressing Warning #1 before broader provisioning reuse. Optional: `/gsd-code-review 1 --fix` when rate limit resets for automated fixes.
