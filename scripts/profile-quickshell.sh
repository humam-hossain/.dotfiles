#!/usr/bin/env bash
# =============================================================================
# scripts/profile-quickshell.sh
#
# Quickshell Performance Profiling and Resource Optimization Harness
# Phase 43.1 - Linux procfs/sysfs telemetry, GNU Stow baseline isolation,
# and structured benchmark reporting.
# =============================================================================
set -euo pipefail

# Fail closed if executed as root or under sudo (ASVS L1 Root Privilege Prevention)
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Error: scripts/profile-quickshell.sh must not be run as root." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Default configuration values (D-03)
WARMUP_SEC=5
DURATION_SEC=30
QUICK_MODE=0
SELECTED_STAGE=""
COMPARE_FILE=""
JSON_OUT_FILE="$REPO_ROOT/.planning/phases/43.1-quickshell-performance-profiling-and-resource-optimization/benchmark-latest.json"
REPORT_OUT_FILE="$REPO_ROOT/.planning/phases/43.1-quickshell-performance-profiling-and-resource-optimization/BENCHMARK.md"

# ANSI color styling
CLR_RESET="\033[0m"
CLR_BOLD="\033[1m"
CLR_CYAN="\033[1;36m"
CLR_GREEN="\033[1;32m"
CLR_YELLOW="\033[1;33m"
CLR_RED="\033[1;31m"

info()    { printf "${CLR_CYAN}[INFO]${CLR_RESET} %s\n" "$*"; }
pass()    { printf "${CLR_GREEN}[PASS]${CLR_RESET} %s\n" "$*"; }
warn()    { printf "${CLR_YELLOW}[WARN]${CLR_RESET} %s\n" "$*"; }
fail()    { printf "${CLR_RED}[FAIL]${CLR_RESET} %s\n" "$*"; }
header()  { printf "\n${CLR_BOLD}${CLR_CYAN}=== %s ===${CLR_RESET}\n" "$*"; }

# Temporary files and signal traps
TMP_FILES=()
STOW_ISOLATED=0
STUB_LIST_FILE="$(mktemp /tmp/p43.1-stubs-XXXXXX)"
TMP_FILES+=("$STUB_LIST_FILE")

cleanup() {
  local exit_code=$?
  trap - EXIT INT TERM
  info "Cleaning up temporary files and restoring state..."
  if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    rm -f "${TMP_FILES[@]}" 2>/dev/null || true
  fi
  if declare -F restore_restow_quickshell >/dev/null 2>&1; then
    restore_restow_quickshell || true
  fi
  exit "$exit_code"
}
trap cleanup EXIT INT TERM

# -----------------------------------------------------------------------------
# CLI Usage and Help
# -----------------------------------------------------------------------------
show_help() {
  cat << 'EOF'
Usage: ./scripts/profile-quickshell.sh [OPTIONS]

Quickshell Performance Profiling and Resource Optimization Harness (Phase 43.1)

Options:
  -h, --help              Show this help message and exit
  -q, --quick             Run fast smoke profiling (2s warmup, 5s duration per stage)
  -s, --stage <id>        Execute only a single specified stage ID from registry
  --warmup <sec>          Stabilization warm-up interval in seconds (default: 5, quick: 2)
  --duration <sec>        Measurement sampling duration in seconds (default: 30, quick: 5)
  --json <path>           Output path for machine-readable JSON telemetry export
  --report <path>         Output path for comprehensive markdown benchmark report
  --compare <file.json>   Compare current benchmark results against baseline JSON

Stages:
  upstream_baseline       Pure upstream dots-hyprland (GNU Stow baseline isolation)
  full_idle               Full production Quickshell shell in stationary idle state
  full_active_popup       Full production Quickshell with CPU/GPU inspector popup active

Telemetry Vectors:
  - Process CPU % (ticks / elapsed time via /proc/$PID/stat)
  - Deep Memory (RSS, PSS, Private Dirty via /proc/$PID/smaps_rollup)
  - Threads & Context Switches (/proc/$PID/status)
  - Syscall Churn & I/O rates (/proc/$PID/io)
  - Open File Descriptors (/proc/$PID/fd/)
  - Intel UHD 770 iGPU Active Render Load & Clock Frequency (sysfs card1 RC6)
EOF
}

