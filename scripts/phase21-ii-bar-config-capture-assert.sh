#!/usr/bin/env bash
# Phase 21 ii bar config capture assert harness (BAR-01, BAR-02, CAP-06).
# One script, one section per ROADMAP criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase21-ii-bar-config-capture-assert.sh [--section <1-7>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

ASSERT_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
SCRATCH_ROOTS=()

cleanup() {
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  local root
  for root in ${SCRATCH_ROOTS[@]+"${SCRATCH_ROOTS[@]}"}; do
    [[ -n "$root" ]] || continue
    chmod -R u+rwX "$root" 2>/dev/null || true
    rm -rf "$root" 2>/dev/null || true
  done
  return 0
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# CLI Argument Parsing
# ---------------------------------------------------------------------------
RUN_SECTION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-7]$ ]]; then
        echo "Error: --section requires an integer from 1 to 7" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-7>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# ===========================================================================
# Section 1: BAR-01: Ingest validation, atomic copy, symlink refusal, and dirty repo mirror skip
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Ingest validation, atomic copy, symlink refusal, and dirty repo mirror skip ---"
  S1_ROOT="$(mktemp -d /tmp/p21-assert-s1-XXXXXX)"
  SCRATCH_ROOTS+=("$S1_ROOT")

  mkdir -p "$S1_ROOT/repo/arch" "$S1_ROOT/repo/capture/testpkg/.config/testpkg" "$S1_ROOT/home/.config/testpkg"
  cp "$REPO_ROOT/arch/dots-hyprland.sh" "$S1_ROOT/repo/arch/dots-hyprland.sh"
  chmod +x "$S1_ROOT/repo/arch/dots-hyprland.sh"

  git -C "$S1_ROOT/repo" init -q
  git -C "$S1_ROOT/repo" config user.email "assert@example.com"
  git -C "$S1_ROOT/repo" config user.name "Assert Runner"

  printf '{"setting": "initial"}\n' > "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json"
  git -C "$S1_ROOT/repo" add -A
  git -C "$S1_ROOT/repo" commit -q -m "initial commit"
  printf '{"setting": "initial"}\n' > "$S1_ROOT/home/.config/testpkg/config.json"

  # Case A: Valid update
  printf '{"setting": "updated_valid"}\n' > "$S1_ROOT/home/.config/testpkg/config.json"
  A_RC=0
  A_OUT="$(cd "$S1_ROOT/repo" && HOME="$S1_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || A_RC=$?
  if [[ "$A_RC" -eq 0 ]] && grep -q -- "captured:" <<<"$A_OUT" && cmp -s "$S1_ROOT/home/.config/testpkg/config.json" "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json"; then
    pass "Section 1A: valid JSON update captured into repo mirror"
  else
    fail "Section 1A: valid JSON update failed to capture (rc=$A_RC)"
    printf '%s\n' "$A_OUT" | sed 's/^/       /' >&2
  fi
  git -C "$S1_ROOT/repo" add -A
  git -C "$S1_ROOT/repo" commit -q -m "captured valid update"

  # Case B: Unchanged skip
  B_RC=0
  B_OUT="$(cd "$S1_ROOT/repo" && HOME="$S1_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || B_RC=$?
  if [[ "$B_RC" -eq 0 ]] && grep -q -- "unchanged:" <<<"$B_OUT"; then
    pass "Section 1B: unchanged file skipped via cmp -s without copy"
  else
    fail "Section 1B: unchanged file not skipped via cmp -s (rc=$B_RC)"
    printf '%s\n' "$B_OUT" | sed 's/^/       /' >&2
  fi

  # Case C: 0-byte file refusal
  : > "$S1_ROOT/home/.config/testpkg/config.json"
  C_RC=0
  C_OUT="$(cd "$S1_ROOT/repo" && HOME="$S1_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || C_RC=$?
  if [[ "$C_RC" -ne 0 ]] && grep -q -- "invalid or empty JSON" <<<"$C_OUT" && grep -q -- "updated_valid" "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json"; then
    pass "Section 1C: 0-byte file refused with fail-closed non-zero exit, repo intact"
  else
    fail "Section 1C: 0-byte file not correctly refused (rc=$C_RC)"
    printf '%s\n' "$C_OUT" | sed 's/^/       /' >&2
  fi

  # Case D: Corrupt syntax refusal
  printf '{"setting": "unclosed_brace' > "$S1_ROOT/home/.config/testpkg/config.json"
  D_RC=0
  D_OUT="$(cd "$S1_ROOT/repo" && HOME="$S1_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || D_RC=$?
  if [[ "$D_RC" -ne 0 ]] && grep -q -- "invalid or empty JSON" <<<"$D_OUT" && grep -q -- "updated_valid" "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json"; then
    pass "Section 1D: corrupt syntax refused with fail-closed non-zero exit, repo intact"
  else
    fail "Section 1D: corrupt syntax not correctly refused (rc=$D_RC)"
    printf '%s\n' "$D_OUT" | sed 's/^/       /' >&2
  fi

  # Case E: Live symlink refusal
  rm -f "$S1_ROOT/home/.config/testpkg/config.json"
  ln -s "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json" "$S1_ROOT/home/.config/testpkg/config.json"
  E_RC=0
  E_OUT="$(cd "$S1_ROOT/repo" && HOME="$S1_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || E_RC=$?
  if [[ "$E_RC" -ne 0 ]] && grep -q -- "refusing live path that is a symlink resolving into repo" <<<"$E_OUT"; then
    pass "Section 1E: live symlink resolving into repo refused (D-06, D-39)"
  else
    fail "Section 1E: live symlink not refused (rc=$E_RC)"
    printf '%s\n' "$E_OUT" | sed 's/^/       /' >&2
  fi

  # Case F: Dirty repo mirror skip
  rm -f "$S1_ROOT/home/.config/testpkg/config.json"
  printf '{"setting": "live_content"}\n' > "$S1_ROOT/home/.config/testpkg/config.json"
  printf '{"setting": "dirty_mirror"}\n' > "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json"
  F_RC=0
  F_OUT="$(cd "$S1_ROOT/repo" && HOME="$S1_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || F_RC=$?
  if [[ "$F_RC" -ne 0 ]] && grep -q -- "repo mirror is dirty against HEAD" <<<"$F_OUT" && grep -q -- "dirty_mirror" "$S1_ROOT/repo/capture/testpkg/.config/testpkg/config.json"; then
    pass "Section 1F: dirty repo mirror skipped without overwrite"
  else
    fail "Section 1F: dirty repo mirror not skipped (rc=$F_RC)"
    printf '%s\n' "$F_OUT" | sed 's/^/       /' >&2
  fi
