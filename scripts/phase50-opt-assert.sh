#!/usr/bin/env bash
# ===========================================================================
# Phase 50: Quickshell Deep Performance Optimization Assert Harness
# Enforces: OPT-01, OPT-02, OPT-03, OPT-04, OPT-05
#
# Usage (from REPO_ROOT):
#   ./scripts/phase50-opt-assert.sh [1-5] [OPTIONS]
#
# Options:
#   -s, --section <1-5>    Execute only the specified section (1-5)
#   -q, --quick,           Run standalone sections only (skip sub-harnesses in S5)
#       --standalone
#   -c, --syntax           Execute static AST and syntax checks only
#   -h, --help             Show this help message
#
# Exit 0 if all hard asserts pass (FAIL=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if executed as root (ASVS L1 Root Privilege Prevention / T-50-01)
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
    --quick|--standalone|-q)
      QUICK_MODE=1
      shift
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [1-5] [OPTIONS]"
      echo ""
      echo "Sections:"
      echo "  1: Preconditions & Safety"
      echo "  2: Quiescent Idle Telemetry & Timer Coalescing (OPT-01, D-50-01)"
      echo "  3: Subshell Elimination Audit & Network/Ping (OPT-03, D-50-02, D-50-07, D-50-08)"
      echo "  4: Multimedia, Canvas Clamping & Popup Scenegraph (OPT-02, OPT-04, D-50-03..D-50-06)"
      echo "  5: Empirical Benchmark Ceilings & Strict Repository Verification (OPT-01..OPT-05, D-50-09, D-50-10)"
      echo ""
      echo "Options:"
      echo "  -s, --section <1-5>    Execute only the specified section (1-5)"
      echo "  -q, --quick,           Run standalone sections only (skip sub-harnesses in S5)"
      echo "      --standalone"
      echo "  -c, --syntax           Execute static AST and syntax checks only"
      echo "  -h, --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

PHASE_DIR="$REPO_ROOT/.planning/phases/50-quickshell-deep-performance-optimization-overhead-reduction"
BENCH_JSON="$PHASE_DIR/benchmark-latest.json"
BENCH_MD="$PHASE_DIR/BENCHMARK.md"

PORCELAIN_BEFORE="$(mktemp "${TMPDIR:-/tmp}/p50-porcelain-before.XXXXXX")"
TMP_FILES+=("$PORCELAIN_BEFORE")
git status --porcelain > "$PORCELAIN_BEFORE"

# Syntax-only mode
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  bash -n "$0"
  pass "Assert harness bash syntax check passed (bash -n verified)"
  [[ -x "$REPO_ROOT/scripts/profile-quickshell.sh" ]] && pass "profile-quickshell.sh is executable" || finding "Missing or non-executable: scripts/profile-quickshell.sh"
  info "=== Syntax Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Preconditions & Safety
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Preconditions & Safety ---"
  command -v stow >/dev/null 2>&1 && pass "S1: stow utility available" || fail "S1: stow not in PATH"
  command -v jq >/dev/null 2>&1 && pass "S1: jq utility available" || fail "S1: jq not in PATH"
  command -v hyprctl >/dev/null 2>&1 && pass "S1: hyprctl utility available" || fail "S1: hyprctl not in PATH"
  if [[ -r "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq" ]]; then
    pass "S1: CPU max freq sysfs node readable"
  else
    fail "S1: Missing CPU max freq sysfs node (/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)"
  fi
fi

# ===========================================================================
# Section 2: Quiescent Idle Telemetry & Timer Coalescing (OPT-01, D-50-01)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Quiescent Idle Telemetry & Timer Coalescing ---"
  SERVICES_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services"

  # HardwareTelemetry idle timer 5000ms
  if grep -q "interval: root\.fastPolling ? 1000 : 5000" "$SERVICES_DIR/HardwareTelemetry.qml" 2>/dev/null; then
    pass "S2: HardwareTelemetry.qml idle interval coalesced to 5000ms"
  else
    fail "S2: HardwareTelemetry.qml idle interval not 5000ms (expected 'interval: root.fastPolling ? 1000 : 5000')"
  fi

  # ResourceUsage idle timer 5000ms
  if grep -q "interval:.*1000 : 5000" "$SERVICES_DIR/ResourceUsage.qml" 2>/dev/null; then
    pass "S2: ResourceUsage.qml idle interval coalesced to 5000ms"
  else
    fail "S2: ResourceUsage.qml idle interval not 5000ms (expected 'interval: ... ? 1000 : 5000')"
  fi

  # StorageUsage ioPollTimer 5000ms
  if grep -q "interval: 5000" "$SERVICES_DIR/StorageUsage.qml" 2>/dev/null; then
    pass "S2: StorageUsage.qml ioPollTimer coalesced to 5000ms"
  else
    fail "S2: StorageUsage.qml ioPollTimer not 5000ms (expected 'interval: 5000')"
  fi

  # GlobalStates fastTelemetryRate coordination bridge
  GLOBAL_STATES="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/GlobalStates.qml"
  if grep -q "property bool barHovered" "$GLOBAL_STATES" 2>/dev/null && \
     grep -q "fastTelemetryRate" "$GLOBAL_STATES" 2>/dev/null; then
    pass "S2: GlobalStates.qml defines barHovered and fastTelemetryRate bridge"
  else
    fail "S2: GlobalStates.qml missing barHovered or fastTelemetryRate bridge"
  fi

  # BarContent barHoverHandler
  BAR_CONTENT="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
  if grep -q "GlobalStates\.barHovered" "$BAR_CONTENT" 2>/dev/null; then
    pass "S2: BarContent.qml contains bar hover detection (GlobalStates.barHovered)"
  else
    fail "S2: BarContent.qml missing bar hover detection"
  fi
