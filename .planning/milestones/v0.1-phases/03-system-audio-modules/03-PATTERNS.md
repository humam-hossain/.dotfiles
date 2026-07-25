# Phase 3: System & Audio Modules - Pattern Map

**Mapped:** 2026-07-23
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.config/quickshell/modules/ii/bar/Resource.qml` | component | transform | same file (extend) | exact |
| `.config/quickshell/modules/ii/bar/Resources.qml` | component | request-response | same file (extend) | exact |
| `.config/quickshell/services/ResourceUsage.qml` | service | batch / poll | same file + `services/Network.qml` Process | exact / role-match |
| `.config/quickshell/services/Audio.qml` | service | event-driven | same file (extend) | exact |
| `.config/quickshell/modules/ii/bar/BarContent.qml` | component | request-response | same file indicators + `VolumeControl.qml` launch | exact / partial |
| `.config/quickshell/modules/common/Config.qml` | config | file-I/O | same file `bar.resources` / `audio.protection` | exact |
| `~/.config/illogical-impulse/config.json` | config | file-I/O | Phase 2 dual-write target | exact |
| `scripts/phase03-config-assert.py` | test | file-I/O | `scripts/phase02-config-assert.py` | exact |
| `.config/quickshell/modules/ii/screenCorners/ScreenCorners.qml` | component | request-response | same volume clamp path (must align 130%) | exact |

**Note:** `ResourcesPopup.qml` is **not productized** — only unhook from `Resources.qml` (leave file). Vertical bar `Resource*.qml` optional keep-in-sync only.

## Pattern Assignments

### `.config/quickshell/modules/ii/bar/Resource.qml` (component, transform)

**Analog:** same file — extend dual thresholds + custom label

**Imports pattern** (lines 1-4):
```qml
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
```

**Core single-threshold ring** (lines 6-33) — extend to dual ladder:
```qml
Item {
    id: root
    required property string iconName
    required property double percentage
    property int warningThreshold: 100
    // ADD: property int errorThreshold: 100
    // ADD: property string labelText: ""  // empty → default percent
    property bool shown: true
    property bool warning: percentage * 100 >= warningThreshold
    // TARGET: isError / isWarning; colPrimary:
    //   isError ? colError : isWarning ? colPrimary : colOnSecondaryContainer

    ClippedFilledCircularProgress {
        value: percentage
        colPrimary: root.warning ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer
        // ...
    }
}
```

**Label / TextMetrics footgun** (lines 52-69) — must widen for capacity strings:
```qml
TextMetrics {
    id: fullPercentageTextMetrics
    text: "100"  // REPLACE with labelText sample or "99.9/99.9 GB"
    font.pixelSize: Appearance.font.pixelSize.small
}
StyledText {
    id: percentageText
    text: `${Math.round(percentage * 100).toString()}`
    // TARGET: use labelText when set; CPU appends "%"; RAM/disk free/total
}
```

**No-button hover MouseArea** (lines 77-83) — keep inert; parent strip must not open popup:
```qml
MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    enabled: resourceRowLayout.x >= 0 && root.width > 0 && root.visible
}
```

---

### `.config/quickshell/modules/ii/bar/Resources.qml` (component, request-response)

**Analog:** same file — reorder, drop swap UI, force always-shown, unhook popup

**Imports + service binding** (lines 1-4, 22-46):
```qml
import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