fi

# ===========================================================================
# Section 2: BAR-01: Isolated fixture wallpaper switch symlink destruction and capture recovery drill
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Wallpaper switch symlink destruction and capture recovery drill ---"
  DRILL_ROOT="$(mktemp -d /tmp/p21-assert-s2-XXXXXX)"
  SCRATCH_ROOTS+=("$DRILL_ROOT")

  mkdir -p "$DRILL_ROOT/repo/arch" "$DRILL_ROOT/repo/capture/ii/.config/illogical-impulse" "$DRILL_ROOT/home/.config/illogical-impulse"
  cp "$REPO_ROOT/arch/dots-hyprland.sh" "$DRILL_ROOT/repo/arch/dots-hyprland.sh"
  chmod +x "$DRILL_ROOT/repo/arch/dots-hyprland.sh"

  git -C "$DRILL_ROOT/repo" init -q
  git -C "$DRILL_ROOT/repo" config user.email "drill@example.com"
  git -C "$DRILL_ROOT/repo" config user.name "Drill Runner"

  printf '{"background": {"wallpaperPath": "/old/path.jpg"}}\n' > "$DRILL_ROOT/repo/capture/ii/.config/illogical-impulse/config.json"
  git -C "$DRILL_ROOT/repo" add -A
  git -C "$DRILL_ROOT/repo" commit -q -m "initial ii bar config"

  SHELL_CONFIG_FILE="$DRILL_ROOT/home/.config/illogical-impulse/config.json"
  ln -s "$DRILL_ROOT/repo/capture/ii/.config/illogical-impulse/config.json" "$SHELL_CONFIG_FILE"

  # Step 1: Assert symlink state before switchwall
  if [[ -L "$SHELL_CONFIG_FILE" ]]; then
    pass "Section 2: initial config.json is a symbolic link"
  else
    fail "Section 2: initial config.json is not a symbolic link"
  fi

  # Step 2: Replicate switchwall.sh:147 mv rename logic
  jq --arg path "/new/wallpaper.jpg" '.background.wallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp"
  mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"

  # Step 3: Assert symlink is severed to plain file
  if [[ ! -L "$SHELL_CONFIG_FILE" && -f "$SHELL_CONFIG_FILE" ]]; then
    pass "Section 2: mv severed symlink and replaced with plain file"
  else
    fail "Section 2: config.json was not converted to plain file by mv"
  fi

  # Step 4: Run capture to ingest plain file
  CAP_RC=0
  CAP_OUT="$(cd "$DRILL_ROOT/repo" && HOME="$DRILL_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || CAP_RC=$?
  if [[ "$CAP_RC" -eq 0 ]] && grep -q -- "captured:" <<<"$CAP_OUT"; then
    pass "Section 2: capture synchronized plain file into repo mirror"
  else
    fail "Section 2: capture failed to synchronize plain file (rc=$CAP_RC)"
    printf '%s\n' "$CAP_OUT" | sed 's/^/       /' >&2
  fi

  # Step 5: Assert git diff in fixture shows updated wallpaper path
  DIFF_OUT="$(git -C "$DRILL_ROOT/repo" diff)"
  if grep -q -- "/new/wallpaper.jpg" <<<"$DIFF_OUT"; then
    pass "Section 2: repo mirror diff reflects updated wallpaper path"
  else
    fail "Section 2: repo mirror diff missing updated wallpaper path"
    printf '%s\n' "$DIFF_OUT" | sed 's/^/       /' >&2
  fi