# -----------------------------------------------------------------------------
# Process Discovery & Lifecycle Management (Pattern A)
# -----------------------------------------------------------------------------
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

restart_quickshell() {
  local qs_bin=""
  if command -v qs >/dev/null 2>&1; then
    qs_bin="qs"
  elif command -v quickshell >/dev/null 2>&1; then
    qs_bin="quickshell"
  else
    fail "Neither 'qs' nor 'quickshell' binary found in PATH"
    return 1
  fi

  info "Stopping active Quickshell instance..."
  $qs_bin -c ii kill 2>/dev/null || true
  local pids=($(collect_qs_pids))
  if [[ ${#pids[@]} -gt 0 ]]; then
    kill "${pids[@]}" 2>/dev/null || true
    for _ in {1..30}; do
      local remaining=0
      for p in "${pids[@]}"; do
        if kill -0 "$p" 2>/dev/null; then remaining=1; break; fi
      done
      [[ "$remaining" -eq 0 ]] && break
      sleep 0.1
    done
  fi

  info "Starting Quickshell daemon ($qs_bin -c ii -d)..."
  $qs_bin -c ii -d >/dev/null 2>&1 &
  sleep 1.5
}

# -----------------------------------------------------------------------------
# Linux Kernel Telemetry Sampling Engine (procfs & sysfs, Pattern C & D)
# -----------------------------------------------------------------------------
sample_proc_cpu() {
  local pid="$1"
  local stat_line tail utime stime
  stat_line="$(cat "/proc/$pid/stat" 2>/dev/null || true)"
  [[ -n "$stat_line" ]] || { echo "0"; return 0; }
  # Strip everything up to the last closing parenthesis to safely handle process names with spaces
  tail="${stat_line##*) }"
  # In tail: field 12 is utime, field 13 is stime
  read -r _ _ _ _ _ _ _ _ _ _ _ utime stime _ <<< "$tail"
  echo "$((utime + stime))"
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

sample_proc_status() {
  local pid="$1"
  local threads=0 vol_ctx=0 nonvol_ctx=0
  if [[ -r "/proc/$pid/status" ]]; then
    while IFS=':' read -r key val; do
      val="${val//[[:space:]]/}"
      case "$key" in
        Threads) threads="$val" ;;
        voluntary_ctxt_switches) vol_ctx="$val" ;;
        nonvoluntary_ctxt_switches) nonvol_ctx="$val" ;;
      esac
    done < "/proc/$pid/status"
  fi
  echo "$threads $vol_ctx $nonvol_ctx"
}

sample_proc_io() {
  local pid="$1"
  local syscr=0 syscw=0 rbytes=0 wbytes=0
  if [[ -r "/proc/$pid/io" ]]; then
    while IFS=':' read -r key val; do
      val="${val//[[:space:]]/}"
      case "$key" in
        syscr) syscr="$val" ;;
        syscw) syscw="$val" ;;
        read_bytes) rbytes="$val" ;;
        write_bytes) wbytes="$val" ;;
      esac
    done < "/proc/$pid/io"
  fi
  echo "$syscr $syscw $rbytes $wbytes"
}

sample_proc_fds() {
  local pid="$1"
  ls -1 "/proc/$pid/fd" 2>/dev/null | wc -l || echo 0
}

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

compute_gpu_load() {
  local d_rc6_ms="$1"
  local d_t_ms="$2"
  awk -v drc6="$d_rc6_ms" -v dt="$d_t_ms" 'BEGIN {
    if (dt <= 0) { printf "0.00"; exit; }
    idle_ratio = drc6 / dt;
    if (idle_ratio > 1.0) idle_ratio = 1.0;
    if (idle_ratio < 0.0) idle_ratio = 0.0;
    active_pct = (1.0 - idle_ratio) * 100.0;
    printf "%.2f", active_pct;
  }'
}

