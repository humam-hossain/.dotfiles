# Phase 36: Visual Voice Pill Component & Dynamic Animations - Research

**Date:** 2026-09-21  
**Status:** Completed  
**Domain:** Quickshell QML Component & Animation Architecture  
**Deliverable:** `36-RESEARCH.md` for Phase 36 planning  

---

<user_constraints>
## Locked Decisions

- **D-01 (Compact Resting Pill):** In `idle` state, the Voice pill remains visible on the status bar in a compact resting state displaying only the `graphic_eq` icon without text, timer, or badges, visually anchoring voice readiness. — **Reversibility:** reversible.
- **D-02 (AI Voice Identity Icon):** Use `graphic_eq` from Google Material Symbols Rounded (`ttf-material-symbols-variable-git`) rendered via `MaterialSymbol.qml` to represent voice/soundwave telemetry. — **Reversibility:** reversible.
- **D-03 (Idle Coloration):** The resting `graphic_eq` icon renders in default status bar text/icon color (`Appearance.colors.colOnLayer1`) to blend seamlessly with adjacent status bar widgets until voice activates. — **Reversibility:** reversible.
- **D-04 (M3 Width Resizing Transitions):** Width transitions between compact resting state and expanded telemetry state use standard `BarGroup.qml` 250ms Material 3 emphasized deceleration (`Appearance.animationCurves.emphasizedDecel`), smoothly expanding on voice activity and smoothly contracting back to the resting icon when returning to idle. — **Reversibility:** reversible.
- **D-05 (No Separate Waveform Bars):** Omit separate vertical equalizer bars to keep the pill minimal, clean, and elegant. Visual telemetry is conveyed directly by the `graphic_eq` icon coupled to reactive state transitions. — **Reversibility:** reversible.
- **D-06 (Sequential Linear Content Flow):** Implement Sequential Linear Flow to avoid rapid, jarring text cycling across fast transcription/typing stages:
  - **Recording / Speaking:** Displays `[graphic_eq]  M:SS` (live timer counting up second-by-second).
  - **Transcribing:** Cross-fades to `[graphic_eq]  Transcribing...`.
  - **Typing:** Cross-fades to `[graphic_eq]  Typing...`.
  - **Completion Wrap-up:** Displays the final total speech duration (`[graphic_eq]  M:SS`) for ~1.5s so the operator can review talk duration, then smoothly collapses back to resting `graphic_eq`. — **Reversibility:** reversible.
- **D-07 (TTS Playback Display):** During Kokoro TTS speech synthesis (`speaking`), the pill displays `[graphic_eq]  M:SS` with the live speech playback duration, matching the STT recording display style. — **Reversibility:** reversible.
- **D-08 (Recording Breathing Pulse):** During active recording, apply a gentle breathing pulse animation on the `graphic_eq` icon (opacity cycling 1.0 ↔ 0.5 over 1000ms) to subtly indicate live microphone capture without distracting the operator. — **Reversibility:** reversible.
- **D-09 (Distinct Dynamic State Palette):** Style the icon and dynamic text with distinct Material You palette tokens derived from the active wallpaper via Matugen:
  - `recording`: `Appearance.colors.colPrimary` (wallpaper primary accent)
  - `transcribing`: `Appearance.colors.colTertiary` (tertiary accent)
  - `typing` & `speaking`: `Appearance.colors.colSecondary` (secondary accent)
  - `idle`: `Appearance.colors.colOnLayer1` (standard bar text color)
  - Zero hardcoded hex colors. — **Reversibility:** reversible.

## Claude's Discretion

- Easing curves and opacity transitions for smooth text cross-fades between states.
- Exact spacing between `graphic_eq` icon and text label (standard 4px matching `BarGroup.qml` columnSpacing).
- Internal state timer logic for the 1.5s completion wrap-up linger before contracting to idle.

## Deferred Ideas

- **Phase 37 (Bar Layout Integration, Dual-Monitor Verification & Strict Packaging):**
  - Placement in `BarContent.qml` Right zone after Media (`mediaLoader`).
  - Dual-monitor testing across `DP-1` and `HDMI-A-1`.
  - Automated test harness `scripts/phase36-voice-pill-assert.sh`.
- **Future Milestone (v0.8+):**
  - Hover tooltips showing recent transcription previews.
  - Click interactions (cancel recording, toggle mute, voice picker).

</user_constraints>

---

<phase_requirements>
## Phase Requirements Mapping

