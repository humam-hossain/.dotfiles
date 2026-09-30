pragma Singleton
pragma ComponentBehavior: Bound

import qs
import QtQuick
import Quickshell

Singleton {
    id: root

    // =========================================================================
    // D-14: Target Metrics & Status Properties
    // =========================================================================
    property bool isRequestInFlight: false
    property var targets: []
    property var wanTarget: ({ host: "8.8.8.8", ms: null, text_value: "-- ms", class: "dead", quality: "offline" })
    property var gatewayTarget: ({ host: "192.168.0.1", ms: null, text_value: "-- ms", class: "dead", quality: "offline" })
    property var homeServerTarget: ({ host: "192.168.0.104", ms: null, text_value: "-- ms", class: "dead", quality: "offline" })
    property var serverTarget: homeServerTarget

    property string wanLatency: wanTarget.text_value || "-- ms"
    property string wanStatus: wanTarget.class || "dead"
    property string gatewayLatency: gatewayTarget.text_value || "-- ms"
    property string gatewayStatus: gatewayTarget.class || "dead"
    property string homeServerLatency: homeServerTarget.text_value || "-- ms"
    property string homeServerStatus: homeServerTarget.class || "dead"

    property string overallClass: "dead"
    property bool isOffline: true

    readonly property string endpointUrl: "http://127.0.0.1:8765/api/status"

    // =========================================================================
    // D-13, D-50-08: Polling Cadence (2s active / 5s idle / 15s offline backoff)
    // =========================================================================
    Timer {
        id: pollTimer
        interval: root.isOffline ? 15000 : (GlobalStates.fastTelemetryRate ? 2000 : 5000)
        repeat: true
        running: true
        onTriggered: root.fetchStatus()
    }

    Component.onCompleted: {
        root.fetchStatus();
    }

    function fetchStatus() {
        if (root.isRequestInFlight) return;
        root.isRequestInFlight = true;

        const xhr = new XMLHttpRequest();
        xhr.open("GET", root.endpointUrl);
        xhr.timeout = 2000;

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.isRequestInFlight = false;
                if (xhr.status === 200) {
                    try {
                        const data = JSON.parse(xhr.responseText);
                        root.isOffline = false;
                        root.overallClass = data.overall_class || data.class || "dead";
                        root.targets = data.targets || [];

                        for (let i = 0; i < root.targets.length; i++) {
                            const t = root.targets[i];
                            if (t.host === "8.8.8.8") {
                                root.wanTarget = t;
                            } else if (t.host === "192.168.0.1") {
                                root.gatewayTarget = t;
                            } else if (t.host === "192.168.0.104") {
                                root.homeServerTarget = t;
                            }
                        }
                    } catch (e) {
                        root.handleOffline();
                    }
                } else {
                    root.handleOffline();
                }
            }
        };

        xhr.ontimeout = function() { root.isRequestInFlight = false; root.handleOffline(); };
        xhr.onerror = function() { root.isRequestInFlight = false; root.handleOffline(); };
        xhr.send();
    }

    function handleOffline() {
        root.isOffline = true;
        root.overallClass = "dead";
        root.wanTarget = { host: "8.8.8.8", ms: null, text_value: "-- ms", class: "dead", quality: "offline" };
        root.gatewayTarget = { host: "192.168.0.1", ms: null, text_value: "-- ms", class: "dead", quality: "offline" };
        root.homeServerTarget = { host: "192.168.0.104", ms: null, text_value: "-- ms", class: "dead", quality: "offline" };
    }
}
