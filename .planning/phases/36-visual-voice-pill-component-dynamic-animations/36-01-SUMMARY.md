---
phase: 36-visual-voice-pill-component-dynamic-animations
plan: 01
subsystem: ui
tags: [quickshell, qml, voice, animations, material-you, bargroup]

requires:
  - phase: 35-voice-telemetry-state-service-architecture
    provides: Voice.qml singleton service with overallState and formattedDuration
provides:
  - VoicePill.qml dedicated status bar pill component with dynamic animations and Matugen theming
  - scripts/phase36-voice-pill-assert.sh automated 6-section assertion test harness
affects: [37-status-bar-layout-integration-packaging]

actuals:
  tokens: 2200
  tasks: 3
  commits: 1

tech-stack:
  added: []
  patterns: [BarGroup pill geometry inheritance, responsive root implicitWidth M3 animated binding, breathing pulse opacity reset onRunningChanged, Sequential Linear Flow wrap-up linger]

key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml
    - scripts/phase36-voice-pill-assert.sh
  modified: []

key-decisions:
  - "D-01, D-02, D-03: Compact resting pill in idle displaying only graphic_eq MaterialSymbol in Appearance.colors.colOnLayer1"
  - "D-04, VOICE-06: Root implicitWidth directly bound to content dimensions (voiceIcon.implicitWidth + label width + padding * 2) driving BarGroup 250ms emphasized deceleration curve"
  - "D-05: Omitted vertical equalizer wave bars in favor of minimal graphic_eq iconography"
  - "D-06, D-07, VOICE-05: Sequential Linear Flow with 1500ms wrap-up linger caching lastRecordedDuration"
  - "D-08, VOICE-03: Gentle breathing pulse animation (1.0 <-> 0.5 opacity over 1000ms) with fail-safe onRunningChanged reset to 1.0"
  - "D-09: Dynamic Material You palette tokens (colPrimary for recording, colTertiary for transcribing, colSecondary for typing/speaking/wrapup, colOnLayer1 for idle)"

patterns-established:
  - "VoicePill QML Component: Subclassing BarGroup with root implicitWidth override to bypass Qt 6.11 GridLayout caching"
  - "Resources array declaration: Placing Timer and Connections in resources: [] on BarGroup root to avoid default property item conflicts"
  - "Layout.alignment: Using Layout.alignment on child container Item inside GridLayout instead of undefined anchors"

requirements-completed:
  - VOICE-01
  - VOICE-02
  - VOICE-03
  - VOICE-04
  - VOICE-05
  - VOICE-06

coverage:
  - id: D1
    description: "Dedicated VoicePill.qml status bar component extending BarGroup with compact idle resting state"
    requirement: "VOICE-01"
    verification:
      - kind: unit
        ref: "./scripts/phase36-voice-pill-assert.sh --section 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "graphic_eq glyph rendering via MaterialSymbol with zero hardcoded hex colors"
    requirement: "VOICE-02"
    verification:
      - kind: unit
        ref: "./scripts/phase36-voice-pill-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D3
    description: "Breathing pulse animation cycling 1.0 <-> 0.5 opacity over 1000ms strictly during recording with clean reset"
    requirement: "VOICE-03"
    verification:
      - kind: unit
        ref: "./scripts/phase36-voice-pill-assert.sh --section 5"
        status: pass
    human_judgment: false
  - id: D4
    description: "Sequential Linear Flow state transitions across recording, transcribing, typing, speaking, and wrapup"
    requirement: "VOICE-04"
    verification:
      - kind: integration
        ref: "./scripts/phase36-voice-pill-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D5
    description: "Live duration (M:SS) display during recording/speaking and status badges with 1.5s wrap-up linger"
    requirement: "VOICE-05"
    verification:
      - kind: integration
        ref: "./scripts/phase36-voice-pill-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D6
    description: "Material 3 250ms emphasized deceleration width resizing between 26px and expanded active states"
    requirement: "VOICE-06"
    verification:
      - kind: unit
        ref: "./scripts/phase36-voice-pill-assert.sh --section 4"
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-09-21
status: complete
---

# Phase 36: Visual Voice Pill Component & Dynamic Animations Summary

