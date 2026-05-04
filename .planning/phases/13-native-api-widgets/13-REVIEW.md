---
phase: 13-native-api-widgets
reviewed: 2026-05-04T16:23:31Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - .config/quickshell/BarContent.qml
  - .config/quickshell/ModulePill.qml
  - .config/quickshell/services/AudioService.qml
  - .config/quickshell/services/HyprWorkspaces.qml
  - .config/quickshell/services/MprisService.qml
  - .config/quickshell/services/qmldir
  - .config/quickshell/widgets/MusicWidget.qml
  - .config/quickshell/widgets/TrayWidget.qml
  - .config/quickshell/widgets/VolumeWidget.qml
  - .config/quickshell/widgets/WorkspacesWidget.qml
  - .config/quickshell/widgets/qmldir
findings:
  critical: 0
  warning: 3
  info: 1
  total: 4
status: issues_found
---

# Phase 13: Code Review Report

**Reviewed:** 2026-05-04T16:23:31Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Reviewed the Phase 13 Quickshell QML services, widgets, and qmldir exports. Syntax-level `qmllint` passed for the scoped QML files, but a live Quickshell launch could not complete in this sandbox because Qt could not initialize Wayland/XCB. The main concerns are runtime correctness around panel sizing and native Hyprland/SystemTray API semantics.

## Warnings

### WR-01: Panel Has No Content-Driven Height Binding

**File:** `.config/quickshell/BarContent.qml:15`

**Issue:** `exclusiveZone` is bound to `height`, but the `PanelWindow` never assigns `height` or `implicitHeight`. The only visual content is a `RowLayout` anchored to the parent, and anchored children do not contribute an implicit size back to their parent. This can leave the panel at height `0`, making the bar invisible and reserving no exclusive zone despite the "content-driven" comment.

**Fix:**
```qml
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    implicitHeight: contentRow.implicitHeight + 8
    height: implicitHeight
    exclusiveZone: height

    RowLayout {
        id: contentRow
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            margins: 4
        }
        spacing: 0
        // existing groups...
    }
}
```

### WR-02: Urgent Workspace Tracking Parses Window Addresses As Workspace IDs

**File:** `.config/quickshell/services/HyprWorkspaces.qml:19`

**Issue:** Hyprland's `urgent` IPC event identifies the urgent window, not a workspace id. The code parses `event.data` as an integer and stores it in `urgentIds`, then `WorkspacesWidget` compares that value to `cell.modelData.id`. This means urgent workspaces will usually never highlight, or could highlight the wrong workspace if a window address happens to parse to a matching number. Quickshell's `HyprlandWorkspace` already exposes an `urgent` property.

**Fix:**
```qml
// services/HyprWorkspaces.qml
Singleton {
    readonly property var workspaces: Hyprland.workspaces.values
        .slice()
        .sort((a, b) => a.id - b.id)
        .filter(w => w.id >= 0 && !(w.name && w.name.startsWith("special:")))
}

// widgets/WorkspacesWidget.qml
color: cell.modelData.urgent ? Colours.critical
     : cell.modelData.active ? Colours.accent
     :                         Colours.textColor
```

### WR-03: Tray Click Handling Does Not Respect Menu Availability Or Only-Menu Items

**File:** `.config/quickshell/widgets/TrayWidget.qml:55`

**Issue:** Left click always calls `activate(mouse.x, mouse.y)`, even though the Quickshell `SystemTrayItem.activate` method is exposed without parameters, and some tray items advertise `onlyMenu`. Right click also assigns and opens `modelData.menu` without checking `hasMenu`. This risks broken clicks or runtime errors/no-ops for tray items that only expose a menu or expose no menu.

**Fix:**
```qml
onClicked: mouse => {
    const item = trayItem.modelData

    if (mouse.button === Qt.LeftButton) {
        if (item.onlyMenu && item.hasMenu) {
            item.display(root.hostWindow, mouse.x, mouse.y)
        } else {
            item.activate()
        }
    } else if (mouse.button === Qt.RightButton && item.hasMenu) {
        menuAnchor.anchor.item = trayItem
        menuAnchor.anchor.rect = Qt.rect(0, trayItem.height, trayItem.width, 0)
        menuAnchor.menu = item.menu
        menuAnchor.open()
    }
}
```

## Info

### IN-01: MPRIS Display String Leaves Dangling Separators

**File:** `.config/quickshell/widgets/MusicWidget.qml:12`

**Issue:** `raw` always concatenates artist, separator, and title before trimming. If only the title or only the artist is present, the widget can display strings like `- Track` or `Artist -`.

**Fix:** Build the title from non-empty parts before truncating.

```qml
readonly property string raw: p ? [p.trackArtist, p.trackTitle].filter(Boolean).join(" - ") : ""
```

---

_Reviewed: 2026-05-04T16:23:31Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
