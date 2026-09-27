#!/usr/bin/env bash
# ===========================================================================
# Phase 43.5: Dynamic Telemetry, Process Attribution Tree & Hover Delay Assert Harness
# Enforces: CPUGPU-05..07, POPUP-01, INTG-02
#
# Usage (from REPO_ROOT):
#   ./scripts/phase43.5-dynamic-telemetry-assert.sh [1-5] [--section <1-5>] [-s <1-5>] [--quick]
#
# Exit 0 if all asserts pass (FAIL=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

RUN_SECTION=0
QUICK_MODE=0

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
    -h|--help)
      echo "Usage: $0 [1-5] [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  [1-5]                 Positional section selector"
      echo "  -s, --section <1-5>   Execute only the specified section (1-5)"
      echo "  -q, --quick           Execute static / quick checks only"
      echo "  -h, --help            Show this help message"
      echo ""
      echo "Sections:"
      echo "  1: Static Verification & Dynamic Telemetry Bindings (CPUGPU-05)"
      echo "  2: Dynamic Core Topology & Hardware Discovery (CPUGPU-06)"
      echo "  3: Hover Intent Delay & Grace Period State Machine (POPUP-01)"
      echo "  4: Process Attribution Tree Engine Integration (CPUGPU-07)"
      echo "  5: Stow Symlink Integrity & Working Tree Verification (INTG-02)"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

info "=== Phase 43.5 Dynamic Telemetry & Process Tree Assert Harness ==="
info "Working directory: $REPO_ROOT"
info "Flags: section=$RUN_SECTION quick=$QUICK_MODE"

BAR_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar"
SERVICES_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services"
SCRIPTS_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/scripts/resource-usage"

POPUP_QML="$BAR_DIR/CpuGpuPopup.qml"
STYLED_POPUP_QML="$BAR_DIR/StyledPopup.qml"
HARDWARE_TELEMETRY_QML="$SERVICES_DIR/HardwareTelemetry.qml"
PROCESS_TREE_PY="$SCRIPTS_DIR/process_tree.py"

# ===========================================================================
# Section 1: Static Verification & Dynamic Telemetry Bindings (CPUGPU-05)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Static Verification & Dynamic Telemetry Bindings (CPUGPU-05) ---"

  if [[ ! -f "$POPUP_QML" ]]; then
    fail "CpuGpuPopup.qml does not exist at $POPUP_QML"
  else
    pass "CpuGpuPopup.qml exists"

    # Verify absence of hardcoded hardware models and thread counts
    HARDCODED_MATCHES=$(grep -nE "(i5-13500|Intel UHD 770|B760|\(12T\)|\(8T\))" "$POPUP_QML" || true)
    if [[ -n "$HARDCODED_MATCHES" ]]; then
      fail "CpuGpuPopup.qml contains hardcoded hardware strings: $HARDCODED_MATCHES"
    else
      pass "CpuGpuPopup.qml contains zero hardcoded hardware strings"
    fi

    # Verify dynamic property bindings
    if grep -q "HardwareTelemetry.cpuModelName" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml binds dynamically to HardwareTelemetry.cpuModelName"
    else
      fail "CpuGpuPopup.qml missing binding to HardwareTelemetry.cpuModelName"
    fi

    if grep -q "HardwareTelemetry.gpuModelName" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml binds dynamically to HardwareTelemetry.gpuModelName"
    else
      fail "CpuGpuPopup.qml missing binding to HardwareTelemetry.gpuModelName"
    fi

    if grep -q "HardwareTelemetry.motherboardModelName" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml binds dynamically to HardwareTelemetry.motherboardModelName"
    else
      fail "CpuGpuPopup.qml missing binding to HardwareTelemetry.motherboardModelName"
    fi

    if grep -q "HardwareTelemetry.isHybridArchitecture" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml gates hybrid topology on HardwareTelemetry.isHybridArchitecture"
    else
      fail "CpuGpuPopup.qml missing check for HardwareTelemetry.isHybridArchitecture"
    fi
  fi
fi

