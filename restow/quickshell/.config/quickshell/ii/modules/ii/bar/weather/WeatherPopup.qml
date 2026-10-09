pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar
import qs.services

StyledPopup {
    id: root

    implicitWidth: 440

    onActiveChanged: {
        if (active) {
            GlobalStates.activeInspectorCount++;
        } else {
            GlobalStates.activeInspectorCount = Math.max(0, GlobalStates.activeInspectorCount - 1);
        }
    }

    Component.onDestruction: {
        if (active) {
            GlobalStates.activeInspectorCount = Math.max(0, GlobalStates.activeInspectorCount - 1);
        }
    }

    StyledFlickable {
        id: flickable
        implicitWidth: 440
        implicitHeight: Math.min(contentColumn.implicitHeight, (root.QsWindow?.window?.screen?.height ?? 1080) * 0.8)
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 8

            // 1. Severe Weather Alert Banner (collapses when empty per D-54-07, D-54-10)
            WeatherAlertBanner {
                id: alertBanner
                Layout.fillWidth: true
            }

            // 2. Primary Desktop Overview Hero Card (D-54-10)
            WeatherHeroCard {
                id: heroCard
                Layout.fillWidth: true
            }
        }
    }
}
