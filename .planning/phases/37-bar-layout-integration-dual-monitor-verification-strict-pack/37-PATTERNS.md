# Phase 37: Bar Layout Integration, Dual-Monitor Verification & Strict Packaging - Pattern Map

**Mapped:** 2026-09-21  
**Files analyzed:** 3  
**Analogs found:** 3 / 3 (100% exact coverage)  

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | component | event-driven | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | exact |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml` | component | event-driven | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml` + `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml` | exact |
| `scripts/phase37-voice-pill-assert.sh` | test | batch | `scripts/phase36-voice-pill-assert.sh` | exact |

---

## Pattern Assignments

### `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` (component, event-driven)

**Analog:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` (tracked in main repo)

**Imports Pattern** (lines 1-13):
Both `BarContent.qml` and `VoicePill.qml` reside in the same directory (`modules/ii/bar/`). Sibling components are already exposed by the module directory import (`import qs.modules.ii.bar`), so `VoicePill` requires no additional import.
```qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar
```

**Responsive Width Thresholds Pattern** (lines 17-18):
`BarContent` evaluates monitor logical width against `Appearance.sizes` thresholds: `0` (> 1200px), `1` (1000px–1200px), or `2` (<= 1000px).
```qml
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth
```

**Parent Click Interception Pattern** (lines 165-180):
`barRightSideMouseArea` covers the right status bar and toggles `sidebarRightOpen` on LeftButton click. Child widgets must swallow mouse events to prevent accidental sidebar toggling.
```qml
    MouseArea { // Right side (D-16: scroll handlers and hints removed)
        id: barRightSideMouseArea

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: middleSection.right
        anchors.right: parent.right
        implicitWidth: rightSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }
        }
```

**Right Zone Placement & Direct Declaration Pattern** (lines 191-230):
`VoicePill` is placed directly in `rightSectionRowLayout` immediately after `mediaLoader` with vertical centering (`Layout.alignment: Qt.AlignVCenter`) and explicit property binding (`useShortenedForm: root.useShortenedForm`). No wrapper `Loader` is needed because `VoicePill` is lightweight, self-contained, and already inherits `BarGroup`.
```qml
            Loader {
                id: mediaLoader
                Layout.alignment: Qt.AlignVCenter
                active: (root.useShortenedForm < 2) && (MprisController.activePlayer != null && (MprisController.activePlayer.trackTitle?.length > 0))
                visible: active

                sourceComponent: BarGroup {
                    Media {
                        visible: root.useShortenedForm < 2
                        Layout.fillWidth: true
                        Layout.maximumWidth: (root.useShortenedForm === 1) ? 140 : 200
                    }
                }
            }

            VoicePill {
                id: voicePill
                Layout.alignment: Qt.AlignVCenter
                useShortenedForm: root.useShortenedForm
            }

            Loader {
                id: updatesLoader
                Layout.alignment: Qt.AlignVCenter
                active: Updates.available && Updates.count > 0
                visible: active

                sourceComponent: BarGroup {
                    UpdatesButton {}
                }
            }
```

---

### `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml` (component, event-driven)

**Analog:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml` (tracked in main repo)  
**Supporting Event Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml` (tracked in submodule)

**Responsive Contract & Expansion Guard Pattern** (modifying lines 59-64):
Expose `property real useShortenedForm: 0`. Guard `isExpanded` with `useShortenedForm < 2 && !vertical` (D-02, D-04, D-08). When `useShortenedForm == 2` (such as rotated `HDMI-A-2` with 720px logical width) or vertical bar mode is active, text expansion is suppressed to keep the pill clamped to its resting 26px size (or baseVerticalBarWidth) while preserving the animated soundwave icon and reactive color shifts.
```qml
    // Multi-Monitor & Responsive Property Contract (D-02, D-08)
    property real useShortenedForm: 0

    // Dynamic Expansion Guard (D-02, D-04)
    readonly property bool isExpanded: effectiveState !== "idle" && useShortenedForm < 2 && !vertical

    // Responsive Width Binding with M3 250ms Emphasized Deceleration (D-04, VOICE-06, Pitfall 1)
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (
        voiceIcon.implicitWidth + (isExpanded ? (voiceLabel.implicitWidth + 4) : 0) + padding * 2
    )
```

**Inert MouseArea Event Swallowing Pattern** (D-05, D-06):
Modeled after `Media.qml` lines 29-43 and `BarGroup.qml` lines 10-12. Because `BarGroup` defines `default property alias items: gridLayout.children`, visual children default to being layout cells. The `MouseArea` MUST declare `parent: root` to attach directly to the root item, with `anchors.fill: parent`, `cursorShape: Qt.ArrowCursor`, `hoverEnabled: false`, and `onPressed: event => event.accepted = true` to consume all mouse clicks (Left, Middle, Right) without triggering `barRightSideMouseArea` or altering pointer styling.
```qml
    // Public Component Aliases for Telemetry & Verification
    readonly property alias inertMouseArea: inertMouseArea

    // Inert Telemetry Mouse Area (D-05, D-06, Pitfall 2)
    MouseArea {
        id: inertMouseArea
        parent: root
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.ArrowCursor
        hoverEnabled: false
        onPressed: event => event.accepted = true
    }
