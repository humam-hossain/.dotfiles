pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    property string text: Qt.formatDateTime(new Date(), "ddd yyyy-MM-dd hh:mm:ss AP")

    property var rawDate: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.text = Qt.formatDateTime(new Date(), "ddd yyyy-MM-dd hh:mm:ss AP")
            root.rawDate = new Date()
        }
    }
}
