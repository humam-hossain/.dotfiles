import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

PopupWindow {
    id: root

    property bool open: false
    property bool showPassword: false
    property bool connecting: false
    property string connectError: ""
    property string pendingPasswordForSsid: ""
    property string connectedSsid: NetworkService.ssid
    property int selectedNetworkIndex: -1
    property var networkList: []
    property string connName: ""
    property string connIpv4: ""
    property string connIpv6: ""
    property string connGateway: ""
    property string connDns: ""
    property string connType: ""
    property string connState: ""
    property string connSsid: ""
    property string connSignal: ""
    property string emptyState: ""
    property string passwordInput: ""

    visible: false
    width: 380
    height: 460

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
            spacing: 6

            Item {
                Layout.preferredHeight: 1
                Layout.preferredWidth: 1
                focus: true
                Keys.onEscapePressed: root.close()
            }

            Rectangle {
                id: statusSection
                Layout.fillWidth: true
                color: Colours.moduleBg
                radius: 6
                visible: connState !== ""

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.bold: true
                        color: Colours.textColor
                        text: connState === "connected" ? "Connected: " + connSsid : "Not connected"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Colours.subtextColor
                        opacity: 0.2
                    }

                    Text {
                        Layout.fillWidth: true
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Colours.subtextColor
                        text: "IP: " + connIpv4
                        visible: connIpv4 !== ""
                    }
                    Text {
                        Layout.fillWidth: true
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Colours.subtextColor
                        text: "IP: " + connIpv6
                        visible: connIpv6 !== ""
                    }
                    Text {
                        Layout.fillWidth: true
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Colours.subtextColor
                        text: "Gateway: " + connGateway
                        visible: connGateway !== ""
                    }
                    Text {
                        Layout.fillWidth: true
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Colours.subtextColor
                        text: "DNS: " + connDns
                        visible: connDns !== ""
                    }
                    Text {
                        Layout.fillWidth: true
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Colours.subtextColor
                        text: "Type: " + connType
                        visible: connType !== ""
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Colours.subtextColor
                            text: "Signal: " + root.signalIcon(parseInt(connSignal)) + " " + connSignal + "%"
                            visible: connSignal !== "" && connSignal !== "0"
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: 80
                            Layout.preferredHeight: 22
                            radius: 4
                            color: "transparent"
                            border.color: Colours.critical
                            border.width: 1
                            visible: connState === "connected"

                            Text {
                                anchors.centerIn: parent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: Colours.critical
                                text: "Disconnect"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: disconnectProc.running = true
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: Colours.subtextColor
                text: "Available Networks"
            }

            Rectangle {
                id: passwordPrompt
                Layout.fillWidth: true
                color: Colours.moduleBg
                radius: 6
                visible: pendingPasswordForSsid !== ""

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                        color: Colours.textColor
                        text: "Connect to: " + pendingPasswordForSsid
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 4
                            color: Colours.surface0
                            border.color: Colours.subtextColor
                            border.width: 1
                            opacity: 0.5

                            TextInput {
                                id: passwordField
                                anchors.fill: parent
                                anchors.margins: 4
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                echoMode: showPassword ? TextInput.Normal : TextInput.Password
                                color: Colours.textColor
                                focus: true
                                onTextChanged: root.passwordInput = text
                            }
                        }

                        Text {
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: Colours.subtextColor
                            text: showPassword ? "\uF6D1" : "\uF6D0"
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: showPassword = !showPassword
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Colours.critical
                        text: connectError
                        visible: connectError !== ""
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 24
                            radius: 4
                            color: "transparent"
                            border.color: Colours.subtextColor
                            border.width: 1
                            opacity: 0.5

                            Text {
                                anchors.centerIn: parent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: Colours.subtextColor
                                text: "Cancel"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: closePasswordPrompt()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 66
                            Layout.preferredHeight: 24
                            radius: 4
                            color: {
                                if (connecting) return Colours.subtextColor
                                if (passwordField.text.length > 0) return Colours.accent
                                return Colours.subtextColor
                            }
                            opacity: passwordField.text.length > 0 && !connecting ? 1 : 0.5

                            Text {
                                anchors.centerIn: parent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: "#ffffff"
                                text: connecting ? "\uF100" : "Connect"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: passwordField.text.length > 0 && !connecting
                                onClicked: root.connectToNetwork(pendingPasswordForSsid, passwordField.text)
                            }
                        }
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: networkListContent.height

                ColumnLayout {
                    id: networkListContent
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: networkList

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 4
                            color: modelData.connected ? Qt.rgba(0.79, 0.65, 0.97, 0.15) : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: Colours.textColor
                                    text: root.signalIcon(modelData.signal)
                                }

                                Text {
                                    Layout.fillWidth: true
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: Colours.textColor
                                    text: modelData.ssid
                                    elide: Text.ElideRight
                                }

                                Text {
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    color: Colours.subtextColor
                                    text: modelData.secured ? "\uF023" : ""
                                    visible: modelData.secured
                                }

                                Text {
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    color: Colours.success
                                    text: "Connected"
                                    visible: modelData.connected
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedNetworkIndex = index
                                    if (modelData.connected) return
                                    if (modelData.secured) {
                                        root.openPasswordPrompt(modelData.ssid)
                                    } else {
                                        root.connectToNetwork(modelData.ssid, "")
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 16
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: Colours.subtextColor
                        horizontalAlignment: Text.AlignHCenter
                        text: networkList.length > 0 ? "" : (emptyState !== "" ? emptyState : "Scanning...")
                        visible: networkList.length === 0
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 4
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: Colours.subtextColor
                horizontalAlignment: Text.AlignHCenter
                text: "Open network: Connect in nmtui"
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: nmtuiProc.running = true
                }
            }
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.close()
    }

    Process {
        id: connInfoProc
        command: ["bash", "-c", "nmcli -g GENERAL.TYPE,GENERAL.STATE,GENERAL.CONNECTION dev show $(nmcli -t -f DEVICE,TYPE dev status | grep -m1 ':wifi\\|:ethernet' | cut -d: -f1) 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = connInfoProc.stdout.trim().split("\n")
                if (lines.length >= 3) {
                    root.connType = lines[0].trim()
                    root.connName = lines[2].trim()
                    root.connState = lines[1].trim().indexOf("connected") >= 0 ? "connected" : ""
                    root.connSsid = root.connName
                } else {
                    root.connState = ""
                }
                ipInfoProc.running = true
            }
        }
        running: false
    }

    Process {
        id: ipInfoProc
        command: ["bash", "-c", "nmcli -g IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS,IP6.GATEWAY con show --active 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = ipInfoProc.stdout.trim().split("\n")
                root.connIpv4 = ""
                root.connIpv6 = ""
                root.connGateway = ""
                root.connDns = ""
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.indexOf("IP4.ADDRESS") === 0) root.connIpv4 = line.substring(line.indexOf(":") + 1).replace("/24", "").trim()
                    else if (line.indexOf("IP4.GATEWAY") === 0) root.connGateway = line.substring(line.indexOf(":") + 1).trim()
                    else if (line.indexOf("IP4.DNS") === 0) root.connDns = (root.connDns ? root.connDns + ", " : "") + line.substring(line.indexOf(":") + 1).trim()
                    else if (line.indexOf("IP6.ADDRESS") === 0) root.connIpv6 = line.substring(line.indexOf(":") + 1).replace("/64", "").trim()
                }
            }
        }
        running: false
    }

    Process {
        id: scanProc
        command: ["nmcli", "--get-values", "SSID,SECURITY,SIGNAL", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = scanProc.stdout.trim()
                if (raw === "") {
                    root.emptyState = "No networks found in range"
                    return
                }
                var entries = raw.split("\n")
                var list = []
                for (var i = 0; i < entries.length; i++) {
                    var entry = entries[i].trim()
                    if (entry === "") continue
                    var lastColon = entry.lastIndexOf(":")
                    if (lastColon < 0) continue
                    var ssid = entry.substring(0, lastColon)
                    var rest = entry.substring(lastColon + 1)
                    var secondLastColon = rest.lastIndexOf(":")
                    var security = secondLastColon >= 0 ? rest.substring(0, secondLastColon) : rest
                    var signal = secondLastColon >= 0 ? rest.substring(secondLastColon + 1) : "0"
                    if (ssid === "") continue
                    list.push({
                        ssid: ssid,
                        secured: security !== "" && security !== "--",
                        signal: parseInt(signal),
                        connected: ssid === root.connSsid
                    })
                }
                root.networkList = list
                if (list.length === 0) {
                    root.emptyState = "No networks found in range"
                }
            }
        }
        running: false
    }

    Process {
        id: nmtuiProc
        command: ["kitty", "-e", "nmtui"]
        running: false
    }

    Process {
        id: disconnectProc
        command: ["bash", "-c", "nmcli con down id \"" + root.connName + "\" 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                refreshInfo()
            }
        }
        running: false
    }

    Process {
        id: connectProc
        property string targetSsid: ""
        property string connectPassword: ""
        command: ["bash", "-c", "nmcli dev wifi connect \"" + targetSsid + "\" password \"" + connectPassword + "\" 2>&1 || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.connecting = false
                var result = connectProc.stdout.trim()
                if (result.indexOf("Successfully activated") >= 0) {
                    root.pendingPasswordForSsid = ""
                    root.passwordInput = ""
                    root.connectError = ""
                    refreshInfo()
                } else if (result.indexOf("Error") >= 0 || result.indexOf("secrets") >= 0) {
                    root.connectError = "Wrong password or connection failed"
                } else {
                    root.connectError = result
                }
            }
        }
        running: false
    }

    Timer {
        id: scanTimer
        interval: 10000
        running: root.visible
        repeat: true
        triggeredOnStart: false
        onTriggered: scanProc.running = true
    }

    onVisibleChanged: {
        if (visible) {
            root.open = true
            root.passwordInput = ""
            root.connectError = ""
            root.pendingPasswordForSsid = ""
            root.showPassword = false
            connInfoProc.running = true
            scanProc.running = true
            root.emptyState = "Scanning..."
        } else {
            root.open = false
        }
    }

    function signalIcon(signal) {
        if (signal >= 80) return "\uF4E8"
        if (signal >= 61) return "\uF4E5"
        if (signal >= 41) return "\uF4E2"
        if (signal >= 21) return "\uF4DF"
        return "\uF4EF"
    }

    function show() {
        root.visible = true
    }

    function close() {
        root.visible = false
    }

    function connectToNetwork(ssid, password) {
        root.connecting = true
        root.connectError = ""
        connectProc.targetSsid = ssid
        connectProc.connectPassword = password
        connectProc.running = true
    }

    function refreshInfo() {
        connInfoProc.running = true
        scanProc.running = true
    }

    function openPasswordPrompt(ssid) {
        root.pendingPasswordForSsid = ssid
        root.passwordInput = ""
        root.connectError = ""
    }

    function closePasswordPrompt() {
        root.pendingPasswordForSsid = ""
        root.passwordInput = ""
        root.connectError = ""
    }
}
