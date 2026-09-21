# Phase 36: Visual Voice Pill Component & Dynamic Animations - Pattern Map

**Mapped:** 2026-09-21  
**Files analyzed:** 2  
**Analogs found:** 2 / 2  

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml` | component / status bar pill | reactive property binding / unidirectional data flow | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` | exact (container foundation) |
| `scripts/phase36-voice-pill-assert.sh` | test / verification harness | batch / headless Quickshell assertion | `scripts/phase35-voice-telemetry-assert.sh` | exact |

---

## Pattern Assignments

### `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml` (component, reactive property binding)

**Primary Container & Geometry Analog:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml`  
**Icon Glyph Renderer Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/MaterialSymbol.qml`  
**Typography Renderer Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/StyledText.qml`  
**Theming Tokens & Easing Curves Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml`  
**Telemetry Service Integration Analog:** `restow/quickshell/.config/quickshell/ii/services/Voice.qml`  
**Adjacent Status Bar Pill Analogs:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml`, `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml`, `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml`

---

#### 1. Header Pragmas & Imports Pattern
From `restow/quickshell/.config/quickshell/ii/services/Voice.qml` (lines 2-7) and `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` (lines 1-4):

```qml
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
```

*Rationale:*
- `pragma ComponentBehavior: Bound` enforces compile-time property resolution and type safety in Qt Quick 6.
- `qs.modules.common` provides `Appearance` (theming, fonts, curves) and `Config` (user preferences).
- `qs.modules.common.widgets` provides `MaterialSymbol` and `StyledText`.
- `qs.services` provides the `Voice` singleton service (`Voice.overallState`, `Voice.formattedDuration`, etc.) and `Translation`.

---

#### 2. Root Component Declaration & Container Geometry Pattern
From `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` (lines 5-11, 23-34):

```qml
BarGroup {
    id: root

    clip: true

    // Internal State Tracking
    property string previousState: "idle"
    property string lastRecordedDuration: "0:00"
    readonly property bool inWrapUp: wrapUpTimer.running

    // Effective Lifecycle State (Sequential Linear Flow)
    readonly property string effectiveState: {
        if (inWrapUp) return "wrapup";
        return Voice.overallState;
    }
```

*Rationale:*
- Subclassing `BarGroup` directly inherits the standard status bar rounded-rectangle geometry (`radius: Appearance.rounding.small` = 12px), default padding (`padding: 5`), base bar height (`Appearance.sizes.baseBarHeight`), and container background coloration (`Appearance.colors.colLayer1`).
- `clip: true` ensures that during width animations and borderless transparent transitions, child elements do not bleed outside the pill bounds.

---

#### 3. Dynamic Material You Palette Mapping Pattern (D-09)
From `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` (lines 123, 148, 157, 166):

```qml
    // Dynamic Material You Palette Mapping (D-09, zero hardcoded hex colors)
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
```

*Rationale:*
- Strictly binds to Matugen-generated tokens derived dynamically from the active wallpaper.
- `recording`: `colPrimary` (primary accent, high energy).
- `transcribing`: `colTertiary` (tertiary accent, processing).
- `typing` & `speaking`: `colSecondary` (secondary accent, delivery / speech output).
- `idle`: `colOnLayer1` (standard resting status bar text/icon color).
- Zero hardcoded `#hex` values.

---

#### 4. Sequential Linear Flow Text Formatting Pattern (D-06, D-07, VOICE-05)
From `restow/quickshell/.config/quickshell/ii/services/Voice.qml` (lines 43-52, 23-30) and `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Translation.qml`:

```qml
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
```

*Rationale:*
- In `idle` state, `displayText` is empty string (`""`) and `isExpanded` is `false`, collapsing the pill to resting icon width.
- In `recording` and `speaking`, live duration counts up (`0:05`, `0:06`).
- In `transcribing` and `typing`, localized status badges indicate progress.
- In `wrapup`, cached final duration (`lastRecordedDuration`) lingers for operator review.

---

#### 5. Responsive Width Calculation & M3 Deceleration Override Pattern (D-04, VOICE-06, Pitfall 1)
From `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` (lines 9-21):

```qml
    // Responsive Width Binding with M3 250ms Emphasized Deceleration (D-04, VOICE-06)
    // Overriding implicitWidth on root BarGroup directly triggers BarGroup's native
    // Behavior on implicitWidth { duration: 250; easing.bezierCurve: Appearance.animationCurves.emphasizedDecel }
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (
        voiceIcon.implicitWidth + (isExpanded ? (voiceLabel.implicitWidth + 4) : 0) + padding * 2
    )
```

*Native `BarGroup.qml` animation behavior inherited automatically:*
```qml
    Behavior on implicitWidth {
        enabled: !root.vertical
        NumberAnimation {
            duration: 250
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
        }
    }
```

*Rationale:*
- Bypasses Qt 6.11 `GridLayout.implicitWidth` caching bug where toggling child visibility leaves width frozen.
- Binding calculated content width directly to `implicitWidth` on the root `BarGroup` triggers the inherited 250ms `emphasizedDecel` animation smoothly on every state shift.
- In `idle`, width is 26px (16px icon + 2×5px padding). In active states, width expands smoothly to 62px (timer), 86px (typing), or 125px (transcribing), then contracts back to 26px.

---

#### 6. Wrap-Up Linger Timer & Voice Telemetry Connections Pattern (D-06, Pitfall 4)
From `restow/quickshell/.config/quickshell/ii/services/Voice.qml` (lines 99-109) and `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml` (lines 22-27):

```qml
    // Completion Wrap-up Linger Timer (~1.5s per D-06)
    Timer {
        id: wrapUpTimer
        interval: 1500
        repeat: false
    }

    // React to Voice State Shifts & Duration Caching
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
```

*Rationale:*
- `Voice.qml` resets `formattedDuration` to `"0:00"` immediately upon entering `idle`. Caching `lastRecordedDuration` ensures the completion wrap-up state preserves the actual speech length.
- If a new recording starts while `wrapUpTimer` is lingering, `wrapUpTimer.stop()` aborts the linger immediately so telemetry reflects the new session without latency.

---

#### 7. Child Content Anchors & Positioning Pattern (Pitfall 2)
From `restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml` (lines 27-43) and `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml` (lines 41-56, 70-78):

```qml
    // Content Layout Container
    Item {
        id: contentContainer
        implicitWidth: voiceIcon.implicitWidth + (root.isExpanded ? (voiceLabel.implicitWidth + 4) : 0)
        implicitHeight: Appearance.font.pixelSize.normal
        anchors.verticalCenter: parent.verticalCenter
```

*Rationale:*
- Uses explicit relative anchors (`anchors.left: parent.left` and `anchors.left: voiceIcon.right; anchors.leftMargin: 4`) inside a container `Item` rather than dynamic `visible` toggling inside `GridLayout`, avoiding layout overlap and Qt repositioning glitches.

---

#### 8. AI Identity Icon & Color Transitions Pattern (D-02, D-03, VOICE-02)
From `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/MaterialSymbol.qml` (lines 4-21) and `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` (lines 255, 330-338):

```qml
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
```

*Rationale:*
- `MaterialSymbol` renders Google Material Symbols Rounded glyphs directly from `Appearance.font.family.iconMaterial`.
- `Appearance.animationCurves.expressiveEffects` (`[0.34, 0.80, 0.34, 1.00, 1, 1]`, 200ms) matches the upstream system design language for color state shifts.

---

#### 9. Gentle Breathing Pulse Animation Pattern (D-08, VOICE-03, Pitfall 3)
From `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/StyledText.qml` (lines 42-89) and `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml` (lines 93-99):

```qml
            // Gentle Breathing Pulse Animation (D-08, VOICE-03)
            SequentialAnimation {
                id: pulseAnimation
                running: root.effectiveState === "recording"
                loops: Animation.Infinite

                // Pitfall 3: Guarantee opacity resets to 1.0 on stop
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
```

*Rationale:*
- Gently oscillates opacity between 1.0 and 0.5 over 1000ms (500ms down, 500ms up) with `Easing.InOutSine` to communicate live audio capture.
- `onRunningChanged` handler explicitly resets `voiceIcon.opacity = 1.0` if recording halts abruptly mid-breath, preventing frozen partial opacities.

---

#### 10. Dynamic Telemetry Label & State Badges Pattern (D-06, VOICE-05)
From `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/StyledText.qml` (lines 4-23) and `restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml` (lines 38-42):

```qml
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

*Rationale:*
- `StyledText` utilizes `Appearance.font.pixelSize.small` (15px) for crisp status badges.
- `visible: root.isExpanded` coupled with 150ms opacity transition provides smooth cross-fading when entering or leaving active states.

---

### `scripts/phase36-voice-pill-assert.sh` (test, batch assertion)

**Primary Analog:** `scripts/phase35-voice-telemetry-assert.sh`  
**Secondary Analog:** `scripts/phase31-overlay-pill-assert.sh`  

---

#### 1. Script Header, Safety Gates & Working-Tree Isolation Pattern
From `scripts/phase35-voice-telemetry-assert.sh` (lines 1-53):

```bash
#!/usr/bin/env bash
# ===========================================================================
# Phase 36: Visual Voice Pill Component & Dynamic Animations Assert Harness
# Enforces: VOICE-01 through VOICE-06, D-01 through D-09
#
# Usage (from REPO_ROOT):
#   ./scripts/phase36-voice-pill-assert.sh [--section <1-6>] [-s <1-6>]
#
# Exit 0 if all hard asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
TMP_DIRS=()

cleanup() {
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  for dir in ${TMP_DIRS[@]+"${TMP_DIRS[@]}"}; do
    [[ -n "$dir" && -d "$dir" ]] && rm -rf "$dir" 2>/dev/null || true
  done
  return 0
}
trap cleanup EXIT
```

---

#### 2. CLI Section Flag Parser & Git Porcelain Invariance Pattern
From `scripts/phase35-voice-telemetry-assert.sh` (lines 55-94):

```bash
RUN_SECTION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-6]$ ]]; then
        echo "Error: --section requires an integer from 1 to 6" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-6>]"
      echo "  -s, --section <1-6>  Execute only the specified section"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p36-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p36-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"
