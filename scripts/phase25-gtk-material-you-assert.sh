#!/usr/bin/env bash
# Phase 25 GTK Material You theming and Catppuccin de-linking assert harness (GTK-01 to GTK-04).
# One script, one section per requirement criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase25-gtk-material-you-assert.sh [--section <1-5>]
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

PORCELAIN_BEFORE="$(mktemp /tmp/p25-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p25-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: GTK-02 Catppuccin De-linking in ~/.config/gtk-4.0/
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: GTK-02 Catppuccin De-linking & Inode Conversion ---"

  # 1. Assert legacy Catppuccin symlinks absent
  if [[ ! -e "$HOME/.config/gtk-4.0/assets" && ! -L "$HOME/.config/gtk-4.0/assets" ]]; then
    pass "GTK-02 (S1): ~/.config/gtk-4.0/assets symlink is absent"
  else
    fail "GTK-02 (S1): legacy ~/.config/gtk-4.0/assets still present"
  fi

  if [[ ! -e "$HOME/.config/gtk-4.0/gtk-dark.css" && ! -L "$HOME/.config/gtk-4.0/gtk-dark.css" ]]; then
    pass "GTK-02 (S1): ~/.config/gtk-4.0/gtk-dark.css symlink is absent (D-08)"
  else
    fail "GTK-02 (S1): legacy ~/.config/gtk-4.0/gtk-dark.css still present"
  fi

  # 2. Assert ~/.config/gtk-4.0/gtk.css is NOT a symlink into /usr/share/themes/catppuccin-*
  if [[ -L "$HOME/.config/gtk-4.0/gtk.css" ]]; then
    TARGET="$(readlink -f "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null || true)"
    if [[ "$TARGET" =~ catppuccin ]]; then
      fail "GTK-02 (S1): ~/.config/gtk-4.0/gtk.css is still symlinked to Catppuccin ($TARGET)"
    else
      fail "GTK-02 (S1): ~/.config/gtk-4.0/gtk.css must be a regular file, not a symlink"
    fi
  else
    pass "GTK-02 (S1): ~/.config/gtk-4.0/gtk.css is not a symlink to legacy system packages"
  fi

  # 3. Assert parent directory unfolding invariant (D-09)
  if [[ -d "$HOME/.config/gtk-4.0" && ! -L "$HOME/.config/gtk-4.0" ]]; then
    pass "GTK-02 (S1): ~/.config/gtk-4.0 is an unfolded physical directory"
  else
    fail "GTK-02 (S1): ~/.config/gtk-4.0 is folded or not a directory"
  fi
fi

