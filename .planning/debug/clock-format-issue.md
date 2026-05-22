# Debug Session: Clock Format String

## Root Cause
`ClockService.qml` passes a Python `strftime`-format string `"{:%a %Y-%m-%d %I:%M:%S %p}"` to `Qt.formatDateTime()`, but Qt uses its own format specifier system (single-letter codes like `ddd`, `yyyy`, `MM`, `hh`, `mm`, `ss`, `AP`) — not `%`-prefixed specifiers.

## Evidence
- ClockService.qml:8,18 — strftime format string
- 14-DISCUSSION-LOG.md:53 — Confirms copied from Waybar config
- Qt `QDateTime::toString` docs — single-letter codes, no `%` prefix

## Files Involved
- `.config/quickshell/services/ClockService.qml` (lines 8, 18)

## Fix Direction
Replace with Qt-compatible: `"ddd yyyy-MM-dd hh:mm:ss AP"`
