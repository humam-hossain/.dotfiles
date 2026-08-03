#!/usr/bin/env bash
# Phase 7 LIVE-01..04 automated smoke asserts (Nyquist validation).
# Also covers wrapper install dry-run + safe uninstall policy (no machine mutation
# beyond dry-run / abort-gate paths).
#
# Modes:
#   - Post-install (ii present): LIVE-01..04 hard asserts
#   - Post-uninstall (ii absent): LIVE ii asserts become SOFT; dual-run waybar +
#     wrapper policy still hard-assert
#
# Usage (from REPO_ROOT):
#   ./scripts/phase07-live-smoke.sh
# Exit 0 if all hard asserts pass; non-zero if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
soft() { printf '[SOFT] %s\n' "$1"; }

II_INSTALLED=0
if test -f "${HOME}/.config/quickshell/ii/shell.qml"; then
  II_INSTALLED=1
fi

echo "=== Phase 7 live smoke (LIVE-01..04 + wrapper policy) ==="
if ((II_INSTALLED)); then
  echo "[CONFIG] mode: post-install (ii tree present)"
else
  echo "[CONFIG] mode: post-uninstall / no-ii (LIVE ii asserts soft)"
fi

# --- LIVE-01 ---
if ((II_INSTALLED)); then
  if test ! -L "${HOME}/.config/quickshell" \
    && test -d "${HOME}/.config/quickshell" \
    && test -f "${HOME}/.config/quickshell/ii/shell.qml"; then
    pass "LIVE-01 real dir + ii/shell.qml"
  else
    fail "LIVE-01 real dir + ii/shell.qml"
  fi

  case "$(readlink -f "${HOME}/.config/quickshell" 2>/dev/null || true)" in
    */.dotfiles/.config/quickshell*) fail "LIVE-01 path under .dotfiles product" ;;
    *) pass "LIVE-01 path not under .dotfiles product" ;;
  esac

  if test -d "${HOME}/.local/state/quickshell/.venv"; then
    pass "LIVE-01 ii Python venv"
  else
    fail "LIVE-01 ii Python venv"
  fi
else
  soft "LIVE-01 ii tree absent (expected after safe uninstall)"
  if test -d "${HOME}/.config/quickshell"; then
    soft "LIVE-01 ~/.config/quickshell still exists without ii/shell.qml"
  else
    pass "LIVE-01 ~/.config/quickshell absent after uninstall"
  fi
fi

if test -f "${HOME}/.config/hypr/hyprland.conf" \
  && test ! -e "${HOME}/.config/hypr/hyprland.conf.old"; then
  pass "LIVE-01 personal hypr conf present, no .old"
else
  fail "LIVE-01 personal hypr conf present, no .old"
fi

# Phase 8 RET-01: in-repo v0.1 product tree was removed; live install is under $HOME only.
if test -d "${REPO_ROOT}/.config/quickshell"; then
  fail "RET-01 in-repo .config/quickshell must be absent (retired Phase 8)"
else
  pass "RET-01 in-repo .config/quickshell absent (retired)"
fi

# --- D-06 dry-run SAFE_DEFAULTS ---
bash -n ./arch/dots-hyprland.sh
pass "bash -n arch/dots-hyprland.sh"

DRY_OUT="$(mktemp)"
UN_OUT="$(mktemp)"
# shellcheck disable=SC2064
trap 'rm -f "$DRY_OUT" "$UN_OUT"' EXIT
if printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run >"$DRY_OUT" 2>&1; then
  if grep -q -- '--core' "$DRY_OUT" \
    && grep -q -- '--skip-hyprland' "$DRY_OUT" \
    && grep -q -- '--skip-sysupdate' "$DRY_OUT" \
    && grep -qiE 'dry-run|would exec' "$DRY_OUT"; then
    pass "D-06 install --dry-run SAFE_DEFAULTS"
  else
    fail "D-06 install --dry-run SAFE_DEFAULTS (argv missing)"
    sed -n '1,40p' "$DRY_OUT" || true
  fi
  # Post-install protect-list re-mark is part of dual-run safety (ii demotes asdeps).
  if grep -qE 'pacman -D --asexplicit|would re-mark as explicit|re-mark protect-list as explicit' "$DRY_OUT"; then
    pass "D-06 install --dry-run plans post-install protect asexplicit"
  else
    fail "D-06 install --dry-run missing post-install protect plan"
    sed -n '1,80p' "$DRY_OUT" || true
  fi
  if grep -qiE 'enable ii hooks|ii hooks already active|would enable ii hooks' "$DRY_OUT"; then
    pass "D-06 install --dry-run plans enable ii hooks"
  else
    fail "D-06 install --dry-run missing enable ii hooks plan"
    sed -n '1,80p' "$DRY_OUT" || true
  fi
