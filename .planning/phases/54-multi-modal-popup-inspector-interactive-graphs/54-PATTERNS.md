# Phase 54: Multi-Modal Popup Inspector & Interactive Graphs - Pattern Map

**Mapped:** 2026-10-10  
**Files analyzed:** 14 (9 QML components, 4 mock fixtures, 1 assert harness)  
**Analogs found:** 14 / 14  

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml` | component / container | event-driven / transform / presentation | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` & `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml` | exact |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBaseCard.qml` | component / container | presentation | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NoticeBox.qml` & `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherCard.qml` | role-match |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherHeroCard.qml` | component | request-response / presentation | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` & `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml` | exact |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml` | component | transform / event-driven / presentation | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/Graph.qml` | role-match |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAtmosphericCard.qml` | component | presentation | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml` & `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` | exact |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherWindCard.qml` | component | event-driven / presentation | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` & `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/ClippedFilledCircularProgress.qml` | role-match |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAqiCard.qml` | component | presentation | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` & `restow/quickshell/.config/quickshell/ii/services/WeatherGlyphs.qml` | role-match |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAstronomyCard.qml` | component | presentation / transform | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/Graph.qml` & `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml` | role-match |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAlertBanner.qml` | component | event-driven / presentation | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/Revealer.qml` & `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` | role-match |
| `tests/fixtures/weather/nominal.json` | config / fixture | file-I/O / static data | `capture/ii/.config/illogical-impulse/config.json` | role-match |
| `tests/fixtures/weather/severe_alerts.json` | config / fixture | file-I/O / static data | `capture/ii/.config/illogical-impulse/config.json` | role-match |
| `tests/fixtures/weather/heavy_rain.json` | config / fixture | file-I/O / static data | `capture/ii/.config/illogical-impulse/config.json` | role-match |
| `tests/fixtures/weather/sparse_offline.json` | config / fixture | file-I/O / static data | `capture/ii/.config/illogical-impulse/config.json` | role-match |
| `scripts/phase54-weather-assert.sh` | test / script | batch / automated validation | `scripts/phase53-weather-assert.sh` | exact |

---

## Pattern Assignments

### 1. `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml` (component, event-driven / presentation)

**Analogs:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` & `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml`

**Imports pattern** (`CpuGpuPopup.qml:1-10`):
```qml
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
```

**Popup container & anchoring pattern** (`CpuGpuPopup.qml:11-25`, `WeatherPopup.qml:9-17`):
```qml
StyledPopup {
    id: root

    // Screen height constraint with Flickable fallback (D-54-08, D-54-09)
    // Width locked to 440px
    implicitWidth: 440

    StyledFlickable {
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 8
            // 1. WeatherAlertBanner
            // 2. WeatherHeroCard
            // 3. WeatherGraph
            // 4. GridLayout (2x2 pairs: Atmospheric | Wind, AQI | Astronomy)
        }
    }
}
```

**Lifecycle & Performance Gating** (`CpuGpuPopup.qml:16-24`):
```qml
    onActiveChanged: {
        if (active) {
            GlobalStates.activeInspectorCount++;
        } else {
            GlobalStates.activeInspectorCount = Math.max(0, GlobalStates.activeInspectorCount - 1);
        }
    }

    Component.onDestruction: {
        if (active) {
            GlobalStates.activeInspectorCount = Math.max(0, GlobalStates.activeInspectorCount - 1);
        }
    }
```

---

### 2. `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBaseCard.qml` (component, presentation)

**Analogs:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NoticeBox.qml` & `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherCard.qml`

**Header, layout, and content alias pattern** (`NoticeBox.qml:6-15`, `WeatherCard.qml:7-18`):
```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    property string title: ""
    property string icon: ""
    property color headerColor: Appearance.colors.colOnSurfaceVariant

    default property alias content: cardContent.data

    radius: Appearance.rounding.small // 12px (D-54-04)
    color: Appearance.colors.colLayer2
    border.width: 1
    border.color: Appearance.colors.colOutlineVariant

    implicitWidth: layout.implicitWidth + 20
    implicitHeight: layout.implicitHeight + 20
    Layout.fillWidth: true

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        RowLayout {
            id: headerRow
            visible: root.title.length > 0 || root.icon.length > 0
            Layout.fillWidth: true
            spacing: 6

            MaterialSymbol {
                visible: root.icon.length > 0
                fill: 0 // Strict outline iconography (D-54-36)
                text: root.icon
                iconSize: 18
                color: root.headerColor
            }

            StyledText {
                visible: root.title.length > 0
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        Item {
            id: cardContent
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
```