# ===========================================================================
# Section 2: GTK-03 Repository Settings Alignment in stow/gtk/
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: GTK-03 Repository Settings Alignment in stow/gtk/ ---"

  FILES=(
    "stow/gtk/.config/gtk-3.0/settings.ini:$HOME/.config/gtk-3.0/settings.ini"
    "stow/gtk/.config/gtk-4.0/settings.ini:$HOME/.config/gtk-4.0/settings.ini"
  )

  for pair in "${FILES[@]}"; do
    REPO_PATH="$REPO_ROOT/${pair%%:*}"
    LIVE_PATH="${pair##*:}"
    REL_PATH="${pair%%:*}"

    # Zero Catppuccin strings
    if grep -iq "catppuccin" "$REPO_PATH"; then
      fail "GTK-03 (S2): $REL_PATH contains residual Catppuccin theme references"
    else
      pass "GTK-03 (S2): $REL_PATH is clean of Catppuccin strings"
    fi

    # Upstream keys verification
    if grep -q "^gtk-theme-name=adw-gtk3-dark$" "$REPO_PATH"; then
      pass "GTK-03 (S2): $REL_PATH declares gtk-theme-name=adw-gtk3-dark"
    else
      fail "GTK-03 (S2): $REL_PATH missing gtk-theme-name=adw-gtk3-dark"
    fi

    if grep -q "^gtk-application-prefer-dark-theme=1$" "$REPO_PATH"; then
      pass "GTK-03 (S2): $REL_PATH declares gtk-application-prefer-dark-theme=1"
    else
      fail "GTK-03 (S2): $REL_PATH missing gtk-application-prefer-dark-theme=1"
    fi

    if grep -q "^gtk-font-name=Google Sans Flex Medium 11 @opsz=11,wght=500$" "$REPO_PATH"; then
      pass "GTK-03 (S2): $REL_PATH declares Google Sans Flex font"
    else
      fail "GTK-03 (S2): $REL_PATH missing Google Sans Flex font"
    fi

    if grep -q "^gtk-cursor-theme-name=Bibata-Modern-Classic$" "$REPO_PATH" && \
       grep -q "^gtk-cursor-theme-size=24$" "$REPO_PATH"; then
      pass "GTK-03 (S2): $REL_PATH declares Bibata-Modern-Classic cursor size 24"
    else
      fail "GTK-03 (S2): $REL_PATH missing Bibata-Modern-Classic cursor"
    fi

    if grep -q "^gtk-icon-theme-name=Tela-circle-dracula-dark$" "$REPO_PATH"; then
      pass "GTK-03 (S2): $REL_PATH declares Tela-circle-dracula-dark icon theme"
    else
      fail "GTK-03 (S2): $REL_PATH missing Tela-circle-dracula-dark icon theme"
    fi

    # Inode link identity (-ef dereferences and tests matching dev+inode)
    if [[ -e "$LIVE_PATH" && -e "$REPO_PATH" && "$LIVE_PATH" -ef "$REPO_PATH" ]]; then
      pass "GTK-03 (S2): $LIVE_PATH inode matches $REL_PATH"
    else
      fail "GTK-03 (S2): $LIVE_PATH does not resolve to $REL_PATH"
    fi
  done

  # Assert GTK3 rendering/sound flags preserved
  GTK3_REPO="$REPO_ROOT/stow/gtk/.config/gtk-3.0/settings.ini"
  for flag in "gtk-xft-antialias=1" "gtk-xft-hinting=1" "gtk-xft-hintstyle=hintslight" "gtk-xft-rgba=rgb" "gtk-enable-event-sounds=1"; do
    if grep -q "^$flag$" "$GTK3_REPO"; then
      pass "GTK-03 (S2): stow/gtk/.config/gtk-3.0/settings.ini preserves $flag"
    else
      fail "GTK-03 (S2): stow/gtk/.config/gtk-3.0/settings.ini missing $flag"
    fi
  done

  # Assert bookmarks preserved (Phase 22 D-11)
  if [[ -f "$REPO_ROOT/stow/gtk/.config/gtk-3.0/bookmarks" ]] && \
     grep -q '^file:///home/pera/' "$REPO_ROOT/stow/gtk/.config/gtk-3.0/bookmarks"; then
    pass "GTK-03 (S2): stow/gtk/.config/gtk-3.0/bookmarks preserved per Phase 22 D-11"
  else
    fail "GTK-03 (S2): stow/gtk/.config/gtk-3.0/bookmarks missing or invalid"
  fi
fi

# ===========================================================================
# Section 3: GTK-04 GNOME Desktop Interface GSettings
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: GTK-04 GNOME Desktop Interface GSettings Alignment ---"

  declare -A EXPECTED_GSETTINGS=(
    ["gtk-theme"]="'adw-gtk3-dark'"
    ["color-scheme"]="'prefer-dark'"
    ["font-name"]="'Google Sans Flex Medium 11 @opsz=11,wght=500'"
    ["cursor-theme"]="'Bibata-Modern-Classic'"
    ["cursor-size"]="24"
    ["icon-theme"]="'Tela-circle-dracula-dark'"
  )

  for key in "${!EXPECTED_GSETTINGS[@]}"; do
    VAL="$(gsettings get org.gnome.desktop.interface "$key" 2>/dev/null || echo "FAILED")"
    EXP="${EXPECTED_GSETTINGS[$key]}"
    if [[ "$VAL" == "$EXP" ]]; then
      pass "GTK-04 (S3): org.gnome.desktop.interface $key matches $EXP"
    else
      fail "GTK-04 (S3): org.gnome.desktop.interface $key is $VAL (expected $EXP)"
    fi
  done
fi

