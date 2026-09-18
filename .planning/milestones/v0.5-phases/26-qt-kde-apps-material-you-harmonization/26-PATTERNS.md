# Phase 26: Qt & KDE Apps Material You Harmonization - Pattern Map

**Mapped:** 2026-09-17  
**Files analyzed:** 2  
**Analogs found:** 2 / 2 (100% coverage)  

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guard-paths.tsv` | config | file-I/O | `guard-paths.tsv` (lines 1–21) | exact |
| `scripts/phase26-qt-kde-material-you-assert.sh` | test | file-I/O | `scripts/phase25-gtk-material-you-assert.sh` (lines 1–346) | exact |

---

## Pattern Assignments

### 1. `guard-paths.tsv` (config, file-I/O)

**Role:** Configuration data contract excluding dynamic runtime theme artifacts and vendor sync directories from git tracking.  
**Data Flow:** Read by `arch/dots-hyprland.sh` (`run_verify`) and assert test harnesses during strict invariant checks.  
**Analog:** [guard-paths.tsv](file:///home/pera/github_repo/.dotfiles/guard-paths.tsv) (lines 1–21)  
**Secondary Analog:** [collision-map.tsv](file:///home/pera/github_repo/.dotfiles/collision-map.tsv) (lines 62, 77)

#### Header and Tab-Separated Column Structure Pattern
**Source:** [guard-paths.tsv](file:///home/pera/github_repo/.dotfiles/guard-paths.tsv#L1-L15)
```tsv
# guard-paths v1
#
# Paths excluded from repository tracking and live repo-symlinking.
# Enforced by arch/dots-hyprland.sh verify and scripts/phase22-kde-and-gtk-capture-assert.sh.
#
# Empirical resolutions:
# Q7: kde-material-you-colors is actively invoked by switchwall.sh via .venv wrapper,
#     rewriting kdeglobals on every wallpaper change. Excluded to eliminate git churn.
# Q8: ~/.config/gtk-4.0/gtk.css symlinks to root-owned /usr/share/themes/... (0644).
#     User writes cannot alter system theme. Both gtk.css files are guarded out.
#
# Columns (tab-separated):
# path	category	generator	reason
$XDG_CONFIG_HOME/kdeglobals	generated_theme	kde-material-you-colors	Active wallpaper churn (Q7)
$XDG_CONFIG_HOME/Kvantum	vendor_theme	dots-hyprland	Upstream directory sync
```

#### Exact Line to Append (D-04, INTG-01)
```tsv
$XDG_CONFIG_HOME/kde-material-you-colors	generated_theme	kde-material-you-colors	Upstream directory sync
```
*Note: Fields must be separated strictly with a single ASCII tab (`\t`), matching `IFS=$'\t' read -r g_path g_cat g_gen g_reason`.*

#### Consuming Validation Gate Pattern
**Source:** [arch/dots-hyprland.sh](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1135-L1167)
```bash
  # GUARD path validation gate (D-18, D-23)
  local guard_file="$main_root/guard-paths.tsv"
  if [[ -f "$guard_file" ]]; then
    local g_path g_cat g_gen g_reason expanded live_target rel_sub
    while IFS=$'\t' read -r g_path g_cat g_gen g_reason || [[ -n "$g_path" ]]; do
      [[ -n "$g_path" && "$g_path" != \#* ]] || continue
      expanded="${g_path//\$XDG_CONFIG_HOME/$HOME\/.config}"
      expanded="${expanded//\$HOME/$HOME}"
      guarded_entries["$expanded"]=1

      # Assert not tracked in stow/, restow/, or capture/
      rel_sub="${expanded#"$HOME"/}"
      for tree in stow restow capture; do
        if [[ -d "$main_root/$tree" ]]; then
          for pkg_dir in "$main_root/$tree"/*; do
            [[ -d "$pkg_dir" ]] || continue
            if [[ -e "$pkg_dir/$rel_sub" ]]; then
              fail "guard path tracked in $tree: ${pkg_dir#"$main_root"/}/$rel_sub"
            fi
          done
        fi
      done

      # Assert live path is not a symlink into repo
      if [[ -L "$expanded" ]]; then
        live_target="$(readlink -f -- "$expanded" 2>/dev/null || true)"
        if [[ "$live_target" == "$main_root_real"/* || "$live_target" == "$main_root"/* ]]; then
          fail "guard path live counterpart symlinks into repo: $expanded -> $live_target"
        fi
      fi
      pass "guard path excluded: $g_path"
    done < "$guard_file"
  fi
```

---

### 2. `scripts/phase26-qt-kde-material-you-assert.sh` (test, file-I/O)

**Role:** Fail-closed bash test harness enforcing QT-01, QT-02, QT-03, INTG-01, and INTG-02 invariants across 5 switchable sections.  
**Data Flow:** Executes CLI probes, checks filesystem links and permissions, inspects INI configurations, runs python checks, invokes `dots-hyprland.sh verify --strict`, and verifies git status immutability.  
**Analog:** [scripts/phase25-gtk-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase25-gtk-material-you-assert.sh#L1-L346)  
**Secondary Analog:** [scripts/phase22-kde-and-gtk-capture-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase22-kde-and-gtk-capture-assert.sh#L451-L481)

#### Shell Setup, Strict Flags, and Pass/Fail Reporting Primitives
**Source:** [scripts/phase25-gtk-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase25-gtk-material-you-assert.sh#L1-L22)
```bash
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
```

#### Temp File & Scratch Root Trap Cleanup
**Source:** [scripts/phase25-gtk-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase25-gtk-material-you-assert.sh#L23-L36)
```bash
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

#### CLI Argument Parsing for Discrete Section Execution
**Source:** [scripts/phase25-gtk-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase25-gtk-material-you-assert.sh#L38-L60)
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
```

#### Git Porcelain Baseline Snapshot Pattern
**Source:** [scripts/phase25-gtk-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase25-gtk-material-you-assert.sh#L61-L75)
```bash
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
```

#### Section 1 Pattern: Virtualenv Readiness & Binary Assertions
**Context Reference:** CONTEXT.md D-08; RESEARCH.md lines 24–25, 99  
**Source Analog:** [scripts/phase25-gtk-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase25-gtk-material-you-assert.sh#L79-L87)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Virtualenv Readiness & Generator Binary ---"

  VENV_DIR="$HOME/.local/state/quickshell/.venv"
  GEN_BIN="$VENV_DIR/bin/kde-material-you-colors"

  if [[ -d "$VENV_DIR" && -x "$GEN_BIN" ]]; then
    pass "S1: quickshell virtualenv exists and kde-material-you-colors is executable"
  else
    fail "S1: quickshell virtualenv missing or kde-material-you-colors not executable: $GEN_BIN"
  fi

  # Version check
  GEN_VER="$("$GEN_BIN" --version 2>&1 || true)"
  if [[ "$GEN_VER" =~ (1\.[0-9]+(\.[0-9]+)?) ]]; then
    pass "S1: kde-material-you-colors reports valid version ($GEN_VER)"
  else
    fail "S1: kde-material-you-colors unexpected version response: $GEN_VER"
  fi
fi
```

#### Section 2 Pattern: Qt Environment Variables Alignment
**Context Reference:** CONTEXT.md D-14, D-15; [env.lua](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/hypr/hyprland/env.lua#L10-L16)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Qt Environment Variables Alignment ---"

  UPSTREAM_ENV="$HOME/.config/hypr/hyprland/env.lua"
  CUSTOM_ENV="$REPO_ROOT/stow/hypr/.config/hypr/custom/env.lua"

  if grep -q 'QT_QPA_PLATFORMTHEME.*"kde"' "$UPSTREAM_ENV" && \
     grep -q 'QT_QPA_PLATFORM.*"wayland;xcb"' "$UPSTREAM_ENV"; then
    pass "S2: ~/.config/hypr/hyprland/env.lua declares QT_QPA_PLATFORMTHEME=kde and QT_QPA_PLATFORM=wayland;xcb"
  else
    fail "S2: ~/.config/hypr/hyprland/env.lua missing standard Qt platform environment variables"
  fi

  # Ensure QT_STYLE_OVERRIDE is unset/empty in custom environment (D-15)
  if grep -q "QT_STYLE_OVERRIDE" "$CUSTOM_ENV"; then
    fail "S2: stow/hypr/.config/hypr/custom/env.lua must not declare QT_STYLE_OVERRIDE (D-15)"
  else
    pass "S2: stow/hypr/.config/hypr/custom/env.lua free of QT_STYLE_OVERRIDE collision"
  fi

  if [[ -n "${QT_STYLE_OVERRIDE:-}" ]]; then
    fail "S2: live session environment has active QT_STYLE_OVERRIDE=$QT_STYLE_OVERRIDE"
  else
    pass "S2: live session environment leaves QT_STYLE_OVERRIDE unset"
  fi
fi
```

#### Section 3 Pattern: Style Engine & Guard Path Contracts
**Context Reference:** CONTEXT.md D-01, D-02, D-03, D-04, INTG-01; [guard-paths.tsv](file:///home/pera/github_repo/.dotfiles/guard-paths.tsv#L14-L15)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Style Engine & Guard Path Contracts ---"

  # 1. Darkly style plugin binary
  DARKLY6_SO="/usr/lib/qt6/plugins/styles/darkly6.so"
  if [[ -f "$DARKLY6_SO" ]]; then
    pass "S3: Qt 6 Darkly style engine plugin exists ($DARKLY6_SO)"
  else
    fail "S3: Qt 6 Darkly style engine plugin missing ($DARKLY6_SO)"
  fi

  # 2. kdeglobals widgetStyle configuration
  KDEGLOBALS="$HOME/.config/kdeglobals"
  if [[ -f "$KDEGLOBALS" ]] && grep -q "^widgetStyle=Darkly$" "$KDEGLOBALS"; then
    pass "S3: ~/.config/kdeglobals configures widgetStyle=Darkly"
  else
    fail "S3: ~/.config/kdeglobals missing widgetStyle=Darkly"
  fi

  # 3. guard-paths.tsv contracts (Kvantum & kde-material-you-colors)
  GUARD_TSV="$REPO_ROOT/guard-paths.tsv"
  if grep -qF '$XDG_CONFIG_HOME/Kvantum' "$GUARD_TSV"; then
    pass "S3: guard-paths.tsv guards $XDG_CONFIG_HOME/Kvantum (D-02)"
  else
    fail "S3: guard-paths.tsv missing $XDG_CONFIG_HOME/Kvantum guard"
  fi

  if grep -qF '$XDG_CONFIG_HOME/kde-material-you-colors' "$GUARD_TSV"; then
    pass "S3: guard-paths.tsv guards $XDG_CONFIG_HOME/kde-material-you-colors (D-04, INTG-01)"
  else
    fail "S3: guard-paths.tsv missing $XDG_CONFIG_HOME/kde-material-you-colors guard"
  fi

  # Tab separation validation
  BAD_SPACES="$(grep -F '$XDG_CONFIG_HOME/kde-material-you-colors' "$GUARD_TSV" | grep ' ' || true)"
  if [[ -z "$BAD_SPACES" ]]; then
    pass "S3: kde-material-you-colors guard entry strictly tab-separated"
  else
    fail "S3: kde-material-you-colors guard entry contains spaces instead of tabs"
  fi
fi
```

#### Section 4 Pattern: Dynamic Palette Generation & Dark Luminance Assertion
**Context Reference:** CONTEXT.md D-05, D-06, D-09, D-13; RESEARCH.md lines 268–290, 301–315
```bash
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
    pass "S4: kde-material-you-colors execution touched ~/.config/kdeglobals"
  else
    fail "S4: ~/.config/kdeglobals was not updated by color generation"
  fi

  if grep -q "^ColorScheme=MaterialYouDark$" "$KDEGLOBALS"; then
    pass "S4: ~/.config/kdeglobals declares ColorScheme=MaterialYouDark"
  else
    fail "S4: ~/.config/kdeglobals missing ColorScheme=MaterialYouDark"
  fi

  # Color tokens presence
  if grep -q "^\[Colors:Window\]" "$KDEGLOBALS" && grep -q "^\[Colors:View\]" "$KDEGLOBALS"; then
    pass "S4: ~/.config/kdeglobals contains [Colors:Window] and [Colors:View] sections"
  else
    fail "S4: ~/.config/kdeglobals missing required color sections"
  fi

  # Programmatic relative luminance check via Python
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
    pass "S4: kdeglobals window and view background luminance conforms to dark palette ($LUM_VERDICT)"
  else
    fail "S4: kdeglobals background luminance failed: $LUM_VERDICT"
  fi
fi
```

#### Section 5 Pattern: Desktop Integration, Zero Churn, and Verifier Pass
**Source:** [scripts/phase25-gtk-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase25-gtk-material-you-assert.sh#L320-L345)
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Desktop Portal Integration & Strict Verifier ---"

  # 1. Desktop Portal FileChooser mapping (D-12)
  PORTAL_CONF="$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
  [[ -f "$PORTAL_CONF" ]] || PORTAL_CONF="$HOME/.config/xdg-desktop-portal/portals.conf"

  if [[ -f "$PORTAL_CONF" ]] && grep -q "org\.freedesktop\.impl\.portal\.FileChooser.*=.*kde" "$PORTAL_CONF"; then
    pass "S5: $PORTAL_CONF maps FileChooser portal to kde"
  else
    fail "S5: portals configuration missing FileChooser = kde"
  fi

  # 2. KDE Target Binaries Presence (D-10)
  for app in "/usr/bin/dolphin" "/usr/bin/gwenview"; do
    if [[ -x "$app" ]]; then
      pass "S5: KDE application $app is installed and executable"
    else
      fail "S5: KDE application $app missing or not executable"
    fi
  done

  # 3. Working tree cleanliness on tracked directories
  if [[ -z "$(git status --porcelain stow/ restow/)" ]]; then
    pass "S5: git working tree clean in stow/ and restow/ packaging directories"
  else
    fail "S5: git status dirty in stow/ or restow/: $(git status --porcelain stow/ restow/)"
  fi

  # 4. Strict verification engine execution (INTG-02)
  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]]; then
    pass "S5: arch/dots-hyprland.sh verify --strict passed with 0 findings"
  else
    fail "S5: arch/dots-hyprland.sh verify --strict failed (rc=$VERIFY_RC)"
    printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
  fi
fi

# Closing porcelain invariant check
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

## Shared Patterns

### 1. Sectioned Fail-Closed Assert CLI Architecture
**Source:** [scripts/phase25-gtk-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase25-gtk-material-you-assert.sh#L16-L59)  
**Apply to:** All verification scripts in `scripts/phase*-assert.sh`.  
**Pattern:**
- Standalone bash script with `set -euo pipefail`.
- Global counters: `FAIL=0` and `FINDINGS=0`.
- Diagnostic output functions: `pass()`, `fail()`, `finding()`, `info()`.
- `--section <N>` CLI option allowing isolated testing of individual requirement waves during development.
- Final summary banner `=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ===` exiting 1 if `FAIL > 0`.

### 2. Two-Phase Git Porcelain Snapshot Invariant
**Source:** [scripts/phase25-gtk-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase25-gtk-material-you-assert.sh#L61-L75), [L333-L339](file:///home/pera/github_repo/.dotfiles/scripts/phase25-gtk-material-you-assert.sh#L333-L339)  
**Apply to:** All integration assert harnesses touching user configurations or live files.  
**Pattern:**
- Captures raw git status (`git status --porcelain --ignored`) before running any test sections.
- Filters out non-repo ephemeral noise (`.commandcode/`, `__pycache__/`).
- Compares baseline against post-execution status (`cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"`).
- Guarantees test execution produces zero repo churn or side-effect drift.

### 3. Automated Temp/Scratch Resource Lifecycle Management
**Source:** [scripts/phase25-gtk-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase25-gtk-material-you-assert.sh#L23-L36)  
**Apply to:** Test harnesses that generate temporary snapshot files or mock directories.  
**Pattern:**
- Registers all created files in `TMP_FILES+=("$TEMP_FILE")`.
- Registers temporary directory trees in `SCRATCH_ROOTS+=("$MOCK_DIR")`.
- Employs `trap cleanup EXIT` to guarantee complete deletion on normal exit, `set -e` failure, or signal interruption.

### 4. Strict TSV Contract Parsing and Validation
**Source:** [arch/dots-hyprland.sh](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1135-L1167)  
**Apply to:** `guard-paths.tsv` and `collision-map.tsv` consumers and assert checkers.  
**Pattern:**
- Strictly uses `IFS=$'\t' read -r ...` to prevent whitespace corruption.
- Comments beginning with `#` and empty lines are explicitly ignored (`[[ -n "$g_path" && "$g_path" != \#* ]] || continue`).
- Expands `$XDG_CONFIG_HOME` to `~/.config` and `$HOME` to `/home/$USER`.
- Asserts that guarded paths do not exist in package trees (`stow/`, `restow/`, `capture/`) and do not symlink into repository root.

### 5. Safe DBus Subshell Execution on Non-KWin Desktops (D-09)
**Source:** [vendor/dots-hyprland/dots/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh#L46-L48)  
**Apply to:** Tests or automation triggering `kde-material-you-colors` under Wayland / Hyprland.  
**Pattern:**
- When running `kde-material-you-colors` outside a KDE Plasma session, the script writes `kdeglobals` and `.colors` scheme files successfully, but raises `dbus.exceptions.DBusException` when attempting `kwin_utils.reload()`.
- Automation must invoke the generator with `|| true` and validate deliverables directly (`stat -c %Y kdeglobals`, `grep ColorScheme=MaterialYouDark`, color group luminance) rather than checking the Python exit code.

---

## No Analog Found

*None.* All files to be modified or created in Phase 26 have direct, high-fidelity analogs in the existing repository codebase:
- `guard-paths.tsv`: Modified existing file following its established header and schema.
- `scripts/phase26-qt-kde-material-you-assert.sh`: Direct 1:1 structural descendant of `scripts/phase25-gtk-material-you-assert.sh`.

---

## Metadata

**Analog search scope:**
- `guard-paths.tsv`
- `collision-map.tsv`
- `arch/dots-hyprland.sh`
- `scripts/phase25-gtk-material-you-assert.sh`
- `scripts/phase22-kde-and-gtk-capture-assert.sh`
- `vendor/dots-hyprland/dots/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/env.lua`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh`
- `vendor/dots-hyprland/dots/.config/xdg-desktop-portal/hyprland-portals.conf`

**Files scanned:** 9  
**Pattern extraction date:** 2026-09-17  
