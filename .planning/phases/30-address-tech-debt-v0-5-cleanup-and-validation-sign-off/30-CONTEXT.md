# Phase 30: Address tech debt: v0.5 cleanup and validation sign-off - Context

**Gathered:** 2026-09-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Address all accumulated technical debt, metadata inconsistencies, and validation coverage gaps identified in the Milestone v0.5 Audit (`.planning/v0.5-MILESTONE-AUDIT.md`) before archiving milestone v0.5:

1. **Kitty Opacity & Visual Polish (`DEBT-05`):**
   - In `restow/kitty/.config/kitty/kitty.conf`, update `background_opacity` from `0.85` to `0.90` per Phase 28 UAT preference (`28-UAT.md`).
   - Align `scripts/phase28-terminal-fuzzel-assert.sh` line 273 and line 282, 289 to check for `0.90` with an inline comment referencing Phase 28 UAT preference and Phase 30 alignment, ensuring multi-phase regression sweeps remain green.
   - Signal live running Kitty instances via `killall -SIGUSR1 kitty 2>/dev/null || true` without dropping active sessions.
   - Strictly confine visual adjustments to Kitty background opacity, preserving all other launcher/terminal templates as verified in Phase 28.

2. **Environment & Signal Robustness (`DEBT-06`):**
   - Virtualenv Fallback: In `bootstrap.sh`'s `generate_initial_theme()`, export `export ILLOGICAL_IMPULSE_VIRTUAL_ENV="${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv}"` before running `switchwall.sh`, ensuring non-graphical runs (raw TTY, SSH, or fresh bootstrap) don't fail when Hyprland environment hooks haven't loaded.
   - Template Fallback: In `~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh`, add fallback parameter expansion to the virtualenv source line (`source "$(eval echo ${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv})/bin/activate"`) live and add idempotent alignment in `bootstrap.sh`.
   - Process Signaling: In `~/.config/quickshell/ii/scripts/colors/applycolor.sh`, replace divergent `pgrep -f kitty` / `kill -SIGUSR1 $(pidof kitty)` with `killall -SIGUSR1 kitty 2>/dev/null || true` to eliminate syntax errors when non-Kitty commands match regex or when no Kitty is running. Add idempotent alignment in `bootstrap.sh`.

3. **Nyquist Validation Sign-Off (`DEBT-07`):**
   - Reconcile `29-VALIDATION.md` frontmatter from `status: draft`, `nyquist_compliant: false` to `status: validated`, `nyquist_compliant: true`, `wave_0_complete: true`, and mark all 6 tasks `✅ green` (backed by `scripts/phase29-theme-data-contracts-assert.sh` passing 30/30 checks).

4. **Phase 30 Test Harness & Regression Suite (`DEBT-08`):**
   - Author dedicated test harness `scripts/phase30-tech-debt-assert.sh` with 5 automated sections:
     - Section 1: Kitty opacity 0.90 check & Phase 28 assert alignment.
     - Section 2: Environment fallback & `applycolor.sh` signaling hardening.
     - Section 3: Nyquist validation compliance across all v0.5 phases (25–30) and `REQUIREMENTS.md` traceability.
     - Section 4: Strict verifier engine gate (`arch/dots-hyprland.sh verify --strict` exits 0 with `FAIL=0 FINDINGS=0`) and working tree porcelain clean check.
     - Section 5: Full v0.5 regression sweep consecutively executing `phase25`, `phase26`, `phase27`, `phase28`, and `phase29` assert scripts fail-closed.
   - Author `30-VALIDATION.md` with Wave 0 test harness mapping and `nyquist_compliant: true`.

Out of scope:
- Modifying upstream dots-hyprland submodule files directly in `vendor/dots-hyprland` (fork/submodule pin remains untouched).
- Waybar custom widget ports (CUST-01..04) — reserved for v2 milestone.
- Expanding visual theming changes beyond Kitty background opacity.

</domain>

<decisions>
## Implementation Decisions

### Kitty Opacity & Visual Polish (DEBT-05)

