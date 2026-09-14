#!/usr/bin/env bash
set -euo pipefail

# arch/dots-hyprland.sh — thin wrapper around vendor/dots-hyprland/./setup
# Pattern: arch/waybar.sh / arch/*.sh (REPO_ROOT, main dispatcher, [LABEL] echos).
# Divergence: no package arrays; delegates install logic to upstream setup.
# Uninstall is the one wrapper-owned path (D-07 / D-10) — do NOT call upstream ./setup uninstall.

# D-06: `pwd -P` (not plain `pwd`) so REPO_ROOT is a fully resolved physical
# path — safe_rm_path compares it against a realpath-resolved candidate, and a
# logical path with an unresolved symlink component would never match.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
II_ROOT="$REPO_ROOT/vendor/dots-hyprland"
SETUP="$II_ROOT/setup"
# D-04: full is the only install behavior; no residual flag injection.
# install* → upstream ./setup; uninstall, verify, capture → wrapper-owned paths (D-07, D-48, D-61)
ALLOWLIST=(install install-deps install-setups install-files uninstall verify capture)

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
  arch/dots-hyprland.sh verify [--strict] [--quiet]
  arch/dots-hyprland.sh capture [--dry-run]
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

Verify (wrapper-owned; reads the repo trees and the live filesystem only):
  verify flags:
    --strict          Promote [FINDING]s to a failing exit code; labels are unchanged
    --quiet           Suppress [PASS] lines only; every other label still prints
  Any other flag exits 2 — an unknown flag means the tree was never examined.

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
  # Extra belt: never anything inside this repo (D-05/D-08).
  # Must sit AFTER the $HOME allow-list, not replace it: the repo lives inside
  # $HOME on this machine, so every repo path already passes that clause. Both
  # sides are canonicalised by realpath(1) because a $HOME-shaped path can
  # reach the repo through a symlink — ~/.config/systemd/user/hyprland-session.service
  # already is one. A literal prefix test on the unresolved $path would miss it.
  # No carve-out for vendor/dots-hyprland (use `git submodule deinit`), and no
  # override flag: a destructive path that has reached the repo means the
  # caller's assumptions are already wrong.
  local resolved_path resolved_root
  resolved_path="$(realpath -m -- "$path")"
  resolved_root="$(realpath -m -- "$REPO_ROOT")"
  if [[ "$resolved_path" == "$resolved_root" || "$resolved_path" == "$resolved_root"/* ]]; then
    echo "[FAIL] Refusing to delete path inside the repo: $path" >&2
    return 1
  fi
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

get_main_repo_root() {
  local common_dir
  if common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
    dirname "$common_dir"
  else
    printf '%s\n' "$REPO_ROOT"
  fi
}

# ---------------------------------------------------------------------------
# run_verify (wrapper-owned)
#
# D-47: Neither run_verify nor run_capture calls preflight. This subcommand
# reads only the repo's own trees (stow/, restow/, capture/) and the live
# filesystem, never touches vendor/dots-hyprland, and runs to a real exit code
# even when the vendored submodule is de-initialised.
#
# D-46: Order matters: link-ness is asserted BEFORE any content comparison.
# D-53 (narrowed by D-16): accepts exactly -h/--help/--strict/--quiet and
# always walks all three trees. No flag narrows what is examined --- --strict
# makes the verdict harsher, --quiet makes the output shorter, both over the
# identical full sweep. D-12/D-15: anything else exits 2.
# D-54: Missing live link is a [FAIL] naming recovery stow command.
# D-50: For capture/ paths, expectation is inverted (symlink into repo is [FAIL]).
# ---------------------------------------------------------------------------
run_verify() {
  local -a unknown=()
  local arg
  # D-19: the accepted flag surface is exactly these four and nothing else.
  # A closed surface is what makes D-15's exit 2 meaningful.
  local strict=0 quiet=0
  for arg in "$@"; do
    case "$arg" in
      -h|--help)
        usage
        exit 0
        ;;
      --strict)
        strict=1
        ;;
      --quiet)
        quiet=1
        ;;
      *)
        unknown+=("$arg")
        ;;
    esac
  done

  if ((${#unknown[@]} > 0)); then
    # D-15: exit 2, not 1 — an unknown flag means the tree was never examined.
    echo "[FAIL] Unknown verify flag(s): ${unknown[*]}" >&2
    echo "[FAIL] See: ./arch/dots-hyprland.sh help" >&2
    exit 2
  fi

  # -------------------------------------------------------------------------
  # Precondition block (D-12, D-17).
  #
  # D-12's rule is POSITIONAL, not semantic: everything decided here, before
  # the walk starts, is exit 2; everything discovered during the walk --- an
  # unreadable directory included --- is exit 1. This one placement (below the
  # parser, above the counters) also satisfies D-17: an exit-2 refusal returns
  # before the closing `=== done:` line, which asserts a completed verdict.
  #
  # Deliberately NOT routed through fail(): that helper writes to stdout and
  # increments a counter this run is about to discard. Same `echo ... >&2`
  # shape the unknown-flag block above already uses.
  # -------------------------------------------------------------------------

  # A fully *unset* HOME cannot reach run_verify at all: the XDG_CONFIG_HOME
  # default near the top of this file dereferences $HOME at file scope under
  # `set -u`, so the process dies before dispatch. The two REACHABLE exit-2
  # forms are an EMPTY HOME and a HOME naming a non-directory. Naming the
  # unreachable case rather than pretending to cover it is the
  # scripts/phase14-verify.sh:10-14 principle applied to this code.
  if [[ -z "${HOME:-}" ]]; then
    echo "[FAIL] precondition: HOME is empty — no live path can be resolved" >&2
    exit 2
  fi
  if [[ ! -d "$HOME" ]]; then
    echo "[FAIL] precondition: HOME is not a directory: $HOME" >&2
    exit 2
  fi

  if [[ ! -d "$REPO_ROOT/stow" && ! -d "$REPO_ROOT/restow" ]]; then
    echo "[FAIL] precondition: neither $REPO_ROOT/stow nor $REPO_ROOT/restow is a directory" >&2
    exit 2
  fi

  # D-23, rated one-way and resolved at the 19-02 Task 2 checkpoint as
  # `hard-dependency`: `git` is a DECLARED required binary. Its absence is a
  # precondition failure and this subcommand exits 2 right here — before the
  # walk starts, and before get_main_repo_root() is ever called, so that
  # helper's fallback to $REPO_ROOT when `git rev-parse` fails is unreachable
  # from `verify`. The dependency was soft until now; it is hard from here on,
  # and there is deliberately no soft-degrade arm. D-21's repo-vs-HEAD
  # observation has no filesystem substitute, so a run without `git` could not
  # make it at all, and `verify` never reports a condition it could not observe
  # (scripts/phase14-verify.sh:10-14). A second, quieter meaning for a green run
  # that a caller cannot tell apart from a full one is worse than a refusal.
  #
  # This is a published contract: any caller running `verify` in a git-less
  # context — a container, a rescue shell, a bootstrap stage before the clone
  # finishes — now gets a precondition failure instead of a verdict. The one
  # known future caller (BOOT-04, Phase 23) clones before it stows, so `git` is
  # necessarily present by the time it calls this.
  #
  # `realpath` is declared here because the folded-ancestor and dangling arms
  # below canonicalise with it (T-19-02); an undeclared dependency that only
  # matters on a pathological tree is a verdict that degrades silently in
  # exactly the case it exists for.
  local -a required_bins=(find readlink cmp dirname basename realpath git)
  local required_bin
  for required_bin in "${required_bins[@]}"; do
    if ! command -v "$required_bin" >/dev/null 2>&1; then
      echo "[FAIL] precondition: required command not found on PATH: $required_bin" >&2
      exit 2
    fi
  done

  # Relocated from below the counters so the root-resolvable condition is
  # genuinely checked BEFORE the walk starts (D-12).
  local main_root
  main_root="$(get_main_repo_root)"
  if [[ -z "$main_root" || ! -d "$main_root" ]]; then
    echo "[FAIL] precondition: main repo root unresolvable or not a directory: ${main_root:-<empty>}" >&2
    exit 2
  fi

  # T-19-02: every repo-prefix test the new arms make compares CANONICALISED
  # strings, never a literal prefix on an unresolved argument. STATE.md records
  # a live instance where ~/.config/systemd/user/hyprland-session.service
  # resolves into stow/systemd/ and is accepted by a literal test and refused by
  # the resolved one. Same `realpath -m --` idiom safe_rm_path already uses.
  local main_root_real
  main_root_real="$(realpath -m -- "$main_root" || true)"
  [[ -n "$main_root_real" ]] || main_root_real="$main_root"

  local fail_count=0
  local finding_count=0
  # D-20: --quiet suppresses [PASS] lines ONLY. Written as an `if` block, never
  # as a trailing `((quiet)) && return`-style conjunction: as the last command
  # of a function that form leaves the return status at 1 whenever quiet is 0,
  # which aborts the `set -euo pipefail` caller at the first passing check
  # (STATE.md records that exact defect falsified live in Phase 17).
  pass() {
    if ((quiet == 0)); then
      printf '[PASS] %s\n' "$1"
    fi
  }
  fail() { printf '[FAIL] %s\n' "$1"; fail_count=$((fail_count + 1)); }
  finding() { printf '[FINDING] %s\n' "$1"; finding_count=$((finding_count + 1)); }
  info() { printf '[INFO] %s\n' "$1"; }

  # ---------------------------------------------------------------------------
  # resolve_dangling_target — the raw-target resolution for a DANGLING symlink,
  # written once and shared by both callers: the repo-side walk's dangling arm
  # below and the live-side sweep's classifier further down. Two copies of this
  # four-line rule is two chances for them to drift into disagreeing about the
  # same link, and the repo/non-repo split is precisely the [FAIL]-versus-[INFO]
  # boundary D-06 draws.
  #
  # $1 = the link path, $2 = the directory the link lives in. Sets two of
  # run_verify()'s locals rather than printing, because BOTH values are needed
  # at every call site — the canonicalised target to test the repo prefix
  # against, and the RAW target to name in the message. Same dynamic-scope
  # convention fail()/finding() already use for the counters.
  #
  # `readlink` WITHOUT -f, deliberately. `readlink -f` returns the empty string
  # for a dangling link, which has already discarded where the link pointed —
  # the exact information this split keys on (RESEARCH Pitfall 3).
  #
  # `realpath -m` on the JOINED path, because stow writes RELATIVE targets: the
  # live shape of PITFALLS.md A-6 is `../../github_repo/.dotfiles/stow/…`, and a
  # literal prefix test on that string never matches the repo root. `-m` is what
  # allows canonicalising a path whose final component does not exist, which is
  # the definition of the dangling case.
  # ---------------------------------------------------------------------------
  local dangling_raw_target=""
  local dangling_abs_target=""
  resolve_dangling_target() {
    local link="$1" link_dir="$2"
    local joined
    dangling_raw_target="$(readlink -- "$link" || true)"
    case "$dangling_raw_target" in
      /*) joined="$dangling_raw_target" ;;
      *)  joined="$link_dir/$dangling_raw_target" ;;
    esac
    dangling_abs_target="$(realpath -m -- "$joined" || true)"
    return 0
  }

  # D-53: Always walks all three trees.
  # Walks repo side only (RESEARCH P-8). Live sidecars are never visited.
  local tree pkg_dir pkg file_path rel live canonical_repo
  local live_dir folded_hit cur ancestor_target raw_target abs_target
  local repo_rel diff_rc tracked_path
  # D-04: the folded-ancestor check is keyed PER DIRECTORY, not per file. Two
  # memos are needed and they answer different questions: folded_verdict caches
  # whether a given live directory sits under a folded ancestor (so the walk is
  # done once per directory rather than once per file), and folded_reported
  # caches which ancestor COMPONENTS have already been named (so two managed
  # directories under one folded component still produce exactly one [FAIL]).
  # "One failure, not N" is the whole point of D-04 and is the same principle
  # scripts/phase14-verify.sh states about a wall of derived failures.
  local -A folded_verdict=()
  local -A folded_reported=()

  # RESEARCH Pitfall 5, and Open Question 3 decided IN SCOPE as [INFO]. This is
  # an EXTENSION of D-21, not a new decision: the walk enumerates repo-side
  # files from the FILESYSTEM, so a file that exists on disk but was never
  # committed makes `git diff --quiet HEAD` return 0 — a literal statement that
  # it matches HEAD, which is false. The tracked set closes that gap.
  #
  # Read ONCE, before the walk, with a single `git ls-files -z`. Do NOT add a
  # per-path trackedness probe here: 94 single-path `git ls-files` calls on top
  # of D-21's 94 `git diff` calls is the anti-pattern research names explicitly.
  # run_capture()'s mirror_is_capturable() legitimately uses the single-path
  # form — it tests ONE path per call, on demand — and that call site is
  # untouched. The distinction is batch-versus-per-file in a 94-iteration walk,
  # not the probe itself.
  # `-z` because a repo-relative path may contain anything but NUL, and the key
  # is the repo-relative path exactly as `$tree/$pkg/$rel` reconstructs it.
  local -A tracked_repo_files=()
  while IFS= read -r -d '' tracked_path; do
    tracked_repo_files["$tracked_path"]=1
  done < <(git -C "$main_root" ls-files -z -- stow restow 2>/dev/null || true)

  for tree in stow restow; do
    local tree_dir="$REPO_ROOT/$tree"
    [[ -d "$tree_dir" ]] || continue
    for pkg_dir in "$tree_dir"/*; do
      [[ -d "$pkg_dir" ]] || continue
      pkg="$(basename "$pkg_dir")"
      while IFS= read -r -d '' file_path; do
        rel="${file_path#"$pkg_dir"/}"
        live="$HOME/$rel"
        canonical_repo="$main_root/$tree/$pkg/$rel"

        # D-04: folded-ancestor pre-check, BEFORE the per-file link tests. A
        # managed file whose ancestor directory is itself a symlink into the
        # repo must be reported as a folded directory, not as N misplaced
        # links. Only a symlink INTO the repo is the pathology criterion 1
        # names: a component that symlinks somewhere outside the repo is
        # allowed and is resolved through silently (D-10).
        live_dir="$(dirname -- "$live")"
        if [[ -z "${folded_verdict[$live_dir]:-}" ]]; then
          folded_hit=0
          cur="$live_dir"
          while [[ "$cur" != "$HOME" && "$cur" != "/" && "$cur" != "." ]]; do
            if [[ -L "$cur" ]]; then
              ancestor_target="$(readlink -f -- "$cur" || true)"
              if [[ -n "$ancestor_target" && "$ancestor_target" == "$main_root_real"/* ]]; then
                folded_hit=1
                if [[ -z "${folded_reported[$cur]:-}" ]]; then
                  folded_reported["$cur"]=1
                  fail "folded ancestor directory: $cur -> $ancestor_target — unfold with: cd $tree && stow -D --no-folding -t ~ $pkg && stow --no-folding -t ~ $pkg"
                fi
              fi
            fi
            cur="$(dirname -- "$cur")"
          done
          folded_verdict["$live_dir"]="$folded_hit"
        fi
        if [[ "${folded_verdict[$live_dir]:-0}" != 0 ]]; then
          continue
        fi

        # D-46 / D-54: Link-ness BEFORE content comparison.
        # Single-machine repo assumption: every package is expected to be installed.
        if [[ ! -e "$live" && ! -L "$live" ]]; then
          fail "no live counterpart: $live — recover with: cd $tree && stow -t ~ $pkg"
          continue
        fi
        if [[ ! -L "$live" ]]; then
          fail "not a symlink: $live — recover with: cd $tree && stow -t ~ $pkg"
          continue
        fi

        # D-06 / PITFALLS.md A-6: the link exists but its target does not.
        # `readlink -f` is useless here — it returns the EMPTY string for a
        # dangling link, which both discards where the link pointed and
        # compares equal to the equally-empty resolution of a missing repo-side
        # target, so the equality test just below would report a broken pair as
        # [PASS] (RESEARCH Pitfall 3). Read the raw target instead and resolve a
        # relative one against the link's own directory. A target under the repo
        # is exactly the A-6 condition — repo unavailable at login — that this
        # phase exists to make loud; anything else is informational.
        #
        # Measured: today's tree has ZERO folded ancestors and ZERO dangling
        # links into the repo (Phase 17's audit found two folded directories and
        # Phase 18's redistribution resolved both). Neither this arm nor the
        # folded-ancestor check above has a live positive to validate against —
        # the composite fixture in plan 19-03 is the only proof either works.
        if [[ ! -e "$live" ]]; then
          # The resolution itself lives in resolve_dangling_target() above, so
          # this arm and the live-side sweep's dangling arms cannot drift apart
          # (plan 19-03 Task 2 factored it out; the rule is unchanged).
          resolve_dangling_target "$live" "$live_dir"
          raw_target="$dangling_raw_target"
          abs_target="$dangling_abs_target"
          case "$abs_target" in
            "$main_root_real"/*)
              fail "dangling symlink into repo: $live -> $raw_target"
              ;;
            *)
              info "dangling symlink (outside repo): $live -> $raw_target"
              ;;
          esac
          continue
        fi

        local live_target repo_target
        live_target="$(readlink -f -- "$live" || true)"
        repo_target="$(readlink -f -- "$canonical_repo" || true)"
        if [[ "$live_target" != "$repo_target" ]]; then
          fail "symlink points elsewhere: $live -> $live_target (expected $repo_target) — recover with: cd $tree && stow -t ~ $pkg"
          continue
        fi

        pass "verified: $live -> $canonical_repo"

        # D-21 / D-46: the content observation, reached ONLY by a path that
        # passed every link test above. Link-ness before content,
        # unconditionally — a path that failed any link assertion `continue`d
        # long before here and is never described in content terms.
        #
        # This is the class the cp-through destruction sits exactly on: `cp -f`
        # through an intact link overwrites the REPO file and leaves the link
        # untouched, so every `test -L` / `readlink -f` assertion above passes
        # and only this observation can see it (PITFALLS.md §30, mirrored).
        #
        # It is [INFO] and never [FINDING] or [FAIL]. The check cannot
        # distinguish an installer write-through from an ordinary uncommitted
        # edit — measured right now, `git diff --name-only HEAD -- stow restow`
        # reports the operator's own edit to stow/fish/.config/fish/config.fish.
        # Reporting a guess as a defect is what scripts/phase14-verify.sh:10-14
        # forbids, and ROADMAP criterion 5 mandates [INFO] independently. Both
        # emissions below go through info(), so neither moves a counter and
        # neither can move the exit code under any flag (D-13).
        #
        # The root comes from get_main_repo_root() and NOT from $HOME: the
        # VER-04 harness overrides HOME and the repo root must not follow it.
        #
        # D-21's per-file form is honoured LITERALLY. Research measured it at
        # 0.437 s against 0.006 s for a single batched call, with identical
        # results, on a subcommand whose total wall time is under a second. That
        # cost is known and accepted — do not "optimise" it into a batch.
        repo_rel="$tree/$pkg/$rel"
        if [[ -z "${tracked_repo_files[$repo_rel]:-}" ]]; then
          # RESEARCH Pitfall 5: `git diff --quiet HEAD` returns 0 here and would
          # otherwise say nothing at all. Its own [INFO] class, worded
          # distinctly from the differs-from-HEAD one, and still [INFO] because
          # `verify` cannot distinguish a deliberate addition awaiting commit
          # from a stray file.
          info "repo file is untracked: $canonical_repo — never committed, so its content cannot be compared against HEAD"
        else
          # T-19-04: status captured with the `rc=0; cmd || rc=$?` idiom rather
          # than tested inline, so `set -euo pipefail` cannot end the run on the
          # expected non-zero. T-19-03: `--` before the path argument.
          diff_rc=0
          git -C "$main_root" diff --quiet HEAD -- "$repo_rel" || diff_rc=$?
          if ((diff_rc != 0)); then
            info "repo file differs from HEAD: $canonical_repo — an installer write-through and an uncommitted edit are indistinguishable here"
          fi
        fi
      done < <(find "$pkg_dir" -type f -print0 | LC_ALL=C sort -z)
    done
  done

  # D-50: capture/ tree check with inverted expectation.
  local capture_dir="$REPO_ROOT/capture"
  if [[ -d "$capture_dir" ]]; then
    for pkg_dir in "$capture_dir"/*; do
      [[ -d "$pkg_dir" ]] || continue
      pkg="$(basename "$pkg_dir")"
      while IFS= read -r -d '' file_path; do
        rel="${file_path#"$pkg_dir"/}"
        live="$HOME/$rel"
        canonical_repo="$main_root/capture/$pkg/$rel"

        if [[ -L "$live" ]]; then
          local live_target
          live_target="$(readlink -f -- "$live" || true)"
          if [[ "$live_target" == "$main_root"/* || "$live_target" == "$REPO_ROOT"/* ]]; then
            fail "live path is a symlink into repo: $live -> $live_target (wrongly stowed)"
            continue
          fi
        fi

        if [[ ! -e "$live" && ! -L "$live" ]]; then
          finding "live counterpart does not exist: $live"
          continue
        fi

        if ! cmp -s -- "$live" "$canonical_repo"; then
          finding "content drift between live and repo: $live"
        else
          pass "capture path verified: $live"
        fi
      done < <(find "$pkg_dir" -type f -print0 | LC_ALL=C sort -z)
    done
  fi

  # ---------------------------------------------------------------------------
  # The live-side sweep (D-01, D-02, D-07 through D-11).
  #
  # D-07: a SEPARATE labelled pass, running after the repo-side walk and after
  # the capture/ block, appending to the same two counters. The Phase 18 loop
  # above is deliberately NOT modified — that separation is the whole point of
  # the decision, and the reason this code lives down here instead of inside it.
  #
  # Why the pass exists at all: the repo-side walk starts from the repo and
  # resolves outward, so it can only ever look at paths the repo already names.
  # Two of the conditions ROADMAP criterion 1 requires are invisible to it BY
  # CONSTRUCTION — a stale or dangling link at a path the repo never declared,
  # and a folded ancestor directory. This pass starts from the live filesystem
  # instead, bounded to the directories the repo trees imply, and classifies
  # every entry it finds there.
  #
  # Nothing below writes, creates, renames or removes anything (T-19-08).
  # `verify` is read-only by contract: it reports and exits, and fixing is the
  # operator's move. A verifier that repairs what it finds can no longer tell
  # you what it found.
  # ---------------------------------------------------------------------------
  echo "--- live-side sweep: managed directories ---"

  # D-01: the root set is the deduplicated dirname of every repo-side relative
  # path under stow/*/ and restow/*/, and the declared set is every such path
  # resolved live. Both are built in ONE traversal, reusing the repo-side walk's
  # loop skeleton and its `find … -print0 | LC_ALL=C sort -z` idiom. capture/ is
  # deliberately excluded from both — the sweep never visits it (D-01).
  #
  # Every root resolves as "$HOME/<rel>" and NEVER through the XDG config-home
  # variable. `stow -t ~` ignores XDG entirely and the repo-side loop above
  # already resolves this way; the XDG defaulting near the top of this file is a
  # READING constraint on this code, not a variable to honour here. That
  # variable is in scope and it looks tempting — it is wrong, and honouring it
  # would point the sweep at directories stow never wrote to. It is named
  # obliquely here on purpose: scripts/phase17-unblock-assert.sh's sibling
  # convention counts literal tokens in this file, and a comment is not a use.
  local -A managed_roots=()
  local -A declared_live=()
  local sweep_tree sweep_tree_dir sweep_pkg_dir sweep_file sweep_rel sweep_rel_dir
  for sweep_tree in stow restow; do
    sweep_tree_dir="$REPO_ROOT/$sweep_tree"
    [[ -d "$sweep_tree_dir" ]] || continue
    for sweep_pkg_dir in "$sweep_tree_dir"/*; do
      [[ -d "$sweep_pkg_dir" ]] || continue
      while IFS= read -r -d '' sweep_file; do
        sweep_rel="${sweep_file#"$sweep_pkg_dir"/}"
        declared_live["$HOME/$sweep_rel"]=1
        sweep_rel_dir="$(dirname -- "$sweep_rel")"
        # The `dirname`-returns-dot case, handled explicitly. Six stow/ files
        # live directly at $HOME and `dirname` returns a single dot for each of
        # them; naive concatenation yields a "$HOME/." key, which is equal in
        # EFFECT to the "$HOME" key but unequal as a STRING — a thirtieth root
        # and a duplicate directory-level line. $HOME is one of the 29 roots and
        # must be spelled the same way both times.
        if [[ "$sweep_rel_dir" == "." ]]; then
          managed_roots["$HOME"]=1
        else
          managed_roots["$HOME/$sweep_rel_dir"]=1
        fi
      done < <(find "$sweep_pkg_dir" -type f -print0 | LC_ALL=C sort -z)
    done
  done

  # ---------------------------------------------------------------------------
  # classify_sweep_entry — D-03's entry classifier.
  #
  # $1 = the absolute entry path, $2 = the managed root it was listed from.
  #
  # ONE decision point. Every entry the sweep sees gets its verdict from this
  # function and from nowhere else; five independent rules scattered through the
  # enumeration loop is exactly the shape D-03 was taken to avoid, because that
  # shape is how two rules quietly start disagreeing about one entry.
  #
  # Nine arms, and the ordering is load-bearing at one place — see arm 6.
  #
  # Read-only throughout (T-19-08): this function `stat`s and `readlink`s and
  # does nothing else. It creates no temp file, writes nothing, renames nothing
  # and removes nothing.
  #
  # T-19-04: every arm returns 0 explicitly, every probe whose non-zero status
  # is expected carries `|| true`, and `local x` is declared on a line separate
  # from `x="$(cmd)"` so `local` cannot swallow a command's exit status. Under
  # `set -euo pipefail` any one of those omissions ends the run silently in the
  # middle of a sweep that had found something.
  # ---------------------------------------------------------------------------
  classify_sweep_entry() {
    local entry="$1" entry_dir="$2"
    local entry_base
    local resolved
    entry_base="${entry##*/}"

    if [[ -L "$entry" ]]; then
      # T-19-02: the repo-prefix test compares CANONICALISED strings, never a
      # literal prefix on the unresolved argument. STATE.md's Phase 17 entry
      # records a live path in this very tree — a systemd user unit under
      # $HOME/.config — that resolves into stow/systemd/ and is accepted by a
      # literal test while being correctly refused by the resolved one.
      resolved="$(readlink -f -- "$entry" 2>/dev/null || true)"
      if [[ -n "$resolved" && -e "$resolved" ]]; then
        case "$resolved" in
          "$main_root_real"/*)
            # Arm 1: a link into the repo at a path the repo DECLARES. Skip
            # silently — the repo-side pass owns it and has already reported on
            # it. This arm is the whole of the "every managed path is reported
            # exactly once per run" invariant: get the key shape wrong and a
            # clean tree turns into 94 false stale-link failures.
            if [[ -n "${declared_live[$entry]:-}" ]]; then
              return 0
            fi
            # Arm 2: a link into the repo at a path the repo does NOT declare.
            # Structurally invisible to the repo-side walk, which is why the
            # sweep exists.
            fail "stale link into repo at an undeclared path: $entry -> $resolved"
            return 0
            ;;
          *)
            # Arm 4: resolves outside the repo. Not ours; silent.
            return 0
            ;;
        esac
      fi

      # Dangling. The split between arms 3 and 5 is D-06's, and it is decided on
      # the RAW target — see resolve_dangling_target() for why `readlink -f` is
      # useless here.
      resolve_dangling_target "$entry" "$entry_dir"
      case "$dangling_abs_target" in
        "$main_root_real"/*)
          # Arm 3: dangles INTO the repo. PITFALLS.md A-6 — repo unavailable at
          # login — produces exactly this shape.
          fail "dangling symlink into repo: $entry -> $dangling_raw_target"
          ;;
        *)
          # Arm 5: dangles outside the repo. [INFO], never [FAIL]. Measured: two
          # links on a healthy machine ($HOME/.steampath and $HOME/.steampid)
          # dangle this way whenever Steam is not running, so this arm is the
          # difference between a clean tree and a permanently noisy one.
          info "dangling symlink (outside repo): $entry -> $dangling_raw_target"
          ;;
      esac
      return 0
    fi

    if [[ -f "$entry" ]]; then
      # Arm 6: the four installer-artifact shapes.
      #
      # ORDERING IS LOAD-BEARING HERE, and this is the only place in the
      # classifier where it is. This test must run BEFORE arm 8's shared-root
      # exemption. D-05 exempts the shared roots from the unclaimed-stub clause
      # ONLY — the artifact-shape clause, the link check, the folded-ancestor
      # check and the dangling check all run there without exception.
      #
      # Measured: 5 of the 19 installer artifacts on this tree sit in the two
      # shared roots — a backed-up shell rc file, a backed-up profile, two
      # backed-up KDE configs and a backed-up mimeapps list. Invert these two
      # arms and those five vanish from the report.
      case "$entry_base" in
        *.old|*.new|*.bak|*.bak.*)
          info "installer backup artifact: $entry"
          return 0
          ;;
      esac

      # Arm 8: a shared root is $HOME itself or $HOME/.config — the two
      # directories every application writes into by convention. Measured: 44
      # unrelated regular files in the first and 27 in the second. Silent.
      if [[ "$entry_dir" == "$HOME" || "$entry_dir" == "$HOME/.config" ]]; then
        return 0
      fi

      # Arm 7: any other regular file in a package-owned directory — that is,
      # any managed directory at depth two or more below $HOME, which is the
      # exact complement of the two shared roots above. Naming them is all this
      # phase does with them; deciding which of them belong in a tree is later
      # work.
      info "unclaimed upstream stub: $entry"
      return 0
    fi

    # Arm 9: a directory, or any other file type. Silent.
    return 0
  }

  # Per-directory verdicts. Exactly one directory-level line per root, whatever
  # the tree holds, so the directory-level line count is invariant at the size
  # of the root set on every run (D-08, D-09).
  #
  # Roots are emitted through `LC_ALL=C sort`. Bash associative-array iteration
  # is HASH order — not insertion order and not lexical order — so without this
  # the pass reorders itself between runs on an unchanged tree, which would
  # break the byte-identical comparisons the --strict and --quiet sections of
  # the phase assert already make.
  local sweep_root sweep_entry
  if ((${#managed_roots[@]} > 0)); then
    while IFS= read -r sweep_root; do
      [[ -n "$sweep_root" ]] || continue

      # D-08: absent is a named [INFO], never silence. Silence was the exact
      # ambiguity the per-directory line exists to remove. The repo-side pass
      # above still owns the per-file [FAIL] and its recovery stow command, so
      # this line adds a statement about the directory without duplicating one.
      if [[ ! -d "$sweep_root" ]]; then
        info "managed directory absent: $sweep_root"
        continue
      fi

      # D-11: `verify` never reports [PASS] for a condition it could not
      # observe, and a directory it cannot read is exactly that.
      #
      # D-12's exit rule is POSITIONAL, not semantic, and this is the one place
      # that pairing is counter-intuitive: an unreadable directory looks like a
      # precondition — "this run cannot make a verdict here" — but it is
      # discovered DURING the walk, so it routes through fail() and moves the
      # exit code to 1, never to 2. Exit 2 is decided before the walk starts and
      # nowhere else.
      if [[ ! -r "$sweep_root" || ! -x "$sweep_root" ]]; then
        fail "unreadable managed directory: $sweep_root (not readable and searchable by the current user)"
        continue
      fi

      pass "managed directory: $sweep_root"

      # D-02: non-recursive by construction. This lists the directory's own
      # entries and never descends into an unmanaged subtree.
      #
      # `find -mindepth 1 -maxdepth 1 -print0` into a `while IFS= read -r -d ''`
      # loop, never bash globbing (T-19-05): globbing needs `nullglob` and
      # `dotglob` plus an explicit dot-entry filter, it still breaks on a name
      # containing a newline, and setting a shell option inside a function leaks
      # it to the caller.
      #
      # D-10: a managed directory reached through a component that symlinks
      # OUTSIDE the repo is resolved through and checked as normal. Only a
      # symlink INTO the repo is the pathology criterion 1 names, and the
      # folded-ancestor check in the repo-side walk above already catches that.
      while IFS= read -r -d '' sweep_entry; do
        classify_sweep_entry "$sweep_entry" "$sweep_root"
      done < <(find "$sweep_root" -mindepth 1 -maxdepth 1 -print0 | LC_ALL=C sort -z)
    done < <(printf '%s\n' "${!managed_roots[@]}" | LC_ALL=C sort)
  fi

  echo "=== done: FAIL=$fail_count FINDINGS=$finding_count ==="
  # D-13: --strict promotes findings to a failing exit code. The second half is
  # a braced group inside the `if` condition so `set -e` cannot fire on the
  # arithmetic test. The echo above is byte-frozen (D-14, D-18).
  if ((fail_count > 0)) || { ((strict)) && ((finding_count > 0)); }; then
    exit 1
  fi
  exit 0
}

# ---------------------------------------------------------------------------
# run_capture (wrapper-owned)
#
# D-47: preflight is deliberately not called. This subcommand operates solely
# on the repo's own trees and the live filesystem without vendor dependencies.
#
# D-43 / D-49 divergence: in scripts/phase14-verify.sh, findings never move
# the exit code. In run_capture, a [FINDING] (such as a dirty, untracked, or
# absent repo mirror, or a missing live file) DOES move the exit code: the run
# exits non-zero if fail_count > 0 || finding_count > 0.
#
# D-38: Copies live to repo in working tree; never runs git add and never commits.
# D-39: Resolved path guards for capture/ containment and live symlink refusal.
# D-41: When capture/ is empty, exits 0 with an explicit empty-tree message.
# D-42: Honours --dry-run.
# ---------------------------------------------------------------------------
run_capture() {
  local dry_run=0
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
      *)
        unknown+=("$arg")
        ;;
    esac
  done

  if ((${#unknown[@]} > 0)); then
    echo "[FAIL] Unknown capture flag(s): ${unknown[*]}" >&2
    echo "[FAIL] See: ./arch/dots-hyprland.sh help" >&2
    exit 1
  fi

  local fail_count=0
  local finding_count=0
  pass() { printf '[PASS] %s\n' "$1"; }
  fail() { printf '[FAIL] %s\n' "$1"; fail_count=$((fail_count + 1)); }
  finding() { printf '[FINDING] %s\n' "$1"; finding_count=$((finding_count + 1)); }
  info() { printf '[INFO] %s\n' "$1"; }

  local capture_dir="$REPO_ROOT/capture"
  local -a packages=()
  if [[ -d "$capture_dir" ]]; then
    for d in "$capture_dir"/*; do
      [[ -d "$d" ]] && packages+=("$d")
    done
  fi

  # D-41: Empty tree exits 0 with explicit message.
  if ((${#packages[@]} == 0)); then
    info "capture/ is empty, nothing to capture."
    exit 0
  fi

  mirror_is_capturable() {
    local p="$1"
    if [[ ! -e "$p" ]]; then
      finding "repo mirror does not exist: $p"
      return 1
    fi
    if ! git ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then
      finding "repo mirror is untracked (no HEAD version to recover): $p"
      return 1
    fi
    if ! git diff --quiet HEAD -- "$p"; then
      finding "repo mirror is dirty against HEAD: $p"
      return 1
    fi
    return 0
  }

  local pkg_dir pkg repo_file rel live
  local capture_real
  capture_real="$(realpath -m -- "$capture_dir")"
  local main_root
  main_root="$(get_main_repo_root)"

  # D-38 / D-40: Walk repo side only; derive live paths from stow layout.
  for pkg_dir in "${packages[@]}"; do
    pkg="$(basename "$pkg_dir")"
    while IFS= read -r -d '' repo_file; do
      rel="${repo_file#"$pkg_dir"/}"
      live="$HOME/$rel"

      # D-39: Repo mirror must live under capture/ (resolved paths)
      local repo_real
      repo_real="$(realpath -m -- "$repo_file")"
      if [[ "$repo_real" != "$capture_real"/* ]]; then
        fail "repo mirror not under capture/: $repo_file"
        continue
      fi

      # D-37 / RESEARCH F-8: Test repo mirror capturability (two-part test)
      if ! mirror_is_capturable "$repo_file"; then
        continue
      fi

      # D-39: Live path must not be a symlink resolving into the repo
      if [[ -L "$live" ]]; then
        local live_target
        live_target="$(readlink -f -- "$live" || true)"
        if [[ "$live_target" == "$main_root"/* || "$live_target" == "$REPO_ROOT"/* ]]; then
          fail "refusing live path that is a symlink resolving into repo: $live -> $live_target"
          continue
        fi
      fi

      # D-43: Repo mirror whose live counterpart is missing
      if [[ ! -e "$live" && ! -L "$live" ]]; then
        finding "live counterpart missing: $live (repo copy kept intact)"
        continue
      fi

      # Clean and capturable: copy live to repo mirror in working tree
      # D-38: Never runs git add and never commits
      if ((dry_run == 1)); then
        info "dry-run: would copy $live -> $repo_file"
      else
        if cp -p -- "$live" "$repo_file"; then
          pass "captured: $live -> $repo_file"
        else
          fail "failed to copy $live -> $repo_file"
        fi
      fi
    done < <(find "$pkg_dir" -type f -print0 | LC_ALL=C sort -z)
  done

  echo "=== done: FAIL=$fail_count FINDINGS=$finding_count ==="
  if ((fail_count > 0 || finding_count > 0)); then
    exit 1
  fi
  exit 0
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

  # Refusal gate for --exp-files (D-30..D-33 / CAP-08).
  # Sits in main() before the allowlist check so it covers install, install-files,
  # uninstall and any subcommand added later. Only this one flag is refused (D-32):
  # the nix, core and skip-family flags still route through 3.files-legacy.sh,
  # keeping the collision map valid. The font-set flag (--fontset) is recorded as
  # an accepted coverage gap in the map header rather than turned into a second refusal.
  for _arg in "$@"; do
    if [[ "$_arg" == "--exp-files" || "$_arg" == --exp-files=* ]]; then
      echo "[FAIL] Refusing --exp-files." >&2
      echo "[FAIL] It routes installation through sdata/subcmd-install/3.files-exp.sh," >&2
      echo "[FAIL] which reads its destinations from 3.files-exp.yaml and uses a different" >&2
      echo "[FAIL] set of write primitives (rsync -av --delete, rsync -av, cp -r, cp -r to" >&2
      echo "[FAIL] .old.N / .new) from the ones collision-map.tsv was derived from." >&2
      echo "[FAIL] Every row of collision-map.tsv would be void under this flag." >&2
      exit 2
    fi
  done

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
    verify)
      run_verify "$@"
      ;;
    capture)
      run_capture "$@"
      ;;
    *)
      run_install_family "$subcmd" "$@"
      ;;
  esac
}

# Dispatch guard (D-09). Written as an `if` block, NOT as the idiomatic
# conjunction one-liner: as the LAST statement of a sourced file the `[[ ... ]]`
# conjunction form leaves the source's return status at 1, which aborts a
# `set -e` caller before it can reach safe_rm_path (Phase 17 research F-5).
# Both spellings behave identically on direct execution; only the sourced path
# differs. Sourcing this file must define its functions and return 0 so
# safe_rm_path is reachable as a library function (D-21).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
