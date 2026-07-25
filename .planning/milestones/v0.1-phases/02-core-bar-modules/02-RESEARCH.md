# Phase 2: Core Bar Modules - Research

**Researched:** 2026-07-21
**Domain:** Quickshell Illogical Impulse bar modules (QML config + layout rewiring)
**Confidence:** HIGH

## Summary

Phase 2 does **not** build workspaces, clock, tray, or network from scratch. All four already exist under `modules/ii/bar/` + service singletons. The work is (1) rewire `BarContent.qml` to the user-locked L→R layout, (2) flip a small set of `Config` / persisted `config.json` keys so clock, tray color, and date display match CONTEXT decisions, (3) reorder the indicators pill, and (4) verify dual-monitor workspace + network state behavior with smoke + UAT.

Current defaults already satisfy workspace appearance (D-01..D-03), tray pin policy (D-14), weather-off (D-16), and stock Hyprland dispatch (D-04 / Phase 1 gap fix). Gaps are: **clock format + seconds**, **clock longDate duplication**, **tray monochrome still on**, **BarContent module order far from D-15**, and **indicators pill order ≠ D-19**.

**Primary recommendation:** Treat Phase 2 as a config + `BarContent.qml` rewiring plan. Update both `Config.qml` defaults and live `~/.config/illogical-impulse/config.json` (persisted overrides win). Prefer explicit `showDate: false` on the clock call site for D-08. Keep service/widget implementations stock.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Workspace appearance (BAR-01)
- **D-01:** Keep ii app icons — `Config.options.bar.workspaces.showAppIcons: true` (not Waybar-style dots only).
- **D-02:** Show **10** workspace slots (`shown: 10`) to match Hyprland workspaces 1–10 (DP-1: 1–5, HDMI-A-2: 6–10).
- **D-03:** Monochrome workspace app icons — `monochromeIcons: true`.
- **D-04:** Interaction: **click** switches workspace; **wheel** cycles (`workspace r±1`). Stock Hyprland `workspace N` dispatch from Phase 1 gap fix stays (no `hl.dsp.focus`).

#### Clock format & click (BAR-02)
- **D-05:** Waybar-like clock with **seconds** — configure `Config.options.time` so the bar shows a full datetime comparable to Waybar `{:%a %Y-%m-%d %I:%M:%S %p}` (Qt format + `secondPrecision: true`). Exact Qt format string is planner discretion as long as weekday, date, 12-hour time, seconds, and AM/PM are present.
- **D-06:** Click/hover keeps **ii `ClockWidgetPopup`** (date, uptime, todos) — do **not** open Google Calendar URL like Waybar.
- **D-07:** Timezone = **system** (host is Asia/Dhaka). Do not hardcode timezone unless system TZ drifts.
- **D-08:** **Time only in the bar** for the clock widget — no separate longDate/`verbose` date text beside the clock once the format string already includes date parts (avoid duplication).

#### Network bar detail (BAR-04)
- **D-09:** Bar surface remains **icon-only** (`Network.materialSymbol` Material glyph) — no SSID/signal text on the bar.
- **D-10:** State distinction via **ii Material symbol set only** (ethernet / signal_wifi_* / disconnected / off / bad) — no extra color coding required for Phase 2.
- **D-11:** Click path: network lives on the **right-sidebar indicators pill**; click opens **right sidebar / wifi panel** (existing ii path). No dedicated NetworkPopup in Phase 2.
- **D-12:** SSID/signal detail: **keep current ii behavior** (“the way it is right now is fine”) — do not invent new tooltip requirements beyond what already works; UAT must still be able to verify connected SSID/signal and disconnected states via existing UI (sidebar/service state).

#### System tray (BAR-03)
- **D-13:** Full-color tray icons (not monochrome) for app recognition (Discord, Steam, etc.).
- **D-14:** Keep ii tray pin/overflow defaults — `invertPinnedItems: true`, `pinnedItems: ["Fcitx"]` (pin list acts as blacklist; overflow for unpinned). Left-click activate, right-click menu.

#### Bar layout (module order)
User-locked order (visual left → right). Planner rewires `BarContent.qml` (and related groups) to match:

| Region | Order (L→R) | Modules |
|--------|-------------|---------|
| **Left** | 1, 2, 5, 3 | LeftSidebarButton → ActiveWindow → **Workspaces** → Resources |
| **Center** | 6, 7 | **ClockWidget** → UtilButtons (weather slot reserved but **off**) |
| **Right** | 4, 8, 10, 9 | Media → BatteryIndicator → **SysTray** → **Indicators pill** |

- **D-15:** Apply the table above as the Phase 2 bar layout contract.
- **D-16:** **WeatherBar stays disabled** for Phase 2 (`bar.weather.enable: false`). Center is Clock + UtilButtons only; weather is a later/v2 concern even though user may re-enable later in the same center region.
- **D-17:** Non-core modules (LeftSidebar, ActiveWindow, Resources, Media, Battery, UtilButtons) **remain present** at the positions above — rearrange, do not strip them for Phase 2.