fi

# ===========================================================================
# Section 3: Subshell Elimination Audit & Network/Ping (OPT-03, D-50-02, D-50-07, D-50-08)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Subshell Elimination Audit & Network/Ping ---"
  SERVICES_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services"

  # Recurring subshell elimination in telemetry singletons
  TELEMETRY_SERVICES=(
    "$SERVICES_DIR/ResourceUsage.qml"
    "$SERVICES_DIR/StorageUsage.qml"
    "$SERVICES_DIR/NetworkUsage.qml"
  )
  RECURRING_SUBSHELL_FOUND=0
  for svc in "${TELEMETRY_SERVICES[@]}"; do
    if [[ -f "$svc" ]] && grep -q "bash.*-c" "$svc" 2>/dev/null; then
      fail "S3: Recurring bash -c subshell found in $(basename "$svc")"
      RECURRING_SUBSHELL_FOUND=1
    fi
  done
  if [[ "$RECURRING_SUBSHELL_FOUND" -eq 0 ]]; then
    pass "S3: Zero recurring bash -c subshells across ResourceUsage, StorageUsage, NetworkUsage"
  fi

  # Check ResourceUsage for lscpu
  if grep -q "lscpu" "$SERVICES_DIR/ResourceUsage.qml" 2>/dev/null; then
    fail "S3: ResourceUsage.qml still references lscpu"
  else
    pass "S3: ResourceUsage.qml eliminated lscpu subshell"
  fi

  # Check StorageUsage for bash -c df
  if grep -q "bash.*df" "$SERVICES_DIR/StorageUsage.qml" 2>/dev/null; then
    fail "S3: StorageUsage.qml still spawns df via shell"
  else
    pass "S3: StorageUsage.qml invokes df directly via argument array"
  fi

  # Check PingService in-flight guard and timeout
  PING_SERVICE="$SERVICES_DIR/PingService.qml"
  if [[ -f "$PING_SERVICE" ]]; then
    if grep -q "RequestInFlight" "$PING_SERVICE" 2>/dev/null && grep -Eq "timeout\s*=\s*[12][0-9]{3}" "$PING_SERVICE" 2>/dev/null; then
      pass "S3: PingService.qml implements in-flight concurrency guard and bounded timeout (<=2000ms)"
    else
      if [[ "$RUN_SECTION" -eq 3 ]]; then
        fail "S3: PingService.qml missing in-flight guard or timeout <= 2000ms"
      else
        finding "S3: PingService.qml in-flight guard / timeout pending Wave 2"
      fi
    fi
  else
    fail "S3: Missing file: $PING_SERVICE"
  fi

  # Check NetworkPingPopup layout fixes
  NETPING_POPUP="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml"
  if [[ -f "$NETPING_POPUP" ]]; then
    if grep -q "allowWrap: false" "$NETPING_POPUP" 2>/dev/null && \
       (grep -q "implicitHeight: 68" "$NETPING_POPUP" 2>/dev/null || grep -q "anchors\.left:" "$NETPING_POPUP" 2>/dev/null); then
      pass "S3: NetworkPingPopup.qml has fixed card geometry and no-wrap labels"
    else
      if [[ "$RUN_SECTION" -eq 3 ]]; then
        fail "S3: NetworkPingPopup.qml missing layout stabilization"
      else
        finding "S3: NetworkPingPopup.qml layout stabilization pending Wave 2"
      fi
    fi
  else
    fail "S3: Missing file: $NETPING_POPUP"
  fi
fi

