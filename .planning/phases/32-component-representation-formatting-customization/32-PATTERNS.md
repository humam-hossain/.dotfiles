# Phase 32: Component Representation & Formatting Customization - Pattern Map

**Phase:** 32  
**Domain:** Quickshell 0.2.x QML Component Customization, GNU Stow `--no-folding` Overlay Architecture, Material Design 3 Color Token Coordination, PipeWire Link Group Telemetry, Pacman & AUR Update Aggregation  
**Output Target:** `.planning/phases/32-component-representation-formatting-customization/32-PATTERNS.md`  

---

## 1. File Inventory & Categorization

| Target File | Role | Data Flow | Closest Codebase Analog | Adaptation / Delta |
|---|---|---|---|---|
| `capture/ii/.config/illogical-impulse/config.json` | Config | File I/O | `capture/ii/.../config.json` (self) | Set `time.format` ("hh:mm:ss AP"), `time.secondPrecision` (true), `time.dateFormat` ("ddd, dd-MM-yyyy"), `utilButtons.showScreenRecord` (true), `resources.memoryWarningThreshold` (80), `resources.cpuWarningThreshold` (60), `resources.swapWarningThreshold` (70). |
| `~/.config/illogical-impulse/config.json` | Config | File I/O | `capture/ii/.../config.json` | Live runtime mirror synchronized with repo capture file. |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml` | Component | Event-driven | `vendor/.../bar/Resource.qml` | Add `property string customText`, `property int criticalThreshold`, dynamic text container width, and synchronized 2-tier visual alerting (Amber warning / Red critical) across circular progress ring, MaterialSymbol icon, and StyledText label. |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml` | Component | Event-driven | `vendor/.../bar/Resources.qml` | Format RAM as definite `X.X/Y.Y GB (ZZ%)` [D-01], dynamic Swap reveal (`shown: ResourceUsage.swapUsed > 0`) formatted identically to RAM [D-03], CPU percentage badge (`XX%`) [D-02], with custom 2-tier thresholds: RAM (80/90), Swap (70/85), CPU (60/90) [D-05]. |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml` | Component | Event-driven | `vendor/.../bar/ClockWidget.qml` | Replace unicode bullet dot glyph (`"•"`) with an 8px non-glyph subtle spacer [D-08] while preserving time, date, hover calendar popup, and sidebar toggle. |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml` | Component | Event-driven / Request-response | `vendor/.../bar/UtilButtons.qml` & `SysTray.qml` | New component: Dedicated pending updates status pill; dynamically hidden at count 0, reveals `system_update_alt` icon + count badge when updates > 0; launches `kitty -1 --hold=yes fish -i -c 'yay -Syu'` on click [D-18]. |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/SysTray.qml` | Component | Event-driven | `vendor/.../bar/SysTray.qml` | Refine `columnSpacing` from 15px to 4px matching `BarGroup` defaults [D-20, COMP-09]; retain monochrome tinting, Fcitx pinning, and expandable overflow drawer. |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | Component / Controller | Event-driven | `restow/.../bar/BarContent.qml` (Phase 31) & `vendor/.../BarContent.qml` | Remove `ActiveWindow` [D-15]; remove background scroll handlers and `ScrollHint` overlays [D-16]; auto-collapse `Media` pill when idle (`isPlaying`) [D-12]; connect `Privacy` Amber mic and Red screen share revealers [D-13]; mount `UpdatesButton` inside a `BarGroup` [D-18]. |
| `restow/quickshell/.config/quickshell/ii/services/Privacy.qml` | Service | Streaming / Event-driven | `vendor/.../services/Privacy.qml` | Resolve upstream array-to-boolean coercion bug (`[]` evaluates to `true`) using Array `.some()` returning primitive booleans [COMP-08, D-13]. |
| `restow/quickshell/.config/quickshell/ii/services/Updates.qml` | Service | Request-response / Event-driven | `vendor/.../services/Updates.qml` | Aggregate official Arch repositories (`checkupdates`) and AUR (`yay -Qua` / `yay -Qu`) non-blocking [D-18, COMP-07]; handle missing `pacman-contrib` gracefully without hanging. |
| `scripts/phase32-component-formatting-assert.sh` | Test | File I/O / Request-response | `scripts/phase31-overlay-pill-assert.sh` | 4-section automated Nyquist validation harness asserting JSON schema values, overlay symlink targets, QML AST/token patterns, and zero repo drift. |

---

## 2. Component Pattern Mappings

### 2.1. `capture/ii/.config/illogical-impulse/config.json` & `~/.config/illogical-impulse/config.json`

#### Role & Data Flow
Native dots-hyprland Tier 1 configuration file (JSON format, File I/O). Read by Quickshell on initialization and hot-reloads via `Config.options`. Modifies time display, date pattern, utility buttons suite, weather settings, and base resource thresholds.

#### Closest Codebase Analog
[capture/ii/.config/illogical-impulse/config.json](file:///home/pera/github_repo/.dotfiles/capture/ii/.config/illogical-impulse/config.json#L152-L183)

#### Upstream / Previous Configuration Excerpt
```json
// capture/ii/.config/illogical-impulse/config.json:152-175
        "resources": {
            "alwaysShowCpu": true,
            "alwaysShowSwap": true,
            "cpuWarningThreshold": 90,
            "memoryWarningThreshold": 95,
            "swapWarningThreshold": 85
        },
        "utilButtons": {
            "showColorPicker": true,
            "showDarkModeToggle": false,
            "showKeyboardToggle": true,
            "showMicToggle": true,
            "showPerformanceProfileToggle": true,
            "showScreenRecord": false,
            "showScreenSnip": true
        },
