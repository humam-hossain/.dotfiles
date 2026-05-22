# Phase 15: Popup Panels - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-22
**Phase:** 15-popup-panels
**Areas discussed:** Calendar data source, Calendar visual style, Calendar day cells, Calendar month nav, Week numbers, Grid rows, First day of week, Adjacent month days, Weekend tint, Month header format, Font, Day click behavior, Popup height, Range limit, Network content scope, Connection actions, IP detail, Panel layout, Signal display, Secured icons, Password prompt UX, Connect feedback, Empty state, Section ordering, Disconnect UX, Scan location, Panel width, Auto-refresh, Scroll, Keyboard nav, Popup infrastructure, qmldir, LazyLoader vs static, Single popup at a time, Escape dismiss, Anchor strategy, P-15 handling, Phase 14 sequencing, POPUP-03 pre-built status

---

## Calendar Popup — Data Source

| Option | Description | Selected |
|--------|-------------|----------|
| Inline JS in CalendarPopup.qml | Simpler — no new service file. Matches VolumeOsd self-contained pattern. | |
| CalendarService singleton | Reusable by Phase 16 animations. Keeps popup file thinner. | ✓ |

## Calendar Popup — Day Cell Interaction

| Option | Description | Selected |
|--------|-------------|----------|
| Display-only + highlight | Today gets accent background. Other days static. | |
| Clickable day cells | Visual highlight only (no popup close). Sets up for future features. | ✓ |

## Calendar Popup — Visual Density

| Option | Description | Selected |
|--------|-------------|----------|
| Compact (~36x36 cells) | Matches bar aesthetic. | ✓ |
| Spacious (~44x44 cells) | Easier to read. | |

## Calendar Popup — Month Navigation

| Option | Description | Selected |
|--------|-------------|----------|
| Nerd Font arrows (/) | Minimal, fits compact bar. | ✓ |
| Text buttons ('< Prev' / 'Next >') | More explicit, uses more space. | |

## Calendar Popup — Week Numbers

| Option | Description | Selected |
|--------|-------------|----------|
| No week numbers | Simpler 7-column grid. | |
| Yes, first column | ISO week number column. | ✓ |

## Calendar Popup — Day-of-Week Headers

| Option | Description | Selected |
|--------|-------------|----------|
| Yes (S M T W T F S) | Standard calendar UX. | ✓ |
| No | Just the number grid. | |

## Calendar Popup — Adjacent Month Days

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, grayed out (subtextColor) | Fills first/last week gaps. | ✓ |
| No, leave blank | Simpler. | |

## Calendar Popup — Weekend Highlight

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, subtle tint (subtext0) | Standard calendar UX. | ✓ |
| No, uniform days | Cleaner look. | |

## Calendar Popup — First Day of Week

| Option | Description | Selected |
|--------|-------------|----------|
| Monday (ISO) | Matches Asia/Dhaka convention. | ✓ |
| Sunday (US) | Common desktop default. | |

## Calendar Popup — Month Header Format

| Option | Description | Selected |
|--------|-------------|----------|
| "May 2026" | Natural language. | ✓ |
| "2026-05" | ISO-style, compact. | |

## Calendar Popup — Month Header Font

| Option | Description | Selected |
|--------|-------------|----------|
| Same 14px bold as day cells | Uniform. | ✓ |
| Slightly larger 16px bold | Visual hierarchy. | |

## Calendar Popup — Day Click Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| No close — visual only | Keeps popup open, non-disruptive. | ✓ |
| Yes, closes on click | More interactive. | |

## Calendar Popup — Grid Rows

| Option | Description | Selected |
|--------|-------------|----------|
| Auto (5 or 6 rows) | Accommodates all months. Fixed 6-row height for uniformity. | ✓ |
| Fixed 6 rows always | Height never changes. | (Same outcome — fixed 6-row height chosen) |

## Calendar Popup — Month Range Limit

| Option | Description | Selected |
|--------|-------------|----------|
| No limit | Browse any month indefinitely. | ✓ |
| ±24 months | Prevents accidental long scroll. | |

## Calendar Popup — Today Highlight Style

| Option | Description | Selected |
|--------|-------------|----------|
| Colours.accent background | Mauve fill. | ✓ |
| Colored text only | Subtler. | |

## Network Panel — Content Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Current connection only | SSID + IP, reuse NetworkService. | |
| Full WiFi scan + status | nmcli dev wifi. Shows available networks. | ✓ |

## Network Panel — Connection Actions

