import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

WeatherBaseCard {
    id: root

    property var model: Weather.current

    icon: "air"
    Layout.fillWidth: true
    title: "Atmospheric"

    function getUvRisk(uv) {
        const val = parseInt(uv, 10);
        if (isNaN(val) || val <= 2)
            return "Low";
        if (val <= 5)
            return "Moderate";
        if (val <= 7)
            return "High";
        if (val <= 10)
            return "Very High";
        return "Extreme";
    }

    GridLayout {
        anchors.fill: parent
        columnSpacing: 10
        columns: 2
        rowSpacing: 8

        // 1. Humidity Cell
        RowLayout {
            spacing: 6

            MaterialSymbol {
                color: Appearance.colors.colPrimary
                fill: 0
                iconSize: 18
                text: "humidity_percentage"
            }

            ColumnLayout {
                spacing: 1

                StyledText {
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    text: "Humidity"
                }

                StyledText {
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    text: root.model?.humidity || "--"
                }
            }
        }

        // 2. Barometric Pressure Cell
        RowLayout {
            spacing: 6

            MaterialSymbol {
                color: Appearance.colors.colSecondary
                fill: 0
                iconSize: 18
                text: "compress"
            }

            ColumnLayout {
                spacing: 1

                StyledText {
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    text: "Pressure"
                }

                StyledText {
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    text: root.model?.pressureHpa || "--"
                }
            }
        }

        // 3. UV Index Cell
        RowLayout {
            spacing: 6

            MaterialSymbol {
                color: Appearance.m3colors.m3primary
                fill: 0
                iconSize: 18
                text: "wb_sunny"
            }

            ColumnLayout {
                spacing: 1

                StyledText {
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    text: "UV Index"
                }

                StyledText {
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    text: `${root.model?.uv ?? "--"} • ${root.getUvRisk(root.model?.uv)}`
                }
            }
        }

        // 4. Visibility Cell
        RowLayout {
            spacing: 6

            MaterialSymbol {
                color: Appearance.m3colors.m3secondary
                fill: 0
                iconSize: 18
                text: "visibility"
            }

            ColumnLayout {
                spacing: 1

                StyledText {
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    text: "Visibility"
                }

                StyledText {
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    text: `${root.model?.visibilityKm || "--"} • Clear`
                }
            }
        }
    }
}
