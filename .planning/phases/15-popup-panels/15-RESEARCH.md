# Research: Phase 15 — Popup Panels

**Domain:** Quickshell QML popup panels — calendar, network panel, notification center  
**Researched:** 2026-05-22  
**Phase:** 15-popup-panels  
**Confidence:** HIGH

---

## 1. PopupWindow Pattern (Reiterated)

### Window Type
- **PopupWindow** (not PanelWindow) for all popups
- `PopupWindow` floats relative to a parent window; does NOT reserve exclusive zone
- Use `WlrLayershell.layer: WlrLayer.Overlay` so popups render above normal windows

### Anchoring Pattern
```
PopupWindow {
  anchor.window: barContentPanelWindow
  anchor.rect.x: parentWindow.width / 2 - implicitWidth / 2  // fixed offset
  anchor.rect.y: parentWindow.height + 12                    // below bar
}
```
The VolumeOsd.qml pattern (anchor.rect.x/y with fixed offset) is the established approach per D-33. No per-widget coordinate calculation.

### Dismiss via HyprlandFocusGrab
```
HyprlandFocusGrab {
  id: focusGrab
  windows: [calendarPopup]
  active: calendarPopup.visible
  onCleared: calendarPopup.visible = false
}
```
- `windows: [popup]` — whitelists popup for input
- `active: popup.visible` — grab active when visible
- `onCleared` — signals outside click; set `visible = false`
- Also handle Escape key (D-32): add `Keys.onPressed` handler within popup

### Visibility State
- `visible: false` (not `opacity: 0`) — fully removes from input tree (P-03)
- Static `visible: false` (not LazyLoader) — per D-29 and P-17 consideration

### Known Pitfalls (from PITFALLS.md)
| # | Pitfall | Prevention |
|---|---------|------------|
| P-01 | `grabFocus: true` steals keyboard | Use `HyprlandFocusGrab` |
| P-03 | `opacity: 0` still intercepts input | Always `visible: false` |
| P-15 | Variants delegate cleanup on hotplug | Popups as children of BarContent → auto-destroyed with parent |
| P-16 | Bar steals keyboard focus | `WlrKeyboardFocus.None` on bar PanelWindow (already set) |
| P-17 | LazyLoader jank on first open | Static `visible: false` deemed acceptable (D-29) |

---

## 2. Calendar Date Math (QML/JS)

### Available APIs
QML engine supports standard JS `Date` API:
| Method | Returns | Use |
|--------|---------|-----|
| `new Date()` | Current date/time | Today reference |
| `date.getFullYear()` | 4-digit year | Month header, grid calculation |
| `date.getMonth()` | 0-11 (Jan=0) | Month navigation, grid |
| `date.getDate()` | 1-31 | Day cells |
| `date.getDay()` | 0-6 (Sun=0) | Weekday offset (Mon first → adjust) |
| `Date.UTC(y,m,d)` | Milliseconds | Date math |
| `new Date(y,m,1)` | First of month | Week start offset |
| `new Date(y,m+1,0)` | Last day of month | Days in month |

### Calendar Grid Algorithm
```
function getMonthData(year, month) {
  // month: 0-11
  const firstDay = new Date(year, month, 1)
  const lastDay = new Date(year, month + 1, 0)
  const daysInMonth = lastDay.getDate()
  
  // Weekday of first day (Mon=0, Sun=6)
  const startOffset = (firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1)
  
  // Total cells = startOffset + daysInMonth, rounded up to multiple of 7
  const totalCells = Math.ceil((startOffset + daysInMonth) / 7) * 7
  // 6 rows max = 42 cells (5 rows = 35, 6 rows = 42)
  
  return {
    daysInMonth,
    startOffset,
    totalCells,
    prevMonthDays: new Date(year, month, 0).getDate(),
    rows: totalCells / 7
  }
}
```

### Today Highlight
- Compare `year === todayYear && month === todayMonth && day === todayDate`
- Today cell gets `Colours.accent` background (mauve) per D-13

### Day Cell Array Generation
Generate 42-element (or 35-element) array for Repeater:
```
for (let i = 0; i < totalCells; i++) {
  const cellDay = i - startOffset + 1
  if (cellDay < 1) // prev month day
  else if (cellDay > daysInMonth) // next month day
  else // current month day
}
```

