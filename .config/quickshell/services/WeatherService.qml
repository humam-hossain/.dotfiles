pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string text:    "err"
    property string tooltip: ""

    Timer {
        interval: 200000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["bash", "-c", Qt.getenv("HOME") + "/.config/waybar/scripts/weather/curr_weather.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text.trim())
                    root.text    = obj.text ?? "err"
                    root.tooltip = obj.tooltip ?? ""
                } catch (e) {
                    root.text = "err"
                }
            }
        }
    }
}
