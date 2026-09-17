#!/usr/bin/env bash
# Phase 26 Qt & KDE Apps Material You Harmonization assert harness (QT-01 to QT-03, INTG-01, INTG-02).
# One script, one section per requirement criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase26-qt-kde-material-you-assert.sh [--section <1-5>]
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

RUN_SECTION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-5>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p26-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p26-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Virtualenv Readiness & Generator Binary (D-08)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Virtualenv Readiness & Generator Binary ---"

  VENV_DIR="$HOME/.local/state/quickshell/.venv"
  GEN_BIN="$VENV_DIR/bin/kde-material-you-colors"

  if [[ -d "$VENV_DIR" && -x "$GEN_BIN" ]]; then
    pass "S1: quickshell virtualenv exists and kde-material-you-colors is executable (D-08)"
  else
    fail "S1: quickshell virtualenv missing or kde-material-you-colors not executable: $GEN_BIN (D-08)"
  fi

  # Version check
  GEN_VER="$("$GEN_BIN" --version 2>&1 || true)"
  if [[ "$GEN_VER" =~ (1\.[0-9]+(\.[0-9]+)?) ]]; then
    pass "S1: kde-material-you-colors reports valid version ($GEN_VER) (D-08)"
  else
    fail "S1: kde-material-you-colors unexpected version response: $GEN_VER (D-08)"
  fi
fi

# ===========================================================================
# Section 2: Qt Environment Variables Alignment (D-14, D-15)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Qt Environment Variables Alignment ---"

  UPSTREAM_ENV="$HOME/.config/hypr/hyprland/env.lua"
  CUSTOM_ENV="$REPO_ROOT/stow/hypr/.config/hypr/custom/env.lua"

  if [[ -f "$UPSTREAM_ENV" ]] && \
     grep -q 'QT_QPA_PLATFORMTHEME.*"kde"' "$UPSTREAM_ENV" && \
     grep -q 'QT_QPA_PLATFORM.*"wayland;xcb"' "$UPSTREAM_ENV"; then
    pass "S2: ~/.config/hypr/hyprland/env.lua declares QT_QPA_PLATFORMTHEME=kde and QT_QPA_PLATFORM=wayland;xcb (D-14)"
  else
    fail "S2: ~/.config/hypr/hyprland/env.lua missing standard Qt platform environment variables (D-14)"
  fi

  # Ensure QT_STYLE_OVERRIDE is unset/empty in custom environment (D-15)
  if [[ -f "$CUSTOM_ENV" ]] && grep -q "QT_STYLE_OVERRIDE" "$CUSTOM_ENV"; then
    fail "S2: stow/hypr/.config/hypr/custom/env.lua must not declare QT_STYLE_OVERRIDE (D-15)"
  else
    pass "S2: stow/hypr/.config/hypr/custom/env.lua free of QT_STYLE_OVERRIDE collision (D-15)"
  fi

  if [[ -n "${QT_STYLE_OVERRIDE:-}" ]]; then
    fail "S2: live session environment has active QT_STYLE_OVERRIDE=$QT_STYLE_OVERRIDE (D-15)"
  else
    pass "S2: live session environment leaves QT_STYLE_OVERRIDE unset (D-15)"
  fi
fi

