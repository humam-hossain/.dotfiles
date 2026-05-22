pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real cpuPercent:       0
    property string cpuPercentFormatted: " 0%"
    property int __prevIdle: -1
    property int __prevTotal: -1

    Timer {
        interval: 300
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["bash", "-c", "awk '/^cpu / {idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i; print idle, total}' /proc/stat || echo '0 0'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parts = this.text.trim().split(/\s+/)
                    if (parts.length < 2) { root.cpuPercentFormatted = "err"; return }
                    const idle = parseInt(parts[0], 10)
                    const total = parseInt(parts[1], 10)
                    if (isNaN(idle) || isNaN(total)) { root.cpuPercentFormatted = "err"; return }

                    let pct
                    if (root.__prevTotal < 0) {
                        pct = (1 - idle / total) * 100
                    } else {
                        const deltaIdle = idle - root.__prevIdle
                        const deltaTotal = total - root.__prevTotal
                        if (deltaTotal <= 0) { root.cpuPercentFormatted = "err"; return }
                        pct = (1 - deltaIdle / deltaTotal) * 100
                    }

                    root.__prevIdle = idle
                    root.__prevTotal = total

                    root.cpuPercent = Math.round(pct * 10) / 10
                    const pctRounded = Math.round(pct)
                    root.cpuPercentFormatted = (pctRounded < 10 ? "  " : pctRounded < 100 ? " " : "") + pctRounded + "%"
                } catch (e) {
                    root.cpuPercentFormatted = "err"
                }
            }
        }
    }
}