else
  fail "D-06 install --dry-run exited non-zero"
  sed -n '1,40p' "$DRY_OUT" || true
fi

# install-deps dry-run also plans protect + enable (package-touching path)
if ./arch/dots-hyprland.sh install-deps --dry-run >"$DRY_OUT" 2>&1; then
  if grep -qE 'pacman -D --asexplicit|would re-mark as explicit|re-mark protect-list as explicit' "$DRY_OUT"; then
    pass "install-deps --dry-run plans post-install protect asexplicit"
  else
    fail "install-deps --dry-run missing post-install protect plan"
    sed -n '1,60p' "$DRY_OUT" || true
  fi
  if grep -qiE 'enable ii hooks|ii hooks already active|would enable ii hooks' "$DRY_OUT"; then
    pass "install-deps --dry-run plans enable ii hooks"
  else
    fail "install-deps --dry-run missing enable ii hooks plan"
    sed -n '1,60p' "$DRY_OUT" || true
  fi
else
  fail "install-deps --dry-run exited non-zero"
fi

# install-files dry-run mirrors real post-setup: protect re-mark + enable ii hooks
# (real path runs both for install|install-deps|install-files).
if printf 'yes\n' | ./arch/dots-hyprland.sh install-files --dry-run >"$DRY_OUT" 2>&1; then
  if grep -qE 're-mark protect-list as explicit|after setup, would re-mark' "$DRY_OUT"; then
    pass "install-files --dry-run plans post-install protect asexplicit"
  else
    fail "install-files --dry-run missing post-install protect plan"
    sed -n '1,40p' "$DRY_OUT" || true
  fi
  if grep -qiE 'enable ii hooks|ii hooks already active|would enable ii hooks' "$DRY_OUT"; then
    pass "install-files --dry-run plans enable ii hooks"
  else
    fail "install-files --dry-run missing enable ii hooks plan"
    sed -n '1,60p' "$DRY_OUT" || true
  fi
else
  fail "install-files --dry-run exited non-zero"
fi

