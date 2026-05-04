import QtQuick
import QtQuick.Controls
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root
    visible: MprisService.hasPlayer

    readonly property var p: MprisService.activePlayer
    readonly property string raw: p ? ((p.trackArtist || "") + " - " + (p.trackTitle || "")).trim() : ""
    readonly property string display: {
        if (!p) return ""
        if (!p.trackTitle && !p.trackArtist) return " No track"
        return " " + (raw.length > 30 ? raw.substring(0, 29) + "\u2026" : raw)
    }

    opacity: (p && p.canControl) ? 1.0 : 0.6

    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        font.bold: true
        color: Colours.textColor
        elide: Text.ElideRight
        text: "\uf1bc" + root.display
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: p ? p.canControl : false
        onClicked: { if (p) p.togglePlaying() }
    }

    ToolTip.visible: clickArea.containsMouse && p
    ToolTip.text: {
        if (!p) return ""
        const lines = []
        if (p.trackArtist) lines.push(p.trackArtist)
        if (p.trackTitle)  lines.push(p.trackTitle)
        if (p.trackAlbum)  lines.push(p.trackAlbum)
        return lines.join("\n")
    }
}