- **D-01:** Update Kitty background opacity: In `restow/kitty/.config/kitty/kitty.conf`, update line 3 from `background_opacity 0.85` to `background_opacity 0.90` to honor user preference recorded in `28-UAT.md`. — **Reversibility:** reversible
- **D-02:** Align Phase 28 assert harness: In `scripts/phase28-terminal-fuzzel-assert.sh`, update lines 273 and 282, 289 to check for `opts.background_opacity - 0.90` (allowing tolerance `abs(...) > 0.01`) with an inline comment citing the Phase 28 UAT preference and Phase 30 alignment. This prevents false regression failures in unified regression sweeps. — **Reversibility:** reversible
- **D-03:** Live Kitty reload: Signal active Kitty instances via `killall -SIGUSR1 kitty 2>/dev/null || true` so running terminal windows adopt the 0.90 opacity immediately without dropping active shell sessions. — **Reversibility:** reversible
- **D-04:** Scope confinement: Strictly confine visual adjustments to Kitty background opacity; do not alter Fuzzel launcher alpha or other terminal settings established in Phase 28. — **Reversibility:** reversible

### Environment & Signal Robustness (DEBT-06)

- **D-05:** Bootstrap virtualenv fallback export: In `bootstrap.sh` function `generate_initial_theme()`, add `export ILLOGICAL_IMPULSE_VIRTUAL_ENV="${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv}"` before executing `switchwall.sh`. This ensures non-graphical runs (TTY, SSH, fresh machine bootstrap before relogin) provide child processes with the virtualenv path. — **Reversibility:** reversible
- **D-06:** Idempotent template fallback alignment in bootstrap: In `bootstrap.sh`, add a sanitization block for `~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh` ensuring the virtualenv source line includes parameter expansion fallback, and patch the live script directly. — **Reversibility:** reversible
- **D-07:** Process signaling hardening in `applycolor.sh`: In `~/.config/quickshell/ii/scripts/colors/applycolor.sh` lines 45-48, replace `if ! pgrep -f kitty >/dev/null; then return; fi; kill -SIGUSR1 $(pidof kitty)` with `killall -SIGUSR1 kitty 2>/dev/null || true`. Add idempotent alignment in `bootstrap.sh` following the GTK 4 template sanitization pattern (`[FIX] Aligned applycolor.sh Kitty process signaling`). — **Reversibility:** reversible

### Nyquist Validation & Test Harness (DEBT-07, DEBT-08)

- **D-08:** Phase 29 validation sign-off: Reconcile `29-VALIDATION.md` frontmatter to `status: validated`, `nyquist_compliant: true`, `wave_0_complete: true`, and mark all 6 tasks `✅ green` based on the 30/30 passing checks in `scripts/phase29-theme-data-contracts-assert.sh`. — **Reversibility:** reversible
- **D-09:** Dedicated Phase 30 assert harness: Author `scripts/phase30-tech-debt-assert.sh` supporting `--section <1-5>` with fail-closed structure:
  - Section 1: Kitty opacity 0.90 in `restow/kitty/` and `phase28` assert alignment.
  - Section 2: Virtualenv fallback in `bootstrap.sh` and hardened signaling in `applycolor.sh`.
  - Section 3: Nyquist compliance across all v0.5 phases (25–30) and `REQUIREMENTS.md` traceability.
  - Section 4: Strict verifier engine gate (`arch/dots-hyprland.sh verify --strict` exits 0 with `FAIL=0 FINDINGS=0`) and git porcelain status check.
  - Section 5: Full v0.5 regression sweep running `phase25`, `phase26`, `phase27`, `phase28`, and `phase29` assert scripts sequentially. — **Reversibility:** reversible
- **D-10:** Phase 30 validation contract: Author `30-VALIDATION.md` establishing Wave 0 harness mapping and `nyquist_compliant: true`. — **Reversibility:** reversible

### Traceability, Bookkeeping & Phase Exit Gate

- **D-11:** Register DEBT requirements in `REQUIREMENTS.md`: Add `DEBT-05` through `DEBT-08` under `### DEBT (Technical Debt & Validation Cleanup)` in `REQUIREMENTS.md`, mapping each to Phase 30 in the traceability table and bringing total v1 requirements from 15 to 19 (100% complete). — **Reversibility:** reversible
- **D-12:** Sync `ROADMAP.md`: Update Phase 30 requirements mapping to `DEBT-05`, `DEBT-06`, `DEBT-07`, `DEBT-08`. — **Reversibility:** reversible
- **D-13:** Plan breakdown: Structure Phase 30 into 2 focused plans:
  - Plan 30-01: Visual polish, environment fallback, and script signaling robustness (`DEBT-05`, `DEBT-06`).
  - Plan 30-02: Validation sign-off, Phase 30 assert harness, full regression sweep, and milestone closeout readiness (`DEBT-07`, `DEBT-08`). — **Reversibility:** reversible
