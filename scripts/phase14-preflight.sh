#!/usr/bin/env bash
# Phase 14 live-adopt preflight — mechanical go conditions for the ADOPT-01 window.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase14-preflight.sh                 # check only; never mutates $HOME
#   ./scripts/phase14-preflight.sh --rotate-backup # checks, then the ONE mutating step
#   ./scripts/phase14-preflight.sh --help
# Exit 0 if all hard asserts pass; non-zero if any hard FAIL.
#
# Output levels:
#   [PASS]     hard condition satisfied
#   [FAIL]     hard condition violated — moves the exit code
#   [FINDING]  reported condition the script deliberately declines to encode as an
#              exit code; it is dispositioned by the runbook's go/no-go checklist
#              (D-18). FINDINGS never move the exit code.
#
# Constraints (Phase 14):
#   - The default path (no arguments) performs no mv/rm/cp/rsync under $HOME. It is
#     read-only against the operator's home directory and safe to run repeatedly
#     (D-13, D-27, RESEARCH Pitfall 2).
#   - The single mutating step is `--rotate-backup`. It is opt-in, it runs only
#     after every check has run, and nothing on the default path calls it.
#   - Never call ./setup or arch/dots-hyprland.sh without --dry-run.
#   - The exit code is input 1 to the go/no-go gate in
#     docs/phase14-adopt-runbook.md — it is not the gate itself (D-18).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }

XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/ii-original-dots-backup"
WRAP="./arch/dots-hyprland.sh"
VENDOR="vendor/dots-hyprland"
RUNBOOK="docs/phase14-adopt-runbook.md"
INVENTORY=".planning/phases/10-full-install-impact-inventory/10-INVENTORY.md"
DISPOSITIONS=".planning/phases/11-disposition-decisions/11-DISPOSITIONS.md"
REPO_HYPRCONF=".config/hypr/hyprland.conf"

usage() {
  cat <<'EOF'
Usage: ./scripts/phase14-preflight.sh [--rotate-backup]

  (default)         Check only. Reports every mechanical go condition for the
                    Phase 14 live adopt window and exits 0 when all hard
                    conditions hold. Performs NO mv/rm/cp/rsync under $HOME and
                    never invokes the wrapper without --dry-run. Safe to re-run.

  --rotate-backup   THE ONLY MUTATING PATH IN THIS SCRIPT. Runs every check
                    first, then moves ~/ii-original-dots-backup aside to a
                    timestamped name so upstream's auto_backup_configs takes a
                    fresh backup on either `ask` branch (D-27). One `mv`, no
                    delete of any kind. Refuses if the directory is absent or if
                    the timestamped destination already exists.
                    Run this inside the adopt window, not during prep.

  -h, --help        Show this help and exit 0.

Output levels: [PASS] hard condition met; [FINDING] reported condition the
runbook's go/no-go checklist must disposition by hand (never moves the exit
code); [FAIL] hard condition violated (moves the exit code).

The exit code is input 1 to the go/no-go gate in docs/phase14-adopt-runbook.md.
It is not the gate itself (D-18).
EOF
}

# --- rotation: the one mutating operation, reachable only via --rotate-backup ---
rotate_backup() {
  local dest
  dest="${BACKUP_DIR}.$(date -u +%Y%m%dT%H%M%SZ)"
  if [[ ! -d "$BACKUP_DIR" ]]; then
    printf '[FAIL] rotate: %s does not exist; nothing to rotate\n' "$BACKUP_DIR" >&2
    return 1
  fi
  if [[ -e "$dest" ]]; then
    printf '[FAIL] rotate: destination already exists: %s\n' "$dest" >&2
    return 1
  fi
  mv "$BACKUP_DIR" "$dest"
  printf '[ROTATED] old: %s\n' "$BACKUP_DIR"
  printf '[ROTATED] new: %s\n' "$dest"
  printf '[ROTATED] re-run ./scripts/phase14-preflight.sh; the ii-original-dots-backup line should now be [PASS].\n'
}

ROTATE=0
for arg in "$@"; do
  case "$arg" in
    --rotate-backup) ROTATE=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[FAIL] unknown arg: $arg" >&2
      exit 1
      ;;
  esac