// CURRENT order Memory → Swap → CPU; TARGET CPU → RAM → Disk
Resource {
    iconName: "memory"
    percentage: ResourceUsage.memoryUsedPercentage
    warningThreshold: Config.options.bar.resources.memoryWarningThreshold
}
Resource {
    iconName: "swap_horiz"  // REMOVE from bar (D-04); service may keep swap data
    // ...
}
Resource {
    iconName: "planner_review"
    percentage: ResourceUsage.cpuUsage
    shown: Config.options.bar.resources.alwaysShowCpu || !(MprisController.activePlayer?.trackTitle?.length > 0) || root.alwaysShowAllResources
    // TARGET: shown: true (D-05) for CPU/RAM/Disk
    warningThreshold: Config.options.bar.resources.cpuWarningThreshold
}
```

**ResourcesPopup host to remove** (lines 50-52) — D-09/D-25:
```qml
ResourcesPopup {
    hoverTarget: root
}
// TARGET: delete instance; prefer Item root or hoverEnabled: false; no click
```

**Root is MouseArea with hover** (lines 6-12) — pitfall for residual popup:
```qml
MouseArea {
    id: root
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    // TARGET: disable hover-as-popup affordance for Phase 3
}
```

---

### `.config/quickshell/services/ResourceUsage.qml` (service, batch/poll)

**Analog:** same file for CPU/RAM; `Network.qml` + local `findCpuMaxFreqProc` for Process/disk

**Singleton + props + format helper** (lines 1-36):
```qml
pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property real memoryTotal: 1
    property real memoryFree: 0
    property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real cpuUsage: 0
    // ADD: diskTotal, diskUsed, diskAvail, diskUsedPercentage (root /)

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }
    // EXTEND: formatBytes auto G/T for bar labels (D-15)
}
```

**Single Timer poll** (lines 62-97) — split multi-rate (D-08/D-14):
```qml
Timer {
    interval: 1
    running: true
    repeat: true
    onTriggered: {
        fileMeminfo.reload()
        fileStat.reload()
        // parse MemTotal/MemAvailable, cpu line delta → cpuUsage
        root.updateHistories()
        interval = Config.options?.resources?.updateInterval ?? 3000
        // TARGET: ~1s CPU, ~3s mem, ~10s disk (tick counter or multi-timer)
    }
}
FileView { id: fileMeminfo; path: "/proc/meminfo" }
FileView { id: fileStat; path: "/proc/stat" }
```

**Process + LANG=C pattern** (lines 103-117 same file; Network lines 244-256):
```qml
// ResourceUsage findCpuMaxFreqProc
Process {
    environment: ({ LANG: "C", LC_ALL: "C" })
    command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
    stdout: StdioCollector {
        onStreamFinished: { /* parse */ }
    }
}

// Network wifiStatusProcess — preferred argv style for df
Process {
    command: ["nmcli", "radio", "wifi"]
    environment: ({ LANG: "C", LC_ALL: "C" })
    stdout: StdioCollector {
        onStreamFinished: {
            root.wifiEnabled = text.trim() === "enabled";
        }
    }
}
// DISK TARGET: command: ["df", "-B1", "--output=size,used,avail,pcent", "/"]
// skip header; parse integers only
```

---

### `.config/quickshell/services/Audio.qml` (service, event-driven)

**Analog:** same file — auto-unmute, 130% clamp, optional openMixer

**PipeWire wrapper + mute controls** (lines 11-70):
```qml
import Quickshell.Services.Pipewire