| Requirement ID | Requirement Description | Implementation Strategy & Research Support |
|---|---|---|
| **VOICE-01** | User sees a dedicated `VoicePill.qml` status bar pill styled with `BarGroup.qml` rounded rectangle geometry (12–16px corner radius, 4–6px internal padding). | `VoicePill.qml` authored in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml` with `BarGroup` as root container, inheriting `radius: Appearance.rounding.small` (12px), `padding: 5` (5px), and `Appearance.colors.colLayer1` container background. [VERIFIED: restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml:8-34] |
| **VOICE-02** | Component displays an AI visual symbol (`graphic_eq` per D-02) rendered via `MaterialSymbol.qml` that matches the desktop shell's design language. | Renders Google Material Symbols Rounded glyph `graphic_eq` with `Appearance.font.pixelSize.normal` (16px) using `MaterialSymbol.qml`. Font is verified available via system packages. [VERIFIED: `fc-list` confirms `MaterialSymbolsRounded`] |
| **VOICE-03** | Component displays a reactive pulse animation and accent color change during active STT recording. | Gentle breathing pulse on `voiceIcon.opacity` cycling 1.0 ↔ 0.5 over 1000ms (500ms down, 500ms up, `Easing.InOutSine`) running strictly when `effectiveState === "recording"`. On stop, opacity resets to 1.0. Color changes dynamically via Matugen tokens. [VERIFIED: prototype animation test] |
| **VOICE-04** | Component displays multi-state reactive transitions (D-05 simplified: sequential linear flow without separate wave bars). | Reactive state engine binds to `Voice.overallState` and implements Sequential Linear Flow (`recording` -> `transcribing` -> `typing` -> `wrapup` -> `idle`). Separate vertical wave bars omitted per D-05. [VERIFIED: restow/quickshell/.config/quickshell/ii/services/Voice.qml:23-30] |
| **VOICE-05** | Component displays live duration text (`0:05`) while recording/speaking and status badges ("Transcribing...", "Typing...") during state transitions. | Dynamic text label binds to `Voice.formattedDuration` during `recording`/`speaking`, displays `"Transcribing..."` and `"Typing..."` badges during transitions, and holds final talk time for 1500ms during `wrapup`. [VERIFIED: prototype dynamic text test] |
| **VOICE-06** | Component smoothly transitions width between a compact resting state and an expanded active telemetry state using Material 3 250ms emphasized deceleration. | `BarGroup`'s native `Behavior on implicitWidth` (250ms `Appearance.animationCurves.emphasizedDecel`) animates width dynamically from 26px (idle resting icon) to ~62px (timer), ~125px (transcribing), ~86px (typing), and back to 26px. [VERIFIED: prototype intermediate animation samples] |

</phase_requirements>

---

## Validation Architecture

Nyquist verification enforces that all Phase 36 requirements and design decisions are verifiable via automated, deterministic checks without requiring human eyes or an active microphone session.

### 1. Verification Strategy
Phase 36 artifacts will be validated through a combination of:
1. **Static AST & Property Assertions**:
   - Zero hardcoded hex color codes (`grep -E "#[0-9a-fA-F]{3,8}"` returns 0).
   - Standard Material Symbols glyph token `text: "graphic_eq"`.
   - Presence of `BarGroup` pill container foundation.
   - Material You color token bindings: `colPrimary`, `colTertiary`, `colSecondary`, `colOnLayer1`.
   - Animation curve binding to `Appearance.animationCurves.emphasizedDecel` (250ms duration).
   - Linger timer duration of 1500ms (`wrapUpTimer`).
   - Breathing pulse cycle duration of 1000ms (500ms + 500ms).
2. **Headless Quickshell Runtime Execution (`quickshell -p`)**:
   - Launch an automated test runner driving mock states (`idle` → `recording` → `transcribing` → `typing` → `wrapup` → `idle`).
   - Assert `implicitWidth` expands and contracts according to M3 emphasized deceleration curve.
   - Assert `voiceIcon.opacity` pulses between 1.0 and 0.5 during `recording` and resets to 1.0 when idle/transcribing.
   - Assert label text reflects `Voice.formattedDuration`, `"Transcribing..."`, `"Typing..."`, and cached wrap-up duration.

### 2. Requirement to Verification Matrix

| Requirement | Target Property / Behavior | Verification Command / Check |
|---|---|---|
| **VOICE-01** | File exists at `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml`, uses `BarGroup` geometry (radius 12px, padding 5px) | `[[ -f restow/.../VoicePill.qml ]] && grep -q "BarGroup" restow/.../VoicePill.qml` |
| **VOICE-02** | Renders `graphic_eq` icon using `MaterialSymbol.qml` | `grep -q 'text: "graphic_eq"' restow/.../VoicePill.qml` |
| **VOICE-03** | Breathing pulse animation (1000ms cycle, 1.0 ↔ 0.5 opacity) active only during recording; opacity resets to 1.0 on stop; color binds to `colPrimary` | `grep -q 'from: 1.0' restow/.../VoicePill.qml && grep -q 'to: 0.5' restow/.../VoicePill.qml && quickshell -p runner.qml` asserting opacity cycle |
| **VOICE-04** | Sequential linear flow transitions across all 6 states (`idle`, `recording`, `transcribing`, `typing`, `speaking`, `wrapup`) without separate equalizer bars | `quickshell -p runner.qml` driving state machine sequence and asserting zero wave bar elements |
| **VOICE-05** | Live duration `M:SS` formatting during recording/speaking; status badges `"Transcribing..."` and `"Typing..."`; 1.5s wrapup linger | `quickshell -p runner.qml` verifying `displayText` matching expected tokens per state and `wrapUpTimer.interval === 1500` |
| **VOICE-06** | 250ms Material 3 emphasized deceleration width resizing between compact (26px) and expanded (62–125px) states | `quickshell -p runner.qml` sampling intermediate `implicitWidth` over 350ms to verify monotonic deceleration curve |

---

## Architecture Responsibility Map

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Desktop Shell Architecture                      │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   Voice CLI Daemon (/home/pera/github_repo/Voice/voice.py)             │
│        │                                                               │
│        ▼ emits PID & lifecycle tokens to tmpfs                         │
│   $XDG_RUNTIME_DIR/voice-stt/{recorder.pid, tts.pid}                   │
│        │                                                               │
│        ▼ non-blocking FileView observation + procfs validation         │
│   Voice.qml Singleton Service (services/Voice.qml)                     │
│   • overallState: "idle" | "recording" | "transcribing" | ...          │
│   • formattedDuration: "M:SS"                                          │
│   • elapsedSeconds: int                                                │
│        │                                                               │
│        ▼ consumed by property bindings                                 │
│   VoicePill.qml Component (modules/ii/bar/VoicePill.qml)   ◄── PHASE 36 │
│   • BarGroup pill container (12px radius, 5px padding)                 │
│   • graphic_eq Material Symbol                                         │
│   • Sequential Linear Flow controller & wrapUpTimer                    │
│   • 250ms M3 emphasized deceleration width resizing                    │
│   • 1000ms breathing pulse animation during recording                  │
│   • Matugen dynamic Material You palette tokens                        │
│        │                                                               │
│        ▼ positioned in status bar (Phase 37)                           │
│   BarContent.qml (modules/ii/bar/BarContent.qml)           ◄── PHASE 37 │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

| Component | Responsibility | Boundary & Invariants |
|---|---|---|
| `Voice.qml` | Authoritative voice telemetry, state detection, PID liveness, and duration tracking. [VERIFIED: restow/.../Voice.qml] | Singleton service; does NOT contain visual UI markup or positioning. |
| `VoicePill.qml` | Visual presentation of voice telemetry: compact pill, `graphic_eq` icon, dynamic width, pulse animation, and text badges. | Self-contained pill widget; does NOT alter `BarContent.qml` or perform process management. |
| `BarGroup.qml` | Reusable pill chrome container providing rounded background and 250ms `Behavior on implicitWidth`. [VERIFIED: restow/.../BarGroup.qml] | Shared by all status bar pills; provides `Appearance.rounding.small` and `padding: 5`. |
| `MaterialSymbol.qml` | Glyph rendering using Google Material Symbols font. [VERIFIED: vendor/.../MaterialSymbol.qml] | Renders variable font glyphs with `Appearance.font.family.iconMaterial`. |
| `Appearance.qml` | Dynamic theming tokens generated from active wallpaper via Matugen. [VERIFIED: vendor/.../Appearance.qml] | Centralized styling; zero hardcoded hex codes. |

---

## Standard Stack & Dependencies

- **Language / Framework:** QML (Qt Quick 6.11 / Quickshell 0.2.1). [VERIFIED: `quickshell --version`]
- **Import Packages:**
  - `qs.modules.common` (Provides `Appearance`, `Config`)
  - `qs.modules.common.widgets` (Provides `MaterialSymbol`, `StyledText`)
  - `qs.services` (Provides `Voice`, `Translation`)
  - `QtQuick` (Provides `Item`, `Rectangle`, `Timer`, `SequentialAnimation`, `NumberAnimation`, `ColorAnimation`)
  - `QtQuick.Layouts` (Available for layout integration)
  - `Quickshell` (Provides shell bindings)
- **Font Dependency:** Google Material Symbols Rounded (`ttf-material-symbols-variable-git`). [VERIFIED: `fc-list` confirms `/usr/share/fonts/ttf-material-symbols-variable/MaterialSymbolsRounded[...]`]
- **Component Pragma:** `pragma ComponentBehavior: Bound` for optimal QML compile performance and property resolution.

---

## Don't Hand-Roll

| Pattern / Need | What NOT to do | Upstream / Existing Solution |
|---|---|---|
| Pill background & rounding | Do NOT hand-roll a new Rectangle with custom radius and padding. | Inherit or wrap `BarGroup.qml`, which standardizes `Appearance.rounding.small` (12px), `padding: 5`, and `Appearance.colors.colLayer1`. [VERIFIED: BarGroup.qml:23-34] |
| Resizing width animation | Do NOT write custom duration/easing curves or manual width step timers. | Rely on `BarGroup.qml`'s native `Behavior on implicitWidth { duration: 250; easing.bezierCurve: Appearance.animationCurves.emphasizedDecel }`. [VERIFIED: BarGroup.qml:14-21] |
| Icon font rendering | Do NOT load raw TTF glyphs or use unicode escape codes. | Use `MaterialSymbol.qml` with `text: "graphic_eq"` and `iconSize: Appearance.font.pixelSize.normal`. [VERIFIED: MaterialSymbol.qml:4-21] |
| Color tokens | Do NOT use hardcoded hex strings (`#ffffff`, `#00ffff`). | Bind to `Appearance.colors.colPrimary`, `colTertiary`, `colSecondary`, and `colOnLayer1`. [VERIFIED: Appearance.qml:111-199] |
| Translation strings | Do NOT hardcode non-internationalized English strings without translation hooks. | Use `Translation.tr("Transcribing...")` and `Translation.tr("Typing...")` (or standard fallbacks). [VERIFIED: Translation.qml] |

