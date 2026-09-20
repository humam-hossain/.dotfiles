pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/*
 * System updates service aggregating Arch repos and AUR packages (D-18, COMP-07).
 */
Singleton {
    id: root

    property bool available: false
    property alias checking: checkUpdatesProc.running
    property int count: 0
    
    readonly property bool updateAdvised: available && count > Config.options.updates.adviseUpdateThreshold
    readonly property bool updateStronglyAdvised: available && count > Config.options.updates.stronglyAdviseUpdateThreshold

    function load() {}
    function refresh() {
        if (!available) return;
        print("[Updates] Checking for system updates")
        checkUpdatesProc.running = true;
    }

    Timer {
        interval: Config.options.updates.checkInterval * 60 * 1000
        repeat: true
        running: Config.ready && Config.options.updates.enableCheck
        onTriggered: {
            print("[Updates] Periodic update check due")
            root.refresh();
        }
    }

    Process {
        id: checkAvailabilityProc
        running: Config.ready && Config.options.updates.enableCheck
        command: ["bash", "-c", "command -v checkupdates >/dev/null 2>&1 || command -v yay >/dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0);
            root.refresh();
        }
    }

    Process {
        id: checkUpdatesProc
        command: ["bash", "-c", "c=0; if command -v checkupdates >/dev/null 2>&1; then c=$((c + $(checkupdates 2>/dev/null | wc -l))); elif command -v yay >/dev/null 2>&1; then c=$((c + $(yay -Qu 2>/dev/null | wc -l))); fi; if command -v yay >/dev/null 2>&1; then c=$((c + $(yay -Qua 2>/dev/null | wc -l))); fi; echo $c"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = parseInt(text.trim());
                root.count = isNaN(parsed) ? 0 : parsed;
            }
        }
    }
}
