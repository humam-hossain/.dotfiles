pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string text:    "err"
    readonly property string tooltip: ""
    readonly property int    percent: 0

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["bash", "-c", "$HOME/.config/waybar/scripts/system/memory.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    root.text    = obj.text    ?? "err"
                    root.tooltip = obj.tooltip ?? ""
                    root.percent = parseInt(obj.percentage, 10) || 0
                } catch (e) {
                    root.text = "err"
                }
            }
        }
    }
}