---

## Common Pitfalls & Critical Discoveries

### Pitfall 1: Qt 6.11 `GridLayout` Implicit Width Caching Bug (CRITICAL)
- **Discovery:** In Qt 6.11 (tested on host system), `GridLayout.implicitWidth` is cached and does **NOT** update dynamically when child items toggle `visible: false` or change text/preferredWidth. In an initial test where `BarGroup` relied solely on `gridLayout.implicitWidth`, toggling text visibility left `bg.implicitWidth` stuck at 177px! [VERIFIED: `test_grid_debug4.qml` and `test_grid_iso.qml`]
- **Resolution:** In `VoicePill.qml`, explicitly bind `implicitWidth` to the calculated content width:
  ```qml
  implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (
      voiceIcon.implicitWidth + (effectiveState !== "idle" ? (voiceLabel.implicitWidth + 4) : 0) + padding * 2
  )
  ```
  Because `implicitWidth` is a property on `BarGroup`, overriding this binding causes `BarGroup`'s `Behavior on implicitWidth` to immediately intercept target changes and smoothly animate over 250ms with `emphasizedDecel`! Live verification proved intermediate values: 26px → 103px → 116px → 121px → 124px. [VERIFIED: `test_override_animation.qml`]

### Pitfall 2: Dynamic Child Positioning inside `BarGroup`
- **Discovery:** `BarGroup.qml` uses a `GridLayout` with `columns: -1`. If a child item toggles `visible: true` dynamically inside `GridLayout` or a raw `Row`, it can be placed at `x = 0` overlapping the icon because positioners do not recalculate layout without a relayout pass. [VERIFIED: `test_pill_row_timing.qml`]
- **Resolution:** Place content in a dedicated container `Item` inside `BarGroup`, using explicit relative anchors:
  - `voiceIcon.anchors.left: parent.left`
  - `voiceIcon.anchors.verticalCenter: parent.verticalCenter`
  - `voiceLabel.anchors.left: voiceIcon.right` with `anchors.leftMargin: 4`
  - `voiceLabel.anchors.verticalCenter: parent.verticalCenter`
  This guarantees `voiceLabel` is always exactly 4px to the right of `voiceIcon` at all times with zero overlap and zero QML layout warnings. [VERIFIED: `test_pill_anchors.qml`]

