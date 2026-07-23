pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    // Misc props
    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00 // People keep joking about setting volume to 5172% so...
    readonly property real maxVolume: 1.30 // D-22: intentional boost ceiling (130% linear)
    property string audioTheme: Config.options.sounds.theme
    property real value: sink?.audio.volume ?? 0
    
    function friendlyDeviceName(node) {
        return (node.nickname || node.description || Translation.tr("Unknown"));
    }
    function appNodeDisplayName(node) {
        return (node.properties["application.name"] || node.description || node.name)
    }

    // Lists
    function correctType(node, isSink) {
        return (node.isSink === isSink) && node.audio
    }
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter((node) => { // Should be list<PwNode> but it breaks ScriptModel
            return root.correctType(node, isSink) && node.isStream
        })
    }
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return root.correctType(node, isSink) && !node.isStream
        })
    }
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    // Signals
    signal sinkProtectionTriggered(string reason);

    // Controls
    function toggleMute() {
        Audio.sink.audio.muted = !Audio.sink.audio.muted
    }

    function toggleMicMute() {
        Audio.source.audio.muted = !Audio.source.audio.muted
    }

    function incrementVolume() {
        if (!sink?.audio) return;
        // D-21: volume change while muted unmutes (scroll / UI path)
        if (sink.audio.muted)
            sink.audio.muted = false;
        const currentVolume = value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02;
        // D-22: raise ceiling is maxVolume (1.30), not 1.0
        sink.audio.volume = Math.min(maxVolume, sink.audio.volume + step);
    }
    
    function decrementVolume() {
        if (!sink?.audio) return;
        // D-21: volume change while muted unmutes
        if (sink.audio.muted)
            sink.audio.muted = false;
        const currentVolume = value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02;
        sink.audio.volume = Math.max(0, sink.audio.volume - step);
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Internals
    PwObjectTracker {
        objects: [sink, source]
    }

    // D-21: auto-unmute on external sink volume changes (keyboard wpctl, etc.).
    // Dedicated Connections so auto-unmute is NOT gated on protection.enable.
    Connections {
        target: sink?.audio ?? null
        property real lastVolume: -1
        function onVolumeChanged() {
            if (!sink?.audio) return;
            const newVolume = sink.audio.volume;
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null)
                return;
            // Unmute when volume actually changed while muted
            if (sink.audio.muted && lastVolume >= 0 && newVolume !== lastVolume)
                sink.audio.muted = false;
            lastVolume = newVolume;
        }
    }

    // D-21 symmetry: auto-unmute mic when input volume changes while muted
    Connections {
        target: source?.audio ?? null
        property real lastVolume: -1
        function onVolumeChanged() {
            if (!source?.audio) return;
            const newVolume = source.audio.volume;
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null)
                return;
            if (source.audio.muted && lastVolume >= 0 && newVolume !== lastVolume)
                source.audio.muted = false;
            lastVolume = newVolume;
        }
    }

    Connections { // Protection against sudden volume changes
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!Config.options.audio.protection.enable) return;
            const newVolume = sink.audio.volume;
            // when resuming from suspend, we should not write volume to avoid pipewire volume reset issues
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false;
                lastVolume = 0;
                return;
            }
            if (!lastReady) {
                lastVolume = newVolume;
                lastReady = true;
                return;
            }
            const maxAllowedIncrease = Config.options.audio.protection.maxAllowedIncrease / 100; 
            const maxAllowed = Config.options.audio.protection.maxAllowed / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered(Translation.tr("Illegal increment"));
            } else if (newVolume > maxAllowed || newVolume > root.hardMaxValue) {
                root.sinkProtectionTriggered(Translation.tr("Exceeded max allowed"));
                sink.audio.volume = Math.min(lastVolume, maxAllowed);
            }
            lastVolume = sink.audio.volume;
        }
    }

    function playSystemSound(soundName) {
        const ogaPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.oga`;
        const oggPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.ogg`;

        // Try playing .oga first
        let command = [
            "ffplay",
            "-nodisp",
            "-autoexit",
            ogaPath
        ];
        Quickshell.execDetached(command);

        // Also try playing .ogg (ffplay will just fail silently if file doesn't exist)
        command = [
            "ffplay",
            "-nodisp",
            "-autoexit",
            oggPath
        ];
        Quickshell.execDetached(command);
    }
}