# -----------------------------------------------------------------------------
# Parse CLI Options
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -q|--quick)
      QUICK_MODE=1
      WARMUP_SEC=2
      DURATION_SEC=5
      shift
      ;;
    -s|--stage)
      [[ -n "${2:-}" ]] || { echo "Error: --stage requires a stage ID" >&2; exit 1; }
      SELECTED_STAGE="$2"
      shift 2
      ;;
    --warmup)
      [[ "${2:-}" =~ ^[0-9]+$ ]] || { echo "Error: --warmup requires an integer" >&2; exit 1; }
      WARMUP_SEC="$2"
      shift 2
      ;;
    --duration)
      [[ "${2:-}" =~ ^[0-9]+$ ]] || { echo "Error: --duration requires an integer" >&2; exit 1; }
      DURATION_SEC="$2"
      shift 2
      ;;
    --json)
      [[ -n "${2:-}" ]] || { echo "Error: --json requires a file path" >&2; exit 1; }
      JSON_OUT_FILE="$2"
      shift 2
      ;;
    --report)
      [[ -n "${2:-}" ]] || { echo "Error: --report requires a file path" >&2; exit 1; }
      REPORT_OUT_FILE="$2"
      shift 2
      ;;
    --compare)
      [[ -n "${2:-}" ]] || { echo "Error: --compare requires a baseline JSON file path" >&2; exit 1; }
      COMPARE_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