```

**Dynamic Palette Theming Pattern** (lines 33-44):
Zero hardcoded hex codes. All colors bind dynamically to Material You tokens via `Appearance.colors.*`.
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

---

### `scripts/phase37-voice-pill-assert.sh` (test, batch)

**Analog:** `scripts/phase36-voice-pill-assert.sh` (tracked in main repo)

**Script Harness Preamble & Cleanup Trap Pattern** (lines 12-50):
Enforces non-root execution, strict bash safety, trap cleanup of temporary files and background mock processes.
```bash
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
MOCK_PIDS=()

cleanup() {
  for pid in ${MOCK_PIDS[@]+"${MOCK_PIDS[@]}"}; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" 2>/dev/null || true
    fi
  done

  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true

  for dir in ${TMP_DIRS[@]+"${TMP_DIRS[@]}"}; do
    [[ -n "$dir" && -d "$dir" ]] && rm -rf "$dir" 2>/dev/null || true
  done

  return 0
}
trap cleanup EXIT
```

**CLI Argument Parsing Pattern** (lines 52-81):
Supports selective section runs (`-s <1-5>` or `--section <1-5>`) and static syntax/AST checks (`-c` or `--syntax`).
```bash
RUN_SECTION=0
SYNTAX_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-5>] [--syntax]"
      echo "  -s, --section <1-5>  Execute only the specified section"
      echo "  -c, --syntax         Execute static AST and syntax checks only"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done