### Pitfall 3: Pulse Animation Mid-Cycle Opacity Freeze
- **Problem:** If a `SequentialAnimation` on `opacity` stops when `Voice.overallState` changes from `"recording"` to `"transcribing"`, the icon opacity may freeze at 0.5 or 0.7 mid-breath.
- **Resolution:** Handle `onRunningChanged`:
  ```qml
  SequentialAnimation {
      id: pulseAnim
      running: root.effectiveState === "recording"
      loops: Animation.Infinite
      onRunningChanged: {
          if (!running) voiceIcon.opacity = 1.0;
      }
      ...
  }
  ```
  This guarantees that exiting recording immediately restores full opacity (1.0).

### Pitfall 4: Wrap-Up Timer State Collisions
- **Problem:** `Voice.qml` resets `formattedDuration` to `"0:00"` when entering `idle`. If `VoicePill.qml` tries to read `Voice.formattedDuration` during the 1.5s wrap-up linger, it will display `"0:00"` instead of the final talk time!
- **Resolution:** `VoicePill.qml` caches `lastRecordedDuration`:
  ```qml
  property string lastRecordedDuration: "0:00"
  onOverallStateChanged: {
      if (Voice.overallState === "recording" || Voice.overallState === "speaking") {
          // Continuously track live duration
      }
  }
  ```
  Whenever `Voice.formattedDuration !== "0:00"`, update `lastRecordedDuration`. During `wrapup`, display `lastRecordedDuration`. If a new recording starts while `wrapUpTimer` is running, immediately call `wrapUpTimer.stop()` to preempt the linger without delay.