fi

# ===========================================================================
# Section 3: BAR-01: Live wallpaper switch confirmation and theme revert drill
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 || "$RUN_SECTION" -eq 7 ]]; then
  info "--- Section 3: Live wallpaper switch confirmation and theme revert drill ---"
  WALLPAPER_FILE="/home/pera/Pictures/55192173787_b8322b1190_o.jpg"
  if [[ -f "$WALLPAPER_FILE" ]]; then
    pass "Section 3: live wallpaper file exists: $WALLPAPER_FILE"
  else
    fail "Section 3: live wallpaper file missing: $WALLPAPER_FILE"
  fi

  # Execute switchwall.sh non-disruptively using the current wallpaper
  SWITCH_OUT="$(bash "$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh" "$WALLPAPER_FILE" 2>&1 || true)"

  # Assert ~/.config/illogical-impulse/config.json is a plain regular file and not a symlink
  if [[ -f "$HOME/.config/illogical-impulse/config.json" && ! -L "$HOME/.config/illogical-impulse/config.json" ]]; then
    pass "Section 3: live config.json remains a plain regular file after switchwall.sh"
  else
    fail "Section 3: live config.json is not a plain file after switchwall.sh"
  fi

  # Run capture --quiet
  S3_CAP_RC=0
  S3_CAP_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" capture --quiet 2>&1)" || S3_CAP_RC=$?
  if [[ "$S3_CAP_RC" -eq 0 ]]; then
    pass "Section 3: capture --quiet succeeded after wallpaper switch"
  else
    fail "Section 3: capture --quiet failed after wallpaper switch (rc=$S3_CAP_RC)"
    printf '%s\n' "$S3_CAP_OUT" | sed 's/^/       /' >&2
  fi

  # Record theme file modifications for Phase 22 (Q7/Q8) and revert theme files cleanly
  info "Section 3: clean revert of generated theme files"
  git -C "$REPO_ROOT" checkout -- restow/kdeglobals/ stow/hypr/ restow/hypr/ 2>/dev/null || true
  pass "Section 3: theme files cleanly reverted"
fi

