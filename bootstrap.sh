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

cleanup_old_logs() {
  local count
  count="$(find "$LOG_DIR" -maxdepth 1 -name 'bootstrap-*.log' 2>/dev/null | wc -l)"
  if ((count > 5)); then
    find "$LOG_DIR" -maxdepth 1 -name 'bootstrap-*.log' -printf '%T@ %p\n' 2>/dev/null \
      | sort -n | head -n -5 | awk '{print $2}' | xargs -r rm -f 2>/dev/null || true
  fi
}

cleanup_logging() {
  exec 1>&3 2>&4 3>&- 4>&-
  wait 2>/dev/null || true
}

# Only attach transcript logging and trap when executed directly, not sourced as a library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  mkdir -p "$LOG_DIR"
  cleanup_old_logs
  LOG_FILE="$LOG_DIR/bootstrap-$(date +"%Y%m%d_%H%M%S_$$").log"

  exec 3>&1 4>&2
  exec > >(tee -a "$LOG_FILE") 2>&1
  trap cleanup_logging EXIT
fi

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

parse_args() {
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
}

# ---------------------------------------------------------------------------
# Resumable JSON State Engine via jq (D-02, D-03, D-05)
# ---------------------------------------------------------------------------
STATE_FILE="$XDG_STATE_HOME/dotfiles/bootstrap-state"

init_state() {
  STATE_FILE="$XDG_STATE_HOME/dotfiles/bootstrap-state"
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
    "$step_command_func"
    return 0
  fi

  echo "[RUN] Executing step: $step_name"
  set_step_status "$step_name" "running"

  local rc=0
  if [[ -n "${DOTFILES_MOCK_FAIL_STEP:-}" && "${DOTFILES_MOCK_FAIL_STEP}" == "$step_name" ]]; then
    echo "[MOCK] Triggering simulated failure for step '$step_name'" >&2
    rc="${DOTFILES_MOCK_FAIL_RC:-42}"
  elif [[ "${DOTFILES_MOCK_STEPS:-0}" -eq 1 ]]; then
    echo "[MOCK] Fast step execution: $step_name"
    rc=0
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
# Guard Paths Handling (D-17)
# ---------------------------------------------------------------------------
declare -A GUARDED_PATHS=()

load_guard_paths() {
  local base_repo="${1:-$REPO_ROOT}"
  local base_home="${2:-$HOME}"
  local guard_file="$base_repo/guard-paths.tsv"
  GUARDED_PATHS=()
  [[ -f "$guard_file" ]] || return 0
  local g_path g_cat g_gen g_reason expanded
  while IFS=$'\t' read -r g_path g_cat g_gen g_reason || [[ -n "$g_path" ]]; do
    [[ -n "$g_path" && "$g_path" != \#* ]] || continue
    expanded="${g_path//\$XDG_CONFIG_HOME/$base_home\/.config}"
    expanded="${expanded//\$HOME/$base_home}"
    GUARDED_PATHS["$expanded"]=1
  done < "$guard_file"
}

is_guarded_path() {
  local check_path="${1%/}"
  local cur="$check_path"
  while [[ -n "$cur" && "$cur" != "/" && "$cur" != "." ]]; do
    if [[ -n "${GUARDED_PATHS["$cur"]:-}" ]]; then
      return 0
    fi
    cur="$(dirname -- "$cur")"
  done
  return 1
}

# ---------------------------------------------------------------------------
# Step 1: Submodule Recursion (D-03)
# ---------------------------------------------------------------------------
step_submodules() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] git submodule update --init --recursive"
    return 0
  fi
  echo "[STEP 1/7] Updating git submodules recursively..."
  git submodule update --init --recursive
}

# ---------------------------------------------------------------------------
# Step 2: Prerequisite Packages Check & AUR Helper (D-03, D-22)
# ---------------------------------------------------------------------------
step_packages() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] Checking base prerequisites (git, stow, jq, yay)..."
    echo "[DRY-RUN] Checking and activating power-profiles-daemon..."
    return 0
  fi
  echo "[STEP 2/7] Checking base prerequisites..."
  local missing=()
  for pkg in git stow jq; do
    if ! command -v "$pkg" &>/dev/null; then
      missing+=("$pkg")
    fi
  done
  if ((${#missing[@]} > 0)); then
    echo "[FAIL] Missing required base prerequisite(s): ${missing[*]}" >&2
    return 1
  fi
  if ! command -v yay &>/dev/null; then
    if [[ -x "$REPO_ROOT/arch/aur.sh" ]]; then
      echo "[INFO] yay not found; installing via arch/aur.sh..."
      "$REPO_ROOT/arch/aur.sh"
    else
      echo "[FAIL] yay not found and arch/aur.sh is missing or not executable." >&2
      return 1
    fi
  fi

  if ! pacman -Q power-profiles-daemon &>/dev/null; then
    echo "[INFO] power-profiles-daemon not installed; installing via pacman..."
    sudo pacman -S --needed --noconfirm power-profiles-daemon
  fi

  if command -v systemctl &>/dev/null; then
    if ! systemctl is-active --quiet power-profiles-daemon.service 2>/dev/null; then
      echo "[CONFIG] Enabling and starting power-profiles-daemon.service..."
      sudo systemctl enable --now power-profiles-daemon.service
    else
      echo "[PASS] power-profiles-daemon.service is already active."
    fi
  fi
}

# ---------------------------------------------------------------------------
# Step 3: Upstream Installer Wrapper Invocation (D-03, D-22)
# ---------------------------------------------------------------------------
step_installer() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] Would dispatch upstream dots-hyprland installer"
    return 0
  fi
  echo "[STEP 3/7] Invoking dots-hyprland installer via wrapper..."
  local subcmd="install"
  if [[ "${DOTFILES_BOOTSTRAP_FILES_ONLY:-0}" -eq 1 ]]; then
    subcmd="install-files"
  fi
  "$REPO_ROOT/arch/dots-hyprland.sh" "$subcmd"
}

