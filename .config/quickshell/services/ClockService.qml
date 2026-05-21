pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string text: Qt.formatDateTime(new Date(), "{:%a %Y-%m-%d %I:%M:%S %p}")

    readonly property var rawDate: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.text = Qt.formatDateTime(new Date(), "{:%a %Y-%m-%d %I:%M:%S %p}")
            root.rawDate = new Date()
        }
    }
}
