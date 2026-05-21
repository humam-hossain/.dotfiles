import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root

    readonly property var classColors: {
        "good":     Colours.pingGood,
        "medium":   Colours.pingMedium,
        "bad":      Colours.pingBad,
        "critical": Colours.pingCritical,
        "dead":     Colours.pingDead
    }

    property color pingColor: Colours.pingDead

    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        font.bold: true
        color: root.pingColor
        text: "󰀶 " + PingService.text
    }

    Connections {
        target: PingService
        function onCssClassChanged() {
            root.pingColor = root.classColors[PingService.cssClass] || Colours.pingDead
        }
    }

    Process {
        id: browserProc
        command: ["xdg-open", "http://localhost:8765/"]
        running: false
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: browserProc.startDetached()
    }

    ToolTip.visible: hover.hovered
    ToolTip.text: PingService.tooltip || "Ping: " + PingService.text
    HoverHandler { id: hover }
}