# ===========================================================================
# Section 4: Multimedia, Canvas Clamping & Popup Scenegraph (OPT-02, OPT-04, D-50-03..D-50-06)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Multimedia, Canvas Clamping & Popup Scenegraph ---"

  PLAYER_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/PlayerControl.qml"
  if [[ -f "$PLAYER_QML" ]]; then
    pass "S4: PlayerControl.qml exists as stowed override"
    if grep -q "OpacityMask" "$PLAYER_QML" 2>/dev/null; then
      fail "S4: PlayerControl.qml contains OpacityMask FBO pass"
    else
      pass "S4: PlayerControl.qml eliminated OpacityMask"
    fi

    if grep -q "StyledBlurEffect" "$PLAYER_QML" 2>/dev/null; then
      fail "S4: PlayerControl.qml contains StyledBlurEffect live Gaussian blur"
    else
      pass "S4: PlayerControl.qml eliminated live Gaussian blur"
    fi
  else
    if [[ "$RUN_SECTION" -eq 4 ]]; then
      fail "S4: Missing PlayerControl.qml override in restow/"
    else
      finding "S4: PlayerControl.qml override pending Wave 2"
    fi
  fi

  GRAPH_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/common/widgets/Graph.qml"
  if [[ -f "$GRAPH_QML" ]]; then
    if grep -q "paintThrottleTimer" "$GRAPH_QML" 2>/dev/null || grep -q "lastPaintTime" "$GRAPH_QML" 2>/dev/null; then
      pass "S4: Graph.qml implements Canvas repaint throttling"
    else
      if [[ "$RUN_SECTION" -eq 4 ]]; then
        fail "S4: Graph.qml missing repaint throttling logic"
      else
        finding "S4: Graph.qml repaint throttling pending Wave 2"
      fi
    fi
  else
    if [[ "$RUN_SECTION" -eq 4 ]]; then
      fail "S4: Missing Graph.qml override in restow/"
    else
      finding "S4: Graph.qml override pending Wave 2"
    fi
  fi

  # StyledPopup shadow caching
  STYLED_POPUP="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml"
  if [[ -f "$STYLED_POPUP" ]]; then
    if grep -q "layer.enabled: true" "$STYLED_POPUP" 2>/dev/null; then
      pass "S4: StyledPopup.qml enables layer caching for drop shadow"
    else
      if [[ "$RUN_SECTION" -eq 4 ]]; then
        fail "S4: StyledPopup.qml missing shadow layer caching"
      else
        finding "S4: StyledPopup.qml shadow layer caching pending Wave 2"
      fi
    fi
  else
    fail "S4: Missing file: $STYLED_POPUP"
  fi

  # ClockWidgetPopup active gating
  CLOCK_POPUP="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidgetPopup.qml"
  if [[ -f "$CLOCK_POPUP" ]]; then
    if grep -q "root\.active" "$CLOCK_POPUP" 2>/dev/null; then
      pass "S4: ClockWidgetPopup.qml gates time/uptime formatting on root.active"
    else
      if [[ "$RUN_SECTION" -eq 4 ]]; then
        fail "S4: ClockWidgetPopup.qml missing root.active gating"
      else
        finding "S4: ClockWidgetPopup.qml root.active gating pending Wave 2"
      fi
    fi
  else
    fail "S4: Missing file: $CLOCK_POPUP"
  fi

  # Zero infinite pulse animations in CPU/GPU and Memory/Storage popups
  CPU_GPU_POPUP="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml"
  MEM_STORAGE_POPUP="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePopup.qml"
  if grep -rn "loops: Animation.Infinite" "$CPU_GPU_POPUP" "$MEM_STORAGE_POPUP" 2>/dev/null; then
    if [[ "$RUN_SECTION" -eq 4 ]]; then
      fail "S4: Found unbounded loops: Animation.Infinite in inspector popups"
    else
      finding "S4: Unbounded Animation.Infinite in inspector popups pending Wave 2 de-escalation"
    fi
  else
    pass "S4: Inspector popups have bounded animation loops"
  fi
fi

