#!/usr/bin/env bash
set -euo pipefail

# Physical repository root (pwd -P resolves all symlinks)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$REPO_ROOT"

# D-06: Non-root execution gate — sudo requested on-demand by sub-tools
CURRENT_EUID="${DOTFILES_MOCK_EUID:-${EUID:-$(id -u)}}"
if [[ "$CURRENT_EUID" -eq 0 ]]; then
  echo "[FAIL] ./bootstrap.sh must NOT be run as root. Run as regular operator." >&2
  exit 1
fi

# Platform assertion: Arch Linux is the sole supported target
ARCH_RELEASE_FILE="${DOTFILES_MOCK_ARCH_RELEASE:-/etc/arch-release}"
if [[ ! -f "$ARCH_RELEASE_FILE" ]]; then
  echo "[FAIL] /etc/arch-release not found. Arch Linux is required for bootstrap." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Dual-Stream Console + Transcript Logging (D-07, Pitfall 3)
# ---------------------------------------------------------------------------
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
LOG_DIR="$XDG_STATE_HOME/dotfiles/logs"
mkdir -p "$LOG_DIR"

cleanup_old_logs() {
  local count
  count="$(find "$LOG_DIR" -maxdepth 1 -name 'bootstrap-*.log' 2>/dev/null | wc -l)"
  if ((count > 5)); then
    find "$LOG_DIR" -maxdepth 1 -name 'bootstrap-*.log' -printf '%T@ %p\n' 2>/dev/null \
      | sort -n | head -n -5 | awk '{print $2}' | xargs -r rm -f 2>/dev/null || true
  fi
}
cleanup_old_logs

LOG_FILE="$LOG_DIR/bootstrap-$(date +"%Y%m%d_%H%M%S_$$").log"

# Duplicate standard descriptors to preserve clean exit flushing
exec 3>&1 4>&2
exec > >(tee -a "$LOG_FILE") 2>&1

cleanup_logging() {
  exec 1>&3 2>&4 3>&- 4>&-
  wait 2>/dev/null || true
}
trap cleanup_logging EXIT

# ---------------------------------------------------------------------------
# CLI Argument Parsing & Closed Flag Surface (D-04)
# ---------------------------------------------------------------------------
usage() {
  cat <<'EOF'
./bootstrap.sh — Reproduce dotfiles desktop environment from a clean clone

Usage:
  ./bootstrap.sh [flags…]

Flags:
  --dry-run       Structured preview of pipeline steps and commands without mutating disk
  --from <step>   Resume execution starting at specified step, skipping prior completed steps
  --only <step>   Execute solely the specified step and exit
  --reset         Wipe persistent state file to force a fresh re-run from step 1
  --snapshot      Regenerate package snapshots (arch/pkglist-*.txt) and exit
  --no-pause      Skip interactive relogin pause (for automated headless validation)
  -h, --help      Display this help message and exit

Pipeline Steps:
  1. submodules   Update git submodules recursively
  2. packages     Verify and install base prerequisites (git, stow, jq, yay)
  3. installer    Execute upstream dots-hyprland installer via wrapper
  4. destub       Discover conflicts, archive stubs to ~/.dotfiles-backup.<epoch>/, unlink
  5. stow         Pre-create parent dirs and stow packages in stow/ then restow/
  6. capture_seed Atomically deploy baseline configs from capture/ to $HOME
  [Relogin Boundary: prompt operator to exit session and log back in]
  7. verify       Activate systemd user timer and run arch/dots-hyprland.sh verify --strict
EOF
}

STEPS=(submodules packages installer destub stow capture_seed verify)

is_valid_step() {
  local s="$1"
  for val in "${STEPS[@]}"; do
    if [[ "$val" == "$s" ]]; then
      return 0
    fi
  done
  return 1
}