### ISO Week Number Calculation
```
function getISOWeekNumber(year, month, day) {
  const date = new Date(Date.UTC(year, month, day))
  // Thursday of this week
  const thursday = date.getTime() + (3 - ((date.getUTCDay() + 6) % 7)) * 86400000
  const thursDate = new Date(thursday)
  // Jan 4th is always in week 1
  const jan4 = new Date(Date.UTC(thursDate.getUTCFullYear(), 0, 4))
  return 1 + Math.round(((thursday - jan4.getTime()) / 86400000 - 3 + ((jan4.getUTCDay() + 6) % 7)) / 7)
}
```

### Month Header Format
`Qt.formatDateTime(new Date(year, month, 1), "MMMM yyyy")` → "May 2026"

### Adjacent Month Days
- Previous month days: `new Date(year, month, 0).getDate() - startOffset + i` — grayed with `Colours.subtextColor`
- Next month days: `cellDay - daysInMonth` — grayed with `Colours.subtextColor`
- Weekend days: index % 7 in {5,6} → subtle tint with `Colours.subtext0 + "30"` at low opacity

### Cell Dimensions
- 36x36px per cell per D-04
- 7-column grid + 1 week-number column = 8 columns
- Fixed height sufficient for 6 rows per D-10: `36 * 6 + spacing * 5 + header height + padding`

---

## 3. nmcli Output Parsing

### WiFi Scan — Available Networks
```
nmcli --get-values SSID,SECURITY,BSSID,SIGNAL,CHAN dev wifi list
```
Output (terse, colon-delimited):
```
SSID1:WPA2:BSSID1:75:6
SSID2:WEP:BSSID2:50:1
:WPA2:BSSID3:90:11   // hidden network (empty SSID)
```
**Parsing rules:**
- Split on first `:` from end for SSID (handles colons in SSID — Phase 14 lesson)
- Signal strength: 0-100 integer → map to Nerd Font bars
  - 0-20: 󰤯 (weak)
  - 21-40: 󰤟 (fair)
  - 41-60: 󰤢 (good)
  - 61-100: 󰤥 (excellent)
- SECURITY field: empty or `--` = open; non-empty = secured → show lock icon 喙

**Scan timing:**
- Timer with `interval: 10000` (10s) while popup visible
- Trigger scan on popup `onVisibleChanged` for immediate first scan
- 10s auto-refresh per D-22

### Connection Status — Current Connection
```
nmcli -g GENERAL.TYPE,GENERAL.STATE,GENERAL.CONNECTION dev show <iface>
nmcli -g IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS,IP6.GATEWAY connection show --active
```

Better approach — fetch connection name then show details:
```
nmcli -g NAME,TYPE,DEVICE con show --active
```
Returns terse colon-separated lines:
```
MyWiFi:wifi:wlan0
Ethernet:ethernet:eth0
```

For a specific connection (e.g., "MyWiFi"):
```
nmcli -g ip4.address,ip4.gateway,ip4.dns,ip6.address,ip6.gateway,general.type con show "MyWiFi"
```
Returns one field per line (terse mode with -g).

**Alternative — `nmcli dev show <iface>`:**
```
GENERAL.DEVICE: wlan0
GENERAL.TYPE: wifi
GENERAL.STATE: 100 (connected)
GENERAL.CONNECTION: MyWiFi
IP4.ADDRESS[1]: 192.168.1.5/24
IP4.GATEWAY: 192.168.1.1
IP4.DNS[1]: 8.8.8.8
IP4.DNS[2]: 1.1.1.1
IP6.ADDRESS[1]: fe80::xxxx/64
IP6.GATEWAY: fe80::yyyy
```
This is the richer format. Parse by splitting on `: ` (first colon-space). Use multiple Process calls or a single bash script that outputs structured data.

### Signal Strength
```
nmcli -g SIGNAL dev wifi list | head -1
```
Or use `nmcli dev wifi list` (default format) and parse the SIGNAL column.

### Key Command to Generate Network Info
```bash
#!/bin/bash
# Gather all network info in one call
echo "=== CONNECTION ==="
nmcli -g GENERAL.TYPE,GENERAL.STATE,GENERAL.CONNECTION dev show "$(nmcli -t -f DEVICE,TYPE dev status | grep ':wifi\|:ethernet' | head -1 | cut -d: -f1)" 2>/dev/null || echo "not connected"
echo "=== IP4 ==="
nmcli -g IP4.ADDRESS,IP4.GATEWAY,IP4.DNS con show --active 2>/dev/null || true
echo "=== IP6 ==="
nmcli -g IP6.ADDRESS,IP6.GATEWAY con show --active 2>/dev/null || true
echo "=== WIFI ==="
nmcli --get-values SSID,SECURITY,SIGNAL dev wifi list 2>/dev/null || true
```

