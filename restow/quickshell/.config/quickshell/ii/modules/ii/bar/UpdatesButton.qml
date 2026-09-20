import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

MouseArea {
    id: root

    implicitWidth: rowLayout.implicitWidth + 16
    implicitHeight: Appearance.sizes.barHeight
    visible: Updates.count > 0
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton

    // Launches yay -Syu via system-update.sh in the configured terminal (COMP-07)
    onClicked: {
        const script = FileUtils.trimFileProtocol(`${Directories.scriptPath}/system-update.sh`);
        const term = Config.options?.apps?.terminal ?? "";
        Quickshell.execDetached(["bash", "-c", `"${script}" "${term}"`]);
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            text: "system_update_alt"
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colPrimary
        }

        StyledText {
            text: `${Updates.count}`
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
        }
    }
}