# ---------------------------------------------------------------------------
# Step 4: De-stubbing & Safe Hierarchical Backup (D-15, D-16, D-17, D-18)
# ---------------------------------------------------------------------------
run_destub() {
  local target="${1:-$HOME}"
  local base_repo="${2:-$REPO_ROOT}"
  local epoch
  epoch="$(date +%s)"
  local backup_dir="$target/.dotfiles-backup.$epoch"
  local manifest="$backup_dir/MANIFEST.txt"
  local destub_count=0

  load_guard_paths "$base_repo" "$target"

  local trees=("$base_repo/stow" "$base_repo/restow")
  for tree_dir in "${trees[@]}"; do
    [[ -d "$tree_dir" ]] || continue
    for pkg_dir in "$tree_dir"/*; do
      [[ -d "$pkg_dir" ]] || continue
      local pkg
      pkg="$(basename "$pkg_dir")"
      [[ "$pkg" != "README.md" && "$pkg" != .* ]] || continue

      # Dry-run conflict simulation via GNU Stow
      local stow_out
      stow_out="$(stow -n --no-folding -d "$tree_dir" -t "$target" "$pkg" 2>&1 || true)"

      local conflict_targets=()
      while IFS= read -r line; do
        if [[ "$line" =~ \*[[:space:]]+cannot[[:space:]]+stow[[:space:]]+.*[[:space:]]+over[[:space:]]+existing[[:space:]]+target[[:space:]]+([^[:space:]]+)[[:space:]]+since ]]; then
          conflict_targets+=("${BASH_REMATCH[1]}")
        elif [[ "$line" =~ \*[[:space:]]+existing[[:space:]]+target[[:space:]]+is[[:space:]]+not[[:space:]]+owned[[:space:]]+by[[:space:]]+stow:[[:space:]]+(.*) ]]; then
          conflict_targets+=("${BASH_REMATCH[1]}")
        elif [[ "$line" =~ \*[[:space:]]+existing[[:space:]]+target[[:space:]]+is[[:space:]]+neither[[:space:]]+a[[:space:]]+link[[:space:]]+nor[[:space:]]+a[[:space:]]+directory:[[:space:]]+(.*) ]]; then
          conflict_targets+=("${BASH_REMATCH[1]}")
        elif [[ "$line" =~ \*[[:space:]]+cannot[[:space:]]+stow[[:space:]]+.*[[:space:]]+as[[:space:]]+existing[[:space:]]+target[[:space:]]+([^[:space:]]+) ]]; then
          conflict_targets+=("${BASH_REMATCH[1]}")
        elif [[ "$line" =~ \*[[:space:]]+existing[[:space:]]+target[[:space:]]+is[[:space:]]+a[[:space:]]+link:[[:space:]]+(.*) ]]; then
          conflict_targets+=("${BASH_REMATCH[1]}")
        fi
      done <<< "$stow_out"

      for raw_path in "${conflict_targets[@]+"${conflict_targets[@]}"}"; do
        local rel_path
        rel_path="$(echo "$raw_path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [[ -n "$rel_path" ]] || continue

        local live_path
        if [[ "$rel_path" = /* ]]; then
          live_path="$rel_path"
          rel_path="${rel_path#"$target"/}"
        else
          live_path="$target/$rel_path"
        fi

        # D-17: Strictly skip all guarded theme outputs
        if is_guarded_path "$live_path"; then
          echo "[GUARD] Preserving guarded theme path: $rel_path"
          continue
        fi

        if [[ -f "$live_path" && ! -L "$live_path" ]]; then
          # Conflicting regular file: back up with manifest then unlink
          if [[ "$DRY_RUN" -eq 1 ]]; then
            echo "[DRY-RUN] Would backup and remove stub: $rel_path"
          else
            mkdir -p "$backup_dir/$(dirname "$rel_path")"
            local sha now
            sha="$(sha256sum "$live_path" | awk '{print $1}')"
            now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
            printf '# Timestamp: %s\n%s  %s\n' "$now" "$sha" "$rel_path" >> "$manifest"
            cp -p "$live_path" "$backup_dir/$rel_path"
            rm -f "$live_path"
            echo "[DESTUB] Archived and removed stub: $rel_path"
            destub_count=$((destub_count + 1))
          fi
        elif [[ -L "$live_path" ]]; then
          # Stale or foreign symlink
          if [[ "$DRY_RUN" -eq 1 ]]; then
            echo "[DRY-RUN] Would remove stale symlink: $rel_path"
          else
            rm -f "$live_path"
            echo "[PRUNE] Removed stale/foreign symlink: $rel_path"
          fi
        fi
      done
    done
  done

  # D-11: Explicit legacy Catppuccin symlink pruning in GTK config directories
  for gtk_ver in gtk-3.0 gtk-4.0; do
    local gtk_dir="$target/.config/$gtk_ver"
    [[ -d "$gtk_dir" ]] || continue
    for f in "$gtk_dir"/*; do
      [[ -L "$f" ]] || continue
      local link_target
      link_target="$(readlink "$f" 2>/dev/null || true)"
      if [[ "$link_target" == */Catppuccin* || "$link_target" == */catppuccin* || "$link_target" == /usr/share/themes/Catppuccin* ]]; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
          echo "[DRY-RUN] Would remove legacy Catppuccin symlink: ${f#"$target"/}"
        else
          rm -f "$f"
          echo "[PRUNE] Removed legacy Catppuccin symlink: ${f#"$target"/}"
          destub_count=$((destub_count + 1))
        fi
      fi
    done
  done
}

