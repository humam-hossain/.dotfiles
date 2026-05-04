pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var  defaultSink:    Pipewire.defaultAudioSink
    readonly property real volume:         defaultSink && defaultSink.audio ? defaultSink.audio.volume : 0
    readonly property bool muted:          defaultSink && defaultSink.audio ? defaultSink.audio.muted  : false
    readonly property int  volumePercent:  Math.round(volume * 100)
    readonly property string sinkName:     defaultSink ? (defaultSink.description || defaultSink.name || "Audio") : ""

    function setVolume(percent) {
        if (!defaultSink || !defaultSink.audio) return
        defaultSink.audio.volume = Math.max(0, Math.min(1, percent / 100))
    }
    function bumpVolume(delta) { setVolume(volumePercent + delta) }
    function toggleMute() {
        if (!defaultSink || !defaultSink.audio) return
        defaultSink.audio.muted = !defaultSink.audio.muted
    }

    PwObjectTracker {
        objects: root.defaultSink ? [root.defaultSink] : []
    }
}
