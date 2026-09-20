# Phase 34: Verification, Zero Drift & Bootstrap Integration - Context

**Gathered:** 2026-09-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Verify Material You dynamic color adaptation across all pills with zero defects, validate repository integrity with `arch/dots-hyprland.sh verify --strict` (0 findings), and verify `./bootstrap.sh` fresh-machine deployment for the Quickshell overlay system:

1. **Material You Dynamic Color Adaptation & Contract (INTG-01):**
   - Execute dual theming drill: test native `switchwall.sh --noswitch` against the active configured wallpaper, plus fallback `--color` seed generation (`switchwall.sh --color "#3f51b5"`).
   - Verify dark mode color tokens (`colLayer0`, `colLayer1`, `colOnLayer1`, `colSecondaryContainer`, `colPrimary`, `colError`) in `~/.local/state/quickshell/user/generated/colors.json`.
   - Ensure all `restow/quickshell/` modules bind strictly to `Appearance` color tokens without unauthorized hardcoded hex codes.
   - Assert monotonic mtime advancement on `colors.json` and confirm the live `quickshell` process remains healthy without crashing or requiring a manual desktop restart.
2. **Repository Integrity & Zero Working Tree Drift (INTG-02):**
   - Verify that `arch/dots-hyprland.sh verify --strict` passes with `FAIL=0 FINDINGS=0`.
   - Commit baseline working tree modifications (`capture/ii/.../config.json` and `stow/hypr/custom/general.lua`) so `git status --porcelain` is 100% clean.
   - Verify 11/11 live overlay symlinks in `~/.config/quickshell/` resolve 1:1 to `$REPO_ROOT/restow/quickshell/` with zero regular file overwrites or dangling links.
   - Preserve existing `*.bak*` backup artifacts as non-blocking `[INFO]` entries.
   - Assert strict byte-identical porcelain cleanliness before and after theming operations (zero git churn).
3. **Fresh-Machine Bootstrap Integration (INTG-03):**
   - Update `bootstrap.sh` `run_stow_step` to explicitly pre-create Quickshell target directories (`.config/quickshell/ii/modules/ii/bar`, `.config/quickshell/ii/services`, `.config/quickshell/ii/scripts/videos`).
   - Confirm `step_destub` automatically detects upstream Quickshell stubs via generic `stow -n` simulation, archiving them into `~/.dotfiles-backup.<epoch>/` with SHA-256 manifests and unlinking them.
   - In Step 6 (`generate_initial_theme`), assert that `colors.json` is primed before relogin and Step 7 verification.
   - Test bootstrap destubbing, pre-creation, and symlinking within an isolated temporary scratch environment (`/tmp/p34-assert-XXXXXX`) without mutating host files.
4. **Automated Test Harness & v0.6 Regression Sweep (INTG-01, INTG-02, INTG-03):**
   - Author `scripts/phase34-verification-assert.sh` adhering to the established 5-section architecture.
   - Execute a full milestone regression sweep (`phase31`, `phase32`, and `phase33` assert scripts), requiring each to pass with `FAIL=0`.
   - Support `--section 1..5` flags for isolated debugging, with complete failure accumulation and clean `EXIT` trap cleanup.

Out of scope:
- Full QML shell rewrite or replacing upstream dots-hyprland base modules.
- New background telemetry daemons (disk/ping/network speed) — reserved for v2 milestone.
- Waybar restoration (Waybar is retired).

</domain>

<decisions>
## Implementation Decisions

### Material You Dynamic Theming Drill & Color Adaptation (INTG-01)
- **D-01 (Dual Theming Drill):** Test both upstream native `switchwall.sh --noswitch` against the active configured wallpaper and synthetic color seed fallback (`switchwall.sh --color "#3f51b5"`), guaranteeing both production paths cleanly update `colors.json` and pill tokens. — **Reversibility:** reversible.
- **D-02 (Dark Mode Testing Scope):** Adhere to upstream dots-hyprland default desktop preferences by verifying dynamic color adaptation strictly in dark mode (`prefer-dark`) without mutating system-wide GNOME color-scheme settings. — **Reversibility:** reversible.
- **D-03 (Full Token Contract Enforcement):** Assert core tokens in `colors.json` (`colLayer0`, `colLayer1`, `colOnLayer1`, `colSecondaryContainer`, `colPrimary`, `colError`), and assert that all components in `restow/quickshell/` bind strictly to `Appearance.colors` and `Appearance.m3colors` tokens with zero unauthorized hardcoded hex codes. — **Reversibility:** reversible.
- **D-04 (Dynamic Hot Update Verification):** Assert strictly monotonic mtime advancement of `~/.local/state/quickshell/user/generated/colors.json` upon theme generation, and verify that the active `quickshell` process remains running smoothly without crashing or requiring an intrusive process restart. — **Reversibility:** reversible.