---

### 3. `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherHeroCard.qml` (component, request-response / presentation)

**Analogs:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` & `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml`

**Temperature readout, condition glyph, and stale badge pattern** (`WeatherBar.qml:32-52`, `WeatherPopup.qml:20-53`):
```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

WeatherBaseCard {
    id: root

    // Expose model override for test fixtures (D-54-05)
    property var model: Weather.current
    property string city: Weather.city
    property string country: Weather.country
    property bool isStale: Weather.isStale
    property bool isOffline: Weather.isOffline
    property string observationTime: Weather.lastRefresh

    RowLayout {
        anchors.fill: parent
        spacing: 12

        // Large Temperature & Glyph
        RowLayout {
            spacing: 8
            MaterialSymbol {
                fill: 0
                iconSize: 36 // D-54-34
                text: root.model?.glyph || WeatherGlyphs.glyphDefault
                color: (root.isStale || root.isOffline) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.colors.colOnLayer1
            }

            StyledText {
                text: (root.model?.tempC !== undefined && root.model?.tempC !== null && root.model?.tempC !== "--") 
                      ? `${Math.round(Number(root.model.tempC))}°C` 
                      : "--°C"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: (root.isStale || root.isOffline) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.colors.colOnLayer1
            }
        }

        Item { Layout.fillWidth: true }

        // Location & Condition Metadata
        ColumnLayout {
            spacing: 2
            StyledText {
                text: root.city || "Dhaka"
                font.weight: Font.Bold
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: root.model?.desc || "Clear"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }
            RowLayout {
                spacing: 4
                // Stale / Offline Pill (D-54-32)
                Rectangle {
                    visible: root.isStale || root.isOffline
                    radius: Appearance.rounding.verysmall
                    color: Appearance.m3colors.m3errorContainer
                    implicitWidth: staleText.implicitWidth + 8
                    implicitHeight: staleText.implicitHeight + 4
                    StyledText {
                        id: staleText
                        anchors.centerIn: parent
                        text: root.isOffline ? "Offline" : "Stale"
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.m3colors.m3onErrorContainer
                    }
                }
                // Observation Time
                StyledText {
                    text: root.observationTime
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnSurfaceVariant
                }
                // Passive Reload Button (D-54-37, D-54-38)
                MaterialSymbol {
                    fill: 0
                    text: "refresh"
                    iconSize: 16
                    color: Appearance.colors.colOnSurfaceVariant
                    MouseArea {
                        anchors.fill: parent
                        enabled: !refreshAnimation.running
                        onClicked: {
                            refreshAnimation.restart();
                            Weather.getData(); // passive cache reload only
                        }
                    }
                    RotationAnimation on rotation {
                        id: refreshAnimation
                        running: false
                        from: 0; to: 360
                        duration: 600
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                    }
                }
            }
        }
    }
}
```

---

### 4. `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml` (component, transform / event-driven / presentation)

**Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/Graph.qml`

**Canvas 2D drawing & zero-repaint scrub pattern** (`Graph.qml:8-51`, `54-RESEARCH.md:278-338`):
```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.services

WeatherBaseCard {
    id: root

    title: "24-Hour Forecast"
    icon: "show_chart"

    // Model binding with automated test override (D-54-05)
    property var model: Weather.hourly
    property bool popupActive: true

    implicitHeight: 220
    Layout.fillWidth: true

    Item {
        anchors.fill: parent

        // 1. Static Canvas 2D: repaints ONCE when active or data changes (D-54-20, D-54-22)
        Canvas {
            id: graphCanvas
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            renderStrategy: Canvas.Immediate

            Connections {
                target: root
                function onModelChanged() { if (root.popupActive) graphCanvas.requestPaint(); }
                function onPopupActiveChanged() { if (root.popupActive) graphCanvas.requestPaint(); }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                // Draw 24h Monotone Splines, Gradient Fill, Dotted Guidelines, and Rain Bars
            }
        }

        // 2. Zero-Repaint Scrub Overlay: Pure QML visual items (D-54-20)
        Item {
            id: scrubOverlay
            anchors.fill: parent
            visible: scrubArea.containsMouse

            Rectangle {
                id: scrubHairline
                width: 1
                height: parent.height
                color: Appearance.colors.colOutlineVariant
                x: activeScrubX
            }

            Rectangle {
                id: snapDot
                width: 8; height: 8; radius: 4
                color: Appearance.colors.colPrimary
                border.width: 2
                border.color: Appearance.colors.colLayer2
                x: activeScrubX - 4
                y: activeScrubY - 4
            }

            Rectangle {
                id: tooltipPill
                radius: Appearance.rounding.verysmall
                color: Appearance.colors.colTooltip
                // Snapped tooltip text showing Time • Temp • Rain %
            }
        }

        MouseArea {
            id: scrubArea
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: mouse => {
                // Update activeScrubX and activeScrubY dynamically
                // STRICTLY ZERO graphCanvas.requestPaint() calls here!
            }
        }
    }
}
```

