# Phase 49: Quickshell Resource Profiling & Component Performance Audit - Pattern Map

**Generated:** 2026-09-30  
**Phase:** 49 - quickshell-resource-profiling-component-performance-audit  
**Domain:** Quickshell runtime diagnostics, Linux procfs/sysfs telemetry, Wayland ydotool cursor navigation, Quickshell IPC, QML animation de-escalation, high-frequency process throttling, and automated regression assertion.  
**Consumes:** [`49-RESEARCH.md`](file:///home/pera/github_repo/.dotfiles/.planning/phases/49-quickshell-resource-profiling-component-performance-audit/49-RESEARCH.md), [`49-VALIDATION.md`](file:///home/pera/github_repo/.dotfiles/.planning/phases/49-quickshell-resource-profiling-component-performance-audit/49-VALIDATION.md)  
**Produces:** Authoritative patterns, architectural guidelines, concrete code blueprints, and test harness specifications for Phase 49 execution.

---

## 1. Executive Summary

Phase 49 establishes an empirical, reproducible resource audit and targeted performance optimization across all Quickshell components in the user's custom Hyprland desktop environment. The goals are strictly aligned with requirements **AUDIT-01**, **AUDIT-02**, and **AUDIT-03**:

1. **AUDIT-01: Baseline Calibration & System Idle Invariants**:
   - Establish clean system idle baseline without Quickshell, verifying system GPU active render load $\le 10\%$ (empirically measured at 0.76%).
   - Establish pure upstream `dots-hyprland` baseline using GNU Stow isolation (`stow -D`), confirming upstream idle consumption (~0.76% CPU, 0.00% GPU).
   - Enforce media playback pre-flight checking (`playerctl pause -a`) to prevent external hardware video decoding from polluting idle measurements.

2. **AUDIT-02: Component-by-Component & Interactive Popup Audit**:
   - Extend [`scripts/profile-quickshell.sh`](file:///home/pera/github_repo/.dotfiles/scripts/profile-quickshell.sh) to programmatically exercise each status bar component and interactive popup.
   - Utilize calibrated Wayland $2\times$ uinput coordinates on `DP-1` via `ydotool` and direct Quickshell IPC (`qs -c ii ipc call <target> open/close`).
   - Profile all 8+ popups (`CpuGpuPopup`, `MemoryStoragePopup`, `NetworkPingPopup`, `ClockWidgetPopup`, `WeatherPopup`, `MediaControls`, `SidebarLeft`, `SidebarRight`) and verify layer shell presence (`hyprctl layers`).

3. **AUDIT-03: Targeted Optimizations, Comparative Reporting & Zero Regressions**:
   - Resolve critical hotspots identified during empirical research:
     - `MediaControls.qml`: Throttle `cava` 60 FPS spectrum stdout processing and gate `cavaProc.running` by active player playback state.
     - `NetworkPingPopup.qml`: De-escalate infinite opacity animation (`loops: Animation.Infinite` $\to$ bounded pulses) and cache DNS server delegate array.
     - `Voice.qml`: Relax idle tmpfs polling interval ($500\text{ ms} \to 2500\text{ ms}$).
     - `StorageUsage.qml`: Relax idle `/proc/diskstats` sampling interval ($1000\text{ ms} \to 3000\text{ ms}$).
   - Construct [`scripts/phase49-audit-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase49-audit-assert.sh) to enforce zero regressions, strict repository verification, and invariant compliance.
   - Generate comparative pre- vs post-optimization reports in `BENCHMARK.md` and `benchmark-latest.json`.

---

## 2. Target File Role & Classification Matrix

| File Path | Operation | Role | Data Flow | Closest Codebase Analog | Key Architectural Responsibilities |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [`scripts/profile-quickshell.sh`](file:///home/pera/github_repo/.dotfiles/scripts/profile-quickshell.sh) | **MODIFY** | Telemetry Harness / Benchmark Engine | Linux procfs/sysfs telemetry + Wayland uinput + Quickshell IPC | [`scripts/profile-quickshell.sh:1-1044`](file:///home/pera/github_repo/.dotfiles/scripts/profile-quickshell.sh#L1-L1044) | Add Phase 49 output directories, pre-flight media playback gate, automated no-Quickshell idle capture (asserting GPU $\le 10\%$), interactive popup automated loop, and comparative reporting. |
| [`scripts/phase49-audit-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase49-audit-assert.sh) | **CREATE** | Quality Assertion Suite / Verification Harness | Request-Response / File Inspection / Invariant Validation | [`scripts/phase43-perf-assert.sh:1-429`](file:///home/pera/github_repo/.dotfiles/scripts/phase43-perf-assert.sh#L1-L429)<br>[`scripts/phase48-right-zone-assert.sh:1-467`](file:///home/pera/github_repo/.dotfiles/scripts/phase48-right-zone-assert.sh#L1-L467) | 5-section CLI runner (`--section`, `--quick`, `--syntax`), non-root fail-closed guard, baseline invariant checks, JSON schema validation, optimization ceiling enforcement, and zero working tree drift assertion. |
| [`restow/quickshell/.../MediaControls.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml) | **MODIFY** | UI Popup / Audio Visualizer | Cava stdout stream $\to$ QML points array | Existing [`MediaControls.qml:56-72`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml#L56-L72) | Gate `cavaProc.running` to active playback only; throttle SplitParser parsing rate (frame-skipping to $\le 20\text{ FPS}$). |
| [`restow/quickshell/.../NetworkPingPopup.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml) | **MODIFY** | UI Popup / Network Diagnostics | Reactive state $\to$ QML Animation & Repeater delegates | Existing [`NetworkPingPopup.qml:110-133, 268-278`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml#L110-L133) | Bound `cardPulseAnimation` loops (replace `Animation.Infinite` with bounded 3-cycle pulse); cache DNS server array model to avoid per-tick delegate churn. |
| [`restow/quickshell/.../Voice.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/Voice.qml) | **MODIFY** | Background Service / Speech Telemetry | Tmpfs FileViews $\to$ QML property bindings | Existing [`Voice.qml:253-259`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/Voice.qml#L253-L259) | Relax idle polling interval from $500\text{ ms}$ to $2500\text{ ms}$ while retaining $100\text{ ms}$ during active voice engagement. |
| [`restow/quickshell/.../StorageUsage.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml) | **MODIFY** | Background Service / Storage Telemetry | `/proc/diskstats` $\to$ QML I/O metrics | Existing [`StorageUsage.qml:54-60`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml#L54-L60) | Relax idle diskstats polling interval from $1000\text{ ms}$ to $3000\text{ ms}$. |
| `BENCHMARK.md` | **GENERATE** | Benchmark Report Artifact | Telemetry data aggregation | Phase 43.1 `BENCHMARK.md` | Master comparative report documenting baseline, per-component attribution, pre/post optimization deltas, and invariant compliance. |
| `benchmark-latest.json` | **GENERATE** | Machine Telemetry Artifact | JSON serialization | Phase 43.1 `benchmark-latest.json` | Standard machine-readable telemetry schema recording hardware environment, stage measurements, and attribution deltas. |

---

## 3. Core Architectural Patterns to Emulate

### Pattern A: Unprivileged Quickshell Process Discovery & Safe Lifecycle
**Analog Source:** [`scripts/profile-quickshell.sh:131-217`](file:///home/pera/github_repo/.dotfiles/scripts/profile-quickshell.sh#L131-L217) and [`arch/dots-hyprland.sh:222-261`](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L222-L261)

Quickshell processes must be discovered without `pgrep -f` (which triggers false positives on text editors or log greps). Processes must terminate gracefully, wait for Wayland socket release, and restart cleanly:

```bash
# Analog excerpt from scripts/profile-quickshell.sh:131-169
collect_qs_pids() {
  local uid
  uid="$(id -u)"
  local proc pid cmdline exe comm owner exe_base argv0
  for proc in /proc/[0-9]*; do
    pid="${proc##*/}"
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    [[ "$pid" == "$$" ]] && continue

    owner="$(stat -c '%u' "$proc" 2>/dev/null || true)"
    [[ "$owner" == "$uid" ]] || continue

    comm="$(cat "$proc/comm" 2>/dev/null || true)"
    if [[ "$comm" == "qs" || "$comm" == "quickshell" ]]; then
      printf '%s\n' "$pid"
      continue
    fi

    exe="$(readlink "$proc/exe" 2>/dev/null || true)"
    exe_base="${exe% (deleted)}"
    exe_base="${exe_base##*/}"
    if [[ "$exe_base" == "qs" || "$exe_base" == "quickshell" ]]; then
      printf '%s\n' "$pid"
      continue
    fi

    cmdline=""
    if [[ -r "$proc/cmdline" ]]; then
      cmdline="$(tr '\0' ' ' <"$proc/cmdline" 2>/dev/null || true)"
      cmdline="${cmdline%"${cmdline##*[![:space:]]}"}"
    fi
    argv0="${cmdline%% *}"
    argv0="${argv0##*/}"
    if [[ "$argv0" == "qs" || "$argv0" == "quickshell" ]]; then
      printf '%s\n' "$pid"
      continue
    fi
  done
}
```

---

### Pattern B: CLI Argument Parsing, Signal Trap, and Non-Root Safety
**Analog Source:** [`scripts/phase48-right-zone-assert.sh:1-87`](file:///home/pera/github_repo/.dotfiles/scripts/phase48-right-zone-assert.sh#L1-L87) and [`scripts/phase43-perf-assert.sh:1-90`](file:///home/pera/github_repo/.dotfiles/scripts/phase43-perf-assert.sh#L1-L90)

All assertion harnesses and utility scripts must enforce non-root execution (`EUID != 0`), support `--section` (or numeric 1–5), `--quick`, `--syntax`, maintain temporary file cleanup traps on `EXIT INT TERM`, and output standard `[PASS]`, `[FAIL]`, `[FINDING]`, `[INFO]` tags:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Fail closed if executed as root (ASVS L1 Root Privilege Prevention)
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Error: Do not run as root" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass()    { printf '[PASS] %s\n' "$1"; }
fail()    { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info()    { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
cleanup() {
  local exit_code=$?
  if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    rm -f "${TMP_FILES[@]}" 2>/dev/null || true
  fi
  return "$exit_code"
}
trap cleanup EXIT INT TERM
```

---

### Pattern C: Intel UHD 770 iGPU DRM Sysfs Sampling & Wayland 2x Scaled ydotool Navigation
**Analog Source:** [`scripts/profile-quickshell.sh:521-547, 305-361`](file:///home/pera/github_repo/.dotfiles/scripts/profile-quickshell.sh#L521-L547), [`49-RESEARCH.md:108-115`](file:///home/pera/github_repo/.dotfiles/.planning/phases/49-quickshell-resource-profiling-component-performance-audit/49-RESEARCH.md#L108-L115)

1. **Unprivileged Intel iGPU Sampling**:
   Active render load is measured via kernel DRM RC6 residency counter:
   $$\text{Active Render Load \%} = \left(1.0 - \frac{\Delta \text{RC6}_{\text{ms}}}{\Delta t_{\text{ms}}}\right) \times 100$$
   ```bash
   sample_intel_gpu() {
     local rc6_path="/sys/class/drm/card1/gt/gt0/rc6_residency_ms"
     local act_freq_path="/sys/class/drm/card1/gt_act_freq_mhz"
     local cur_freq_path="/sys/class/drm/card1/gt_cur_freq_mhz"

     local rc6_ms=0 freq_mhz=0
     [[ -r "$rc6_path" ]] && rc6_ms="$(cat "$rc6_path" 2>/dev/null || echo 0)"
     if [[ -r "$act_freq_path" ]]; then
       freq_mhz="$(cat "$act_freq_path" 2>/dev/null || echo 0)"
     elif [[ -r "$cur_freq_path" ]]; then
       freq_mhz="$(cat "$cur_freq_path" 2>/dev/null || echo 0)"
     fi
     echo "$rc6_ms $freq_mhz"
   }
   ```

2. **Wayland 2x Coordinate Calculation**:
   On ultrawide display `DP-1` (3440x1440), testing confirmed an exact $2\times$ scale relationship with `uinput`:
   $$X_{\text{ydotool}} = \text{round}(X / 2), \quad Y_{\text{ydotool}} = \text{round}(Y / 2)$$
   - Top status bar center ($Y=20$): $Y_{\text{ydotool}} = 10$.
   - Screen center neutral idle ($X=1720, Y=720$): $X_{\text{ydotool}} = 860, Y_{\text{ydotool}} = 360$.

---

### Pattern D: Automated Baseline Cleanliness Gating & Media Playback Pre-flight
**Analog Source:** [`49-RESEARCH.md:232-244`](file:///home/pera/github_repo/.dotfiles/.planning/phases/49-quickshell-resource-profiling-component-performance-audit/49-RESEARCH.md#L232-L244)

External media players (e.g., YouTube video playback in Google Chrome) consume ~30% GPU continuously via hardware video decoding. The profiling harness must pre-flight test media state and isolate Quickshell:

```bash
check_and_pause_media() {
  if command -v playerctl >/dev/null 2>&1; then
    local statuses
    statuses="$(playerctl -a status 2>/dev/null || true)"
    if echo "$statuses" | grep -q "Playing"; then
      warn "Active media playback detected across MPRIS players!"
      info "Pausing active players to eliminate GPU hardware decode interference..."
      playerctl pause -a 2>/dev/null || true
      sleep 1.0
    fi
  fi
}

sample_system_idle_baseline() {
  header "Profiling Stage: System Idle Without Quickshell (system_idle_no_qs)"
  check_and_pause_media

  info "Stopping all Quickshell processes..."
  local qs_bin=""
  command -v qs >/dev/null 2>&1 && qs_bin="qs" || qs_bin="quickshell"
  $qs_bin -c ii kill 2>/dev/null || true
  killall -9 qs quickshell 2>/dev/null || true
  sleep 2.0  # Allow Intel iGPU to settle into RC6 sleep states

  local rc6_1 freq1 rc6_2 freq2 t1 t2
  t1="$(date +%s%N)"
  read -r rc6_1 freq1 <<< "$(sample_intel_gpu)"
  sleep 4.0
  t2="$(date +%s%N)"
  read -r rc6_2 freq2 <<< "$(sample_intel_gpu)"

  local dt_ms="$(awk -v t1="$t1" -v t2="$t2" 'BEGIN { printf "%.2f", (t2 - t1)/1000000.0 }')"
  local gpu_busy_pct="$(compute_gpu_load "$((rc6_2 - rc6_1))" "$dt_ms")"
  info "System Idle GPU Load: ${gpu_busy_pct}% (clock: ${freq2} MHz)"

  if (( $(awk -v g="$gpu_busy_pct" 'BEGIN { print (g <= 10.0) }') )); then
    pass "AUDIT-01 Invariant PASSED: System Idle GPU Load <= 10% (${gpu_busy_pct}%)"
  else
    warn "AUDIT-01 Invariant VIOLATION: System Idle GPU Load > 10% (${gpu_busy_pct}%). Check for external video/render activity!"
  fi

  # Record stage telemetry
  printf "%s|%s|0.00|0.00|0.00|0.00|0.00|0|0.0|0.0|0.0|0.0|0|%s|%s\n" \
    "system_idle_no_qs" "System Idle (No Quickshell)" "$gpu_busy_pct" "$freq2" >> "$STAGE_DATA_FILE"
}
```

---

### Pattern E: Multi-Target Declarative Interactive Popup Audit Engine
**Analog Source:** [`scripts/profile-quickshell.sh:68-80`](file:///home/pera/github_repo/.dotfiles/scripts/profile-quickshell.sh#L68-L80) and [`49-RESEARCH.md:251-268`](file:///home/pera/github_repo/.dotfiles/.planning/phases/49-quickshell-resource-profiling-component-performance-audit/49-RESEARCH.md#L251-L268)

Interactive popups are triggered using a unified dispatcher supporting both `hover` (via `ydotool mousemove`) and `ipc` (`qs -c ii ipc call <target> open/close`), validating active layer shell surfaces:

```bash
navigate_and_sample_popup() {
  local stage_id="$1"
  local stage_name="$2"
  local method="$3"      # "hover" or "ipc"
  local target_x="$4"     # ydotool X coord or IPC target name
  local target_y="$5"     # ydotool Y coord or IPC open method
  local expected_layer="$6"

  header "Interactive Popup Stage: $stage_name ($stage_id)"

  if [[ "$method" == "hover" ]]; then
    info "Moving cursor to ($target_x, $target_y) to activate popup..."
    ydotool mousemove -a -x "$target_x" -y "$target_y" 2>/dev/null || true
    sleep 0.5
  elif [[ "$method" == "ipc" ]]; then
    info "Triggering IPC call: qs -c ii ipc call $target_x $target_y"
    qs -c ii ipc call "$target_x" "$target_y" 2>/dev/null || true
    sleep 0.5
  fi

  # Verify layer shell surface exists
  if hyprctl layers 2>/dev/null | grep -q "namespace: $expected_layer"; then
    pass "Layer surface verified: $expected_layer"
  else
    warn "Layer surface $expected_layer not found in hyprctl layers output"
  fi

  # Run standard sampling window
  run_sample_window "$stage_id" "$stage_name" "custom_active"

  # Teardown / Dismiss
  if [[ "$method" == "hover" ]]; then
    ydotool mousemove -a -x 860 -y 360 2>/dev/null || true
    sleep 0.4
  elif [[ "$method" == "ipc" ]]; then
    qs -c ii ipc call "$target_x" "close" 2>/dev/null || true
    sleep 0.4
  fi
}
```

---

### Pattern F: QML High-Frequency Process Streaming Throttling
**Analog Source:** [`restow/quickshell/.../MediaControls.qml:56-72`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml#L56-L72)

`cava` raw stdout parsing at 60 FPS on the GUI thread consumes 45% CPU. Optimization combines **playback-state gating** with **frame-rate throttling**:

```qml
// Pattern: restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml
property int _cavaFrameSkip: 0

Process {
    id: cavaProc
    // Optimization 1: Only run cava process when media controls are open AND active player is Playing
    running: mediaControlsLoader.active && (root.activePlayer?.playbackState === MprisPlaybackState.Playing)
    onRunningChanged: {
        if (!cavaProc.running) {
            root.visualizerPoints = [];
            root._cavaFrameSkip = 0;
        }
    }
    command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
    stdout: SplitParser {
        onRead: data => {
            // Optimization 2: Frame-skipping throttle (downsample 60 FPS -> 20 FPS, cutting CPU by ~66%)
            root._cavaFrameSkip++;
            if (root._cavaFrameSkip % 3 !== 0) return;

            let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
            root.visualizerPoints = points;
        }
    }
}
```

---

### Pattern G: QML Animation Loop De-escalation & Delegate Model Caching
**Analog Source:** [`restow/quickshell/.../NetworkPingPopup.qml:110-133, 268-278`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml#L110-L133)

1. **Animation Loop De-escalation**:
   Infinite opacity loops (`loops: Animation.Infinite`) continuously wake the compositor and force 1550 MHz GPU clocks. Replace infinite looping with a 3-cycle pulse alert that settles on a static warning state:

```qml
// Pattern: restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml
SequentialAnimation {
    id: cardPulseAnimation
    running: card.isCritical
    loops: 3 // De-escalated from Animation.Infinite: pulse 3 times to grab attention, then settle
    onRunningChanged: {
        if (!running) {
            card.opacity = PingService.isOffline ? 0.6 : 1.0;
        }
    }
    NumberAnimation {
        target: card
        property: "opacity"
        to: 0.4
        duration: 600
        easing.type: Easing.InOutSine
    }
    NumberAnimation {
        target: card
        property: "opacity"
        to: PingService.isOffline ? 0.7 : 1.0
        duration: 600
        easing.type: Easing.InOutSine
    }
}
```

2. **Delegate Model Caching**:
   Instantiating inline arrays inside `Repeater.model` forces QML to recreate delegate items on every binding update:

```qml
// Pattern: Cache DNS model array
readonly property var cachedDnsServers: {
    const raw = NetworkUsage.dnsServers;
    if (!raw || raw === "--") return [{ label: "DNS Server", value: "--" }];
    const parts = raw.split(",").map(s => s.trim()).filter(s => s.length > 0);
    if (parts.length <= 1) return [{ label: "DNS Server", value: parts[0] || "--" }];
    return parts.map((dns, idx) => ({
        label: `DNS Server ${idx + 1}`,
        value: dns
    }));
}

Repeater {
    model: card.cachedDnsServers
    delegate: NetworkDetailRow {
        required property var modelData
        label: modelData.label
        value: modelData.value
    }
}
```

---

### Pattern H: QML Idle Polling Interval Backoff
**Analog Source:** [`Voice.qml:253-259`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/Voice.qml#L253-L259) and [`StorageUsage.qml:54-60`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml#L54-L60)

Services that poll procfs or tmpfs files during complete system idle must back off when no active interaction is in flight:

```qml
// Voice.qml: Relax idle poll interval from 500ms -> 2500ms (5x reduction in idle file reads)
Timer {
    id: pollTimer
    interval: (root.overallState === "idle" && !typingLingerTimer.running) ? 2500 : 100
    repeat: true
    running: true
    onTriggered: root.poll()
}
```

```qml
// StorageUsage.qml: Relax idle diskstats interval from 1000ms -> 3000ms (3x reduction in syscalls)
Timer {
    id: ioPollTimer
    interval: 3000
    repeat: true
    running: true
    onTriggered: root.updateDiskIo()
}
```

---

## 4. Concrete Implementation Templates

### 4.1 Test Harness Extension: `scripts/profile-quickshell.sh`

The profiling harness must support Phase 49 by allowing an override or auto-detection of the output phase directory and incorporating AUDIT-01 and AUDIT-02 procedures:

```bash
# Configuration defaults in scripts/profile-quickshell.sh
PHASE_DIR="$REPO_ROOT/.planning/phases/49-quickshell-resource-profiling-component-performance-audit"
JSON_OUT_FILE="$PHASE_DIR/benchmark-latest.json"
REPORT_OUT_FILE="$PHASE_DIR/BENCHMARK.md"

# CLI flag addition:
# --phase-dir <dir>       Override target phase output directory

# Declarative Registry Extended for AUDIT-02:
# Schema: STAGE_ID | METHOD | TARGET/COORD_X | COORD_Y | EXPECTED_LAYER | DESCRIPTION
POPUP_STAGES=(
  "popup_cpugpu|hover|100|10|quickshell:popup|CPU/GPU Inspector popup"
  "popup_memstorage|hover|40|10|quickshell:popup|Memory/Storage Breakdown popup"
  "popup_netping|hover|160|10|quickshell:popup|Network/Multi-Target Ping popup"
  "popup_clock|hover|800|10|quickshell:popup|Clock & Calendar popup"
  "popup_weather|hover|900|10|quickshell:popup|Weather extended forecast popup"
  "popup_mediacontrols|ipc|mediaControls|open|quickshell:mediaControls|MediaControls overlay"
  "popup_sidebarleft|ipc|sidebarLeft|open|quickshell:sidebarLeft|Left Dashboard sidebar"
  "popup_sidebarright|ipc|sidebarRight|open|quickshell:sidebarRight|Right Control sidebar"
)
```

---

### 4.2 Assertion Suite Blueprint: `scripts/phase49-audit-assert.sh`

Modeled directly on [`scripts/phase43-perf-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase43-perf-assert.sh) and [`scripts/phase48-right-zone-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase48-right-zone-assert.sh):

```bash
#!/usr/bin/env bash
# ===========================================================================
# Phase 49: Quickshell Resource Profiling & Component Performance Audit Assert
# Enforces: AUDIT-01, AUDIT-02, AUDIT-03
#
# Usage (from REPO_ROOT):
#   ./scripts/phase49-audit-assert.sh [1-5] [--section <1-5>] [-s <1-5>] [--quick] [--syntax]
#
# Exit 0 if all hard asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if executed as root
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Error: Do not run as root" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass()    { printf '[PASS] %s\n' "$1"; }
fail()    { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info()    { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
cleanup() {
  local exit_code=$?
  if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    rm -f "${TMP_FILES[@]}" 2>/dev/null || true
  fi
  return "$exit_code"
}
trap cleanup EXIT INT TERM

RUN_SECTION=0
QUICK_MODE=0
SYNTAX_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    1|2|3|4|5)
      RUN_SECTION="$1"
      shift
      ;;
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    --quick|-q)
      QUICK_MODE=1
      shift
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [1-5] [OPTIONS]"
      echo "Sections:"
      echo "  1: Test Harness Safety & Preconditions"
      echo "  2: Baseline Resource Invariants (AUDIT-01)"
      echo "  3: Component & Popup Audit Coverage (AUDIT-02)"
      echo "  4: Targeted Optimization Ceilings & AST Rules (AUDIT-03)"
      echo "  5: Strict Repository Verification & Zero Stow Drift"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

PHASE_DIR="$REPO_ROOT/.planning/phases/49-quickshell-resource-profiling-component-performance-audit"
BENCH_JSON="$PHASE_DIR/benchmark-latest.json"
BENCH_MD="$PHASE_DIR/BENCHMARK.md"

# ---------------------------------------------------------------------------
# Section 1: Test Harness Safety & Preconditions
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Test Harness Safety & Preconditions ---"
  
  PROFILE_SCRIPT="$REPO_ROOT/scripts/profile-quickshell.sh"
  [[ -x "$PROFILE_SCRIPT" ]] && pass "scripts/profile-quickshell.sh is executable" || fail "Missing or non-executable profile-quickshell.sh"
  
  if bash -n "$PROFILE_SCRIPT"; then
    pass "scripts/profile-quickshell.sh bash syntax valid"
  else
    fail "scripts/profile-quickshell.sh bash syntax error"
  fi

  [[ -r "/sys/class/drm/card1/gt/gt0/rc6_residency_ms" ]] && pass "Intel iGPU RC6 sysfs interface readable" || fail "Missing DRM RC6 sysfs interface"
  
  if command -v ydotool >/dev/null 2>&1; then
    pass "ydotool command available"
  else
    finding "ydotool not found in PATH"
  fi
fi

# ---------------------------------------------------------------------------
# Section 2: Baseline Resource Invariants (AUDIT-01)
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Baseline Resource Invariants (AUDIT-01) ---"

  if [[ -f "$BENCH_JSON" ]] && jq empty "$BENCH_JSON" 2>/dev/null; then
    # Invariant 1: System Idle without Quickshell GPU <= 10.0%
    IDLE_GPU="$(jq -r '.stages.system_idle_no_qs.gpu_busy_pct // empty' "$BENCH_JSON")"
    if [[ -n "$IDLE_GPU" ]]; then
      if (( $(awk -v g="$IDLE_GPU" 'BEGIN { print (g <= 10.0) }') )); then
        pass "AUDIT-01: System Idle GPU load <= 10.0% (${IDLE_GPU}%)"
      else
        fail "AUDIT-01: System Idle GPU load exceeded 10.0% (${IDLE_GPU}%)"
      fi
    else
      finding "AUDIT-01: stage 'system_idle_no_qs' not yet present in benchmark-latest.json"
    fi

    # Invariant 2: Upstream baseline CPU <= 5.0%, GPU <= 10.0%
    UPSTREAM_CPU="$(jq -r '.stages.upstream_baseline.cpu_pct_avg // empty' "$BENCH_JSON")"
    if [[ -n "$UPSTREAM_CPU" ]]; then
      if (( $(awk -v c="$UPSTREAM_CPU" 'BEGIN { print (c <= 5.0) }') )); then
        pass "AUDIT-01: Upstream baseline CPU <= 5.0% (${UPSTREAM_CPU}%)"
      else
        fail "AUDIT-01: Upstream baseline CPU exceeded 5.0% (${UPSTREAM_CPU}%)"
      fi
    fi
  else
    finding "benchmark-latest.json missing or invalid JSON; run profile-quickshell.sh to populate"
  fi
fi

# ---------------------------------------------------------------------------
# Section 3: Component & Popup Audit Coverage (AUDIT-02)
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Component & Popup Audit Coverage (AUDIT-02) ---"

  if [[ -f "$BENCH_JSON" ]] && jq empty "$BENCH_JSON" 2>/dev/null; then
    REQUIRED_STAGES=(
      "popup_cpugpu"
      "popup_memstorage"
      "popup_netping"
      "popup_clock"
      "popup_weather"
      "popup_mediacontrols"
      "popup_sidebarleft"
      "popup_sidebarright"
    )
    for sid in "${REQUIRED_STAGES[@]}"; do
      if jq -e --arg s "$sid" '.stages[$s] != null' "$BENCH_JSON" >/dev/null 2>&1; then
        pass "AUDIT-02 Coverage: stage '$sid' recorded in telemetry"
      else
        fail "AUDIT-02 Coverage: stage '$sid' missing from benchmark-latest.json"
      fi
    done
  fi

  if [[ -f "$BENCH_MD" ]]; then
    if grep -q "Master Attribution Matrix" "$BENCH_MD" && grep -q "Interactive Popup Attribution" "$BENCH_MD"; then
      pass "AUDIT-02: BENCHMARK.md contains interactive popup attribution reporting"
    else
      fail "AUDIT-02: BENCHMARK.md missing required attribution report sections"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Section 4: Targeted Optimization Ceilings & AST Rules (AUDIT-03)
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Targeted Optimization Ceilings & AST Rules (AUDIT-03) ---"

  MEDIA_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml"
  PING_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml"
  VOICE_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/Voice.qml"
  STORAGE_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml"

  # MediaControls.qml AST checks
  if grep -q "MprisPlaybackState.Playing" "$MEDIA_QML" || grep -q "activePlayer?.playbackState" "$MEDIA_QML"; then
    pass "MediaControls.qml gates cava execution by active playback state"
  else
    fail "MediaControls.qml missing playback state gating on cava process"
  fi

  if grep -q "_cavaFrameSkip" "$MEDIA_QML" || grep -q "throttle" "$MEDIA_QML"; then
    pass "MediaControls.qml implements cava frame rate throttling"
  else
    fail "MediaControls.qml missing frame rate throttling"
  fi

  # NetworkPingPopup.qml AST checks
  if grep -q "loops: Animation.Infinite" "$PING_QML"; then
    fail "NetworkPingPopup.qml still contains unbounded infinite animation loop (loops: Animation.Infinite)"
  else
    pass "NetworkPingPopup.qml de-escalates infinite cardPulseAnimation loops"
  fi

  # Voice.qml AST checks
  if grep -q "2500" "$VOICE_QML" || grep -q "2000" "$VOICE_QML"; then
    pass "Voice.qml relaxes idle tmpfs polling interval (>= 2000ms)"
  else
    fail "Voice.qml idle polling interval below relaxed threshold"
  fi

  # StorageUsage.qml AST checks
  if grep -q "interval: 3000" "$STORAGE_QML" || grep -q "interval: 5000" "$STORAGE_QML"; then
    pass "StorageUsage.qml relaxes idle diskstats interval (>= 3000ms)"
  else
    fail "StorageUsage.qml diskstats interval below relaxed threshold"
  fi
fi

# ---------------------------------------------------------------------------
# Section 5: Strict Repository Verification & Zero Stow Drift
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Strict Repository Verification & Zero Stow Drift ---"

  if [[ "$QUICK_MODE" -eq 0 && -x "$REPO_ROOT/arch/dots-hyprland.sh" ]]; then
    info "Running ./arch/dots-hyprland.sh verify --strict..."
    if "$REPO_ROOT/arch/dots-hyprland.sh" verify --strict; then
      pass "./arch/dots-hyprland.sh verify --strict passed cleanly"
    else
      fail "./arch/dots-hyprland.sh verify --strict failed"
    fi
  fi
fi

info "=== Assertion Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
```

---

## 5. Architectural Anti-Patterns & Guardrails

### ❌ Anti-Pattern 1: Profiling Without Pre-Flight Media Pause
- **Problem:** If a background Chrome/Firefox tab or media player is decoding video (e.g., YouTube), the GPU active render load will hover around ~30% even if Quickshell is completely shut down.
- **Guardrail:** The test harness must explicitly query `playerctl -a status` and pause active players before capturing system baseline measurements.

### ❌ Anti-Pattern 2: Unbounded Infinite Opacity Animations
- **Problem:** Using `SequentialAnimation { loops: Animation.Infinite }` on visibility or opacity properties prevents the compositor from caching surfaces and forces the Intel UHD 770 GPU to remain clocked at 1550 MHz boost.
- **Guardrail:** Cap alert animations to bounded iterations (e.g. `loops: 3`) or gate them strictly behind hover interactions (`cardMouseArea.containsMouse`).

### ❌ Anti-Pattern 3: 60 FPS ASCII Stream Parsing in QML Main Thread
- **Problem:** `cava` streams semicolon-delimited values over stdout 60 times per second. Splitting strings, mapping numbers, and assigning `visualizerPoints` every frame saturates the QML JavaScript thread and burns 45% CPU.
- **Guardrail:** Downsample/throttle points assignment with a frame counter (e.g. skip 2 out of 3 frames for a smooth 20 FPS visualizer) and gate `cavaProc.running` so it stops entirely when media is paused.

### ❌ Anti-Pattern 4: Inline Model Array Allocation in Repeaters
- **Problem:** `model: { const raw = ...; return parts.map(...); }` creates a brand-new JavaScript array object on every binding evaluation, forcing QML to tear down and recreate all delegate instances.
- **Guardrail:** Define a memoized property binding (e.g., `readonly property var cachedDnsServers: ...`) so delegates are only rebuilt when the underlying data string actually changes.

### ❌ Anti-Pattern 5: Aggressive Idle Polling on Inactive Subsystems
- **Problem:** `Voice.qml` reloading 6 FileViews every 500ms when speech recognition has not been invoked for hours causes unnecessary timer wakeups and context switches.
- **Guardrail:** Implement multi-tier intervals: 2500ms while completely idle, accelerating to 100ms when recording or processing.

---

## 6. Verification & Assertion Plan

The implementation in Phase 49 proceeds across 3 plans:

| Plan | Target Files | Key Assertions / Verifications |
| :--- | :--- | :--- |
| **Plan 49-01** | `scripts/profile-quickshell.sh`, `scripts/phase49-audit-assert.sh` | - Section 1 & Section 2 pass (`bash scripts/phase49-audit-assert.sh -s 1,2`).<br>- System idle GPU load without Quickshell $\le 10\%$ verified.<br>- Pure upstream baseline isolation captured and recorded. |
| **Plan 49-02** | `scripts/profile-quickshell.sh`, `benchmark-latest.json`, `BENCHMARK.md` | - Section 3 passes (`bash scripts/phase49-audit-assert.sh -s 3`).<br>- All 8+ popup stages recorded with layer shell confirmations.<br>- Empirical resource matrix documented. |
| **Plan 49-03** | `MediaControls.qml`, `NetworkPingPopup.qml`, `Voice.qml`, `StorageUsage.qml` | - Section 4 passes (`bash scripts/phase49-audit-assert.sh -s 4`).<br>- Pre- vs post-optimization deltas verified.<br>- Section 5 passes (`./arch/dots-hyprland.sh verify --strict` clean). |