DRY_RUN=0
FROM_STEP=""
ONLY_STEP=""
RESET_STATE=0
SNAPSHOT_MODE=0
NO_PAUSE=0
declare -a UNKNOWN_FLAGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --from)
      if [[ -z "${2:-}" ]]; then
        echo "[FAIL] --from requires a step argument." >&2
        exit 2
      fi
      if ! is_valid_step "$2"; then
        echo "[FAIL] Invalid step '$2' for --from. Valid steps: ${STEPS[*]}" >&2
        exit 2
      fi
      FROM_STEP="$2"
      shift 2
      ;;
    --only)
      if [[ -z "${2:-}" ]]; then
        echo "[FAIL] --only requires a step argument." >&2
        exit 2
      fi
      if ! is_valid_step "$2"; then
        echo "[FAIL] Invalid step '$2' for --only. Valid steps: ${STEPS[*]}" >&2
        exit 2
      fi
      ONLY_STEP="$2"
      shift 2
      ;;
    --reset)
      RESET_STATE=1
      shift
      ;;
    --snapshot)
      SNAPSHOT_MODE=1
      shift
      ;;
    --no-pause)
      NO_PAUSE=1
      shift
      ;;
    *)
      UNKNOWN_FLAGS+=("$1")
      shift
      ;;
  esac
done