---

### 5. `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAtmosphericCard.qml` (component, presentation)

**Analogs:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml` & `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml`

**2x2 compact grid pattern** (`WeatherPopup.qml:55-91`, `CpuGpuPopup.qml:306-335`):
```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

WeatherBaseCard {
    id: root

    title: "Atmospheric"
    icon: "air"

    property var model: Weather.current

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: 6
        columnSpacing: 8

        // Cell 1: Humidity
        // Cell 2: Barometric Pressure
        // Cell 3: UV Index with qualitative rating
        // Cell 4: Visibility
    }
}
```

---

### 6. `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherWindCard.qml` (component, event-driven / presentation)

**Analogs:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml` & `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/ClippedFilledCircularProgress.qml`

**Circular compass rose & shortest-path rotation pattern** (`WeatherBar.qml:145-151`, `ClippedFilledCircularProgress.qml:36-50`):
```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

WeatherBaseCard {
    id: root

    title: "Wind & Direction"
    icon: "near_me"

    property var model: Weather.current
    property real targetDegree: Number(model?.windDegree) || 0
    property real currentDegree: targetDegree

    onTargetDegreeChanged: {
        // Shortest path interpolation (D-54-25, Pitfall 3)
        let diff = (targetDegree - (currentDegree % 360) + 540) % 360 - 180;
        currentDegree += diff;
    }

    Behavior on currentDegree {
        NumberAnimation {
            duration: 400
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // 56px Compass Rose Dial
        Item {
            implicitWidth: 56
            implicitHeight: 56

            // Cardinal marks (N highlighted in accent, E, S, W in muted)
            // Rotating needle pointing to currentDegree
        }

        // Numeric wind readouts (Speed km/h, Gusts km/h, 16-point direction)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
        }
    }
}
```

---

### 7. `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAqiCard.qml` (component, presentation)

**Analogs:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` & `restow/quickshell/.config/quickshell/ii/services/WeatherGlyphs.qml`

**EPA badge, 6-segment mini meter, and particulate readout pattern** (`CpuGpuPopup.qml:103-108`, `WeatherGlyphs.qml:114-137`):
```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

WeatherBaseCard {
    id: root

    title: "Air Quality"
    icon: "masks"

    property var model: Weather.aqi

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            spacing: 8
            // US-EPA Category Badge
            Rectangle {
                radius: Appearance.rounding.verysmall
                color: root.model?.color || WeatherGlyphs.getAqiColor(root.model?.epaIndex)
                implicitWidth: badgeText.implicitWidth + 10
                implicitHeight: badgeText.implicitHeight + 4

                StyledText {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.model?.category || "Unavailable"
                    font.weight: Font.Bold
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
        }

        // 6-Segment Mini Progress Meter (D-54-27)
        RowLayout {
            Layout.fillWidth: true
            spacing: 2
            Repeater {
                model: 6
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: (index + 1 <= (root.model?.epaIndex || 0)) 
                           ? WeatherGlyphs.getAqiColor(index + 1) 
                           : Appearance.colors.colLayer0Border
                }
            }
        }

        // Particulate Readouts (PM2.5 and PM10)
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: `PM2.5: ${root.model?.pm2_5 ?? "--"} µg/m³`
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colOnSurfaceVariant
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: `PM10: ${root.model?.pm10 ?? "--"} µg/m³`
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colOnSurfaceVariant
            }
        }
    }
}
```

---

### 8. `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAstronomyCard.qml` (component, presentation / transform)

**Analogs:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/Graph.qml` & `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml`

