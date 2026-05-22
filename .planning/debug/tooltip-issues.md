# Debug Session: Tooltip Issues

## Root Cause
`QtQuick.Controls.ToolTip` attached property cannot display tooltip popups inside Quickshell's `PanelWindow` — Wayland layer-shell surfaces have no `Overlay` infrastructure that `ApplicationWindow` provides. All 8 widgets use this broken mechanism (MemoryWidget, WeatherWidget, ForecastWidget, DiskWidget, NetworkWidget, PingWidget, VolumeWidget, MusicWidget).

## Evidence
- BarContent.qml:10 — Uses `PanelWindow` (Wayland layer-surface), not `ApplicationWindow`
- `QtQuick.Controls.ToolTip` requires `Overlay` infrastructure from `ApplicationWindow`
- `ModulePill.qml:5` — `default property alias content: inner.data` routes children to text-sized area
- memory.sh outputs Pango HTML markup in tooltip data

## Files Involved
- `.config/quickshell/widgets/MemoryWidget.qml` — ToolTip usage
- `.config/quickshell/widgets/WeatherWidget.qml` — ToolTip usage
- `.config/quickshell/widgets/ForecastWidget.qml` — ToolTip usage
- `.config/quickshell/widgets/DiskWidget.qml` — ToolTip usage
- `.config/quickshell/widgets/NetworkWidget.qml` — ToolTip usage
- `.config/quickshell/widgets/PingWidget.qml` — ToolTip usage
- `.config/quickshell/widgets/VolumeWidget.qml` — ToolTip usage
- `.config/quickshell/widgets/MusicWidget.qml` — ToolTip usage

## Fix Direction
Remove tooltip entirely (matches user preference). Remove `ToolTip.visible`, `ToolTip.text`, `HoverHandler` lines from all 8 widget files.
