# Phase 27: Hyprland & Quickshell ii Accent Coordination - Pattern Map

**Mapped:** 2026-09-17  
**Files analyzed:** 10  
**Analogs found:** 10 / 10 (100% coverage)  

---

## File Classification

| File / Component | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/phase27-accent-coordination-assert.sh` | test | file-I/O / request-response | [scripts/phase26-qt-kde-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase26-qt-kde-material-you-assert.sh) (lines 1–334) | exact |
| `stow/hypr/.config/hypr/custom/general.lua` | config | file-I/O | [stow/hypr/.config/hypr/custom/general.lua](file:///home/pera/github_repo/.dotfiles/stow/hypr/.config/hypr/custom/general.lua) (lines 1–28) | exact |
| `vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua` | template | file-I/O | [vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua) (lines 1–17) | exact |
| `~/.config/hypr/hyprland/colors.lua` | config (generated) | file-I/O / event-driven inotify | `~/.config/hypr/hyprland/colors.lua` (lines 1–17) | exact |
| `vendor/dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml` | service | streaming / event-driven QML FileView | [vendor/dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml) (lines 1–98) | exact |
| `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | model / service | reactive property binding | [vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml) (lines 37–100, 150–199) | exact |
| `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh` | controller / script | process execution / event-driven | [vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh) (lines 306–375) | exact |
| `~/.local/state/quickshell/user/generated/colors.json` | data / state | file-I/O | [vendor/dots-hyprland/dots/.config/matugen/templates/colors.json](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/matugen/templates/colors.json) (lines 1–52) | exact |
| `capture/ii/.config/illogical-impulse/config.json` | config / capture | file-I/O | [capture/ii/.config/illogical-impulse/config.json](file:///home/pera/github_repo/.dotfiles/capture/ii/.config/illogical-impulse/config.json) (lines 32–53, 152–158) | exact |
| `guard-paths.tsv` | config | file-I/O | [guard-paths.tsv](file:///home/pera/github_repo/.dotfiles/guard-paths.tsv) (lines 13–21) | exact |

---

## Pattern Assignments

### 1. `scripts/phase27-accent-coordination-assert.sh` (test, file-I/O / request-response)

**Role:** Automated 5-section fail-closed bash test harness enforcing SHELL-01, SHELL-02, SHELL-03, INTG-01, and INTG-02 requirements.  
**Data Flow:** Parses Matugen templates, Lua scripts, JSON state; queries live Hyprland compositor IPC via `hyprctl`; runs `--noswitch` wallpaper reloads; monitors subsecond mtimes; verifies `guard-paths.tsv`; runs `dots-hyprland.sh verify --strict`; guarantees zero git working tree drift.  
**Analog:** [scripts/phase26-qt-kde-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase26-qt-kde-material-you-assert.sh#L1-L334)  
**Secondary Analog:** [scripts/phase25-gtk-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase25-gtk-material-you-assert.sh#L1-L346)  

#### Header, Bash Flags, and Output Primitives Pattern
**Source:** [scripts/phase26-qt-kde-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase26-qt-kde-material-you-assert.sh#L1-L24)
```bash
#!/usr/bin/env bash
# Phase 27 Hyprland & Quickshell ii Accent Coordination assert harness (SHELL-01 to SHELL-03, INTG-01, INTG-02).
# One script, one section per requirement criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase27-accent-coordination-assert.sh [--section <1-5>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

ASSERT_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }
```

#### Trap Cleanup & CLI Argument Parser Pattern
**Source:** [scripts/phase26-qt-kde-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase26-qt-kde-material-you-assert.sh#L25-L61)
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

#### Two-Phase Git Porcelain Snapshot Pattern
**Source:** [scripts/phase26-qt-kde-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase26-qt-kde-material-you-assert.sh#L63-L77)
```bash
porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p27-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p27-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"
```

#### Section 1 Pattern: Template & Config Readiness (INTG-01, D-01, D-02, D-04, D-08)
**Goal:** Verify Matugen templates, `colors.lua` existence, `guard-paths.tsv` data contract, and zero personal border overrides in `stow/hypr/custom/general.lua`.
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Template & Config Readiness (INTG-01, D-01..D-04, D-08) ---"

  # 1. Matugen hyprland colors template readiness
  MATUGEN_HYPR_TPL="$REPO_ROOT/vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua"
  [[ -f "$MATUGEN_HYPR_TPL" ]] || MATUGEN_HYPR_TPL="$XDG_CONFIG_HOME/matugen/templates/hyprland/colors.lua"

  if [[ -f "$MATUGEN_HYPR_TPL" ]] && \
     grep -q 'active_border.*outline_variant' "$MATUGEN_HYPR_TPL" && \
     grep -q 'inactive_border.*surface_container_low' "$MATUGEN_HYPR_TPL" && \
     grep -q 'background_color.*surface\.dark' "$MATUGEN_HYPR_TPL" && \
     grep -q 'border_color.*primary' "$MATUGEN_HYPR_TPL"; then
    pass "S1: Matugen hyprland colors template declares active, inactive, background, and pinned border tokens (D-01..D-03, D-08)"
  else
    fail "S1: Matugen hyprland colors template missing required token bindings ($MATUGEN_HYPR_TPL)"
  fi

  # 2. Live colors.lua existence and syntax
  LIVE_COLORS_LUA="$XDG_CONFIG_HOME/hypr/hyprland/colors.lua"
  if [[ -f "$LIVE_COLORS_LUA" && -s "$LIVE_COLORS_LUA" ]]; then
    pass "S1: Live colors.lua exists and is non-empty ($LIVE_COLORS_LUA)"
  else
    fail "S1: Live colors.lua missing or empty ($LIVE_COLORS_LUA)"
  fi

  # 3. guard-paths.tsv contract validation for colors.lua (INTG-01)
  GUARD_TSV="$REPO_ROOT/guard-paths.tsv"
  if grep -qF '$XDG_CONFIG_HOME/hypr/hyprland/colors.lua' "$GUARD_TSV"; then
    pass "S1: guard-paths.tsv guards \$XDG_CONFIG_HOME/hypr/hyprland/colors.lua (INTG-01)"
  else
    fail "S1: guard-paths.tsv missing \$XDG_CONFIG_HOME/hypr/hyprland/colors.lua guard (INTG-01)"
  fi

  # Tab separation validation: ensure columns are strictly delimited by tabs
  ROW="$(grep -F '$XDG_CONFIG_HOME/hypr/hyprland/colors.lua' "$GUARD_TSV" || true)"
  IFS=$'\t' read -r c1 c2 c3 c4 <<< "$ROW"
  if [[ "$c1" == '$XDG_CONFIG_HOME/hypr/hyprland/colors.lua' && "$c2" == "generated_theme" && "$c3" == "matugen" && -n "$c4" && ! "$c1" =~ [[:space:]] && ! "$c2" =~ [[:space:]] && ! "$c3" =~ [[:space:]] ]]; then
    pass "S1: colors.lua guard entry strictly tab-separated (INTG-01)"
  else
    fail "S1: colors.lua guard entry not properly tab-separated (INTG-01)"
  fi

  # 4. Upstream overlay purity: Zero personal border overrides in custom/general.lua (D-04)
  CUSTOM_GENERAL="$REPO_ROOT/stow/hypr/.config/hypr/custom/general.lua"
  if [[ -f "$CUSTOM_GENERAL" ]]; then
    if grep -E -q '(active_border|inactive_border|col\.active|col\.inactive|border_color|background_color)' "$CUSTOM_GENERAL"; then
      fail "S1: stow/hypr/.config/hypr/custom/general.lua contains personal border overrides (D-04 violation)"
    else
      pass "S1: stow/hypr/.config/hypr/custom/general.lua maintains upstream overlay purity (zero border overrides) (D-04)"
    fi
  else
    pass "S1: stow/hypr/.config/hypr/custom/general.lua not present (pure upstream)"
  fi
fi
```

#### Section 2 Pattern: Hyprland Window Borders & Compositor Token Match (SHELL-01, D-01..D-03, D-08, D-30)
**Goal:** Parse tokens from `colors.lua`, translate `rgba(RRGGBBAA)` to compositor format `AARRGGBB`, query live `hyprctl getoption`, and provide graceful fallback for headless CI.
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Hyprland Window Borders & Compositor Token Match (SHELL-01, D-01..D-03, D-08, D-30) ---"

  LIVE_COLORS_LUA="$XDG_CONFIG_HOME/hypr/hyprland/colors.lua"

  # 1. Parse active_border: rgba(46474777) -> RGB=464747, Alpha=77 -> Expected gradient hex: 77464747
  lua_active_raw="$(grep -oP 'active_border\s*=\s*"rgba\(\K[0-9a-fA-F]{8}' "$LIVE_COLORS_LUA" || true)"
  if [[ -n "$lua_active_raw" && ${#lua_active_raw} -eq 8 ]]; then
    lua_active_rgb="${lua_active_raw:0:6}"
    lua_active_alpha="${lua_active_raw:6:2}"
    expected_active_gradient="${lua_active_alpha}${lua_active_rgb}"
    pass "S2: Parsed active_border from colors.lua: rgba(${lua_active_raw}) -> expected gradient ${expected_active_gradient} (D-01)"
  else
    fail "S2: Failed to parse active_border from colors.lua ($LIVE_COLORS_LUA) (D-01)"
  fi

  # 2. Parse inactive_border: rgba(1b1c1c33) -> RGB=1b1c1c, Alpha=33 -> Expected gradient hex: 331b1c1c
  lua_inactive_raw="$(grep -oP 'inactive_border\s*=\s*"rgba\(\K[0-9a-fA-F]{8}' "$LIVE_COLORS_LUA" || true)"
  if [[ -n "$lua_inactive_raw" && ${#lua_inactive_raw} -eq 8 ]]; then
    lua_inactive_rgb="${lua_inactive_raw:0:6}"
    lua_inactive_alpha="${lua_inactive_raw:6:2}"
    expected_inactive_gradient="${lua_inactive_alpha}${lua_inactive_rgb}"
    pass "S2: Parsed inactive_border from colors.lua: rgba(${lua_inactive_raw}) -> expected gradient ${expected_inactive_gradient} (D-02)"
  else
    fail "S2: Failed to parse inactive_border from colors.lua ($LIVE_COLORS_LUA) (D-02)"
  fi

  # 3. Parse pinned window rule primary accent gradient (D-03)
  if grep -qP 'match\s*=\s*\{\s*pin\s*=\s*1\s*\}' "$LIVE_COLORS_LUA" && \
     grep -qP 'border_color\s*=\s*"rgba\([0-9a-fA-F]{8}\)\s+rgba\([0-9a-fA-F]{8}\)"' "$LIVE_COLORS_LUA"; then
    pass "S2: Pinned window border rule binds primary accent gradient in colors.lua (D-03)"
  else
    fail "S2: Pinned window border rule missing or invalid in colors.lua (D-03)"
  fi

  # 4. Parse canvas background_color (D-08)
  lua_bg_raw="$(grep -oP 'background_color\s*=\s*"rgba\(\K[0-9a-fA-F]{8}' "$LIVE_COLORS_LUA" || true)"
  if [[ -n "$lua_bg_raw" && ${#lua_bg_raw} -eq 8 ]]; then
    pass "S2: Canvas background_color declared as rgba(${lua_bg_raw}) (D-08)"
  else
    fail "S2: Canvas background_color missing or invalid in colors.lua (D-08)"
  fi

  # 5. Live Compositor State Query (D-30)
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl &>/dev/null; then
    info "S2: Active Hyprland compositor detected (signature=$HYPRLAND_INSTANCE_SIGNATURE)"

    # Query active_border
    live_active_gradient="$(hyprctl -j getoption general:col.active_border 2>/dev/null | jq -r '.gradient // empty' | awk '{print $1}')"
    if [[ -n "$live_active_gradient" && "${expected_active_gradient,,}" == "${live_active_gradient,,}" ]]; then
      pass "S2: Live compositor active_border matches colors.lua ($live_active_gradient) (SHELL-01, D-01)"
    else
      fail "S2: Live compositor active_border mismatch: expected ${expected_active_gradient,,}, got ${live_active_gradient,,}"
    fi

    # Query inactive_border
    live_inactive_gradient="$(hyprctl -j getoption general:col.inactive_border 2>/dev/null | jq -r '.gradient // empty' | awk '{print $1}')"
    if [[ -n "$live_inactive_gradient" && "${expected_inactive_gradient,,}" == "${live_inactive_gradient,,}" ]]; then
      pass "S2: Live compositor inactive_border matches colors.lua ($live_inactive_gradient) (SHELL-01, D-02)"
    else
      fail "S2: Live compositor inactive_border mismatch: expected ${expected_inactive_gradient,,}, got ${live_inactive_gradient,,}"
    fi
  else
    info "S2: Headless CI or non-GUI environment (HYPRLAND_INSTANCE_SIGNATURE unset); skipping live compositor probe (D-30 fallback)"
  fi
fi
```

#### Section 3 Pattern: Quickshell ii Token Schema & Appearance Integrity (SHELL-02, D-13..D-15, D-31)
**Goal:** Assert `colors.json` format, validate 8 core M3 tokens, and verify `config.json` warning thresholds and appearance baseline.
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Quickshell ii Token Schema & Appearance Integrity (SHELL-02, D-13..D-15, D-31) ---"

  COLORS_JSON="$XDG_STATE_HOME/quickshell/user/generated/colors.json"

  # 1. Assert colors.json existence and non-empty
  if [[ -f "$COLORS_JSON" && -s "$COLORS_JSON" ]]; then
    pass "S3: Quickshell generated colors.json exists ($COLORS_JSON) (SHELL-02)"
  else
    fail "S3: Quickshell generated colors.json missing or empty ($COLORS_JSON) (SHELL-02)"
  fi

  # 2. Validate JSON syntax
  if jq empty "$COLORS_JSON" 2>/dev/null; then
    pass "S3: colors.json is valid JSON (D-31)"
  else
    fail "S3: colors.json is invalid JSON syntax (D-31)"
  fi

  # 3. Assert required M3 color tokens presence and #RRGGBB hex format (D-31)
  required_tokens=(
    "primary"
    "secondary"
    "tertiary"
    "surface"
    "error"
    "outline_variant"
    "surface_container_low"
    "background"
  )
  for token in "${required_tokens[@]}"; do
    val="$(jq -r --arg t "$token" '.[$t] // empty' "$COLORS_JSON" 2>/dev/null || true)"
    if [[ "$val" =~ ^#[0-9a-fA-F]{6}$ ]]; then
      pass "S3: M3 token '$token' present and valid hex: $val (D-31)"
    else
      fail "S3: M3 token '$token' missing or invalid hex format: '$val' (D-31)"
    fi
  done

  # 4. Validate appearance baseline configuration in config.json (D-13, D-14, D-15)
  CONFIG_JSON="$REPO_ROOT/capture/ii/.config/illogical-impulse/config.json"
  [[ -f "$CONFIG_JSON" ]] || CONFIG_JSON="$XDG_CONFIG_HOME/illogical-impulse/config.json"

  if [[ -f "$CONFIG_JSON" ]]; then
    # Palette scheme type "auto" (D-13)
    p_type="$(jq -r '.appearance.palette.type // empty' "$CONFIG_JSON" 2>/dev/null || true)"
    if [[ "$p_type" == "auto" ]]; then
      pass "S3: Appearance palette type is 'auto' (D-13)"
    else
      fail "S3: Appearance palette type expected 'auto', got '$p_type' (D-13)"
    fi

    # Background transparency disabled (opaque) (D-15)
    transp="$(jq -r '.appearance.transparency.enable // empty' "$CONFIG_JSON" 2>/dev/null || true)"
    if [[ "$transp" == "false" ]]; then
      pass "S3: Background transparency is disabled (opaque) (D-15)"
    else
      fail "S3: Background transparency expected 'false', got '$transp' (D-15)"
    fi

    # Warning thresholds (D-14)
    cpu_warn="$(jq -r '.resources.cpuWarningThreshold // empty' "$CONFIG_JSON" 2>/dev/null || true)"
    mem_warn="$(jq -r '.resources.memoryWarningThreshold // empty' "$CONFIG_JSON" 2>/dev/null || true)"
    swap_warn="$(jq -r '.resources.swapWarningThreshold // empty' "$CONFIG_JSON" 2>/dev/null || true)"
    if [[ "$cpu_warn" == "90" && "$mem_warn" == "95" && "$swap_warn" == "85" ]]; then
      pass "S3: Resource warning thresholds match upstream spec (cpu:90, mem:95, swap:85) (D-14)"
    else
      fail "S3: Resource warning thresholds mismatch: cpu=$cpu_warn mem=$mem_warn swap=$swap_warn (D-14)"
    fi

    # Wallpaper fixture validation
    wp_path="$(jq -r '.background.wallpaperPath // empty' "$CONFIG_JSON" 2>/dev/null || true)"
    if [[ -n "$wp_path" && -f "$wp_path" && -r "$wp_path" ]]; then
      pass "S3: Wallpaper fixture exists and is readable ($wp_path)"
    else
      finding "S3: Wallpaper path does not point to readable file ($wp_path)"
    fi
  else
    fail "S3: Logical impulse config.json missing ($CONFIG_JSON)"
  fi
fi
```

#### Section 4 Pattern: Coordinated Wallpaper Reload Probe (SHELL-03, D-21, D-22, D-24, D-28, D-32)
**Goal:** Execute `switchwall.sh --noswitch` drill, verify mtime advancement on `colors.lua` and `colors.json`, check border sync, and ensure non-blocking fail-soft completion.
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Live Coordinated Reload Probe (SHELL-03, D-21, D-22, D-24, D-28, D-32) ---"

  SWITCHWALL="$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"
  LIVE_COLORS_LUA="$XDG_CONFIG_HOME/hypr/hyprland/colors.lua"
  COLORS_JSON="$XDG_STATE_HOME/quickshell/user/generated/colors.json"

  if [[ -x "$SWITCHWALL" ]]; then
    pass "S4: switchwall.sh exists and is executable ($SWITCHWALL) (D-26)"
  else
    fail "S4: switchwall.sh missing or not executable ($SWITCHWALL) (D-26)"
  fi

  # Record pre-run mtimes
  BEFORE_LUA_MTIME="$(stat -c %Y "$LIVE_COLORS_LUA" 2>/dev/null || echo 0)"
  BEFORE_JSON_MTIME="$(stat -c %Y "$COLORS_JSON" 2>/dev/null || echo 0)"

  # Allow filesystem timestamp clock tick
  sleep 1

  # Execute coordinated reload drill via --noswitch
  SW_RC=0
  "$SWITCHWALL" --noswitch >/dev/null 2>&1 || SW_RC=$?
  if [[ "$SW_RC" -eq 0 ]]; then
    pass "S4: switchwall.sh --noswitch executed successfully with exit 0 (SHELL-03, D-23)"
  else
    fail "S4: switchwall.sh --noswitch failed with exit code $SW_RC (SHELL-03, D-23)"
  fi

  # Record post-run mtimes
  AFTER_LUA_MTIME="$(stat -c %Y "$LIVE_COLORS_LUA" 2>/dev/null || echo 0)"
  AFTER_JSON_MTIME="$(stat -c %Y "$COLORS_JSON" 2>/dev/null || echo 0)"

  if [[ "$AFTER_LUA_MTIME" -gt "$BEFORE_LUA_MTIME" ]]; then
    pass "S4: colors.lua mtime advanced ($BEFORE_LUA_MTIME -> $AFTER_LUA_MTIME) (D-32)"
  else
    fail "S4: colors.lua mtime was not updated by switchwall.sh (D-32)"
  fi

  if [[ "$AFTER_JSON_MTIME" -gt "$BEFORE_JSON_MTIME" ]]; then
    pass "S4: colors.json mtime advanced ($BEFORE_JSON_MTIME -> $AFTER_JSON_MTIME) (D-32)"
  else
    fail "S4: colors.json mtime was not updated by switchwall.sh (D-32)"
  fi

  # Inotify live border sync probe (when compositor active)
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl &>/dev/null; then
    sleep 0.2
    new_active_raw="$(grep -oP 'active_border\s*=\s*"rgba\(\K[0-9a-fA-F]{8}' "$LIVE_COLORS_LUA" || true)"
    if [[ -n "$new_active_raw" && ${#new_active_raw} -eq 8 ]]; then
      exp_new="${new_active_raw:6:2}${new_active_raw:0:6}"
      live_new="$(hyprctl -j getoption general:col.active_border 2>/dev/null | jq -r '.gradient // empty' | awk '{print $1}')"
      if [[ "${exp_new,,}" == "${live_new,,}" ]]; then
        pass "S4: Hyprland inotify re-evaluated active_border live without restart ($live_new) (D-21)"
      else
        fail "S4: Hyprland inotify border mismatch: expected $exp_new, got $live_new (D-21)"
      fi
    fi
  fi
fi
```

#### Section 5 Pattern: Strict Verification Engine & Zero Git Drift (INTG-01, INTG-02, D-28, D-29)
**Goal:** Verify packaging directories have clean git status and run `./arch/dots-hyprland.sh verify --strict` reporting `FAIL=0 FINDINGS=0`.
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Strict Verification Engine & Zero Git Drift (INTG-01, INTG-02, D-28, D-29) ---"

  # 1. Cleanliness of packaging trees
  DIRTY_PACKAGES="$(git status --porcelain stow/ restow/ capture/ || true)"
  if [[ -z "$DIRTY_PACKAGES" ]]; then
    pass "S5: Packaging directories (stow/, restow/, capture/) are 100% clean (INTG-02)"
  else
    fail "S5: Packaging directories dirty: $DIRTY_PACKAGES (INTG-02)"
  fi

  # 2. Strict verification engine run
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
  pass "Closing self-check: git status --porcelain unchanged across run (D-28)"
else
  fail "Closing self-check: git status --porcelain mutated across run (D-28)"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

---

### 2. `stow/hypr/.config/hypr/custom/general.lua` (config, file-I/O)

**Role:** Personal display, monitor scaling, and workspace mapping configuration.  
**Data Flow:** Sourced conditionally by upstream `hyprland.lua` via `is_file_exists(HOME .. "/.config/hypr/custom/general.lua")`.  
**Analog:** [stow/hypr/.config/hypr/custom/general.lua](file:///home/pera/github_repo/.dotfiles/stow/hypr/.config/hypr/custom/general.lua#L1-L28)  

#### Overlay Purity & Zero Border Override Pattern
**Source:** [stow/hypr/.config/hypr/custom/general.lua](file:///home/pera/github_repo/.dotfiles/stow/hypr/.config/hypr/custom/general.lua#L1-L28)
```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.

hl.monitor({
    output = "DP-1",
    mode = "preferred",
    position = "auto",
    scale = "auto"
})
hl.monitor({
    output = "HDMI-A-2",
    mode = "preferred",
    position = "auto",
    scale = 1.5,
    transform = 1
})

hl.workspace_rule({ workspace = "1", monitor = "DP-1" })
hl.workspace_rule({ workspace = "2", monitor = "DP-1" })
hl.workspace_rule({ workspace = "3", monitor = "DP-1" })
hl.workspace_rule({ workspace = "4", monitor = "DP-1" })
hl.workspace_rule({ workspace = "5", monitor = "DP-1" })
hl.workspace_rule({ workspace = "special:social", monitor = "DP-1" })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "9", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-2" })
```
*Note (D-04): This file MUST NOT contain `col.active_border`, `col.inactive_border`, `border_color`, or `background_color`. Dynamic decorations are governed solely by `colors.lua`.*

---

### 3. Matugen Hyprland Color Template `vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua` & Target `~/.config/hypr/hyprland/colors.lua` (template / generated config, file-I/O / inotify)

**Role:** Dynamic Material You window decoration and canvas background template rendered by Matugen.  
**Data Flow:** Seeded by wallpaper color extraction in `switchwall.sh`, written to `~/.config/hypr/hyprland/colors.lua`, and re-evaluated dynamically by Hyprland 0.56 inotify.  
**Analog:** [vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua#L1-L17)  

#### Template Declaration Pattern
**Source:** [vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua#L1-L17)
```lua
hl.config({
    general = {
        col = {
            active_border   = "rgba({{colors.outline_variant.default.hex_stripped}}77)",
            inactive_border = "rgba({{colors.surface_container_low.default.hex_stripped}}33)",
        },
    },
    misc = {
        background_color = "rgba({{colors.surface.dark.hex_stripped}}FF)",
    },
})

hl.window_rule({
    match        = { pin = 1 },
    border_color = "rgba({{colors.primary.default.hex_stripped}}AA) rgba({{colors.primary.default.hex_stripped}}77)",
})
```

#### Inotify Sourcing Hierarchy in Hyprland Startup
**Source:** [vendor/dots-hyprland/dots/.config/hypr/hyprland.lua](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/hypr/hyprland.lua#L14-L20)
```lua
-- Default configurations --
require("hyprland.execs")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.colors")
require("hyprland.keybinds")
```
*Note (D-21): Hyprland 0.56 automatically places inotify watches on all Lua files required by `hyprland.lua`. When Matugen modifies `colors.lua`, Hyprland re-evaluates `hl.config()` and updates window borders live without needing `hyprctl reload`.*

---

### 4. Quickshell Theme Loader `vendor/dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml` (service, streaming / event-driven)

**Role:** In-process theme watcher loading generated M3 tokens into `Appearance.m3colors`.  
**Data Flow:** Uses native Qt `FileView` to detect modifications to `colors.json` and updates property bindings in-place.  
**Analog:** [vendor/dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml#L22-L34,L61-L74)  

#### In-Process Theme Parsing and Hot-Reload Pattern
**Source:** [vendor/dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml#L22-L34,L61-L74)
```qml
    function applyColors(fileContent) {
        const json = JSON.parse(fileContent)
        for (const key in json) {
            if (json.hasOwnProperty(key)) {
                // Convert snake_case to CamelCase
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                const m3Key = `m3${camelCaseKey}`
                Appearance.m3colors[m3Key] = json[key]
            }
        }
        Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
    }

    FileView { 
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
        onLoadFailed: root.resetFilePathNextTime();
    }
```

---

### 5. Coordinated Wallpaper Reload Orchestrator `switchwall.sh` (controller / script, process execution / event-driven)

**Role:** Master coordinator executing Matugen synchronously and dispatching downstream terminal and Qt reloads concurrently in the background.  
**Data Flow:** Reads `.background.wallpaperPath` from `config.json`, generates palette templates, dispatches background tasks, exits with 0 and clean repository state.  
**Analog:** [vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L306-L317,L371-L375)  

#### Synchronous Generation with Asynchronous Dispatch Pattern
**Source:** [vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L306-L317)
```bash
    # Synchronous Matugen template rendering (colors.lua, colors.json, gtk.css)
    matugen "${matugen_args[@]}"
    source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
    python3 "$SCRIPT_DIR/generate_colors_material.py" "${generate_colors_material_args[@]}" \
        > "$STATE_DIR"/user/generated/material_colors.scss
    deactivate

    # Downstream terminal palette update
    "$SCRIPT_DIR"/applycolor.sh

    # Asynchronous background post-processing (KDE / Qt kdeglobals sync)
    max_width_desired="$(hyprctl monitors -j | jq '([.[].width] | min)' | xargs)"
    max_height_desired="$(hyprctl monitors -j | jq '([.[].height] | min)' | xargs)"
    post_process "$max_width_desired" "$max_height_desired" "$imgpath"
```

#### `--noswitch` Entry Point Invocation Pattern
**Source:** [vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L371-L375)
```bash
    --noswitch)
        noswitch_flag="1"
        imgpath=$(jq -r '.background.wallpaperPath' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "")
        shift
        ;;
```

---

### 6. Repository Guard Contract `guard-paths.tsv` (config, file-I/O)

**Role:** Data contract excluding dynamic theme files from repository tracking and symlinking.  
**Data Flow:** Parsed by `arch/dots-hyprland.sh` (`run_verify`) and assert test harnesses during strict invariant checks.  
**Analog:** [guard-paths.tsv](file:///home/pera/github_repo/.dotfiles/guard-paths.tsv#L13-L21)  

#### Tab-Separated Guard Contract Pattern
**Source:** [guard-paths.tsv](file:///home/pera/github_repo/.dotfiles/guard-paths.tsv#L13-L21)
```tsv
# Columns (tab-separated):
# path	category	generator	reason
$XDG_CONFIG_HOME/kdeglobals	generated_theme	kde-material-you-colors	Active wallpaper churn (Q7)
$XDG_CONFIG_HOME/Kvantum	vendor_theme	dots-hyprland	Upstream directory sync
$XDG_CONFIG_HOME/gtk-3.0/gtk.css	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/gtk-4.0/gtk.css	generated_theme	matugen	Root-owned theme symlink (Q8)
$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/hypr/hyprland/colors.lua	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/hypr/hyprlock/colors.conf	generated_theme	matugen	Matugen template output
$XDG_CONFIG_HOME/kde-material-you-colors	generated_theme	kde-material-you-colors	Upstream directory sync
```

---

## Shared Patterns

### 1. Hyprland Endianness Gradient Translation (`rgba(RRGGBBAA)` vs `AARRGGBB`)
**Source:** Hyprland 0.56 IPC Engine & [RESEARCH.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/27-hyprland-quickshell-ii-accent-coordination/27-RESEARCH.md#L204-L216)  
**Mechanism:**
- In `colors.lua`, colors are specified as standard CSS-style RGBA: `rgba(46474777)` (`RGB=464747`, `Alpha=77`).
- When querying compositor runtime state via `hyprctl getoption general:col.active_border`, Hyprland returns gradient data in `AARRGGBB` hex format (e.g. `gradient data: 77464747 0deg`).
- Any test or tool verifying live compositor sync must transpose alpha to the front:
  ```bash
  lua_raw="46474777"
  rgb="${lua_raw:0:6}"
  alpha="${lua_raw:6:2}"
  expected_gradient="${alpha}${rgb}" # "77464747"
  ```

### 2. Dual-Stage Inotify & FileView Hot-Reload Reactivity (Zero Process Restart)
**Source:** [CONTEXT.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/27-hyprland-quickshell-ii-accent-coordination/27-CONTEXT.md#L40-L52) D-16, D-21  
**Mechanism:**
- Compositor tier: Hyprland 0.56 natively watches all Lua files evaluated via `require()` (`colors.lua`). Modifying `colors.lua` re-evaluates `col.active_border` live without compositor reload or restart.
- Shell tier: Quickshell ii utilizes QML `FileView` watching `colors.json`. Modifying `colors.json` triggers `onFileChanged` and updates `Appearance.m3colors` in memory in ~10ms.
- Coordinated reload requires ZERO process restarts (`pkill` or `hyprctl reload`), ensuring zero flickering, zero state loss, and zero tray resets.

### 3. High-Precision Mtime Reload Verification (Clock-Tick Invariant)
**Source:** [RESEARCH.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/27-hyprland-quickshell-ii-accent-coordination/27-RESEARCH.md#L260-L265) Pitfall 2  
**Mechanism:**
- File system modification timestamps (`stat -c %Y`) have 1-second granularity on some filesystems.
- When verifying that a reload script touched output files, tests must record pre-run mtimes, execute a brief `sleep 1` to guarantee a clock tick, invoke the reload command, and assert `AFTER_MTIME > BEFORE_MTIME`.

### 4. Headless-Aware Compositor IPC Fallback (CI Reliability)
**Source:** [CONTEXT.md](file:///home/pera/github_repo/.dotfiles/.planning/phases/27-hyprland-quickshell-ii-accent-coordination/27-CONTEXT.md#L72) D-30  
**Mechanism:**
- `hyprctl` requires an active Wayland display socket located via `$HYPRLAND_INSTANCE_SIGNATURE`.
- When running in headless environments, containerized builds, or SSH sessions, `hyprctl` will fail to connect.
- Test suites must check `[[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]` before executing `hyprctl` probes, falling back gracefully to static `colors.lua` syntax and schema validation without returning a false failure.

### 5. Two-Phase Git Porcelain Working Tree Immutability
**Source:** [scripts/phase26-qt-kde-material-you-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase26-qt-kde-material-you-assert.sh#L63-L77), [L321-L327](file:///home/pera/github_repo/.dotfiles/scripts/phase26-qt-kde-material-you-assert.sh#L321-L327)  
**Mechanism:**
- Snapshot git status before testing into temporary file (`$PORCELAIN_BEFORE`), filtering ephemeral caches (`.commandcode/`, `__pycache__/`).
- Snapshot git status after testing into `$PORCELAIN_AFTER`.
- Compare using `cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"`.
- Enforces that executing test drills (like `switchwall.sh --noswitch`) produces zero repository drift and satisfies data contract invariants.

---

## Anti-Patterns to Avoid

- **Overriding Window Borders in `custom/general.lua`:** Adding `col.active_border` or `col.inactive_border` to `stow/hypr/.config/hypr/custom/general.lua` overrides `colors.lua` and breaks wallpaper color coordination (violating D-04).
- **Calling `hyprctl reload` on Theme Changes:** Hyprland automatically evaluates `colors.lua` via inotify. Explicit `hyprctl reload` causes compositor reinitialization, window flashes, and cursor jumps (violating D-21).
- **Restarting Quickshell on Wallpaper Changes:** Restarting Quickshell (`pkill qs && qs -c ii`) drops system tray icons and closes active menus. Quickshell's `MaterialThemeLoader.qml` reloads colors in-memory via `FileView` (violating D-16).
- **Direct Hex Comparison Without Endianness Conversion:** Comparing `rgba(46474777)` directly to `77464747` without transposing alpha causes false assertion failures.
- **Checking File Mtimes Without Clock Tick Delay:** Running `switchwall.sh` within the same filesystem second as the pre-check can cause false `mtime unchanged` assertion failures.
- **Committing Generated State to Git:** Modifying or adding generated files under `$XDG_STATE_HOME` to git tracking violates repository boundaries and causes dirty porcelain checks.

---

## No Analog Found

*None.* All files to be created, modified, or verified in Phase 27 have direct, high-fidelity analogs in the existing repository codebase:
- `scripts/phase27-accent-coordination-assert.sh`: Direct 1:1 structural descendant of `scripts/phase26-qt-kde-material-you-assert.sh` and `scripts/phase25-gtk-material-you-assert.sh`.
- `stow/hypr/.config/hypr/custom/general.lua`: Existing repository configuration maintaining overlay purity.
- `guard-paths.tsv`: Existing repository data contract with established tab-separated schema.
- Upstream Matugen templates, Quickshell services, and `switchwall.sh`: Fully inspectable, operational components in the workspace.

---

## Metadata

**Analog search scope:**
- `scripts/phase26-qt-kde-material-you-assert.sh`
- `scripts/phase25-gtk-material-you-assert.sh`
- `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`
- `scripts/phase21-ii-bar-config-capture-assert.sh`
- `stow/hypr/.config/hypr/custom/general.lua`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/general.lua`
- `vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua`
- `~/.config/hypr/hyprland/colors.lua`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh`
- `capture/ii/.config/illogical-impulse/config.json`
- `guard-paths.tsv`
- `arch/dots-hyprland.sh`

**Files scanned:** 15  
**Pattern extraction date:** 2026-09-17  