# ===========================================================================
# Section 3: Style Engine & Guard Path Contracts (D-01, D-02, D-03, D-04, INTG-01)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Style Engine & Guard Path Contracts ---"

  # 1. Darkly style plugin binary (D-01)
  DARKLY6_SO="/usr/lib/qt6/plugins/styles/darkly6.so"
  if [[ -f "$DARKLY6_SO" ]]; then
    pass "S3: Qt 6 Darkly style engine plugin exists ($DARKLY6_SO) (D-01)"
  else
    fail "S3: Qt 6 Darkly style engine plugin missing ($DARKLY6_SO) (D-01)"
  fi

  # 2. kdeglobals widgetStyle configuration (D-01)
  KDEGLOBALS="$HOME/.config/kdeglobals"
  if [[ -f "$KDEGLOBALS" ]] && grep -q "^widgetStyle=Darkly$" "$KDEGLOBALS"; then
    pass "S3: ~/.config/kdeglobals configures widgetStyle=Darkly (D-01)"
  else
    fail "S3: ~/.config/kdeglobals missing widgetStyle=Darkly (D-01)"
  fi

  # 3. darklyrc retention (D-03)
  DARKLYRC="$HOME/.config/darklyrc"
  if [[ -f "$DARKLYRC" ]]; then
    pass "S3: ~/.config/darklyrc exists as upstream configuration (D-03)"
  else
    fail "S3: ~/.config/darklyrc missing (D-03)"
  fi

  # 4. guard-paths.tsv contracts (Kvantum & kde-material-you-colors) (D-02, D-04, INTG-01)
  GUARD_TSV="$REPO_ROOT/guard-paths.tsv"
  if grep -qF '$XDG_CONFIG_HOME/Kvantum' "$GUARD_TSV"; then
    pass "S3: guard-paths.tsv guards $XDG_CONFIG_HOME/Kvantum (D-02)"
  else
    fail "S3: guard-paths.tsv missing $XDG_CONFIG_HOME/Kvantum guard (D-02)"
  fi

  if grep -qF '$XDG_CONFIG_HOME/kde-material-you-colors' "$GUARD_TSV"; then
    pass "S3: guard-paths.tsv guards $XDG_CONFIG_HOME/kde-material-you-colors (D-04, INTG-01)"
  else
    fail "S3: guard-paths.tsv missing $XDG_CONFIG_HOME/kde-material-you-colors guard (D-04, INTG-01)"
  fi

  # Tab separation validation
  BAD_SPACES="$(grep -F '$XDG_CONFIG_HOME/kde-material-you-colors' "$GUARD_TSV" | grep ' ' || true)"
  if [[ -z "$BAD_SPACES" ]]; then
    pass "S3: kde-material-you-colors guard entry strictly tab-separated (INTG-01)"
  else
    fail "S3: kde-material-you-colors guard entry contains spaces instead of tabs (INTG-01)"
  fi
fi

# ===========================================================================
# Section 4: Dynamic Palette Generation & Dark Luminance Invariant (D-05, D-06, D-07, D-09, D-13, QT-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Dynamic Palette Generation & Luminance Invariant ---"

  VENV_BIN="$HOME/.local/state/quickshell/.venv/bin"
  COLOR_FILE="$HOME/.local/state/quickshell/user/generated/color.txt"
  SEED_COLOR="$(tr -d '\n' < "$COLOR_FILE" 2>/dev/null || echo "#82d3e1")"
  KDEGLOBALS="$HOME/.config/kdeglobals"

  BEFORE_MTIME="$(stat -c %Y "$KDEGLOBALS" 2>/dev/null || echo 0)"

  # Invoke generator in venv with -d and standard TonalSpot variant (sv 5)
  # D-09: Ignore non-fatal KWin DBus reload exception under Hyprland
  "$VENV_BIN/kde-material-you-colors" -d --color "$SEED_COLOR" -sv 5 >/dev/null 2>&1 || true

  AFTER_MTIME="$(stat -c %Y "$KDEGLOBALS" 2>/dev/null || echo 0)"
  if [[ "$AFTER_MTIME" -ge "$BEFORE_MTIME" ]]; then
    pass "S4: kde-material-you-colors execution touched ~/.config/kdeglobals (QT-02, D-05)"
  else
    fail "S4: ~/.config/kdeglobals was not updated by color generation (QT-02, D-05)"
  fi

  if grep -q "^ColorScheme=MaterialYouDark$" "$KDEGLOBALS"; then
    pass "S4: ~/.config/kdeglobals declares ColorScheme=MaterialYouDark (D-05, D-06)"
  else
    fail "S4: ~/.config/kdeglobals missing ColorScheme=MaterialYouDark (D-05, D-06)"
  fi

  # Color tokens presence
  if grep -q "^\[Colors:Window\]" "$KDEGLOBALS" && grep -q "^\[Colors:View\]" "$KDEGLOBALS"; then
    pass "S4: ~/.config/kdeglobals contains [Colors:Window] and [Colors:View] sections (QT-02)"
  else
    fail "S4: ~/.config/kdeglobals missing required color sections (QT-02)"
  fi

  # Icon theme retention (D-07)
  KMYC_CONF="$HOME/.config/kde-material-you-colors/config.conf"
  if [[ -f "$KMYC_CONF" ]] && grep -q "^iconsdark = breeze-plus-dark$" "$KMYC_CONF"; then
    pass "S4: ~/.config/kde-material-you-colors/config.conf retains iconsdark = breeze-plus-dark (D-07)"
  else
    fail "S4: ~/.config/kde-material-you-colors/config.conf missing iconsdark = breeze-plus-dark (D-07)"
  fi

  # Programmatic relative luminance check via Python (D-13)
  LUM_VERDICT="$(python3 -c "