```

---

#### 3. Headless Quickshell Runner Helper Pattern
From `scripts/phase35-voice-telemetry-assert.sh` (lines 95-116):

```bash
run_qs_test() {
  local qml_content="$1"
  local runtime_dir="${2:-}"
  local timeout_sec="${3:-2.5}"

  local runner_file
  runner_file="$(mktemp "${XDG_CONFIG_HOME}/quickshell/ii/p36_runner_XXXXXX.qml")"
  TMP_FILES+=("$runner_file")

  printf '%s\n' "$qml_content" > "$runner_file"

  local out=""
  if [[ -n "$runtime_dir" ]]; then
    out="$(XDG_RUNTIME_DIR="$runtime_dir" timeout "${timeout_sec}s" quickshell -p "$runner_file" 2>&1 || true)"
  else
    out="$(timeout "${timeout_sec}s" quickshell -p "$runner_file" 2>&1 || true)"
  fi

  rm -f "$runner_file" 2>/dev/null || true
  printf '%s\n' "$out"
}
```

---

#### 4. Section 1: Symlink & Packaging Integrity Pattern (VOICE-01, D-01)
From `scripts/phase31-overlay-pill-assert.sh` (lines 80-111) and `scripts/phase35-voice-telemetry-assert.sh` (lines 121-143):

```bash
# S1 asserts:
# 1. VoicePill.qml exists in restow tree
VOICE_PILL_REPO="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml"
# 2. VoicePill.qml is deployed as live symlink into ~/.config/
VOICE_PILL_LIVE="$XDG_CONFIG_HOME/quickshell/ii/modules/ii/bar/VoicePill.qml"
# 3. Ancestor directories remain real directories (no folding)
# 4. vendor/dots-hyprland working tree remains 100% clean
```

---

#### 5. Section 2: Component AST & Static Tokens Pattern (VOICE-02, D-02, D-03, D-05, D-09)
From `scripts/phase35-voice-telemetry-assert.sh` (lines 144-167) and `scripts/phase31-overlay-pill-assert.sh` (lines 170-204):

```bash
# S2 asserts via static inspection:
# 1. Zero hardcoded hex colors: grep -E "#[0-9a-fA-F]{3,8}" returns 0
# 2. Base container is BarGroup: grep -q "BarGroup"
# 3. AI soundwave icon: grep -q 'text: "graphic_eq"'
# 4. Material You palette token bindings: colPrimary, colTertiary, colSecondary, colOnLayer1
# 5. Easing curve binding: Appearance.animationCurves.emphasizedDecel (or inherited via BarGroup)
# 6. Wrap-up linger interval: interval: 1500
# 7. Absence of vertical wave bar sub-items (D-05)
```

---

#### 6. Section 3: Headless State Progression & Badging Pattern (VOICE-04, VOICE-05, D-06, D-07)
From `scripts/phase35-voice-telemetry-assert.sh` (lines 170-235):

```bash
# S3 asserts headless QML execution driving state progression:
# - idle: displayText == "", isExpanded == false, color == colOnLayer1
# - recording: displayText == Voice.formattedDuration ("0:05"), color == colPrimary
# - transcribing: displayText == "Transcribing...", color == colTertiary
# - typing: displayText == "Typing...", color == colSecondary
# - speaking: displayText == Voice.formattedDuration, color == colSecondary
# - wrapup: displayText == "0:05" (lingers for 1500ms), color == colSecondary
# - wrapup expiration: returns to idle ("")
```

---

#### 7. Section 4: M3 Emphasized Deceleration Width Resizing Pattern (VOICE-06, D-04)
From `scripts/phase31-overlay-pill-assert.sh` (lines 176-185):

```bash
# S4 asserts dynamic width transitions via headless Quickshell sampling:
# - idle resting implicitWidth is ~26px (16px icon + 10px padding)
# - expanded active implicitWidth expands to ~62px+
# - samples intermediate implicitWidth across 250ms to verify monotonic deceleration curve
# - contracts back to ~26px upon returning to idle
```

---

#### 8. Section 5: Breathing Pulse Animation & Opacity Invariants Pattern (VOICE-03, D-08)
From `scripts/phase35-voice-telemetry-assert.sh` (lines 271-318):

```bash
# S5 asserts breathing pulse behavior:
# - running condition is strictly (effectiveState === "recording")
# - opacity oscillates between 1.0 and 0.5 over 1000ms cycle
# - opacity safely resets to 1.0 when recording transitions to transcribing or idle
```

---

#### 9. Section 6: Git Working-Tree Invariance & Strict Verification Gate Pattern
From `scripts/phase35-voice-telemetry-assert.sh` (lines 589-612):

```bash
# Check working-tree invariance
porcelain_snapshot > "$PORCELAIN_AFTER"
if diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" >/dev/null; then
  pass "S6: Git working tree invariant before vs after test harness run"