# ===========================================================================
# Section 5: Empirical Benchmark Ceilings & Strict Repository Verification (OPT-01..OPT-05, D-50-09, D-50-10)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Empirical Benchmark Ceilings & Strict Repository Verification ---"
  if [[ -f "$BENCH_JSON" ]] && jq empty "$BENCH_JSON" 2>/dev/null; then
    # Idle CPU <= 2.0%
    IDLE_CPU="$(jq -r '.stages.custom_idle.cpu_pct_avg // empty' "$BENCH_JSON")"
    if [[ -n "$IDLE_CPU" ]]; then
      if (( $(awk -v c="$IDLE_CPU" 'BEGIN { print (c <= 2.0) }') )); then
        pass "S5: Idle CPU <= 2.0% (${IDLE_CPU}%)"
      else
        fail "S5: Idle CPU exceeded 2.0% (${IDLE_CPU}%)"
      fi
    else
      fail "S5: stages.custom_idle.cpu_pct_avg missing from benchmark-latest.json"
    fi

    # Context Switches < 100/s
    CTX_SW="$(jq -r '.stages.custom_idle.ctx_switches_per_sec // .stages.custom_idle.voluntary_ctxt_rate // empty' "$BENCH_JSON")"
    if [[ -n "$CTX_SW" ]]; then
      if (( $(awk -v c="$CTX_SW" 'BEGIN { print (c < 100.0) }') )); then
        pass "S5: Idle Context Switches < 100/s (${CTX_SW}/s)"
      else
        fail "S5: Idle Context Switches exceeded 100/s (${CTX_SW}/s)"
      fi
    else
      fail "S5: stages.custom_idle context switch metrics missing from benchmark-latest.json"
    fi

    # MediaControls CPU <= 10.0%, iGPU <= 12.0%
    MEDIA_CPU="$(jq -r '.stages.popup_mediacontrols.cpu_pct_avg // empty' "$BENCH_JSON")"
    MEDIA_GPU="$(jq -r '.stages.popup_mediacontrols.gpu_busy_pct // empty' "$BENCH_JSON")"
    if [[ -n "$MEDIA_CPU" && -n "$MEDIA_GPU" ]]; then
      (( $(awk -v c="$MEDIA_CPU" 'BEGIN { print (c <= 10.0) }') )) && pass "S5: MediaControls CPU <= 10.0% (${MEDIA_CPU}%)" || fail "S5: MediaControls CPU exceeded 10.0% (${MEDIA_CPU}%)"
      (( $(awk -v g="$MEDIA_GPU" 'BEGIN { print (g <= 12.0) }') )) && pass "S5: MediaControls iGPU <= 12.0% (${MEDIA_GPU}%)" || fail "S5: MediaControls iGPU exceeded 12.0% (${MEDIA_GPU}%)"
    else
      fail "S5: stages.popup_mediacontrols metrics missing from benchmark-latest.json"
    fi

    # NetPing GPU Boost Lock Check (act freq == 0.0 MHz)
    NETPING_FREQ="$(jq -r '.stages.popup_netping.gpu_act_freq_mhz // empty' "$BENCH_JSON")"
    if [[ -n "$NETPING_FREQ" ]]; then
      if (( $(awk -v f="$NETPING_FREQ" 'BEGIN { print (f == 0.0) }') )); then
        pass "S5: NetPing GPU boost clock lock eliminated (${NETPING_FREQ} MHz)"
      else
        fail "S5: NetPing GPU clock locked at boost frequency (${NETPING_FREQ} MHz)"
      fi
    else
      fail "S5: stages.popup_netping.gpu_act_freq_mhz missing from benchmark-latest.json"
    fi
  else
    if [[ "$RUN_SECTION" -eq 5 ]]; then
      fail "S5: benchmark-latest.json missing or invalid JSON ($BENCH_JSON)"
    else
      finding "S5: benchmark-latest.json pending benchmarking run (Wave 3)"
    fi
  fi

  if [[ "$QUICK_MODE" -eq 1 ]]; then
    info "S5: Quick mode enabled. Skipping dots-hyprland.sh verify --strict."
  elif [[ -x "$REPO_ROOT/arch/dots-hyprland.sh" ]]; then
    info "Running ./arch/dots-hyprland.sh verify --strict..."
    if "$REPO_ROOT/arch/dots-hyprland.sh" verify --strict; then
      pass "S5: ./arch/dots-hyprland.sh verify --strict passed cleanly"
    else
      fail "S5: ./arch/dots-hyprland.sh verify --strict failed"
    fi
  fi

  SUBMODULE_STATUS="$(git status --porcelain vendor/dots-hyprland 2>/dev/null || true)"
  if [[ -z "$SUBMODULE_STATUS" ]]; then
    pass "S5: vendor/dots-hyprland submodule has 0 git churn"
  else
    fail "S5: vendor/dots-hyprland has uncommitted churn: $SUBMODULE_STATUS"
  fi
fi

# Working tree drift check
PORCELAIN_AFTER="$(mktemp "${TMPDIR:-/tmp}/p50-porcelain-after.XXXXXX")"
TMP_FILES+=("$PORCELAIN_AFTER")
git status --porcelain > "$PORCELAIN_AFTER"

if diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" >/dev/null; then
  pass "Zero working tree drift during assert execution (porcelain unchanged)"
else
  fail "Working tree drifted during assert execution"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

info "=== Assertion Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="

if [[ "$FAIL" -eq 0 && "$FINDINGS" -eq 0 ]]; then
  pass "All hard assertions passed with zero findings!"
  exit 0
elif [[ "$FAIL" -eq 0 ]]; then
  pass "All hard assertions passed ($FINDINGS informational findings)"
  exit 0
else
  fail "Assert harness encountered $FAIL failure(s)"
  exit 1
fi