### Fresh-Machine Bootstrap & Quickshell Destubbing (INTG-03)
- **D-05 (Explicit Quickshell Directory Pre-Creation):** In `bootstrap.sh` `run_stow_step` (Step 5), add Quickshell overlay target directories (`.config/quickshell/ii/modules/ii/bar`, `.config/quickshell/ii/services`, `.config/quickshell/ii/scripts/videos`) to the `mkdir -p` pre-creation list, guaranteeing zero GNU Stow directory folding on fresh installs. — **Reversibility:** reversible.
- **D-06 (Generic Stow Conflict Destubbing):** Rely on `bootstrap.sh` `run_destub`'s existing `stow -n --no-folding` conflict detection to automatically discover all upstream Quickshell stubs, archiving them into `~/.dotfiles-backup.<epoch>/` with SHA-256 manifests and unlinking them cleanly without fragile hardcoded path lists. — **Reversibility:** reversible.
- **D-07 (Isolated Scratch Bootstrap Drill):** In `scripts/phase34-verification-assert.sh`, execute Section 4 within a mock home and repo scratch environment (`/tmp/p34-assert-s4-XXXXXX`), validating `run_destub`, parent directory pre-creation, and symlink resolution safely without mutating the operator's live environment. — **Reversibility:** reversible.
- **D-08 (Verified Color Priming in Bootstrap):** In `bootstrap.sh` `generate_initial_theme` (Step 6), assert that `colors.json` is generated and non-empty before proceeding to Step 7 verification, guaranteeing Quickshell pill colors are primed before operator relogin. — **Reversibility:** reversible.

### Repository Integrity & Strict Verification Rules (INTG-02)
- **D-09 (Commit Baseline Working Tree Refinements):** Commit pending modifications (`capture/ii/.config/illogical-impulse/config.json` setting `showPerformanceProfileToggle: false` and `stow/hypr/.config/hypr/custom/general.lua` setting refined layout geometry and animations) as part of Phase 34 baseline to achieve strict zero porcelain drift. — **Reversibility:** reversible.
- **D-10 (Retain Backup Artifacts as Non-Blocking [INFO]):** Retain existing `.bak` installer backup files in `~/.config/quickshell/` as harmless non-blocking `[INFO]` entries, maintaining `arch/dots-hyprland.sh verify --strict` pass with `FAIL=0 FINDINGS=0`. — **Reversibility:** reversible.
- **D-11 (Strict 11/11 Symlink Target Assertion):** Assert that all 11 live overlay files in `~/.config/quickshell/` strictly resolve 1:1 to `$REPO_ROOT/restow/quickshell/` with zero dangling links or unlinked regular files. — **Reversibility:** reversible.
- **D-12 (Strict Porcelain Snapshot Invariant):** Take a `git status --porcelain` snapshot immediately before and after theme switching drills; assert 100% byte-identical clean output to prove zero working tree churn. — **Reversibility:** reversible.

### Automated Test Harness & v0.6 Regression Sweep (INTG-01, INTG-02, INTG-03)
- **D-13 (5-Section Test Harness Architecture):** Author `scripts/phase34-verification-assert.sh` structured across 5 fail-closed sections:
  - Section 1: Data contracts, 11/11 symlinks, and directory pre-creation checks.
  - Section 2: Material You dynamic theming drill (dual drill) and zero-churn porcelain check.
  - Section 3: Repository strict verification gate (`arch/dots-hyprland.sh verify --strict` with `FAIL=0 FINDINGS=0`).
  - Section 4: Isolated bootstrap destub, stow, and color priming scratch drill.
  - Section 5: Full v0.6 milestone regression sweep (`phase31`, `phase32`, `phase33`). — **Reversibility:** reversible.
- **D-14 (Full v0.6 Regression Sweep):** Section 5 executes `scripts/phase31-overlay-pill-assert.sh`, `scripts/phase32-component-formatting-assert.sh`, and `scripts/phase33-layout-assert.sh` in sequence, asserting that each exits 0 with `FAIL=0`. — **Reversibility:** reversible.
- **D-15 (Standard CLI Flag Filtering):** Support `--section 1..5` (and `-s`) flags allowing developers to run isolated sections during targeted testing, defaulting to all 5 sections when run without flags. — **Reversibility:** reversible.
- **D-16 (Comprehensive Accumulation & Trap Cleanup):** Accumulate PASS and FAIL counts across all assertions, report summary results, clean up all temporary scratch roots on `EXIT`/`SIGINT`/`SIGTERM`, and exit 0 only if `FAIL == 0`. — **Reversibility:** reversible.