step_destub() {
  echo "[STEP 4/7] De-stubbing conflicts and creating backup archive..."
  run_destub "$HOME" "$REPO_ROOT"
}

# ---------------------------------------------------------------------------
# Step 5: Stow Package Orchestration & Parent Dir Protection (D-12, D-13, D-14)
# ---------------------------------------------------------------------------
run_stow_step() {
  local target="${1:-$HOME}"
  local base_repo="${2:-$REPO_ROOT}"

  # D-14: Pre-create sensitive parent directories before stowing
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] Would pre-create sensitive parent directories"
  else
    mkdir -p "$target/.config/fuzzel" \
             "$target/.config/gtk-3.0" \
             "$target/.config/gtk-4.0" \
             "$target/.config/hypr/custom" \
             "$target/.config/kitty" \
             "$target/.config/quickshell/ii/modules/ii/bar" \
             "$target/.config/quickshell/ii/services" \
             "$target/.config/quickshell/ii/scripts/videos" \
             "$target/.config/systemd/user"
  fi

  # Link stow/ packages first (D-12, D-13)
  if [[ -d "$base_repo/stow" ]]; then
    for pkg_dir in "$base_repo/stow"/*; do
      [[ -d "$pkg_dir" ]] || continue
      local pkg
      pkg="$(basename "$pkg_dir")"
      [[ "$pkg" != "README.md" && "$pkg" != .* ]] || continue
      if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DRY-RUN] stow --verbose=5 --no-folding -d $base_repo/stow -t $target $pkg"
      else
        stow --verbose=5 --no-folding -d "$base_repo/stow" -t "$target" "$pkg"
      fi
    done
  fi

  # Link restow/ packages next (D-12, D-13)
  if [[ -d "$base_repo/restow" ]]; then
    for pkg_dir in "$base_repo/restow"/*; do
      [[ -d "$pkg_dir" ]] || continue
      local pkg
      pkg="$(basename "$pkg_dir")"
      [[ "$pkg" != "README.md" && "$pkg" != .* ]] || continue
      if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DRY-RUN] stow --verbose=5 --no-folding -d $base_repo/restow -t $target $pkg"
      else
        stow --verbose=5 --no-folding -d "$base_repo/restow" -t "$target" "$pkg"
      fi
    done
  fi
}

step_stow() {
  echo "[STEP 5/7] Linking dotfiles via GNU Stow..."
  run_stow_step "$HOME" "$REPO_ROOT"
}

# ---------------------------------------------------------------------------
# Step 6: Atomic Capture Seed Deployment with Validation (D-19)
# ---------------------------------------------------------------------------
deploy_capture_seeds() {
  local target="${1:-$HOME}"
  local base_repo="${2:-$REPO_ROOT}"
  local capture_root="$base_repo/capture"
  [[ -d "$capture_root" ]] || return 0

  while IFS= read -r -d '' src_file; do
    local rel_path="${src_file#"$capture_root"/}"
    # Strip the package-level directory component (e.g. ii/.config/... -> .config/...)
    local dest_sub="${rel_path#*/}"
    local dest_file="$target/$dest_sub"

    # JSON syntax validation before deployment (D-19)
    if [[ "$src_file" == *.json ]]; then
      if ! jq empty "$src_file" 2>/dev/null; then
        echo "[FAIL] Invalid JSON syntax in capture seed: $rel_path" >&2
        return 1
      fi
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] Would deploy capture seed: $dest_sub"
    else
      mkdir -p "$(dirname "$dest_file")"
      local tmp_file="${dest_file}.tmp.$$"
      cp -p "$src_file" "$tmp_file"
      mv "$tmp_file" "$dest_file"
      echo "[SEED] Deployed baseline capture config: $dest_sub"
    fi
  done < <(find "$capture_root" -type f -print0)
}