done

FULL_OUT="$(mktemp /tmp/p14-preflight-full-XXXXXX)"
UNINST_OUT="$(mktemp /tmp/p14-preflight-uninst-XXXXXX)"
PROTECT_OUT="$(mktemp /tmp/p14-preflight-protect-XXXXXX)"
# shellcheck disable=SC2064
trap 'rm -f "$FULL_OUT" "$UNINST_OUT" "$PROTECT_OUT"' EXIT

echo "=== Phase 14 adopt preflight (non-mutating on the default path) ==="
echo "[CONFIG] repo_root=$REPO_ROOT"
echo "[CONFIG] xdg=$XDG"
echo "[CONFIG] backup_dir=$BACKUP_DIR"
echo "[CONFIG] rotate_requested=$ROTATE"

# --- D-34: not-firstrun marker (hard precondition; every later check depends on it) ---
if [[ -f "$XDG/illogical-impulse/installed_true" ]]; then
  pass "D-34 not-firstrun marker present: $XDG/illogical-impulse/installed_true"
else
  fail "D-34 not-firstrun marker missing: $XDG/illogical-impulse/installed_true"
  echo "       Without installed_true, upstream sets INSTALL_FIRSTRUN=true and replaces"
  echo "       live hyprlock.conf / hypridle.conf instead of writing .new sidecars."
  echo "       Phase 11 D-24 (lock/idle no-touch) stops holding. Adopt is a no-go."
  echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
  exit 1
fi

# --- D-12: vendor submodule pin recorded and clean ---
VENDOR_PIN="$(git -C "$VENDOR" rev-parse HEAD)"
echo "[CONFIG] submodule pin=$VENDOR_PIN"
VENDOR_DIRTY="$(git -C "$VENDOR" status --porcelain)"
VENDOR_SUBS="$(git -C "$VENDOR" submodule status --recursive 2>/dev/null | grep -E '^[+U-]' || true)"
PARENT_VENDOR_DIRTY="$(git status --porcelain -- "$VENDOR")"
if [[ -z "$VENDOR_DIRTY" && -z "$VENDOR_SUBS" && -z "$PARENT_VENDOR_DIRTY" ]]; then
  pass "D-12 vendor submodule clean and pin matches parent: $VENDOR_PIN"
else
  fail "D-12 vendor submodule dirty or pin mismatch"
  [[ -n "$VENDOR_DIRTY" ]] && printf '       worktree: %s\n' "$VENDOR_DIRTY"
  [[ -n "$VENDOR_SUBS" ]] && printf '       nested submodule: %s\n' "$VENDOR_SUBS"
  [[ -n "$PARENT_VENDOR_DIRTY" ]] && printf '       parent records a different pin: %s\n' "$PARENT_VENDOR_DIRTY"
fi

# --- ADOPT-01: Phase 10 / Phase 11 source-of-truth artifacts ---
if [[ -s "$INVENTORY" ]]; then
  pass "ADOPT-01 INV-01 inventory present and non-empty: $INVENTORY"
else
  fail "ADOPT-01 INV-01 inventory missing or empty: $INVENTORY"
fi
if [[ -s "$DISPOSITIONS" ]]; then
  pass "ADOPT-01 DISP-01 dispositions present and non-empty: $DISPOSITIONS"
else
  fail "ADOPT-01 DISP-01 dispositions missing or empty: $DISPOSITIONS"
fi
if ./scripts/phase10-inventory-assert.sh >/dev/null 2>&1; then
  pass "ADOPT-01 INV-01 phase10-inventory-assert.sh exits 0"
else
  fail "ADOPT-01 INV-01 phase10-inventory-assert.sh exited non-zero"
  ./scripts/phase10-inventory-assert.sh 2>&1 | grep '^\[FAIL\]' | sed -n '1,10p' || true
fi
if ./scripts/phase11-dispositions-assert.sh >/dev/null 2>&1; then
  pass "ADOPT-01 DISP-01 phase11-dispositions-assert.sh exits 0"
else
  fail "ADOPT-01 DISP-01 phase11-dispositions-assert.sh exited non-zero"
  ./scripts/phase11-dispositions-assert.sh 2>&1 | grep '^\[FAIL\]' | sed -n '1,10p' || true