else
  fail "S6: Git working tree churn detected during test run:"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

# Strict repository verification gate
info "Executing ./arch/dots-hyprland.sh verify --strict..."
VERIFY_OUT="$(./arch/dots-hyprland.sh verify --strict 2>&1 || true)"
if echo "$VERIFY_OUT" | grep -q "=== done: FAIL=0 FINDINGS=0 ==="; then
  pass "S6: arch/dots-hyprland.sh verify --strict passed with FAIL=0 FINDINGS=0"
else
  fail "S6: arch/dots-hyprland.sh verify --strict reported failures or findings:"
  printf '%s\n' "$VERIFY_OUT" | grep -E "(\[FAIL\]|\[FINDING\])" || true
fi
```

---

## Shared Patterns

### Pattern 1: BarGroup Container Extension & Width Animation Trigger
**Source:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml`  
**Apply to:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml`
```qml
BarGroup {
    id: root
    clip: true

    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (
        voiceIcon.implicitWidth + (isExpanded ? (voiceLabel.implicitWidth + 4) : 0) + padding * 2
    )
    // Inherits Behavior on implicitWidth { duration: 250; easing.bezierCurve: Appearance.animationCurves.emphasizedDecel }
}
```

### Pattern 2: Multi-State Dynamic Palette Mapping (Zero Hex Colors)
**Source:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml`  
**Apply to:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml`
```qml
readonly property color currentColor: {
    switch (effectiveState) {
        case "recording": return Appearance.colors.colPrimary;
        case "transcribing": return Appearance.colors.colTertiary;
        case "typing": return Appearance.colors.colSecondary;
        case "speaking": return Appearance.colors.colSecondary;
        case "wrapup": return Appearance.colors.colSecondary;
        default: return Appearance.colors.colOnLayer1;
    }
}
```

### Pattern 3: State Transition Wrap-Up Linger & Metric Caching
**Source:** `restow/quickshell/.config/quickshell/ii/services/Voice.qml` (typing linger timer)  
**Apply to:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml`
```qml
Timer {
    id: wrapUpTimer
    interval: 1500
    repeat: false
}
```

