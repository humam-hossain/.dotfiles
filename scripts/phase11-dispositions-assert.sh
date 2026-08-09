#!/usr/bin/env bash
# Phase 11 disposition structural/lint asserts (Nyquist Wave 0+).
#
# Modes:
#   (default)  Structural + lint gates on 11-DISPOSITIONS.md only
#   --full     Same + read-only PRESENT/ABSENT host checklist (test -e only)
#   --strict   Also hard-require full HIGH-path sample set (post 11-04)
#
# Usage (from REPO_ROOT):
#   ./scripts/phase11-dispositions-assert.sh
#   ./scripts/phase11-dispositions-assert.sh --full
#   ./scripts/phase11-dispositions-assert.sh --strict
# Exit 0 if all hard asserts pass; non-zero if any FAIL.
#
# Constraints (Phase 11):
#   - Structural/lint only — never rsync/cp/mv/rm into XDG or backup dirs
#   - Never call ./setup or arch/dots-hyprland.sh (no install invocation)
#   - Chrome REQUIRED (inverse of phase10 D-15 ban)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DISP="$REPO_ROOT/.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md"
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

FULL=0
STRICT=0
for arg in "$@"; do
  case "$arg" in
    --full) FULL=1 ;;
    --strict) STRICT=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/phase11-dispositions-assert.sh [--full] [--strict]

  (default)  Structural + lint gates on 11-DISPOSITIONS.md
  --full     Also print read-only PRESENT/ABSENT host checklist
  --strict   Hard-require full HIGH path samples (phase close)
EOF
      exit 0
      ;;
    *)
      echo "[FAIL] unknown arg: $arg" >&2
      exit 1
      ;;
  esac
done

echo "=== Phase 11 disposition asserts ==="
echo "[CONFIG] dispositions=$DISP"

# --- D-01 path exists ---
if [[ -f "$DISP" ]]; then
  pass "D-01 dispositions file exists"
else
  fail "D-01 dispositions file missing: $DISP"
  echo "=== done: FAIL=${FAIL} ==="
  exit 1
fi

# --- Required section intent keys (flexible wording) ---
if grep -qiE 'Pre-flight|repo sync' "$DISP"; then
  pass "section: pre-flight / repo sync"
else
  fail "section: pre-flight / repo sync missing"
fi

if grep -qiE 'flag profile|SAFE_DEFAULTS|full-adopt' "$DISP"; then
  pass "section: flag profile / SAFE_DEFAULTS / full-adopt"
else
  fail "section: flag profile / SAFE_DEFAULTS / full-adopt missing"
fi

if grep -qiE 'Axis A|hyprland|skip-hyprland' "$DISP"; then
  pass "section: Axis A / hyprland / skip-hyprland"
else
  fail "section: Axis A / hyprland / skip-hyprland missing"
fi

if grep -qiE 'Axis B|drop --core|misc' "$DISP"; then
  pass "section: Axis B / drop --core / misc"
else
  fail "section: Axis B / drop --core / misc missing"
fi

if grep -qiE 'sysupdate|packages|Axis C' "$DISP"; then
  pass "section: Axis C / sysupdate / packages"
else
  fail "section: Axis C / sysupdate / packages missing"
fi

if grep -qiE 'chrome|waybar' "$DISP"; then
  pass "section: chrome / waybar"
else
  fail "section: chrome / waybar missing"
fi

if grep -qiE 'hyprlock|hypridle|lock' "$DISP"; then
  pass "section: lock / idle / hyprlock"
else
  fail "section: lock / idle / hyprlock missing"
fi

if grep -qiE 'UNKNOWN|extra surface' "$DISP"; then
  pass "section: UNKNOWN / extra surface"
else
  fail "section: UNKNOWN / extra surface missing"
fi

# --- D-03 table header ---
if grep -qiE 'Path.*Inventory risk.*Disposition.*Rationale.*Flag stage.*Inventory source' "$DISP"; then
  pass "D-03 table header Path|Inventory risk|Disposition|Rationale|Flag stage|Inventory source"
else
  fail "D-03 table header missing"
fi

# --- DISP-02 / D-10 residual SAFE_DEFAULTS ---
if grep -q 'SAFE_DEFAULTS' "$DISP"; then
  pass "SAFE_DEFAULTS mentioned"
else
  fail "SAFE_DEFAULTS missing"
fi

for tok in --core --skip-hyprland --skip-sysupdate; do
  if grep -qF -- "$tok" "$DISP"; then
    pass "residual token $tok present"
  else
    fail "residual token $tok missing"
  fi
done

# Residual/default still-safe language near residual claim
if grep -qiE '(remains|still|unchanged|default).{0,100}(SAFE_DEFAULTS|safe|residual|dual-run)|(SAFE_DEFAULTS|safe|residual|dual-run).{0,100}(remains|still|unchanged|default)' "$DISP"; then
  pass "D-10 residual/default still-safe language"
else
  fail "D-10 residual/default still-safe language missing"
fi