Singleton {
    id: root
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00
    // ADD: readonly property real maxVolume: 1.30  // D-22

    function toggleMute() {
        Audio.sink.audio.muted = !Audio.sink.audio.muted
    }
    function toggleMicMute() {
        Audio.source.audio.muted = !Audio.source.audio.muted
    }

    function incrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step);
        // TARGET: unmute if muted (D-21); Math.min(maxVolume, ...) not 1
    }
    function decrementVolume() {
        // TARGET: unmute if muted on volume change; same step logic
        Audio.sink.audio.volume -= step;
    }
}
```

**Protection Connections** (lines 85-114) — also host auto-unmute on external volume change:
```qml
Connections {
    target: sink?.audio ?? null
    property bool lastReady: false
    property real lastVolume: 0
    function onVolumeChanged() {
        if (!Config.options.audio.protection.enable) return;
        // ... maxAllowedIncrease / maxAllowed clamps
        // ADD (outside or inside): if muted && volume actually changed → muted = false
        // Ensure maxAllowed dual-written ≥ 130 so protection cannot fight D-22
    }
}
```

**Mixer launch helper pattern** — copy from VolumeControl (not currently in Audio):
```qml
// modules/waffle/actionCenter/volumeControl/VolumeControl.qml lines 64-66
Quickshell.execDetached(["bash", "-c", Config.options.apps.volumeMixer]);
// Optional: Audio.openMixer() wrapping same call for BarContent middle/right
```

---

### `.config/quickshell/modules/ii/bar/BarContent.qml` (component, request-response)

**Analog:** same file indicators + right-scroll; VolumeControl for pavucontrol

**Resources placement left** (lines 110-113) — keep; strip content changes inside Resources:
```qml
Resources {
    alwaysShowAllResources: root.useShortenedForm === 2
    Layout.fillHeight: true
}
```

**Right-bar volume scroll** (lines 143-156) — keep D-20:
```qml
FocusedScrollMouseArea {
    id: barRightSideMouseArea
    onScrollDown: Audio.decrementVolume();
    onScrollUp: Audio.incrementVolume();
    onMovedAway: GlobalStates.osdVolumeOpen = false;
    // left-click still toggles sidebarRightOpen
}
```

**Mute/mic indicators** (lines 240-259) — enhance % + multi-button (D-18/19/23):
```qml
// CURRENT: icon-only MaterialSymbol + left-click toggle
MaterialSymbol {
    text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
    MouseArea {
        anchors.fill: parent
        z: 10
        onClicked: (mouse) => { Audio.toggleMute(); mouse.accepted = true; }
    }
}
// TARGET structure:
// Row { MaterialSymbol + StyledText visible when !muted with Math.round(volume*100)+"%" }
// MouseArea acceptedButtons: Left|Middle|Right
// Left → toggleMute/toggleMicMute; Middle/Right → volumeMixer execDetached
// Keep z: 10; mouse.accepted = true so sidebar RippleButton does not steal
```

**volumeMixer launch analog** (`VolumeControl.qml` 64-66):
```qml
Quickshell.execDetached(["bash", "-c", Config.options.apps.volumeMixer]);
```

---

### `.config/quickshell/modules/common/Config.qml` (config, file-I/O)

**Analog:** same file defaults dual-written with live JSON

**audio.protection** (lines 145-151):
```qml
property JsonObject audio: JsonObject {
    property JsonObject protection: JsonObject {
        property bool enable: false
        property real maxAllowedIncrease: 10
        property real maxAllowed: 99  // TARGET: 130 (D-22)
    }
}
```

**apps.volumeMixer** (line 163) — already correct for D-23:
```qml
property string volumeMixer: `~/.config/hypr/hyprland/scripts/launch_first_available.sh "pavucontrol-qt" "pavucontrol"`
```

**bar.resources** (lines 246-252):
```qml
property JsonObject resources: JsonObject {
    property bool alwaysShowSwap: true   // TARGET: false (bar UI hides swap)
    property bool alwaysShowCpu: true
    property int memoryWarningThreshold: 95  // TARGET: 75 + memoryErrorThreshold 95
    property int swapWarningThreshold: 85
    property int cpuWarningThreshold: 90     // TARGET: 40 + cpuErrorThreshold 80
    // ADD: diskWarningThreshold 80, diskErrorThreshold 95
}
```

**resources poll** (lines 461-464):
```qml
property JsonObject resources: JsonObject {
    property int updateInterval: 3000
    // ADD optional: memoryUpdateInterval 3000, diskUpdateInterval 10000; or keep counters
    property int historyLength: 60
}
```

---

### `~/.config/illogical-impulse/config.json` (config, file-I/O)

**Analog:** Phase 2 dual-write — live keys **shadow** Config.qml defaults

**Pattern:** Every new/changed key must be written into live JSON or UAT sees old CPU 90 / mem 95 / interval 3000 / maxAllowed 99.

**Recommended dual-write payload** (from RESEARCH):
```json
{
  "bar": {
    "resources": {
      "alwaysShowCpu": true,
      "alwaysShowSwap": false,
      "cpuWarningThreshold": 40,
      "cpuErrorThreshold": 80,
      "memoryWarningThreshold": 75,
      "memoryErrorThreshold": 95,
      "diskWarningThreshold": 80,
      "diskErrorThreshold": 95
    }
  },
  "resources": {
    "updateInterval": 1000,
    "memoryUpdateInterval": 3000,
    "diskUpdateInterval": 10000
  },
  "audio": {
    "protection": {
      "enable": false,
      "maxAllowed": 130
    }
  }
}
```

---

### `scripts/phase03-config-assert.py` (test, file-I/O)

**Analog:** `scripts/phase02-config-assert.py` (full file pattern)

**Structure to copy** (lines 1-75):
```python
#!/usr/bin/env python3
"""Phase 3 Wave 0 live-config asserts for BAR-05..08 keys."""
from __future__ import annotations

import json
import sys
from pathlib import Path

CONFIG_PATH = Path.home() / ".config" / "illogical-impulse" / "config.json"

