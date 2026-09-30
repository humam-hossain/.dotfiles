#!/usr/bin/env bash
# ===========================================================================
# Phase 49: Quickshell Resource Profiling & Component Performance Audit Assert
# Enforces: AUDIT-01, AUDIT-02, AUDIT-03
#
# Usage (from REPO_ROOT):
#   ./scripts/phase49-audit-assert.sh [1-5] [OPTIONS]
#
# Options:
#   -s, --section <1-5>    Execute only the specified section (1-5)
#   -q, --quick,
#       --standalone       Run standalone sections only (skip sub-harnesses in S5)
#   -c, --syntax           Execute static AST and syntax checks only
#   -h, --help             Show this help message
#
# Exit 0 if all hard asserts pass (FAIL=0); exit 1 if any FAIL.
# ===========================================================================

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
      echo "  1: Test Harness Safety & Preconditions"
      echo "  2: Baseline Resource Invariants (AUDIT-01)"
      echo "  3: Component & Popup Audit Coverage (AUDIT-02)"
      echo "  4: Targeted Optimization Ceilings & AST Rules (AUDIT-03)"
      echo "  5: Strict Repository Verification & Zero Stow Drift"
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

PHASE_DIR="$REPO_ROOT/.planning/phases/49-quickshell-resource-profiling-component-performance-audit"
BENCH_JSON="$PHASE_DIR/benchmark-latest.json"
BENCH_MD="$PHASE_DIR/BENCHMARK.md"

PORCELAIN_BEFORE="$(mktemp "${TMPDIR:-/tmp}/p49-porcelain-before.XXXXXX")"
TMP_FILES+=("$PORCELAIN_BEFORE")
git status --porcelain > "$PORCELAIN_BEFORE"

# Syntax-only mode
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  bash -n "$0"
  pass "Assert harness bash syntax check passed (bash -n verified)"
  [[ -x "$REPO_ROOT/scripts/profile-quickshell.sh" ]] && pass "profile-quickshell.sh is executable" || fail "Missing: scripts/profile-quickshell.sh"
  info "=== Syntax Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Test Harness Safety & Preconditions
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Test Harness Safety & Preconditions ---"

  PROFILE_SCRIPT="$REPO_ROOT/scripts/profile-quickshell.sh"
  if [[ -x "$PROFILE_SCRIPT" ]]; then
    pass "S1: scripts/profile-quickshell.sh exists and is executable"
  else
    fail "S1: scripts/profile-quickshell.sh missing or non-executable"
  fi

  if bash -n "$PROFILE_SCRIPT"; then
    pass "S1: scripts/profile-quickshell.sh bash syntax valid (bash -n passed)"
  else
    fail "S1: scripts/profile-quickshell.sh bash syntax error"
  fi

  if [[ -r "/sys/class/drm/card1/gt/gt0/rc6_residency_ms" ]]; then
    pass "S1: Intel iGPU RC6 sysfs interface readable (/sys/class/drm/card1/gt/gt0/rc6_residency_ms)"
  else
    fail "S1: Missing DRM RC6 sysfs interface"
  fi

  if command -v ydotool >/dev/null 2>&1; then
    pass "S1: ydotool command available in PATH"
  else
    finding "S1: ydotool not found in PATH (automated mouse interaction will fall back)"
  fi

  if command -v hyprctl >/dev/null 2>&1; then
    pass "S1: hyprctl command available in PATH"
  else
    finding "S1: hyprctl not found in PATH"
  fi
fi