fi

# --- Overlay readiness (Phase 13 D-19): the overlay the window applies at step 8 ---
OVL=".config/hypr/custom"
if [[ -s "$OVL/general.lua" ]] \
  && [[ "$(grep -c 'hl.monitor' "$OVL/general.lua")" -eq 2 ]] \
  && [[ "$(grep -c 'hl.workspace_rule' "$OVL/general.lua")" -eq 11 ]] \
  && [[ -f "$OVL/env.lua" ]] && [[ -f "$OVL/execs.lua" ]]; then
  pass "overlay readiness: general.lua non-empty, hl.monitor==2, hl.workspace_rule==11, env/execs slots present"
else
  fail "overlay readiness: general.lua content or env/execs slots wrong under $OVL"
fi
if ./scripts/phase13-d19-assert.sh >/dev/null 2>&1; then
  pass "overlay readiness: phase13-d19-assert.sh exits 0"
else
  fail "overlay readiness: phase13-d19-assert.sh exited non-zero"
  ./scripts/phase13-d19-assert.sh 2>&1 | grep '^\[FAIL\]' | sed -n '1,10p' || true
fi

# --- D-15/D-35: the runbook the operator reads at a TTY must be the version on GitHub ---
# D-35 is "clean apart from this phase's own transcript and verify artifacts". The
# runbook orders section 2 (script(1) starts the transcript) before section 3 (this
# check), so the transcript is guaranteed to be present and untracked by the time the
# gate runs. Excusing exactly these three paths is what makes the gate reachable at
# all; anything else dirty is still a hard FAIL.
PHASE14_ARTIFACTS=(
  ".planning/phases/14-live-full-adopt-verify/14-ADOPT-TRANSCRIPT.txt"
  ".planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md"
  "scripts/phase14-verify.sh"
)
PORCELAIN_ALL="$(git status --porcelain)"
PORCELAIN="$PORCELAIN_ALL"
EXCUSED=""
# Match the porcelain path exactly. An unanchored substring match also excuses
# 14-LIVE-VERIFY.md.orig, phase14-verify.sh.bak and any other look-alike, which
# would let real uncommitted work slip past the D-15/D-35 gate. phase14-verify.sh
# implements this same gate with a prefix match; the two must not disagree.
for artifact in "${PHASE14_ARTIFACTS[@]}"; do
  hit=""
  REMAINING=""
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # porcelain is "XY <path>"; strip the 2-char status field and its separator
    if [[ "${line:3}" == "$artifact" ]]; then
      hit+="$line"$'\n'
    else
      REMAINING+="$line"$'\n'
    fi
  done <<< "$PORCELAIN"
  if [[ -n "$hit" ]]; then
    EXCUSED+="$hit"
    PORCELAIN="$REMAINING"
  fi
done
if [[ -n "$EXCUSED" ]]; then
  echo "[REPORT] D-35 excused this phase's own artifacts from the clean-tree gate:"
  printf '%s' "$EXCUSED" | sed '/^$/d; s/^/           /'
fi
if [[ -z "$PORCELAIN" ]]; then
  pass "D-15/D-35 git status --porcelain is clean apart from this phase's own artifacts"
else
  fail "D-15/D-35 git status --porcelain is non-empty (dirty tree)"
  printf '%s\n' "$PORCELAIN" | sed -n '1,20p'
fi
AHEAD="$(git rev-list --count origin/main..HEAD 2>/dev/null || echo unknown)"
if [[ "$AHEAD" == "0" ]]; then
  pass "D-15/D-35 origin/main is current (0 commits ahead) — porcelain gate complete"
else
  fail "D-15/D-35 $AHEAD commit(s) not on origin/main — remediation: git push"
  echo "       D-25 depends on GitHub being current: the rollback section must be"
  echo "       readable from a phone while this machine has no desktop."
fi

# --- D-13/D-27: report the backup directory; never mutate it on this path ---
if [[ -w "$HOME" ]]; then
  pass "D-13 \$HOME is writable, so rotating ii-original-dots-backup is possible"
else
  fail "D-13 \$HOME is not writable; rotating ii-original-dots-backup is impossible"