#### Indicators pill (item 9)
- **D-18:** Keep **full ii cluster** contents: mute revealer, mic revealer, HyprlandXkb, NotificationUnreadCount, Network, Bluetooth.
- **D-19:** Reorder icons **on the bar pill only** to:  
  **mute → mic → xkb → Bluetooth → Network → notif**  
  (sidebar panel contents/order unchanged; whole pill still toggles `GlobalStates.sidebarRightOpen`).

### Claude's Discretion
- Exact Qt `time.format` / date format strings that realize D-05 + D-08 without double date text
- How to restructure `BarContent.qml` Row/BarGroup/layoutDirection so visual L→R matches D-15 despite existing `RightToLeft` on the right section
- Whether tray monochrome default needs an explicit Config flip vs Appearance path
- Tooltip polish for network if UAT cannot verify SSID without code change (only if current behavior fails success criteria)
- Dual-monitor: same panel on all screens (Phase 1 D-13) unless layout rewiring surfaces a per-monitor issue

### Deferred Ideas (OUT OF SCOPE)
- **WeatherBar enabled + center placement** — user wants layout slot eventually; `bar.weather.enable` remains false for Phase 2 (v2 CMOD / later)
- **CPU / memory / disk / volume product goals** — Phase 3 (Resources already on bar left but Phase 3 owns metrics parity)
- **Google Calendar on clock click** — rejected for Phase 2; could revisit if user wants dual action later
- **SSID text on bar** — rejected; icon-only + existing ii detail paths
- **IPC / keybinds / Waybar cutover** — Phase 4
- **nm-applet coexistence policy** — not decided; leave default system behavior
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BAR-01 | User can see and click Hyprland workspace indicators to switch workspaces | `Workspaces.qml` + `WorkspaceModel` (`shown:10`, app icons, monochrome); stock `Hyprland.dispatch("workspace N")` / `workspace r±1`; layout moves Workspaces to left region |
| BAR-02 | User sees current date and time in the bar | `DateTime.qml` + `Config.options.time.format` + `secondPrecision`; force `ClockWidget.showDate: false`; popup stays `ClockWidgetPopup` |
| BAR-03 | User sees system tray icons from running applications | `SysTray` / `SysTrayItem` / `TrayService`; set `tray.monochromeIcons: false`; keep invert pin list; layout places SysTray before indicators on right |
| BAR-04 | User sees network connection status (wifi/ethernet/disconnected) | Bar `Network.materialSymbol` icon-only; state matrix in `Network.qml`; detail/SSID via right sidebar `NetworkToggle` + `wifiNetworks/`; pill click → `sidebarRightOpen` |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Workspace indicators + click/wheel | Desktop shell UI (Quickshell QML) | Hyprland IPC | Widget renders; compositor owns workspace focus |
| Workspace occupancy / biggest window | Service (`HyprlandData`, `WorkspaceModel`) | Hyprland events | Service-singleton pattern (FWK-03) |
| Clock display + second ticks | Service (`DateTime` / `SystemClock`) | Host TZ (systemd/timedated) | Format from Config; no app-level TZ hardcode |
| Clock popup (uptime/todos) | Desktop shell UI | Todo service | Existing `ClockWidgetPopup` only |
| System tray icons + menus | Desktop shell UI + `Quickshell.Services.SystemTray` | App StatusNotifierItems | Protocol host is Quickshell; pin logic in `TrayService` |
| Network icon on bar | Service (`Network.qml` nmcli) | Desktop shell UI (MaterialSymbol) | Icon-only surface; service owns state |
| Network SSID / connect UI | Desktop shell UI (sidebar wifi) | nmcli CLI | D-09/D-12: detail not on bar |
| Bar module layout order | Desktop shell UI (`BarContent.qml`) | Config toggles | User layout contract D-15 |
| Theme chrome colors | Appearance tokens (Phase 1) | — | Do not re-theme in Phase 2 |

---

## Current vs Target Gap Matrix

Verified against live tree + `~/.config/illogical-impulse/config.json` on 2026-07-21. [VERIFIED: codebase + host config]

