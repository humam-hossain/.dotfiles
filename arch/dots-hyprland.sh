#!/usr/bin/env bash
set -euo pipefail

# arch/dots-hyprland.sh — thin wrapper around vendor/dots-hyprland/./setup
# Pattern: arch/waybar.sh / arch/*.sh (REPO_ROOT, main dispatcher, [LABEL] echos).
# Divergence: no package arrays; delegates install logic to upstream setup.
# Uninstall/protect are wrapper-owned (safe) — do NOT call upstream ./setup uninstall.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
II_ROOT="$REPO_ROOT/vendor/dots-hyprland"
SETUP="$II_ROOT/setup"
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)
# install* → upstream ./setup; uninstall/protect → wrapper-owned safe path
ALLOWLIST=(install install-deps install-setups install-files uninstall protect)

# XDG defaults (match upstream environment-variables.sh)
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
II_CONFDIR="${XDG_CONFIG_HOME}/illogical-impulse"
II_BACKUP_DIR="${BACKUP_DIR:-$HOME/ii-original-dots-backup}"

usage() {
  cat <<'EOF'
arch/dots-hyprland.sh — thin wrapper for vendor/dots-hyprland/./setup

Usage:
  arch/dots-hyprland.sh <install|install-deps|install-setups|install-files> [flags…]
  arch/dots-hyprland.sh uninstall [flags…]
  arch/dots-hyprland.sh protect [flags…]
  arch/dots-hyprland.sh help|-h|--help

Allowlisted subcommands:
  install          Full upstream pipeline (deps + setups + files)
  install-deps     Dependencies only
  install-setups   Setup steps only
  install-files    File install only
  uninstall        Safe dual-run uninstall (wrapper-owned; see below)
  protect          Re-mark personal-stack pkgs explicit; optional reinstall missing

Safe defaults (injected for install and install-files only):
  --core --skip-hyprland --skip-sysupdate
  Protects personal hyprland.conf (full --skip-hyprland, not entry-only).
  Skips unattended full system package upgrade. install-deps / install-setups get no injection.
  Never auto-injects --force or --skip-allgreeting.
  After install / install-deps succeed, re-marks PROTECT_EXPLICIT packages as --asexplicit
  (ii install demotes shared deps via --asdeps / implicitize_old_dependencies).

Backup gate (install and install-files only):
  Interactive confirmation required before files-touching paths (type yes).
  Upstream backup dir: ~/ii-original-dots-backup
  Quickshell config will be overwritten; hyprland.conf kept via --skip-hyprland.
  Do NOT pass --skip-backup on first adoption.
  Bare --skip-backup is refused unless also passing --allow-skip-backup.

Uninstall (SAFE — default; does NOT call upstream ./setup uninstall):
  Removes only illogical-impulse-* meta packages with pacman -R (no -s cascade).
  Re-marks personal dual-run stack packages as explicit (pacman -D --asexplicit) so a later
  orphan cleanup (yay -Yc / pacman -Rsu / pacman -Rns \$(pacman -Qtdq)) cannot delete
  hyprland, kitty, starship, bc, jq, cliphist, etc. that ii install demoted to --asdeps.
  Optionally removes ii-owned configs/state (quickshell ii tree, illogical-impulse conf, venv).
  Stops running qs/quickshell processes (otherwise the top bar stays up after files are gone).
  Deletes personal hypr hooks (exec-once = qs -c ii and ILLOGICAL_IMPULSE_VIRTUAL_ENV)
  in ~/.config/hypr and REPO .config/hypr so login does not error after uninstall.
  NEVER deletes ~/.config/hypr trees, hyprland/hyprlock packages, fish/kitty/starship,
  group memberships, or /etc modules. NEVER runs yay -Rns or orphan auto-remove.
  Why: upstream ./setup uninstall uses yay -Rns on meta pkgs (incl. illogical-impulse-hyprland)
  and will cascade-delete packages that install marked asdeps (fish/starship/… and sometimes hyprland).
  Even pacman -R alone is not enough if you later clean orphans — protect-list re-marking is required.

  uninstall flags:
    --dry-run         Print plan only; change nothing
    --packages-only   Meta packages only; leave configs/state
    --configs-only    Configs/state only; leave packages
    --keep-venv       Keep ~/.local/state/quickshell/.venv
    --keep-hypr-hooks Leave qs -c ii / ILLOGICAL_IMPULSE env lines active (default: delete them)
    --skip-protect    Do NOT re-mark personal-stack packages as explicit (not recommended)
    --upstream-dangerous
                      Run vendor ./setup uninstall as-is (WILL cascade packages / groups).
                      Requires typing: UPSTREAM-UNINSTALL

Protect (SAFE — heal asdeps / restore cascade damage; no ii uninstall):
  Re-marks PROTECT_EXPLICIT personal dual-run packages as pacman --asexplicit.
  Use after ii install (deps demoted to asdeps) or after a bad orphan cleanup.
  With --install-missing, also pacman -S --needed any protect-list packages that
  are not installed (restores hyprland/kitty/bc/jq/… wiped by yay -Yc / -Rsu).

  protect flags:
    --dry-run           Print plan only; change nothing
    --install-missing   Install missing protect-list packages, then re-mark explicit

Wrapper-owned meta flags (stripped; never forwarded to ./setup):
  --dry-run              Print would-exec argv and exit 0
  --allow-skip-backup    Explicit override for --skip-backup policy

Examples:
  ./arch/dots-hyprland.sh install
  ./arch/dots-hyprland.sh install-deps
  ./arch/dots-hyprland.sh install-files --exp-files
  ./arch/dots-hyprland.sh install-deps --dry-run
  printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run
  ./arch/dots-hyprland.sh uninstall --dry-run
  ./arch/dots-hyprland.sh uninstall
  ./arch/dots-hyprland.sh uninstall --packages-only
  ./arch/dots-hyprland.sh uninstall --dry-run --skip-protect
  ./arch/dots-hyprland.sh protect --dry-run
  ./arch/dots-hyprland.sh protect
  ./arch/dots-hyprland.sh protect --install-missing

Other setup subcommands (exp-update, exp-merge, virtmon, …):
  Use vendor/dots-hyprland/./setup directly.

Note: once defaults inject --skip-hyprland there is no upstream undo flag.
Full hypr install requires calling vendor/dots-hyprland/./setup outside this wrapper.
EOF
}

is_allowlisted() {
  local s="$1" a
  for a in "${ALLOWLIST[@]}"; do
    [[ "$s" == "$a" ]] && return 0
  done
  return 1
}

# D-05: defaults only for files-touching install paths.
needs_safe_defaults() {
  case "$1" in
    install|install-files) return 0 ;;
    *) return 1 ;;
  esac
}

# D-14 / D-15: require initialized submodule + executable setup; never auto-fix.
preflight() {
  if [[ ! -e "$II_ROOT/.git" ]]; then
    echo "[FAIL] vendor/dots-hyprland is not an initialized submodule (missing .git)." >&2
    echo "[FAIL] Fix (from REPO_ROOT): git submodule update --init --recursive" >&2
    exit 1
  fi
  if [[ ! -x "$SETUP" ]]; then
    echo "[FAIL] $SETUP missing or not executable." >&2
    echo "[FAIL] Fix: git submodule update --init --recursive && chmod +x vendor/dots-hyprland/setup" >&2
    exit 1
  fi
}