### Pitfall 5: Borderless / Transparent Shell Mode Bleeding
- **Problem:** When the bar is in `borderless` mode (`Config.options?.bar.borderless`), `BarGroup` sets its background to `transparent`. If child elements overflow during width animation, unclipped text could briefly appear over desktop windows.
- **Resolution:** Explicitly specify `clip: true` on `VoicePill.qml`. This ensures that during width contraction and expansion, all child graphics are strictly bounded by the pill boundary.

---

## Canonical Code Example: `VoicePill.qml`

The following implementation represents the authoritative component design verified against Quickshell 0.2.1:

```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

BarGroup {
    id: root

    clip: true

    // Internal State Tracking
    property string previousState: "idle"
    property string lastRecordedDuration: "0:00"
    readonly property bool inWrapUp: wrapUpTimer.running

    // Effective Lifecycle State
    readonly property string effectiveState: {
        if (inWrapUp) return "wrapup";
        return Voice.overallState;
    }

    // Dynamic Material You Palette Mapping (D-09)
    readonly property color currentColor: {
        switch (effectiveState) {
            case "recording": return Appearance.colors.colPrimary;
            case "transcribing": return Appearance.colors.colTertiary;
            case "typing": return Appearance.colors.colSecondary;
            case "speaking": return Appearance.colors.colSecondary;
            case "wrapup": return Appearance.colors.colSecondary;
            case "starting": return Appearance.colors.colPrimary;
            default: return Appearance.colors.colOnLayer1;
        }
    }

    // Dynamic Text Content Mapping (D-06, D-07)
    readonly property string displayText: {
        switch (effectiveState) {
            case "recording": return Voice.formattedDuration;
            case "speaking": return Voice.formattedDuration;
            case "transcribing": return Translation.tr("Transcribing...");
            case "typing": return Translation.tr("Typing...");
            case "wrapup": return lastRecordedDuration;
            case "starting": return Voice.formattedDuration;
            default: return "";
        }
    }

    readonly property bool isExpanded: effectiveState !== "idle"

    // Responsive Width Binding with M3 250ms Emphasized Deceleration (D-04, VOICE-06)
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (
        voiceIcon.implicitWidth + (isExpanded ? (voiceLabel.implicitWidth + 4) : 0) + padding * 2
    )

    // Completion Wrap-up Linger Timer (~1.5s per D-06)
    Timer {
        id: wrapUpTimer
        interval: 1500
        repeat: false
    }

    // React to Voice State Shifts
    Connections {
        target: Voice

        function onOverallStateChanged() {
            if (Voice.overallState === "recording" || Voice.overallState === "speaking") {
                wrapUpTimer.stop();
            } else if (Voice.overallState === "idle") {
                if (root.previousState === "typing" || root.previousState === "speaking") {
                    wrapUpTimer.restart();
                }
            } else {
                wrapUpTimer.stop();
            }
            root.previousState = Voice.overallState;
        }

        function onFormattedDurationChanged() {
            if (Voice.formattedDuration !== "0:00") {
                root.lastRecordedDuration = Voice.formattedDuration;
            }
        }
    }

    // Content Layout Container
    Item {
        id: contentContainer
        implicitWidth: voiceIcon.implicitWidth + (root.isExpanded ? (voiceLabel.implicitWidth + 4) : 0)
        implicitHeight: Appearance.font.pixelSize.normal

        // AI Identity Soundwave Icon (D-02, D-03)
        MaterialSymbol {
            id: voiceIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "graphic_eq"
            iconSize: Appearance.font.pixelSize.normal
            color: root.currentColor

            Behavior on color {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }

            // Gentle Breathing Pulse Animation (D-08, VOICE-03)
            SequentialAnimation {
                id: pulseAnimation
                running: root.effectiveState === "recording"
                loops: Animation.Infinite

                onRunningChanged: {
                    if (!running) voiceIcon.opacity = 1.0;
                }

                NumberAnimation {
                    target: voiceIcon
                    property: "opacity"
                    to: 0.5
                    duration: 500
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: voiceIcon
                    property: "opacity"
                    to: 1.0
                    duration: 500
                    easing.type: Easing.InOutSine
                }
            }
        }

        // Live Telemetry Label & State Badges (D-06, VOICE-05)
        StyledText {
            id: voiceLabel
            anchors.left: voiceIcon.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: root.displayText
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.currentColor
            visible: root.isExpanded
            opacity: root.isExpanded ? 1.0 : 0.0

            Behavior on color {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }
        }
    }
}
```

