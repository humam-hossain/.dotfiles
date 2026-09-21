pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Paths
    readonly property string runtimeDir: {
        const xdg = Quickshell.env("XDG_RUNTIME_DIR");
        return (xdg && xdg.length > 0) ? (xdg + "/voice-stt") : "/run/user/1000/voice-stt";
    }
    readonly property string recorderPidPath: runtimeDir + "/recorder.pid"
    readonly property string ttsPidPath: runtimeDir + "/tts.pid"

    // Reactive State Properties
    property string sttState: "idle"
    property string ttsState: "idle"
    readonly property string overallState: {
        if (sttState === "recording") return "recording";
        if (sttState === "transcribing") return "transcribing";
        if (ttsState === "speaking") return "speaking";
        if (sttState === "typing") return "typing";
        if (sttState === "starting") return "starting";
        return "idle";
    }

    // Process Tracking
    property int sttPid: 0
    property int ttsPid: 0

    // TTS Metadata
    property string ttsVoice: "af_heart"
    property string ttsBackend: "kokoro"

    // Telemetry & Metrics
    property int elapsedSeconds: 0
    property real elapsedMs: 0
    property string formattedDuration: "0:00"
    readonly property int maxDurationSeconds: 300
    property real startTime: 0

    // Formatting Helper
    function formatDuration(sec) {
        const m = Math.floor(sec / 60);
        const s = sec % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // State File Observers
    FileView {
        id: recorderFile
        path: root.recorderPidPath
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: ttsFile
        path: root.ttsPidPath
        printErrors: false
        blockLoading: true
    }

    // Procfs Observers
    FileView {
        id: sttCmdlineFile
        path: root.sttPid > 0 ? ("/proc/" + root.sttPid + "/cmdline") : ""
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: ttsCmdlineFile
        path: root.ttsPid > 0 ? ("/proc/" + root.ttsPid + "/cmdline") : ""
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: sttStatFile
        path: root.sttPid > 0 ? ("/proc/" + root.sttPid + "/stat") : ""
        printErrors: false
        blockLoading: true
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        printErrors: false
        blockLoading: true
    }

    // Visual Linger Timer for Rapid Typing
    Timer {
        id: typingLingerTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (root.sttState === "typing") {
                root.sttState = "idle";
                root.resetDuration();
            }
        }
    }

    function resetDuration() {
        startTime = 0;
        elapsedMs = 0;
        elapsedSeconds = 0;
        formattedDuration = "0:00";
    }

    // Recover Start Time on Shell Reload
    function recoverStartTime(pid) {
        if (pid > 0) {
            sttStatFile.reload();
            uptimeFile.reload();
            const statText = sttStatFile.text().trim();
            const uptimeText = uptimeFile.text().trim();
            const lastParen = statText.lastIndexOf(")");
            if (lastParen !== -1 && uptimeText.length > 0) {
                const rest = statText.substring(lastParen + 1).trim().split(/\s+/);
                const startTicks = parseFloat(rest[19]); // Index 19 after comm is field 22
                const uptimeSec = parseFloat(uptimeText.split(/\s+/)[0]);
                if (!isNaN(startTicks) && !isNaN(uptimeSec)) {
                    const elapsedSec = Math.max(0, uptimeSec - (startTicks / 100.0));
                    if (!isNaN(elapsedSec) && elapsedSec >= 0 && elapsedSec < maxDurationSeconds) {
                        return Date.now() - (elapsedSec * 1000);
                    }
                }
            }
        }
        return Date.now();
    }

    function updateDuration() {
        if (overallState === "recording" || overallState === "speaking") {
            if (startTime <= 0) {
                const activePid = (overallState === "recording") ? sttPid : ttsPid;
                startTime = Math.min(Date.now(), recoverStartTime(activePid));
            }
            const diff = Math.max(0, Date.now() - startTime);
            elapsedMs = diff;
            const sec = Math.floor(diff / 1000);
            elapsedSeconds = sec;
            formattedDuration = formatDuration(sec);
        } else if (overallState === "transcribing" || overallState === "typing") {
            // Frozen at final recorded value
        } else if (overallState === "idle" && !typingLingerTimer.running) {
            resetDuration();
        }
    }

    function poll() {
        recorderFile.reload();
        ttsFile.reload();

        const recText = recorderFile.text().trim();
        const ttsText = ttsFile.text().trim();

        // 1. STT State Evaluation
        if (recText.length > 0) {
            const parts = recText.split(/\s+/);
            const pid = parseInt(parts[0]);
            const rawState = parts[1] || "recording";

            if (!isNaN(pid) && pid > 0) {
                root.sttPid = pid;
                sttCmdlineFile.reload();
                const cmdline = sttCmdlineFile.text().toLowerCase();

                if (!cmdline || (!cmdline.includes("voice") && !cmdline.includes("voicemode"))) {
                    console.warn("[Voice] Purged stale PID lock: " + pid);
                    Quickshell.execDetached(["rm", "-f", root.recorderPidPath]);
                    root.sttPid = 0;
                    if (root.sttState === "transcribing") {
                        root.sttState = "typing";
                        typingLingerTimer.restart();
                    } else if (!typingLingerTimer.running) {
                        root.sttState = "idle";
                    }
                } else {
                    if (rawState === "typing") {
                        root.sttState = "typing";
                        typingLingerTimer.restart();
                    } else if (root.sttState !== "typing" || !typingLingerTimer.running) {
                        root.sttState = rawState;
                    }
                }
            } else {
                if (!typingLingerTimer.running) {
                    root.sttState = "idle";
                    root.sttPid = 0;
                }
            }
        } else {
            if (root.sttState === "transcribing") {
                root.sttState = "typing";
                typingLingerTimer.restart();
            } else if (!typingLingerTimer.running) {
                root.sttState = "idle";
                root.sttPid = 0;
            }
        }

        // 2. TTS State Evaluation
        if (ttsText.length > 0) {
            const parts = ttsText.split(/\s+/);
            const pid = parseInt(parts[0]);

            if (!isNaN(pid) && pid > 0) {
                root.ttsPid = pid;
                ttsCmdlineFile.reload();
                const cmdline = ttsCmdlineFile.text();

                if (!cmdline || (!cmdline.toLowerCase().includes("voice") && !cmdline.toLowerCase().includes("voicemode"))) {
                    console.warn("[Voice] Purged stale PID lock: " + pid);
                    Quickshell.execDetached(["rm", "-f", root.ttsPidPath]);
                    root.ttsPid = 0;
                    root.ttsState = "idle";
                } else {
                    root.ttsState = "speaking";
                    const args = cmdline.split("\0");
                    let voice = "af_heart";
                    let backend = "kokoro";
                    for (let i = 0; i < args.length; i++) {
                        if (args[i] === "--tts-voice" && i + 1 < args.length) {
                            voice = args[i + 1];
                        } else if (args[i] === "--tts-backend" && i + 1 < args.length) {
                            backend = args[i + 1];
                        }
                    }
                    root.ttsVoice = voice;
                    root.ttsBackend = backend;
                }
            } else {
                root.ttsState = "idle";
                root.ttsPid = 0;
            }
        } else {
            root.ttsState = "idle";
            root.ttsPid = 0;
        }

        root.updateDuration();
    }

    Timer {
        id: pollTimer
        interval: (root.overallState === "idle" && !typingLingerTimer.running) ? 500 : 100
        repeat: true
        running: true
        onTriggered: root.poll()
    }

    Component.onCompleted: {
        root.poll();
    }
}
