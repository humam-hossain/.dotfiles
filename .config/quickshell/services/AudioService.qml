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
    // Poll via wpctl subprocess instead of reading Pipewire API directly.
    // wpctl returns real daemon state, bypassing QS binding cache.
    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wpctlProc.running = true
        }
    }

    Process {
        id: wpctlProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.trim()
                const match = out.match(/Volume:\s*([\d.]+)/)
                if (!match) return
                const vol = parseFloat(match[1])
                if (isNaN(vol)) return

                const rounded = Math.round(vol * 100) / 100
                root.muted = out.indexOf("[MUTED]") >= 0

                // Detect real volume change to trigger VolumeOsd
                if (Math.abs(root.volume - rounded) > 0.001) {
                    root.volume = rounded
                    root.volumePercent = Math.round(rounded * 100)
                    root.sinkName = "Default Audio Sink"
                }
            }
        }
    }
}