# D-11 / D-13: hard interactive gate for install / install-files.
# Optional arg: full=0|1 (Phase 12). Safe-path residual note only when full==0 so
# full dry-run output does not claim skip-hyprland protection (Pitfall 5 / FULL-01 greps).
# Full-specific D-07 blast-radius messaging is expanded in plan 12-02.
backup_gate() {
  local full="${1:-0}"
  echo "[CONFIG] Upstream may backup clashing paths to: ~/ii-original-dots-backup"
  echo "[CONFIG] install-files will overwrite ~/.config/quickshell (Quickshell tree / rsync --delete)."
  if ((full == 0)); then
    echo "[CONFIG] Defaults include --skip-hyprland so personal hyprland.conf is not renamed."
  else
    # Avoid residual flag tokens here — full path injects none (D-03); 12-02 expands themes.
    echo "[CONFIG] Full profile path: no residual safe defaults on this path."
  fi
  echo "[CONFIG] Do NOT pass --skip-backup on first adoption."
  local ans
  read -r -p "Type 'yes' to continue: " ans
  if [[ "$ans" != "yes" ]]; then
    echo "[FAIL] Aborted (backup gate). No ./setup invoked." >&2
    exit 1
  fi
}

# True when user args are solely subcommand help (-h / --help) — skip gate (D-11).
is_help_only_user_flags() {
  local -n _flags=$1
  local f
  if ((${#_flags[@]} == 0)); then
    return 1
  fi
  for f in "${_flags[@]}"; do
    case "$f" in
      -h|--help) ;;
      *) return 1 ;;
    esac
  done
  return 0
}

user_flags_contain() {
  local needle="$1"
  local -n _flags=$2
  local f
  for f in "${_flags[@]}"; do
    [[ "$f" == "$needle" ]] && return 0
  done
  return 1
}

# ---------------------------------------------------------------------------
# Safe uninstall (wrapper-owned)
# ---------------------------------------------------------------------------

# Personal dual-run / arch/*.sh packages that ii install often demotes to --asdeps
# (via yay --asdeps on meta depends + implicitize_old_dependencies). After meta
# removal they become orphans; yay -Yc / pacman -Rsu then deletes them — including
# hyprland. Re-mark as explicit during safe uninstall so orphan cleanup is safe.
# Keep curated (session + shared tools), not every package ever installed by arch/.
PROTECT_EXPLICIT=(
  # Compositor / session (arch/hyprland.sh)
  hyprland
  hyprland-protocols
  hyprpaper
  hyprshot
  hyprlock
  hypridle
  hyprpicker
  hyprsunset
  xdg-desktop-portal
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  xdg-desktop-portal-wlr
  wl-clipboard
  cliphist
  ddcutil
  brightnessctl
  blueman
  dnsmasq
  # Bar dual-run (arch/waybar.sh) — bc/jq used by waybar scripts
  waybar
  curl
  jq
  bc
  python
  iputils
  playerctl
  pavucontrol
  networkmanager
  btop
  nautilus
  kitty
  swaync
  # Shells / prompt (arch/fish.sh, arch/zsh.sh)
  fish
  starship
  eza
  zsh
  # ii-basic / shared CLI tools also used outside ii
  ripgrep
  wget
  rsync
  cmake
  coreutils
  xdg-user-dirs
  git
  fd
  fzf
  neovim
  # Audio stack personal (arch/audio.sh) — often pulled as ii deps
  pipewire
  pipewire-pulse
  pipewire-alsa
  wireplumber
  # Bluetooth (arch/bluetooth.sh) — session-adjacent
  bluez
  bluez-utils
  # Fonts that personal + ii both reference
  ttf-jetbrains-mono-nerd
  ttf-font-awesome
  woff2-font-awesome
  ttf-material-symbols-variable
  noto-fonts
  noto-fonts-emoji
)

# Print array elements one per line; no-op on empty (avoids set -u / bare printf issues).
print_lines() {
  local -n _arr=$1
  local _e
  for _e in "${_arr[@]+"${_arr[@]}"}"; do
    printf '%s\n' "$_e"
  done
}

# Resolve a protect-list name → the real installed package name.
# pacman -Qq resolves Provides transparently ("ttf-font-awesome" → "woff2-font-awesome")
# but pacman -D needs the real name. pacman -Q prints "realname version" always.
resolve_real_package_name() {
  local name="$1"
  local line
  line="$(pacman -Q "$name" 2>/dev/null)" || return 1
  # Extract the first field (package name)
  printf '%s\n' "${line%% *}"
}

# Installed members of PROTECT_EXPLICIT — resolved to real package names, deduplicated.
collect_installed_protect_packages() {
  local -a present=()
  local p real
  for p in "${PROTECT_EXPLICIT[@]}"; do
    if real="$(resolve_real_package_name "$p")"; then
      present+=("$real")
    fi
  done
  # Deduplicate (two protect entries can map to same real pkg, e.g.
  # ttf-font-awesome + woff2-font-awesome both resolve to woff2-font-awesome).
  if ((${#present[@]} > 0)); then
    printf '%s\n' "${present[@]}" | sort -u
  fi
}

# Protect-list packages that are NOT currently installed.
collect_missing_protect_packages() {
  local -a missing=()
  local p
  for p in "${PROTECT_EXPLICIT[@]}"; do
    if ! pacman -Qq "$p" &>/dev/null; then
      missing+=("$p")
    fi
  done
  print_lines missing
}

# Re-mark personal-stack packages as explicitly installed so they are not orphans.
# Must run while packages are still present (before or after meta -R; -R does not
# remove these). Idempotent on already-explicit packages.
# Uses per-package pacman -D so one failure (e.g. virtual/provide name that slipped
# past resolve, or a package group) does not abort the entire batch under set -e.
# label: log prefix (UNINSTALL / PROTECT).
protect_explicit_packages() {
  local dry_run="${1:-0}"
  local label="${2:-UNINSTALL}"
  local -a present=()
  local line
  while IFS= read -r line; do
    [[ -n "$line" ]] && present+=("$line")
  done < <(collect_installed_protect_packages)

  if ((${#present[@]} == 0)); then
    echo "[$label] Protect-list: no listed personal-stack packages are installed."
    return 0
  fi

  if ((dry_run)); then
    echo "[CONFIG] dry-run: would re-mark as explicit (survives yay -Yc / pacman -Rsu):"
    printf '[CONFIG] dry-run:   %s\n' "${present[@]}"
    return 0
  fi

  echo "[$label] Re-marking personal-stack packages as explicit (anti-orphan):"
  printf '  - %s\n' "${present[@]}"

  local -a failed=()
  local pkg
  for pkg in "${present[@]}"; do
    if ! sudo pacman -D --asexplicit -- "$pkg" 2>/dev/null; then
      failed+=("$pkg")
      echo "[$label] WARNING: failed to mark explicit: $pkg" >&2
    fi
  done

  if ((${#failed[@]} > 0)); then
    echo "[$label] WARNING: ${#failed[@]} package(s) could not be marked explicit:" >&2
    printf '  - %s\n' "${failed[@]}" >&2
    echo "[$label] Continuing — remaining packages were marked successfully."
    return 1
  fi
  echo "[$label] All protect-list packages are now explicit; orphan cleanup will not remove them."
}

# Install missing protect-list packages (restore after cascade orphan cleanup).
install_missing_protect_packages() {
  local dry_run="${1:-0}"
  local -a missing=()
  local line
  while IFS= read -r line; do
    [[ -n "$line" ]] && missing+=("$line")
  done < <(collect_missing_protect_packages)

  if ((${#missing[@]} == 0)); then
    echo "[PROTECT] install-missing: all protect-list packages already installed."
    return 0
  fi

  if ((dry_run)); then
    echo "[CONFIG] dry-run: would install missing protect-list packages (${#missing[@]}):"
    printf '[CONFIG] dry-run:   %s\n' "${missing[@]}"
    echo "[CONFIG] dry-run: would run: sudo pacman -Sy --noconfirm --needed -- ${missing[*]}"
    return 0
  fi

  echo "[PROTECT] Installing missing protect-list packages (${#missing[@]}):"
  printf '  - %s\n' "${missing[@]}"
  sudo pacman -Sy --noconfirm --needed -- "${missing[@]}"
  echo "[PROTECT] Missing protect-list packages installed."
}

# Standalone protect subcommand: optional reinstall + asexplicit heal.
run_protect() {
  local dry_run=0
  local install_missing=0
  local -a unknown=()
  local arg

  for arg in "$@"; do
    case "$arg" in
      -h|--help)
        usage
        exit 0
        ;;
      --dry-run)
        dry_run=1
        ;;
      --install-missing)
        install_missing=1
        ;;
      *)
        unknown+=("$arg")
        ;;
    esac
  done

  if ((${#unknown[@]} > 0)); then
    echo "[FAIL] Unknown protect flag(s): ${unknown[*]}" >&2
    echo "[FAIL] See: ./arch/dots-hyprland.sh help" >&2
    exit 1
  fi

  if ((dry_run)); then
    echo "[CONFIG] dry-run: protect plan (no changes)"
  else
    echo "[PROTECT] Personal dual-run stack protect (wrapper-owned)."
    echo "[PROTECT] Re-marks packages explicit so yay -Yc / pacman -Rsu cannot delete them."
  fi

  if ((install_missing == 1)); then
    install_missing_protect_packages "$dry_run"
  else
    local -a missing=()
    local line
    while IFS= read -r line; do
      [[ -n "$line" ]] && missing+=("$line")
    done < <(collect_missing_protect_packages)
    if ((${#missing[@]} > 0)); then
      echo "[PROTECT] ${#missing[@]} protect-list package(s) not installed (e.g. wiped by orphan cleanup)."
      echo "[PROTECT] Re-run with --install-missing to restore, or: ./arch/hyprland.sh / waybar.sh / fish.sh"
      printf '  - %s\n' "${missing[@]}"
    fi
  fi

  protect_explicit_packages "$dry_run" "PROTECT"

  if ((dry_run == 0)); then
    echo
    echo "[DONE] Protect finished."
    if pacman -Qq hyprland &>/dev/null; then
      echo "[DONE] hyprland installed: $(pacman -Q hyprland 2>/dev/null)"
    else
      echo "[WARN] hyprland still missing — run: ./arch/dots-hyprland.sh protect --install-missing" >&2
    fi
    echo "[DONE] Do NOT auto-clean orphans: avoid  yay -Yc  and  pacman -Rns \$(pacman -Qtdq)"
  fi
}

# Collect installed illogical-impulse-* meta packages (and optional plasma-browser-integration
# only if it is present — install with --core skips it, but older runs may have it).
collect_ii_meta_packages() {
  local -a pkgs=()
  local p
  while IFS= read -r p; do
    [[ -n "$p" ]] && pkgs+=("$p")
  done < <(pacman -Qq 2>/dev/null | grep -E '^illogical-impulse-' || true)
  # Only remove plasma-browser-integration if nothing else requires it later — we still
  # use -R without -s so its deps stay. Skip if not installed.
  if pacman -Qq plasma-browser-integration &>/dev/null; then
    # Heuristic: only auto-include when an ii meta pkg set is present (ii-related install).
    if ((${#pkgs[@]} > 0)); then
      pkgs+=(plasma-browser-integration)
    fi
  fi
  print_lines pkgs
}

# Paths safe to remove when they look like ii-owned installs.
# Never includes ~/.config/hypr (personal; install used --skip-hyprland).
collect_ii_config_targets() {
  local -a targets=()
  local qs="${XDG_CONFIG_HOME}/quickshell"
  # Signature of stock ii install-files (LIVE-01)
  if [[ -f "$qs/ii/shell.qml" ]] || [[ -d "$qs/ii" ]]; then
    targets+=("$qs")
  fi
  if [[ -d "$II_CONFDIR" ]]; then
    targets+=("$II_CONFDIR")
  fi
  # Google Sans Flex + any other ii-prefixed font dirs from upstream 3.files.sh
  local f
  shopt -s nullglob
  for f in "${XDG_DATA_HOME}"/fonts/illogical-impulse-*; do
    targets+=("$f")
  done
  # Icon dropped by install-files (see installed_listfile)
  for f in \
    "${XDG_DATA_HOME}/icons/illogical-impulse.svg" \
    "${XDG_DATA_HOME}/icons/illogical-impulse.png"
  do
    [[ -e "$f" ]] && targets+=("$f")
  done
  shopt -u nullglob
  print_lines targets
}

collect_ii_state_targets() {
  local -a targets=()
  local st="${XDG_STATE_HOME}/quickshell"
  # Whole state dir if present (states.json, user/, .venv). --keep-venv handled by caller.
  if [[ -d "$st" ]]; then
    targets+=("$st")
  fi
  print_lines targets
}

# Collect PIDs of this user's qs/quickshell shells via /proc (no pgrep -f).
# Handles live binaries and deleted-binary zombies still mapped in memory.
# IMPORTANT: match argv0 / comm / exe basename only — never substring-search the
# full cmdline (that false-positives on shells/editors whose args mention "qs -c").
collect_qs_pids() {
  local uid
  uid="$(id -u)"
  local proc pid cmdline exe comm owner exe_base argv0
  for proc in /proc/[0-9]*; do
    pid="${proc##*/}"
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    [[ "$pid" == "$$" ]] && continue
    # Owner must be current user
    owner="$(stat -c '%u' "$proc" 2>/dev/null || true)"
    [[ "$owner" == "$uid" ]] || continue

    comm="$(cat "$proc/comm" 2>/dev/null || true)"
    if [[ "$comm" == "qs" || "$comm" == "quickshell" ]]; then
      printf '%s\n' "$pid"
      continue
    fi

    exe="$(readlink "$proc/exe" 2>/dev/null || true)"
    # readlink may yield: /usr/bin/quickshell  or  /usr/bin/quickshell (deleted)
    exe_base="${exe% (deleted)}"
    exe_base="${exe_base##*/}"
    if [[ "$exe_base" == "qs" || "$exe_base" == "quickshell" ]]; then
      printf '%s\n' "$pid"
      continue
    fi

    cmdline=""
    if [[ -r "$proc/cmdline" ]]; then
      cmdline="$(tr '\0' ' ' <"$proc/cmdline" 2>/dev/null || true)"
      cmdline="${cmdline%"${cmdline##*[![:space:]]}"}" # rtrim
    fi
    # First argv only (e.g. "qs -c ii" → qs; "/usr/bin/qs -c ii" → qs)
    argv0="${cmdline%% *}"
    argv0="${argv0##*/}"
    if [[ "$argv0" == "qs" || "$argv0" == "quickshell" ]]; then
      printf '%s\n' "$pid"
      continue
    fi
  done
}

# Stop live qs/quickshell processes so the bar does not keep running after files/pkgs go away.
# Uninstall removes the binary from disk, but an already-started process stays resident
# (Linux shows exe as "/usr/bin/quickshell (deleted)") until killed.
stop_running_qs() {
  local dry_run="${1:-0}"
  local -a uniq=()
  local -A seen=()
  local pid cmd

  while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    [[ -n "${seen[$pid]:-}" ]] && continue
    seen[$pid]=1
    uniq+=("$pid")
  done < <(collect_qs_pids)

  if ((${#uniq[@]} == 0)); then
    echo "[UNINSTALL] No running qs/quickshell processes to stop."
    return 0
  fi

  if ((dry_run)); then
    echo "[CONFIG] dry-run: would stop qs/quickshell PIDs: ${uniq[*]}"
    for pid in "${uniq[@]}"; do
      cmd="$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null || echo '?')"
      echo "[CONFIG] dry-run:   pid=$pid cmd=$cmd"
    done
    return 0
  fi

  echo "[UNINSTALL] Stopping running qs/quickshell (bar stays up until process exits): ${uniq[*]}"
  for pid in "${uniq[@]}"; do
    cmd="$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null || echo '?')"
    echo "[UNINSTALL] SIGTERM pid=$pid ($cmd)"
    kill "$pid" 2>/dev/null || true
  done
  # Brief wait, then SIGKILL stragglers (including deleted-binary zombies)
  local i any
  for i in 1 2 3 4 5; do
    any=0
    for pid in "${uniq[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        any=1
        break
      fi
    done
    ((any == 0)) && break
    sleep 0.2
  done
  for pid in "${uniq[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      echo "[UNINSTALL] SIGKILL pid=$pid"
      kill -9 "$pid" 2>/dev/null || true
    fi
  done
  # State dir may be recreated by the process between rm and kill; clean again.
  if [[ -d "${XDG_STATE_HOME}/quickshell" ]]; then
    echo "[UNINSTALL] Re-cleaning state recreated by live process: ${XDG_STATE_HOME}/quickshell"
    rm -rf -- "${XDG_STATE_HOME}/quickshell"
  fi
}

# Live + repo hyprland.conf targets (deduped by realpath). Enable/disable both so they stay in sync.
list_hypr_ii_hook_target_files() {
  local -a candidates=(
    "${XDG_CONFIG_HOME}/hypr/hyprland.conf"
    "${REPO_ROOT}/.config/hypr/hyprland.conf"
  )
  local f real
  local -A seen=()
  for f in "${candidates[@]}"; do
    [[ -f "$f" ]] || continue
    real="$(realpath "$f" 2>/dev/null || printf '%s' "$f")"
    [[ -n "${seen[$real]:-}" ]] && continue
    seen[$real]=1
    printf '%s\n' "$f"
  done
}

# Conf files under live/repo hypr trees with active ii hooks (any *.conf).
list_active_hypr_ii_hook_files() {
  local -a dirs=(
    "${XDG_CONFIG_HOME}/hypr"
    "${REPO_ROOT}/.config/hypr"
  )
  local d f
  local -A seen=()
  local real
  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      if grep -Eq '^[[:space:]]*exec-once[[:space:]]*=[[:space:]]*qs[[:space:]]+-c[[:space:]]+ii([[:space:]]|$)' "$f" \
        || grep -Eq '^[[:space:]]*env[[:space:]]*=[[:space:]]*ILLOGICAL_IMPULSE_VIRTUAL_ENV' "$f"; then
        real="$(realpath "$f" 2>/dev/null || printf '%s' "$f")"
        [[ -n "${seen[$real]:-}" ]] && continue
        seen[$real]=1
        printf '%s\n' "$f"
      fi
    done < <(find "$d" -type f -name '*.conf' 2>/dev/null || true)
  done
}

# Conf files with active OR leftover commented ii hooks (old uninstall style).
list_any_hypr_ii_hook_files() {
  local -a dirs=(
    "${XDG_CONFIG_HOME}/hypr"
    "${REPO_ROOT}/.config/hypr"
  )
  local d f real
  local -A seen=()
  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      if grep -Eq '^[[:space:]]*(#[[:space:]]*)?exec-once[[:space:]]*=[[:space:]]*qs[[:space:]]+-c[[:space:]]+ii' "$f" \
        || grep -Eq '^[[:space:]]*(#[[:space:]]*)?env[[:space:]]*=[[:space:]]*ILLOGICAL_IMPULSE_VIRTUAL_ENV' "$f"; then
        real="$(realpath "$f" 2>/dev/null || printf '%s' "$f")"
        [[ -n "${seen[$real]:-}" ]] && continue
        seen[$real]=1
        printf '%s\n' "$f"
      fi
    done < <(find "$d" -type f -name '*.conf' 2>/dev/null || true)
  done
}

file_has_active_ii_hooks() {
  local f="$1"
  grep -Eq '^[[:space:]]*exec-once[[:space:]]*=[[:space:]]*qs[[:space:]]+-c[[:space:]]+ii([[:space:]]|$)' "$f" \
    && grep -Eq '^[[:space:]]*env[[:space:]]*=[[:space:]]*ILLOGICAL_IMPULSE_VIRTUAL_ENV' "$f"
}

file_has_commented_ii_hooks() {
  local f="$1"
  grep -Eq '^[[:space:]]*#[[:space:]]*exec-once[[:space:]]*=[[:space:]]*qs[[:space:]]+-c[[:space:]]+ii' "$f" \
    || grep -Eq '^[[:space:]]*#[[:space:]]*env[[:space:]]*=[[:space:]]*ILLOGICAL_IMPULSE_VIRTUAL_ENV' "$f"
}

# Personal hypr still references ii — warn only (used with --keep-hypr-hooks).
warn_hypr_ii_hooks() {
  local -a hits=()
  local f
  while IFS= read -r f; do
    [[ -n "$f" ]] && hits+=("$f")
  done < <(list_active_hypr_ii_hook_files)
  if ((${#hits[@]} > 0)); then
    echo "[WARN] Hyprland still has active ii hooks:" >&2
    local h
    for h in "${hits[@]}"; do
      echo "[WARN]   $h" >&2
      grep -En '^[[:space:]]*exec-once[[:space:]]*=[[:space:]]*qs[[:space:]]+-c[[:space:]]+ii|^[[:space:]]*env[[:space:]]*=[[:space:]]*ILLOGICAL_IMPULSE_VIRTUAL_ENV' "$h" 2>/dev/null \
        | head -5 \
        | while IFS= read -r gl; do echo "[WARN]     $gl" >&2; done
    done
    echo "[WARN] Re-run without --keep-hypr-hooks, or delete those lines, to avoid login errors." >&2
  fi
}

# Delete active + leftover commented ii hooks in live + repo hypr confs (does not delete hypr trees).
disable_hypr_ii_hooks() {
  local dry_run="${1:-0}"
  local -a files=()
  local f
  while IFS= read -r f; do
    [[ -n "$f" ]] && files+=("$f")
  done < <(list_any_hypr_ii_hook_files)

  if ((${#files[@]} == 0)); then
    echo "[UNINSTALL] No hypr ii hooks to disable."
    return 0
  fi

  if ((dry_run)); then
    echo "[CONFIG] dry-run: would delete ii hooks in:"
    printf '[CONFIG] dry-run:   %s\n' "${files[@]}"
    return 0
  fi

  local tmp
  for f in "${files[@]}"; do
    tmp="$(mktemp)"
    # Drop active and commented ii hooks (old uninstall left "# … # disabled by …").
    # shellcheck disable=SC2016
    awk '
      /^[[:space:]]*(#[[:space:]]*)?exec-once[[:space:]]*=[[:space:]]*qs[[:space:]]+-c[[:space:]]+ii/ { next }
      /^[[:space:]]*(#[[:space:]]*)?env[[:space:]]*=[[:space:]]*ILLOGICAL_IMPULSE_VIRTUAL_ENV/ { next }
      { print }
    ' "$f" >"$tmp"
    if ! cmp -s "$f" "$tmp"; then
      cat "$tmp" >"$f"
      echo "[UNINSTALL] Deleted ii hooks in: $f"
    fi
    rm -f -- "$tmp"
  done
}

# Ensure active ii hooks in live + repo hyprland.conf.
# - Uncomments leftover "# exec-once / # env" lines from older uninstall style
# - Dedupes duplicates
# - Inserts missing lines before ### LOOK AND FEEL ### (appends if marker absent)
# - Verifies both hooks are active after write (never claims success on comments alone)
enable_hypr_ii_hooks() {
  local dry_run="${1:-0}"
  local -a files=()
  local f
  while IFS= read -r f; do
    [[ -n "$f" ]] && files+=("$f")
  done < <(list_hypr_ii_hook_target_files)

  if ((${#files[@]} == 0)); then
    echo "[INSTALL] No hyprland.conf found to enable ii hooks."
    return 0
  fi

  local needs_work=0
  for f in "${files[@]}"; do
    if ! file_has_active_ii_hooks "$f" || file_has_commented_ii_hooks "$f"; then
      needs_work=1
      break
    fi
  done

  if ((needs_work == 0)); then
    if ((dry_run)); then
      echo "[CONFIG] dry-run: ii hooks already active (no change):"
      printf '[CONFIG] dry-run:   %s\n' "${files[@]}"
    else
      echo "[INSTALL] ii hooks already active:"
      printf '[INSTALL]   %s\n' "${files[@]}"
    fi
    return 0
  fi

  if ((dry_run)); then
    echo "[CONFIG] dry-run: would enable ii hooks (uncomment/insert) in:"
    printf '[CONFIG] dry-run:   %s\n' "${files[@]}"
    return 0
  fi

  local tmp exec_line env_line
  exec_line='exec-once = qs -c ii'
  env_line='env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv'

  for f in "${files[@]}"; do
    tmp="$(mktemp)"
    # shellcheck disable=SC2016
    awk -v exec_line="$exec_line" -v env_line="$env_line" '
      function is_active_exec(line) {
        return line ~ /^[[:space:]]*exec-once[[:space:]]*=[[:space:]]*qs[[:space:]]+-c[[:space:]]+ii([[:space:]]|$)/
      }
      function is_active_env(line) {
        return line ~ /^[[:space:]]*env[[:space:]]*=[[:space:]]*ILLOGICAL_IMPULSE_VIRTUAL_ENV/
      }
      function is_commented_exec(line) {
        return line ~ /^[[:space:]]*#[[:space:]]*exec-once[[:space:]]*=[[:space:]]*qs[[:space:]]+-c[[:space:]]+ii/
      }
      function is_commented_env(line) {
        return line ~ /^[[:space:]]*#[[:space:]]*env[[:space:]]*=[[:space:]]*ILLOGICAL_IMPULSE_VIRTUAL_ENV/
      }
      function strip_hook_comment(line,    s) {
        s = line
        sub(/^[[:space:]]*#[[:space:]]*/, "", s)
        sub(/[[:space:]]*#[[:space:]]*disabled by arch\/dots-hyprland\.sh uninstall[[:space:]]*$/, "", s)
        return s
      }
      {
        if (is_commented_exec($0)) {
          if (!seen_exec) {
            print strip_hook_comment($0)
            seen_exec = 1
          }
          next
        }
        if (is_commented_env($0)) {
          if (!seen_env) {
            print strip_hook_comment($0)
            seen_env = 1
          }
          next
        }
        if (is_active_exec($0)) {
          if (!seen_exec) {
            print
            seen_exec = 1
          }
          next
        }
        if (is_active_env($0)) {
          if (!seen_env) {
            print
            seen_env = 1
          }
          next
        }
        if ($0 ~ /^### LOOK AND FEEL ###/) {
          if (!seen_exec) {
            print exec_line
            seen_exec = 1
          }
          if (!seen_env) {
            print env_line
            seen_env = 1
          }
          print
          next
        }
        print
      }
      END {
        if (!seen_exec) print exec_line
        if (!seen_env) print env_line
      }
    ' "$f" >"$tmp"

    if ! cmp -s "$f" "$tmp"; then
      cat "$tmp" >"$f"
    fi
    rm -f -- "$tmp"

    if file_has_active_ii_hooks "$f"; then
      # Refuse success if any ii hook line is still commented.
      if file_has_commented_ii_hooks "$f"; then
        echo "[WARN] ii hooks partially enabled (commented leftovers remain) in: $f" >&2
        grep -En '^[[:space:]]*#[[:space:]]*(exec-once[[:space:]]*=[[:space:]]*qs[[:space:]]+-c[[:space:]]+ii|env[[:space:]]*=[[:space:]]*ILLOGICAL_IMPULSE_VIRTUAL_ENV)' "$f" 2>/dev/null \
          | head -5 \
          | while IFS= read -r gl; do echo "[WARN]   $gl" >&2; done
      else
        echo "[INSTALL] Enabled ii hooks in: $f"
      fi
      grep -En '^[[:space:]]*exec-once[[:space:]]*=[[:space:]]*qs[[:space:]]+-c[[:space:]]+ii|^[[:space:]]*env[[:space:]]*=[[:space:]]*ILLOGICAL_IMPULSE_VIRTUAL_ENV' "$f" 2>/dev/null \
        | head -5 \
        | while IFS= read -r gl; do echo "[INSTALL]   $gl"; done
    else
      echo "[WARN] Failed to enable active ii hooks in: $f" >&2
      grep -Eq '^[[:space:]]*exec-once[[:space:]]*=[[:space:]]*qs[[:space:]]+-c[[:space:]]+ii([[:space:]]|$)' "$f" \
        || echo "[WARN]   missing: exec-once = qs -c ii" >&2
      grep -Eq '^[[:space:]]*env[[:space:]]*=[[:space:]]*ILLOGICAL_IMPULSE_VIRTUAL_ENV' "$f" \
        || echo "[WARN]   missing: env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv" >&2
      if file_has_commented_ii_hooks "$f"; then
        echo "[WARN]   commented ii hook lines still present (uncomment failed):" >&2
        grep -En '^[[:space:]]*#[[:space:]]*(exec-once[[:space:]]*=[[:space:]]*qs[[:space:]]+-c[[:space:]]+ii|env[[:space:]]*=[[:space:]]*ILLOGICAL_IMPULSE_VIRTUAL_ENV)' "$f" 2>/dev/null \
          | head -5 \
          | while IFS= read -r gl; do echo "[WARN]     $gl" >&2; done
      fi
    fi
  done
}

uninstall_gate() {
  local packages_only="$1"
  local configs_only="$2"
  local keep_venv="$3"
  local keep_hypr_hooks="$4"
  local skip_protect="$5"
  local -a pkgs=()
  local -a cfgs=()
  local -a states=()
  local -a hook_files=()
  local -a protect=()
  local line

  while IFS= read -r line; do
    [[ -n "$line" ]] && pkgs+=("$line")
  done < <(collect_ii_meta_packages)

  while IFS= read -r line; do
    [[ -n "$line" ]] && cfgs+=("$line")
  done < <(collect_ii_config_targets)

  while IFS= read -r line; do
    [[ -n "$line" ]] && states+=("$line")
  done < <(collect_ii_state_targets)

  while IFS= read -r line; do
    [[ -n "$line" ]] && hook_files+=("$line")
  done < <(list_active_hypr_ii_hook_files)

  while IFS= read -r line; do
    [[ -n "$line" ]] && protect+=("$line")
  done < <(collect_installed_protect_packages)

  echo "[UNINSTALL] Safe dual-run uninstall (wrapper-owned)."
  echo "[UNINSTALL] This does NOT call upstream ./setup uninstall."
  echo "[UNINSTALL] Upstream uninstall uses yay -Rns and can delete hyprland/fish/starship"
  echo "[UNINSTALL] when those were marked asdeps — that path is NOT used here."
  echo
  echo "[UNINSTALL] WILL NOT touch:"
  echo "  - hyprland / hyprlock / hypridle packages (left installed; re-marked explicit)"
  echo "  - fish / kitty / starship / bc / jq / cliphist and other personal-stack deps"
  echo "  - hypr config trees (no rm of ~/.config/hypr); only deletes qs -c ii / ILLOGICAL env lines"
  echo "  - group memberships (video/i2c/input)"
  echo "  - /etc/modules-load.d/i2c-dev.conf"
  echo "  - never runs yay -Rns or automatic orphan removal"
  echo

  if ((packages_only == 0 && configs_only == 0)) || ((packages_only == 1)); then
    if ((${#pkgs[@]} == 0)); then
      echo "[UNINSTALL] Meta packages: (none installed)"
    else
      echo "[UNINSTALL] Meta packages to remove (pacman -R, no cascade):"
      printf '  - %s\n' "${pkgs[@]}"
    fi
  else
    echo "[UNINSTALL] Meta packages: skipped (--configs-only)"
  fi
  echo

  if ((skip_protect == 1)); then
    echo "[UNINSTALL] Protect-list re-mark: SKIPPED (--skip-protect)"
    echo "[UNINSTALL] WARNING: personal-stack pkgs left as asdeps may be deleted by yay -Yc / pacman -Rsu."
  else
    if ((${#protect[@]} == 0)); then
      echo "[UNINSTALL] Protect-list re-mark: (none of the listed packages are installed)"
    else
      echo "[UNINSTALL] Protect-list: re-mark as explicit before meta removal (${#protect[@]} pkgs):"
      printf '  - %s\n' "${protect[@]}"
    fi
  fi
  echo

  if ((packages_only == 0 && configs_only == 0)) || ((configs_only == 1)); then
    if ((${#cfgs[@]} == 0)); then
      echo "[UNINSTALL] Config targets: (none matched ii signatures)"
    else
      echo "[UNINSTALL] Config targets to remove:"
      printf '  - %s\n' "${cfgs[@]}"
    fi
    if ((keep_venv == 1)); then
      echo "[UNINSTALL] State: will remove ${XDG_STATE_HOME}/quickshell contents except .venv (--keep-venv)"
    else
      if ((${#states[@]} == 0)); then
        echo "[UNINSTALL] State targets: (none)"
      else
        echo "[UNINSTALL] State targets to remove:"
        printf '  - %s\n' "${states[@]}"
      fi
    fi
  else
    echo "[UNINSTALL] Configs/state: skipped (--packages-only)"
  fi
  echo
  echo "[UNINSTALL] Will stop any running qs/quickshell process (otherwise the bar stays up)."
  if ((keep_hypr_hooks == 1)); then
    echo "[UNINSTALL] Hypr ii hooks: kept active (--keep-hypr-hooks)"
    if ((${#hook_files[@]} > 0)); then
      printf '  - %s\n' "${hook_files[@]}"
    fi
  else
    if ((${#hook_files[@]} == 0)); then
      echo "[UNINSTALL] Hypr ii hooks: none active"
    else
      echo "[UNINSTALL] Hypr ii hooks to delete (exec-once qs -c ii / ILLOGICAL_IMPULSE env):"
      printf '  - %s\n' "${hook_files[@]}"
    fi
  fi
  echo
  if [[ -d "$II_BACKUP_DIR" ]]; then
    echo "[UNINSTALL] Install-time backup (if any) still at: $II_BACKUP_DIR"
  fi
  echo "[UNINSTALL] Afterward, optional orphan review (do NOT auto-remove): pacman -Qtdq"
  echo "[UNINSTALL] Do NOT run: yay -Yc   or   pacman -Rns \$(pacman -Qtdq)"
  echo "[UNINSTALL] Those commands cascade-delete asdeps left by ii (bc/jq/hyprland/…)."
  echo
  local ans
  read -r -p "Type 'yes' to continue safe uninstall: " ans
  if [[ "$ans" != "yes" ]]; then
    echo "[FAIL] Aborted (uninstall gate). Nothing changed." >&2
    exit 1
  fi
}

# Remove path if it exists; refuse anything outside $HOME.
safe_rm_path() {
  local path="$1"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    echo "[UNINSTALL] skip (missing): $path"
    return 0
  fi
  case "$path" in
    "$HOME"/*) ;;
    *)
      echo "[FAIL] Refusing to delete path outside \$HOME: $path" >&2
      return 1
      ;;
  esac
  # Extra belt: never hypr
  case "$path" in
    */.config/hypr|*/.config/hypr/*)
      echo "[FAIL] Refusing to delete hypr path: $path" >&2
      return 1
      ;;
  esac
  echo "[UNINSTALL] rm -rf -- $path"
  rm -rf -- "$path"
}

run_safe_uninstall() {
  local dry_run="$1"
  local packages_only="$2"
  local configs_only="$3"
  local keep_venv="$4"
  local keep_hypr_hooks="$5"
  local skip_protect="$6"
  local rc=0

  local -a pkgs=()
  local -a cfgs=()
  local -a states=()
  local line

  while IFS= read -r line; do
    [[ -n "$line" ]] && pkgs+=("$line")
  done < <(collect_ii_meta_packages)
  while IFS= read -r line; do
    [[ -n "$line" ]] && cfgs+=("$line")
  done < <(collect_ii_config_targets)
  while IFS= read -r line; do
    [[ -n "$line" ]] && states+=("$line")
  done < <(collect_ii_state_targets)

  if ((dry_run)); then
    echo "[CONFIG] dry-run: safe uninstall plan (no changes)"
    if ((skip_protect == 0)); then
      protect_explicit_packages 1
    else
      echo "[CONFIG] dry-run: would skip protect-list re-mark (--skip-protect)"
    fi
    if ((configs_only == 0)); then
      if ((${#pkgs[@]} > 0)); then
        echo "[CONFIG] dry-run: would run: sudo pacman -R --noconfirm -- ${pkgs[*]}"
      else
        echo "[CONFIG] dry-run: no illogical-impulse-* meta packages to remove"
      fi
    fi
    if ((packages_only == 0)); then
      local t
      for t in "${cfgs[@]+"${cfgs[@]}"}"; do
        echo "[CONFIG] dry-run: would rm -rf -- $t"
      done
      if ((keep_venv == 1)); then
        local st="${XDG_STATE_HOME}/quickshell"
        if [[ -d "$st" ]]; then
          local child
          shopt -s nullglob dotglob
          for child in "$st"/*; do
            [[ "$(basename "$child")" == ".venv" ]] && continue
            echo "[CONFIG] dry-run: would rm -rf -- $child"
          done
          shopt -u nullglob dotglob
        fi
      else
        for t in "${states[@]+"${states[@]}"}"; do
          echo "[CONFIG] dry-run: would rm -rf -- $t"
        done
      fi
    fi
    stop_running_qs 1
    if ((keep_hypr_hooks == 0)); then
      disable_hypr_ii_hooks 1
    else
      echo "[CONFIG] dry-run: would keep hypr ii hooks (--keep-hypr-hooks)"
      warn_hypr_ii_hooks
    fi
    echo "[CONFIG] dry-run: would NOT remove hyprland package or delete ~/.config/hypr"
    echo "[CONFIG] dry-run: would NOT run yay -Rns or pacman -Rsu orphan cleanup"
    exit 0
  fi

  # Stop the live bar FIRST so removing configs/binary does not leave a
  # deleted-binary zombie still drawing chrome (and re-writing state).
  stop_running_qs 0

  # Re-mark personal stack as explicit BEFORE meta removal. ii install demotes
  # these to asdeps; after -R they would be orphans and yay -Yc / pacman -Rsu
  # would delete hyprland, bc, jq, kitty, starship, …
  # Defense-in-depth: partial protect failure must not prevent meta/config cleanup.
  if ((skip_protect == 0)); then
    protect_explicit_packages 0 || {
      echo "[UNINSTALL] WARNING: protect had errors; continuing with meta/config removal." >&2
      rc=1
    }
  else
    echo "[UNINSTALL] Skipping protect-list re-mark (--skip-protect)."
  fi

  # Packages next (so a later config failure still drops meta pkgs if desired)
  if ((configs_only == 0)); then
    if ((${#pkgs[@]} == 0)); then
      echo "[UNINSTALL] No illogical-impulse-* meta packages installed."
    else
      echo "[UNINSTALL] Removing meta packages (no dependency cascade): ${pkgs[*]}"
      # -R only: keeps hyprland/fish/kitty/starship/etc. even if currently asdeps of these metas.
      sudo pacman -R --noconfirm -- "${pkgs[@]}"
    fi
  fi

  local removed_fonts=0
  if ((packages_only == 0)); then
    local t
    for t in "${cfgs[@]+"${cfgs[@]}"}"; do
      case "$t" in
        */fonts/illogical-impulse-*) removed_fonts=1 ;;
      esac
      safe_rm_path "$t"
    done
    if ((keep_venv == 1)); then
      local st="${XDG_STATE_HOME}/quickshell"
      if [[ -d "$st" ]]; then
        local child
        shopt -s nullglob dotglob
        for child in "$st"/*; do
          [[ "$(basename "$child")" == ".venv" ]] && continue
          safe_rm_path "$child"
        done
        shopt -u nullglob dotglob
      fi
    else
      for t in "${states[@]+"${states[@]}"}"; do
        safe_rm_path "$t"
      done
    fi
    if ((removed_fonts == 1)) && command -v fc-cache >/dev/null; then
      echo "[UNINSTALL] Rebuilding font cache after ii font removal…"
      fc-cache -f >/dev/null 2>&1 || true
    fi
  fi

  # Final sweep: kill any straggler, then re-remove configs/state the process may
  # have recreated while it was still alive (seen: config.json + states.json).
  stop_running_qs 0
  if ((packages_only == 0)); then
    local -a again=()
    local line t
    while IFS= read -r line; do
      [[ -n "$line" ]] && again+=("$line")
    done < <(collect_ii_config_targets)
    while IFS= read -r line; do
      [[ -n "$line" ]] && again+=("$line")
    done < <(collect_ii_state_targets)
    for t in "${again[@]+"${again[@]}"}"; do
      if [[ -e "$t" || -L "$t" ]]; then
        echo "[UNINSTALL] Post-stop re-clean (recreated by live process): $t"
        safe_rm_path "$t"
      fi
    done
  fi

  # Disable login hooks last (hypr conf edits; never deletes hypr trees).
  if ((keep_hypr_hooks == 0)); then
    disable_hypr_ii_hooks 0
  else
    warn_hypr_ii_hooks
  fi

  echo
  echo "[DONE] Safe uninstall finished."
  echo "[DONE] Preserved: hyprland stack, ~/.config/hypr tree, and non-meta deps (fish/kitty/…)."
  if ((skip_protect == 0)); then
    echo "[DONE] Personal-stack packages re-marked explicit (bc/jq/hyprland/kitty/… safe from orphan cleanup)."
  fi
  if [[ -d "$II_BACKUP_DIR" ]]; then
    echo "[DONE] Backup (if created at install): $II_BACKUP_DIR"
  fi
  echo "[DONE] Review orphans carefully (do not blind-remove): pacman -Qtdq"
  echo "[DONE] Do NOT auto-clean orphans: avoid  yay -Yc  and  pacman -Rns \$(pacman -Qtdq)"
  if pacman -Qq hyprland &>/dev/null; then
    echo "[DONE] hyprland still installed: $(pacman -Q hyprland 2>/dev/null)"
  else
    echo "[WARN] hyprland is NOT installed (was already missing before this uninstall, or removed outside this script)." >&2
    echo "[WARN] Restore personal session: ./arch/hyprland.sh  (and ./arch/waybar.sh / ./arch/fish.sh / ./arch/kitty.sh as needed)." >&2
  fi
  # Confirm no qs still drawing chrome
  local -a leftover=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && leftover+=("$line")
  done < <(collect_qs_pids)
  if ((${#leftover[@]} > 0)); then
    echo "[WARN] qs/quickshell still running after stop attempts: ${leftover[*]}" >&2
    echo "[WARN] Kill manually: kill ${leftover[*]}" >&2
  else
    echo "[DONE] No qs/quickshell process running."
  fi
  if ((keep_hypr_hooks == 0)); then
    local -a still=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && still+=("$line")
    done < <(list_active_hypr_ii_hook_files)
    if ((${#still[@]} > 0)); then
      echo "[WARN] Active ii hooks still present in: ${still[*]}" >&2
    else
      echo "[DONE] Hypr ii hooks deleted (or were already inactive)."
    fi
  fi

  if ((rc != 0)); then
    echo "[DONE] Safe uninstall completed with warnings (exit 1). Review messages above." >&2
  fi
  return $rc
}

run_upstream_uninstall_dangerous() {
  local dry_run="$1"
  echo "[WARN] ============================================================" >&2
  echo "[WARN] --upstream-dangerous runs vendor ./setup uninstall AS-IS." >&2
  echo "[WARN] That path uses yay -Rns on illogical-impulse-* meta packages." >&2
  echo "[WARN] Cascades can remove hyprland, fish, starship, kitty, fonts, …" >&2
  echo "[WARN] It also tries to drop video/i2c/input groups and i2c-dev.conf." >&2
  echo "[WARN] Prefer default: ./arch/dots-hyprland.sh uninstall" >&2
  echo "[WARN] ============================================================" >&2
  local ans
  read -r -p "Type 'UPSTREAM-UNINSTALL' to proceed: " ans
  if [[ "$ans" != "UPSTREAM-UNINSTALL" ]]; then
    echo "[FAIL] Aborted. Upstream uninstall not run." >&2
    exit 1
  fi
  preflight
  local -a cmd=(./setup uninstall)
  echo "[UNINSTALL] ${cmd[*]}  (cwd=$II_ROOT)"
  if ((dry_run)); then
    echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"
    exit 0
  fi
  (
    cd "$II_ROOT"
    "${cmd[@]}"
  )
}

run_uninstall() {
  local dry_run=0
  local packages_only=0
  local configs_only=0
  local keep_venv=0
  local keep_hypr_hooks=0
  local skip_protect=0
  local upstream_dangerous=0
  local -a unknown=()
  local arg

  for arg in "$@"; do
    case "$arg" in
      -h|--help)
        usage
        exit 0
        ;;
      --dry-run)
        dry_run=1
        ;;
      --packages-only)
        packages_only=1
        ;;
      --configs-only)
        configs_only=1
        ;;
      --keep-venv)
        keep_venv=1
        ;;
      --keep-hypr-hooks)
        keep_hypr_hooks=1
        ;;
      --skip-protect)
        skip_protect=1
        ;;
      --upstream-dangerous)
        upstream_dangerous=1
        ;;
      --allow-skip-backup)
        # harmless if mixed; ignore
        ;;
      *)
        unknown+=("$arg")
        ;;
    esac
  done

  if ((${#unknown[@]} > 0)); then
    echo "[FAIL] Unknown uninstall flag(s): ${unknown[*]}" >&2
    echo "[FAIL] See: ./arch/dots-hyprland.sh help" >&2
    exit 1
  fi
  if ((packages_only == 1 && configs_only == 1)); then
    echo "[FAIL] --packages-only and --configs-only are mutually exclusive." >&2
    exit 1
  fi

  if ((upstream_dangerous == 1)); then
    run_upstream_uninstall_dangerous "$dry_run"
    return
  fi

  # Safe path does not require submodule for package/config cleanup, but warn if missing.
  if [[ ! -e "$II_ROOT/.git" ]]; then
    echo "[CONFIG] Note: vendor/dots-hyprland submodule not initialized; proceeding with local cleanup only."
  fi

  if ((dry_run == 0)); then
    uninstall_gate "$packages_only" "$configs_only" "$keep_venv" "$keep_hypr_hooks" "$skip_protect"
  else
    echo "[CONFIG] dry-run: skipping uninstall gate"
  fi

  run_safe_uninstall "$dry_run" "$packages_only" "$configs_only" "$keep_venv" "$keep_hypr_hooks" "$skip_protect"
}

run_install_family() {
  local subcmd="$1"
  shift

  # Scan remaining args: strip wrapper-owned meta flags; preserve order (WRAP-04)
  local dry_run=0
  local allow_skip_backup=0
  local full=0
  local -a user_flags=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run)
        dry_run=1
        ;;
      --allow-skip-backup)
        allow_skip_backup=1
        ;;
      --full)
        # D-01: wrapper-owned meta; never forward to ./setup
        full=1
        ;;
      *)
        user_flags+=("$arg")
        ;;
    esac
  done

  # D-02: --full only valid on install / install-files (same scope as SAFE_DEFAULTS)
  if ((full == 1)) && ! needs_safe_defaults "$subcmd"; then
    echo "[FAIL] --full is only valid with install or install-files." >&2
    echo "[FAIL] Refusing --full on subcommand: $subcmd" >&2
    exit 1
  fi

  # Preflight before any path that invokes setup (D-14)
  preflight

  # D-12: refuse bare --skip-backup unless --allow-skip-backup (before gate)
  if user_flags_contain "--skip-backup" user_flags && ((allow_skip_backup == 0)); then
    echo "[FAIL] --skip-backup refused without --allow-skip-backup." >&2
    echo "[FAIL] First adoption must not skip backup. Re-run with --allow-skip-backup only if you intentionally override." >&2
    exit 1
  fi

  # Hard backup gate for install / install-files (skip pure -h/--help passthrough)
  # D-08: still runs on --full --dry-run; pass full so messaging does not claim residual protection
  if needs_safe_defaults "$subcmd" && ! is_help_only_user_flags user_flags; then
    backup_gate "$full"
  fi

  # Build argv: ./setup <sub> [SAFE_DEFAULTS…] [user flags…] (D-09)
  # D-03 / FULL-01: when --full, inject nothing from SAFE_DEFAULTS
  # D-05 / FULL-02: when full==0, still inject the triple residual
  local -a cmd=(./setup "$subcmd")
  if needs_safe_defaults "$subcmd" && ((full == 0)); then
    echo "[CONFIG] safe defaults: ${SAFE_DEFAULTS[*]}"
    cmd+=("${SAFE_DEFAULTS[@]}")
  elif needs_safe_defaults "$subcmd" && ((full == 1)); then
    echo "[CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)"
  fi
  if ((${#user_flags[@]} > 0)); then
    cmd+=("${user_flags[@]}")
  fi

  echo "[INSTALL] ${cmd[*]}  (cwd=$II_ROOT)"

  # --dry-run: print would-exec, exit 0 without calling setup (D-16)
  if ((dry_run)); then
    echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"
    # Mirror post-setup work from the real path below (protect + enable).
    case "$subcmd" in
      install|install-deps|install-files)
        echo "[CONFIG] dry-run: after setup, would re-mark protect-list as explicit (ii demotes deps)"
        protect_explicit_packages 1 "PROTECT"
        echo "[CONFIG] dry-run: after setup, would enable ii hooks in live + repo hyprland.conf"
        enable_hypr_ii_hooks 1
        ;;
    esac
    exit 0
  fi

  # Array exec only — never eval a concatenated command string (T-06-04)
  (
    cd "$II_ROOT"
    "${cmd[@]}"
  )

  # ii install-deps marks meta depends with --asdeps and may demote previously
  # explicit personal packages (bc/jq/hyprland/kitty/…) via implicitize_old_dependencies.
  # Re-mark dual-run stack explicit so a later meta -R + yay -Yc cannot wipe them.
  case "$subcmd" in
    install|install-deps|install-files)
      echo "[PROTECT] Post-install: re-marking personal dual-run stack as explicit…"
      protect_explicit_packages 0 "PROTECT" || {
        echo "[PROTECT] WARNING: some packages could not be marked explicit; review above." >&2
      }
      enable_hypr_ii_hooks 0
      ;;
  esac
}

main() {
  # 1) bare / help → wrapper usage, exit 0 (D-02, D-03)
  if [[ $# -eq 0 ]]; then
    usage
    exit 0
  fi
  case "$1" in
    help|-h|--help)
      usage
      exit 0
      ;;
  esac

  # 2) allowlist
  if ! is_allowlisted "$1"; then
    echo "[FAIL] Unknown or non-allowlisted subcommand: $1" >&2
    echo "[FAIL] Allowlisted: ${ALLOWLIST[*]}" >&2
    echo "[FAIL] For other ops use vendor/dots-hyprland/./setup directly." >&2
    exit 1
  fi

  local subcmd="$1"
  shift

  case "$subcmd" in
    uninstall)
      run_uninstall "$@"
      ;;
    protect)
      run_protect "$@"
      ;;
    *)
      run_install_family "$subcmd" "$@"
      ;;
  esac
}

main "$@"
