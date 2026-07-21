---
phase: 02-core-bar-modules
status: clean
reviewed: "2026-07-21T18:33:16Z"
scope: gap-closure plans 02-06, 02-07, 02-08
---

# Phase 2 Code Review (gap-closure)

**Scope:** StyledPopup.qml, ClockWidget.qml, BarContent.qml changes from 02-06..02-08  
**Verdict:** clean (advisory — no blockers)

## Findings

None blocking.

### Notes (non-blocking)

1. **StyledPopup.forceActive** defaults false — Battery/Resources/Weather consumers unchanged. Good.
2. **Clock pin** has no outside-click-to-dismiss beyond second click / hover leave when unpinned — matches plan; acceptable for UAT.
3. **Bluetooth always-visible** shows `bluetooth_disabled` when bluez DBus fails — correct for G-02-7b (full strip).
4. **HyprlandXkbIndicator** still multi-layout-only — zero width on single layout; intentional per plan.
5. **ActiveWindow.qml** remains on disk unused — intentional (do not delete file).

## Security

No new trust boundaries, IPC, or shell exec in gap diffs.
