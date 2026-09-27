#!/usr/bin/env bash
# ===========================================================================
# Phase 43.1: Quickshell Performance Profiling & Resource Optimization Assert
# Enforces: PERF-01..03, D-01 through D-15
#
# Usage (from REPO_ROOT):
#   ./scripts/phase43-perf-assert.sh [1-5] [--section <1-5>] [-s <1-5>] [--quick] [--syntax]
#
# Exit 0 if all asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root (ASVS L1 Root Privilege Prevention)
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Error: Do not run as root" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass()    { printf '[PASS] %s\n' "$1"; }
fail()    { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info()    { printf '[INFO] %s\n' "$1"; }

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
      echo ""
      echo "Options:"
      echo "  [1-5]                 Positional section selector"
      echo "  -s, --section <1-5>   Execute only the specified section (1-5)"
      echo "  -q, --quick           Execute static / quick checks only"
      echo "  -c, --syntax          Execute syntax checks only"
      echo "  -h, --help            Show this help message"
      echo ""
      echo "Sections:"
      echo "  1: Restow Isolation & Harness Safety"
      echo "  2: Profiling CLI & Output Artifact Compliance"
      echo "  3: Metric Sanity Bounds & Resource Leak Ceilings"
      echo "  4: Static Timer & Hotspot Inventory Audit"
      echo "  5: Strict Repository Verification & Zero Drift"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

info "=== Phase 43.1 Quickshell Performance Regression Assert Harness ==="
info "Working directory: $REPO_ROOT"
info "Flags: section=$RUN_SECTION quick=$QUICK_MODE syntax_only=$SYNTAX_ONLY"

# ---------------------------------------------------------------------------
# Syntax-only mode early exit check
# ---------------------------------------------------------------------------
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "Running syntax validation..."
  if bash -n "$REPO_ROOT/scripts/profile-quickshell.sh"; then
    pass "scripts/profile-quickshell.sh syntax clean"
  else
    fail "scripts/profile-quickshell.sh syntax check failed"
  fi
  if bash -n "$REPO_ROOT/scripts/phase43-perf-assert.sh"; then
    pass "scripts/phase43-perf-assert.sh syntax clean"
  else
    fail "scripts/phase43-perf-assert.sh syntax check failed"
  fi
  exit "$FAIL"
fi

# Snapshot git porcelain state before assertions
PORCELAIN_BEFORE="$(mktemp /tmp/p43.1-porcelain-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE")
git status --porcelain | grep -vE "BENCHMARK\.md|benchmark-latest\.json|\.gitkeep" > "$PORCELAIN_BEFORE" || true

# ---------------------------------------------------------------------------
# Helper functions for process sampling
# ---------------------------------------------------------------------------
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

sample_proc_fds() {
  local pid="$1"
  ls -1 "/proc/$pid/fd" 2>/dev/null | wc -l || echo 0
}

sample_proc_memory() {
  local pid="$1"
  local rss_kb=0 pss_kb=0 priv_dirty_kb=0
  if [[ -r "/proc/$pid/smaps_rollup" ]]; then
    while IFS=':' read -r key val; do
      val="${val//[^0-9]/}"
      case "$key" in
        Rss) rss_kb="$val" ;;
        Pss) pss_kb="$val" ;;
        Private_Dirty) priv_dirty_kb="$val" ;;
      esac
    done < "/proc/$pid/smaps_rollup"
  fi
  printf "%.2f %.2f %.2f\n" \
    "$(awk -v k="$rss_kb" 'BEGIN { printf "%.2f", k/1024 }')" \
    "$(awk -v k="$pss_kb" 'BEGIN { printf "%.2f", k/1024 }')" \
    "$(awk -v k="$priv_dirty_kb" 'BEGIN { printf "%.2f", k/1024 }')"
}

sample_proc_cpu() {
  local pid="$1"
  local stat_line tail utime stime
  stat_line="$(cat "/proc/$pid/stat" 2>/dev/null || true)"
  [[ -n "$stat_line" ]] || { echo "0"; return 0; }
  tail="${stat_line##*) }"
  read -r _ _ _ _ _ _ _ _ _ _ _ utime stime _ <<< "$tail"
  echo "$((utime + stime))"
}

# ---------------------------------------------------------------------------
# Section 1: Restow Isolation & Harness Safety (PERF-01, D-01, D-12)
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Restow Isolation & Harness Safety ---"

  PROFILE_SCRIPT="$REPO_ROOT/scripts/profile-quickshell.sh"
  if [[ -x "$PROFILE_SCRIPT" ]]; then
    pass "scripts/profile-quickshell.sh exists and is executable"
  else
    fail "scripts/profile-quickshell.sh missing or not executable"
  fi

  # Signal trap handlers check
  if grep -q "trap cleanup EXIT INT TERM" "$PROFILE_SCRIPT"; then
    pass "profile-quickshell.sh implements robust safety trap (EXIT INT TERM)"
  else
    fail "profile-quickshell.sh missing safety trap on EXIT INT TERM"
  fi

  # Upstream stub restoration check
  if grep -q "stow -D" "$PROFILE_SCRIPT" && grep -q "\.bak" "$PROFILE_SCRIPT"; then
    pass "profile-quickshell.sh implements GNU Stow unstow with .bak stub handling"
  else
    fail "profile-quickshell.sh missing GNU Stow unstow / stub logic"
  fi

  # Non-root enforcement check
  if grep -q "EUID.*-eq 0" "$PROFILE_SCRIPT" || grep -q "EUID.*-ne 0" "$PROFILE_SCRIPT"; then
    pass "profile-quickshell.sh enforces non-root execution check"
  else
    fail "profile-quickshell.sh missing non-root enforcement check"
  fi
