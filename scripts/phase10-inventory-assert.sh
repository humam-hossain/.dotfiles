#!/usr/bin/env bash
# Phase 10 inventory structural/lint asserts (Nyquist Wave 0).
#
# Modes:
#   (default)  Structural + lint gates on 10-INVENTORY.md only
#   --full     Same + read-only PRESENT/ABSENT host checklist (test -e only)
#
# Usage (from REPO_ROOT):
#   ./scripts/phase10-inventory-assert.sh
#   ./scripts/phase10-inventory-assert.sh --full
# Exit 0 if all hard asserts pass; non-zero if any FAIL.
#
# Constraints (Phase 10):
#   - Never rsync/cp/mv/rm into XDG or backup dirs
#   - Never call ./setup or arch/dots-hyprland.sh without --dry-run
#     (this script does not invoke either)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

INVENTORY="$REPO_ROOT/.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md"
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

FULL=0
for arg in "$@"; do
  case "$arg" in
    --full) FULL=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/phase10-inventory-assert.sh [--full]

  (default)  Structural + lint gates on 10-INVENTORY.md
  --full     Also print read-only PRESENT/ABSENT host checklist
EOF
      exit 0
      ;;
    *)
      echo "[FAIL] unknown arg: $arg" >&2
      exit 1
      ;;
  esac
done

echo "=== Phase 10 inventory asserts ==="
echo "[CONFIG] inventory=$INVENTORY"

# --- D-01 path exists ---
if [[ -f "$INVENTORY" ]]; then
  pass "D-01 inventory file exists"
else
  fail "D-01 inventory file missing: $INVENTORY"
  echo "=== done: FAIL=${FAIL} ==="
  exit 1
fi

# --- Required section headings (intent keys; flexible wording) ---
# SAFE_DEFAULTS residual
if grep -qiE 'SAFE_DEFAULTS' "$INVENTORY" \
  && grep -qiE 'residual|INV-04' "$INVENTORY"; then
  pass "section: SAFE_DEFAULTS residual (INV-04)"
else
  fail "section: SAFE_DEFAULTS residual (INV-04) missing"
fi

# Axis A: drop --skip-hyprland / hypr
if grep -qiE 'skip-hyprland|hypr files|Axis:.*hypr' "$INVENTORY"; then
  pass "section: hypr / drop --skip-hyprland axis"
else
  fail "section: hypr / drop --skip-hyprland axis missing"
fi

# Axis B: drop --core / misc
if grep -qiE 'drop --core|misc.*fish|Axis:.*core|Axis:.*misc' "$INVENTORY"; then
  pass "section: misc / drop --core axis"
else
  fail "section: misc / drop --core axis missing"
fi

# Axis C: sysupdate / packages
if grep -qiE 'sysupdate|package effects|Axis:.*package' "$INVENTORY"; then
  pass "section: sysupdate / packages axis"
else
  fail "section: sysupdate / packages axis missing"
fi

# Host snapshot
if grep -qiE 'Host snapshot|live ~/.config|live \`~/.config\`' "$INVENTORY"; then
  pass "section: Host snapshot"
else
  fail "section: Host snapshot missing"
fi

# UNKNOWN
if grep -qiE 'UNKNOWN|research notes' "$INVENTORY"; then
  pass "section: UNKNOWN / research notes"
else
  fail "section: UNKNOWN / research notes missing"
fi

# Sources
if grep -qiE '^## Sources|^## .*Sources' "$INVENTORY"; then
  pass "section: Sources"
else
  fail "section: Sources missing"
fi

# --- D-10 table columns ---
if grep -qiE 'Path.*Effect.*Risk.*Source.*Host present' "$INVENTORY"; then
  pass "D-10 table header Path|Effect|Risk|Source|Host present?"
else
  fail "D-10 table header Path|Effect|Risk|Source|Host present? missing"
fi

# --- INV-04 residual hard gates ---
if grep -q 'SAFE_DEFAULTS' "$INVENTORY"; then
  pass "INV-04 mentions SAFE_DEFAULTS"
else
  fail "INV-04 missing SAFE_DEFAULTS"
fi

for tok in --core --skip-hyprland --skip-sysupdate; do
  if grep -qF -- "$tok" "$INVENTORY"; then
    pass "INV-04 token $tok present"
  else
    fail "INV-04 token $tok missing"
  fi
done

# Safe/default dual-run remains available (match remains|still near safe/default/SAFE_DEFAULTS)
if grep -qiE '(remains|still).{0,80}(safe|default|SAFE_DEFAULTS|dual-run)|(safe|default|SAFE_DEFAULTS|dual-run).{0,80}(remains|still)' "$INVENTORY"; then
  pass "INV-04 safe/default dual-run remains/still available"