**Dedicated `VoicePill.qml` status bar component with Google Material Symbols `graphic_eq` iconography, dynamic Material You palette tokens, gentle breathing pulse animation, Sequential Linear Flow with 1.5s wrap-up linger, and fluid 250ms Material 3 emphasized deceleration width expansion.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-21T12:02:14Z
- **Completed:** 2026-09-21T12:11:10Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Authored `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml` inheriting `BarGroup.qml` pill geometry (12px radius, 5px padding, `colLayer1` container) and deployed as a leaf symlink to `/home/pera/.config/quickshell/ii/modules/ii/bar/VoicePill.qml` via GNU Stow without directory folding.
- Rendered Google Material Symbols Rounded `graphic_eq` icon via `MaterialSymbol.qml` with dynamic Material You palette shifts across lifecycle states (`colPrimary`, `colTertiary`, `colSecondary`, `colOnLayer1`) with zero hardcoded hex colors.
- Implemented gentle breathing pulse animation (`1.0 <-> 0.5` opacity over 1000ms using `Easing.InOutSine`) active strictly during active STT recording, featuring an unconditional `onRunningChanged` guard that immediately restores 1.0 opacity on stop.
- Implemented Sequential Linear Flow state engine binding to `Voice.overallState` and `Voice.formattedDuration`, displaying live timers (`M:SS`) during recording/speaking, localized status badges (`"Transcribing..."`, `"Typing..."`) during transitions, and holding final talk duration for 1500ms via `wrapUpTimer` before returning to idle.
- Bypassed Qt 6.11 `GridLayout` caching by binding content dimensions directly to root `implicitWidth`, driving smooth 250ms Material 3 emphasized deceleration resizing between compact resting width (26px) and expanded states (63–125px).
- Built automated 6-section test suite `scripts/phase36-voice-pill-assert.sh` validating syntax, AST tokens, headless state progression, width resizing, pulse invariants, git working-tree invariance, and strict repository verification.

## Task Commits

1. **Task 1: End-to-end VoicePill component tracer slice, test harness scaffold, and geometry/iconography integration** - `239d584` (feat)
2. **Task 2: Breathing pulse animation with mid-cycle opacity reset and active recording/speaking transitions** - Verified in `239d584` & Section 5 test harness
3. **Task 3: Sequential Linear Flow state engine, completion wrap-up linger, and full regression verification** - Verified in `239d584` & full assert test suite

## Files Created/Modified

- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml` - Dedicated voice status bar pill component extending BarGroup with M3 animations, theming, and telemetry bindings
- `scripts/phase36-voice-pill-assert.sh` - Automated 6-section headless Quickshell assertion test harness

## Decisions Made

- Placed non-visual QML objects (`Timer`, `Connections`) inside `resources: []` on `BarGroup` root to avoid type mismatch collisions with `BarGroup`'s default property `items: gridLayout.children`.
- Used `Layout.alignment: Qt.AlignVCenter` on `contentContainer` within `BarGroup`'s `GridLayout` to eliminate Qt Quick anchor warnings on layout-managed items.
- Configured wrap-up duration cache in `VoicePill.qml` via `onFormattedDurationChanged` to preserve the actual elapsed talk time for 1.5s even after `Voice.qml` resets its internal timer to `"0:00"` on entering `idle`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Default property items collision with non-Item objects**
- **Found during:** Task 1 (Headless Quickshell component loading)
- **Issue:** `BarGroup` sets `default property alias items: gridLayout.children` which expects `QQuickItem`. Declaring `Timer` and `Connections` directly in the root caused `Cannot assign object of type "QQmlTimer" to list property "items"`.
- **Fix:** Placed `wrapUpTimer` and `Connections` into `resources: [ ... ]` list property on `BarGroup`.
- **Files modified:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml`
- **Verification:** `quickshell -p` loaded `VoicePill.qml` with exit code 0.
- **Committed in:** `239d584`

**2. [Rule 1 - Bug] Anchor warning on layout-managed contentContainer**
- **Found during:** Task 1 (Initial component execution)
- **Issue:** `contentContainer` had `anchors.verticalCenter` inside `GridLayout`, producing `Detected anchors on an item that is managed by a layout`.
- **Fix:** Replaced `anchors.verticalCenter` with `Layout.alignment: Qt.AlignVCenter`.
- **Files modified:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml`
- **Verification:** Warning eliminated completely from Quickshell log output.
- **Committed in:** `239d584`

**3. [Rule 1 - Bug] Subshell pipe hang during mock process spawning in test harness**
- **Found during:** Task 1 (Section 4 execution)
- **Issue:** `spawn_mock_voice` inside a command substitution `$(spawn_mock_voice)` held standard output open and blocked bash subshell execution indefinitely.
- **Fix:** Refactored mock process spawning to execute directly in the test section's shell without subshell capture.
- **Files modified:** `scripts/phase36-voice-pill-assert.sh`
- **Verification:** Section 4 and full test suite executed synchronously in < 4 seconds.
- **Committed in:** `239d584`

---

**Total deviations:** 3 auto-fixed (3 bug fixes)
**Impact on plan:** All auto-fixes necessary for runtime correctness, clean logging, and automated test execution. No scope creep.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `VoicePill.qml` is fully validated, themed, animated, and deployed as a live symlink.
- Ready for Phase 37: Status Bar Layout Integration, Dual-Monitor Placement (`BarContent.qml`), and Strict Packaging.

## Self-Check: PASSED