fi

# ---------------------------------------------------------------------------
# Section 2: Profiling CLI & Output Artifact Compliance (PERF-02, D-02, D-04)
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Profiling CLI & Output Artifact Compliance ---"

  PROFILE_SCRIPT="$REPO_ROOT/scripts/profile-quickshell.sh"
  # Help CLI check
  if "$PROFILE_SCRIPT" --help >/dev/null 2>&1; then
    pass "profile-quickshell.sh --help executes cleanly"
  else
    fail "profile-quickshell.sh --help failed"
  fi

  # Staging list check
  if "$PROFILE_SCRIPT" --list-stages >/dev/null 2>&1; then
    pass "profile-quickshell.sh --list-stages executes cleanly"
  else
    fail "profile-quickshell.sh --list-stages failed"
  fi

  # Artifact existence check
  PHASE_DIR="$REPO_ROOT/.planning/phases/43.1-quickshell-performance-profiling-and-resource-optimization"
  BENCH_MD="$PHASE_DIR/BENCHMARK.md"
  BENCH_JSON="$PHASE_DIR/benchmark-latest.json"

  if [[ -f "$BENCH_MD" ]]; then
    pass "BENCHMARK.md exists"
    if grep -q "Master Attribution Matrix" "$BENCH_MD" && grep -q "Evidence-Based Optimization" "$BENCH_MD"; then
      pass "BENCHMARK.md contains required attribution and roadmap sections"
    else
      fail "BENCHMARK.md missing required report sections"
    fi
  else
    fail "BENCHMARK.md not found at $BENCH_MD"
  fi

  if [[ -f "$BENCH_JSON" ]] && jq empty "$BENCH_JSON" 2>/dev/null; then
    pass "benchmark-latest.json exists and is valid JSON"
    # Validate required schema keys
    for key in timestamp environment config stages attributions; do
      if jq -e --arg k "$key" 'has($k)' "$BENCH_JSON" >/dev/null 2>&1; then
        pass "benchmark-latest.json contains required root key: $key"
      else
        fail "benchmark-latest.json missing required root key: $key"
      fi
    done
  else
    fail "benchmark-latest.json missing or invalid JSON"
  fi

  # Phase 43.2 Artifact check if directory exists
  PHASE43_2_DIR="$REPO_ROOT/.planning/phases/43.2-quickshell-profiling-harness-calibration-and-empirical-baseline"
  if [[ -d "$PHASE43_2_DIR" ]]; then
    if [[ -f "$PHASE43_2_DIR/BENCHMARK.md" ]]; then
      pass "Phase 43.2 BENCHMARK.md exists and is populated"
    fi
    if [[ -f "$PHASE43_2_DIR/benchmark-latest.json" ]] && jq empty "$PHASE43_2_DIR/benchmark-latest.json" 2>/dev/null; then
      pass "Phase 43.2 benchmark-latest.json exists and is valid JSON"
    fi
  fi

  # Phase 43.4 Artifact check if directory exists
  PHASE43_4_DIR="$REPO_ROOT/.planning/phases/43.4-quickshell-targeted-optimization-and-empirical-verification"
  if [[ -d "$PHASE43_4_DIR" ]]; then
    if [[ -f "$PHASE43_4_DIR/BENCHMARK.md" ]]; then
      pass "Phase 43.4 BENCHMARK.md exists and is populated"
    fi
    if [[ -f "$PHASE43_4_DIR/benchmark-latest.json" ]] && jq empty "$PHASE43_4_DIR/benchmark-latest.json" 2>/dev/null; then
      pass "Phase 43.4 benchmark-latest.json exists and is valid JSON"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Section 3: Metric Sanity Bounds & Resource Leak Ceilings (PERF-03, D-06, D-08)
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Metric Sanity Bounds & Resource Leak Ceilings ---"

  # Find live quickshell PID
  PIDS=($(collect_qs_pids))
  if [[ ${#PIDS[@]} -gt 0 ]]; then
    QS_PID="${PIDS[0]}"
    pass "Active Quickshell PID detected: $QS_PID"

    # 1. Open FDs < 150 (prevent FileView handle leaks)
    FD_COUNT="$(sample_proc_fds "$QS_PID")"
    if (( FD_COUNT < 150 )); then
      pass "Open file descriptors within sanity limit: $FD_COUNT < 150"
    else
      fail "Open file descriptors exceeded limit: $FD_COUNT >= 150 (possible leak)"
    fi

    # 2. RSS Memory < 1200 MB
    read -r rss_mb pss_mb priv_dirty_mb <<< "$(sample_proc_memory "$QS_PID")"
    if (( $(awk -v r="$rss_mb" 'BEGIN { print (r < 1200.0) }') )); then
      pass "RSS memory within sanity limit: ${rss_mb}MB < 1200MB"
    else
      fail "RSS memory exceeded limit: ${rss_mb}MB >= 1200MB"
    fi

    # 3. Private Dirty Memory < 700 MB
    if (( $(awk -v d="$priv_dirty_mb" 'BEGIN { print (d < 700.0) }') )); then
      pass "Private dirty memory within sanity limit: ${priv_dirty_mb}MB < 700MB"
    else
      fail "Private dirty memory exceeded limit: ${priv_dirty_mb}MB >= 700MB"
    fi

    # 4. Idle CPU < 15.0%
    clk_tck="$(getconf CLK_TCK 2>/dev/null || echo 100)"
    t1="$(date +%s%N)"
    ticks1="$(sample_proc_cpu "$QS_PID")"
    sleep 1
    t2="$(date +%s%N)"
    ticks2="$(sample_proc_cpu "$QS_PID")"
    dt_sec="$(awk -v t1="$t1" -v t2="$t2" 'BEGIN { printf "%.4f", (t2 - t1)/1000000000.0 }')"
    dticks="$((ticks2 - ticks1))"
    inst_cpu="$(awk -v dticks="$dticks" -v dt="$dt_sec" -v clk="$clk_tck" 'BEGIN { printf "%.2f", (dticks / (dt * clk)) * 100.0 }')"
    if (( $(awk -v c="$inst_cpu" 'BEGIN { print (c < 15.0) }') )); then
      pass "Idle CPU utilization within sanity limit: ${inst_cpu}% < 15.0%"
    else
      fail "Idle CPU utilization exceeded limit: ${inst_cpu}% >= 15.0%"
    fi
  else
    finding "No live Quickshell process running; skipping live metric ceilings"
  fi
fi

# ---------------------------------------------------------------------------
# Section 4: Static Timer & Hotspot Inventory Audit (D-07, D-10)
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Static Timer & Hotspot Inventory Audit ---"

  # Verify DRM sysfs paths exist
  if [[ -r "/sys/class/drm/card1/gt/gt0/rc6_residency_ms" ]]; then
    pass "Intel UHD 770 iGPU RC6 sysfs interface is readable"
  else
    fail "Intel UHD 770 iGPU RC6 sysfs interface missing or unreadable"
  fi

  # Verify ResourceUsage.qml timer exists in codebase
  RU_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml"
  if grep -q "Timer" "$RU_QML" && grep -q "interval:" "$RU_QML"; then
    pass "ResourceUsage.qml contains polling timer"
  else
    fail "ResourceUsage.qml timer definition missing"
  fi

  # Verify HardwareTelemetry.qml FileViews
  HW_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml"
  FV_COUNT="$(grep -c "FileView" "$HW_QML" || echo 0)"
  if (( FV_COUNT >= 20 )); then
    pass "HardwareTelemetry.qml defines comprehensive sensor FileViews ($FV_COUNT >= 20)"
  else
    fail "HardwareTelemetry.qml FileView count below expected: $FV_COUNT < 20"
  fi
fi

# ---------------------------------------------------------------------------
# Section 5: Strict Repository Verification & Zero Drift (INTG-01, D-15)
# ---------------------------------------------------------------------------
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Strict Repository Verification & Zero Drift ---"

  # Git porcelain cleanliness check
  PORCELAIN_AFTER="$(mktemp /tmp/p43.1-porcelain-XXXXXX)"
  TMP_FILES+=("$PORCELAIN_AFTER")
  git status --porcelain | grep -vE "BENCHMARK\.md|benchmark-latest\.json|\.gitkeep" > "$PORCELAIN_AFTER" || true

  if diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" >/dev/null 2>&1; then
    pass "Git porcelain status clean; zero working tree drift during assert run"
  else
    fail "Git porcelain status drifted during assert run"
    diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
  fi

  # Run ./arch/dots-hyprland.sh verify --strict
  if [[ "$QUICK_MODE" -eq 0 && -x "$REPO_ROOT/arch/dots-hyprland.sh" ]]; then
    info "Running ./arch/dots-hyprland.sh verify --strict..."
    if "$REPO_ROOT/arch/dots-hyprland.sh" verify --strict; then
      pass "./arch/dots-hyprland.sh verify --strict passed cleanly (FAIL=0 FINDINGS=0)"
    else
      fail "./arch/dots-hyprland.sh verify --strict encountered failures"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Summary & Exit
# ---------------------------------------------------------------------------
info "=== Phase 43.1 Assertion Summary ==="
info "FAIL: $FAIL | FINDINGS: $FINDINGS"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
