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
