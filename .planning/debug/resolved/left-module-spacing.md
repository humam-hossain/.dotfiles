---
status: diagnosed
gap_id: G-02-9
phase: 02-core-bar-modules
created: 2026-07-22T04:38:23Z
---

# Debug: Left module spacing incoherent

## Symptom

After ActiveWindow removal, left bar modules (sidebar → workspaces → resources) look too far apart / uneven spacing.

## Investigation

`BarContent.qml` left cluster:

```qml
RowLayout {
    id: leftSectionRowLayout
    anchors.fill: parent   // fills entire left half (to middleSection)
    spacing: 0

    LeftSidebarButton { Layout.leftMargin: Appearance.rounding.screenRounding }
    Workspaces { Layout.leftMargin: 10; Layout.rightMargin: 4 }
    Resources { Layout.rightMargin: Appearance.rounding.screenRounding }
}
```

- Pre-02-07, `ActiveWindow` sat between sidebar and workspaces with `Layout.fillWidth: true` (spacer).
- Post-02-07, ActiveWindow gone; `Layout.leftMargin: 10` moved onto Workspaces (was ActiveWindow's left margin).
- Center cluster uses `BarGroup` + `spacing: 4` — left has no group and uneven margins.
- `barLeftSideMouseArea` stretches left→center; visual empty region after Resources is large, making the three modules feel sparse.

## Root cause

Left cluster margins and grouping were never re-tuned after ActiveWindow removal. Uneven margins + no compact group container → incoherent spacing.

## Fix direction

1. Set `leftSectionRowLayout.spacing` to a small uniform value (4–8).
2. Normalize margins: outer screenRounding only; remove ad-hoc 10px Workspaces leftMargin or replace with spacing.
3. Optionally wrap Workspaces+Resources (or all three) in `BarGroup` for visual cohesion matching center.

## Files

- `.config/quickshell/modules/ii/bar/BarContent.qml`
