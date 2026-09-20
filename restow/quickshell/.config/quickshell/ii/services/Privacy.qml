pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * Screensharing and mic activity with primitive boolean evaluation (D-13, COMP-08).
 */
Singleton {
    id: root

    readonly property bool screenSharing: Pipewire.linkGroups.values.some(pwlg => pwlg.source?.type === PwNodeType.VideoSource)
    readonly property bool micActive: Pipewire.linkGroups.values.some(pwlg => pwlg.source?.type === PwNodeType.AudioSource && pwlg.target?.type === PwNodeType.AudioInStream)
}