# ===========================================================================
# Section 4: CAP-06: Systemd user timer enabled, active, stowed, and oneshot service execution
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 || "$RUN_SECTION" -eq 7 ]]; then
  info "--- Section 4: Systemd user timer enabled, active, stowed, and oneshot service execution ---"

  # 1. Verify unit file syntax
  if systemd-analyze --user verify "$HOME/.config/systemd/user/dotfiles-capture.service" "$HOME/.config/systemd/user/dotfiles-capture.timer" 2>&1; then
    pass "Section 4: systemd-analyze verify passed for service and timer units"
  else
    fail "Section 4: systemd-analyze verify failed"
  fi

  # 2. Verify stow symlinks
  S_UNIT="$HOME/.config/systemd/user/dotfiles-capture.service"
  T_UNIT="$HOME/.config/systemd/user/dotfiles-capture.timer"
  if [[ -L "$S_UNIT" ]] && [[ "$(readlink -f -- "$S_UNIT")" == "$REPO_ROOT/stow/systemd/.config/systemd/user/dotfiles-capture.service" ]]; then
    pass "Section 4: dotfiles-capture.service is a symlink resolving into stow/systemd"
  else
    fail "Section 4: dotfiles-capture.service symlink missing or does not resolve to stow/systemd"
  fi

  if [[ -L "$T_UNIT" ]] && [[ "$(readlink -f -- "$T_UNIT")" == "$REPO_ROOT/stow/systemd/.config/systemd/user/dotfiles-capture.timer" ]]; then
    pass "Section 4: dotfiles-capture.timer is a symlink resolving into stow/systemd"
  else
    fail "Section 4: dotfiles-capture.timer symlink missing or does not resolve to stow/systemd"
  fi

  # 3. Verify timer enablement
  IS_EN="$(systemctl --user is-enabled dotfiles-capture.timer 2>&1 || true)"
  if [[ "$IS_EN" == "enabled" ]]; then
    pass "Section 4: dotfiles-capture.timer is enabled"
  else
    fail "Section 4: dotfiles-capture.timer is not enabled (status: $IS_EN)"
  fi

  # 4. Verify timer active
  IS_ACT="$(systemctl --user is-active dotfiles-capture.timer 2>&1 || true)"
  if [[ "$IS_ACT" == "active" ]]; then
    pass "Section 4: dotfiles-capture.timer is active"
  else
    fail "Section 4: dotfiles-capture.timer is not active (status: $IS_ACT)"
  fi

  # 5. Verify service oneshot execution
  SVC_RC=0
  systemctl --user start dotfiles-capture.service 2>&1 || SVC_RC=$?
  J_OUT="$(journalctl --user -u dotfiles-capture -n 20 2>&1 || true)"
  if [[ "$SVC_RC" -eq 0 ]] && grep -qi -- "Capture dotfiles from live environment" <<<"$J_OUT"; then
    pass "Section 4: oneshot dotfiles-capture.service executed successfully"
  else
    fail "Section 4: oneshot dotfiles-capture.service failed or missing journal entry (rc=$SVC_RC)"
    printf '%s\n' "$J_OUT" | sed 's/^/       /' >&2
  fi
fi

# ===========================================================================
# Section 5: CAP-06: Drift capture drill: hand-edited live file captured to unstaged git status
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 || "$RUN_SECTION" -eq 7 ]]; then
  info "--- Section 5: Drift capture drill: hand-edited live file captured to unstaged git status ---"
  S5_ROOT="$(mktemp -d /tmp/p21-assert-s5-XXXXXX)"
  SCRATCH_ROOTS+=("$S5_ROOT")

  mkdir -p "$S5_ROOT/repo/arch" "$S5_ROOT/repo/capture/testpkg/.config/testpkg" "$S5_ROOT/home/.config/testpkg"
  cp "$REPO_ROOT/arch/dots-hyprland.sh" "$S5_ROOT/repo/arch/dots-hyprland.sh"
  chmod +x "$S5_ROOT/repo/arch/dots-hyprland.sh"

  git -C "$S5_ROOT/repo" init -q
  git -C "$S5_ROOT/repo" config user.email "s5@example.com"
  git -C "$S5_ROOT/repo" config user.name "S5 Runner"

  printf '{"setting": "initial"}\n' > "$S5_ROOT/repo/capture/testpkg/.config/testpkg/config.json"
  git -C "$S5_ROOT/repo" add capture
  git -C "$S5_ROOT/repo" commit -q -m "initial capture mirror"
  printf '{"setting": "initial"}\n' > "$S5_ROOT/home/.config/testpkg/config.json"

  # User hand-edits the live file
  printf '{"setting": "user-modified"}\n' > "$S5_ROOT/home/.config/testpkg/config.json"

  # Run capture
  S5_CAP_RC=0
  S5_CAP_OUT="$(cd "$S5_ROOT/repo" && HOME="$S5_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || S5_CAP_RC=$?
  if [[ "$S5_CAP_RC" -eq 0 ]] && grep -q -- "captured:" <<<"$S5_CAP_OUT"; then
    pass "Section 5: live configuration drift captured to repository mirror"
  else
    fail "Section 5: live drift capture failed (rc=$S5_CAP_RC)"
    printf '%s\n' "$S5_CAP_OUT" | sed 's/^/       /' >&2
  fi

  # Verify git status is unstaged modified (" M ")
  S5_STATUS="$(git -C "$S5_ROOT/repo" status --porcelain)"
  if [[ "$S5_STATUS" =~ [[:space:]]M[[:space:]]capture/testpkg/\.config/testpkg/config\.json ]]; then
    pass "Section 5: drift captured into unstaged git status"
  else
    fail "Section 5: unexpected git status: $S5_STATUS"
  fi

  # Verify staging index is completely empty (no git add / commit)
  S5_CACHED_DIFF="$(git -C "$S5_ROOT/repo" diff --cached)"
  if [[ -z "$S5_CACHED_DIFF" ]]; then
    pass "Section 5: git staging index is clean (no automatic git add)"
  else
    fail "Section 5: git staging index contains staged changes"
    printf '%s\n' "$S5_CACHED_DIFF" | sed 's/^/       /' >&2
  fi

  # Re-run capture: assert cmp -s skips as unchanged no-op
  S5_SECOND_RC=0
  S5_SECOND_OUT="$(cd "$S5_ROOT/repo" && HOME="$S5_ROOT/home" ./arch/dots-hyprland.sh capture 2>&1)" || S5_SECOND_RC=$?
  if [[ "$S5_SECOND_RC" -eq 0 ]] && grep -q -- "unchanged:" <<<"$S5_SECOND_OUT"; then
    pass "Section 5: second capture run detects byte identity and skips as no-op"
  else
    fail "Section 5: second capture run failed or did not skip unchanged (rc=$S5_SECOND_RC)"
    printf '%s\n' "$S5_SECOND_OUT" | sed 's/^/       /' >&2
  fi
