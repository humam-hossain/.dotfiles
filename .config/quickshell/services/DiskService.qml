pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string text:    "err"
    property string tooltip: "err"
    property int    percent: 0

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["bash", "-c", "df -h / | awk 'NR==2 {printf \"%s/%s|%d\", $3, $2, $5}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parts = this.text.trim().split("|")
                    if (parts.length === 3) {
                        root.text    = parts[0] + "/" + parts[1]
                        root.percent = parseInt(parts[2], 10) || 0
                        root.tooltip = "Disk: " + root.text + " (" + root.percent + "%)"
                    } else {
                        root.text = "err"
                    }
                } catch (e) {
                    root.text = "err"
                }
            }
        }
    }
}