def main() -> int:
    if not CONFIG_PATH.is_file():
        print(f"error: missing config file: {CONFIG_PATH}", file=sys.stderr)
        return 1
    try:
        config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"error: failed to load {CONFIG_PATH}: {exc}", file=sys.stderr)
        return 1
    try:
        # nested asserts with clear want messages
        workspaces = config["bar"]["workspaces"]  # phase2 style
        assert workspaces["shown"] == 4, f"... want 4"
    except KeyError as exc:
        print(f"config assert FAIL: missing key {exc}", file=sys.stderr)
        return 1
    except AssertionError as exc:
        print(f"config assert FAIL: {exc}", file=sys.stderr)
        return 1
    print("config asserts OK")
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

**Phase 3 assert targets:** `cpuWarningThreshold==40`, `cpuErrorThreshold==80`, `memoryWarningThreshold==75`, `memoryErrorThreshold==95`, `diskWarningThreshold==80`, `diskErrorThreshold==95`, `alwaysShowCpu is True`, intervals if dual-written, `audio.protection.maxAllowed >= 130`.

---

### `.config/quickshell/modules/ii/screenCorners/ScreenCorners.qml` (component, request-response)

**Analog:** same file — duplicate 100% clamp must not fight D-22

**Volume raise path** (lines 107-116):
```qml
onScrollUp: {
    // ...
    const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
    Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step);
    // TARGET: prefer Audio.incrementVolume() OR Math.min(Audio.maxVolume, ...)
}
```

---

## Shared Patterns

### Service singleton → widget bind (FWK-03)
**Source:** `ResourceUsage.qml` + `Resources.qml`  
**Apply to:** BAR-05..07 strip; BAR-08 binds `Audio.sink/source`  
```qml
Resource {
    percentage: ResourceUsage.cpuUsage
    warningThreshold: Config.options.bar.resources.cpuWarningThreshold
}
// Indicators:
text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
```

### Dual-write Config.qml + live config.json
**Source:** Phase 2 practice + `Config.qml` JsonObject defaults  
**Apply to:** all thresholds, intervals, maxAllowed  
**Validation:** `scripts/phase02-config-assert.py` → clone as `phase03-config-assert.py`

### Process metrics with LANG=C
**Source:** `ResourceUsage.qml` 103-108; `Network.qml` 244-256  
**Apply to:** disk `df -B1 --output=size,used,avail,pcent /`  
```qml
environment: ({ LANG: "C", LC_ALL: "C" })
command: ["df", "-B1", "--output=size,used,avail,pcent", "/"]
stdout: StdioCollector { onStreamFinished: { /* skip header */ } }
```

### App launch via Config.options.apps.*
**Source:** `VolumeControl.qml` 66; Config `apps.volumeMixer` 163  
**Apply to:** mute/mic middle/right click  
```qml
Quickshell.execDetached(["bash", "-c", Config.options.apps.volumeMixer]);
```

### Indicator MouseArea isolation
**Source:** `BarContent.qml` 245-258  
**Apply to:** enhanced mute/mic rows  
```qml
MouseArea {
    anchors.fill: parent
    z: 10
    // acceptedButtons: Left|Middle|Right
    onClicked: (mouse) => { /* ... */; mouse.accepted = true; }
}
```

### Volume clamp centralization
**Source:** `Audio.incrementVolume` (hard-cap 1.0 today); corners duplicate  
**Apply to:** all user raise paths  
- Prefer calling `Audio.incrementVolume` / shared `maxVolume`  
- Dual-write `protection.maxAllowed: 130`  
- Do not leave one path at `Math.min(1, …)`

### Appearance color tokens
**Source:** `Resource.qml` line 32 `Appearance.colors.colError`  
**Apply to:** dual-threshold ladder — `colError` for error tier; warning tier has no `colWarning` (RESEARCH: use `colPrimary` unless UAT says otherwise)

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | All Phase 3 surfaces extend existing ii files; disk Process is new logic but Process pattern exists in Network/ResourceUsage |

**Greenfield-ish logic only:** disk free/total parse + dual-threshold color ladder + auto-unmute on `onVolumeChanged` — implement inside existing analogs using RESEARCH code examples.

## Metadata

**Analog search scope:** `.config/quickshell/{services,modules/ii/bar,modules/common,modules/waffle,modules/ii/screenCorners}`, `scripts/phase02-config-assert.py`  
**Files scanned:** ~12 primary (Resource*, ResourceUsage, Audio, BarContent, Config, Network, VolumeControl, ScreenCorners, phase02 assert)  
**Pattern extraction date:** 2026-07-23