# --- DISP-02 / D-05 first full-adopt drops all three ---
# Require drop/full-profile/full-adopt language near residual flag tokens
if grep -qiE '(drop|full-profile|full-adopt|full adopt).{0,200}(--skip-hyprland|--core|--skip-sysupdate)' "$DISP" \
  || grep -qiE '(--skip-hyprland|--core|--skip-sysupdate).{0,200}(drop|full-profile|full-adopt|full adopt)' "$DISP"; then
  # Also require all three tokens appear (already checked) + explicit "all three" or drop-all wording
  if grep -qiE 'drop(s|ping)? all three|all three residual|drops all three|drop all three' "$DISP" \
    || { grep -qiE 'full-adopt|full adopt|full-profile' "$DISP" \
         && grep -qF -- '--core' "$DISP" \
         && grep -qF -- '--skip-hyprland' "$DISP" \
         && grep -qF -- '--skip-sysupdate' "$DISP" \
         && grep -qiE 'drop' "$DISP"; }; then
    pass "D-05 first full-adopt drops residual flags language"
  else
    fail "D-05 first full-adopt drops all three residuals language missing"
  fi
else
  fail "D-05 full-adopt / drop residual flags language missing"
fi

# --- Enum tokens (merge optional) ---
for d in keep-personal migrate-to-hypr-custom accept-upstream defer; do
  if grep -qF "$d" "$DISP"; then
    pass "enum token $d"
  else
    fail "enum token $d missing"
  fi
done

# --- Sample Axis A keywords (tracer + progressive) ---
if grep -qF 'hyprland.conf' "$DISP"; then
  pass "Axis A keyword hyprland.conf"
else
  fail "Axis A keyword hyprland.conf missing"
fi

if grep -qF 'hyprland/' "$DISP" || grep -qF 'hyprland.lua' "$DISP"; then
  pass "Axis A keyword hyprland/ or hyprland.lua"
else
  fail "Axis A keyword hyprland/ or hyprland.lua missing"
fi

if grep -qF 'migrate-to-hypr-custom' "$DISP"; then
  pass "Axis A migrate-to-hypr-custom present"
else
  fail "Axis A migrate-to-hypr-custom missing"
fi

# --- Chrome REQUIRED (inverse of phase10) ---
CHROME_OK=1
for surface in waybar rofi swaync; do
  if grep -qiE "$surface" "$DISP"; then
    pass "chrome surface $surface named"
  else
    fail "chrome surface $surface missing"
    CHROME_OK=0
  fi
done

if ((CHROME_OK)); then
  if grep -qiE 'accept-remove|explicit.*remove|overrides? DISP-03|accepted otherwise|accepts otherwise' "$DISP"; then
    pass "DISP-03 chrome override / accept-remove language"
  else
    fail "DISP-03 chrome override / accept-remove language missing"
  fi
fi

# --- Progressive HIGH path samples (soft in default; hard with --strict) ---
HIGH_SAMPLES=(
  "hyprland.conf"
  "fish"
  "starship.toml"
  "pacman -Syu"
)
HIGH_MISS=0
for p in "${HIGH_SAMPLES[@]}"; do
  if grep -qF -- "$p" "$DISP"; then
    pass "HIGH sample cite $p"
  else
    if ((STRICT)); then
      fail "HIGH sample cite $p missing (--strict)"
    else
      printf '[SOFT] HIGH sample cite %s not yet present (ok until --strict / 11-04)\n' "$p"
      HIGH_MISS=$((HIGH_MISS + 1))
    fi
  fi
done

# Additional progressive samples often planted as stubs
for p in kitty fontconfig asdeps illogical-impulse hyprlock; do
  if grep -qiE "$p" "$DISP"; then
    pass "progressive keyword $p"
  else
    if ((STRICT)); then
      fail "progressive keyword $p missing (--strict)"
    else
      printf '[SOFT] progressive keyword %s not yet present\n' "$p"
    fi
  fi
done

# --- Self-policy: script body must not mutate XDG ---
# Fail only on real rsync *invocations* (command at line start after optional indent).
# Do not match comments or grep pattern strings that document the ban.
if grep -nE '^[[:space:]]*rsync[[:space:]]' "$0" >/dev/null 2>&1; then
  fail "assert script must not invoke rsync (found executable rsync line)"
  grep -nE '^[[:space:]]*rsync[[:space:]]' "$0" || true
else
  pass "assert script has no live rsync invocation"
fi
# Also ban cp/mv/rm targeting HOME config in executable lines (not comments)
if grep -nE '^[[:space:]]*(cp|mv|rm)[[:space:]].*(HOME|XDG_CONFIG|~\/\.config)' "$0" >/dev/null 2>&1; then
  fail "assert script must not cp/mv/rm against HOME/XDG"
else
  pass "assert script has no live cp/mv/rm against HOME/XDG"
fi

# --- --full: read-only host checklist ---
if ((FULL)); then
  echo "=== Host presence checklist (read-only test -e) ==="
  host_check() {
    local rel="$1"
    local path="$XDG/$rel"
    if [[ "$rel" == /* ]]; then
      path="$rel"
    fi
    if test -e "$path"; then
      printf 'PRESENT %s\n' "$path"
    else
      printf 'ABSENT  %s\n' "$path"
    fi
  }
  host_check "hypr/hyprland.conf"
  host_check "hypr/hyprland"
  host_check "hypr/hyprlock.conf"
  host_check "hypr/hypridle.conf"
  host_check "waybar"
  host_check "rofi"
  host_check "swaync"
  host_check "fish"
  host_check "kitty"
  host_check "starship.toml"
fi

echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
printf 'phase11 dispositions asserts OK\n'
exit 0
