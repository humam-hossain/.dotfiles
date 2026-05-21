pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property real cpuPercent:       0
    readonly property string cpuPercentFormatted: " 0%"

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["bash", "-c", "awk '/^cpu / {print 100-($5/($2+$3+$4+$5))*100}' /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const val = parseFloat(this.text.trim())
                    if (!isNaN(val)) {
                        root.cpuPercent = Math.round(val * 10) / 10
                        const pct = Math.round(val)
                        root.cpuPercentFormatted = (pct < 10 ? "  " : pct < 100 ? " " : "") + pct + "%"
                    } else {
                        root.cpuPercentFormatted = "err"
                    }
                } catch (e) {
                    root.cpuPercentFormatted = "err"
                }
            }
        }
    }
}