if ((${#UNKNOWN_FLAGS[@]} > 0)); then
  echo "[FAIL] Unknown bootstrap flag(s): ${UNKNOWN_FLAGS[*]}" >&2
  echo "[FAIL] Run ./bootstrap.sh --help for accepted flags." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Resumable JSON State Engine via jq (D-02, D-03, D-05)
# ---------------------------------------------------------------------------
STATE_FILE="$XDG_STATE_HOME/dotfiles/bootstrap-state"

init_state() {
  if [[ "$RESET_STATE" -eq 1 && -f "$STATE_FILE" ]]; then
    rm -f "$STATE_FILE"
  fi
  if [[ ! -f "$STATE_FILE" ]]; then
    mkdir -p "$(dirname "$STATE_FILE")"
    local now
    now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    jq -n --arg ts "$now" '{
      schema_version: 1,
      started_at: $ts,
      updated_at: $ts,
      stage: 1,
      current_step: "submodules",
      steps: {
        submodules: { status: "pending", timestamp: null },
        packages: { status: "pending", timestamp: null },
        installer: { status: "pending", timestamp: null },
        destub: { status: "pending", timestamp: null },
        stow: { status: "pending", timestamp: null },
        capture_seed: { status: "pending", timestamp: null },
        verify: { status: "pending", timestamp: null }
      },
      last_error: null
    }' > "$STATE_FILE.tmp.$$" && mv "$STATE_FILE.tmp.$$" "$STATE_FILE"
  fi
}

set_step_status() {
  local step="$1" status="$2" err="${3:-}"
  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local tmp="$STATE_FILE.tmp.$$"
  jq --arg step "$step" --arg status "$status" --arg ts "$now" --arg err "$err" '
    .updated_at = $ts |
    .current_step = $step |
    .steps[$step].status = $status |
    .steps[$step].timestamp = $ts |
    if $err != "" then .last_error = $err else . end
  ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

get_step_status() {
  local step="$1"
  if [[ -f "$STATE_FILE" ]]; then
    jq -r --arg step "$step" '.steps[$step].status // "pending"' "$STATE_FILE"
  else
    echo "pending"
  fi
}

get_stage() {
  if [[ -f "$STATE_FILE" ]]; then
    jq -r '.stage // 1' "$STATE_FILE"
  else
    echo 1
  fi
}

set_stage() {
  local stage="$1"
  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local tmp="$STATE_FILE.tmp.$$"
  jq --argjson stage "$stage" --arg ts "$now" '
    .updated_at = $ts | .stage = $stage
  ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

FROM_ACTIVE=0

execute_step() {
  local step_name="$1"
  local step_command_func="$2"

  # Check --only filter
  if [[ -n "$ONLY_STEP" && "$ONLY_STEP" != "$step_name" ]]; then
    return 0
  fi

  # Check --from filter
  if [[ -n "$FROM_STEP" ]]; then
    if [[ "$FROM_ACTIVE" -eq 0 ]]; then
      if [[ "$FROM_STEP" == "$step_name" ]]; then
        FROM_ACTIVE=1
      else
        echo "[SKIP] Step '$step_name' skipped by --from $FROM_STEP."
        return 0
      fi
    fi
  fi

  # Check idempotence: if not targeting via --only and step already complete
  local current_status
  current_status="$(get_step_status "$step_name")"
  if [[ -z "$ONLY_STEP" && "$current_status" == "complete" ]]; then
    echo "[SKIP] Step '$step_name' already completed."
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] Would execute step: $step_name"
    return 0
  fi

  echo "[RUN] Executing step: $step_name"
  set_step_status "$step_name" "running"

  local rc=0
  if [[ -n "${DOTFILES_MOCK_FAIL_STEP:-}" && "${DOTFILES_MOCK_FAIL_STEP}" == "$step_name" ]]; then
    echo "[MOCK] Triggering simulated failure for step '$step_name'" >&2
    rc="${DOTFILES_MOCK_FAIL_RC:-42}"
  else
    "$step_command_func" || rc=$?
  fi

  if [[ "$rc" -eq 0 ]]; then
    set_step_status "$step_name" "complete"
    echo "[PASS] Step '$step_name' completed successfully."
  else
    local err_msg="Step '$step_name' failed with exit code $rc"
    set_step_status "$step_name" "failed" "$err_msg"
    echo "[FAIL] Bootstrap failed during step '$step_name' (exit code $rc)." >&2
    echo "[INFO] To resume bootstrap from this step after addressing the issue, run: ./bootstrap.sh --from $step_name" >&2
    exit "$rc"
  fi
}

# ---------------------------------------------------------------------------
# Pipeline Step Implementations (Stubs for Wave 1; detailed in Wave 2 & 3)
# ---------------------------------------------------------------------------
step_submodules() {
  echo "[STEP 1/7] Updating submodules..."
}

step_packages() {
  echo "[STEP 2/7] Checking base prerequisites..."
}

step_installer() {
  echo "[STEP 3/7] Invoking dots-hyprland installer..."
}

step_destub() {
  echo "[STEP 4/7] De-stubbing conflicts..."
}

step_stow() {
  echo "[STEP 5/7] Linking dotfiles via GNU Stow..."
}

step_capture_seed() {
  echo "[STEP 6/7] Seeding capture baseline..."
}

step_verify() {
  echo "[STEP 7/7] Verifying desktop environment..."
}

# ---------------------------------------------------------------------------
# Package Snapshot Generator (--snapshot) (D-20, D-21)
# ---------------------------------------------------------------------------
generate_package_snapshots() {
  local host
  host="$(uname -n 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "${HOSTNAME:-arch}")"
  local ts
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local kernel
  kernel="$(uname -r 2>/dev/null || echo "unknown")"
  local pac_ver
  pac_ver="$(pacman -V 2>/dev/null | grep -o 'Pacman v[0-9.]* - libalpm v[0-9.]*' || echo "unknown")"

  local nat_file="$REPO_ROOT/arch/pkglist-native.txt"
  {
    printf '# arch/pkglist-native.txt — explicitly installed native packages\n'
    printf '# Hostname: %s\n' "$host"
    printf '# Timestamp: %s\n' "$ts"
    printf '# Kernel: %s\n' "$kernel"
    printf '# Pacman: %s\n' "$pac_ver"
    printf '# Count: %d\n' "$(pacman -Qqen 2>/dev/null | wc -l || echo 0)"
    pacman -Qqen 2>/dev/null | LC_ALL=C sort -u || true
  } > "$nat_file.tmp.$$" && mv "$nat_file.tmp.$$" "$nat_file"

  local aur_file="$REPO_ROOT/arch/pkglist-aur.txt"
  {
    printf '# arch/pkglist-aur.txt — explicitly installed foreign/AUR packages\n'
    printf '# Hostname: %s\n' "$host"
    printf '# Timestamp: %s\n' "$ts"
    printf '# Kernel: %s\n' "$kernel"
    printf '# Pacman: %s\n' "$pac_ver"
    printf '# Count: %d\n' "$(pacman -Qqem 2>/dev/null | wc -l || echo 0)"
    pacman -Qqem 2>/dev/null | LC_ALL=C sort -u || true
  } > "$aur_file.tmp.$$" && mv "$aur_file.tmp.$$" "$aur_file"

  echo "[SNAPSHOT] Successfully generated $nat_file and $aur_file"
}

# ---------------------------------------------------------------------------
# Main Orchestrator Dispatcher
# ---------------------------------------------------------------------------
main() {
  init_state

  if [[ "$SNAPSHOT_MODE" -eq 1 ]]; then
    generate_package_snapshots
    exit 0
  fi

  execute_step "submodules" step_submodules
  execute_step "packages" step_packages
  execute_step "installer" step_installer
  execute_step "destub" step_destub
  execute_step "stow" step_stow
  execute_step "capture_seed" step_capture_seed
  execute_step "verify" step_verify

  echo "[DONE] Bootstrap pipeline execution complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