| Area | Current (repo + live config) | Target (CONTEXT) | Plan action |
|------|------------------------------|------------------|-------------|
| Workspaces `showAppIcons` | `true` | `true` (D-01) | No change |
| Workspaces `shown` | `10` | `10` (D-02) | No change |
| Workspaces `monochromeIcons` | `true` | `true` (D-03) | No change |
| Workspace dispatch | `workspace N` / `r±1` | stock (D-04) | No change |
| `time.format` | `"hh:mm"` | Waybar-like datetime (D-05) | **Change** Config + live JSON |
| `time.secondPrecision` | `false` | `true` (D-05) | **Change** Config + live JSON |
| Clock `showDate` / longDate | `verbose && !shortened` → **shows** longDate | time-only (D-08) | **Force false** at call site |
| Clock click | `ClockWidgetPopup` | keep (D-06) | No change |
| Timezone | system (`Asia/Dhaka`) | system (D-07) | No hardcode |
| Tray `monochromeIcons` | `true` | `false` (D-13) | **Change** Config + live JSON |
| Tray pin policy | invert + `["Fcitx"]` | same (D-14) | No change |
| Weather | `enable: false` | off (D-16) | No change |
| Bar layout | stock ii (workspaces center; clock right-center; media left-center; tray right) | D-15 table | **Rewrite BarContent regions** |
| Indicators order | mute → mic → xkb → **notif → Network → Bluetooth** | mute → mic → xkb → **Bluetooth → Network → notif** (D-19) | **Reorder children** |

### Recommended clock format (discretion)

Waybar reference: `{:%a %Y-%m-%d %I:%M:%S %p}` [VERIFIED: `.config/waybar/config.jsonc`].

Qt / `DateTime.qml` uses `Qt.locale().toString(clock.date, Config.options.time.format)` [VERIFIED: `services/DateTime.qml`].

**Recommend:**

```qml
// Config.options.time
format: "ddd yyyy-MM-dd hh:mm:ss AP"
secondPrecision: true
```

Verified on host with PyQt6 6.11 → `Tue 2026-07-21 10:57:45 PM` [VERIFIED: PyQt6 QLocale.toString]. Matches D-05 fields (weekday, ISO-like date, 12h, seconds, AM/PM). With this format, **must** disable adjacent `DateTime.longDate` (D-08).

---

## Standard Stack

### Core

| Library / Component | Version | Purpose | Why Standard |
|---------------------|---------|---------|--------------|
| Quickshell | 0.3.0-2 (Arch) | QML desktop shell host | Already running `quickshell:bar` [VERIFIED: `pacman -Q`, `hyprctl layers`] |
| Illogical Impulse bar (`modules/ii/bar/*`) | in-tree wholesale | Bar widgets | Phase 1 foundation; do not rewrite |
| Qt 6 / QML | 6.11.x | UI + `Qt.locale` formatting | Shell runtime |
| Hyprland | 0.55.4 | Workspaces, monitors, layers | Host compositor [VERIFIED: `hyprctl version`] |
| NetworkManager `nmcli` | system | Network service backend | `Network.qml` Process commands [VERIFIED: `command -v nmcli`, wifi connected] |

### Supporting

| Library / Component | Version | Purpose | When to Use |
|---------------------|---------|---------|-------------|
| `Quickshell.Services.SystemTray` | bundled | Tray SNI items | SysTray already imports it |
| `Quickshell.Hyprland` | bundled | dispatch / monitor / focus grab | Workspaces + tray overflow |
| Material Symbols font | Phase 1 installed | Network + indicator glyphs | Already required |
| `~/.config/illogical-impulse/config.json` | live | Persisted Config overrides | **Must update with defaults** (Phase 1 learning) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Config-driven clock format | Hardcode text in `ClockWidget.qml` | Breaks settings GUI / FWK patterns — **don't** |
| Icon-only network on bar | Waybar-style SSID text | Explicitly rejected (D-09) |
| Custom NetworkPopup | Sidebar wifi dialog | Deferred; D-11 uses existing sidebar path |
| Per-monitor workspace strip (1–5 vs 6–10) | `shown: 5` + group offset | User locked `shown: 10` (D-02); both monitors show 1–10 |

**Installation:**

```bash
# No new packages required for Phase 2 core modules.
# Runtime prerequisites already present:
#   quickshell, hyprland, nmcli, Material Symbols font
```

**Version verification:** Host packages confirmed 2026-07-21 (`quickshell 0.3.0-2`, Hyprland 0.55.4, PyQt6 6.11.0-2 for format check only). No npm/pypi/crates installs in this phase.

---

## Package Legitimacy Audit

> Phase 2 installs **no** external registry packages. Config/layout-only.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | N/A | No installs |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```text
┌──────────────────────── Hyprland session ─────────────────────────┐
│  Monitors: DP-1 (ws 1-5), HDMI-A-2 (ws 6-10)                      │
│  Layers: quickshell:bar (+ waybar until Phase 4)                  │
└───────────────┬───────────────────────────────┬───────────────────┘
                │                               │
                ▼                               ▼
     ┌──────────────────┐            ┌─────────────────────┐
     │ shell.qml        │            │ StatusNotifier apps │
     │ PanelLoader → ii │            │ (Discord, Fcitx,…)  │
     └────────┬─────────┘            └──────────┬──────────┘
              │                                 │
              ▼                                 ▼
     ┌──────────────────┐            ┌─────────────────────┐
     │ Bar (per screen) │            │ SystemTray service  │
     │   BarContent     │◄───────────│ TrayService pin/    │
     │                  │            │ overflow            │
     └────────┬─────────┘            └─────────────────────┘
              │
    ┌─────────┼──────────────────────────────┐
    ▼         ▼                              ▼
 Left      Center                          Right
 LSidebar  ClockWidget ──► DateTime        Media
 ActiveWin   └ popup     (SystemClock)     Battery
 Workspaces◄─ WorkspaceModel               SysTray
 Resources   └ HyprlandData                Indicators pill
                                              │
                    mute mic xkb BT Network notif
                                              │
                         click ──► GlobalStates.sidebarRightOpen
                                              │
                                              ▼
                                   SidebarRight + wifiNetworks
                                              │
                                              ▼
                                         Network.qml
                                         (nmcli monitor)
```