// lines 466-478:
    "time": {
        "dateFormat": "ddd, dd-MM-yyyy",
        "dateWithYearFormat": "dd/MM/yyyy",
        "format": "hh:mm:ss AP",
        "secondPrecision": true,
        "shortDateFormat": "dd/MM"
    },
```

#### Target Configuration Delta
```json
// Tier 1 Native JSON options to enforce
{
  "bar": {
    "resources": {
      "alwaysShowCpu": true,
      "alwaysShowSwap": true,
      "cpuWarningThreshold": 60,
      "memoryWarningThreshold": 80,
      "swapWarningThreshold": 70
    },
    "utilButtons": {
      "showColorPicker": true,
      "showDarkModeToggle": false,
      "showKeyboardToggle": true,
      "showMicToggle": true,
      "showPerformanceProfileToggle": true,
      "showScreenRecord": true,
      "showScreenSnip": true
    },
    "weather": {
      "city": "Dhaka",
      "enable": true,
      "enableGPS": false,
      "fetchInterval": 10,
      "useUSCS": false
    }
  },
  "time": {
    "dateFormat": "ddd, dd-MM-yyyy",
    "format": "hh:mm:ss AP",
    "secondPrecision": true
  }
}
```

#### Conventions & Invariants to Maintain
1. **JSON Formatting:** Maintain standard 4-space indentation and valid JSON syntax (no trailing commas).
2. **Dual Synchronization:** Apply changes synchronously to both `capture/ii/.config/illogical-impulse/config.json` (git tracked) and `~/.config/illogical-impulse/config.json` (live active).
3. **Threshold Alignment:** Base warning thresholds in JSON serve as seeds for `Resource.qml` defaults.

---

### 2.2. `restow/quickshell/.../bar/Resource.qml` (Metric Item & Synchronous Alerting)

#### Role & Data Flow
Reusable bar component representing an individual hardware resource metric (RAM, CPU, or Swap). Consumes reactive numerical percentages and optional string overrides. Renders a circular progress ring (`ClippedFilledCircularProgress`), a Material Symbol glyph (`MaterialSymbol`), and a text badge (`StyledText`).

#### Closest Codebase Analog
[vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Resource.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Resource.qml#L1-L93)

#### Upstream Flawed Pattern
```qml
// vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Resource.qml:8-70
Item {
    id: root
    required property string iconName
    required property double percentage
    property int warningThreshold: 100
    property bool shown: true
    // ...
    property bool warning: percentage * 100 >= warningThreshold

    RowLayout {
        // ...
        ClippedFilledCircularProgress {
            id: resourceCircProg
            // ...
            // ONLY circular ring turns red; icon and text remain unaffected!
            colPrimary: root.warning ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer
            accountForLightBleeding: !root.warning
            // ...
            MaterialSymbol {
                // Color remains static m3onSecondaryContainer under alert
                color: Appearance.m3colors.m3onSecondaryContainer
            }
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            // HARDCODED WIDTH PREVENTS DETAILED TEXT (e.g. "5.4/31.2 GB (17%)")
            implicitWidth: fullPercentageTextMetrics.width
            implicitHeight: percentageText.implicitHeight

            TextMetrics {
                id: fullPercentageTextMetrics
                text: "100" // No '%' sign
                font.pixelSize: Appearance.font.pixelSize.small
            }

            StyledText {
                id: percentageText
                anchors.centerIn: parent
                // Text color remains static colOnLayer1 under alert
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: `${Math.round(percentage * 100).toString()}` // Raw number without '%'
            }
        }
    }
}
```

#### Overlay Target Pattern (`restow/quickshell/.../bar/Resource.qml`)
```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property string iconName
    required property double percentage
    property string customText: ""
    property int warningThreshold: 100
    property int criticalThreshold: 100
    property bool shown: true
    clip: true
    visible: width > 0 && height > 0
    implicitWidth: resourceRowLayout.x < 0 ? 0 : resourceRowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    // Synchronized two-tier alert states (D-04, D-05)
    readonly property bool isCritical: (percentage * 100) >= criticalThreshold
    readonly property bool isWarning: !isCritical && ((percentage * 100) >= warningThreshold)
    readonly property color alertColor: isCritical ? Appearance.colors.colError : (isWarning ? "#FFA000" : "transparent")
    readonly property string displayText: customText.length > 0 ? customText : `${Math.round(percentage * 100).toString()}%`

    RowLayout {
        id: resourceRowLayout
        spacing: 2
        x: shown ? 0 : -resourceRowLayout.width
        anchors.verticalCenter: parent.verticalCenter

        ClippedFilledCircularProgress {
            id: resourceCircProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: root.percentage
            implicitSize: 20
            colPrimary: (root.isCritical || root.isWarning) ? root.alertColor : Appearance.colors.colOnSecondaryContainer
            accountForLightBleeding: !root.isCritical && !root.isWarning
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: resourceCircProg.implicitSize
                height: resourceCircProg.implicitSize
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    font.weight: Font.DemiBold
                    fill: 1
                    text: root.iconName
                    iconSize: Appearance.font.pixelSize.normal
                    // Synchronous icon color alerting (D-04)
                    color: (root.isCritical || root.isWarning) ? root.alertColor : Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            // Dynamic text width calculation preventing truncation (D-01)
            implicitWidth: root.customText.length > 0 ? percentageText.implicitWidth : fullPercentageTextMetrics.width
            implicitHeight: percentageText.implicitHeight

            TextMetrics {
                id: fullPercentageTextMetrics
                text: "100%"
                font.pixelSize: Appearance.font.pixelSize.small
            }

            StyledText {
                id: percentageText
                anchors.centerIn: parent
                // Synchronous text color alerting (D-04)
                color: (root.isCritical || root.isWarning) ? root.alertColor : Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: root.displayText
            }
        }

        Behavior on x {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: resourceRowLayout.x >= 0 && root.width > 0 && root.visible
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
}
```

#### Conventions & Invariants to Maintain
1. **Dynamic Width Unlocking:** When `customText` is supplied, `implicitWidth` MUST use `percentageText.implicitWidth`. When `customText` is empty, use `fullPercentageTextMetrics.width` with text `"100%"` to prevent 2-digit to 3-digit jitter.
2. **Synchronous Color Coordination:** When `isCritical` or `isWarning` is true, the circular progress ring (`colPrimary`), the icon glyph (`MaterialSymbol.color`), and the text label (`StyledText.color`) must ALL transition to `alertColor` synchronously.
3. **Amber Warning Token:** Use Material 3 Amber accent `#FFA000` (or `#FFB74D`) for warning; use `Appearance.colors.colError` for critical.

---

### 2.3. `restow/quickshell/.../bar/Resources.qml` (Bar Resources Layout)

#### Role & Data Flow
Aggregates RAM, Swap, and CPU `Resource` items inside the status bar. Consumes live metrics from `ResourceUsage` singleton (`ResourceUsage.memoryUsed`, `memoryTotal`, `swapUsed`, `swapTotal`, `cpuUsage`).

#### Closest Codebase Analog
[vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Resources.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Resources.qml#L1-L54)

#### Upstream Simple Representation Pattern
```qml
// vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Resources.qml:22-47
        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options.bar.resources.alwaysShowSwap && percentage > 0) || 
                (MprisController.activePlayer?.trackTitle == null) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu || 
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }
```

#### Overlay Target Pattern (`restow/quickshell/.../bar/Resources.qml`)
```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml
import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout
        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        // RAM: Definite gigabytes used / total + percentage badge (D-01, COMP-01)
        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            customText: `${(ResourceUsage.memoryUsed / (1024 * 1024)).toFixed(1)}/${(ResourceUsage.memoryTotal / (1024 * 1024)).toFixed(1)} GB (${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%)`
            warningThreshold: 80
            criticalThreshold: 90
        }

        // Swap: Dynamically revealed only when swap is actively in use (> 0%) (D-03, COMP-02)
        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: ResourceUsage.swapUsed > 0
            Layout.leftMargin: shown ? 6 : 0
            customText: `${(ResourceUsage.swapUsed / (1024 * 1024)).toFixed(1)}/${(ResourceUsage.swapTotal / (1024 * 1024)).toFixed(1)} GB (${Math.round(ResourceUsage.swapUsedPercentage * 100)}%)`
            warningThreshold: 70
            criticalThreshold: 85
        }

        // CPU: Planner review icon + percentage badge (D-02, COMP-02)
        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu || root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: 60
            criticalThreshold: 90
        }
    }

    ResourcesPopup {
        hoverTarget: root
    }
}
```

#### Conventions & Invariants to Maintain
1. **Math Precision:** Memory conversion must divide KB values from `/proc/meminfo` by `(1024 * 1024)` and format via `.toFixed(1)`. Percentage badge must round to the nearest integer via `Math.round(percentage * 100)`.
2. **Dynamic Swap Visibility:** Swap is shown strictly when `ResourceUsage.swapUsed > 0`. When 0, `shown: false` and `Layout.leftMargin: 0` removes all margin space.
3. **Threshold Specifics:** RAM (80% / 90%), Swap (70% / 85%), CPU (60% / 90%) per D-05.

---

### 2.4. `restow/quickshell/.../bar/ClockWidget.qml` (Time & Date Representation)

#### Role & Data Flow
Status bar clock and calendar widget. Consumes `DateTime.time` and `DateTime.longDate`. Manages hover preview of `ClockWidgetPopup`.

#### Closest Codebase Analog
[vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml#L1-L50)

#### Upstream Bullet Glyph Pattern
```qml
// vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml:14-38
    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: DateTime.time
        }

        // UNICODE BULLET GLYPH TO BE REMOVED (D-08)
        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: "•"
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: DateTime.longDate
        }
    }
```

#### Overlay Target Pattern (`restow/quickshell/.../bar/ClockWidget.qml`)
```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 0

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: DateTime.time
        }

        // Subtle non-glyph spacer replacing unicode bullet (D-08, COMP-03)
        Item {
            visible: root.showDate
            implicitWidth: 8
            implicitHeight: 1
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: DateTime.longDate
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}
```

#### Conventions & Invariants to Maintain
1. **Typography:** Keep `Appearance.font.pixelSize.large` for time and `small` for date.
2. **Interactions:** Retain `ClockWidgetPopup` hover target for calendar inspection and outer click handler toggling sidebar right.

---

### 2.5. `restow/quickshell/.../bar/UpdatesButton.qml` (Dedicated Package Updates Pill)

#### Role & Data Flow
Status bar widget providing real-time pending update telemetry and a one-click terminal upgrade launcher. Binds to `Updates.count`. Dispatches terminal execution via `Quickshell.execDetached`.

#### Closest Codebase Analogs
- [vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/UtilButtons.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/UtilButtons.qml#L23-L68) (button layout & execution)
- [vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/SysTray.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/SysTray.qml#L75-L103) (icon and sizing)

#### Target Implementation Pattern (`restow/quickshell/.../bar/UpdatesButton.qml`)
```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    implicitWidth: rowLayout.implicitWidth + 8
    implicitHeight: Appearance.sizes.barHeight
    visible: Updates.count > 0

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["kitty", "-1", "--hold=yes", "fish", "-i", "-c", "yay -Syu"]);
        }

        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                text: "system_update_alt"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colPrimary
            }

            StyledText {
                text: `${Updates.count}`
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
            }
        }
    }
}
```

#### Conventions & Invariants to Maintain
1. **Dynamic Visibility:** Must hide completely (`visible: Updates.count > 0` or enclosed in `BarGroup` loader `active: Updates.available && Updates.count > 0`) when 0 updates are pending.
2. **Command Vector:** Dispatch non-blocking detached command array `["kitty", "-1", "--hold=yes", "fish", "-i", "-c", "yay -Syu"]`. Never concatenate raw strings through shell interpolation.

---

### 2.6. `restow/quickshell/.../bar/SysTray.qml` (System Tray Refinement)

#### Role & Data Flow
Container for StatusNotifierItem (SNI) tray icons, pinned application shortcuts, and an expandable chevron overflow drawer.

#### Closest Codebase Analog
[vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/SysTray.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/SysTray.qml#L68-L157)

#### Upstream Wide Spacing Pattern
```qml
// vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/SysTray.qml:68-74
    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors.fill: parent
        rowSpacing: 8
        columnSpacing: 15 // <-- WIDE 15PX ICON SPACING (D-20)
```

#### Overlay Target Pattern (`restow/quickshell/.../bar/SysTray.qml`)
```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/SysTray.qml
// ... upstream imports and properties ...
    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors.fill: parent
        rowSpacing: 8
        columnSpacing: 4 // <-- BALANCED 4PX SPACING MATCHING BARGROUP (D-20, COMP-09)

        RippleButton {
            id: trayOverflowButton
            visible: root.showOverflowMenu && root.unpinnedItems.length > 0
            toggled: root.trayOverflowOpen
            // ... overflow menu logic preserved identically ...
```

#### Conventions & Invariants to Maintain
1. **Fidelity:** Retain all existing behavior: `HyprlandFocusGrab`, `overflowPopup`, `SysTrayItem` delegate bindings, and `Fcitx` pinned item preservation.
2. **Spacing Standard:** Enforce `columnSpacing: 4` across the grid layout.

---

### 2.7. `restow/quickshell/.../bar/BarContent.qml` (Modular Bar Layout Overlay)

#### Role & Data Flow
Primary status bar layout controller orchestrating left, center, and right sections. Manages component mounting, visibility bindings, sidebar toggle events, and revealer animations.

#### Closest Codebase Analogs
- [restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L50-L343) (established Phase 31)
- [vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarContent.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L50-L343)

#### Overlay Target Pattern (`restow/quickshell/.../bar/BarContent.qml`)
```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml: key excerpts

    // 1. Left Mouse Area: Scroll handlers and ScrollHint removed (D-16)
    MouseArea {
        id: barLeftSideMouseArea
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: middleSection.left
        }
        implicitWidth: leftSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }

        RowLayout {
            id: leftSectionRowLayout
            anchors.fill: parent
            spacing: 0

            LeftSidebarButton {
                id: leftSidebarButton
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Appearance.rounding.screenRounding
                colBackground: barLeftSideMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
            }

            // ActiveWindow removed per D-15
        }
    }

    // 2. Middle Section: Media Auto-Collapse (D-12)
    Row {
        id: middleSection
        // ...
        BarGroup {
            id: leftCenterGroup
            anchors.verticalCenter: parent.verticalCenter

            Resources {
                alwaysShowAllResources: root.useShortenedForm === 2
                Layout.fillWidth: root.useShortenedForm === 2
            }

            Media {
                // Dynamically collapse media pill when no track is actively playing (D-12, COMP-04)
                visible: (root.useShortenedForm < 2) && (MprisController.activePlayer?.isPlaying ?? false)
                Layout.fillWidth: true
            }
        }
        // ...
    }

    // 3. Right Mouse Area: Scroll handlers and ScrollHint removed (D-16)
    MouseArea {
        id: barRightSideMouseArea
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: middleSection.right
            right: parent.right
        }
        implicitWidth: rightSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight
        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }
        }

        RowLayout {
            id: rightSectionRowLayout
            anchors.fill: parent
            spacing: 5
            layoutDirection: Qt.RightToLeft

            RippleButton {
                id: rightSidebarButton
                // ...
                RowLayout {
                    id: indicatorsRowLayout
                    anchors.centerIn: parent
                    property real realSpacing: 15
                    spacing: 0

                    // Privacy In-Use Alerts (D-13, COMP-08)
                    // Amber Mic Alert (Direct click mutes active capture)
                    Revealer {
                        reveal: Privacy.micActive
                        Layout.fillHeight: true
                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                        Behavior on Layout.rightMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        RippleButton {
                            implicitWidth: 24
                            implicitHeight: 24
                            downAction: () => Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SOURCE@", "1"])
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "mic"
                                iconSize: Appearance.font.pixelSize.larger
                                color: "#FFA000"
                            }
                        }
                    }

                    // Red Screen Sharing Alert (Direct click opens recorder)
                    Revealer {
                        reveal: Privacy.screenSharing
                        Layout.fillHeight: true
                        Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                        Behavior on Layout.rightMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        RippleButton {
                            implicitWidth: 24
                            implicitHeight: 24
                            downAction: () => Quickshell.execDetached([Directories.recordScriptPath])
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "screen_share"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colError
                            }
                        }
                    }

                    // Standard status indicators retained (D-14, COMP-10)
                    Revealer {
                        reveal: Audio.sink?.audio?.muted ?? false
                        // ... volume_off ...
                    }
                    Revealer {
                        reveal: Audio.source?.audio?.muted ?? false
                        // ... mic_off ...
                    }
                    HyprlandXkbIndicator {
                        // ...
                    }
                    Revealer {
                        reveal: Notifications.silent || Notifications.unread > 0
                        // ...
                    }
                    MaterialSymbol {
                        text: Network.materialSymbol
                        // ...
                    }
                    MaterialSymbol {
                        visible: BluetoothStatus.available
                        // ...
                    }
                }
            }

            SysTray {
                visible: root.useShortenedForm === 0
                Layout.fillWidth: false
                Layout.fillHeight: true
                invertSide: Config?.options.bar.bottom
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Dedicated Updates Status Pill (D-18, COMP-07)
            Loader {
                Layout.leftMargin: 4
                active: Updates.available && Updates.count > 0
                sourceComponent: BarGroup {
                    UpdatesButton {}
                }
            }

            // Weather Widget Retained (D-19, COMP-05)
            Loader {
                Layout.leftMargin: 4
                active: Config.options.bar.weather.enable
                sourceComponent: BarGroup {
                    WeatherBar {}
                }
            }
        }
    }
```

#### Conventions & Invariants to Maintain
1. **Unclamped Middle Section:** Preserve the Phase 31 unclamped `leftCenterGroup` and `rightCenterGroup` geometry.
2. **Zero Accidental Jitter:** Background mouse scroll areas must NOT contain any `onScrollDown` or `onScrollUp` handlers.
3. **Smooth Revealers:** All privacy revealers and dynamic indicators must animate margins with `Appearance.animation.elementMoveFast`.

---

### 2.8. `restow/quickshell/.../services/Privacy.qml` (PipeWire Boolean Telemetry)

#### Role & Data Flow
Quickshell singleton service monitoring PipeWire link groups to detect active screen capture or microphone streams.

#### Closest Codebase Analog
[vendor/dots-hyprland/dots/.config/quickshell/ii/services/Privacy.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/services/Privacy.qml#L1-L17)

#### Upstream Buggy Coercion Pattern
```qml
// vendor/dots-hyprland/dots/.config/quickshell/ii/services/Privacy.qml:14-15
    // FLAGGED BUG: [].filter(...).map(...) yields [] which coerces to true!
    property bool screenSharing: Pipewire.linkGroups.values.filter(pwlg => pwlg.source.type === PwNodeType.VideoSource).map(pwlg => pwlg.target)
    property bool micActive: Pipewire.linkGroups.values.filter(pwlg => pwlg.source.type === PwNodeType.AudioSource && pwlg.target.type === PwNodeType.AudioInStream).map(pwlg => pwlg.target)
```

#### Overlay Target Pattern (`restow/quickshell/.../services/Privacy.qml`)
```qml
// restow/quickshell/.config/quickshell/ii/services/Privacy.qml
pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * Screensharing and mic activity with primitive boolean evaluation.
 */
Singleton {
    id: root

    readonly property bool screenSharing: Pipewire.linkGroups.values.some(pwlg => pwlg.source?.type === PwNodeType.VideoSource)
    readonly property bool micActive: Pipewire.linkGroups.values.some(pwlg => pwlg.source?.type === PwNodeType.AudioSource && pwlg.target?.type === PwNodeType.AudioInStream)
}
```

#### Conventions & Invariants to Maintain
1. **Boolean Primitive Guarantee:** Must use `.some(...)` with optional chaining (`pwlg.source?.type`). Returns strictly `true` or `false`.
2. **Singleton Declaration:** Maintain `pragma Singleton` and `pragma ComponentBehavior: Bound`.

---

### 2.9. `restow/quickshell/.../services/Updates.qml` (Arch + AUR Update Poller)

#### Role & Data Flow
Quickshell singleton service running periodic background update checks. Aggregates official Arch repositories and AUR packages. Exposes `available` and `count`.

#### Closest Codebase Analog
[vendor/dots-hyprland/dots/.config/quickshell/ii/services/Updates.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/services/Updates.qml#L1-L59)

#### Upstream Single-Repo Pattern
```qml
// vendor/dots-hyprland/dots/.config/quickshell/ii/services/Updates.qml:39-57
    Process {
        id: checkAvailabilityProc
        running: Config.ready && Config.options.updates.enableCheck
        command: ["which", "checkupdates"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0);
            root.refresh();
        }
    }

    Process {
        id: checkUpdatesProc
        command: ["bash", "-c", "checkupdates | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.count = parseInt(text.trim());
            }
        }
    }
```

#### Overlay Target Pattern (`restow/quickshell/.../services/Updates.qml`)
```qml
// restow/quickshell/.config/quickshell/ii/services/Updates.qml
pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/*
 * System updates service aggregating Arch repos and AUR packages (D-18).
 */
Singleton {
    id: root

    property bool available: false
    property alias checking: checkUpdatesProc.running
    property int count: 0
    
    readonly property bool updateAdvised: available && count > Config.options.updates.adviseUpdateThreshold
    readonly property bool updateStronglyAdvised: available && count > Config.options.updates.stronglyAdviseUpdateThreshold

    function load() {}
    function refresh() {
        if (!available) return;
        print("[Updates] Checking for system updates")
        checkUpdatesProc.running = true;
    }

    Timer {
        interval: Config.options.updates.checkInterval * 60 * 1000
        repeat: true
        running: Config.ready && Config.options.updates.enableCheck
        onTriggered: {
            print("[Updates] Periodic update check due")
            root.refresh();
        }
    }

    Process {
        id: checkAvailabilityProc
        running: Config.ready && Config.options.updates.enableCheck
        command: ["bash", "-c", "command -v checkupdates >/dev/null 2>&1 || command -v yay >/dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0);
            root.refresh();
        }
    }

    Process {
        id: checkUpdatesProc
        command: ["bash", "-c", "c=0; if command -v checkupdates >/dev/null 2>&1; then c=$((c + $(checkupdates 2>/dev/null | wc -l))); elif command -v yay >/dev/null 2>&1; then c=$((c + $(yay -Qu 2>/dev/null | wc -l))); fi; if command -v yay >/dev/null 2>&1; then c=$((c + $(yay -Qua 2>/dev/null | wc -l))); fi; echo $c"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = parseInt(text.trim());
                root.count = isNaN(parsed) ? 0 : parsed;
            }
        }
    }
}
```

#### Conventions & Invariants to Maintain
1. **Zero-Hang Fallback:** Availability check succeeds if either `checkupdates` OR `yay` is present.
2. **Dual-Repo Aggregation:** Count combines official repo updates + AUR updates (`yay -Qua`).
3. **Parse Safety:** Validate integer conversion via `isNaN(parsed) ? 0 : parsed`.

---

### 2.10. `scripts/phase32-component-formatting-assert.sh` (Nyquist Assertion Harness)

#### Role & Data Flow
Automated test suite enforcing 100% test coverage across Tier 1 JSON options, Tier 2 overlay symlinks, QML syntax/token rules, and system verifier cleanliness.

#### Closest Codebase Analog
[scripts/phase31-overlay-pill-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase31-overlay-pill-assert.sh#L1-L280)

#### Structure & Scaffold Pattern
```bash
#!/usr/bin/env bash
# Phase 32: Component Representation & Formatting Customization Assert Harness
# Enforces: COMP-01 through COMP-10 and D-01 through D-20
#
# Usage (from REPO_ROOT):
#   ./scripts/phase32-component-formatting-assert.sh [--section <1-4>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Boilerplate, traps, porcelain snapshots identical to Phase 31...
```

#### Section Assert Details
- **Section 1: Tier 1 Native JSON Configuration Integrity:**
  - Asserts `capture/ii/.../config.json` and `~/.config/illogical-impulse/config.json` using `jq`:
    - `time.format == "hh:mm:ss AP"`
    - `time.secondPrecision == true`
    - `time.dateFormat == "ddd, dd-MM-yyyy"`
    - `bar.utilButtons.showScreenRecord == true`
    - `bar.weather.city == "Dhaka"`
    - `bar.weather.useUSCS == false`
    - `bar.resources.memoryWarningThreshold == 80`
    - `bar.resources.cpuWarningThreshold == 60`
    - `bar.resources.swapWarningThreshold == 70`
- **Section 2: Symlink & Overlay Packaging Integrity:**
  - Asserts symlinks in `~/.config/quickshell/ii/`:
    - `modules/ii/bar/Resource.qml`
    - `modules/ii/bar/Resources.qml`
    - `modules/ii/bar/ClockWidget.qml`
    - `modules/ii/bar/UpdatesButton.qml`
    - `modules/ii/bar/SysTray.qml`
    - `modules/ii/bar/BarContent.qml`
    - `services/Privacy.qml`
    - `services/Updates.qml`
  - Asserts ancestor directories are real directories (no folding).
  - Asserts `vendor/dots-hyprland` working tree is clean.
- **Section 3: Component Representation & Formatting Rules:**
  - Asserts `Resource.qml`: `customText`, `criticalThreshold`, `alertColor`, synchronous recoloring, dynamic width.
  - Asserts `Resources.qml`: `X.X/Y.Y GB (ZZ%)` format, swap `shown: ResourceUsage.swapUsed > 0`, thresholds (80/90, 70/85, 60/90).
  - Asserts `ClockWidget.qml`: absence of `"•"`, presence of 8px spacer.
  - Asserts `BarContent.qml`: absence of `ActiveWindow`, absence of scroll handlers / `ScrollHint`, presence of Privacy revealers, Media `isPlaying` auto-collapse, `UpdatesButton` loader.
  - Asserts `Privacy.qml`: `.some(...)` predicate usage.
  - Asserts `SysTray.qml`: `columnSpacing: 4`.
  - Asserts `Updates.qml`: aggregated `checkupdates` + `yay -Qua` logic.
- **Section 4: Repository Hygiene & Verifier Gate:**
  - Asserts `./arch/dots-hyprland.sh verify --strict` exits 0 with 0 findings.
  - Asserts `git status --porcelain` is identical across run.

---

## 3. Cross-Cutting Operational Patterns

### 3.1. Safe Stow Overlay Deployment Procedure (Replacing Banned `--adopt`)
**Context:** `~/.config/quickshell/ii/modules/ii/bar/` and `~/.config/quickshell/ii/services/` contain regular files installed by dots-hyprland installer. GNU Stow refuses to create symlinks over existing regular files, and `--adopt` is strictly banned (`stow/README.md:64-73`).

**Execution Pattern:**
1. Populate repository overlay files:
   - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/{Resource.qml,Resources.qml,ClockWidget.qml,UpdatesButton.qml,SysTray.qml,BarContent.qml}`
   - `restow/quickshell/.config/quickshell/ii/services/{Privacy.qml,Updates.qml}`
2. Remove or backup regular files in `$HOME`:
   ```bash
   for f in Resource.qml Resources.qml ClockWidget.qml SysTray.qml; do
     target="$HOME/.config/quickshell/ii/modules/ii/bar/$f"
     [[ -f "$target" && ! -L "$target" ]] && rm -f "$target"
   done
   for s in Privacy.qml Updates.qml; do
     target="$HOME/.config/quickshell/ii/services/$s"
     [[ -f "$target" && ! -L "$target" ]] && rm -f "$target"
   done
   ```
3. Deploy the overlay symlinks with `--no-folding`:
   ```bash
   cd restow && stow --verbose=5 --no-folding -t ~ quickshell
   ```
4. Verify leaf symlinks and verify ancestor directories remain intact.

### 3.2. Live Quickshell Reload Pattern
**Context:** Quickshell caches QML in memory. After modifying or stowing overlay QML files, reload the shell process.  
**Methods:**
- Operator hotkey: `Ctrl+Super+R` (configured in `~/.config/hypr/hyprland/keybinds.lua:56`).
- Headless execution:
  ```bash
  killall qs quickshell 2>/dev/null || true
  nohup qs -c ii >/dev/null 2>&1 &
  ```

### 3.3. Two-Tier Color Token Mapping
| Alert Tier | State Name | Color Token | Visual Application |
|---|---|---|---|
| Tier 0 (Normal) | Baseline | `Appearance.colors.colOnSecondaryContainer` (Ring)<br/>`Appearance.m3colors.m3onSecondaryContainer` (Icon)<br/>`Appearance.colors.colOnLayer1` (Text) | Standard subtle contrast |
| Tier 1 (Warning) | Warning | Amber `#FFA000` | Synchronously applied to Ring, Icon, and Text |
| Tier 2 (Critical) | Critical / Error | `Appearance.colors.colError` (Red) | Synchronously applied to Ring, Icon, and Text |

---

## 4. Anti-Patterns to Avoid

| Anti-Pattern | Why Prohibited | Proper Alternative |
|---|---|---|
| Editing files in `vendor/dots-hyprland/` | Breaks submodule pin tracking, prevents clean vendor updates, and pollutes git tree. | Author changes exclusively in `restow/quickshell/` and stow into `$HOME`. |
| Running `stow` without `--no-folding` | Stow folds `~/.config/quickshell` into a directory symlink, destroying siblings and failing strict verification. | Always specify `stow --verbose=5 --no-folding -t ~ <pkg>`. |
| Using `stow --adopt` | Overwrites local repo changes with target files on disk. Strictly banned in repository policy. | Remove or backup live target files prior to stowing. |
| Hardcoding text container widths (`implicitWidth: 100`) | Truncates detailed memory strings like `5.4/31.2 GB (17%)` or causes visual clipping. | Use `implicitWidth: customText.length > 0 ? percentageText.implicitWidth : fullPercentageTextMetrics.width`. |
| Relying on JavaScript `[]` truthiness for boolean checks | Empty array `[]` coerces to `true` in QML, causing privacy alerts to remain permanently on. | Use Array `.some(...)` returning primitive boolean `true` or `false`. |
| Running raw shell commands with string concatenation | Introduces shell injection and escaping vulnerabilities. | Use fixed argument lists with `Quickshell.execDetached([...])`. |
| Hand-editing Section 3 in `restow/README.md` | Causes Phase 18 capture-model assertion failures due to byte discrepancies. | Run `./scripts/gen-collision-map.sh --restow-table` to update the section. |
| Using `qmllint` or `qmlformat` in bash assertions | Standalone Qt 6 tools crash on ECMAScript optional chaining (`?.`), causing false test failures. | Validate QML integrity via regex/token checks and live shell execution. |

---

*Pattern map generated for Phase 32 planning.*