generate_initial_theme() {
  local target="${1:-$HOME}"
  local switchwall="$target/.config/quickshell/ii/scripts/colors/switchwall.sh"
  local config_file="$target/.config/illogical-impulse/config.json"
  local matugen_gtk4_tpl="$target/.config/matugen/templates/gtk-4.0/gtk.css"
  local kde_wrapper="$target/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
  local applycolor="$target/.config/quickshell/ii/scripts/colors/applycolor.sh"

  # Sanitize GTK 4 template pseudo-class if present (Pitfall 4)
  if [[ -f "$matugen_gtk4_tpl" ]] && grep -q ':insensitive' "$matugen_gtk4_tpl"; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] Would align GTK 4 template :insensitive -> :disabled"
    else
      sed -i 's/\.boxed-list row:insensitive/\.boxed-list row:disabled/g' "$matugen_gtk4_tpl"
      echo "[FIX] Aligned GTK 4 Matugen template pseudo-class (:disabled)"
    fi
  fi

  # Idempotent alignment for kde-material-you-colors-wrapper.sh virtualenv fallback (D-06)
  if [[ -f "$kde_wrapper" ]] && ! grep -Fq '${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-' "$kde_wrapper"; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] Would add virtualenv fallback to kde-material-you-colors-wrapper.sh"
    else
      sed -i 's|source "$(eval echo \$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"|source "$(eval echo ${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv})/bin/activate"|g' "$kde_wrapper"
      echo "[FIX] Aligned kde-material-you-colors-wrapper.sh virtualenv fallback"
    fi
  fi

  # Idempotent alignment for applycolor.sh Kitty process signaling (D-07)
  if [[ -f "$applycolor" ]] && grep -q 'kill -SIGUSR1 \$(pidof kitty)' "$applycolor"; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] Would align applycolor.sh Kitty process signaling"
    else
      sed -i '/if ! pgrep -f kitty >\/dev\/null; then/,/kill -SIGUSR1 \$(pidof kitty)/c\  killall -SIGUSR1 kitty 2>/dev/null || true' "$applycolor"
      echo "[FIX] Aligned applycolor.sh Kitty process signaling"
    fi
  fi

  if [[ ! -f "$switchwall" ]]; then
    echo "[WARN] switchwall.sh not found at $switchwall; skipping initial theming"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] Would trigger initial Material You theme generation"
    return 0
  fi

  export ILLOGICAL_IMPULSE_VIRTUAL_ENV="${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv}"

  local wp_path=""
  if [[ -f "$config_file" ]]; then
    wp_path="$(jq -r '.background.wallpaperPath // empty' "$config_file" 2>/dev/null || true)"
  fi

  echo "[THEME] Triggering initial theme generation..."
  if [[ -n "$wp_path" && -f "$wp_path" ]]; then
    echo "[THEME] Generating theme from configured wallpaper: $wp_path"
    if ! "$switchwall" --noswitch; then
      echo "[WARN] switchwall.sh --noswitch failed; falling back to color seed #3f51b5"
      "$switchwall" --color "#3f51b5" || echo "[WARN] Fallback theme generation failed"
    fi
  else
    echo "[THEME] Configured wallpaper absent or inaccessible; falling back to color seed #3f51b5"
    if ! "$switchwall" --color "#3f51b5"; then
      echo "[WARN] Fallback color seed theme generation failed"
    fi
  fi

  local generated_colors="$target/.local/state/quickshell/user/generated/colors.json"
  if [[ -n "${XDG_STATE_HOME:-}" && "$target" == "$HOME" ]]; then
    generated_colors="$XDG_STATE_HOME/quickshell/user/generated/colors.json"
  fi
  if [[ ! -s "$generated_colors" ]]; then
    echo "[FAIL] Initial theme generation did not produce primed colors.json at $generated_colors" >&2
    return 1
  fi
  echo "[THEME] Verified primed colors.json palette state ($generated_colors)"
}