### Recommended Project Structure (touch set)

```text
.config/quickshell/
├── modules/ii/bar/
│   ├── BarContent.qml          # PRIMARY: layout regions + indicators order
│   ├── Workspaces.qml          # verify only (dispatch already fixed)
│   ├── ClockWidget.qml         # optional: default showDate=false
│   ├── ClockWidgetPopup.qml    # verify only (D-06)
│   ├── SysTray.qml / SysTrayItem.qml  # monochrome via Config
│   └── …
├── modules/common/Config.qml   # defaults: time.*, tray.monochromeIcons
├── services/
│   ├── DateTime.qml            # verify only
│   ├── Network.qml             # verify materialSymbol matrix
│   ├── TrayService.qml         # verify pin invert logic
│   └── HyprlandData.qml        # verify only
└── (host) ~/.config/illogical-impulse/config.json  # LIVE overrides
```

Waybar (`.config/waybar/config.jsonc`) is **parity reference only** — do not port modules.

### Pattern 1: Service singleton → widget render (FWK-03)

**What:** Services expose reactive properties; bar widgets bind and render.  
**When to use:** All four BAR modules.  
**Example:**

```qml
// Source: .config/quickshell/modules/ii/bar/BarContent.qml (Network icon)
MaterialSymbol {
    text: Network.materialSymbol
    iconSize: Appearance.font.pixelSize.larger
    color: rightSidebarButton.colText
}
```

```qml
// Source: .config/quickshell/services/DateTime.qml
property string time: Qt.locale().toString(clock.date, Config.options?.time.format ?? "hh:mm")
// precision: SystemClock.Seconds when Config.options.time.secondPrecision
```

### Pattern 2: Config defaults + persisted override dual-write

**What:** `Config.qml` sets defaults; `FileView` persists to `Directories.shellConfigPath` → `~/.config/illogical-impulse/config.json`. Live values override QML defaults.  
**When to use:** Any Config key change (clock, tray monochrome).  
**How to avoid Phase 1 footgun:** Update **both** `Config.qml` and the live JSON (or write via Config API / settings so adapter flushes). [VERIFIED: Phase 1 LEARNINGS “Persisted Config overrides QML defaults”]

### Pattern 3: Right section `layoutDirection: Qt.RightToLeft`

**What:** Right `RowLayout` declares children right-first; visual L→R is reverse of declaration order.  
**When to use:** Understanding current code; rewiring for D-15.  
**Recommendation (discretion):** Either:

1. **Keep RTL** and declare children as: Indicators → SysTray → Battery → Media → fill spacer (rightmost first), **or**
2. **Switch right section to LTR** and declare Media → Battery → SysTray → Indicators (clearer for D-15 audit).

Prefer (2) for plan readability unless RTL is required for scroll-hint/margin anchoring — verify `Layout.rightMargin` on the pill still hugs the screen edge.

### Pattern 4: Indicators pill as single hit target

**What:** Entire `RippleButton` toggles `GlobalStates.sidebarRightOpen`; Network is **not** an independent click target.  
**When to use:** BAR-04 click path (D-11).  
**Do not** split Network into its own button in Phase 2.

### Anti-Patterns to Avoid

- **Hardcoding timezone `"Asia/Dhaka"` in QML** — D-07 says system TZ; Waybar hardcodes timezone but ii must not copy that.
- **Opening Google Calendar on clock click** — Waybar does; D-06 forbids.
- **SSID text on the bar** — violates D-09; verify detail in sidebar.
- **Reintroducing `hl.dsp.focus`** — broken without plugin (Phase 1).
- **Changing only `Config.qml` defaults** — live JSON will keep old clock/tray values.
- **Stripping non-core modules** to “simplify” — D-17 requires rearrange-only.
- **Enabling weather** — D-16 / deferred.
- **Hand-rolling a new tray host** — `SystemTray` + `TrayService` already correct.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Workspace model / occupancy | Custom Hyprland IPC parser | `WorkspaceModel` + `HyprlandData` | Dual-monitor groups, special WS, biggest-window already handled |
| Clock ticking | `Timer` every second in widget | `SystemClock` + `secondPrecision` | Correct precision switching; lock screen also uses Seconds |
| Tray SNI protocol | Custom StatusNotifier watcher | `Quickshell.Services.SystemTray` | Wayland tray edge cases, menus, focus grab |
| Network scan/connect | Custom D-Bus NM client | `Network.qml` nmcli + sidebar wifi UI | Already production-tested in ii |
| Date formatting | Manual string concat | `Qt.locale().toString` + Config format | Locale-aware weekday/AMPM |
| Pin/overflow tray policy | Ad-hoc filter in SysTray | `TrayService` invert pin lists | Single source of truth |