### Connect to Secured Network
```bash
nmcli dev wifi connect <SSID> password <password>
```
Returns success/error text. On success, connection activates automatically.

### Disconnect
```bash
nmcli con down id <SSID>
```

### nmcli Error Handling
- "No network devices found" — adapter missing/disabled
- Empty wifi list — scan returned no networks
- "Error: No network with SSID '...'" — SSID changed or out of range
- "Error: secrets were required, but not provided" — wrong password
- Connection timeout — ~15s scan interval per nmcli default

---

## 4. Keyboard Navigation in QML

### Modal Focus for Popups
QML `Item` with `focus: true` inside a PopupWindow can capture keyboard events via `Keys` attached property:
```qml
Item {
  focus: true
  Keys.onEscapePressed: closePopup()
  Keys.onTabPressed: { event.accepted = true; /* cycle focus */ }
  Keys.onReturnPressed: { event.accepted = true; /* submit */ }
  Keys.onUpPressed: { event.accepted = true; /* move up in list */ }
  Keys.onDownPressed: { event.accepted = true; /* move down */ }
}
```

### Focus Chain with Tab
- `TabButton` / `Button` items in QML naturally participate in Tab focus chain (via `activeFocusOnTab`)
- For custom items, set `activeFocusOnTab: true`
- `TextInput` fields (password, text) have built-in tab focus
- Need to manage focus cycling manually for custom implementations

### Network Panel Keyboard Spec (D-35)
1. Tab cycles: network list → password field → eye toggle → Cancel → Connect → back to start
2. Arrow keys (Up/Down) navigate the SSID Flickable list items
3. Enter on selected SSID: if secured → focus moves to password field; if open → connect immediately
4. Enter on password field with focus: submit connection
5. Enter on Connect button: submit connection
6. Escape: close popup

### Password Field
```qml
TextInput {
  echoMode: TextInput.Password   // masked
  // Toggle via:
  // echoMode: showPassword ? TextInput.Normal : TextInput.Password
}
```
Eye icon toggle per D-19: 󰛐 (hidden) / 󰛑 (visible)

---

## 5. Empty/Multiple State Handling

### Network Empty State (D-25)
Three distinct empty states based on nmcli error:
1. **No adapter detected** — `nmcli dev status` lists no wifi device → "No wireless adapter detected"
2. **WiFi disabled** — `nmcli radio wifi` returns `disabled` → "WiFi is disabled" with enable action
3. **No networks found** — scan returns empty list → "No networks in range"
4. **Scan error** — `nmcli` exits non-zero → "Could not scan for networks"

### Calendar No Edge Cases
- Month always has at least 28 days; the grid always renders
- Adjacent month days are always present (even for Dec 1 → prev month = Nov)
- Week number is always calculable
- No edge cases beyond year wrap-around (handled by JS Date constructor naturally)

---

## 6. Single Popup Management (D-31)

```qml
// In BarContent.qml
property Item currentPopup: null

function openPopup(popup) {
  if (currentPopup && currentPopup !== popup) {
    currentPopup.visible = false
  }
  currentPopup = popup
  popup.visible = true
}
```

Each popup's `onVisibleChanged` can notify a shared handler, or BarContent manages popup state via a counter that tracks which popup is currently open.

---

## 7. Architecture Summary

| Aspect | Decision |
|--------|----------|
| Window Type | `PopupWindow` (not PanelWindow) |
| Dismiss | `HyprlandFocusGrab` + `Keys.onEscapePressed` |
| Visibility | `visible: false` (not opacity) |
| Loading | Static `visible: false` (not LazyLoader) |
| Anchor | Fixed offset (VolumeOsd pattern) |
| Multi-popup | Single popup at a time (close previous) |
| Import | `import "./popups/" as Popups` in BarContent.qml |
| Qmldir | `services/qmldir` gets CalendarService entry; no popups/qmldir |
| CalendarService | `pragma Singleton` in services/ |
| Network scan | Self-contained Process in NetworkPopup.qml (D-21) |
| Hotplug cleanup | Natural (popups are children of BarContent Variants) |

---

*Research completed: 2026-05-22*
