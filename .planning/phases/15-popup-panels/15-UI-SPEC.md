# UI-SPEC: Phase 15 — Popup Panels

**Generated:** 2026-05-22
**Source:** 15-CONTEXT.md (37 decisions)
**Confidence:** HIGH

---

## 1. Calendar Popup

### Trigger
- ClockWidget click → open CalendarPopup (D-01)
- Day cell click is visual-only — does NOT close popup (D-05, D-36)

### Layout
```
┌─────────────────────────────────┐
│  ◀    May 2026        ▶        │  ← Month header + nav arrows
├──┐ ┌──┬──┬──┬──┬──┬──┬──┐      │
│WN│ │Mo│Tu│We│Th│Fr│Sa│Su│      │  ← Day-of-week header row
├──┘ └──┴──┴──┴──┴──┴──┴──┘      │
│ 18 │ 1│ 2│ 3│ 4│ 5│ 6│ 7│      │  ← Wk 18, May 1-7
│ 19 │ 8│ 9│10│11│12│13│14│      │
│ 20 │15│16│17│18│19│20│21│      │  ← Today (accent bg)
│ 21 │22│23│24│25│26│27│28│      │
│ 22 │29│30│31│ 1│ 2│ 3│ 4│      │  ← Adjacent grayed
│ 23 │ 5│ 6│ 7│ 8│ 9│10│11│      │  ← 6th row (fixed height)
└────┴──┴──┴──┴──┴──┴──┴──┘
```

### Components

**Month Header**
- Format: `"May 2026"` — natural language, month-first (D-11)
- Font: 14px bold, same as day cells (D-12)
- Left arrow: Nerd Font  (prev month)
- Right arrow: Nerd Font  (next month)
- No range limit on nav (D-09)

**Day-of-Week Header Row**
- Mon–Sun order (ISO standard, D-03)
- Single-letter abbreviations: M T W T F S S (D-02)

**Week Number Column**
- ISO 8601 week numbers in first column (D-08)
- Left of day-of-week headers

**Day Grid**
- 36x36px cells (D-04)
- 7-column grid (Mon–Sun) + 1 column for week numbers
- Fixed height sufficient for 6 rows (D-10)
- Auto-adjusts between 5–6 row months but popup uses fixed 6-row height so size doesn't jump

**Day Cell Visual States**
| State | Background | Text Color |
|-------|-----------|------------|
| Today | `Colours.accent` (mauve) solid | `Colours.base` or high contrast |
| Current month, other days | `transparent` | `Colours.textColor` |
| Adjacent month days | `transparent` | `Colours.subtextColor` (grayed) |
| Weekend (Sat/Sun) | `Colours.subtext0` at low opacity | `Colours.textColor` |
| Clicked/highlighted | Slightly lighter than accent | `Colours.base` |

### Dismiss
- Outside click via `HyprlandFocusGrab` (D-28)
- Escape key (D-32)

---

## 2. Network Panel

### Trigger
- NetworkWidget click → open NetworkPopup (D-14)
- Replaces previous behavior (nmtui open in kitty)

### Layout
```
┌─────────────────────────────────────┐
│  Connected: MyWiFi                   │
│  IP: 192.168.1.5 (IPv4)             │  ← Connection Status (Section 1)
│  IP: fe80::xxxx (IPv6)               │
│  Gateway: 192.168.1.1                │
│  DNS: 8.8.8.8, 1.1.1.1              │
│  Type: WiFi  ·  Signal: 󰤥 75%       │
│  [Disconnect]                        │
├──────────────────────────────────────┤
│  Available Networks                  │  ← Section 2 Header
│  ┌────────────────────────────────┐  │
│  │ 󰤥 MyNetwork                  │  │  ← Connected (highlighted bg)
│  │ 󰤢 NeighborNet                │  │
│  │ 󰤯 FarAway                    │  │
│  │ 󰤟 OpenWiFi                    │  │  ← Open (no lock icon)
│  │ 󰤨 Office_Guest               │  │
│  └────────────────────────────────┘  │  ← Flickable scroll area
├──────────────────────────────────────┤
│  Old open network: Connect in nmtui  │  ← Footer (D-26)
└──────────────────────────────────────┘
```

### Connection Status Section (D-15, D-16)
- SSID: connected network name
- IP address: IPv4 + IPv6
- Gateway
- DNS servers
- Connection type: WiFi / Ethernet
- Signal strength: Nerd Font bars + percentage
- Disconnect button