# ===========================================================================
# Section 4: GTK-01 Dynamic Matugen CSS Generation
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: GTK-01 Dynamic Matugen CSS Generation ---"

  CSS3="$HOME/.config/gtk-3.0/gtk.css"
  CSS4="$HOME/.config/gtk-4.0/gtk.css"

  # 1. Assert regular file existence and non-empty size
  if [[ -f "$CSS3" && ! -L "$CSS3" && -s "$CSS3" ]]; then
    pass "GTK-01 (S4): ~/.config/gtk-3.0/gtk.css is a non-empty regular file"
  else
    fail "GTK-01 (S4): ~/.config/gtk-3.0/gtk.css is missing, empty, or a symlink"
  fi

  if [[ -f "$CSS4" && ! -L "$CSS4" && -s "$CSS4" ]]; then
    pass "GTK-01 (S4): ~/.config/gtk-4.0/gtk.css is a non-empty regular file"
  else
    fail "GTK-01 (S4): ~/.config/gtk-4.0/gtk.css is missing, empty, or a symlink"
  fi

  # 2. Assert Material You tokens present in GTK 3 CSS
  if [[ -f "$CSS3" ]] && grep -q "@define-color accent_color" "$CSS3" && grep -q "@define-color window_bg_color" "$CSS3"; then
    pass "GTK-01 (S4): ~/.config/gtk-3.0/gtk.css contains valid Material You color definitions"
  else
    fail "GTK-01 (S4): ~/.config/gtk-3.0/gtk.css missing required @define-color tokens"
  fi

  # 3. Assert Material You tokens and media queries present in GTK 4 CSS
  if [[ -f "$CSS4" ]] && grep -q "@media (prefers-color-scheme: dark)" "$CSS4" && grep -q "@define-color accent_color" "$CSS4"; then
    pass "GTK-01 (S4): ~/.config/gtk-4.0/gtk.css contains prefers-color-scheme media queries and tokens"
  else
    fail "GTK-01 (S4): ~/.config/gtk-4.0/gtk.css missing required media queries or tokens"
  fi

  # 4. Matugen non-interactive dry-run test
  WP_PATH="$(cat "$HOME/.local/state/quickshell/user/generated/wallpaper/path.txt" 2>/dev/null || echo "$HOME/Pictures/55192173787_b8322b1190_o.jpg")"
  if [[ -f "$WP_PATH" ]]; then
    if matugen --source-color-index 0 --mode dark image "$WP_PATH" --dry-run >/dev/null 2>&1; then
      pass "GTK-01 (S4): matugen non-interactive execution succeeds with active wallpaper ($WP_PATH)"
    else
      fail "GTK-01 (S4): matugen execution failed on active wallpaper ($WP_PATH)"
    fi
  else
    info "GTK-01 (S4): active wallpaper path not accessible; dry-run skipped"
  fi

  # 5. Assert GTK 4 CSS parser compliance (no Gtk-WARNING on load)
  if grep -q ':insensitive' "$CSS4"; then
    fail "GTK-01 (S4): ~/.config/gtk-4.0/gtk.css contains invalid :insensitive pseudo-class"
  else
    pass "GTK-01 (S4): ~/.config/gtk-4.0/gtk.css free of invalid :insensitive pseudo-class"
  fi

  if grep -q '\.boxed-list row:disabled' "$CSS4"; then
    pass "GTK-01 (S4): ~/.config/gtk-4.0/gtk.css specifies valid GTK 4 .boxed-list row:disabled selector"
  else
    fail "GTK-01 (S4): ~/.config/gtk-4.0/gtk.css missing .boxed-list row:disabled selector"
  fi

  GTK4_WARN="$(python3 -c "import gi; gi.require_version('Gtk', '4.0'); from gi.repository import Gtk; Gtk.init(); p = Gtk.CssProvider(); p.load_from_path('$CSS4')" 2>&1 || true)"
  if [[ -z "$GTK4_WARN" ]]; then
    pass "GTK-01 (S4): GTK 4 CssProvider loaded ~/.config/gtk-4.0/gtk.css with zero parser warnings"
  else
    fail "GTK-01 (S4): GTK 4 CssProvider emitted parser warnings: $GTK4_WARN"
  fi
fi

# ===========================================================================
# Section 5: INTG-01 & INTG-02 Verification Engine & Zero Churn
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: INTG-01 & INTG-02 Verification Engine & Zero Churn ---"

  # 1. Assert guard-paths.tsv integrity
  GUARD_TSV="$REPO_ROOT/guard-paths.tsv"
  if grep -qF '$XDG_CONFIG_HOME/gtk-3.0/gtk.css' "$GUARD_TSV" && \
     grep -qF '$XDG_CONFIG_HOME/gtk-4.0/gtk.css' "$GUARD_TSV"; then
    pass "INTG-01 (S5): guard-paths.tsv guards both gtk-3.0/gtk.css and gtk-4.0/gtk.css"
  else
    fail "INTG-01 (S5): guard-paths.tsv missing gtk-3.0 or gtk-4.0 CSS guards"
  fi

  # 2. Assert root .gitignore integrity
  if grep -q '^gtk\.css$' "$REPO_ROOT/.gitignore" && grep -q '^gtk-dark\.css$' "$REPO_ROOT/.gitignore"; then
    pass "INTG-01 (S5): root .gitignore excludes gtk.css and gtk-dark.css"
  else
    fail "INTG-01 (S5): root .gitignore missing gtk.css or gtk-dark.css"
  fi

  # 3. Assert git status clean on repo working tree for generated theme files
  if [[ -z "$(git status --porcelain stow/gtk)" ]]; then
    pass "INTG-02 (S5): git status clean for stow/gtk working tree"
  else
    fail "INTG-02 (S5): git status dirty in stow/gtk"
  fi

  # 4. Strict verification engine execution
  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]]; then
    pass "INTG-02 (S5): arch/dots-hyprland.sh verify --strict passed with 0 findings"
  else
    fail "INTG-02 (S5): arch/dots-hyprland.sh verify --strict failed (rc=$VERIFY_RC)"
    printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
  fi
fi

# Porcelain comparison check
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
