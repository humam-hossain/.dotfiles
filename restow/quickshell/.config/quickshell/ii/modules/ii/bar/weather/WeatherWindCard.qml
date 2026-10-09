import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

WeatherBaseCard {
    id: root

    property real currentDegree: targetDegree
    property var model: Weather.current
    property real targetDegree: Number(root.model?.windDegree) || 0

    icon: "near_me"
    Layout.fillWidth: true
    title: "Wind & Direction"

    onTargetDegreeChanged: {
        const diff = (targetDegree - (currentDegree % 360) + 540) % 360 - 180;
        currentDegree += diff;
    }

    Behavior on currentDegree {
        NumberAnimation {
            duration: 400
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            easing.type: Easing.BezierSpline
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        // 56px Compass Rose Dial (POPUP-05, D-54-24, D-54-26)
        Item {
            implicitHeight: 56
            implicitWidth: 56

            Rectangle {
                anchors.fill: parent
                border.color: Appearance.colors.colOutlineVariant
                border.width: 1
                color: Appearance.colors.colLayer1
                radius: 28

                // North Cardinal (Highlighted in primary accent, bold per D-54-26)
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 2
                    color: Appearance.colors.colPrimary
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    text: "N"
                }

                // South Cardinal
                StyledText {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: 9
                    text: "S"
                }

                // East Cardinal
                StyledText {
                    anchors.right: parent.right
                    anchors.rightMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: 9
                    text: "E"
                }

                // West Cardinal
                StyledText {
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: 9
                    text: "W"
                }

                // Rotating Needle (D-54-25)
                Item {
                    id: needleCenter

                    anchors.centerIn: parent
                    height: 32
                    rotation: root.currentDegree
                    width: 32

                    MaterialSymbol {
                        anchors.centerIn: parent
                        color: Appearance.colors.colPrimary
                        fill: 0
                        iconSize: 24
                        text: "navigation"
                    }
                }
            }
        }

        // Right Wind Telemetry Metadata
        ColumnLayout {
            spacing: 2

            StyledText {
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Bold
                text: root.model?.windKmph || "--"
            }

            StyledText {
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: `Gusts: ${root.model?.windGustKmph || "-- km/h"}`
            }

            StyledText {
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: `Direction: ${root.model?.windDir || "--"}`
            }
        }
    }
}