```

**Git Working Tree Invariance Snapshot Pattern** (lines 83-96):
Captures git porcelain status before and after execution to guarantee zero working tree churn.
```bash
porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p37-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p37-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"
```

**Headless Quickshell Runner Pattern** (lines 110-130):
Spawns temporary QML test snippets under `$XDG_CONFIG_HOME/quickshell/ii/` and executes via `quickshell -p` with timeouts.
```bash
run_qs_test() {
  local qml_content="$1"
  local runtime_dir="${2:-}"
  local timeout_sec="${3:-4.5}"

  local runner_file
  runner_file="$(mktemp "${XDG_CONFIG_HOME}/quickshell/ii/p37_runner_XXXXXX.qml")"
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

**GNU Stow Leaf Symlink & Directory Non-Folding Verification Pattern** (lines 147-164):
Verifies that managed QML files are leaf symlinks pointing to `restow/quickshell` and ancestor directories are real directories (never directory symlinks).
```bash
  # Live symlink target check
  if [[ -L "$VOICE_PILL_LIVE" ]]; then
    target="$(readlink "$VOICE_PILL_LIVE")"
    if [[ "$target" == *"restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml"* ]]; then
      pass "S1: VoicePill.qml is deployed as live symlink into restow: $target"
    else
      fail "S1: VoicePill.qml symlink points elsewhere: $target"
    fi
  else
    fail "S1: VoicePill.qml is not a live symlink: $VOICE_PILL_LIVE"
  fi

  # Ancestor directory realness check (no directory folding)
  LIVE_BAR_DIR="$XDG_CONFIG_HOME/quickshell/ii/modules/ii/bar"
  if [[ -d "$LIVE_BAR_DIR" && ! -L "$LIVE_BAR_DIR" ]]; then
    pass "S1: Parent directory $LIVE_BAR_DIR is a real directory (no folding)"
  else
    fail "S1: Parent directory $LIVE_BAR_DIR is symlinked or missing (folded)"
  fi
```

**Headless Responsive Geometry & Mock Display Simulation Pattern** (from RESEARCH.md §Example 4):
Tests multi-monitor responsiveness headlessly across synthetic display modes (`useShortenedForm: 0`, `2` and `vertical: true`).
```bash
  QML_S3=$(cat << 'EOF'
import QtQuick
import Quickshell
import "modules/ii/bar"
import "services"

Scope {
    VoicePill {
        id: pillFull
        useShortenedForm: 0
    }
    VoicePill {
        id: pillNarrow
        useShortenedForm: 2
    }
    VoicePill {
        id: pillVert
        vertical: true
    }

    Component.onCompleted: {
        Voice.formattedDuration = "0:05";
        Voice.overallState = "recording";
        console.log("RESP_REC full=" + pillFull.isExpanded + " full_w=" + Math.round(pillFull.implicitWidth) +
                    " narrow=" + pillNarrow.isExpanded + " narrow_w=" + Math.round(pillNarrow.implicitWidth) +
                    " vert=" + pillVert.isExpanded + " vert_w=" + Math.round(pillVert.implicitWidth));
        Qt.quit();
    }
}
EOF
)
  OUT_S3="$(run_qs_test "$QML_S3")"
```

**Strict Repository Verification Gate Pattern** (lines 611-622):
Invokes `./arch/dots-hyprland.sh verify --strict` and verifies `=== done: FAIL=0 FINDINGS=0 ===`.
```bash
  if [[ "$SYNTAX_ONLY" -eq 0 ]]; then
    info "Executing ./arch/dots-hyprland.sh verify --strict..."
    VERIFY_OUT="$(./arch/dots-hyprland.sh verify --strict 2>&1 || true)"
    if echo "$VERIFY_OUT" | grep -q "=== done: FAIL=0 FINDINGS=0 ==="; then
      pass "S5: arch/dots-hyprland.sh verify --strict passed with FAIL=0 FINDINGS=0"
    else
      fail "S5: arch/dots-hyprland.sh verify --strict reported failures or findings:"
      printf '%s\n' "$VERIFY_OUT" | grep -E "(\[FAIL\]|\[FINDING\])" || true
    fi
  else
    pass "S5: [SKIPPED in --syntax mode] Strict repository verification gate"
  fi
```

---

## Shared Patterns

### 1. GNU Stow Leaf Symlink Packaging Without Directory Folding (INTG-02)
**Source:** `restow/README.md:63`, `scripts/phase36-voice-pill-assert.sh:147-164`  
**Apply to:** All deployed QML configurations (`BarContent.qml`, `VoicePill.qml`, `Voice.qml`)
```bash
# Packaging deployment command:
cd restow && stow --verbose=5 --no-folding -t ~ quickshell
```
- Real directories must be preserved at all ancestor levels (`~/.config/quickshell/ii/modules/ii/bar/`).
- Only individual leaf files are symlinks.
- Upstream submodule `vendor/dots-hyprland` must remain 100% pristine and unmodified.

### 2. Material You Palette Token Reactivity (INTG-03, D-12)
**Source:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml:33-44`, `guard-paths.tsv:18-25`  
**Apply to:** `VoicePill.qml` and all bar widgets
- Prohibit hardcoded hex colors (`grep -E "#[0-9a-fA-F]{3,8}"`).
- Map status states strictly to semantic palette tokens:
  - `recording`: `Appearance.colors.colPrimary`
  - `transcribing`: `Appearance.colors.colTertiary`
  - `typing` / `speaking` / `wrapup`: `Appearance.colors.colSecondary`
  - `idle`: `Appearance.colors.colOnLayer1`
- Verify theme adaptability non-destructively via static AST audits and in-memory headless property checks; never execute disk-mutating wallpaper switches (`switchwall.sh`) during test execution.

### 3. Inert Mouse Event Interception with Layout Isolation (D-05, D-06, Pitfall 2)
**Source:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml:29-43`, `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml:10-12`  
**Apply to:** `VoicePill.qml`
```qml
MouseArea {
    id: inertMouseArea
    parent: root
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    cursorShape: Qt.ArrowCursor
    hoverEnabled: false
    onPressed: event => event.accepted = true
}
```
- `parent: root` detaches the item from `BarGroup`'s internal `GridLayout`, eliminating `Anchors are not supported inside Layouts` warnings and preventing empty layout cells.
- `acceptedButtons: Qt.AllButtons` and `onPressed: event => event.accepted = true` consume Left, Right, and Middle clicks, stopping event propagation to parent `barRightSideMouseArea`.
- `hoverEnabled: false` and `cursorShape: Qt.ArrowCursor` keep the surface visually passive with zero hover styling.

### 4. Multi-Monitor Responsive Adaptation (D-01, D-02, D-03, D-04)
**Source:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml:17`, `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml:394-395`  
**Apply to:** `BarContent.qml` declaration and `VoicePill.qml` expansion logic
- `BarContent` computes `useShortenedForm` (`0`, `1`, `2`) based on screen width.
- `VoicePill` receives `useShortenedForm` and guards expansion: `isExpanded: effectiveState !== "idle" && useShortenedForm < 2 && !vertical`.
- When `useShortenedForm == 2` (e.g. rotated `HDMI-A-2` with 720px logical width) or `vertical: true`, text is suppressed while preserving the 26px resting pill with pulsing soundwave icon and reactive colors.

---

## No Analog Found

*None. All files have direct, high-fidelity analogs in the tracked repository tree.*

---

## Metadata

**Analog search scope:**
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/`
- `restow/quickshell/.config/quickshell/ii/services/`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/`
- `scripts/`
- `arch/`

**Files scanned:** 12  
**Pattern extraction date:** 2026-09-21  