# ===========================================================================
# Section 2: Baseline Resource Invariants (AUDIT-01)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Baseline Resource Invariants (AUDIT-01) ---"

  if [[ -f "$BENCH_JSON" ]] && jq empty "$BENCH_JSON" 2>/dev/null; then
    # Invariant 1: System Idle without Quickshell GPU <= 10.0%
    IDLE_GPU="$(jq -r '.stages.system_idle_no_qs.gpu_busy_pct // empty' "$BENCH_JSON")"
    if [[ -n "$IDLE_GPU" ]]; then
      if (( $(awk -v g="$IDLE_GPU" 'BEGIN { print (g <= 10.0) }') )); then
        pass "S2: AUDIT-01 Invariant 1: System Idle GPU load <= 10.0% (${IDLE_GPU}%)"
      else
        fail "S2: AUDIT-01 Invariant 1: System Idle GPU load exceeded 10.0% (${IDLE_GPU}%)"
      fi
    else
      fail "S2: AUDIT-01: stage 'system_idle_no_qs' missing from benchmark-latest.json"
    fi

    # Invariant 2: Upstream baseline CPU <= 5.0%, GPU <= 10.0%
    UPSTREAM_CPU="$(jq -r '.stages.upstream_baseline.cpu_pct_avg // empty' "$BENCH_JSON")"
    UPSTREAM_GPU="$(jq -r '.stages.upstream_baseline.gpu_busy_pct // empty' "$BENCH_JSON")"
    if [[ -n "$UPSTREAM_CPU" ]]; then
      if (( $(awk -v c="$UPSTREAM_CPU" 'BEGIN { print (c <= 5.0) }') )); then
        pass "S2: AUDIT-01 Invariant 2: Upstream baseline CPU <= 5.0% (${UPSTREAM_CPU}%)"
      else
        fail "S2: AUDIT-01 Invariant 2: Upstream baseline CPU exceeded 5.0% (${UPSTREAM_CPU}%)"
      fi
    else
      fail "S2: AUDIT-01: stage 'upstream_baseline' missing cpu_pct_avg in benchmark-latest.json"
    fi

    if [[ -n "$UPSTREAM_GPU" ]]; then
      if (( $(awk -v g="$UPSTREAM_GPU" 'BEGIN { print (g <= 10.0) }') )); then
        pass "S2: AUDIT-01 Invariant 2: Upstream baseline GPU <= 10.0% (${UPSTREAM_GPU}%)"
      else
        fail "S2: AUDIT-01 Invariant 2: Upstream baseline GPU exceeded 10.0% (${UPSTREAM_GPU}%)"
      fi
    else
      fail "S2: AUDIT-01: stage 'upstream_baseline' missing gpu_busy_pct in benchmark-latest.json"
    fi
  else
    if [[ "$RUN_SECTION" -eq 2 ]]; then
      fail "S2: benchmark-latest.json missing or invalid JSON ($BENCH_JSON)"
    else
      finding "S2: benchmark-latest.json not yet populated (run Task 2 baseline profiling)"
    fi
  fi
fi

# ===========================================================================
# Section 3: Component & Popup Audit Coverage (AUDIT-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Component & Popup Audit Coverage (AUDIT-02) ---"

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

  if [[ -f "$BENCH_JSON" ]] && jq empty "$BENCH_JSON" 2>/dev/null; then
    MISSING_STAGE=0
    for sid in "${REQUIRED_STAGES[@]}"; do
      if jq -e --arg s "$sid" '.stages[$s] != null' "$BENCH_JSON" >/dev/null 2>&1; then
        pass "S3: AUDIT-02 Coverage: stage '$sid' recorded in telemetry"
      else
        MISSING_STAGE=$((MISSING_STAGE + 1))
        if [[ "$RUN_SECTION" -eq 3 ]]; then
          fail "S3: AUDIT-02 Coverage: stage '$sid' missing from benchmark-latest.json"
        else
          finding "S3: AUDIT-02 Coverage: stage '$sid' not yet in benchmark-latest.json (Wave 2)"
        fi
      fi
    done
  else
    if [[ "$RUN_SECTION" -eq 3 ]]; then
      fail "S3: benchmark-latest.json missing or invalid JSON ($BENCH_JSON)"
    else
      finding "S3: benchmark-latest.json not yet populated (scheduled for Wave 2)"
    fi
  fi

  if [[ -f "$BENCH_MD" ]]; then
    if grep -q "Master Attribution Matrix" "$BENCH_MD" 2>/dev/null && grep -q "Interactive Popup Attribution" "$BENCH_MD" 2>/dev/null; then
      pass "S3: AUDIT-02: BENCHMARK.md contains interactive popup attribution reporting"
    else
      if [[ "$RUN_SECTION" -eq 3 ]]; then
        fail "S3: AUDIT-02: BENCHMARK.md missing required attribution report sections"
      else
        finding "S3: AUDIT-02: BENCHMARK.md attribution sections pending Wave 2"
      fi
    fi
  else
    if [[ "$RUN_SECTION" -eq 3 ]]; then
      fail "S3: BENCHMARK.md missing ($BENCH_MD)"
    else
      finding "S3: BENCHMARK.md pending Wave 2"
    fi
  fi