**Key insight:** Phase 2 value is **layout + config alignment**, not new modules. Custom rewrites fight wholesale-ii upgrades and Phase 1 architecture.

---

## Common Pitfalls

### Pitfall 1: Persisted config silently wins

**What goes wrong:** Change `Config.qml` `time.format` / `tray.monochromeIcons`; bar still shows old values.  
**Why it happens:** `~/.config/illogical-impulse/config.json` already has keys written.  
**How to avoid:** Dual-write defaults + live JSON; smoke-check with a one-liner dump of live keys after edit.  
**Warning signs:** Clock still `hh:mm`; tray still grayscale after “fix”.

### Pitfall 2: RightToLeft visual order inversion

**What goes wrong:** Children ordered Media…Indicators in code but appear reversed on screen.  
**Why it happens:** `layoutDirection: Qt.RightToLeft` on `rightSectionRowLayout` [VERIFIED: `BarContent.qml` L225].  
**How to avoid:** Decide LTR vs reverse-declare; verify with screenshot/UAT L→R checklist matching D-15 table.  
**Warning signs:** Indicators on left of tray; Media next to screen edge.

### Pitfall 3: Clock date duplication

**What goes wrong:** Format includes date **and** `DateTime.longDate` shows beside it (`showDate` true when `bar.verbose`).  
**Why it happens:** `BarContent` passes `showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)` and `verbose` defaults true [VERIFIED].  
**How to avoid:** Set `showDate: false` explicitly on `ClockWidget` (recommended) or gate on a new config flag.  
**Warning signs:** Two date strings in center group.

### Pitfall 4: Dual-monitor workspace expectations

**What goes wrong:** User expects DP-1 to show only 1–5 and HDMI only 6–10; both show 1–10 with `shown: 10`.  
**Why it happens:** `WorkspaceModel.group = floor((activeWorkspace-1)/shownCount)` → group 0 for all of 1–10 [VERIFIED: `WorkspaceModel.qml`]. Hyprland still **binds** 1–5→DP-1, 6–10→HDMI-A-2 [VERIFIED: `hyprland.conf`].  
**How to avoid:** Document as intentional (D-02). Clicking 6–10 from DP-1 focuses the other monitor — stock Hyprland.  
**Warning signs:** UAT confusion, not a bug.

### Pitfall 5: Network success criteria vs icon-only UI

**What goes wrong:** UAT fails “shows SSID” because bar has no text.  
**Why it happens:** Roadmap wording vs D-09/D-12.  
**How to avoid:** UAT script: (1) bar icon glyph changes for connected/disconnected/ethernet, (2) open right sidebar → NetworkToggle tooltip / wifi list shows SSID & signal.  
**Warning signs:** Tester only looks at bar chrome.

### Pitfall 6: Shortened-bar visibility gates

**What goes wrong:** SysTray / ActiveWindow disappear on narrow screens (`useShortenedForm !== 0`).  
**Why it happens:** Width thresholds 1200 / 1000 in Appearance [VERIFIED]. DP-1 3440 is fine; HDMI-A-2 portrait at scale 1.5 may shorten.  
**How to avoid:** After layout move, re-check HDMI-A-2 width effective pixels; do not remove gates unless UAT requires.  
**Warning signs:** Tray missing on second monitor only.

### Pitfall 7: Dual bars during testing

**What goes wrong:** Visual clutter; wrong bar clicked.  
**Why it happens:** Waybar still exec'd until Phase 4 [VERIFIED: `hyprctl layers` shows both `quickshell:bar` and `waybar`].  
**How to avoid:** UAT instructions: interact with `quickshell:bar` (topmost / namespace); optionally `pkill waybar` for screenshots only — do not permanent-cutover.

### Pitfall 8: Indicator reorder breaks spacing

**What goes wrong:** `Layout.rightMargin` / `Layout.leftMargin` on revealers look uneven after move.  
**Why it happens:** Bluetooth currently uses `Layout.leftMargin: realSpacing`; notif uses conditional `rightMargin`.  
**How to avoid:** After reorder to mute→mic→xkb→BT→Network→notif, normalize spacing so non-revealer icons still use `realSpacing` consistently.

### Pitfall 9: Tray pin ID mismatch

