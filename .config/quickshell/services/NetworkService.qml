pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string ssid:         "No Network"
    property string iconText:     "󰤮"
    property bool   connected:    false
    property string tooltipText:  "Disconnected"

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wifiProc.running = true
    }

    Process {
        id: wifiProc
        command: ["bash", "-c", "nmcli -t -f active,ssid,signal,type dev wifi | grep '^yes' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim()
                if (line) {
                    const parts = line.split(":")
                    const sig    = parseInt(parts[2], 10) || 0
                    root.ssid    = parts[1] || "WiFi"
                    root.connected = true
                    root.iconText = sig <= 20  ? "󰤯"
                                 : sig <= 40  ? "󰤟"
                                 : sig <= 60  ? "󰤢"
                                 : sig <= 80  ? "󰤥"
                                 :               "󰤨"
                    root.tooltipText = "SSID: " + root.ssid + " (" + sig + "%)"
                } else {
                    ethProc.running = true
                }
            }
        }
    }

    Process {
        id: ethProc
        command: ["bash", "-c", "nmcli -t -f device,type,state dev status | grep 'ethernet:connected' | head -1"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim()
                if (line) {
                    root.ssid      = "eth0"
                    root.connected = true
                    root.iconText  = "󰈀"
                    root.tooltipText = "Ethernet — Connected"
                } else {
                    root.ssid      = "No Network"
                    root.connected = false
                    root.iconText  = "󰤮"
                    root.tooltipText = "Disconnected"
                }
            }
        }
    }
}
