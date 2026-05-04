import QtQuick
import qs.theme

Rectangle {
    default property alias content: inner.data

    color:  Colours.moduleBg   // #1e1e2e D-06
    radius: 8                  // D-03 border-radius

    property int topPadding:    6   // D-03 padding 6px 14px
    property int bottomPadding: 6
    property int leftPadding:   14
    property int rightPadding:  14

    implicitWidth:  inner.implicitWidth  + leftPadding + rightPadding
    implicitHeight: inner.implicitHeight + topPadding  + bottomPadding

    Item {
        id: inner
        anchors.centerIn: parent
        implicitWidth:  childrenRect.width
        implicitHeight: childrenRect.height
    }
}
