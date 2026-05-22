pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var  defaultSink:    Pipewire.defaultAudioSink
    property real volume:         0.0
    property bool muted:          false
    property int  volumePercent:  0
    property string sinkName:     ""

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

    // QS 0.2.1 workaround: Pipewire readonly binding propagation broken (issue #807)
    // Polling Timer reads Pipewire API directly and updates writable properties.
    // This triggers volumePercentChanged() downstream → VolumeOsd.show()
    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const sink = Pipewire.defaultAudioSink
            if (!sink || !sink.audio) return
            root.volume = sink.audio.volume
            root.muted = sink.audio.muted
            root.volumePercent = Math.round(sink.audio.volume * 100)
            root.sinkName = sink.description || sink.name || "Audio"
        }
    }
}
