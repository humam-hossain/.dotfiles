#!/usr/bin/env bash
# ===========================================================================
# Phase 43.6: Streamlined CpuGpuPopup Layout & Process Elimination Assert Harness
# Enforces: CPUGPU-05, CPUGPU-06
#
# Usage (from REPO_ROOT):
#   ./scripts/phase43.6-streamline-assert.sh [1-5] [--section <1-5>] [-s <1-5>] [--quick]
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
      echo "  1: Process Attribution Tree Removal & Script Deprecation (CPUGPU-05, CPUGPU-06)"
      echo "  2: Dynamic Telemetry Bindings & Hardware Discovery (CPUGPU-05, CPUGPU-06)"
      echo "  3: Two-Column Streamlined Layout Structure"
      echo "  4: Lifecycle & Safety Controls"
      echo "  5: Stow Symlink Integrity & Working Tree Verification"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

info "=== Phase 43.6 Streamlined CpuGpuPopup Assert Harness ==="
info "Working directory: $REPO_ROOT"
info "Flags: section=$RUN_SECTION quick=$QUICK_MODE"

BAR_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar"
SCRIPTS_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/scripts/resource-usage"

POPUP_QML="$BAR_DIR/CpuGpuPopup.qml"
PROCESS_TREE_PY="$SCRIPTS_DIR/process_tree.py"
PROCESS_TREE_SH="$SCRIPTS_DIR/process_tree.sh"

# ===========================================================================
# Section 1: Process Attribution Tree Removal & Script Deprecation (CPUGPU-05, CPUGPU-06)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Process Attribution Tree Removal & Script Deprecation ---"

  if [[ ! -f "$POPUP_QML" ]]; then
    fail "CpuGpuPopup.qml does not exist at $POPUP_QML"
  else
    pass "CpuGpuPopup.qml exists"

    # Verify zero references to process tree properties, functions, timers, and processes
    PROC_MATCHES=$(grep -nE "(topCpuProcesses|topGpuProcesses|procScanTimer|processTreeProc|triggerProcessScan|process_tree\.sh|process_tree\.py)" "$POPUP_QML" || true)
    if [[ -n "$PROC_MATCHES" ]]; then
      fail "CpuGpuPopup.qml contains process scanner references: $PROC_MATCHES"
    else
      pass "CpuGpuPopup.qml contains zero process scanner references"
    fi

    # Verify Quickshell.Io import is removed
    if grep -qE "import[[:space:]]+Quickshell\.Io" "$POPUP_QML"; then
      fail "CpuGpuPopup.qml still imports Quickshell.Io"
    else
      pass "CpuGpuPopup.qml does not import Quickshell.Io"
    fi

    # Verify deprecation notice in process_tree.py
    if [[ -f "$PROCESS_TREE_PY" ]]; then
      if grep -qi "DEPRECATED" "$PROCESS_TREE_PY"; then
        pass "process_tree.py contains deprecation notice"
      else
        fail "process_tree.py missing deprecation notice"
      fi
    else
      fail "process_tree.py not found at $PROCESS_TREE_PY"
    fi

    # Verify deprecation notice in process_tree.sh
    if [[ -f "$PROCESS_TREE_SH" ]]; then
      if grep -qi "DEPRECATED" "$PROCESS_TREE_SH"; then
        pass "process_tree.sh contains deprecation notice"
      else
        fail "process_tree.sh missing deprecation notice"
      fi
    else
      fail "process_tree.sh not found at $PROCESS_TREE_SH"
    fi
  fi
fi

