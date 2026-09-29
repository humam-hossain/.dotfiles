# Debug Session: Network Pill Divider and Throughput Units

## Symptoms
User reported: "i don't see vertical divider, I see live throughput with directions but it just shows K not KB or just B I think KB is fine KB and B is fine yeah the ping are accurate everything is fine"

## Root Cause
1. `NetworkPingPill.qml` places `Rectangle { id: divider; implicitWidth: 1; Layout.fillHeight: true; color: Appearance.colors.colLayer0Border; opacity: 0.6 }` inside a `GridLayout` in `BarGroup`. `BarGroup` anchors the `GridLayout` with vertical centering (`verticalCenter: parent.verticalCenter`), but does not anchor top/bottom when horizontal. The `divider` `Rectangle` has default `implicitHeight: 0` and no `Layout.preferredHeight`, causing `Layout.fillHeight: true` to collapse to 0 height. In addition, `opacity: 0.6` on `colLayer0Border` makes it practically invisible.
2. `NetworkUsage.qml`'s `formatShortRate(bytesPerSec)` returns `"0K"` when `< 1024` and `Math.round(bytesPerSec/1024) + "K"` without "B" suffix.

## Fix Direction
1. In `NetworkPingPill.qml`, assign explicit `Layout.preferredHeight: 14`, `Layout.alignment: Qt.AlignVCenter`, and remove opacity or use a clear border color (`Appearance.colors.colOutlineVariant` or `Appearance.colors.colLayer0Border` with opacity 1.0).
2. In `NetworkUsage.qml`, update `formatShortRate` so that rates display clearly (e.g. `0 KB` or `KB`).
