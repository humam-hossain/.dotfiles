import QtQuick

Item {
    default property alias children: row.children

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8    // D-03 inter-module spacing 8px (4px each side from Waybar margin: 6px 4px)
    }
}