**What goes wrong:** Fcitx still appears in overflow or wrong section.  
**Why it happens:** Pin match is exact `item.id` string (`"Fcitx"`) [VERIFIED: `TrayService.qml`].  
**How to avoid:** If wrong, enable `tray.showItemId: true` temporarily to read real IDs; keep D-14 defaults unless ID differs.

---

## Code Examples

### Workspace click / wheel (keep)

```qml
// Source: .config/quickshell/modules/ii/bar/Workspaces.qml
function switchWorkspaceToHovered() {
    // Stock Hyprland dispatcher (hl.dsp.focus requires a plugin we do not ship)
    Hyprland.dispatch(`workspace ${wsModel.getWorkspaceIdAt(hoverIndex)}`);
}
onWheel: event => {
    if (event.angleDelta.y < 0)
        Hyprland.dispatch("workspace r+1");
    else if (event.angleDelta.y > 0)
        Hyprland.dispatch("workspace r-1");
}
```

### Clock config target

```qml
// Source pattern: modules/common/Config.qml → property JsonObject time
// Recommended values (discretion):
property string format: "ddd yyyy-MM-dd hh:mm:ss AP"
property bool secondPrecision: true
```

### Clock widget — kill longDate for D-08

```qml
// Source: modules/ii/bar/BarContent.qml (call site change)
ClockWidget {
    showDate: false  // D-08: format string already includes date parts
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: true
}
```

### Tray monochrome off (D-13)

```qml
// Source: modules/common/Config.qml → tray
property bool monochromeIcons: false  // was true; full-color icons
// SysTrayItem already branches:
//   IconImage visible when !monochromeIcons
//   Desaturate+ColorOverlay when monochromeIcons
```

### Tray pin invert (keep D-14)

```qml
// Source: services/TrayService.qml
property bool invertPins: Config.options.tray.invertPinnedItems
property list<var> pinnedItems: invertPins ? itemsNotInUserList : itemsInUserList
property list<var> unpinnedItems: invertPins ? itemsInUserList : itemsNotInUserList
// With invertPinnedItems:true and pinnedItems:["Fcitx"], Fcitx is blacklisted from the
// always-visible strip and lives in overflow; everything else is "pinned" (visible).
```

### Network materialSymbol matrix (keep D-10)

```qml
// Source: services/Network.qml (summary)
// ethernet connected     → "lan"
// wifi connected         → signal_wifi_4_bar | network_wifi | network_wifi_3_bar |
//                          network_wifi_2_bar | network_wifi_1_bar | signal_wifi_0_bar
// connecting             → "signal_wifi_statusbar_not_connected"
// disconnected           → "wifi_find"
// disabled               → "signal_wifi_off"
// other / bad            → "signal_wifi_bad"
```

### Indicators target order (D-19)

```qml
// Target child order inside indicatorsRowLayout (L→R, layoutDirection default LTR):
// 1. Revealer mute (volume_off)
// 2. Revealer mic (mic_off)
// 3. HyprlandXkbIndicator
// 4. MaterialSymbol Bluetooth (moved earlier)
// 5. MaterialSymbol Network.materialSymbol
// 6. Revealer NotificationUnreadCount (moved last)
```

### Layout contract sketch (D-15)

```text
LEFT  (RowLayout, LTR):
  LeftSidebarButton | ActiveWindow(fill) | Workspaces | Resources

CENTER (Row, centered):
  BarGroup { ClockWidget(showDate:false); UtilButtons }
  // WeatherBar loader stays inactive (enable:false)

RIGHT  (prefer LTR for clarity):
  Media | BatteryIndicator | SysTray | IndicatorsPill
```

Move modules **by reparenting existing components** — do not duplicate files. Preserve brightness scroll on left mouse area and volume scroll on right mouse area; note Media/Battery will fall under volume scroll after move (acceptable side effect unless UAT objects).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Waybar modules JSON | ii QML widgets + services | Phase 1 wholesale | Config keys not Waybar keys |
| `hl.dsp.focus` workspace plugin | stock `workspace` dispatch | Phase 1 gap 01-04 | Keep in Phase 2 |
| Waybar clock → Google Calendar | ClockWidgetPopup | Phase 2 decision | D-06 |
| Waybar network SSID on bar | Material icon + sidebar | Phase 2 decision | D-09/D-12 |
| Stock ii bar order | User-locked D-15 order | Phase 2 | Primary code change |

**Deprecated/outdated for this phase:**

- Porting Waybar CSS/modules literally
- Building waffle bar family instead of ii
- Vertical bar path (`bar.vertical`) — host is horizontal top bar

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Switching right section from RTL to LTR is safe if margins rechecked | Architecture Patterns | Edge spacing/rounding off-by-one on right |
| A2 | Opening full right sidebar satisfies D-11 “wifi panel” without auto-opening `WifiDialog` | BAR-04 / Pitfall 5 | User may expect one-click wifi list; would need small click routing change |
| A3 | HDMI-A-2 effective width stays above shorten thresholds after layout move | Pitfall 6 | Tray/ActiveWindow may hide on second monitor |
| A4 | Fcitx tray `item.id` remains exactly `"Fcitx"` | Pitfall 9 | Pin blacklist ineffective until ID fixed |