step_capture_seed() {
  echo "[STEP 6/7] Seeding capture baseline and generating initial theme..."
  deploy_capture_seeds "$HOME" "$REPO_ROOT"
  generate_initial_theme "$HOME"
}

# ---------------------------------------------------------------------------
# Stage 1 Relogin Banner & Stage 2 Runtime Session Probe (D-08, D-09, D-10)
# ---------------------------------------------------------------------------
show_relogin_banner() {
  local reset="\033[0m" bold="\033[1m" green="\033[32m" cyan="\033[36m"
  if [[ ! -t 1 ]]; then
    reset="" bold="" green="" cyan=""
  fi

  cat <<EOF

${bold}${cyan}┌────────────────────────────────────────────────────────────────────────┐${reset}
${bold}${cyan}│${reset}                        ${bold}${green}BOOTSTRAP: STAGE 1 COMPLETE${reset}                     ${bold}${cyan}│${reset}
${bold}${cyan}├────────────────────────────────────────────────────────────────────────┤${reset}
${bold}${cyan}│${reset} All dotfiles, overlays, and session configs have been placed on disk.  ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}                                                                        ${bold}${cyan}│${reset}
${bold}${cyan}│${reset} The session entry point has changed to upstream ${bold}hyprland.lua${reset}.          ${bold}${cyan}│${reset}
${bold}${cyan}│${reset} A session relogin is mandatory to load the new desktop environment:    ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}                                                                        ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}   1. Exit current session:  ${bold}hyprctl dispatch exit${reset}                      ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}   2. Log back in via display manager / SDDM                             ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}   3. Complete bootstrap by running:                                     ${bold}${cyan}│${reset}
${bold}${cyan}│${reset}        ${bold}./bootstrap.sh${reset}                                                   ${bold}${cyan}│${reset}
${bold}${cyan}└────────────────────────────────────────────────────────────────────────┘${reset}