# --- Safe uninstall dry-run / policy (no machine mutation) ---
if ./arch/dots-hyprland.sh uninstall --dry-run >"$UN_OUT" 2>&1; then
  # After a real uninstall there may be zero meta pkgs — accept either plan line or "no … to remove".
  # Do NOT treat warning text that *mentions* yay -Rns / pacman -Rsu as a cascade plan.
  # Only fail if dry-run would actually execute a cascade remove.
  safe_pkg_plan=0
  if grep -qF 'would run: sudo pacman -R --noconfirm' "$UN_OUT" \
    || grep -qF 'no illogical-impulse-* meta packages to remove' "$UN_OUT"; then
    safe_pkg_plan=1
  fi
  cascade_plan=0
  # Actual exec plans only (not "would NOT run yay -Rns" warnings)
  if grep -E 'would run:.*yay -Rns|would exec from .*[.]/setup uninstall' "$UN_OUT" >/dev/null; then
    cascade_plan=1
  fi
  if ((safe_pkg_plan == 1)) && ((cascade_plan == 0)) \
    && grep -qiE 'would NOT (touch|remove) hyprland|NOT touch hyprland|NOT remove hyprland' "$UN_OUT"; then
    pass "uninstall --dry-run uses pacman -R (no -Rns cascade)"
  else
    fail "uninstall --dry-run missing safe pacman -R plan"
    sed -n '1,60p' "$UN_OUT" || true
  fi
  # Protect-list: re-mark personal stack asexplicit so later orphan cleanup cannot
  # cascade-delete bc/jq/hyprland/kitty (ii install demotes them to asdeps).
  if grep -qE 'pacman -D --asexplicit|would re-mark as explicit|Protect-list: no listed' "$UN_OUT" \
    && grep -qiE 'yay -Yc|pacman -Rsu|orphan' "$UN_OUT"; then
    pass "uninstall --dry-run plans protect-list asexplicit (anti-orphan)"
  else
    fail "uninstall --dry-run missing protect-list asexplicit plan"
    sed -n '1,80p' "$UN_OUT" || true
  fi
  # Shared tools that dual-run needs must appear in protect plan when installed
  for _prot in bc jq; do
    if pacman -Qq "$_prot" &>/dev/null; then
      if grep -E "would re-mark as explicit|pacman -D --asexplicit" -A999 "$UN_OUT" \
        | grep -E "(^| )${_prot}( |$)" >/dev/null; then
        pass "uninstall --dry-run protect-list includes installed $_prot"
      else
        fail "uninstall --dry-run protect-list missing installed $_prot"
      fi
    else
      soft "uninstall protect-list: $_prot not installed (skip membership assert)"
    fi
  done
  if grep -qiE 'No running qs/quickshell|would stop qs|No hypr ii hooks|would delete ii hooks|keep hypr ii hooks' "$UN_OUT"; then
    pass "uninstall --dry-run surfaces qs stop and/or hypr-hook plan"
  else
    soft "uninstall --dry-run: no qs/hook plan lines (unexpected but non-fatal)"
  fi
  # Must not false-positive-kill shells whose cmdline merely mentions "qs -c"
  if grep -E 'would stop qs/quickshell PIDs:.*zsh|would stop qs/quickshell PIDs:.*bash' "$UN_OUT"; then
    fail "uninstall --dry-run false-positive qs match on shell"
  else
    pass "uninstall --dry-run no false-positive shell kill"
  fi
  # Help / usage documents process stop + hook delete + protect-list
  if ./arch/dots-hyprland.sh help 2>&1 | grep -q 'Stops running qs'; then
    pass "wrapper help documents qs process stop"
  else
    fail "wrapper help missing qs process stop"
  fi
  if ./arch/dots-hyprland.sh help 2>&1 | grep -q 'asexplicit'; then
    pass "wrapper help documents protect-list asexplicit"
  else
    fail "wrapper help missing protect-list asexplicit"
  fi
  if ./arch/dots-hyprland.sh help 2>&1 | grep -q -- '--skip-protect'; then
    pass "wrapper help documents --skip-protect"
  else
    fail "wrapper help missing --skip-protect"
  fi
else
  fail "uninstall --dry-run exited non-zero"
  sed -n '1,40p' "$UN_OUT" || true
fi

# --skip-protect dry-run must omit asexplicit re-mark
if ./arch/dots-hyprland.sh uninstall --dry-run --skip-protect >"$UN_OUT" 2>&1; then
  if grep -qiE 'skip protect-list|skipping protect|--skip-protect' "$UN_OUT" \
    && ! grep -q 'pacman -D --asexplicit' "$UN_OUT"; then
    pass "uninstall --dry-run --skip-protect omits asexplicit"
  else
    fail "uninstall --dry-run --skip-protect still plans asexplicit"
    sed -n '1,40p' "$UN_OUT" || true
  fi
else
  fail "uninstall --dry-run --skip-protect exited non-zero"
fi

# Abort gate must exit 1 and change nothing
if printf 'no\n' | ./arch/dots-hyprland.sh uninstall >"$UN_OUT" 2>&1; then
  fail "uninstall abort gate should exit non-zero"
else
  if grep -q 'Aborted (uninstall gate)' "$UN_OUT"; then
    pass "uninstall abort gate refuses without yes"
  else
    fail "uninstall abort gate message missing"
    sed -n '1,40p' "$UN_OUT" || true
  fi
fi

# Mutual exclusion
if ./arch/dots-hyprland.sh uninstall --packages-only --configs-only >"$UN_OUT" 2>&1; then
  fail "uninstall --packages-only --configs-only should fail"
else
  pass "uninstall packages/configs mutual exclusion"
fi

# Help lists uninstall + protect
if ./arch/dots-hyprland.sh help 2>&1 | grep -q 'uninstall'; then
  pass "wrapper help documents uninstall"
else
  fail "wrapper help missing uninstall"
fi
if ./arch/dots-hyprland.sh help 2>&1 | grep -qE '(^| )protect( |$)'; then
  pass "wrapper help documents protect subcommand"
else
  fail "wrapper help missing protect subcommand"
fi

