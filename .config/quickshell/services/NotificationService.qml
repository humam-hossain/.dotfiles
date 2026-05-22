pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int    count: 0
    property string formatted: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["swaync-client", "-c"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const val = parseInt(this.text.trim(), 10)
                    if (!isNaN(val) && val > 0) {
                        root.count = val
                        root.formatted = (val < 10 ? " " : "") + String(val)
                    } else {
                        root.count = 0
                        root.formatted = ""
                    }
                } catch (e) {
                    root.count = 0
                    root.formatted = ""
                }
            }
        }
    }
}
