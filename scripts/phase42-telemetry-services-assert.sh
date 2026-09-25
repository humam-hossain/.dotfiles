#!/usr/bin/env bash
# ===========================================================================
# Phase 42: Telemetry Services & Sensor Infrastructure Assert Harness
# Enforces: CPUGPU-01..04, MEMDSK-01..04, NETPING-01..05, D-01 through D-15
#
# Usage (from REPO_ROOT):
#   ./scripts/phase42-telemetry-services-assert.sh [1-6] [--section <1-6>] [--quick] [--syntax]
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

TMP_FILES=()
cleanup() {
  if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    rm -f "${TMP_FILES[@]}" 2>/dev/null || true
  fi
  return 0
}
trap cleanup EXIT INT TERM

RUN_SECTION=0
QUICK_MODE=0
SYNTAX_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    1|2|3|4|5|6)
      RUN_SECTION="$1"
      shift
      ;;
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-6]$ ]]; then
        echo "Error: --section requires an integer from 1 to 6" >&2
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
      echo "Usage: $0 [1-6] [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  [1-6]                 Positional section selector"
      echo "  -s, --section <1-6>   Execute only the specified section (1-6)"
      echo "  -q, --quick           Execute static / quick checks only"
      echo "  -c, --syntax          Execute syntax checks only"
      echo "  -h, --help            Show this help message"
      echo ""
      echo "Sections:"
      echo "  1: Structure & Environment Verification"
      echo "  2: HardwareTelemetry.qml (CPUGPU-01..04, D-01..D-07, T-42-01)"
      echo "  3: StorageUsage.qml (MEMDSK-01..04, D-08..D-11, T-42-02)"
      echo "  4: PingService.qml & server.py (NETPING-01..05, D-12..D-14, T-42-03)"
      echo "  5: ResourceUsage.qml (MEMDSK-01, D-15)"
      echo "  6: Stow Integrity & Symlink Verification"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

info "=== Phase 42 Telemetry Services & Sensor Infrastructure Assert Harness ==="
info "Working directory: $REPO_ROOT"
info "Flags: section=$RUN_SECTION quick=$QUICK_MODE syntax_only=$SYNTAX_ONLY"

# ===========================================================================
# Section 1: Structure & Environment Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Structure & Environment Verification ---"
  
  # Check required tools
  REQUIRED_TOOLS=(bash git python3 jq curl stow)
  for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      pass "Required tool '$tool' is available"
    else
      fail "Required tool '$tool' is missing"
    fi
  done

  # Check quickshell or qs
  if command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1; then
    pass "Quickshell executable is installed"
  else
    finding "Quickshell executable not found in PATH (syntax verification may degrade)"
  fi

  # Check service directory exists in restow
  SERVICE_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services"
  if [[ -d "$SERVICE_DIR" ]]; then
    pass "Service directory exists: $SERVICE_DIR"
  else
    fail "Service directory does not exist: $SERVICE_DIR"
  fi
fi