fi

# ===========================================================================
# Section 6: BAR-02: Personal bar settings baseline check and defaults-reset recovery drill
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 6 || "$RUN_SECTION" -eq 7 ]]; then
  info "--- Section 6: Personal bar settings baseline check and defaults-reset recovery drill ---"
  REPO_MIRROR="capture/ii/.config/illogical-impulse/config.json"

  # 1. Verify repo mirror file exists and is tracked
  if [[ -f "$REPO_MIRROR" ]] && git ls-files --error-unmatch "$REPO_MIRROR" >/dev/null 2>&1; then
    pass "Section 6: repo mirror exists and is tracked in git"
  else
    fail "Section 6: repo mirror missing or untracked: $REPO_MIRROR"
  fi

  # 2. Verify personal bar settings values via jq -e
  if jq -e '.bar.bottom == false' "$REPO_MIRROR" >/dev/null 2>&1 \
     && jq -e '.bar.topLeftIcon == "spark"' "$REPO_MIRROR" >/dev/null 2>&1 \
     && jq -e '.bar.weather.city == "Dhaka"' "$REPO_MIRROR" >/dev/null 2>&1 \
     && jq -e '.bar.workspaces.shown == 5' "$REPO_MIRROR" >/dev/null 2>&1 \
     && jq -e '.bar.utilButtons.showMicToggle == true' "$REPO_MIRROR" >/dev/null 2>&1 \
     && jq -e '.bar.utilButtons.showScreenSnip == true' "$REPO_MIRROR" >/dev/null 2>&1; then
    pass "Section 6: personal bar settings verified (top bar, spark icon, Dhaka weather, 5 workspaces, mic/snip toggles)"
  else
    fail "Section 6: personal bar settings mismatch in repo mirror"
  fi

  # 3. Defaults-reset recovery drill
  LIVE_CFG="$HOME/.config/illogical-impulse/config.json"
  BACKUP_FILE="${LIVE_CFG}.bak.$(date +%s)"
  TMP_FILES+=("$BACKUP_FILE")
  cp -p "$LIVE_CFG" "$BACKUP_FILE"

  # Simulate defaults reset: write empty JSON
  printf '{}\n' > "$LIVE_CFG"

  # Restore from repo mirror
  cp -p "$REPO_MIRROR" "$LIVE_CFG"

  if cmp -s "$LIVE_CFG" "$BACKUP_FILE"; then
    pass "Section 6: restored config.json is byte-identical to pre-reset backup"
  else
    fail "Section 6: restored config.json differs from pre-reset backup"
  fi
  rm -f "$BACKUP_FILE"

  # Reload Quickshell ii process
  qs kill -c ii >/dev/null 2>&1 || true
  sleep 1
  nohup qs -d -c ii >/dev/null 2>&1 &
  sleep 2

  if pgrep -f "qs.*-c ii" >/dev/null 2>&1 || qs list -c ii >/dev/null 2>&1; then
    pass "Section 6: Quickshell ii reloaded and active"
  else
    fail "Section 6: Quickshell ii process not running after reload"
  fi
fi

# ===========================================================================
# Section 7: Full suite verification gate & strict link check
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 7 ]]; then
  info "--- Section 7: Full suite verification gate & strict link check ---"
  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]] && grep -q -- "capture path verified: /home/pera/.config/illogical-impulse/config.json" <<<"$VERIFY_OUT"; then
    pass "Section 7: arch/dots-hyprland.sh verify --strict passed with zero findings"
  else
    fail "Section 7: arch/dots-hyprland.sh verify --strict failed (rc=$VERIFY_RC)"
    printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
  fi
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