# ===========================================================================
# Section 2: Dynamic Core Topology & Hardware Discovery (CPUGPU-06)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Dynamic Core Topology & Hardware Discovery (CPUGPU-06) ---"

  if [[ ! -f "$HARDWARE_TELEMETRY_QML" ]]; then
    fail "HardwareTelemetry.qml does not exist at $HARDWARE_TELEMETRY_QML"
  else
    pass "HardwareTelemetry.qml exists"

    # Verify property declarations
    for prop in "property string cpuModelName" \
                "property string gpuModelName" \
                "property string motherboardModelName" \
                "property bool isHybridArchitecture" \
                "property int pCoreThreadCount" \
                "property int eCoreThreadCount" \
                "property int totalThreadCount"; do
      if grep -q "$prop" "$HARDWARE_TELEMETRY_QML"; then
        pass "HardwareTelemetry.qml declares $prop"
      else
        fail "HardwareTelemetry.qml missing declaration: $prop"
      fi
    done

    # Verify dynamic sysfs query for cpu_atom
    if grep -q "cpu_atom" "$HARDWARE_TELEMETRY_QML"; then
      pass "HardwareTelemetry.qml queries /sys/devices/cpu_atom for hybrid topology"
    else
      fail "HardwareTelemetry.qml does not query cpu_atom"
    fi

    # Verify no hardcoded thread count division in updateCpuLoadTier2
    if grep -E "(pCoreSum / 12\.0|eCoreSum / 8\.0)" "$HARDWARE_TELEMETRY_QML"; then
      fail "HardwareTelemetry.qml still contains hardcoded thread count divisions (12.0 or 8.0)"
    else
      pass "HardwareTelemetry.qml uses dynamic core counts for load calculation"
    fi

    # Verify dynamic hardware resolver execution
    HW_OUTPUT=$(bash -c '
      cpu_name=$(awk -F": " "/model name/ {print $2; exit}" /proc/cpuinfo 2>/dev/null | sed -E "s/.*(Core\(TM\) |AMD )//; s/\((R|TM)\)//g; s/CPU //g; s/Processor//g; s/@.*//; s/^[ ]+//; s/[ ]+$//")
      [ -z "$cpu_name" ] && cpu_name="CPU"
      gpu_name="GPU"
      if command -v lspci >/dev/null 2>&1; then
        gpu_raw=$(lspci -d ::0300 2>/dev/null | head -n1 | sed -E "s/.*: (Intel Corporation |Advanced Micro Devices, Inc. \\[AMD\\/ATI\\] |NVIDIA Corporation )?//; s/.*\\[(.*)\\].*/\\1/; s/^[ ]+//; s/[ ]+$//")
        [ -n "$gpu_raw" ] && gpu_name="$gpu_raw"
      fi
      mobo_name="Platform"
      if [ -r /sys/class/dmi/id/board_name ]; then
        mobo_name=$(cat /sys/class/dmi/id/board_name 2>/dev/null | xargs)
      elif [ -r /sys/class/dmi/id/product_name ]; then
        mobo_name=$(cat /sys/class/dmi/id/product_name 2>/dev/null | xargs)
      fi
      [ -z "$mobo_name" ] && mobo_name="Platform"
      is_hybrid=false
      p_threads=0
      e_threads=0
      if [ -d /sys/devices/cpu_atom ] && [ -f /sys/devices/cpu_atom/cpus ]; then
        is_hybrid=true
        p_threads=$(cat /sys/devices/cpu_core/cpus 2>/dev/null | tr "," "\n" | awk -F- "{ if (\$2 != \"\") sum += (\$2 - \$1 + 1); else sum += 1 } END { print sum }")
        e_threads=$(cat /sys/devices/cpu_atom/cpus 2>/dev/null | tr "," "\n" | awk -F- "{ if (\$2 != \"\") sum += (\$2 - \$1 + 1); else sum += 1 } END { print sum }")
      else
        p_threads=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo 1)
        e_threads=0
      fi
      echo "$cpu_name|$gpu_name|$mobo_name|$is_hybrid|$p_threads|$e_threads"
    ')

    IFS="|" read -r c_name g_name m_name hyb p_t e_t <<< "$HW_OUTPUT"
    info "Host Hardware: CPU='$c_name', GPU='$g_name', Mobo='$m_name', Hybrid=$hyb, P=$p_t, E=$e_t"
    if [[ -n "$c_name" && "$c_name" != "CPU" ]]; then
      pass "Resolved valid CPU model name ($c_name)"
    else
      finding "CPU model name resolved to fallback ($c_name)"
    fi

    if [[ "$hyb" == "true" ]]; then
      if [[ "$p_t" -gt 0 && "$e_t" -gt 0 ]]; then
        pass "Hybrid architecture correctly computed P-threads ($p_t) and E-threads ($e_t)"
      else
        fail "Hybrid architecture reported invalid thread counts: P=$p_t, E=$e_t"
      fi
    else
      if [[ "$p_t" -gt 0 && "$e_t" -eq 0 ]]; then
        pass "Uniform architecture correctly computed P-threads ($p_t) and E-threads ($e_t)"
      else
        fail "Uniform architecture reported invalid thread counts: P=$p_t, E=$e_t"
      fi
    fi
  fi
fi