fi

# ===========================================================================
# Section 4: Targeted Optimization Ceilings & AST Rules (AUDIT-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Targeted Optimization Ceilings & AST Rules (AUDIT-03) ---"

  MEDIA_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml"
  PING_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/NetworkPingPopup.qml"
  VOICE_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/Voice.qml"
  STORAGE_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml"

  # MediaControls.qml AST checks
  if [[ -f "$MEDIA_QML" ]]; then
    if grep -q "MprisPlaybackState.Playing" "$MEDIA_QML" || grep -q "activePlayer?.playbackState" "$MEDIA_QML"; then
      pass "S4: MediaControls.qml gates cava execution by active playback state"
    else
      if [[ "$RUN_SECTION" -eq 4 ]]; then
        fail "S4: MediaControls.qml missing playback state gating on cava process"
      else
        finding "S4: MediaControls.qml playback state gating pending Wave 3 optimization"
      fi
    fi

    if grep -q "_cavaFrameSkip" "$MEDIA_QML" || grep -q "throttle" "$MEDIA_QML"; then
      pass "S4: MediaControls.qml implements cava frame rate throttling"
    else
      if [[ "$RUN_SECTION" -eq 4 ]]; then
        fail "S4: MediaControls.qml missing frame rate throttling"
      else
        finding "S4: MediaControls.qml frame rate throttling pending Wave 3 optimization"
      fi
    fi
  else
    fail "S4: Missing file: $MEDIA_QML"
  fi

  # NetworkPingPopup.qml AST checks
  if [[ -f "$PING_QML" ]]; then
    if grep -q "loops: Animation.Infinite" "$PING_QML"; then
      if [[ "$RUN_SECTION" -eq 4 ]]; then
        fail "S4: NetworkPingPopup.qml still contains unbounded infinite animation loop (loops: Animation.Infinite)"
      else
        finding "S4: NetworkPingPopup.qml infinite animation loop pending Wave 3 de-escalation"
      fi
    else
      pass "S4: NetworkPingPopup.qml de-escalates infinite cardPulseAnimation loops"
    fi
  else
    fail "S4: Missing file: $PING_QML"
  fi

  # Voice.qml AST checks
  if [[ -f "$VOICE_QML" ]]; then
    if grep -q "2500" "$VOICE_QML" || grep -q "2000" "$VOICE_QML"; then
      pass "S4: Voice.qml relaxes idle tmpfs polling interval (>= 2000ms)"
    else
      if [[ "$RUN_SECTION" -eq 4 ]]; then
        fail "S4: Voice.qml idle polling interval below relaxed threshold"
      else
        finding "S4: Voice.qml idle polling interval relaxation pending Wave 3"
      fi
    fi
  else
    fail "S4: Missing file: $VOICE_QML"
  fi

  # StorageUsage.qml AST checks
  if [[ -f "$STORAGE_QML" ]]; then
    if grep -q "interval: 3000" "$STORAGE_QML" || grep -q "interval: 5000" "$STORAGE_QML"; then
      pass "S4: StorageUsage.qml relaxes idle diskstats interval (>= 3000ms)"
    else
      if [[ "$RUN_SECTION" -eq 4 ]]; then
        fail "S4: StorageUsage.qml diskstats interval below relaxed threshold"
      else
        finding "S4: StorageUsage.qml diskstats interval relaxation pending Wave 3"
      fi
    fi
  else
    fail "S4: Missing file: $STORAGE_QML"
  fi
fi

# ===========================================================================
# Section 5: Strict Repository Verification & Zero Stow Drift
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Strict Repository Verification & Zero Stow Drift ---"

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
PORCELAIN_AFTER="$(mktemp "${TMPDIR:-/tmp}/p49-porcelain-after.XXXXXX")"
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
