#!/usr/bin/env bash
set -euo pipefail

# arch/dots-hyprland.sh — thin wrapper around vendor/dots-hyprland/./setup
# Pattern: arch/waybar.sh / arch/*.sh (REPO_ROOT, main dispatcher, [LABEL] echos).
# Divergence: no package arrays; delegates install logic to upstream setup.
# Uninstall is the one wrapper-owned path (D-07 / D-10) — do NOT call upstream ./setup uninstall.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
II_ROOT="$REPO_ROOT/vendor/dots-hyprland"
SETUP="$II_ROOT/setup"
# D-04: full is the only install behavior; no residual flag injection.
# install* → upstream ./setup; uninstall → the one wrapper-owned path (D-07)
ALLOWLIST=(install install-deps install-setups install-files uninstall)

# XDG defaults (match upstream environment-variables.sh)
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
II_CONFDIR="${XDG_CONFIG_HOME}/illogical-impulse"

usage() {
  cat <<'EOF'
arch/dots-hyprland.sh — thin wrapper for vendor/dots-hyprland/./setup

Usage:
  arch/dots-hyprland.sh <install|install-deps|install-setups|install-files> [flags…]
  arch/dots-hyprland.sh uninstall [flags…]
  arch/dots-hyprland.sh help|-h|--help

What this wrapper does:
  Validates the subcommand against a fixed allowlist and refuses anything else.
  Preflights the vendored submodule and the upstream executable; never auto-fixes them.
  Builds the upstream argv as an array and execs it after changing into the vendored
  tree — never eval, never a concatenated command string.
  Forwards the upstream backup-suppression flag on the two file-touching install
  subcommands only, because upstream reads it on the files step and nowhere else.
  Owns the removal path outright instead of delegating it to upstream.

Allowlisted subcommands:
  install          Full upstream pipeline (deps + setups + files)
  install-deps     Dependencies only
  install-setups   Setup steps only
  install-files    File install only
  uninstall        Wrapper-owned removal: gates on its own exact-token confirmation,
                   drops the illogical-impulse-* meta packages with no dependency
                   cascade, and removes ii-owned configs and state (see below)
  help|-h|--help   This text

Install behavior (D-04, D-06, D-09):
  A bare invocation is the full install; no profile flags are injected.
  install and install-files also pass the upstream backup-suppression flag by default:
  nothing is snapshotted before files are replaced, and there is no undo.
  Pass --keep-backup to leave upstream's snapshot enabled for a run.
  install-deps / install-setups do not — upstream reads that flag on the files step only.

Interactivity:
  This wrapper asks nothing before an install; that is true of the wrapper alone.
  Upstream still runs its own greeting and at least one 'Enter to proceed' pause,
  unless it is force-run by flags passed straight to vendor/dots-hyprland/./setup.
  This wrapper never auto-injects --force or --skip-allgreeting.

Wrapper-owned meta flags (stripped; never forwarded to ./setup):
  --dry-run   Print the argv this wrapper would exec, then exit 0 without calling upstream
  --full      Accepted but ignored (D-05). Full is the only install behavior now, so the
              flag is an announced no-op kept so old transcripts and scripts still work.
              It is never forwarded to ./setup.
  --keep-backup
              Do not suppress upstream's auto_backup_configs for this run. Only meaningful
              on install / install-files, the two subcommands that reach the files step.

Uninstall (wrapper-owned; does NOT call upstream ./setup uninstall):
  Removes only illogical-impulse-* meta packages with pacman -R (no -s cascade).
  Optionally removes ii-owned configs/state (quickshell ii tree, illogical-impulse conf, venv).
  Stops running qs/quickshell processes (otherwise the top bar stays up after files are gone).
  NEVER deletes ~/.config/hypr trees, hyprland/hyprlock packages, fish/kitty/starship,
  group memberships, or /etc modules. NEVER runs yay -Rns or orphan auto-remove.
  Why: upstream ./setup uninstall uses yay -Rns on meta pkgs (incl. illogical-impulse-hyprland)
  and will cascade-delete packages that install marked asdeps (fish/starship/… and sometimes hyprland).

  uninstall flags:
    --dry-run         Print plan only; change nothing
    --packages-only   Meta packages only; leave configs/state
    --configs-only    Configs/state only; leave packages
    --keep-venv       Keep ~/.local/state/quickshell/.venv
    --upstream-dangerous
                      Run vendor ./setup uninstall as-is (WILL cascade packages / groups).
                      Requires typing: UPSTREAM-UNINSTALL

Examples:
  ./arch/dots-hyprland.sh install --dry-run          # preview the argv; changes nothing
  ./arch/dots-hyprland.sh install                    # the real full install
  ./arch/dots-hyprland.sh install-files --dry-run    # preview a pin-bump re-apply
  ./arch/dots-hyprland.sh install-files              # re-apply files after a submodule pin bump
  ./arch/dots-hyprland.sh install-deps               # only the package set changed
  ./arch/dots-hyprland.sh uninstall --dry-run        # print the removal plan only
  ./arch/dots-hyprland.sh uninstall --packages-only  # meta packages only; keep configs/state

Other setup subcommands (exp-update, exp-merge, virtmon, …):
  Use vendor/dots-hyprland/./setup directly.

Playbook: docs/dots-hyprland-workflow.md
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

# ---------------------------------------------------------------------------
# Safe uninstall (wrapper-owned)
# ---------------------------------------------------------------------------

# Print array elements one per line; no-op on empty (avoids set -u / bare printf issues).
print_lines() {
  local -n _arr=$1
  local _e
  for _e in "${_arr[@]+"${_arr[@]}"}"; do
    printf '%s\n' "$_e"
  done
}

# Collect installed illogical-impulse-* meta packages (and optional plasma-browser-integration
# only if it is present — earlier profile-limited runs skipped it, later ones may not (D-04).
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
# Never includes ~/.config/hypr (personal; hypr trees are never a removal target, D-07).
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

# Re-clean the quickshell state dir a live process may have recreated between the
# removal loop and the kill. Scoped by the same flags the caller was given, so it
# cannot overrule --packages-only or --keep-venv (which it silently did before), and
# routed through safe_rm_path so it inherits the $HOME / hypr refusals every other
# removal in this file already has.
reclean_qs_state() {
  local dry_run="${1:-0}"
  local packages_only="${2:-0}"
  local keep_venv="${3:-0}"
  local st="${XDG_STATE_HOME}/quickshell"

  ((packages_only == 0)) || return 0
  [[ -d "$st" ]] || return 0

  local child
  if ((keep_venv == 1)); then
    shopt -s nullglob dotglob
    for child in "$st"/*; do
      [[ "$(basename "$child")" == ".venv" ]] && continue
      if ((dry_run)); then
        echo "[CONFIG] dry-run: would re-clean recreated state: $child"
      else
        echo "[UNINSTALL] Re-cleaning state recreated by live process: $child"
        safe_rm_path "$child"
      fi
    done
    shopt -u nullglob dotglob
  else
    if ((dry_run)); then
      echo "[CONFIG] dry-run: would re-clean recreated state: $st"
    else
      echo "[UNINSTALL] Re-cleaning state recreated by live process: $st"
      safe_rm_path "$st"
    fi
  fi
}

# Stop live qs/quickshell processes so the bar does not keep running after files/pkgs go away.
# Uninstall removes the binary from disk, but an already-started process stays resident
# (Linux shows exe as "/usr/bin/quickshell (deleted)") until killed.
stop_running_qs() {
  local dry_run="${1:-0}"
  local packages_only="${2:-0}"
  local keep_venv="${3:-0}"
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
    reclean_qs_state 1 "$packages_only" "$keep_venv"
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
  # State dir may be recreated by the process between rm and kill; clean again,
  # but only within the scope the caller's flags allow.
  reclean_qs_state 0 "$packages_only" "$keep_venv"
}

uninstall_gate() {
  local packages_only="$1"
  local configs_only="$2"
  local keep_venv="$3"
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

  echo "[UNINSTALL] Safe uninstall (wrapper-owned)."
  echo "[UNINSTALL] This does NOT call upstream ./setup uninstall."
  echo "[UNINSTALL] Upstream uninstall uses yay -Rns and can delete hyprland/fish/starship"
  echo "[UNINSTALL] when those were marked asdeps — that path is NOT used here."
  echo
  echo "[UNINSTALL] WILL NOT touch:"
  echo "  - hyprland / hyprlock / hypridle packages (left installed)"
  echo "  - fish / kitty / starship / bc / jq / cliphist and other personal-stack deps"
  echo "  - hypr config trees (no rm of ~/.config/hypr)"
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
  echo
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
    stop_running_qs 1 "$packages_only" "$keep_venv"
    echo "[CONFIG] dry-run: would NOT remove hyprland package or delete ~/.config/hypr"
    echo "[CONFIG] dry-run: would NOT run yay -Rns or pacman -Rsu orphan cleanup"
    exit 0
  fi

  # Stop the live bar FIRST so removing configs/binary does not leave a
  # deleted-binary zombie still drawing chrome (and re-writing state).
  stop_running_qs 0 "$packages_only" "$keep_venv"

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
  stop_running_qs 0 "$packages_only" "$keep_venv"
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

  echo
  echo "[DONE] Safe uninstall finished."
  echo "[DONE] Preserved: hyprland stack, ~/.config/hypr tree, and non-meta deps (fish/kitty/…)."
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
  return 0
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
      --upstream-dangerous)
        upstream_dangerous=1
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
    uninstall_gate "$packages_only" "$configs_only" "$keep_venv"
  else
    echo "[CONFIG] dry-run: skipping uninstall gate"
  fi

  run_safe_uninstall "$dry_run" "$packages_only" "$configs_only" "$keep_venv"
}

# D-06: the files-touching install paths are the only ones where upstream reads
# the skip-backup flag (vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:219),
# so it is appended there and nowhere else.
touches_files() {
  case "$1" in
    install|install-files) return 0 ;;
    *) return 1 ;;
  esac
}

run_install_family() {
  local subcmd="$1"
  shift

  # Scan remaining args: strip wrapper-owned meta flags; preserve order (WRAP-04)
  local dry_run=0
  local keep_backup=0
  local -a user_flags=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run)
        dry_run=1
        ;;
      --keep-backup)
        # Escape hatch for the D-06 injection below. Upstream's getopt has no
        # counter-flag to --skip-backup, so without this the suppression is
        # unconditional and an operator has no way to keep the one snapshot
        # upstream would otherwise take.
        keep_backup=1
        ;;
      --full)
        # D-05: accepted no-op alias, kept deliberately. The catch-all below would
        # forward it to upstream, whose getopt has no such long option and exits 1.
        echo "[CONFIG] --full is accepted but ignored: full is now the only install behavior."
        ;;
      *)
        user_flags+=("$arg")
        ;;
    esac
  done

  # Preflight before any path that invokes setup (D-11 / D-14)
  preflight

  # D-04: no residual injection — a bare invocation is the full behavior.
  # D-06: skip the upstream backup, scoped to the paths where it is read.
  local -a cmd=(./setup "$subcmd")
  if touches_files "$subcmd" && ((keep_backup == 0)); then
    cmd+=(--skip-backup)
  fi
  if ((keep_backup == 1)); then
    if touches_files "$subcmd"; then
      echo "[CONFIG] --keep-backup: leaving upstream's auto_backup_configs enabled for this run."
    else
      echo "[CONFIG] --keep-backup has no effect on $subcmd: upstream reads the backup flag on the files step only."
    fi
  fi
  if ((${#user_flags[@]} > 0)); then
    cmd+=("${user_flags[@]}")
  fi

  echo "[INSTALL] ${cmd[*]}  (cwd=$II_ROOT)"

  # --dry-run: print would-exec, exit 0 without calling setup (D-16)
  if ((dry_run)); then
    echo "[CONFIG] dry-run: would exec from $II_ROOT: ${cmd[*]}"
    exit 0
  fi

  # Array exec only — never eval a concatenated command string (D-11 / T-06-04)
  (
    cd "$II_ROOT"
    "${cmd[@]}"
  )
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
    *)
      run_install_family "$subcmd" "$@"
      ;;
  esac
}

main "$@"
