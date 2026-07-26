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

Safe defaults (injected for install and install-files only):
  --core --skip-hyprland --skip-sysupdate
  Protects personal hyprland.conf (full --skip-hyprland, not entry-only).
  Skips unattended full system package upgrade. install-deps / install-setups get no injection.
  Never auto-injects --force or --skip-allgreeting.

Backup gate (install and install-files only):
  Interactive confirmation required before files-touching paths (type yes).
  Upstream backup dir: ~/ii-original-dots-backup
  Quickshell config will be overwritten; hyprland.conf kept via --skip-hyprland.
  Do NOT pass --skip-backup on first adoption.
  Bare --skip-backup is refused unless also passing --allow-skip-backup.

Wrapper-owned meta flags (stripped; never forwarded to ./setup):
  --dry-run              Print would-exec argv and exit 0
  --allow-skip-backup    Explicit override for --skip-backup policy

Examples:
  ./arch/dots-hyprland.sh install
  ./arch/dots-hyprland.sh install-deps
  ./arch/dots-hyprland.sh install-files --exp-files
  ./arch/dots-hyprland.sh install-deps --dry-run
  printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run

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
backup_gate() {
  echo "[CONFIG] Upstream may backup clashing paths to: ~/ii-original-dots-backup"
  echo "[CONFIG] install-files will overwrite ~/.config/quickshell (Quickshell tree / rsync --delete)."
  echo "[CONFIG] Defaults include --skip-hyprland so personal hyprland.conf is not renamed."
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

  # 4) Preflight before any path that invokes setup (D-14)
  preflight

  # 5) D-12: refuse bare --skip-backup unless --allow-skip-backup (before gate)
  if user_flags_contain "--skip-backup" user_flags && ((allow_skip_backup == 0)); then
    echo "[FAIL] --skip-backup refused without --allow-skip-backup." >&2
    echo "[FAIL] First adoption must not skip backup. Re-run with --allow-skip-backup only if you intentionally override." >&2
    exit 1
  fi

  # 6) Hard backup gate for install / install-files (skip pure -h/--help passthrough)
  if needs_safe_defaults "$subcmd" && ! is_help_only_user_flags user_flags; then
    backup_gate
  fi

  # 7) Build argv: ./setup <sub> [SAFE_DEFAULTS…] [user flags…] (D-09)
  local -a cmd=(./setup "$subcmd")
  if needs_safe_defaults "$subcmd"; then
    echo "[CONFIG] safe defaults: ${SAFE_DEFAULTS[*]}"
    cmd+=("${SAFE_DEFAULTS[@]}")
  fi
  if ((${#user_flags[@]} > 0)); then
    cmd+=("${user_flags[@]}")
  fi

  echo "[INSTALL] ${cmd[*]}  (cwd=$II_ROOT)"

  # 8) --dry-run: print would-exec, exit 0 without calling setup (D-16)
  if ((dry_run)); then
    echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"
    exit 0
  fi

  # 9) Array exec only — never eval a concatenated command string (T-06-04)
  (
    cd "$II_ROOT"
    "${cmd[@]}"
  )
}

main "$@"