**If wrong:** A2 is the only product-facing ambiguity — UAT can confirm; only then add tooltip or direct `showWifiDialog` wiring (still no NetworkPopup).

---

## Open Questions

1. **Does D-11 require auto-opening WifiDialog?**
   - What we know: Pill sets `sidebarRightOpen`; wifi UI is `SidebarRightContent.showWifiDialog` via NetworkToggle / android panel signals [VERIFIED: sidebar QML].
   - What's unclear: Whether “wifi panel” means sidebar home vs wifi dialog.
   - Recommendation: Ship sidebar toggle only; if UAT fails, add optional path to set `showWifiDialog` when clicking network region (still within pill — higher effort).

2. **Should `bar.verbose` stay true after D-08?**
   - What we know: verbose also gates UtilButtons visibility and center side widths.
   - Recommendation: Leave `verbose: true`; only force `ClockWidget.showDate: false`.

3. **HDMI connected during Phase 2 UAT?**
   - What we know: At research time only DP-1 active [VERIFIED: `hyprctl monitors`].
   - Recommendation: Optional dual-monitor UAT when HDMI attached; single-monitor still proves BAR-01..04.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `quickshell` / `qs` | Bar runtime | ✓ | 0.3.0-2 | — |
| Hyprland / `hyprctl` | Workspaces, layers | ✓ | 0.55.4 | — |
| `nmcli` | Network service | ✓ | present; wifi connected | — |
| System TZ Asia/Dhaka | Clock (D-07) | ✓ | timedatectl | — |
| Material Symbols font | Indicators/network icons | ✓ | Phase 1 | — |
| Live ii config JSON | Config overrides | ✓ | `~/.config/illogical-impulse/config.json` | — |
| Waybar | Parity reference only | ✓ (coexists) | running | Ignore for runtime success |
| HDMI-A-2 | Dual-monitor UAT | ✗ at research time | — | Single-monitor UAT + optional later |
| npm/pip packages | — | N/A | — | No install phase |

**Missing dependencies with no fallback:** none for core Phase 2 work.

**Missing dependencies with fallback:** HDMI dual-monitor verification optional.

---

## Validation Architecture

> `workflow.nyquist_validation: true` in `.planning/config.json` — section required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual QML validation (quickshell runtime) + shell smoke (same as Phase 1) |
| Config file | none — no unit test framework for QML |
| Quick run command | `timeout 4 quickshell 2>&1 \| rg 'Configuration Loaded|Error|WARN.*hl\\.dsp'` |
| Full suite command | smoke launch + live config key asserts + `hyprctl layers` + human UAT |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BAR-01 | Workspaces render 10 slots; click dispatches `workspace N` | smoke + manual | `rg -n 'workspace \$\{|workspace r' .config/quickshell/modules/ii/bar/Workspaces.qml` + UAT click | ✅ source; ❌ dedicated test file — Wave 0 uses smoke/UAT |
| BAR-01 | `shown:10`, `showAppIcons:true`, `monochromeIcons:true` | config assert | `python3 -c` dump live `bar.workspaces` keys | ❌ Wave 0 script |
| BAR-02 | Clock format + seconds | config assert + visual | assert live `time.format` contains `ss` and `AP`/`ap`; `secondPrecision is True` | ❌ Wave 0 script |
| BAR-02 | No longDate beside clock | static | `rg -n 'showDate' .config/quickshell/modules/ii/bar/BarContent.qml` expects false | ✅ after implement |
| BAR-02 | Popup is ClockWidgetPopup not calendar URL | static | `rg -n 'ClockWidgetPopup|calendar.google' .config/quickshell/modules/ii/bar/ClockWidget.qml` | ✅ |
| BAR-03 | Tray full-color | config assert | live `tray.monochromeIcons is False` | ❌ Wave 0 script |
| BAR-03 | Pin policy | config assert | `invertPinnedItems True` and `pinnedItems == ['Fcitx']` | ❌ Wave 0 script |
| BAR-04 | Network icon bound | static | `rg -n 'Network.materialSymbol' BarContent.qml` | ✅ |
| BAR-04 | Disconnected/connected glyph change | manual / optional nmcli | toggle wifi; observe symbol; sidebar SSID | manual |
| D-15 | Module L→R order | manual UAT checklist | visual left→right per CONTEXT table | manual |
| D-19 | Indicators order | static + visual | child order in `indicatorsRowLayout` | ✅ after implement |
| Smoke | Configuration Loaded | smoke | `timeout 4 quickshell 2>&1 \| rg 'Configuration Loaded'` | ✅ pattern from Phase 1 |

### Sampling Rate

