import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

PopupWindow {
    id: root

    property bool open: false
    property int selectedDayIndex: -1

    visible: false

    width: 340
    height: 290

    anchor.rect.x: parentWindow.width / 2 - implicitWidth / 2
    anchor.rect.y: parentWindow.height + 12

    Rectangle {
        anchors.fill: parent
        color: Colours.moduleBg
        radius: 8
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Item {
                Layout.preferredHeight: 1
                Layout.preferredWidth: 1
                focus: true
                Keys.onEscapePressed: root.close()
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 4

                Text {
                    Layout.preferredWidth: 28
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Colours.subtextColor
                    horizontalAlignment: Text.AlignHCenter
                    text: "\uE8E7"
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CalendarService.prevMonth()
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    color: Colours.textColor
                    text: CalendarService.monthHeader
                }

                Item { Layout.fillWidth: true }

                Text {
                    Layout.preferredWidth: 28
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Colours.subtextColor
                    horizontalAlignment: Text.AlignHCenter
                    text: "\uE8E8"
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CalendarService.nextMonth()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colours.subtextColor
                opacity: 0.3
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                ColumnLayout {
                    Layout.preferredWidth: 28
                    Layout.fillHeight: true
                    spacing: 2

                    Text {
                        Layout.preferredHeight: 24
                        Layout.fillWidth: true
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: Colours.subtextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "Wk"
                    }

                    Repeater {
                        model: CalendarService.weekNumbers
                        delegate: Text {
                            Layout.preferredHeight: 34
                            Layout.fillWidth: true
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: Colours.subtextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: modelData
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        spacing: 0

                        Repeater {
                            model: ["M", "T", "W", "T", "F", "S", "S"]
                            delegate: Text {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 24
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.bold: true
                                color: Colours.subtextColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: modelData
                            }
                        }
                    }

                    Grid {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 7
                        columnSpacing: 0
                        rowSpacing: 2

                        Repeater {
                            model: CalendarService.dayGrid

                            delegate: Rectangle {
                                width: 36
                                height: 34
                                radius: 4
                                color: {
                                    if (modelData.isToday) return Colours.accent
                                    if (modelData.isCurrentMonth && modelData.isWeekend) {
                                        return Qt.rgba(0.65, 0.69, 0.78, 0.12)
                                    }
                                    return "transparent"
                                }

                                Text {
                                    anchors.centerIn: parent
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    font.bold: modelData.isToday
                                    color: {
                                        if (modelData.isToday) return Colours.base
                                        if (!modelData.isCurrentMonth) return Colours.subtextColor
                                        return Colours.textColor
                                    }
                                    text: modelData.day
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedDayIndex = index
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.close()
    }

    function show() {
        root.visible = true
        root.open = true
    }

    function close() {
        root.visible = false
        root.open = false
    }

    onVisibleChanged: {
        if (!visible) {
            root.open = false
            root.selectedDayIndex = -1
        }
    }
}