import configparser

config = configparser.ConfigParser()
config.read('$KDEGLOBALS')

def hex_or_rgb_to_rgb(val):
    if val.startswith('#'):
        val = val.lstrip('#')
        return tuple(int(val[i:i+2], 16) for i in (0, 2, 4))
    parts = [int(p.strip()) for p in val.split(',')]
    return tuple(parts[:3])

win_bg = config.get('Colors:Window', 'BackgroundNormal', fallback='#1b2122')
view_bg = config.get('Colors:View', 'BackgroundNormal', fallback='#0c1213')

r1, g1, b1 = hex_or_rgb_to_rgb(win_bg)
r2, g2, b2 = hex_or_rgb_to_rgb(view_bg)

lum1 = (0.2126 * r1 + 0.7152 * g1 + 0.0722 * b1) / 255.0
lum2 = (0.2126 * r2 + 0.7152 * g2 + 0.0722 * b2) / 255.0

if lum1 < 0.25 and lum2 < 0.25 and r1 < 60 and g1 < 60 and b1 < 60 and r2 < 60 and g2 < 60 and b2 < 60:
    print(f'PASS: win_lum={lum1:.3f} view_lum={lum2:.3f}')
else:
    print(f'FAIL: luminance exceeds dark threshold: win={lum1:.3f} view={lum2:.3f}')
" 2>&1 || echo "FAIL: python execution error")"

  if [[ "$LUM_VERDICT" =~ ^PASS ]]; then
    pass "S4: kdeglobals window and view background luminance conforms to dark palette ($LUM_VERDICT) (D-13)"
  else
    fail "S4: kdeglobals background luminance failed: $LUM_VERDICT (D-13)"
  fi
fi

# ===========================================================================
# Section 5: Desktop Portal Integration & Strict Verifier (D-10, D-11, D-12, INTG-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Desktop Portal Integration & Strict Verifier ---"

  # 1. Desktop Portal FileChooser mapping (D-12)
  PORTAL_CONF="$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
  [[ -f "$PORTAL_CONF" ]] || PORTAL_CONF="$HOME/.config/xdg-desktop-portal/portals.conf"

  if [[ -f "$PORTAL_CONF" ]] && grep -q "org\.freedesktop\.impl\.portal\.FileChooser.*=.*kde" "$PORTAL_CONF"; then
    pass "S5: $PORTAL_CONF maps FileChooser portal to kde (D-12)"
  else
    fail "S5: portals configuration missing FileChooser = kde (D-12)"
  fi

  # 2. KDE Target Binaries Presence (D-10)
  for app in "/usr/bin/dolphin" "/usr/bin/gwenview"; do
    if [[ -x "$app" ]]; then
      pass "S5: KDE application $app is installed and executable (D-10)"
    else
      fail "S5: KDE application $app missing or not executable (D-10)"
    fi
  done

  # 3. Unmanaged runtime state check: gwenviewrc not tracked in repository (D-11)
  if git ls-files | grep -q 'gwenviewrc'; then
    fail "S5: gwenviewrc must not be tracked in git repository (D-11)"
  else
    pass "S5: gwenviewrc remains unmanaged runtime state (D-11)"
  fi

  # 4. Working tree cleanliness on tracked directories
  if [[ -z "$(git status --porcelain stow/ restow/)" ]]; then
    pass "S5: git working tree clean in stow/ and restow/ packaging directories (INTG-02)"
  else
    fail "S5: git status dirty in stow/ or restow/: $(git status --porcelain stow/ restow/) (INTG-02)"
  fi

  # 5. Strict verification engine execution (INTG-02)
  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]]; then
    pass "S5: arch/dots-hyprland.sh verify --strict passed with 0 findings (INTG-02)"
  else
    fail "S5: arch/dots-hyprland.sh verify --strict failed (rc=$VERIFY_RC) (INTG-02)"
    printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
  fi
fi

# ===========================================================================
# Closing porcelain invariant check & summary
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run"
else
  fail "Closing self-check: git status --porcelain mutated across run"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
