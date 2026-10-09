import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Revealer {
    id: root

    property int currentIndex: 0
    property bool expanded: false
    property var model: Weather.alerts

    readonly property var activeAlert: (root.model && root.model.length > root.currentIndex) ? root.model[root.currentIndex] : ((root.model && root.model.length > 0) ? root.model[0] : null)

    Layout.fillWidth: true
    reveal: !!(root.model && root.model.length > 0)
    vertical: true

    Rectangle {
        Layout.fillWidth: true
        border.color: WeatherGlyphs.getAlertColor(root.activeAlert?.severity || root.activeAlert?.event || "")
        border.width: 1
        color: Appearance.m3colors.m3errorContainer
        implicitHeight: bannerLayout.implicitHeight + 16
        implicitWidth: parent.width
        radius: Appearance.rounding.small

        ColumnLayout {
            id: bannerLayout

            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // Header Row (Click to toggle drawer)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    color: Appearance.m3colors.m3error
                    fill: 0
                    iconSize: 18
                    text: "warning"
                }

                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.m3colors.m3onErrorContainer
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Bold
                    text: root.activeAlert?.headline || root.activeAlert?.event || "Severe Weather Alert"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = !root.expanded
                    }
                }

                // Carousel stepping controls (visible if multiple alerts per D-54-31)
                RowLayout {
                    id: alertCarousel

                    spacing: 2
                    visible: !!(root.model && root.model.length > 1)

                    MaterialSymbol {
                        color: Appearance.m3colors.m3onErrorContainer
                        fill: 0
                        iconSize: 18
                        text: "chevron_left"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.model && root.model.length > 1) {
                                    root.currentIndex = (root.currentIndex - 1 + root.model.length) % root.model.length;
                                }
                            }
                        }
                    }

                    StyledText {
                        color: Appearance.m3colors.m3onErrorContainer
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        text: `${root.currentIndex + 1} of ${root.model ? root.model.length : 1}`
                    }

                    MaterialSymbol {
                        color: Appearance.m3colors.m3onErrorContainer
                        fill: 0
                        iconSize: 18
                        text: "chevron_right"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.model && root.model.length > 1) {
                                    root.currentIndex = (root.currentIndex + 1) % root.model.length;
                                }
                            }
                        }
                    }
                }

                // Expand/collapse chevron
                MaterialSymbol {
                    id: expandChevron

                    color: Appearance.m3colors.m3onErrorContainer
                    fill: 0
                    iconSize: 20
                    rotation: root.expanded ? 180 : 0
                    text: "expand_more"

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = !root.expanded
                    }
                }
            }

            // Advisory Text Drawer (Revealer per D-54-30)
            Revealer {
                Layout.fillWidth: true
                reveal: root.expanded
                vertical: true

                ColumnLayout {
                    spacing: 4
                    width: parent.width

                    StyledText {
                        Layout.fillWidth: true
                        color: Appearance.m3colors.m3onErrorContainer
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        text: root.activeAlert?.desc || "No further details provided."
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Appearance.m3colors.m3onErrorContainer
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.DemiBold
                        text: root.activeAlert?.areas ? `Areas: ${root.activeAlert.areas}` : ""
                        visible: !!(root.activeAlert?.areas && root.activeAlert.areas.length > 0)
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