# --- protect subcommand dry-run / policy ---
if ./arch/dots-hyprland.sh protect --dry-run >"$UN_OUT" 2>&1; then
  if grep -q 'pacman -D --asexplicit' "$UN_OUT" \
    || grep -qiE 'Protect-list: no listed|would re-mark as explicit' "$UN_OUT"; then
    pass "protect --dry-run plans asexplicit"
  else
    fail "protect --dry-run missing asexplicit plan"
    sed -n '1,40p' "$UN_OUT" || true
  fi
  # Without --install-missing, missing pkgs are reported not installed
  if ! pacman -Qq hyprland &>/dev/null; then
    if grep -qiE 'not installed|install-missing' "$UN_OUT"; then
      pass "protect --dry-run reports missing hyprland without --install-missing"
    else
      fail "protect --dry-run should list missing hyprland hint"
      sed -n '1,40p' "$UN_OUT" || true
    fi
  else
    soft "protect: hyprland present (skip missing-hint assert)"
  fi
else
  fail "protect --dry-run exited non-zero"
  sed -n '1,40p' "$UN_OUT" || true
fi

if ./arch/dots-hyprland.sh protect --dry-run --install-missing >"$UN_OUT" 2>&1; then
  if ! pacman -Qq hyprland &>/dev/null; then
    if grep -qF 'would run: sudo pacman -Sy --noconfirm --needed' "$UN_OUT" \
      && grep -E '(^| )hyprland( |$)' "$UN_OUT" >/dev/null; then
      pass "protect --dry-run --install-missing plans hyprland restore"
    else
      fail "protect --dry-run --install-missing missing hyprland restore plan"
      sed -n '1,60p' "$UN_OUT" || true
    fi
  else
    if grep -qiE 'all protect-list packages already installed|would re-mark as explicit|pacman -D --asexplicit' "$UN_OUT"; then
      pass "protect --dry-run --install-missing ok while fully installed"
    else
      fail "protect --dry-run --install-missing unexpected output"
      sed -n '1,40p' "$UN_OUT" || true
    fi
  fi
  # Must still plan asexplicit after optional install
  if grep -q 'pacman -D --asexplicit' "$UN_OUT" \
    || grep -qiE 'would re-mark as explicit|Protect-list: no listed' "$UN_OUT"; then
    pass "protect --install-missing still plans asexplicit"
  else
    fail "protect --install-missing missing asexplicit follow-up"
  fi
else
  fail "protect --dry-run --install-missing exited non-zero"
  sed -n '1,40p' "$UN_OUT" || true
fi

# Unknown protect flag rejected
if ./arch/dots-hyprland.sh protect --nope >"$UN_OUT" 2>&1; then
  fail "protect unknown flag should exit non-zero"
else
  if grep -qi 'Unknown protect flag' "$UN_OUT"; then
    pass "protect rejects unknown flags"
  else
    fail "protect unknown flag message missing"
    sed -n '1,20p' "$UN_OUT" || true
  fi
fi

# --- LIVE-02 (hooks active when installed; deleted when uninstalled) ---
if ((II_INSTALLED)); then
  if grep -E '^[[:space:]]*env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,' .config/hypr/hyprland.conf >/dev/null; then
    pass "LIVE-02 repo env ILLOGICAL_IMPULSE_VIRTUAL_ENV active"
  else
    fail "LIVE-02 repo env ILLOGICAL_IMPULSE_VIRTUAL_ENV active"
  fi

  if grep -E '^[[:space:]]*exec-once = qs -c ii' .config/hypr/hyprland.conf >/dev/null; then
    pass "LIVE-02 repo exec-once qs -c ii active"
  else
    fail "LIVE-02 repo exec-once qs -c ii active"
  fi
  # Must not leave disabled leftovers after enable
  if grep -E '^[[:space:]]*#.*exec-once = qs -c ii|^[[:space:]]*#.*ILLOGICAL_IMPULSE_VIRTUAL_ENV' .config/hypr/hyprland.conf >/dev/null; then
    fail "LIVE-02 repo still has commented ii hooks after install/enable"
  else
    pass "LIVE-02 repo has no commented ii hook leftovers"
  fi
