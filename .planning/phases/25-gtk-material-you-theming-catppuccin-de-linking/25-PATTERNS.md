# Phase 25: GTK Material You Theming & Catppuccin De-linking — Pattern Map

**Mapped:** 2026-09-16  
**Phase Directory:** [25-gtk-material-you-theming-catppuccin-de-linking](file:///home/pera/github_repo/.dotfiles/.planning/phases/25-gtk-material-you-theming-catppuccin-de-linking)  
**Output File:** [25-PATTERNS.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/25-gtk-material-you-theming-catppuccin-de-linking/25-PATTERNS.md)  
**Files Classified:** 7 target artifacts / operational units (1 new assert harness, 2 modified repo config files, 1 live directory de-linking target, 2 dynamic runtime theme outputs, 1 live GSettings interface schema)  
**Analogs Found:** 7 / 7 (100% covered by verified existing files in repository and upstream submodules)  

---

## File Classification

| Target Artifact / Path | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/phase25-gtk-material-you-assert.sh` (**new**) | test | batch / request-response | [`phase22-kde-and-gtk-capture-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase22-kde-and-gtk-capture-assert.sh#L234-L332) + [`phase24-tech-debt-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase24-tech-debt-assert.sh#L1-L75) | exact composite |
| `stow/gtk/.config/gtk-3.0/settings.ini` (**modify**) | config | file-I/O | [`stow/gtk/.config/gtk-3.0/settings.ini`](file:///home/pera/github_repo/.dotfiles/stow/gtk/.config/gtk-3.0/settings.ini#L1-L18) + [`switchwall.sh`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L37-L46) | exact self-analog |
| `stow/gtk/.config/gtk-4.0/settings.ini` (**modify**) | config | file-I/O | [`stow/gtk/.config/gtk-4.0/settings.ini`](file:///home/pera/github_repo/.dotfiles/stow/gtk/.config/gtk-4.0/settings.ini#L1-L8) + [`stow/gtk/.config/gtk-3.0/settings.ini`](file:///home/pera/github_repo/.dotfiles/stow/gtk/.config/gtk-3.0/settings.ini#L1-L18) | exact self-analog |
| `~/.config/gtk-4.0/` (Catppuccin symlink de-linking) | runtime state | file-I/O | [`phase22-kde-and-gtk-capture-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase22-kde-and-gtk-capture-assert.sh#L496-L508) + [`dots-hyprland.sh`](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1333-L1357) | exact |
| Dynamic theme outputs (`gtk-3.0/gtk.css` & `gtk-4.0/gtk.css`) | generated theme | event-driven / transform | [`matugen/templates/gtk-3.0/gtk.css`](file:///home/pera/.config/matugen/templates/gtk-3.0/gtk.css#L1-L39) + [`matugen/templates/gtk-4.0/gtk.css`](file:///home/pera/.config/matugen/templates/gtk-4.0/gtk.css#L6-L130) + [`switchwall.sh`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L184) | exact |
| `org.gnome.desktop.interface` (GSettings schema) | config | request-response / IPC | [`switchwall.sh`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L37-L46) + [`2.setups.sh`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/sdata/subcmd-install/2.setups.sh#L70-L72) | exact |
| `~/.config/xsettingsd/xsettingsd.conf` (discretionary align) | config | file-I/O | `~/.config/xsettingsd/xsettingsd.conf` (live file) | self-analog |

---

## Pattern Assignments by Component

### 1. `scripts/phase25-gtk-material-you-assert.sh` (Dedicated Gating Assert Harness)

**Role:** Phase gating test suite validating all 4 Phase 25 criteria (GTK-01, GTK-02, GTK-03, GTK-04) and 2 integration contracts (INTG-01, INTG-02) with fail-closed semantics.  
**Primary Analog:** [`scripts/phase22-kde-and-gtk-capture-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase22-kde-and-gtk-capture-assert.sh#L234-L332) (GTK package layout, unfolded parent directory assertion, and guard path checks).  
**Secondary Analog:** [`scripts/phase24-tech-debt-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase24-tech-debt-assert.sh#L1-L75) (scaffolding, cleanup trap, CLI `--section <1-5>` dispatch, git status porcelain snapshot bracket, and terminal summary block).

#### Pattern 1.1: Runner Scaffolding, Helpers, and Cleanup Trap
Copy from [`scripts/phase24-tech-debt-assert.sh:1-37`](file:///home/pera/github_repo/.dotfiles/scripts/phase24-tech-debt-assert.sh#L1-L37):
```bash
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
```

#### Pattern 1.2: CLI Section Parsing & Git Porcelain Bracket
Copy from [`scripts/phase24-tech-debt-assert.sh:38-75, 392-398`](file:///home/pera/github_repo/.dotfiles/scripts/phase24-tech-debt-assert.sh#L38-L75):
```bash
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
```

#### Pattern 1.3: Section 1 — Catppuccin De-linking in `~/.config/gtk-4.0/` (GTK-02)
Adapted from [`scripts/phase22-kde-and-gtk-capture-assert.sh:276-287, 496-508`](file:///home/pera/github_repo/.dotfiles/scripts/phase22-kde-and-gtk-capture-assert.sh#L276-L287):
```bash
# --- Section 1: Catppuccin De-linking in ~/.config/gtk-4.0/ (GTK-02) ---
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
```

#### Pattern 1.4: Section 2 — Repository Settings Alignment in `stow/gtk/` (GTK-03)
Adapted from [`scripts/phase22-kde-and-gtk-capture-assert.sh:240-274, 296-309`](file:///home/pera/github_repo/.dotfiles/scripts/phase22-kde-and-gtk-capture-assert.sh#L240-L274):
```bash
# --- Section 2: Repository Settings Alignment in stow/gtk/ (GTK-03) ---
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
```

#### Pattern 1.5: Section 3 — GNOME Desktop Interface GSettings (GTK-04)
Adapted from [`vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh:37-46`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L37-L46) and [`2.setups.sh:70-72`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/sdata/subcmd-install/2.setups.sh#L70-L72):
```bash
# --- Section 3: GNOME Desktop Interface GSettings (GTK-04) ---
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
```

#### Pattern 1.6: Section 4 — Dynamic Matugen CSS Generation (GTK-01)
Adapted from [`vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh:184`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L184) and [`~/.config/matugen/templates/gtk-4.0/gtk.css:6-130`](file:///home/pera/.config/matugen/templates/gtk-4.0/gtk.css#L6-L130):
```bash
# --- Section 4: Dynamic Matugen CSS Generation (GTK-01) ---
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
  if grep -q "@define-color accent_color" "$CSS3" && grep -q "@define-color window_bg_color" "$CSS3"; then
    pass "GTK-01 (S4): ~/.config/gtk-3.0/gtk.css contains valid Material You color definitions"
  else
    fail "GTK-01 (S4): ~/.config/gtk-3.0/gtk.css missing required @define-color tokens"
  fi

  # 3. Assert Material You tokens and media queries present in GTK 4 CSS
  if grep -q "@media (prefers-color-scheme: dark)" "$CSS4" && grep -q "@define-color accent_color" "$CSS4"; then
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
fi
```

#### Pattern 1.7: Section 5 — Verification Engine & Zero Churn (INTG-01, INTG-02)
Adapted from [`scripts/phase22-kde-and-gtk-capture-assert.sh:450-481, 536-544`](file:///home/pera/github_repo/.dotfiles/scripts/phase22-kde-and-gtk-capture-assert.sh#L450-L481) and [`scripts/phase24-tech-debt-assert.sh:378-405`](file:///home/pera/github_repo/.dotfiles/scripts/phase24-tech-debt-assert.sh#L378-L405):
```bash
# --- Section 5: Verification Engine & Zero Churn (INTG-01, INTG-02) ---
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
```

---

### 2. `stow/gtk/.config/gtk-3.0/settings.ini` (GTK 3 Desktop Configuration)

**Role:** Repository source of truth for GTK 3 desktop application settings.  
**Primary Analog:** [`stow/gtk/.config/gtk-3.0/settings.ini:1-18`](file:///home/pera/github_repo/.dotfiles/stow/gtk/.config/gtk-3.0/settings.ini#L1-L18).  
**Secondary Reference:** [`switchwall.sh:42`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L42) (`adw-gtk3-dark`) and [`2.setups.sh:70`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/sdata/subcmd-install/2.setups.sh#L70) (`Google Sans Flex Medium 11 @opsz=11,wght=500`).

#### Concrete Replacement Chunk Pattern
```ini
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Tela-circle-dracula-dark
gtk-font-name=Google Sans Flex Medium 11 @opsz=11,wght=500
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
```

**Key Points to Observe:**
- Preserves all GTK 3 font rendering and sound flags (`gtk-xft-*`, `gtk-enable-*-sounds`).
- Sets `gtk-theme-name=adw-gtk3-dark` (resolves D-01).
- Sets `gtk-font-name=Google Sans Flex Medium 11 @opsz=11,wght=500` (resolves D-02).
- Cursor set to `Bibata-Modern-Classic` size 24 (resolves D-03).
- No spaces around `=` in INI keys.

---

### 3. `stow/gtk/.config/gtk-4.0/settings.ini` (GTK 4 Fallback Desktop Configuration)

**Role:** Repository source of truth for GTK 4 fallback application settings.  
**Primary Analog:** [`stow/gtk/.config/gtk-4.0/settings.ini:1-8`](file:///home/pera/github_repo/.dotfiles/stow/gtk/.config/gtk-4.0/settings.ini#L1-L8).  
**Secondary Reference:** [`stow/gtk/.config/gtk-3.0/settings.ini`](file:///home/pera/github_repo/.dotfiles/stow/gtk/.config/gtk-3.0/settings.ini#L1-L6).

#### Concrete Replacement Chunk Pattern
```ini
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Tela-circle-dracula-dark
gtk-font-name=Google Sans Flex Medium 11 @opsz=11,wght=500
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
```

**Key Points to Observe:**
- Mirrors GTK 3 theme, icon, font, cursor, and dark preference keys.
- Does NOT include GTK 3 legacy toolbar or Xft keys (GTK 4 does not use Xft flags in `settings.ini`).
- Eliminates `catppuccin-mocha-teal-standard+default`.

---

### 4. `~/.config/gtk-4.0/` Legacy Symlink De-linking & Inode Conversion

**Role:** Safe unprivileged user-space unlinking of legacy root-pointing symlinks, freeing `~/.config/gtk-4.0/gtk.css` for Matugen output.  
**Primary Analog:** [`scripts/phase22-kde-and-gtk-capture-assert.sh:496-508`](file:///home/pera/github_repo/.dotfiles/scripts/phase22-kde-and-gtk-capture-assert.sh#L496-L508) (kdeglobals retirement and live symlink conversion).  
**Secondary Reference:** [`arch/dots-hyprland.sh:1333-1357`](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1333-L1357) (`managed_roots` directory unfolding check).

#### Concrete Shell Execution Pattern
```bash
# Safely remove Catppuccin symlinks pointing into /usr/share/themes/
rm -f "$HOME/.config/gtk-4.0/assets"
rm -f "$HOME/.config/gtk-4.0/gtk.css"
rm -f "$HOME/.config/gtk-4.0/gtk-dark.css"

# Invariant check: directory MUST remain an unfolded physical directory, NOT a symlink
test -d "$HOME/.config/gtk-4.0" && test ! -L "$HOME/.config/gtk-4.0"
```

**Key Points to Observe:**
- Does NOT touch `/usr/share/themes/` (system package boundaries respected per D-09).
- Does NOT create a replacement symlink `gtk-dark.css -> gtk.css` (violates D-08).
- Preserves existing Stow symlink: `~/.config/gtk-4.0/settings.ini -> stow/gtk/.config/gtk-4.0/settings.ini`.

---

### 5. Dynamic Theme Generation Pipeline (`~/.config/gtk-3.0/gtk.css` & `~/.config/gtk-4.0/gtk.css`)

**Role:** Compiles Material You color tokens extracted from wallpaper into regular CSS files.  
**Primary Analog:** [`switchwall.sh:184, 306-311`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L184) (`matugen_args=(--source-color-index 0)`).  
**Secondary Analog:** [`~/.config/matugen/config.toml:20-26`](file:///home/pera/.config/matugen/config.toml#L20-L26) (`[templates.gtk3]` and `[templates.gtk4]`).

#### Concrete Execution Pattern
```bash
# Query active wallpaper from quickshell state
WP_PATH="$(cat "$HOME/.local/state/quickshell/user/generated/wallpaper/path.txt" 2>/dev/null || echo "$HOME/Pictures/55192173787_b8322b1190_o.jpg")"

# Execute Matugen non-interactively with dark mode preference
matugen --source-color-index 0 --mode dark image "$WP_PATH"

# Verify outputs are regular files owned by user with mode 0644
test -f "$HOME/.config/gtk-3.0/gtk.css" && test ! -L "$HOME/.config/gtk-3.0/gtk.css"
test -f "$HOME/.config/gtk-4.0/gtk.css" && test ! -L "$HOME/.config/gtk-4.0/gtk.css"
```

**Key Points to Observe:**
- Always specify `--source-color-index 0` to prevent interactive TTY prompting on stdin.
- Output paths are governed by `~/.config/matugen/config.toml` lines 20–26.
- GTK 4 template outputs both `@media (prefers-color-scheme: light)` and `@media (prefers-color-scheme: dark)` blocks in a single `gtk.css`.

---

### 6. Desktop Interface GSettings Schema (`org.gnome.desktop.interface`)

**Role:** Synchronizes desktop portal and Wayland session GTK properties in dconf.  
**Primary Analog:** [`switchwall.sh:41-42`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L41-L42).  
**Secondary Analog:** [`2.setups.sh:70-71`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/sdata/subcmd-install/2.setups.sh#L70-L71).

#### Concrete CLI Configuration Pattern
```bash
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface font-name 'Google Sans Flex Medium 11 @opsz=11,wght=500'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
gsettings set org.gnome.desktop.interface cursor-size 24
gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle-dracula-dark'
```

---

### 7. Unmanaged Configuration Alignment (`~/.config/xsettingsd/xsettingsd.conf`)

**Role:** Discretionary cleanup of unmanaged legacy XSettings configuration on disk to avoid residual Catppuccin leakage if `xsettingsd` is ever launched.  
**Primary Analog:** `~/.config/xsettingsd/xsettingsd.conf` (live file).

#### Concrete Edit Pattern
```ini
Net/ThemeName "adw-gtk3-dark"
Net/IconThemeName "Tela-circle-dracula-dark"
Gtk/CursorThemeName "Bibata-Modern-Classic"
Gtk/CursorThemeSize 24
Net/EnableEventSounds 1
EnableInputFeedbackSounds 0
Xft/Antialias 1
Xft/Hinting 1
Xft/HintStyle "hintslight"
Xft/RGBA "rgb"
```

---

## Guard & Zero Churn Integration Patterns

### 1. `guard-paths.tsv` Registration (INTG-01)
Source: [`guard-paths.tsv:16-17`](file:///home/pera/github_repo/.dotfiles/guard-paths.tsv#L16-L17)
```tsv
$XDG_CONFIG_HOME/gtk-3.0/gtk.css	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/gtk-4.0/gtk.css	generated_theme	matugen	Root-owned theme symlink (Q8)
```
- Invariant: Neither file may ever be tracked in `stow/`, `restow/`, or `capture/`.
- Invariant: Live file must never symlink back into the repository working tree.

### 2. `.gitignore` Rule Semantics (INTG-01)
Source: [`.gitignore:38-39`](file:///home/pera/github_repo/.dotfiles/.gitignore#L38-L39)
```gitignore
gtk.css
gtk-dark.css
```
- Slash-free pattern matches at any directory depth.
- Prevents accidental `git add` of generated CSS stylesheets.

### 3. Verification Engine Classification (INTG-02)
Source: [`arch/dots-hyprland.sh:1341-1344`](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1341-L1344)
```bash
# Guarded theme output check (D-24)
if [[ -n "${guarded_entries[$entry]:-}" ]]; then
  info "guarded theme output: $entry"
  return 0
fi
```
When `~/.config/gtk-4.0/gtk.css` is generated as a regular file, the verification engine matches it against `guarded_entries`, logs `[INFO] guarded theme output: /home/pera/.config/gtk-4.0/gtk.css`, and exits 0 with 0 findings.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It Fails | Correct Pattern |
|---|---|---|
| **Interactive `matugen image <path>` invocation** | Matugen blocks on stdin prompting *"Select the color you want to use as source color"*, hanging automated scripts and tests. | Always pass `--source-color-index 0` (e.g. `matugen --source-color-index 0 --mode dark image <path>`). |
| **Creating `ln -s gtk.css gtk-dark.css` in `~/.config/gtk-4.0/`** | GTK 4 evaluates dark/light modes via `@media (prefers-color-scheme: dark)` in a single `gtk.css`. Leaving `gtk-dark.css` creates an unmanaged stub violating D-08. | Remove `gtk-dark.css` and do not recreate it. |
| **Running `pacman -R` on Catppuccin system packages** | Violates D-09 and phase boundary. System packages in `/usr/share/` are out of scope for user dotfiles. | Limit all actions strictly to user configuration (`~/.config/gtk-4.0/` and repo `stow/gtk/`). |
| **Folding `~/.config/gtk-4.0/` into a symlink to `stow/gtk/`** | If `~/.config/gtk-4.0` became a symlink to the repo, Matugen generating `gtk.css` would write directly into git, causing dirty status and failing `verify --strict`. | Keep `stow/gtk/` unfolded (`--no-folding`). `~/.config/gtk-4.0/` must remain a real directory. |
| **Modifying `stow/gtk/.config/gtk-3.0/bookmarks`** | Violates Phase 22 D-11 convention preserving single-machine personal dotfile bookmarks. | Retain `bookmarks` file unchanged. |

---

## Pattern Coverage Summary

```
Target Components: 7 / 7 Classified
├── Test Harness: scripts/phase25-gtk-material-you-assert.sh (exact composite from phase22 + phase24)
├── GTK 3 Config: stow/gtk/.config/gtk-3.0/settings.ini (self-analog + upstream switchwall.sh / 2.setups.sh)
├── GTK 4 Config: stow/gtk/.config/gtk-4.0/settings.ini (self-analog + GTK 3 dark settings)
├── Live De-linking: ~/.config/gtk-4.0/ (phase22 kdeglobals unlinking analog)
├── Dynamic Generator: Matugen CLI + templates (quickshell switchwall.sh analog)
├── GSettings: org.gnome.desktop.interface (quickshell switchwall.sh + 2.setups.sh analog)
└── Discretionary: ~/.config/xsettingsd/xsettingsd.conf (self-analog)

Coverage: 100%
All code excerpts verified against live filesystem and repository commits.
```