# -----------------------------------------------------------------------------
# Single Stage Sampling Window
# -----------------------------------------------------------------------------
run_sample_window() {
  local stage_id="$1"
  local stage_name="$2"
  local warmup_sec="$WARMUP_SEC"
  local duration_sec="$DURATION_SEC"

  header "Profiling Stage: $stage_name ($stage_id)"
  info "Warm-up: ${warmup_sec}s | Sampling Duration: ${duration_sec}s"

  info "Stabilization warm-up (${warmup_sec}s)..."
  sleep "$warmup_sec"

  local pids=($(collect_qs_pids))
  if [[ ${#pids[@]} -eq 0 ]]; then
    fail "No Quickshell PID found for stage: $stage_id"
    return 1
  fi
  local pid="${pids[0]}"
  info "Active Quickshell PID: $pid"

  local clk_tck
  clk_tck="$(getconf CLK_TCK 2>/dev/null || echo 100)"

  # Initial snapshot
  local t1 cpu_ticks1 vol_ctx1 nonvol_ctx1 syscr1 syscw1 rc6_1 freq_mhz1
  t1="$(date +%s%N)"
  cpu_ticks1="$(sample_proc_cpu "$pid")"
  read -r threads1 vol_ctx1 nonvol_ctx1 <<< "$(sample_proc_status "$pid")"
  read -r syscr1 syscw1 rbytes1 wbytes1 <<< "$(sample_proc_io "$pid")"
  read -r rc6_1 freq_mhz1 <<< "$(sample_intel_gpu)"

  local samples=0
  local peak_cpu=0.0
  local sum_cpu=0.0
  local last_ticks="$cpu_ticks1"
  local last_t="$t1"

  for ((i=1; i<=duration_sec; i++)); do
    sleep 1
    local now_t="$(date +%s%N)"
    local now_ticks="$(sample_proc_cpu "$pid")"
    local dt_sec="$(awk -v t1="$last_t" -v t2="$now_t" 'BEGIN { printf "%.4f", (t2 - t1)/1000000000.0 }')"
    local dticks="$((now_ticks - last_ticks))"
    local inst_cpu="$(awk -v dticks="$dticks" -v dt="$dt_sec" -v clk="$clk_tck" 'BEGIN { printf "%.2f", (dticks / (dt * clk)) * 100.0 }')"

    sum_cpu="$(awk -v s="$sum_cpu" -v c="$inst_cpu" 'BEGIN { printf "%.2f", s + c }')"
    peak_cpu="$(awk -v p="$peak_cpu" -v c="$inst_cpu" 'BEGIN { printf "%.2f", (c > p ? c : p) }')"
    samples=$((samples + 1))
    last_ticks="$now_ticks"
    last_t="$now_t"
  done

  # Final snapshot
  local t2="$(date +%s%N)"
  local total_dt_sec="$(awk -v t1="$t1" -v t2="$t2" 'BEGIN { printf "%.4f", (t2 - t1)/1000000000.0 }')"
  local total_dt_ms="$(awk -v t1="$t1" -v t2="$t2" 'BEGIN { printf "%.2f", (t2 - t1)/1000000.0 }')"

  local avg_cpu="$(awk -v sum="$sum_cpu" -v n="$samples" 'BEGIN { printf "%.2f", (n > 0 ? sum / n : 0.0) }')"
  local rss_mb pss_mb priv_dirty_mb
  read -r rss_mb pss_mb priv_dirty_mb <<< "$(sample_proc_memory "$pid")"
  local final_threads vol_ctx2 nonvol_ctx2
  read -r final_threads vol_ctx2 nonvol_ctx2 <<< "$(sample_proc_status "$pid")"
  local syscr2 syscw2 rbytes2 wbytes2
  read -r syscr2 syscw2 rbytes2 wbytes2 <<< "$(sample_proc_io "$pid")"
  local rc6_2 final_freq_mhz
  read -r rc6_2 final_freq_mhz <<< "$(sample_intel_gpu)"
  local open_fds
  open_fds="$(sample_proc_fds "$pid")"

  # Rates
  local vol_ctx_rate nonvol_ctx_rate syscr_rate syscw_rate gpu_busy_pct
  vol_ctx_rate="$(awk -v v1="$vol_ctx1" -v v2="$vol_ctx2" -v dt="$total_dt_sec" 'BEGIN { printf "%.1f", (v2 - v1) / dt }')"
  nonvol_ctx_rate="$(awk -v n1="$nonvol_ctx1" -v n2="$nonvol_ctx2" -v dt="$total_dt_sec" 'BEGIN { printf "%.1f", (n2 - n1) / dt }')"
  syscr_rate="$(awk -v s1="$syscr1" -v s2="$syscr2" -v dt="$total_dt_sec" 'BEGIN { printf "%.1f", (s2 - s1) / dt }')"
  syscw_rate="$(awk -v s1="$syscw1" -v s2="$syscw2" -v dt="$total_dt_sec" 'BEGIN { printf "%.1f", (s2 - s1) / dt }')"
  gpu_busy_pct="$(compute_gpu_load "$((rc6_2 - rc6_1))" "$total_dt_ms")"

  header "Telemetry Results: $stage_name ($stage_id)"
  printf "  %-24s: %s%% (avg) / %s%% (peak)\n" "CPU Utilization" "$avg_cpu" "$peak_cpu"
  printf "  %-24s: %s MB\n" "Memory RSS" "$rss_mb"
  printf "  %-24s: %s MB\n" "Memory PSS" "$pss_mb"
  printf "  %-24s: %s MB\n" "Private Dirty Memory" "$priv_dirty_mb"
  printf "  %-24s: %s threads\n" "Active Threads" "$final_threads"
  printf "  %-24s: %s /sec (vol) / %s /sec (non-vol)\n" "Context Switches" "$vol_ctx_rate" "$nonvol_ctx_rate"
  printf "  %-24s: %s reads/s, %s writes/s\n" "Syscall Churn" "$syscr_rate" "$syscw_rate"
  printf "  %-24s: %s\n" "Open File Descriptors" "$open_fds"
  printf "  %-24s: %s%% (active clock: %s MHz)\n" "Intel iGPU Render Load" "$gpu_busy_pct" "$final_freq_mhz"
}

# -----------------------------------------------------------------------------
# Main Execution Entrypoint
# -----------------------------------------------------------------------------
main() {
  local target_stage="${SELECTED_STAGE:-full_idle}"
  run_sample_window "$target_stage" "Quickshell Run"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