### Pattern 4: Breathing Pulse Animation with Safe Mid-Cycle Reset
**Source:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml` & `StyledText.qml`  
**Apply to:** `VoicePill.qml` (`voiceIcon`)
```qml
SequentialAnimation {
    id: pulseAnimation
    running: root.effectiveState === "recording"
    loops: Animation.Infinite
    onRunningChanged: {
        if (!running) voiceIcon.opacity = 1.0;
    }
    NumberAnimation { target: voiceIcon; property: "opacity"; to: 0.5; duration: 500; easing.type: Easing.InOutSine }
    NumberAnimation { target: voiceIcon; property: "opacity"; to: 1.0; duration: 500; easing.type: Easing.InOutSine }
}
```

### Pattern 5: Relative Anchoring Inside Container Item
**Source:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml` & `Resource.qml`  
**Apply to:** `VoicePill.qml` (`contentContainer`)
```qml
Item {
    id: contentContainer
    implicitWidth: voiceIcon.implicitWidth + (root.isExpanded ? (voiceLabel.implicitWidth + 4) : 0)
    implicitHeight: Appearance.font.pixelSize.normal

    MaterialSymbol { id: voiceIcon; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
    StyledText { id: voiceLabel; anchors.left: voiceIcon.right; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter }
}
```

