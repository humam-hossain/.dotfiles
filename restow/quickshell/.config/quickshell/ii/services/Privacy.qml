pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * Screensharing and mic activity with primitive boolean evaluation (D-13, COMP-08).
 * Screen recording detection via wf-recorder process telemetry (COMP-08).
 */
Singleton {
    id: root

    property bool screenRecording: false
    readonly property bool screenSharing: screenRecording || Pipewire.linkGroups.values.some(pwlg => pwlg.source?.type === PwNodeType.VideoSource)
    readonly property bool micActive: Pipewire.linkGroups.values.some(pwlg => pwlg.source?.type === PwNodeType.AudioSource && pwlg.target?.type === PwNodeType.AudioInStream)

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            if (!wfRecorderProc.running) {
                wfRecorderProc.running = true;
            }
        }
    }

    Process {
        id: wfRecorderProc
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            root.screenRecording = (exitCode === 0);
        }
    }
}
