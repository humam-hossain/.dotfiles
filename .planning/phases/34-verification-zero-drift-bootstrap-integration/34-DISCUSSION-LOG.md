# Phase 34: Verification, Zero Drift & Bootstrap Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-20
**Phase:** 34-verification-zero-drift-bootstrap-integration
**Areas discussed:** Material You dynamic theming drill & color adaptation, Fresh-machine bootstrap & Quickshell destubbing, Repository integrity & strict verification rules, Automated test harness & v0.6 regression sweep

---

## Material You dynamic theming drill & color adaptation

| Option | Description | Selected |
|--------|-------------|----------|
| Dual Drill | Test native switchwall.sh --noswitch on active wallpaper, plus a temporary --color seed fallback to verify both paths cleanly update quickshell colors.json and pill tokens | ✓ |
| Active Wallpaper Only | Exclusively test switchwall.sh --noswitch against the wallpaper path configured in config.json | |
| Isolated Color Seed Only | Test purely synthetic color seeds via switchwall.sh --color without referencing any local wallpaper image files | |

**User's choice:** Dual Drill (matches upstream dots-hyprland bootstrap & daily workflow)
**Notes:** User inquired about upstream dots-hyprland behavior; confirmed upstream supports both active wallpaper theming (`--noswitch`) and color seed fallback (`--color`).