---

## Assumptions Log

| # | Assumption | Classification | Status & Evidence |
|---|---|---|---|
| 1 | `graphic_eq` glyph exists in Google Material Symbols font and renders via `MaterialSymbol.qml`. | [VERIFIED] | Verified via `fc-list` showing `MaterialSymbolsRounded` installed at `/usr/share/fonts/ttf-material-symbols-variable/` and tested live via Quickshell runner. |
| 2 | `BarGroup.qml`'s 250ms `Behavior on implicitWidth` will animate width changes if `implicitWidth` is bound on the root component. | [VERIFIED] | Tested live with intermediate timer samples: `T=0: 26px`, `T=50ms: 103px`, `T=100ms: 116px`, `T=300ms: 124px`. Monotonic emphasized deceleration curve confirmed. |
| 3 | Upstream `dots-hyprland` repository working tree remains 100% clean and unmodified. | [VERIFIED] | Submodule status at `vendor/dots-hyprland` verified 100% clean via `git status`. |
| 4 | `VoicePill.qml` layout insertion into `BarContent.qml` belongs in Phase 37, not Phase 36. | [VERIFIED] | Authoritatively locked in `36-CONTEXT.md` §Deferred Ideas ("Phase 37 owns layout insertion into BarContent.qml Right zone after Media"). |
| 5 | Stowing `VoicePill.qml` via restow leaf symlink: `arch/dots-hyprland.sh verify --strict` requires all files in `restow/` to have live counterparts in `~/.config/`. | [VERIFIED] | Inspected `arch/dots-hyprland.sh:1001-1004`. Once `VoicePill.qml` is created in `restow/quickshell/`, `stow -d restow --no-folding -t ~ quickshell` deploys the symlink cleanly. |

---

## Planning Implications & Recommendations for Phase 36 Planner

1. **Single Execution Plan (36-01):**
   - Author `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml`.
   - Deploy leaf symlink via `stow -d restow --no-folding -t ~ quickshell`.
   - Implement headless Quickshell verification assert script (`scripts/phase36-voice-pill-assert.sh` or mock driver) asserting all 6 requirement IDs (VOICE-01 through VOICE-06).
   - Verify `arch/dots-hyprland.sh verify --strict` maintains 0 findings.
2. **Key Implementation Guards:**
   - Override `implicitWidth` explicitly on `BarGroup` root to bypass the Qt 6.11 `GridLayout` caching bug.
   - Use relative anchors (`anchors.left: voiceIcon.right; anchors.leftMargin: 4`) rather than nested positioners.
   - Ensure `onRunningChanged` on the pulse animation resets `voiceIcon.opacity = 1.0`.
   - Ensure `wrapUpTimer` lingers for 1500ms after typing/speaking before collapsing to idle.

---

*Research completed: 2026-09-21*  
*Phase: 36-visual-voice-pill-component-dynamic-animations*
