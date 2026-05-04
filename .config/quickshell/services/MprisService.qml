pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    readonly property var activePlayer: {
        const list = Mpris.players.values
        if (!list || list.length === 0) return null
        const playing = list.find(p => p.playbackState === MprisPlaybackState.Playing)
        return playing ?? list[0]
    }
    readonly property bool hasPlayer: activePlayer !== null
}
