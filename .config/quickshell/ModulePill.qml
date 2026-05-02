import QtQuick
import qs.theme

Rectangle {
    default property alias content: inner.children

    color:  Colours.moduleBg   // #1e1e2e D-06
    radius: 8                  // D-03 border-radius

    topPadding:    6           // D-03 padding 6px 14px
    bottomPadding: 6
    leftPadding:   14
    rightPadding:  14

    implicitWidth:  inner.implicitWidth  + leftPadding + rightPadding
    implicitHeight: inner.implicitHeight + topPadding  + bottomPadding

    Item {
        id: inner
        anchors.centerIn: parent
        implicitWidth:  childrenRect.width
        implicitHeight: childrenRect.height
    }
}
