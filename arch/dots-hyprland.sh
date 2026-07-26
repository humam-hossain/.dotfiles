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

  # Task 2 / plan 06-02 complete the path: meta-flag scan, preflight,
  # SAFE_DEFAULTS injection, backup_gate, dry-run, array-exec of ./setup.
  echo "[FAIL] Subcommand '$subcmd' accepted but exec path not yet wired (06-01 Task 2)." >&2
  exit 1
}

main "$@"