- **Per task commit:** `timeout 4 quickshell 2>&1 | rg 'Configuration Loaded|Error|hl\\.dsp'`
- **Per wave merge:** smoke + python live-config asserts for `time.*` / `tray.monochromeIcons` / `bar.workspaces` / `bar.weather.enable`
- **Phase gate:** Full smoke green + UAT checklist for BAR-01..04 before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `scripts` or plan-inline **live config assert** snippet (python dump of `~/.config/illogical-impulse/config.json` keys listed above) — not a full test framework
- [ ] Phase 2 UAT checklist file (created during verify/UAT, not blocking plan) covering D-15 order, clock string, tray color, network icon + sidebar SSID
- [ ] Framework install: **none** — reuse Phase 1 smoke pattern

*(No pytest/jest infrastructure exists or is required for this QML shell phase.)*

### Suggested automated config assert (Wave 0 / per-wave)

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

---

## Security Domain

> `security_enforcement: true`, ASVS level 1.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Local desktop session only |
| V3 Session Management | no | — |
| V4 Access Control | no | Same-user session; no multi-user bar ACL |
| V5 Input Validation | partial | Config JSON via FileView adapter; nmcli SSID from NetworkManager (not free user text on bar) |
| V6 Cryptography | no | No new crypto |

### Known Threat Patterns for Quickshell bar / nmcli

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Command injection via SSID in nmcli | Tampering | Pre-existing `Network.qml` uses process args / env for password change; **do not** introduce `bash -c` with unescaped SSID in Phase 2 |
| Tray item activates unexpected app | Elevation / Spoofing | Left-click is intentional SNI activate; accept as desktop norm |
| Malicious tray icon | Spoofing | Full-color icons (D-13) increase recognizability; still trust session apps |
| Config JSON corruption | Tampering / DoS | Invalid JSON → Config load failure; smoke catches; keep edits valid JSON |
| Information disclosure of SSID | Info disclosure | SSID already in sidebar/tooltips; not a Phase 2 regression |
| Dual bar clickjack confusion | Spoofing | Document which layer is under test; Phase 4 cutover removes Waybar |

**Phase 2 security posture:** No new trust boundaries. Prefer config/layout edits over new `Process` commands. Do not expand nmcli surface.

---

## Project Constraints (from CLAUDE.md)

`./CLAUDE.md` and `./.claude/CLAUDE.md` were **not present** at research time. Constraints come from:

- Phase 1 learnings (stock dispatch, dual-write config, Material Symbols)
- `.planning/PROJECT.md` / REQUIREMENTS / CONTEXT (via this document’s user_constraints)
- Wholesale ii architecture already in tree

---

## Sources

### Primary (HIGH confidence)

- `.config/quickshell/modules/ii/bar/BarContent.qml` — layout, indicators, RTL
- `.config/quickshell/modules/ii/bar/Workspaces.qml` — dispatch, icons, wheel
- `.config/quickshell/modules/common/models/WorkspaceModel.qml` — shown/group math
- `.config/quickshell/modules/ii/bar/ClockWidget.qml` / `ClockWidgetPopup.qml`
- `.config/quickshell/modules/ii/bar/SysTray.qml` / `SysTrayItem.qml`
- `.config/quickshell/services/{DateTime,Network,TrayService}.qml`
- `.config/quickshell/modules/common/Config.qml` — defaults for workspaces/time/tray/weather
- `~/.config/illogical-impulse/config.json` — live overrides
- `.config/waybar/config.jsonc` — parity reference (clock/tray/network)
- `.config/hypr/hyprland.conf` — workspace↔monitor map
- `.planning/phases/01-shell-foundation-theme/01-LEARNINGS.md` / `01-VALIDATION.md`
- Host probes: `hyprctl layers/monitors`, `nmcli`, `timedatectl`, `pacman -Q quickshell`

### Secondary (MEDIUM confidence)

- Qt 6 format tokens via official doc.qt.io mention of `AP`/`ap` AM/PM forms [CITED: doc.qt.io/qt-6/qtime.html]
- PyQt6 6.11 host verification of recommended format string [VERIFIED: local PyQt6]

### Tertiary (LOW confidence)

- A1–A4 assumptions (RTL switch safety, WifiDialog auto-open, HDMI width, Fcitx id)

---

## Metadata

**Confidence breakdown:**

| Area | Level | Reason |
|------|-------|--------|
| Standard stack | HIGH | Running host packages + in-tree ii modules |
| Architecture / layout gaps | HIGH | Full read of BarContent + services + live config |
| Config keys / defaults | HIGH | Grep + live JSON dump |
| Qt format string | HIGH | PyQt6 verification on same host |
| Dual-monitor edge cases | MEDIUM | HDMI not attached at research time |
| WifiDialog vs sidebar semantics | MEDIUM | D-11 wording slightly ambiguous |

**Research date:** 2026-07-21  
**Valid until:** 2026-08-20 (stable shell stack; re-check if quickshell or ii tree is upgraded wholesale)
