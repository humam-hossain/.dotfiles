pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    readonly property var workspaces: Hyprland.workspaces.values
        .slice()
        .sort((a, b) => a.id - b.id)
        .filter(w => w.id >= 0 && !(w.name && w.name.startsWith("special:")))

    property var urgentIds: ({})

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "urgent") {
                const id = parseInt(event.data, 10)
                if (!isNaN(id)) {
                    const next = Object.assign({}, root.urgentIds)
                    next[id] = true
                    root.urgentIds = next
                }
            } else if (event.name === "workspace" || event.name === "focusedmon") {
                if (Hyprland.focusedWorkspace) {
                    const id = Hyprland.focusedWorkspace.id
                    if (root.urgentIds[id]) {
                        const next = Object.assign({}, root.urgentIds)
                        delete next[id]
                        root.urgentIds = next
                    }
                }
            }
        }
    }

    function isUrgent(id) { return !!urgentIds[id] }
}