**Canvas 2D lunar disc & solar twilight pattern** (`Graph.qml:20-50`, `WeatherPopup.qml:92-101`, `WeatherGlyphs.qml:17-18`):
```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

WeatherBaseCard {
    id: root

    title: "Astronomy"
    icon: "nights_stay"

    property var model: Weather.astronomy

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Left Side: Sunrise & Sunset
        ColumnLayout {
            spacing: 4
            RowLayout {
                MaterialSymbol {
                    fill: 0
                    text: WeatherGlyphs.glyphSunrise
                    iconSize: 16
                    color: Appearance.m3colors.m3primary
                }
                StyledText {
                    text: root.model?.sunrise || "--:--"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer1
                }
            }
            RowLayout {
                MaterialSymbol {
                    fill: 0
                    text: WeatherGlyphs.glyphSunset
                    iconSize: 16
                    color: Appearance.m3colors.m3secondary
                }
                StyledText {
                    text: root.model?.sunset || "--:--"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Right Side: Canvas 2D Dynamic Lunar Disc & Illumination %
        RowLayout {
            spacing: 6
            Canvas {
                id: moonCanvas
                implicitWidth: 36
                implicitHeight: 36
                onPaint: {
                    var ctx = getContext("2d");
                    // Base dark circle + dynamic terminator arc via ctx.ellipse
                }
            }
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: root.model?.moonPhase || "Moon"
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: `${root.model?.moonIllumination ?? "--"}% Illuminated`
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
        }
    }
}
```

---

### 9. `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherAlertBanner.qml` (component, event-driven / presentation)

