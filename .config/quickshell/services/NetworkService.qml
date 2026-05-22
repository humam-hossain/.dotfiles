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
        command: ["bash", "-c", "nmcli -t -f active,ssid,signal dev wifi | grep '^yes' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim()
                if (line) {
                    const firstColon = line.indexOf(":")
                    const lastColon  = line.lastIndexOf(":")
                    if (firstColon > 0 && lastColon > firstColon) {
                        const sig  = parseInt(line.substring(lastColon + 1), 10) || 0
                        const ssid = line.substring(firstColon + 1, lastColon) || "WiFi"
                        root.ssid      = ssid
                        root.connected = true
                        root.iconText  = sig <= 20  ? "󰤯"
                                     : sig <= 40  ? "󰤟"
                                     : sig <= 60  ? "󰤢"
                                     : sig <= 80  ? "󰤥"
                                     :               "󰤨"
                        root.tooltipText = "SSID: " + ssid + " (" + sig + "%)"
                    } else {
                        ethProc.running = true
                    }
                } else {
                    ethProc.running = true
                }
            }
        }
    }

    Process {
        id: ethProc
        command: ["bash", "-c", "nmcli -t -f device,type,state dev status | grep 'ethernet' | head -1"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim()
                if (line && line.indexOf(":connected") >= 0) {
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
