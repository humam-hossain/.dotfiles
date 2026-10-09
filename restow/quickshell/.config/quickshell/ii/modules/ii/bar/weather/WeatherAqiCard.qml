import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

WeatherBaseCard {
    id: root

    property var model: Weather.aqi

    icon: "masks"
    Layout.fillWidth: true
    title: "Air Quality"

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // Category Badge Row
        RowLayout {
            spacing: 6

            Rectangle {
                color: root.model?.color || WeatherGlyphs.getAqiColor(root.model?.epaIndex || 0)
                implicitHeight: badgeText.implicitHeight + 4
                implicitWidth: badgeText.implicitWidth + 8
                radius: Appearance.rounding.verysmall

                StyledText {
                    id: badgeText

                    anchors.centerIn: parent
                    color: "#000000"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.Bold
                    text: `EPA ${root.model?.epaIndex || "--"} • ${root.model?.category || "Unavailable"}`
                }
            }
        }

        // 6-Segment Mini Progress Meter (D-54-27)
        RowLayout {
            Layout.fillWidth: true
            spacing: 3

            Repeater {
                model: 6

                Rectangle {
                    Layout.fillWidth: true
                    color: (index + 1 <= (root.model?.epaIndex || 0)) ? WeatherGlyphs.getAqiColor(index + 1) : Appearance.colors.colOutlineVariant
                    implicitHeight: 4
                    radius: 2
                }
            }
        }

        // Fine Particulate Concentrations
        RowLayout {
            Layout.fillWidth: true

            StyledText {
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.smallest
                text: `PM2.5: ${root.model?.pm2_5 ?? "--"} µg/m³`
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.smallest
                text: `PM10: ${root.model?.pm10 ?? "--"} µg/m³`
            }
        }
    }
}