EOF
}

probe_session_environment() {
  if command -v hyprctl &>/dev/null; then
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || ! hyprctl -j status &>/dev/null; then
      local candidate_sig
      candidate_sig="$(ls -td "/run/user/$(id -u)/hypr/"* 2>/dev/null | head -1 | xargs -r basename || true)"
      if [[ -n "$candidate_sig" ]]; then
        export HYPRLAND_INSTANCE_SIGNATURE="$candidate_sig"
      fi
    fi
  fi
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo "[WARN] HYPRLAND_INSTANCE_SIGNATURE is not set. Graphical session may not be active." >&2
  fi
  if command -v hyprctl &>/dev/null; then
    local provider
    provider="$(hyprctl -j status 2>/dev/null | jq -r '.configProvider // "unknown"')"
    if [[ "$provider" != "lua" ]]; then
      echo "[WARN] Active configProvider is '$provider' (expected 'lua'). Did you relogin?" >&2
    fi
  fi
}

# ---------------------------------------------------------------------------
# Step 7: Systemd & Strict Verification (D-11, D-23, BOOT-04)
# ---------------------------------------------------------------------------
step_verify() {
  echo "[STEP 7/7] Activating systemd capture timer and running strict verification..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] systemctl --user daemon-reload"
    echo "[DRY-RUN] systemctl --user --now enable dotfiles-capture.timer"
    echo "[DRY-RUN] $REPO_ROOT/arch/dots-hyprland.sh verify --strict"
    return 0
  fi

  if command -v systemctl &>/dev/null; then
    echo "[SYSTEMD] Reloading user systemd daemon..."
    systemctl --user daemon-reload 2>/dev/null || true
    echo "[SYSTEMD] Enabling and starting dotfiles-capture.timer..."
    systemctl --user --now enable dotfiles-capture.timer 2>/dev/null || true
    if ! systemctl --user is-active --quiet dotfiles-capture.timer 2>/dev/null; then
      echo "[WARN] dotfiles-capture.timer is not active (user D-Bus session may be unavailable)." >&2
    else
      echo "[PASS] dotfiles-capture.timer is active."
    fi
  fi

  echo "[VERIFY] Running strict repository verification..."
  local verify_rc=0
  "$REPO_ROOT/arch/dots-hyprland.sh" verify --strict || verify_rc=$?
  if [[ "$verify_rc" -ne 0 ]]; then
    echo "[FAIL] Strict verification failed with exit code $verify_rc." >&2
  else
    echo "[PASS] Strict verification passed with 0 findings."
  fi
  return "$verify_rc"
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
  parse_args "$@"
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

  # Two-Stage Execution Boundary across Relogin (D-08, D-09)
  if [[ -z "$ONLY_STEP" && "$(get_stage)" -eq 1 ]]; then
    set_stage 2
    show_relogin_banner
    if [[ "$NO_PAUSE" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
      echo "[INFO] Pausing for session relogin. Run ./bootstrap.sh after logging back in."
      exit 0
    fi
  fi

  probe_session_environment
  execute_step "verify" step_verify

  echo "[DONE] Bootstrap pipeline execution complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
