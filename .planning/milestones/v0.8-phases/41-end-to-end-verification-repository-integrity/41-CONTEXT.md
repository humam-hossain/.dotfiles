# Phase 41: End-to-End Verification & Repository Integrity - Context

**Gathered:** 2026-09-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 41 delivers comprehensive automated verification across all milestone v0.8 features (Phases 38, 39, 40, 40.1) and enforces strict repository cleanliness with zero working-tree churn:
1. All QML modifications deployed strictly via `restow/quickshell/` leaf symlinks without modifying `vendor/dots-hyprland` (`INTG-01`).
2. Automated assertion test harness (`scripts/phase41-interactions-assert.sh`) verifying power profile transitions, media popup positioning, notification dismissal, link opening, OTP parsing, clock padding, and volume ceiling (`INTG-02`).
3. Repository integrity verification (`arch/dots-hyprland.sh verify --strict`) exiting 0 with 0 findings and zero git working-tree churn (`INTG-03`).

</domain>

<decisions>
## Implementation Decisions

### Harness Architecture & Test Suite Execution
- **D-01:** Implement `scripts/phase41-interactions-assert.sh` as the Milestone v0.8 Integration & Verification Engine. By default (no arguments), it executes BOTH the high-level end-to-end integration tests AND invokes the 4 sub-harnesses (`phase38`, `phase39`, `phase40`, `phase40.1`) to provide a comprehensive, 100% verdict on milestone completion. It supports `--quick` / `--standalone` to skip sub-harnesses, and `--section <1-6>` for modular execution. — **Reversibility:** reversible
- **D-02:** Structure `scripts/phase41-interactions-assert.sh` into 6 modular sections matching each milestone domain + repository integrity:
  - Section 1: Restow symlink isolation (`INTG-01`)
  - Section 2: Power profiles daemon & quick-toggle (`POWER-01..03`)
  - Section 3: Media popup positioning & clamping (`MEDIA-01..02`)
  - Section 4: Notification dismissal, URL navigation & OTP parsing (`NOTIF-01..02`, `NAV-01..02`, `OTP-01..02`)
  - Section 5: Clock padding & volume ceiling contract (`CLOCK-01`, `VOL-01..02`)
  - Section 6: Repository integrity & `verify --strict` (`INTG-03`)
  — **Reversibility:** reversible
- **D-03:** Support standard GSD assert CLI flags: `--section/-s <1-6>`, `--syntax` (syntax gate via `bash -n`), `--quick` / `--standalone`, and standard `[PASS]`, `[FAIL]`, `[INFO]`, and `[SOFT]` output format with exit code reflecting the total failure count (`exit $FAIL`). — **Reversibility:** reversible

### Environment Resilience & Live Desktop Gating
- **D-04:** Two-tier gating (Hard AST + Soft Live): All static AST checks, leaf symlink audits, config JSON schema validity, and regex extraction unit matrices must fail hard (`[FAIL]`). Live IPC/D-Bus probes (e.g., active D-Bus responses, Wayland monitor queries, Quickshell IPC via `qs -c ii`) gracefully soft-skip (`[SOFT]`) if running in a non-graphical or inactive session. — **Reversibility:** reversible
- **D-05:** Prerequisite binaries check: All core tools (`bash`, `jq`, `node`, `lua`, `powerprofilesctl`, `wpctl`, `qs`) must be present on `$PATH` at execution start (failing hard if missing), ensuring the host environment is fully provisioned. — **Reversibility:** reversible
- **D-06:** Live Quickshell process detection and IPC queries must target the `-c ii` profile (`qs -c ii list` / `quickshell/ii/shell.qml`), preventing false negatives from bare `qs list`. — **Reversibility:** reversible

### Live Power Profile Cycling & Safe State Rollback
- **D-07:** In Section 2, perform atomic power profile transition testing: record the initial profile (`INITIAL_PROFILE=$(powerprofilesctl get)`), cycle through available profiles (`power-saver`, `balanced`, `performance`) verifying active D-Bus state at each step, and unconditionally restore `$INITIAL_PROFILE` via a `trap cleanup EXIT INT TERM` handler. — **Reversibility:** reversible

### Notification & OTP Interaction Testing
- **D-08:** Default to headless AST and regex unit execution for notification dismissal, URL navigation, and OTP extraction tests without cluttering the user's active display. Provide an optional `--live-notify` / `--live` flag to send a transient test notification (`notify-send -t 800 -a "Phase41Test" ...`) when manual desktop visual verification is desired. — **Reversibility:** reversible

### Working-Tree Churn & Repository Integrity
- **D-09:** Verify repository churn using a dual-layer check:
  1. Capture `git status --porcelain` before and after harness execution to assert zero *execution* churn (delta is empty).
  2. Verify `vendor/dots-hyprland` submodule has 0 uncommitted changes.
  Unrelated pre-existing modifications outside milestone v0.8 (`restow/dolphinrc/`, `lazy-lock.json`) are isolated and left untouched for milestone closeout. — **Reversibility:** reversible