---

## Anti-Patterns & Don't Hand-Roll

| Anti-Pattern | Why It Breaks | Required Existing Pattern |
|---|---|---|
| **Hardcoding Hex Colors** (`#ffffff`, `#7aa2f7`, `#FFA000`) | Breaks Matugen dynamic theming when switching wallpapers; violates D-09 and strict verifier checks. | Always use `Appearance.colors.colPrimary`, `colTertiary`, `colSecondary`, `colOnLayer1`. |
| **Relying on `GridLayout.implicitWidth` Dynamically** | Qt 6.11 caches `GridLayout.implicitWidth` when child elements toggle visibility, causing pill width to stay stuck at 177px. | Explicitly bind `implicitWidth` on the root `BarGroup` component to calculated content dimensions. |
| **Using Nested Positioners with Dynamic Visibility** | Placing dynamically toggled items directly in `Row` or `GridLayout` causes elements to render at `x = 0` overlapping the icon. | Wrap elements in a dedicated `Item` container using relative anchors (`voiceLabel.anchors.left: voiceIcon.right`). |
| **Unbounded Pulse Animation Opacity** | Stopping a `SequentialAnimation` without an `onRunningChanged` handler leaves `voiceIcon.opacity` frozen at partial opacity (0.5). | Attach `onRunningChanged: if (!running) voiceIcon.opacity = 1.0;` to restore full opacity unconditionally. |
| **Reading `Voice.formattedDuration` in Idle Wrap-Up** | `Voice.qml` resets `formattedDuration` to `"0:00"` on transition to `idle`, losing the final talk time. | Cache `lastRecordedDuration` in `VoicePill.qml` on `formattedDurationChanged` and display it during `wrapup`. |
| **Modifying Upstream Files in `vendor/dots-hyprland`** | Violates submodule boundary and causes `git status` churn, failing `./arch/dots-hyprland.sh verify --strict`. | Author all additions in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml`. |

---

## No Analog Found

*None. All files planned for creation or modification in Phase 36 have exact analogs in the existing repository codebase or tracked submodules.*

---

## Metadata

**Analog search scope:**
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/`
- `restow/quickshell/.config/quickshell/ii/services/`
- `scripts/phase*.sh`

**Files scanned:** 48  
**Pattern extraction date:** 2026-09-21  