# ===========================================================================
# Section 2: HardwareTelemetry.qml (CPUGPU-01..04, D-01..D-07, T-42-01)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: HardwareTelemetry.qml Verification ---"
  HW_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml"
  
  if [[ ! -f "$HW_QML" ]]; then
    fail "HardwareTelemetry.qml does not exist at $HW_QML"
  else
    pass "HardwareTelemetry.qml exists"
    
    # Pragma checks
    if grep -q "pragma Singleton" "$HW_QML"; then
      pass "HardwareTelemetry.qml declares pragma Singleton"
    else
      fail "HardwareTelemetry.qml missing pragma Singleton"
    fi
    
    # D-01: Adaptive Polling
    if grep -qE "interval:" "$HW_QML" && grep -qE "(1000|3000)" "$HW_QML"; then
      pass "HardwareTelemetry.qml implements adaptive polling cadence (1000ms/3000ms)"
    else
      fail "HardwareTelemetry.qml does not implement adaptive polling interval (1000ms/3000ms)"
    fi

    # D-02: P-Core & E-Core Segregation
    REQUIRED_PROPS_CPU=(
      "overallCpuLoad"
      "pCoreLoad"
      "eCoreLoad"
      "pCoreFrequencyMhz"
      "eCoreFrequencyMhz"
      "perThreadLoads"
    )
    for prop in "${REQUIRED_PROPS_CPU[@]}"; do
      if grep -qE "(property[[:space:]]+[A-Za-z0-9_<>]+[[:space:]]+$prop|readonly[[:space:]]+property[[:space:]]+[A-Za-z0-9_<>]+[[:space:]]+$prop)" "$HW_QML"; then
        pass "HardwareTelemetry.qml exposes property: $prop"
      else
        fail "HardwareTelemetry.qml missing required CPU property: $prop"
      fi
    done

    # D-03: EPP & Governor
    if grep -q "energyPerformancePreference" "$HW_QML" && grep -q "scalingGovernor" "$HW_QML"; then
      pass "HardwareTelemetry.qml exposes energyPerformancePreference and scalingGovernor"
    else
      fail "HardwareTelemetry.qml missing EPP or scalingGovernor properties"
    fi

    # D-04: Intel UHD 770 iGPU Telemetry
    REQUIRED_PROPS_GPU=(
      "gpuLoad"
      "gpuFrequencyMhz"
      "gpuThrottled"
    )
    for prop in "${REQUIRED_PROPS_GPU[@]}"; do
      if grep -qE "(property[[:space:]]+[A-Za-z0-9_<>]+[[:space:]]+$prop|readonly[[:space:]]+property[[:space:]]+[A-Za-z0-9_<>]+[[:space:]]+$prop)" "$HW_QML"; then
        pass "HardwareTelemetry.qml exposes GPU property: $prop"
      else
        fail "HardwareTelemetry.qml missing required GPU property: $prop"
      fi
    done

    # D-05: Zero Root / Wattage Omission (T-42-01)
    if grep -qiE "(rapl|watts|wattage|power_uw|energy_uj)" "$HW_QML"; then
      fail "HardwareTelemetry.qml references privileged power/RAPL nodes (violates D-05 Zero Root / Wattage Omission)"
    else
      pass "HardwareTelemetry.qml contains no privileged power/RAPL references (D-05 verified)"
    fi

    # D-06 & D-07: Thermals
    REQUIRED_PROPS_TEMP=(
      "packageTemp"
      "peakSystemTemperature"
      "peakDeviceLabel"
      "nvme1Temp"
      "nvme2Temp"
      "vrmTemp"
    )
    for prop in "${REQUIRED_PROPS_TEMP[@]}"; do
      if grep -qE "(property[[:space:]]+[A-Za-z0-9_<>]+[[:space:]]+$prop|readonly[[:space:]]+property[[:space:]]+[A-Za-z0-9_<>]+[[:space:]]+$prop)" "$HW_QML"; then
        pass "HardwareTelemetry.qml exposes thermal property: $prop"
      else
        fail "HardwareTelemetry.qml missing required thermal property: $prop"
      fi
    done
  fi
fi

# ===========================================================================
# Section 3: StorageUsage.qml (MEMDSK-01..04, D-08..D-11, T-42-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: StorageUsage.qml Verification ---"
  STORAGE_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml"
  
  if [[ ! -f "$STORAGE_QML" ]]; then
    fail "StorageUsage.qml does not exist at $STORAGE_QML"
  else
    pass "StorageUsage.qml exists"
    
    # Pragma check
    if grep -q "pragma Singleton" "$STORAGE_QML"; then
      pass "StorageUsage.qml declares pragma Singleton"
    else
      fail "StorageUsage.qml missing pragma Singleton"
    fi

    # D-08: Pure I/O-driven / on-demand df
    if grep -qE "(function[[:space:]]+refresh|function[[:space:]]+queryDf)" "$STORAGE_QML"; then
      pass "StorageUsage.qml exposes refresh() function for on-demand polling"
    else
      fail "StorageUsage.qml missing on-demand refresh function"
    fi

    # D-09 & D-10: diskstats tracking & active disk
    REQUIRED_PROPS_STORAGE=(
      "diskIoPercentage"
      "readBytesPerSec"
      "writeBytesPerSec"
      "activeDisk"
      "mounts"
    )
    for prop in "${REQUIRED_PROPS_STORAGE[@]}"; do
      if grep -qE "(property[[:space:]]+[A-Za-z0-9_<>]+[[:space:]]+$prop|readonly[[:space:]]+property[[:space:]]+[A-Za-z0-9_<>]+[[:space:]]+$prop)" "$STORAGE_QML"; then
        pass "StorageUsage.qml exposes property: $prop"
      else
        fail "StorageUsage.qml missing required storage property: $prop"
      fi
    done

    # D-11: Mount classification
    if grep -q "gdrive" "$STORAGE_QML" || grep -q "GoogleDrive" "$STORAGE_QML"; then
      pass "StorageUsage.qml includes classification for cloud FUSE mounts"
    else
      fail "StorageUsage.qml missing classification for GoogleDrive / cloud FUSE mounts"
    fi
  fi
fi

