# Phase 2: Core Bar Modules - Pattern Map

**Mapped:** 2026-07-21
**Files analyzed:** 8 (create/modify set; most are in-place rewires)
**Analogs found:** 8 / 8 (all targets already exist; analogs = self + sibling ii patterns)

> Phase 2 is **config + layout rewiring**, not greenfield modules. Closest analog for each file is the file itself (keep stock ii patterns; change only order/keys/call-site props). Secondary analogs show dual-write and service→widget binding conventions.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.config/quickshell/modules/ii/bar/BarContent.qml` | component (layout shell) | request-response (UI layout / click toggles) | **self** + existing left/center/right regions in same file | exact (rewire) |
| `.config/quickshell/modules/common/Config.qml` | config | transform (defaults → FileView JSON) | **self** `time` / `tray` / `bar.workspaces` blocks | exact |
| `~/.config/illogical-impulse/config.json` (host live) | config | file-I/O | same keys as `Config.qml` (Phase 1 dual-write) | role-match |
| `.config/quickshell/modules/ii/bar/ClockWidget.qml` | component | request-response (bind + popup) | **self**; call-site override in `BarContent.qml` | exact (verify / optional default) |
| `.config/quickshell/modules/ii/bar/Workspaces.qml` | component | event-driven (Hyprland dispatch) | **self** (Phase 1 stock dispatch) | exact (verify only) |
| `.config/quickshell/modules/ii/bar/SysTray.qml` / `SysTrayItem.qml` | component | event-driven (SNI tray) | **self** + `TrayService.qml` | exact (config-driven monochrome) |
| `.config/quickshell/services/DateTime.qml` | service | transform (SystemClock → strings) | **self** | exact (verify only) |
| `.config/quickshell/services/Network.qml` | service | event-driven (nmcli → symbol) | **self** + bar `MaterialSymbol` bind | exact (verify only) |

**Out of scope (do not modify):** `ClockWidgetPopup.qml`, `TrayService.qml` pin logic (keep D-14), weather enable, Resources/Media/Battery implementations (reparent only), sidebar wifi panel internals.

## Pattern Assignments

### `.config/quickshell/modules/ii/bar/BarContent.qml` (component, layout rewire)

**Analog:** same file (stock ii three-region bar) — reparent existing children; do not invent new module files.

**Imports pattern** (lines 1–10):
```qml
import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
```

**Core layout pattern — three regions** (left LTR / center Row / right currently RTL):

Left region children today (lines 80–99) — **target D-15:** LeftSidebarButton → ActiveWindow → **Workspaces** → Resources:
```qml
RowLayout {
    id: leftSectionRowLayout
    anchors.fill: parent
    spacing: 0

    LeftSidebarButton { /* … */ }
    ActiveWindow {
        Layout.fillWidth: true
        visible: root.useShortenedForm === 0
    }
    // MOVE Workspaces + Resources here from center (D-15)
}
```

Center today hosts Resources + Media | Workspaces | Clock + UtilButtons + Battery (lines 102–187) — **target D-15:** ClockWidget → UtilButtons only (weather loader stays inactive via Config):
```qml
// Target center (sketch from RESEARCH):
BarGroup {
    ClockWidget {
        showDate: false  // D-08 — override verbose default
        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
    }
    UtilButtons {
        visible: (Config.options.bar.verbose && root.useShortenedForm === 0)
        Layout.alignment: Qt.AlignVCenter
    }
}
```

**Right section RTL pitfall** (lines 221–225) — visual L→R is reverse of declaration order:
```qml
RowLayout {
    id: rightSectionRowLayout
    anchors.fill: parent
    spacing: 5
    layoutDirection: Qt.RightToLeft
    // Children declared rightmost-first today: Indicators → SysTray → fill → Weather
}
```

**Recommended rewire (planner discretion, RESEARCH Pattern 3 option 2):** switch right section to LTR and declare Media → BatteryIndicator → SysTray → Indicators pill for D-15 auditability. Preserve volume scroll on `barRightSideMouseArea` and brightness scroll on left.

**Clock call-site anti-duplication** (lines 171–175 — **change**):
```qml
// CURRENT (causes longDate when bar.verbose):
ClockWidget {
    showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: true
}

