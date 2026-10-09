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

    radius: Appearance.rounding.small
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
                fill: 0
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