# ===========================================================================
# Section 3: Hover Intent Delay & Grace Period State Machine (POPUP-01)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Hover Intent Delay & Grace Period State Machine (POPUP-01) ---"

  if [[ ! -f "$STYLED_POPUP_QML" ]]; then
    fail "StyledPopup.qml does not exist at $STYLED_POPUP_QML"
  else
    pass "StyledPopup.qml exists"

    # Check for hoverOpenDelayMs property
    if grep -q "hoverOpenDelayMs: 1000" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml sets hoverOpenDelayMs: 1000"
    else
      fail "StyledPopup.qml missing hoverOpenDelayMs: 1000"
    fi

    # Check for openTimer declaration and interval
    if grep -q "openTimer" "$STYLED_POPUP_QML" && grep -q "interval: root.hoverOpenDelayMs" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml declares openTimer with interval: root.hoverOpenDelayMs"
    elif grep -q "openTimer" "$STYLED_POPUP_QML" && grep -q "interval: hoverOpenDelayMs" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml declares openTimer with interval: hoverOpenDelayMs"
    else
      fail "StyledPopup.qml missing openTimer linked to hoverOpenDelayMs"
    fi

    # Check for closeTimer declaration with 200ms grace period
    if grep -q "closeTimer" "$STYLED_POPUP_QML" && grep -q "interval: 200" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml declares closeTimer with interval: 200 (grace period)"
    else
      fail "StyledPopup.qml missing closeTimer with interval: 200"
    fi

    # Check onHoveredChanged state transitions
    if grep -q "root.openTimer.stop()" "$STYLED_POPUP_QML" || grep -q "openTimer.stop()" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml cancels openTimer when unhovered"
    else
      fail "StyledPopup.qml does not cancel openTimer when unhovered"
    fi

    if grep -q "root.openTimer.restart()" "$STYLED_POPUP_QML" || grep -q "openTimer.restart()" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml starts openTimer on hover"
    else
      fail "StyledPopup.qml does not start openTimer on hover"
    fi
  fi
fi

# ===========================================================================
# Section 4: Process Attribution Tree Engine Integration (CPUGPU-07)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Process Attribution Tree Engine Integration (CPUGPU-07) ---"

  if [[ ! -f "$PROCESS_TREE_PY" ]]; then
    fail "process_tree.py does not exist at $PROCESS_TREE_PY"
  else
    pass "process_tree.py exists"

    if [[ ! -x "$PROCESS_TREE_PY" ]]; then
      fail "process_tree.py is not marked executable"
    else
      pass "process_tree.py is executable"
    fi

    # Execute process_tree.py and measure execution time
    T_START=$(date +%s%N)
    TREE_OUTPUT=$(python3 "$PROCESS_TREE_PY" 2>&1 || true)
    T_END=$(date +%s%N)
    DURATION_MS=$(( (T_END - T_START) / 1000000 ))

    info "process_tree.py execution time: ${DURATION_MS}ms"

    if echo "$TREE_OUTPUT" | jq -e . >/dev/null 2>&1; then
      pass "process_tree.py produces valid JSON"

      # Check for top_cpu and top_gpu arrays
      HAS_TOP_CPU=$(echo "$TREE_OUTPUT" | jq 'has("top_cpu") and (.top_cpu | type == "array")')
      HAS_TOP_GPU=$(echo "$TREE_OUTPUT" | jq 'has("top_gpu") and (.top_gpu | type == "array")')

      if [[ "$HAS_TOP_CPU" == "true" ]]; then
        pass "process_tree.py output contains top_cpu array"
      else
        fail "process_tree.py output missing top_cpu array"
      fi

      if [[ "$HAS_TOP_GPU" == "true" ]]; then
        pass "process_tree.py output contains top_gpu array"
      else
        fail "process_tree.py output missing top_gpu array"
      fi

      # Execution speed check
      if [[ "$DURATION_MS" -le 100 ]]; then
        pass "process_tree.py executed in <= 100ms (${DURATION_MS}ms)"
      else
        finding "process_tree.py executed in > 100ms (${DURATION_MS}ms)"
      fi
    else
      fail "process_tree.py did not produce valid JSON: $TREE_OUTPUT"
    fi
  fi
fi

# ===========================================================================
# Section 5: Stow Symlink Integrity & Working Tree Verification (INTG-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Stow Symlink Integrity & Working Tree Verification (INTG-02) ---"

  if [[ "$QUICK_MODE" -eq 1 ]]; then
    pass "Skipping strict stow verification in quick mode"
  else
    if ./arch/dots-hyprland.sh verify --strict >/dev/null 2>&1; then
      pass "Stow symlinks and managed files pass strict verification"
    else
      fail "Stow symlink verification failed"
    fi
  fi
fi

# ===========================================================================
# Summary
# ===========================================================================
info "=== Phase 43.5 Assert Summary ==="
info "Failures: $FAIL, Findings: $FINDINGS"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