// TARGET (D-08):
ClockWidget {
    showDate: false
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: true
}
```

**Indicators pill as single hit target** (lines 227–253) — keep whole pill; do not split Network:
```qml
RippleButton {
    id: rightSidebarButton
    toggled: GlobalStates.sidebarRightOpen
    onPressed: {
        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
    }
    // Network is a MaterialSymbol child only — not its own button (D-11)
}
```

**Indicators order today vs D-19** (lines 255–316):

| Current child order | Target (D-19 L→R) |
|---------------------|-------------------|
| mute Revealer | mute Revealer |
| mic Revealer | mic Revealer |
| HyprlandXkbIndicator | HyprlandXkbIndicator |
| NotificationUnreadCount Revealer | **Bluetooth MaterialSymbol** |
| Network MaterialSymbol | **Network MaterialSymbol** |
| Bluetooth MaterialSymbol | **NotificationUnreadCount Revealer** |

Network bind (keep D-09/D-10) lines 305–309:
```qml
MaterialSymbol {
    text: Network.materialSymbol
    iconSize: Appearance.font.pixelSize.larger
    color: rightSidebarButton.colText
}
```

Bluetooth (lines 310–316) — move before Network; keep `visible: BluetoothStatus.available` and `Layout.leftMargin` spacing normalized after reorder.

**Weather gate** (lines 332–340 — keep inactive):
```qml
Loader {
    Layout.leftMargin: 4
    active: Config.options.bar.weather.enable  // remains false (D-16)
    sourceComponent: BarGroup {
        WeatherBar {}
    }
}
```

**SysTray placement** (lines 320–325) — reparent into D-15 right order; keep shortened gate:
```qml
SysTray {
    visible: root.useShortenedForm === 0
    Layout.fillWidth: false
    Layout.fillHeight: true
    invertSide: Config?.options.bar.bottom
}
```

**Scroll / sidebar side effects to preserve:**
- Left `FocusedScrollMouseArea`: brightness + left-click left sidebar (lines 50–68)
- Right `FocusedScrollMouseArea`: volume + left-click right sidebar (lines 190–208)
- After Media/Battery move to right, they inherit volume scroll region (RESEARCH: acceptable)

---

### `.config/quickshell/modules/common/Config.qml` (config defaults)

**Analog:** same file JsonObject defaults (Phase 1 dual-write pattern).

**Workspaces defaults — already match D-01..D-03** (lines 263–271) — **no change**:
```qml
property JsonObject workspaces: JsonObject {
    property bool monochromeIcons: true
    property int shown: 10
    property bool showAppIcons: true
    // …
}
```

**Weather — already off D-16** (lines 272–273) — **no change**:
```qml
property JsonObject weather: JsonObject {
    property bool enable: false
```

**Tray — change monochrome only; keep pin policy D-13/D-14** (lines 466–471):
```qml
property JsonObject tray: JsonObject {
    property bool monochromeIcons: true  // TARGET: false (D-13 full-color)
    property bool showItemId: false
    property bool invertPinnedItems: true
    property list<var> pinnedItems: [ "Fcitx" ]
    property bool filterPassive: true
}
```

**Time — change format + secondPrecision D-05** (lines 566–578):
```qml
property JsonObject time: JsonObject {
    // https://doc.qt.io/qt-6/qtime.html#toString
    property string format: "hh:mm"           // TARGET: "ddd yyyy-MM-dd hh:mm:ss AP"
    property string shortDateFormat: "dd/MM"
    property string dateWithYearFormat: "dd/MM/yyyy"
    property string dateFormat: "ddd, dd/MM"
    // …
    property bool secondPrecision: false      // TARGET: true
}
```

Recommended values (RESEARCH discretion, PyQt6-verified):
```qml
property string format: "ddd yyyy-MM-dd hh:mm:ss AP"
property bool secondPrecision: true
```

---

### `~/.config/illogical-impulse/config.json` (live overrides)

**Analog:** Phase 1 learning — persisted FileView JSON **wins** over `Config.qml` defaults.

**Pattern:** Dual-write every key changed in `Config.qml`. Wave 0 assert snippet from RESEARCH:

```bash
python3 - <<'PY'
import json
from pathlib import Path
c = json.loads(Path.home().joinpath(".config/illogical-impulse/config.json").read_text())
assert c["bar"]["workspaces"]["shown"] == 10
assert c["bar"]["workspaces"]["showAppIcons"] is True
assert c["bar"]["workspaces"]["monochromeIcons"] is True
assert c["bar"]["weather"]["enable"] is False
assert c["time"]["secondPrecision"] is True
assert "ss" in c["time"]["format"] and ("AP" in c["time"]["format"] or "ap" in c["time"]["format"])
assert c["tray"]["monochromeIcons"] is False
assert c["tray"]["invertPinnedItems"] is True
assert "Fcitx" in c["tray"]["pinnedItems"]
print("config asserts OK")
PY
```

**Do not** only edit QML defaults — clock/tray will stay stale.

---

### `.config/quickshell/modules/ii/bar/ClockWidget.qml` (component, verify / optional default)

**Analog:** self — service bind + popup (D-06 keep).

**Service → render (FWK-03)** (lines 19–37):
```qml
StyledText {
    font.pixelSize: Appearance.font.pixelSize.large
    color: Appearance.colors.colOnLayer1
    text: DateTime.time
}
StyledText {
    visible: root.showDate
    text: DateTime.longDate
}
```

**Popup (D-06 — keep; no Google Calendar)** (lines 40–48):
```qml
MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    ClockWidgetPopup {
        hoverTarget: mouseArea
    }
}
```

**Default `showDate`** (line 10):
```qml
property bool showDate: Config.options.bar.verbose
```
Planner preference: force `showDate: false` at **BarContent call site** (does not break other uses of verbose). Optional change of default here only if call site not enough.

---

### `.config/quickshell/services/DateTime.qml` (service, verify only)

**Analog:** self — SystemClock precision + Qt.locale format.

**Core pattern** (lines 13–24):
```qml
property var clock: SystemClock {
    id: clock
    precision: {
        if (Config.options.time.secondPrecision || GlobalStates.screenLocked)
            return SystemClock.Seconds;
        return SystemClock.Minutes;
    }
}
property string time: Qt.locale().toString(clock.date, Config.options?.time.format ?? "hh:mm")
property string longDate: Qt.locale().toString(clock.date, Config.options?.time.dateFormat ?? "dddd, dd/MM")
```

No code change required when Config keys flip. **Do not** hardcode timezone (D-07).

---

### `.config/quickshell/modules/ii/bar/Workspaces.qml` (component, verify only)

**Analog:** self — Phase 1 stock dispatch (D-04).

**Click / wheel** (lines 58–73):
```qml
function switchWorkspaceToHovered() {
    // Stock Hyprland dispatcher (hl.dsp.focus requires a plugin we do not ship)
    Hyprland.dispatch(`workspace ${wsModel.getWorkspaceIdAt(hoverIndex)}`);
}
onPressed: mouse => {
    if (mouse.button == Qt.LeftButton)
        switchWorkspaceToHovered();
    else if (mouse.button == Qt.RightButton)
        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
}
onWheel: event => {
    if (event.angleDelta.y < 0)
        Hyprland.dispatch("workspace r+1");
    else if (event.angleDelta.y > 0)
        Hyprland.dispatch("workspace r-1");
}
```

App icons / monochrome already read `Config.options.bar.workspaces.*` — no rewrite. Layout **position** changes only in `BarContent.qml`.

---

### `.config/quickshell/modules/ii/bar/SysTrayItem.qml` + `TrayService.qml` (component/service, config-driven)

**Analog:** self — monochrome branch already exists; flip Config only.

**Activate / menu** (SysTrayItem lines 25–36):
```qml
onPressed: (event) => {
    switch (event.button) {
    case Qt.LeftButton:
        item.activate();
        break;
    case Qt.RightButton:
        if (item.hasMenu)
            if (menu.active && menu.item && typeof menu.item.close === "function")
                menu.item.close();
            else
                menu.open();
        break;
    }
    event.accepted = true;
}
```

**Full-color vs monochrome** (lines 71–96) — D-13 needs `Config.options.tray.monochromeIcons === false`:
```qml
IconImage {
    id: trayIcon
    visible: !Config.options.tray.monochromeIcons
    source: root.item.icon
    // …
}
Loader {
    active: Config.options.tray.monochromeIcons
    // Desaturate + ColorOverlay
}
```

**Pin invert (D-14 keep)** — `TrayService.qml` lines 12–17:
```qml
property list<var> itemsInUserList: SystemTray.items.values.filter(i => (Config.options.tray.pinnedItems.includes(i.id) && …))
property list<var> itemsNotInUserList: SystemTray.items.values.filter(i => (!Config.options.tray.pinnedItems.includes(i.id) && …))
property bool invertPins: Config.options.tray.invertPinnedItems
property list<var> pinnedItems: invertPins ? itemsNotInUserList : itemsInUserList
property list<var> unpinnedItems: invertPins ? itemsInUserList : itemsNotInUserList
// invert:true + pinnedItems:["Fcitx"] → Fcitx blacklisted from always-visible strip
```

---

### `.config/quickshell/services/Network.qml` (service, verify only)

**Analog:** self — materialSymbol matrix (D-10).

**Icon matrix** (lines 37–54):
```qml
property string materialSymbol: root.ethernet
    ? "lan"
    : (root.wifiEnabled && root.wifiStatus === "connected")
        ? (
            (root.active?.strength ?? 0) > 83 ? "signal_wifi_4_bar" :
            (root.active?.strength ?? 0) > 67 ? "network_wifi" :
            (root.active?.strength ?? 0) > 50 ? "network_wifi_3_bar" :
            (root.active?.strength ?? 0) > 33 ? "network_wifi_2_bar" :
            (root.active?.strength ?? 0) > 17 ? "network_wifi_1_bar" :
            "signal_wifi_0_bar"
        )
        : (root.wifiStatus === "connecting")
            ? "signal_wifi_statusbar_not_connected"
            : (root.wifiStatus === "disconnected")
                ? "wifi_find"
                : (root.wifiStatus === "disabled")
                    ? "signal_wifi_off"
                    : "signal_wifi_bad"
