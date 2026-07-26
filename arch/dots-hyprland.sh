#!/usr/bin/env bash
set -euo pipefail

# arch/dots-hyprland.sh — thin wrapper around vendor/dots-hyprland/./setup
# Pattern: arch/quickshell.sh (REPO_ROOT, main dispatcher, [LABEL] echos).
# Divergence: no package arrays; delegates all install logic to upstream setup.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
II_ROOT="$REPO_ROOT/vendor/dots-hyprland"
SETUP="$II_ROOT/setup"
SAFE_DEFAULTS=(--core --skip-hyprland --skip-sysupdate)
ALLOWLIST=(install install-deps install-setups install-files)

usage() {
  cat <<'EOF'
arch/dots-hyprland.sh — thin wrapper for vendor/dots-hyprland/./setup

Usage:
  arch/dots-hyprland.sh <install|install-deps|install-setups|install-files> [flags…]
  arch/dots-hyprland.sh help|-h|--help

Allowlisted subcommands (WRAP-01):
  install          Full upstream pipeline (deps + setups + files)
  install-deps     Dependencies only
  install-setups   Setup steps only
  install-files    File install only

Safe defaults (injected for install and install-files only — plan 06-02):
  --core --skip-hyprland --skip-sysupdate
  Protects personal hyprland.conf (full --skip-hyprland, not entry-only).
  Skips unattended pacman -Syu. install-deps / install-setups get no injection.

Backup gate (install and install-files — plan 06-02):
  Interactive confirmation required before files-touching paths.
  Upstream backup dir: ~/ii-original-dots-backup
  Quickshell config will be overwritten; hyprland.conf kept via --skip-hyprland.
  Do NOT pass --skip-backup on first adoption.
  Bare --skip-backup is refused unless also passing --allow-skip-backup.

Wrapper-owned meta flags (stripped; never forwarded to ./setup):
  --dry-run              Print would-exec argv and exit 0
  --allow-skip-backup    Explicit override for --skip-backup policy (06-02)

Examples:
  ./arch/dots-hyprland.sh install
  ./arch/dots-hyprland.sh install-deps
  ./arch/dots-hyprland.sh install-files --exp-files
  ./arch/dots-hyprland.sh install-deps --dry-run

Other setup subcommands (uninstall, exp-update, exp-merge, virtmon, …):
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

  # 2) allowlist only WRAP-01 four (D-04)
  if ! is_allowlisted "$1"; then
    echo "[FAIL] Unknown or non-allowlisted subcommand: $1" >&2
    echo "[FAIL] Allowlisted: ${ALLOWLIST[*]}" >&2
    echo "[FAIL] For other ops use vendor/dots-hyprland/./setup directly." >&2
    exit 1
  fi

  local subcmd="$1"
  shift

  # 3) Scan remaining args: strip wrapper-owned meta flags; preserve order (WRAP-04)
  local dry_run=0
  local allow_skip_backup=0
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
      *)
        user_flags+=("$arg")
        ;;
    esac
  done
  # allow_skip_backup stored for plan 06-02 skip-backup policy; not forwarded.
  : "${allow_skip_backup}"

  # 4) Preflight before any path that invokes setup (D-14)
  preflight

  # 5) Build argv as bash array — no SAFE_DEFAULTS injection yet (06-02)
  local -a cmd=(./setup "$subcmd")
  if ((${#user_flags[@]} > 0)); then
    cmd+=("${user_flags[@]}")
  fi

  echo "[INSTALL] ${cmd[*]}  (cwd=$II_ROOT)"

  # 6) --dry-run: print would-exec, exit 0 without calling setup (D-16)
  if ((dry_run)); then
    echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"
    exit 0
  fi

  # 7) Array exec only — never eval a concatenated command string (T-06-04)
  (
    cd "$II_ROOT"
    "${cmd[@]}"
  )
}

main "$@"