### the agent's Discretion
- Exact naming and formatting of internal test assertions and logging helpers in `scripts/phase34-verification-assert.sh`.
- Scratch file naming and mock repository fixtures in Section 4.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and Requirements
- `.planning/ROADMAP.md` §Phase 34 — Verification, Zero Drift & Bootstrap Integration goal and success criteria
- `.planning/REQUIREMENTS.md` lines 34–39 — INTG-01, INTG-02, INTG-03 specifications
- `.planning/STATE.md` §Milestone v0.6 — Accumulated milestone decisions and status

### Prior Phase Verification Architecture
- `.planning/milestones/v0.5-phases/29-theme-data-contracts-verification-bootstrap-integration/29-CONTEXT.md` — Reference 5-section verification suite and bootstrap drill
- `.planning/phases/31-overlay-infrastructure-pill-geometry-foundation/31-CONTEXT.md` — Quickshell overlay foundation and BarGroup geometry
- `.planning/phases/32-component-representation-formatting-customization/32-CONTEXT.md` — Audited component formatting contracts
- `.planning/phases/33-modular-layout-live-trial-and-error-rearrangement/33-CONTEXT.md` — Modular Left, Center, and Right layout in BarContent.qml

### Bootstrap & Verification Orchestrators
- `bootstrap.sh` — Root orchestrator (`run_destub`, `run_stow_step`, `generate_initial_theme`, `deploy_capture_seeds`)
- `arch/dots-hyprland.sh` — Wrapper implementing `run_verify()` and strict verification gate
- `guard-paths.tsv` — Machine-checked data contract for guarded theme paths
- `collision-map.tsv` — Machine-asserted collision map derivation
- `restow/README.md` — Restow contract, recovery tags, and package table

### Active Quickshell Modules & Scripts
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` — Modular bar layout
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` — Pill container geometry
- `~/.config/quickshell/ii/scripts/colors/switchwall.sh` — Upstream dynamic wallpaper & color switcher
- `~/.config/quickshell/ii/scripts/colors/applycolor.sh` — Matugen invocation and color reload

### Milestone v0.6 Assertion Suites
- `scripts/phase31-overlay-pill-assert.sh` — Phase 31 pill foundation assert harness
- `scripts/phase32-component-formatting-assert.sh` — Phase 32 component formatting assert harness
- `scripts/phase33-layout-assert.sh` — Phase 33 layout assert harness

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/phase29-theme-data-contracts-assert.sh`: Established 5-section test harness pattern with porcelain bracket checks, strict verification execution, and isolated scratch bootstrap drilling.
- `bootstrap.sh`: 7-step resumable state machine already supporting `run_destub`, `run_stow_step`, and `generate_initial_theme`.
- `arch/dots-hyprland.sh`: `verify --strict` engine already recognizes Quickshell directories, backup artifacts, and stowed links.

### Established Patterns
- Restow overlay discipline: Personal customizations reside under `restow/quickshell/` and symlink into `~/.config/quickshell/` with `--no-folding`.
- Monotonic mtime assertion: Verifying that theme operations actually advance file modification times without modifying git working trees.
- Scratch testing in `/tmp/`: Exercising destructive or mutating procedures (destub, stow) in disposable sandboxes to protect live desktop sessions.

### Integration Points
- `bootstrap.sh` lines 518–524: `run_stow_step` `mkdir -p` list to include Quickshell overlay directories.
- `bootstrap.sh` lines 652–665: `generate_initial_theme` color priming assertion for `colors.json`.
- `scripts/phase34-verification-assert.sh`: New executable test suite verifying INTG-01, INTG-02, and INTG-03.

</code_context>

<specifics>
## Specific Ideas

- **Test Sequence in Section 2 (Theming Drill):**
  1. Record porcelain snapshot: `git status --porcelain`.
  2. Record initial mtime of `colors.json`.
  3. Execute `switchwall.sh --noswitch` on active wallpaper.
  4. Assert monotonic mtime advance and healthy `quickshell` process.
  5. Execute `switchwall.sh --color "#3f51b5"` temporary seed drill.
  6. Re-run `switchwall.sh --noswitch` to restore operator wallpaper palette.
  7. Assert porcelain snapshot is byte-identical clean.
- **Section 4 (Bootstrap Scratch Drill):**
  1. Create temporary mock home with simulated upstream stubs in `modules/ii/bar/` and `services/`.
  2. Run `run_destub` and assert stubs moved to `.dotfiles-backup.<epoch>/` with SHA-256 manifest.
  3. Run `run_stow_step` and assert symlinks created to `restow/quickshell/` with zero directory folding.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within Phase 34 scope.

</deferred>

---

*Phase: 34-verification-zero-drift-bootstrap-integration*
*Context gathered: 2026-09-20*