- **D-14:** Mandatory phase exit gate: `scripts/phase30-tech-debt-assert.sh` passing all 5 sections with `FAIL=0 FINDINGS=0`, `arch/dots-hyprland.sh verify --strict` returning 0 violations, and byte-identical clean git working tree. — **Reversibility:** permanent invariant

### the agent's Discretion

- Specific bash function names and formatting inside `scripts/phase30-tech-debt-assert.sh`.
- Minor sed pattern optimization when aligning `applycolor.sh` and `kde-material-you-colors-wrapper.sh` in `bootstrap.sh`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Audits & Project Docs
- `.planning/v0.5-MILESTONE-AUDIT.md` — source catalog of all v0.5 technical debt, audit scores, and validation sign-off items
- `.planning/ROADMAP.md` §Phase 30 — goal, dependencies, and requirements mapping
- `.planning/REQUIREMENTS.md` — requirements traceability table and DEBT definitions
- `.planning/STATE.md` — accumulated phase decisions and state
- `.planning/milestones/v0.4-phases/24-address-tech-debt-bookkeeping-and-validation-cleanup/24-CONTEXT.md` — Phase 24 technical debt precedent

### Data Contracts & Configuration Trees
- `restow/kitty/.config/kitty/kitty.conf` — Kitty configuration containing background_opacity setting
- `guard-paths.tsv` — machine-readable data contract of all 8 guarded dynamic theme paths
- `collision-map.tsv` — machine-asserted collision map

### Orchestrator & Live Theme Scripts
- `bootstrap.sh` — root orchestrator with initial theme generation and template sanitization
- `~/.config/quickshell/ii/scripts/colors/applycolor.sh` — terminal theme generator and process signaling
- `~/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh` — KDE Material You colors wrapper
- `~/.config/quickshell/ii/scripts/colors/switchwall.sh` — wallpaper reload and theme dispatcher

### Verification Suites & Test Scripts
- `scripts/phase28-terminal-fuzzel-assert.sh` — Phase 28 terminal and launcher assert script
- `scripts/phase29-theme-data-contracts-assert.sh` — Phase 29 data contracts assert script
- `scripts/phase24-tech-debt-assert.sh` — Phase 24 tech debt assert harness (structure reference)
- `.planning/phases/29-theme-data-contracts-verification-bootstrap-integration/29-VALIDATION.md` — Phase 29 validation contract

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/phase24-tech-debt-assert.sh`: Provides the exact 5-section architecture (`--section <1-5>`, `pass`/`fail`/`finding` helpers, trap cleanup, porcelain snapshot comparison).
- `bootstrap.sh` sanitization pattern: Lines 603–611 demonstrate the idempotent `sed -i` pattern for aligning live template files during bootstrap.

### Established Patterns
- **Fail-closed assert suites:** Every phase owns an executable assert script (`scripts/phaseNN-*.sh`) with `set -euo pipefail` that returns non-zero on any failure.
- **Porcelain snapshots:** Assert scripts capture `git status --porcelain` before and after test runs to guarantee tests themselves never dirty the working tree.
- **Three-tree capture taxonomy:** `kitty` resides in `restow/kitty/` because upstream installer primitive `install_dir__sync` would destroy live symlinks.
- **Strict verification exit code binding:** `arch/dots-hyprland.sh verify --strict` must always exit 0 with `FAIL=0 FINDINGS=0`.

### Integration Points
- `bootstrap.sh` Step 6 (`capture_seed`): Executes `generate_initial_theme()`, where virtualenv export and script sanitization hooks take effect.
- `scripts/phase29-theme-data-contracts-assert.sh` Section 5: Runs `scripts/phase28-terminal-fuzzel-assert.sh`, requiring opacity assert alignment to remain green.

</code_context>

<specifics>
## Specific Ideas

- Ensure `phase28-terminal-fuzzel-assert.sh` includes a clear comment explaining that the expectation was updated from `0.85` to `0.90` to fulfill the user's preference recorded in `28-UAT.md`.
- In `applycolor.sh`, `killall -SIGUSR1 kitty 2>/dev/null || true` replaces the fragile `pgrep -f kitty` / `kill -SIGUSR1 $(pidof kitty)` construct cleanly.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed strictly within the technical debt and validation sign-off scope cataloged in `.planning/v0.5-MILESTONE-AUDIT.md`.

</deferred>

---

*Phase: 30-address-tech-debt-v0-5-cleanup-and-validation-sign-off*
*Context gathered: 2026-09-18*