- **D-10:** Execute `./arch/dots-hyprland.sh verify --strict` in Section 6, verifying that the command exits with code 0 AND that stdout explicitly reports `FAIL=0` and `FINDINGS=0`. Temporary test captures must use `mktemp` in `/tmp` and clean up via trap. — **Reversibility:** reversible

### Milestone Reporting & Verification Artifacts
- **D-11:** Author `41-VERIFICATION.md` to document Phase 41 assertion results (`INTG-01..03`) and compile a complete milestone v0.8 cross-phase summary table covering Phases 38, 39, 40, 40.1, and 41. — **Reversibility:** reversible

### the agent's Discretion
None — all gray areas and interaction patterns were explicitly discussed and decided with user alignment.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Test Harnesses & Tooling
- `scripts/phase38-power-profiles-assert.sh` — Baseline harness for power profile cycling and daemon system integration.
- `scripts/phase39-media-popup-assert.sh` — Baseline harness for media popup anchoring and coordinate boundary clamping.
- `scripts/phase40-notification-interaction-assert.sh` — Baseline harness for notification close button, body click URL navigation, and OTP parsing.
- `scripts/phase40.1-clock-volume-assert.sh` — Baseline harness for clock horizontal padding and single source of truth 150% volume ceiling.
- `arch/dots-hyprland.sh` — Repository verification and symlink management script (`verify --strict`).

### Configuration & Services Under Test
- `capture/ii/.config/illogical-impulse/config.json` — Desktop configuration containing `"audio": {"volumeCeiling": 1.5}`.
- `stow/hypr/.config/hypr/custom/keybinds.lua` — Hyprland custom keybindings consuming `volumeCeiling`.
- `restow/quickshell/.config/quickshell/ii/services/Audio.qml` — Centralized audio service managing `maxVolume` and `incrementVolume()`.

### Modified QML Leaf Components
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml` — Status bar clock widget with 10px horizontal breathing room.
- `restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml` — Media popup anchored to Media bar pill with coordinate clamping.
- `restow/quickshell/.config/quickshell/ii/modules/ii/sidebarRight/QuickSliders.qml` — Right sidebar volume slider bound to `Audio.maxVolume` with 100% stop notch.
- `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` — Right sidebar notification card with always-visible 'X' close button.
- `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` — Notification item with OTP "Copy [Code]" action chip and smart body click.
- `restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml` — Regex parser for OTP code extraction and URL extraction.
- `restow/quickshell/.config/quickshell/ii/modules/common/Config.qml` — Quickshell configuration singleton with `volumeCeiling`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `pass()`, `fail()`, `info()`, `finding()`, `soft()`: Standard logging helpers established across phase assert scripts.
- Temporary file management: `TMP_FILES=()`, `cleanup() { rm -f ...; }`, `trap cleanup EXIT INT TERM`.
- Pre-execution EUID guard: Fail closed if run as root (`[[ "${EUID:-$(id -u)}" -ne 0 ]]`).

### Established Patterns
- Restow symlink isolation: All QML modifications deployed via `restow/quickshell/` leaf symlinks without modifying `vendor/dots-hyprland` (`INTG-01`).
- Quickshell instance isolation: Quickshell daemon runs with `-c ii` flag (`qs -c ii list`).
- Dual-layer git churn detection: Verify zero net change in git status before and after script execution.

### Integration Points
- `powerprofilesctl get` / `powerprofilesctl set`: System power profile switching via D-Bus.
- `hyprctl monitors -j`: Live Wayland monitor geometry inspection.
- `wpctl get-volume @DEFAULT_AUDIO_SINK@`: PipeWire audio volume query.
- `./arch/dots-hyprland.sh verify --strict`: Canonical repository symlink and submodule auditor.

</code_context>

<specifics>
## Specific Ideas

- Safe power profile restoration:
  ```bash
  INITIAL_PROFILE=$(powerprofilesctl get 2>/dev/null || echo "balanced")
  trap 'powerprofilesctl set "$INITIAL_PROFILE" 2>/dev/null || true; cleanup' EXIT INT TERM
  ```
- Sub-harness execution matrix:
  ```bash
  for script in scripts/phase38-power-profiles-assert.sh \
                scripts/phase39-media-popup-assert.sh \
                scripts/phase40-notification-interaction-assert.sh \
                scripts/phase40.1-clock-volume-assert.sh; do
    "$script" || fail "Sub-harness $script failed"
  done
  ```

</specifics>

<deferred>
## Deferred Ideas

- Pre-existing uncommitted files outside milestone scope (`restow/dolphinrc/.config/dolphinrc` and `stow/nvim/.config/nvim/lazy-lock.json`) are deferred to milestone closeout staging.

</deferred>

---

*Phase: 41-end-to-end-verification-repository-integrity*
*Context gathered: 2026-09-25*