else
  # After safe uninstall, hooks should be deleted (default) or still present with --keep-hypr-hooks
  if grep -E '^[[:space:]]*exec-once = qs -c ii' .config/hypr/hyprland.conf >/dev/null \
    || grep -E '^[[:space:]]*env = ILLOGICAL_IMPULSE_VIRTUAL_ENV' .config/hypr/hyprland.conf >/dev/null; then
    soft "LIVE-02 repo still has active ii hooks (kept via --keep-hypr-hooks?)"
  elif grep -E '^[[:space:]]*#.*exec-once = qs -c ii|^[[:space:]]*#.*ILLOGICAL_IMPULSE_VIRTUAL_ENV' .config/hypr/hyprland.conf >/dev/null; then
    soft "LIVE-02 repo has leftover commented ii hooks (pre-delete uninstall style)"
  else
    pass "LIVE-02 repo ii hooks deleted after uninstall"
  fi
fi

if cmp -s .config/hypr/hyprland.conf "${HOME}/.config/hypr/hyprland.conf"; then
  pass "LIVE-02 repo/live hyprland.conf cmp -s"
else
  # After uninstall both should still match if disable_hypr_ii_hooks touched both
  fail "LIVE-02 repo/live hyprland.conf cmp -s"
fi

# --- LIVE-03 dual-run waybar (required in both modes) ---
if pgrep -x waybar >/dev/null; then
  pass "LIVE-03 waybar process"
else
  fail "LIVE-03 waybar process"
fi

if grep -E 'exec-once = waybar' .config/hypr/hyprland.conf >/dev/null; then
  pass "LIVE-03 waybar exec-once preserved"
else
  fail "LIVE-03 waybar exec-once preserved"
fi

if pgrep -x swaync >/dev/null; then
  pass "LIVE-03 swaync soft present"
else
  soft "LIVE-03 swaync not running (soft assert)"
fi

# --- LIVE-04 automated (chrome is manual / UAT) ---
if ((II_INSTALLED)); then
  if pgrep -a qs 2>/dev/null | grep -E -- '-c ii|\bii\b' >/dev/null; then
    pass "LIVE-04 qs -c ii process"
  else
    fail "LIVE-04 qs -c ii process"
  fi

  QS_PID="$(pgrep -n -x qs 2>/dev/null || true)"
  if [[ -n "$QS_PID" ]] \
    && tr '\0' '\n' <"/proc/${QS_PID}/environ" 2>/dev/null \
      | grep -q '^ILLOGICAL_IMPULSE_VIRTUAL_ENV='; then
    pass "LIVE-04 qs environ has ILLOGICAL_IMPULSE_VIRTUAL_ENV"
  else
    fail "LIVE-04 qs environ has ILLOGICAL_IMPULSE_VIRTUAL_ENV"
  fi
else
  # Tight check: no qs/quickshell process for this user
  qs_left=0
  uid="$(id -u)"
  for proc in /proc/[0-9]*; do
    pid="${proc##*/}"
    owner="$(stat -c '%u' "$proc" 2>/dev/null || true)"
    [[ "$owner" == "$uid" ]] || continue
    comm="$(cat "$proc/comm" 2>/dev/null || true)"
    exe="$(readlink "$proc/exe" 2>/dev/null || true)"
    exe_base="${exe% (deleted)}"
    exe_base="${exe_base##*/}"
    cmdline="$(tr '\0' ' ' <"$proc/cmdline" 2>/dev/null || true)"
    argv0="${cmdline%% *}"
    argv0="${argv0##*/}"
    if [[ "$comm" == "qs" || "$comm" == "quickshell" \
      || "$exe_base" == "qs" || "$exe_base" == "quickshell" \
      || "$argv0" == "qs" || "$argv0" == "quickshell" ]]; then
      qs_left=1
      break
    fi
  done
  if ((qs_left == 0)); then
    pass "LIVE-04 no qs/quickshell process after uninstall"
  else
    fail "LIVE-04 qs/quickshell still running after uninstall"
  fi
fi

# hyprland must survive *safe* uninstall (pacman -R metas only). If missing after
# post-uninstall, that is external damage (yay -Yc / pacman -Rsu on asdeps) — soft
# when ii is already gone; hard when ii is still installed (session must work).
if pacman -Qq hyprland &>/dev/null; then
  pass "hyprland package still installed"
elif ((II_INSTALLED)); then
  fail "hyprland package missing while ii is installed"
else
  soft "hyprland package missing post-uninstall (restore: ./arch/dots-hyprland.sh protect --install-missing) — likely orphan cleanup after ii demoted it to asdeps"
fi

echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