# ===========================================================================
# Section 4: PingService.qml & server.py (NETPING-01..05, D-12..D-14, T-42-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: PingService.qml & server.py Verification ---"
  
  # Check server.py
  SERVER_PY="$REPO_ROOT/stow/system_monitor/.config/system_monitor/ping/server.py"
  if [[ ! -f "$SERVER_PY" ]]; then
    fail "server.py does not exist at $SERVER_PY"
  else
    pass "server.py exists"
    
    # Check D-12 clean JSON output in server.py (render_status must return targets)
    if grep -A 25 "def render_status" "$SERVER_PY" | grep -q '"targets":'; then
      pass "server.py includes 'targets' key in render_status return payload"
    else
      fail "server.py render_status missing clean 'targets' structured JSON payload in /api/status"
    fi
  fi

  # Check PingService.qml
  PING_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/PingService.qml"
  if [[ ! -f "$PING_QML" ]]; then
    fail "PingService.qml does not exist at $PING_QML"
  else
    pass "PingService.qml exists"
    
    # Pragma check
    if grep -q "pragma Singleton" "$PING_QML"; then
      pass "PingService.qml declares pragma Singleton"
    else
      fail "PingService.qml missing pragma Singleton"
    fi

    # D-13: 5s polling and 15s offline backoff
    if grep -q "5000" "$PING_QML" && grep -q "15000" "$PING_QML"; then
      pass "PingService.qml implements 5000ms poll and 15000ms offline backoff"
    else
      fail "PingService.qml missing 5000ms polling and 15000ms offline backoff cadence"
    fi

    # D-14: Target properties
    REQUIRED_PROPS_PING=(
      "wanLatency"
      "wanStatus"
      "gatewayLatency"
      "gatewayStatus"
      "homeServerLatency"
      "homeServerStatus"
      "isOffline"
    )
    for prop in "${REQUIRED_PROPS_PING[@]}"; do
      if grep -qE "(property[[:space:]]+[A-Za-z0-9_<>]+[[:space:]]+$prop|readonly[[:space:]]+property[[:space:]]+[A-Za-z0-9_<>]+[[:space:]]+$prop)" "$PING_QML"; then
        pass "PingService.qml exposes ping property: $prop"
      else
        fail "PingService.qml missing required ping property: $prop"
      fi
    done
  fi

  # Test live API if server is currently listening
  if ! [[ "$QUICK_MODE" -eq 1 ]]; then
    if curl -s --max-time 1 "http://127.0.0.1:8765/api/status" >/dev/null 2>&1; then
      LIVE_JSON="$(curl -s --max-time 1 "http://127.0.0.1:8765/api/status")"
      if echo "$LIVE_JSON" | jq -e '.targets' >/dev/null 2>&1; then
        pass "Live daemon http://127.0.0.1:8765/api/status returns valid JSON with .targets"
      else
        finding "Live daemon on :8765 did not return .targets array yet (container may need rebuild)"
      fi
    else
      info "Local ping server not currently listening on :8765 (skipping live HTTP probe)"
    fi
  fi
fi

# ===========================================================================
# Section 5: ResourceUsage.qml (MEMDSK-01, D-15)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: ResourceUsage.qml Verification ---"
  RES_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml"
  
  if [[ ! -f "$RES_QML" ]]; then
    fail "ResourceUsage.qml does not exist at $RES_QML"
  else
    pass "ResourceUsage.qml exists in restow overlay"
    
    # Pragma check
    if grep -q "pragma Singleton" "$RES_QML"; then
      pass "ResourceUsage.qml declares pragma Singleton"
    else
      fail "ResourceUsage.qml missing pragma Singleton"
    fi

    # D-15: memoryAvailable, memoryBuffers, memoryCached
    REQUIRED_PROPS_MEM=(
      "memoryAvailable"
      "memoryBuffers"
      "memoryCached"
    )
    for prop in "${REQUIRED_PROPS_MEM[@]}"; do
      if grep -qE "(property[[:space:]]+[A-Za-z0-9_<>]+[[:space:]]+$prop|readonly[[:space:]]+property[[:space:]]+[A-Za-z0-9_<>]+[[:space:]]+$prop)" "$RES_QML"; then
        pass "ResourceUsage.qml exposes extended memory property: $prop"
      else
        fail "ResourceUsage.qml missing extended memory property: $prop"
      fi
    done
  fi
fi

# ===========================================================================
# Section 6: Stow Integrity & Symlink Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 6 ]]; then
  info "--- Section 6: Stow Integrity & Symlink Verification ---"
  
  TARGET_SERVICES_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/services"
  CHECK_LINKS=(
    "HardwareTelemetry.qml"
    "StorageUsage.qml"
    "PingService.qml"
    "ResourceUsage.qml"
  )
  
  for link_name in "${CHECK_LINKS[@]}"; do
    link_path="$TARGET_SERVICES_DIR/$link_name"
    if [[ -L "$link_path" ]]; then
      resolved="$(readlink -f "$link_path" 2>/dev/null || true)"
      if [[ -f "$resolved" ]]; then
        pass "Symlink $link_name exists and resolves to $resolved"
      else
        fail "Symlink $link_name points to broken target: $resolved"
      fi
    elif [[ -f "$link_path" ]]; then
      finding "$link_path is a regular file, not a symlink"
    else
      fail "$link_path does not exist in target user config"
    fi
  done
fi

info "=== Assertion Summary ==="
info "Failures: $FAIL, Findings: $FINDINGS"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