| Option | Description | Selected |
|--------|-------------|----------|
| Display-only info | Shows current connection info. | |
| Click-to-connect | Inline password prompt for secured networks. | ✓ |

## Network Panel — IP Detail

| Option | Description | Selected |
|--------|-------------|----------|
| IPv4 only | Simpler. | |
| Full network info (IPv4, IPv6, gateway, DNS) | More informative. | ✓ |

## Network Panel — Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Info-panel style (connection header + list) | Structured. | ✓ |
| List-only | Simpler QML. | |

## Network Panel — Signal Display

| Option | Description | Selected |
|--------|-------------|----------|
| Nerd Font bars (same as NetworkWidget) | Consistent. | ✓ |
| Percentage text | More precise. | |

## Network Panel — Secured Network Icon

| Option | Description | Selected |
|--------|-------------|----------|
| Lock icon () for secured | Standard WiFi list UX. | ✓ |
| Color difference (green = open) | Subtle visual. | |

## Network Panel — Password Prompt UX

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, eye toggle + Cancel + Submit | Full form UX. | ✓ |
| Submit only | Simpler. | |

## Network Panel — Connect Feedback

| Option | Description | Selected |
|--------|-------------|----------|
| Loading spinner + error/success | Full UX with inline error. | ✓ |
| Silent attempt | No indicator. | |

## Network Panel — Empty State

| Option | Description | Selected |
|--------|-------------|----------|
| Detailed message (no adapter / no networks / disabled) | Based on nmcli error. | ✓ |
| "No networks found" | Static text. | |

## Network Panel — Section Ordering

| Option | Description | Selected |
|--------|-------------|----------|
| Connection status on top, networks below | Primary info first. | ✓ |
| Networks on top, connection below | Action-first. | |

## Network Panel — Disconnect Button

| Option | Description | Selected |
|--------|-------------|----------|
| Connection header area | Always visible regardless of scroll. | ✓ |
| Connected network row | More contextual. | |

## Network Panel — WiFi Scan Location

| Option | Description | Selected |
|--------|-------------|----------|
| Inside NetworkPopup.qml | Self-contained concern separation. | ✓ |
| Extend NetworkService | Centralized but couples widget + popup. | |

## Network Panel — Width

| Option | Description | Selected |
|--------|-------------|----------|
| Content-driven | Adjusts to longest SSID. | ✓ |
| Fixed 320px | Predictable layout. | |

## Network Panel — Auto-Refresh

| Option | Description | Selected |
|--------|-------------|----------|
| Static snapshot on open | Simpler. | |
| Auto-refresh every 10s | Live list updates. | ✓ |

## Network Panel — Scrollable List

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, scrollable (Flickable) | Handles dense urban areas (15+ networks). | ✓ |
| No, show top 8 | Simpler QML. | |

## Network Panel — Keyboard Navigation

| Option | Description | Selected |
|--------|-------------|----------|
| Full keyboard UX (Tab, arrows, Enter) | Accessible. | ✓ |
| Minimal (Escape only) | Mouse-driven. | |

## Popup Infrastructure — Import Pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Direct import `import "./popups/" as Popups` | No qmldir. Consistent with VolumeOsd. | ✓ |
| Add popups/qmldir | Matches services/ and widgets/ convention. | |

## Popup Infrastructure — Loading Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Static `visible: false` | Simple, predictable. | ✓ |
| LazyLoader pre-loaded | P-17 prevention. | |

## Popup Infrastructure — Multiple Popups

| Option | Description | Selected |
|--------|-------------|----------|
| Close previous | Single popup at a time. | ✓ |
| Allow concurrent | User dismisses each independently. | |

## Popup Infrastructure — Escape Dismiss

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, Escape closes | In addition to outside-click. | ✓ |
| Outside-click only | Simpler. | |

## Popup Infrastructure — Anchor Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed offset (preset position) | Simpler approximation. Matches VolumeOsd. | ✓ |
| Widget coordinate calculation | Precise per-widget placement. | |

## Popup Infrastructure — P-15 Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Natural cleanup | PopupWindow destroyed with parent. No explicit handler needed. | ✓ |
| Explicit Component.onDestruction | Add close handler for safety. | |

## Popup Infrastructure — Password Prompt Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Sits above network list | User sees both form and available networks. | ✓ |
| Replaces network list | Cleaner layout. | |

## Phase Sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| Wait for Phase 14 close | Stable base preferred. | ✓ |
| Start Phase 15 now | No shared code blocks. | |

---

*Discussion completed: 2026-05-22*
