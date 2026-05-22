pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int    brightnessPercent: 0
    property string formatted:         "err"

    property int _pendingDelta: 0

    Timer {
        id: pollTimer
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: readProc.running = true
    }

    Process {
        id: readProc
        command: ["bash", "-c", "ddcutil getvcp 10 2>/dev/null | awk '/current value/ {gsub(/,/,\"\",$9); print $9}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const val = parseInt(this.text.trim(), 10)
                    if (!isNaN(val) && val >= 0 && val <= 100) {
                        root.brightnessPercent = val
                        root.formatted = (val < 10 ? "  " : val < 100 ? " " : "") + val + "%"
                    } else {
                        root.formatted = "err"
                    }
                } catch (e) {
                    root.formatted = "err"
                }
            }
        }
    }

    Timer {
        id: debounceTimer
        interval: 300
        running: false
        repeat: false
        onTriggered: {
            const current = root.brightnessPercent
            const target  = Math.max(0, Math.min(100, current + root._pendingDelta))
            writeProc.command = ["ddcutil", "setvcp", "10", String(target)]
            writeProc.running = true
            root._pendingDelta = 0
        }
    }

    function adjustBrightness(delta) {
        root._pendingDelta = Math.max(-100, Math.min(100, root._pendingDelta + delta))
        debounceTimer.restart()
    }

    Process {
        id: writeProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                pollTimer.interval = 2000
                pollTimer.restart()
                readProc.running = true
            }
        }
    }

    Timer {
        interval: 2000
        running: false
        repeat: false
        onTriggered: pollTimer.interval = 30000
    }
}
