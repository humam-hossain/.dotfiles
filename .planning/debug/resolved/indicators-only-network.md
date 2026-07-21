---
status: code_fixed
gap_ids: [G-02-7b, G-02-8]
phase: 02-core-bar-modules
created: 2026-07-22
updated: 2026-07-21T18:35:06Z
---

# Debug: Indicators pill shows only Network (+ empty space)

## Symptoms
- User sees only network icon on indicators pill
- Space after network, nothing else
- Confirmed on test 8: “no just network”

## Investigation
`BarContent.qml` indicatorsRowLayout (D-19 order):

| Icon | Visibility gate | Result when idle |
|------|-----------------|------------------|
| mute | `Revealer` only if `Audio.sink.muted` | hidden |
| mic | `Revealer` only if `Audio.source.muted` | hidden |
| xkb | `HyprlandXkbIndicator` active only if `layoutCodes.length > 1` | hidden (single layout) |
| Bluetooth | `visible: BluetoothStatus.available` | hidden (bluez DBus failed at runtime) |
| Network | always | **visible** |
| notif | `Revealer` only if silent \|\| unread > 0 | hidden |

Trailing empty space: Network `MaterialSymbol` always has `Layout.rightMargin: realSpacing` even when following children collapse to zero width.

## Root cause
1. **Conditional revealers / availability gates** — only Network is always shown. Idle desktop correctly shows “just network” under stock ii logic, but UAT expects a full always-visible strip (mute → mic → xkb → Bluetooth → Network → notif).
2. **Trailing margin** on Network creates a blank gap after the only visible icon.
3. Bluetooth often unavailable (bluez not registered) — still should show disabled glyph if always-visible.

## Fix direction
- Show mute/mic/bluetooth/network/notif **always** with state-dependent glyphs (not hide-when-idle)
- Keep D-19 order; whole pill still toggles right sidebar
- xkb: keep multi-layout gate OR show single-layout code (prefer keep multi-layout-only to avoid clutter; if always empty, acceptable if others always show)
- Fix margins: use RowLayout spacing or margin only between visible items; no orphan trailing space after Network

## Resolution

status: code_fixed (2026-07-21T18:35:06Z)
Code shipped via gap-closure plans 02-06..02-08. Awaiting human re-UAT via /gsd-verify-work 2.