### Available Networks Section (D-17, D-23)
- Each row: signal bars + SSID + lock icon () for secured
- Connected network highlighted with background color (D-18)
- Scrollable via `Flickable` / `ScrollView`
- Auto-refresh every 10s (D-22)
- Content-driven width (adjusts to longest SSID) (D-24)

### Signal Bar Thresholds
| Range | Icon | Meaning |
|-------|------|---------|
| 0-20% | 󰤯 | Weak |
| 21-40% | 󰟟 | Fair |
| 41-60% | 󰤢 | Good |
| 61-100% | 󰤥 | Excellent |

### Password Prompt (D-19, D-20)
```
┌───────────────────────────┐
│ Connect to: SecuredNet    │
│ Password: 󰛐 ●●●●●●●●  │  ← Masked field + eye toggle
│                           │
│  [Cancel]    [Connect]    │
│                           │
│ ⚠ Wrong password          │  ← Inline error (if failed)
│ ───────────────────────── │
│ (network list below)      │
└───────────────────────────┘
```
- Sits above the network list (doesn't replace it) (D-19)
- Eye icon toggles: 󰛐 (masked) / 󰛑 (visible) (D-19)
- Cancel button clears prompt
- Connect button submits
- Loading spinner during connection attempt (D-20)
- Error message on wrong password (D-20)
- Success → highlight SSID as connected (D-20)

### Dismiss
- Outside click via `HyprlandFocusGrab`
- Escape key
- **Important:** Password prompt must close if popup is dismissed

### Empty State Messages (D-25)
| Condition | Message |
|-----------|---------|
| No wireless adapter | "No wireless adapter detected" |
| WiFi disabled | "WiFi is disabled" |
| No networks in range | "No networks found in range" |
| Scan error | "Could not scan for networks. Check NetworkManager." |

### Keyboard Navigation (D-35)
| Key | Action |
|-----|--------|
| Tab | Cycle: network list → password → eye toggle → Cancel → Connect |
| Shift+Tab | Reverse cycle |
| Up/Down | Navigate SSID list rows |
| Enter | If SSID selected + secured → focus password; if open → connect; if password has focus → submit |
| Escape | Close popup |

---

## 3. Notification Center Toggle (POPUP-03)

**Pre-built in Phase 14 (D-27).** No new QML popup file needed.

- Click NotificationWidget → `swaync-client -t` (already implemented)
- Phase 15 verifies this works in the end-to-end bar context

---

## 4. Shared Behavior

### Single Popup At A Time (D-31)
- Opening CalendarPopup closes NetworkPopup (if open)
- Opening NetworkPopup closes CalendarPopup (if open)
- Notification center toggle (swaync) is independent — not affected by this rule

### Dismiss Methods (D-28, D-32)
| Method | Implemented By |
|--------|---------------|
| Outside click | `HyprlandFocusGrab.onCleared` |
| Escape key | `Keys.onEscapePressed` in popup |
| Open another popup | Single-popup management in BarContent |

### Anchor Strategy (D-33)
- Fixed horizontal offset (preset position, not per-widget coordinate calc)
- Vertical offset: bar height + 12px
- Pattern: `anchor.rect.x: parentWindow.width / 2 - implicitWidth / 2`

### Hotplug Cleanup (D-34)
- PopupWindow is child of BarContent, auto-destroyed when parent Variants delegate is destroyed
- No explicit `Component.onDestruction` needed

### Styling
- Inherits Catppuccin Mocha colors from `Colours.qml`
- JetBrainsMono Nerd Font for all text
- Pill-shaped module containers (border-radius inherited from ModulePill)

---

## 5. Color Map

| Token | Usage | Hex |
|-------|-------|-----|
| `Colours.accent` | Today highlight, active states | Mauve (see Colours.qml) |
| `Colours.moduleBg` | Popup background | Surface0 (see Colours.qml) |
| `Colours.textColor` | Primary text | Text (see Colours.qml) |
| `Colours.subtextColor` | Adjacent-month days, secondary text | Subtext (see Colours.qml) |
| `Colours.subtext0` | Weekend tint (low opacity) | Subtext0 (see Colours.qml) |
| `Colours.critical` | Error state | Red (see Colours.qml) |

---

*UI-SPEC generated from 15-CONTEXT.md decisions*
