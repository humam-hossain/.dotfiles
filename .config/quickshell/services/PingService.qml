pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string text:     "err"
    readonly property string cssClass: "dead"
    readonly property string tooltip:  ""

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["bash", "-c", Qt.getenv("HOME") + "/.config/waybar/scripts/network/ping_status.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    root.text    = obj.text ?? "err"
                    root.cssClass = obj.class ?? "dead"
                    root.tooltip = obj.text ? "Ping: " + obj.text : ""
                } catch (e) {
                    root.text    = "err"
                    root.cssClass = "dead"
                }
            }
        }
    }
}
