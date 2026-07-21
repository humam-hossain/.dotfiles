# Phase 2: Core Bar Modules - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-21
**Phase:** 2-Core Bar Modules
**Areas discussed:** Workspace appearance, Clock format & click, Network bar detail, Layout vs Waybar positions, System tray, Indicators cluster

---

## Workspace appearance

| Option | Description | Selected |
|--------|-------------|----------|
| Keep ii app icons | showAppIcons: true | ✓ |
| Numbers only | showAppIcons: false | |
| Always show numbers + app icons | alwaysShowNumbers + icons | |

**User's choice:** Keep ii app icons  
**Notes:** Aligns with Phase 1 “embrace ii”

| Option | Description | Selected |
|--------|-------------|----------|
| 10 slots | matches hypr workspaces 1–10 | ✓ |
| 5 slots | primary monitor only | |
| You decide | | |

**User's choice:** 10

| Option | Description | Selected |
|--------|-------------|----------|
| Monochrome icons | monochromeIcons: true | ✓ |
| Full-color app icons | | |
| You decide | | |

**User's choice:** Monochrome

| Option | Description | Selected |
|--------|-------------|----------|
| Click + wheel cycle | stock workspace dispatch | ✓ |
| Click only | | |
| You decide | | |

**User's choice:** Click + wheel

---

## Clock format & click

| Option | Description | Selected |
|--------|-------------|----------|
| Waybar-like with seconds | full datetime + secondPrecision | ✓ |
| ii default hh:mm + date | | |
| 12-hour without seconds | | |
| You decide | | |

**User's choice:** Waybar-like with seconds

| Option | Description | Selected |
|--------|-------------|----------|
| Keep ii ClockWidgetPopup | | ✓ |
| Open Google Calendar URL | Waybar parity | |
| Both popup + calendar | | |
| You decide | | |

**User's choice:** Keep ii popup

| Option | Description | Selected |
|--------|-------------|----------|
| System timezone Asia/Dhaka | | ✓ |
| Hardcode Asia/Dhaka | | |
| You decide | | |

**User's choice:** System timezone

| Option | Description | Selected |
|--------|-------------|----------|
| Time only in bar | no redundant longDate | ✓ |
| Keep time + longDate verbose | | |
| You decide | | |

**User's choice:** Time only in bar

---

## Network bar detail

| Option | Description | Selected |
|--------|-------------|----------|
| Icon only (ii default) | | ✓ |
| Icon + SSID/status text | | |
| Icon + signal % only | | |
| You decide | | |

**User's choice:** Icon only

| Option | Description | Selected |
|--------|-------------|----------|
| ii Material symbols only | | ✓ |
| Icons + color change | | |
| You decide | | |

**User's choice:** Material symbols only

| Option | Description | Selected |
|--------|-------------|----------|
| Open right sidebar / wifi panel | | ✓ |
| Dedicated network popup | | |
| No click action | | |
| You decide | | |

**User's choice:** Right sidebar path

| Option | Description | Selected |
|--------|-------------|----------|
| Tooltip + sidebar | | |
| Sidebar only | | |
| You decide | | |
| Other | “The way it is right now is fine” | ✓ |

**User's choice:** Keep current ii behavior for SSID/signal detail  
**Notes:** Freeform — no new tooltip mandate

---

## Layout vs Waybar positions

User provided numbered module list, then ordered:

- **Left:** 1 LeftSidebarButton, 2 ActiveWindow, 5 Workspaces, 3 Resources  
- **Center:** 11 WeatherBar, 6 ClockWidget, 7 UtilButtons  
- **Right:** 4 Media, 8 BatteryIndicator, 10 SysTray, 9 Indicators  

| Option | Description | Selected |
|--------|-------------|----------|
| Lock custom layout | | ✓ |
| Lock but hide weather | | |
| Change order | | |
| Keep current ii layout | | |

**User's choice:** Yes, lock it (freeform confirm)

| Option | Description | Selected |
|--------|-------------|----------|
| Enable weather in center | | |
| Keep weather off for Phase 2 | | ✓ |
| Remove weather from layout | | |
| You decide | | |

**User's choice:** Weather off for Phase 2

| Option | Description | Selected |
|--------|-------------|----------|
| Clock + UtilButtons only | | ✓ |
| Clock only | | |
| You decide | | |

**User's choice:** Clock + UtilButtons only (center)

---

## System tray

| Option | Description | Selected |
|--------|-------------|----------|
| Full-color tray icons | | ✓ |
| Monochrome tray icons | | |
| You decide | | |

**User's choice:** Full-color

| Option | Description | Selected |
|--------|-------------|----------|
| Keep ii pin/overflow defaults | invertPinnedItems + Fcitx | ✓ |
| Show all flat no overflow | | |
| You decide | | |

**User's choice:** Keep ii defaults

**Notes:** SysTray explained as status-notifier icons (Discord, Steam, nm-applet, Fcitx…); left-click activate, right-click menu; pin/overflow via TrayService. Distinct from Media and Network modules.

---

## Indicators cluster

| Option | Description | Selected |
|--------|-------------|----------|
| Keep full ii cluster | mute, mic, xkb, notif, Network, BT | ✓ |
| Network only | | |
| Network + BT + notif | | |
| You decide | | |

**User's choice:** Full cluster

| Option | Description | Selected |
|--------|-------------|----------|
| Keep ii internal order | | |
| Network first | | |
| You decide | | |
| Freeform order | mute \| mic \| xkb \| Bluetooth \| Network \| notif | ✓ |

**User's choice:** Custom pill order: mute → mic → xkb → Bluetooth → Network → notif  
**Notes:** Clarified this is the **bar pill**, not the right sidebar panel contents.

---

## Claude's Discretion

- Exact Qt time format strings for Waybar-like clock
- BarContent rewiring mechanics (RTL right section)
- Tray monochrome Config path if needed for full-color
- Network tooltip only if UAT fails with current behavior

## Deferred Ideas

- Weather enable + center placement (later / v2)
- Phase 3 system metrics / volume
- Google Calendar clock click
- SSID text on bar
- Phase 4 IPC / cutover
- nm-applet coexistence policy (undecided)