| Option | Description | Selected |
|--------|-------------|----------|
| Full Light + Dark Cycle | Exercise switchwall.sh in both light and dark modes, asserting that pill color tokens and contrast invert cleanly, then restore original user mode | |
| Dark Mode Only | Validate theming strictly in dark mode (dots-hyprland's default desktop preference) without toggling system color-scheme | ✓ |
| You decide | Standard test practice (test current mode plus dark/light token contract check) | |

**User's choice:** Dark Mode Only
**Notes:** Validates theming strictly in dark mode per dots-hyprland's default desktop preference without disrupting the operator's system-wide color-scheme.

| Option | Description | Selected |
|--------|-------------|----------|
| Full Token Contract | Assert core tokens in colors.json (colLayer0, colLayer1, colOnLayer1, colSecondaryContainer, colPrimary, colError) and verify restow/quickshell components bind strictly to Appearance tokens with zero unauthorized hardcoded hex codes | ✓ |
| Container & Text Only | Verify only the primary pill background (colLayer1) and foreground text (colOnLayer1) bindings | |
| You decide | Enforce full token schema matching upstream Appearance.qml contract | |

**User's choice:** Full Token Contract
**Notes:** Enforces strict token conformance across all customized pills.

| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic Hot Update | Verify strictly monotonic mtime advancement of colors.json and verify the live quickshell process remains running smoothly without crashing or requiring an intrusive process restart | ✓ |
| Explicit Shell Reload | Trigger a full quickshell restart after color generation to confirm cold startup color parsing | |
| You decide | Validate live file mtime updates without disrupting the user's active session | |

**User's choice:** Dynamic Hot Update
**Notes:** Verifies Quickshell's reactive file-watcher architecture non-intrusively.

---

## Fresh-machine bootstrap & Quickshell destubbing

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit Pre-creation | Add Quickshell overlay target directories (.config/quickshell/ii/modules/ii/bar, .config/quickshell/ii/services, .config/quickshell/ii/scripts/videos) to bootstrap.sh run_stow_step's mkdir -p list to guarantee zero directory folding on fresh machines | ✓ |
| Implicit Upstream Layout | Rely on upstream dots-hyprland installer (Step 3) having already established ~/.config/quickshell tree, keeping bootstrap.sh list as-is | |
| You decide | Enforce explicit parent directory pre-creation per repo convention | |

**User's choice:** Explicit Pre-creation
**Notes:** Prevents GNU Stow directory folding issues during clean-machine bootstrap.

| Option | Description | Selected |
|--------|-------------|----------|
| Generic Stow Conflict Detection | Let bootstrap.sh run_destub's stow -n dry-run automatically detect all conflicting upstream Quickshell stubs, archiving them into ~/.dotfiles-backup.<epoch>/ with SHA-256 manifests and unlinking them without hardcoded path lists | ✓ |
| Explicit Path Pruning | Add explicit Quickshell file checks in run_destub alongside legacy Catppuccin checks to unconditionally back up and remove upstream bar stubs before stow runs | |
| You decide | Maintain the generic stow -n conflict resolution mechanism | |

**User's choice:** Generic Stow Conflict Detection
**Notes:** Uses proven architecture to automatically detect and archive upstream stubs without brittle hardcoded lists.

| Option | Description | Selected |
|--------|-------------|----------|
| Isolated Scratch Drill | Verify destub, pre-creation, and restow/quickshell symlink creation inside a temporary mock $HOME (/tmp/p34-assert-XXXXXX) to test real filesystem mutations safely without affecting the operator session | ✓ |
| Live Dry-Run Only | Execute ./bootstrap.sh --dry-run directly on the host to verify pipeline parsing and command output without disk mutations | |
| You decide | Use isolated scratch drill with mock upstream files | |

**User's choice:** Isolated Scratch Drill
**Notes:** Follows Section 4 pattern from Phase 29.

| Option | Description | Selected |
|--------|-------------|----------|
| Verified Color Priming | Assert that colors.json exists and is non-empty after generate_initial_theme runs, confirming Quickshell pill colors are primed before operator relogin | ✓ |
| Soft Warning | Log a non-blocking warning if colors.json is not generated yet, allowing first login to run switchwall.sh | |
| You decide | Verify colors.json creation with fallback confirmation | |

**User's choice:** Verified Color Priming
**Notes:** Ensures Quickshell has a valid palette before Step 7 verification and user relogin.

---

## Repository integrity & strict verification rules

| Option | Description | Selected |
|--------|-------------|----------|
| Commit Baseline Changes | Commit current pending modifications (capture/ii/.../config.json and stow/hypr/custom/general.lua) into git so working tree achieves strict zero porcelain drift | ✓ |
| Stash or Revert | Discard or stash unstaged changes before running strict verification to test against HEAD | |
| You decide | Commit legitimate configuration changes as part of Phase 34 commits | |

**User's choice:** Commit Baseline Changes
**Notes:** Locks in performance profile toggle setting and window animation refinements.

| Option | Description | Selected |
|--------|-------------|----------|
| Retain as Non-Blocking [INFO] | Keep existing .bak files in place; verify --strict recognizes them as harmless installer/overlay backups and passes with FAIL=0 FINDINGS=0 | ✓ |
| Archive to Backup Dir | Move old .bak files into ~/.dotfiles-backup.<epoch>/ to eliminate all clutter and leave ~/.config/quickshell completely clean of legacy backup files | |
| You decide | Retain as non-blocking [INFO] per existing verify contract | |

**User's choice:** Retain as Non-Blocking [INFO]
**Notes:** Matches existing `run_verify()` contract.

| Option | Description | Selected |
|--------|-------------|----------|
| Strict 11/11 Symlink Target Assertion | Assert that all 11 live overlay files in ~/.config/quickshell/ strictly resolve to $REPO_ROOT/restow/quickshell/ with zero regular file overwrites or dangling links | ✓ |
| Bar Modules Only (7 files) | Verify strictly the 7 bar/ QML files (BarContent, BarGroup, ClockWidget, Resource, Resources, SysTray, UpdatesButton) | |
| You decide | Enforce full 11/11 symlink target resolution suite | |

**User's choice:** Strict 11/11 Symlink Target Assertion
**Notes:** Ensures 100% overlay coverage across bar, services, and scripts.

| Option | Description | Selected |
|--------|-------------|----------|
| Strict Porcelain Snapshot | Take git status --porcelain snapshot before and after switchwall.sh execution; assert 100% byte-identical clean state to guarantee zero repository churn | ✓ |
| Modified Files Only | Check git diff --name-only to ensure no tracked files are modified, ignoring any temporary untracked files | |
| You decide | Enforce strict byte-identical porcelain cleanliness | |

**User's choice:** Strict Porcelain Snapshot
**Notes:** Verifies zero working-tree churn across runtime operations.

---

## Automated test harness & v0.6 regression sweep

| Option | Description | Selected |
|--------|-------------|----------|
| 5-Section Test Harness | Section 1 (Contracts & 11/11 symlinks), Section 2 (Theming drill & zero-churn porcelain check), Section 3 (arch/dots-hyprland.sh verify --strict gate), Section 4 (Isolated bootstrap destub/stow drill), Section 5 (v0.6 regression sweep) | ✓ |
| Core Verification Only | Combine theming & symlinks into Section 1, strict verify & bootstrap drill in Section 2, regression sweep in Section 3 | |
| You decide | Follow the proven 5-section Phase 29 structure adapted for v0.6 Quickshell | |

**User's choice:** 5-Section Test Harness
**Notes:** Mirrors the structure of Phase 29.

| Option | Description | Selected |
|--------|-------------|----------|
| Full v0.6 Regression Sweep | Execute phase31, phase32, and phase33 assert scripts in sequence, requiring each to exit 0 with FAIL=0 to guarantee zero regressions across the entire milestone | ✓ |
| Latest Phase Only | Run only phase33-layout-assert.sh in the regression step to minimize runtime | |
| You decide | Run the complete v0.6 suite (phase31, phase32, phase33) | |

**User's choice:** Full v0.6 Regression Sweep
**Notes:** Guarantees zero regressions across pill geometry, component formatting, and modular layout.

| Option | Description | Selected |
|--------|-------------|----------|
| Standard --section N Filtering | Support --section 1..5 flags allowing isolated debugging of specific sections during planning and execution, defaulting to all sections when no flag is provided | ✓ |
| All-or-Nothing | Execute all 5 sections unconditionally without individual section isolation flags | |
| You decide | Support --section N filtering for developer convenience | |

**User's choice:** Standard --section N Filtering
**Notes:** Standard CLI contract across repo test scripts.

| Option | Description | Selected |
|--------|-------------|----------|
| Comprehensive Accumulation & Trap Cleanup | Run all assertions across selected sections, accumulate PASS/FAIL counts, clean up temporary scratch files via EXIT trap, and exit non-zero only at completion if any failures occurred | ✓ |
| Abort on First Defect | Stop execution immediately with exit code 1 upon encountering the first assertion failure | |
| You decide | Enforce standard comprehensive reporting with trap cleanup | |

**User's choice:** Comprehensive Accumulation & Trap Cleanup
**Notes:** Provides a complete report on test execution with clean environment handling.

---

## the agent's Discretion

- Test helper function names and internal assertion output formatting in `scripts/phase34-verification-assert.sh`.
- Scratch file naming and mock repository fixtures in Section 4.

## Deferred Ideas

- None — discussion stayed within Phase 34 scope.