# ===========================================================================
# Section 2: Dynamic Telemetry Bindings & Hardware Discovery (CPUGPU-05, CPUGPU-06)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Dynamic Telemetry Bindings & Hardware Discovery ---"

  if [[ ! -f "$POPUP_QML" ]]; then
    fail "CpuGpuPopup.qml does not exist at $POPUP_QML"
  else
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
# Section 3: Two-Column Streamlined Layout Structure
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Two-Column Streamlined Layout Structure ---"

  if [[ ! -f "$POPUP_QML" ]]; then
    fail "CpuGpuPopup.qml does not exist at $POPUP_QML"
  else
    # Check for two columns with preferredWidth: 320
    COL_320_COUNT=$(grep -cE "preferredWidth:[[:space:]]*320" "$POPUP_QML" || true)
    if [[ "$COL_320_COUNT" -ge 2 ]]; then
      pass "CpuGpuPopup.qml declares at least two 320px preferredWidth columns ($COL_320_COUNT found)"
    else
      fail "CpuGpuPopup.qml does not declare two 320px preferredWidth columns (found $COL_320_COUNT)"
    fi

    # Verify vertical divider exists between columns
    if grep -qE "implicitWidth:[[:space:]]*1" "$POPUP_QML" && grep -qE "Layout\.fillHeight:[[:space:]]*true" "$POPUP_QML"; then
      pass "Vertical separator exists between columns"
    else
      fail "Missing vertical separator (implicitWidth: 1, Layout.fillHeight: true) between columns"
    fi

    # Verify Right column contains Platform header and 6 PlatformSensorRow instances
    SENSOR_COUNT=$(grep -c "PlatformSensorRow" "$POPUP_QML" || true)
    if [[ "$SENSOR_COUNT" -ge 6 ]]; then
      pass "Right column contains 6 PlatformSensorRow instances ($SENSOR_COUNT found)"
    else
      fail "CpuGpuPopup.qml has fewer than 6 PlatformSensorRow instances ($SENSOR_COUNT found)"
    fi

    # Verify no bottom drawer layout spanning across columns
    # In the old layout, the bottom drawer was a separate ColumnLayout after the upper RowLayout.
    # In the new layout, popupContent is a RowLayout and does not have a bottom drawer ColumnLayout.
    if awk '
      /id:[[:space:]]*popupContent/ { in_pc=1; next }
      in_pc && /RowLayout[[:space:]]*\{/ { in_row=1; next }
      in_pc && !in_row && /StyledPopupHeaderRow/ && /Platform/ { bottom_drawer=1 }
      END { exit bottom_drawer ? 1 : 0 }
    ' "$POPUP_QML"; then
      pass "Zero bottom drawer spanning across columns detected"
    else
      fail "Detected separate bottom drawer spanning across columns"
    fi
  fi
fi

# ===========================================================================
# Section 4: Lifecycle & Safety Controls
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Lifecycle & Safety Controls ---"

  if [[ ! -f "$POPUP_QML" ]]; then
    fail "CpuGpuPopup.qml does not exist at $POPUP_QML"
  else
    # Verify fastPollingRequests increment and decrement
    if grep -q "HardwareTelemetry.fastPollingRequests++" "$POPUP_QML"; then
      pass "fastPollingRequests increment on active is present"
    else
      fail "Missing fastPollingRequests increment on active"
    fi

    DECREMENT_COUNT=$(grep -c "HardwareTelemetry.fastPollingRequests--" "$POPUP_QML" || true)
    if [[ "$DECREMENT_COUNT" -ge 2 ]]; then
      pass "fastPollingRequests decrement on inactive and destruction present ($DECREMENT_COUNT instances)"
    else
      fail "fastPollingRequests decrement missing on inactive or destruction (found $DECREMENT_COUNT instances)"
    fi

    # Verify popupCriticalPulse is gated strictly on root.active && root.isCritical
    if grep -qE "running:[[:space:]]*root\.active[[:space:]]*&&[[:space:]]*root\.isCritical" "$POPUP_QML"; then
      pass "popupCriticalPulse is gated strictly on root.active && root.isCritical"
    else
      fail "popupCriticalPulse missing strict root.active && root.isCritical gate"
    fi

    # Verify zero hardcoded alert hex colors (#FF0000, #ff0000, etc.)
    ALERT_HEX=$(grep -nE '"#(FF0000|ff0000|F00|f00)"' "$POPUP_QML" || true)
    if [[ -n "$ALERT_HEX" ]]; then
      fail "Hardcoded alert hex color detected in CpuGpuPopup.qml: $ALERT_HEX"
    else
      pass "Zero hardcoded alert hex colors detected"
    fi
  fi
fi

# ===========================================================================
# Section 5: Stow Symlink Integrity & Working Tree Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Stow Symlink Integrity & Working Tree Verification ---"

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
info "=== Phase 43.6 Assert Summary ==="
info "Failures: $FAIL, Findings: $FINDINGS"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