```

Bar stays icon-only via `MaterialSymbol { text: Network.materialSymbol }`. SSID/detail: right sidebar (existing path). **Do not** add bar SSID text or new NetworkPopup.

---

## Shared Patterns

### Service singleton → widget render (FWK-03)
**Source:** `BarContent.qml` Network bind; `ClockWidget.qml` → `DateTime.time`  
**Apply to:** All BAR-01..04 surfaces (bind only; no new services)

```qml
// Network
MaterialSymbol { text: Network.materialSymbol; /* … */ }

// Clock
StyledText { text: DateTime.time }
```

### Config defaults + persisted override dual-write
**Source:** Phase 1 LEARNINGS + `Config.qml` FileView  
**Apply to:** `time.format`, `time.secondPrecision`, `tray.monochromeIcons`  
**Rule:** Update both `Config.qml` and `~/.config/illogical-impulse/config.json` (or flush via Config API).

### Right section layoutDirection awareness
**Source:** `BarContent.qml` L221–225  
**Apply to:** Any reordering of Media / Battery / SysTray / Indicators  
**Rule:** Either reverse-declare under RTL or switch to LTR and declare Media → Battery → SysTray → Indicators; UAT L→R against D-15 table.

### Indicators pill single hit target
**Source:** `BarContent.qml` `rightSidebarButton`  
**Apply to:** BAR-04 click path  
**Rule:** Whole pill toggles `GlobalStates.sidebarRightOpen`; Network is not a separate button.

### Stock Hyprland workspace dispatch
**Source:** `Workspaces.qml` L58–72  
**Apply to:** BAR-01 interaction  
**Rule:** Keep `workspace N` / `workspace r±1`; never reintroduce `hl.dsp.focus`.

### Smoke validation (Phase 1 pattern)
**Apply to:** Every commit / wave

```bash
timeout 4 quickshell 2>&1 | rg 'Configuration Loaded|Error|WARN.*hl\.dsp'
```

Plus live config asserts (see config.json section).

### Appearance / Material tokens
**Source:** existing bar widgets  
**Apply to:** layout rewires only — do **not** re-theme in Phase 2; keep `Appearance.colors.*` / `Appearance.font.pixelSize.*` on moved widgets.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | **None.** All Phase 2 targets are in-tree ii modules/services. Planner uses self-analogs + RESEARCH gap matrix. |

Optional host-only file without repo path: live `config.json` is outside the git tree but mirrors Config keys (role-match to `Config.qml`).

## Anti-Patterns (do not copy)

| Anti-pattern | Why |
|--------------|-----|
| Hardcode timezone `"Asia/Dhaka"` | D-07: system TZ only |
| Waybar Google Calendar on clock click | D-06: `ClockWidgetPopup` only |
| SSID text on bar | D-09 |
| Change only `Config.qml` defaults | Live JSON overrides (Pitfall 1) |
| Strip LeftSidebar/ActiveWindow/Resources/Media/Battery/UtilButtons | D-17 rearrange-only |
| Enable `bar.weather` | D-16 deferred |
| Custom tray SNI host or nmcli rewrite | Don't hand-roll (RESEARCH) |
| Per-monitor `shown: 5` workspace strips | User locked `shown: 10` (D-02) |

## Metadata

**Analog search scope:**
- `.config/quickshell/modules/ii/bar/`
- `.config/quickshell/modules/common/Config.qml`
- `.config/quickshell/services/{DateTime,Network,TrayService}.qml`
- `.planning/phases/02-core-bar-modules/{02-CONTEXT,02-RESEARCH}.md`
- Phase 1 dual-write / smoke conventions from RESEARCH citations

**Files scanned:** ~12 primary QML/service files + CONTEXT/RESEARCH  
**Pattern extraction date:** 2026-07-21  
**Planner note:** Primary plan actions = (1) rewire `BarContent.qml` regions + indicators order, (2) dual-write clock/tray Config keys, (3) `showDate: false` call site, (4) smoke + UAT — verify-only for Workspaces/DateTime/Network/TrayService implementations.