**Analogs:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/Revealer.qml` & `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml`

**Collapsible alert banner, drawer, and carousel pattern** (`Revealer.qml:8-25`, `WeatherBar.qml:69-136`):
```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Revealer {
    id: root

    property var model: Weather.alerts
    property int currentIndex: 0
    property bool expanded: false

    reveal: root.model && root.model.length > 0
    vertical: true
    Layout.fillWidth: true

    Rectangle {
        Layout.fillWidth: true
        radius: Appearance.rounding.small
        color: Appearance.m3colors.m3errorContainer
        border.width: 1
        border.color: WeatherGlyphs.getAlertColor(activeAlert?.severity)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            // Header Row (Click to toggle drawer)
            RowLayout {
                Layout.fillWidth: true
                MaterialSymbol {
                    fill: 0
                    text: "warning"
                    iconSize: 18
                    color: Appearance.m3colors.m3error
                }
                StyledText {
                    text: activeAlert?.headline || activeAlert?.event || "Severe Weather Alert"
                    font.weight: Font.Bold
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.m3colors.m3onErrorContainer
                    Layout.fillWidth: true
                }
                // Carousel stepping buttons if multiple alerts (D-54-31)
                // Expand/collapse chevron
            }

            // Advisory Text Drawer (Revealer)
            Revealer {
                reveal: root.expanded
                vertical: true
                StyledText {
                    text: activeAlert?.desc || ""
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.m3colors.m3onErrorContainer
                }
            }
        }
    }
}
```

---

### 10–13. `tests/fixtures/weather/*.json` (config / fixture, file-I/O / static data)

**Analog:** `capture/ii/.config/illogical-impulse/config.json` & `test_wwo_api/raw_response.json`

**Envelope Schema Pattern**:
```json
{
  "status": "nominal",
  "is_stale": false,
  "fetched_at": "2026-10-10T00:00:00Z",
  "data": {
    "current_condition": [
      {
        "temp_C": "28",
        "FeelsLikeC": "31",
        "weatherCode": "113",
        "weatherDesc": [{ "value": "Sunny" }],
        "humidity": "65",
        "pressure": "1012",
        "uvIndex": "7",
        "visibility": "10",
        "windspeedKmph": "14",
        "winddir16Point": "SSW",
        "winddirDegree": "200",
        "air_quality": {
          "us-epa-index": "2",
          "pm2_5": "18.4",
          "pm10": "32.1"
        }
      }
    ],
    "weather": [
      {
        "astronomy": [
          {
            "sunrise": "05:48 AM",
            "sunset": "05:32 PM",
            "moon_phase": "Waxing Gibbous",
            "moon_illumination": "82"
          }
        ],
        "hourly": [
          { "time": "0", "tempC": "26", "FeelsLikeC": "28", "chanceofrain": "0", "precipMM": "0.0" }
        ]
      }
    ],
    "nearest_area": [
      { "areaName": [{ "value": "Dhaka" }], "country": [{ "value": "Bangladesh" }] }
    ],
    "alerts": {
      "alert": []
    }
  }
}
```

---

### 14. `scripts/phase54-weather-assert.sh` (test / script, batch / automated validation)

**Analog:** `scripts/phase53-weather-assert.sh`

**Harness Structure Pattern** (`phase53-weather-assert.sh:1-60`, `phase53-weather-assert.sh:560-575`):
```bash
#!/usr/bin/env bash
set -euo pipefail

# ASVS L1 Root Privilege Prevention
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Error: Do not run as root" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass()    { printf '[PASS] %s\n' "$1"; }
fail()    { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info()    { printf '[INFO] %s\n' "$1"; }

# CLI Section Parsing & Quick Mode
RUN_SECTION=0
QUICK_MODE=0
# ...
```

**Node.js In-Memory QML AST & Logic Assertion Pattern** (`phase53-weather-assert.sh:240-353`):
```bash
node -e '
  const fs = require("fs");
  const code = fs.readFileSync(process.argv[1], "utf8");
  let failures = [];

  // Check required tokens and bindings
  if (!code.includes("Appearance.colors.colLayer2")) {
    failures.push("Missing colLayer2 surface color");
  }

  // Validate math/algorithms in headless mode
  // ...
  if (failures.length > 0) {
    console.error(failures.join("\n"));
    process.exit(1);
  }
' "$TARGET_FILE"
```

---

## Shared Patterns

### 1. Material 3 Design Tokens & Outline Iconography
- **Source:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml:128-132,190,205,255`
- **Apply to:** All 9 QML subcomponents
```qml
// Surface & Borders
color: Appearance.colors.colLayer2
radius: Appearance.rounding.small // 12px
border.color: Appearance.colors.colOutlineVariant

// Outline Iconography
MaterialSymbol {
    fill: 0 // Strict outline requirement (D-54-36)
    iconSize: 18
    color: Appearance.colors.colOnSurfaceVariant
}

// Fluid Animations
easing.type: Easing.BezierSpline
easing.bezierCurve: Appearance.animationCurves.expressiveEffects // [0.34, 0.80, 0.34, 1.00, 1, 1]
```

### 2. Defensive Optional Chaining & Cold-Boot Fallbacks
- **Source:** `restow/quickshell/.config/quickshell/ii/services/Weather.qml:193-210`
- **Apply to:** All weather cards (`WeatherHeroCard`, `WeatherAtmosphericCard`, `WeatherWindCard`, `WeatherAqiCard`, `WeatherAstronomyCard`)
```qml
// Neutral placeholders prevent runtime TypeError when cache is uninitialized (D-54-33, Pitfall 5)
text: root.model?.tempC !== undefined && root.model?.tempC !== null ? `${Math.round(Number(root.model.tempC))}°C` : "--°C"
text: root.model?.humidity ?? "--%"
text: root.model?.pressureHpa ?? "-- hPa"
```

### 3. Zero-Repaint Scenegraph Interactivity
- **Source:** `54-RESEARCH.md:278-338`
- **Apply to:** `WeatherGraph.qml`
```qml
// Canvas 2D repaints ONCE when data updates or popup opens (gated by root.active)
// Interactive hover scrub uses pure QML items (Rectangle, Text) tracking MouseArea.mouseX
// Result: 60fps scrub tracking with 0.0% CPU overhead, preserving idle CPU <= 1.68%
```

---

## No Analog Found

*None.* All 14 files have concrete in-tree analogs adhering to the Git-Tracked Source Gate (#3645).

---

## Metadata

**Analog search scope:**  
- `restow/quickshell/.config/quickshell/ii/`  
- `vendor/dots-hyprland/dots/.config/quickshell/ii/` (submodule tracked files)  
- `scripts/`  
- `capture/ii/`  

**Files scanned:** 120+  
**Pattern extraction date:** 2026-10-10  