fi
if [[ -d "$BACKUP_DIR" ]]; then
  echo "[REPORT] ii-original-dots-backup exists: $BACKUP_DIR"
  echo "[REPORT] top-level entries:"
  ls -A1 "$BACKUP_DIR" | sed 's/^/           /'
  echo "[REPORT] total size: $(du -sh "$BACKUP_DIR" | cut -f1)"
  BK_CONF="$BACKUP_DIR/.config/hypr/hyprland.conf"
  LIVE_CONF="$XDG/hypr/hyprland.conf"
  if [[ -f "$BK_CONF" ]]; then
    echo "[REPORT] inner .config/hypr/hyprland.conf mtime: $(stat -c '%y' "$BK_CONF")"
  else
    echo "[REPORT] inner .config/hypr/hyprland.conf: absent"
  fi
  BK_MSG="D-13/D-27 ii-original-dots-backup exists, so upstream's auto_backup_configs makes the backup conditional on an \`ask\` answer you may not control."
  if [[ -f "$BK_CONF" && -f "$LIVE_CONF" && "$BK_CONF" -ot "$LIVE_CONF" ]]; then
    BK_MSG="$BK_MSG Its inner hyprland.conf is STALE: backup $(stat -c '%y' "$BK_CONF") vs live $(stat -c '%y' "$LIVE_CONF")."
  fi
  BK_MSG="$BK_MSG Remediation: ./scripts/phase14-preflight.sh --rotate-backup (runbook section 5; mandatory before go)."
  finding "$BK_MSG"
else
  pass "D-13/D-27 ii-original-dots-backup absent — upstream backs up on either \`ask\` branch"
fi

# --- D-26: prove the rollback inputs exist; never rehearse the restore ---
if printf '' | "$WRAP" uninstall --dry-run >"$UNINST_OUT" 2>&1; then
  pass "D-26 rollback tier 2 input: uninstall --dry-run exits 0"
else
  fail "D-26 rollback tier 2 input: uninstall --dry-run exited non-zero"
  sed -n '1,40p' "$UNINST_OUT" || true
fi
if printf '' | "$WRAP" protect --dry-run >"$PROTECT_OUT" 2>&1; then
  pass "D-26 rollback tier 3 input: protect --dry-run exits 0"
else
  fail "D-26 rollback tier 3 input: protect --dry-run exited non-zero"
  sed -n '1,40p' "$PROTECT_OUT" || true
fi
if [[ -s "$REPO_HYPRCONF" ]]; then
  pass "D-26 rollback tier 1 input: repo pre-adopt archive present and non-empty: $REPO_HYPRCONF"
else
  fail "D-26 rollback tier 1 input: repo pre-adopt archive missing or empty: $REPO_HYPRCONF"
fi

# --- The gate cannot pass without the document that defines it ---
if [[ -s "$RUNBOOK" ]]; then
  pass "runbook present and non-empty: $RUNBOOK"
else
  fail "runbook missing or empty: $RUNBOOK"
fi

# --- D-05: gate-fed dry-run (the only agent-safe mutating-form wrapper invocation) ---
# The `printf 'yes\n' |` pipe is mandatory: backup_gate reads stdin and exits 1 on
# any non-`yes` token before argv is ever assembled.
if printf 'yes\n' | "$WRAP" install --full --dry-run >"$FULL_OUT" 2>&1; then
  if grep -q 'would exec' "$FULL_OUT" && ! grep -q -- '--skip-hyprland' "$FULL_OUT"; then
    pass "D-05 gate-fed install --full --dry-run prints would-exec, no --skip-hyprland"
  else
    fail "D-05 gate-fed install --full --dry-run malformed (missing would-exec or leaked --skip-hyprland)"
    sed -n '1,40p' "$FULL_OUT" || true
  fi
else
  fail "D-05 gate-fed install --full --dry-run exited non-zero"
  sed -n '1,40p' "$FULL_OUT" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="

# Rotation runs only when the flag was given, and only after every check above.
if [[ "$ROTATE" -eq 1 ]]; then
  echo "=== --rotate-backup: the one mutating step in this script ==="
  rotate_backup
fi

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