else
  fail "INV-04 missing claim that safe/default dual-run remains/still available"
fi

# --- INV-02 hypr keywords (planted as stubs in Wave 0; expanded later) ---
for kw in hyprland.conf hyprland.lua hyprpaper; do
  if grep -qF -- "$kw" "$INVENTORY"; then
    pass "INV-02 keyword $kw"
  else
    fail "INV-02 keyword $kw missing"
  fi
done

if grep -qE 'auto_backup|\.new' "$INVENTORY"; then
  pass "INV-02 auto_backup or .new"
else
  fail "INV-02 missing auto_backup or .new"
fi

if grep -qiE 'custom|ignore_existing' "$INVENTORY"; then
  pass "INV-02 custom / ignore_existing"
else
  fail "INV-02 missing custom / ignore_existing"
fi

# --- INV-03 misc keywords ---
for kw in fish kitty starship fontconfig; do
  if grep -qiE "$kw" "$INVENTORY"; then
    pass "INV-03 keyword $kw"
  else
    fail "INV-03 keyword $kw missing"
  fi
done

MISC_EXTRA=0
for kw in fuzzel matugen wlogout mpv dolphinrc; do
  if grep -qiE "$kw" "$INVENTORY"; then
    MISC_EXTRA=$((MISC_EXTRA + 1))
  fi
done
if ((MISC_EXTRA >= 2)); then
  pass "INV-03 at least two of fuzzel|matugen|wlogout|mpv|dolphinrc ($MISC_EXTRA found)"
else
  fail "INV-03 need ≥2 of fuzzel|matugen|wlogout|mpv|dolphinrc (found $MISC_EXTRA)"
fi

# --- INV-01 packages/sysupdate ---
if grep -qE 'Syu|pacman -Syu' "$INVENTORY"; then
  pass "INV-01 Syu / pacman -Syu"
else
  fail "INV-01 missing Syu / pacman -Syu"
fi

if grep -qF 'illogical-impulse' "$INVENTORY"; then
  pass "INV-01 illogical-impulse"
else
  fail "INV-01 missing illogical-impulse"
fi

if grep -qE 'asdeps|skip-sysupdate' "$INVENTORY"; then
  pass "INV-01 asdeps or skip-sysupdate"
else
  fail "INV-01 missing asdeps or skip-sysupdate"
fi

# --- D-12 disposition lint (fail on recommend keep|migrate|accept or disposition:) ---
if grep -niE 'recommend (keep|migrate|accept)|disposition:' "$INVENTORY" >/dev/null; then
  fail "D-12 disposition language found (recommend keep|migrate|accept or disposition:)"
  grep -niE 'recommend (keep|migrate|accept)|disposition:' "$INVENTORY" || true
else
  pass "D-12 no disposition recommendation language"
fi

# --- D-15 chrome ban (waybar|rofi|swaync) ---
if grep -niE 'waybar|rofi|swaync' "$INVENTORY" >/dev/null; then
  fail "D-15 dual-run chrome (waybar|rofi|swaync) must be omitted"
  grep -niE 'waybar|rofi|swaync' "$INVENTORY" || true
else
  pass "D-15 no waybar/rofi/swaync"
fi

# --- Script self-policy notes (documentation only; this script never mutates) ---
# Host scan uses test -e / printf only. No rsync/cp/mv/rm into XDG.
# No ./setup or arch/dots-hyprland.sh invocation in this script.

# --- --full: read-only host PRESENT/ABSENT checklist ---
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

  # INV-02 hypr set
  host_check "hypr/hyprland.conf"
  host_check "hypr/hyprland"
  host_check "hypr/hyprland.lua"
  host_check "hypr/hyprlock.conf"
  host_check "hypr/hypridle.conf"
  host_check "hypr/hyprpaper.conf"
  host_check "hypr/custom"
  host_check "hypr/hyprlock"
  host_check "illogical-impulse/installed_true"

  # Full misc basenames (RESEARCH catalog) + fish/fontconfig
  for p in \
    fish fontconfig \
    chrome-flags.conf code-flags.conf darklyrc dolphinrc foot fuzzel \
    kdeglobals kde-material-you-colors kitty konsolerc Kvantum matugen \
    mpv starship.toml thorium-flags.conf wlogout xdg-desktop-portal zshrc.d \
    quickshell; do
    host_check "$p"
  done
  # konsole share (outside pure XDG config)
  if test -e "${XDG_DATA_HOME:-$HOME/.local/share}/konsole"; then
    printf 'PRESENT %s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/konsole"
  else
    printf 'ABSENT  %s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/konsole"
  fi
fi

echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
printf 'phase10 inventory asserts OK\n'
exit 0
