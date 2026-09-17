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

PORCELAIN_BEFORE="$(mktemp /tmp/p27-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p27-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Template & Config Readiness (INTG-01, D-01..D-04, D-08)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Template & Config Readiness (INTG-01, D-01..D-04, D-08) ---"

  # 1. Matugen hyprland colors template readiness
  MATUGEN_HYPR_TPL="$REPO_ROOT/vendor/dots-hyprland/dots/.config/matugen/templates/hyprland/colors.lua"
  [[ -f "$MATUGEN_HYPR_TPL" ]] || MATUGEN_HYPR_TPL="$XDG_CONFIG_HOME/matugen/templates/hyprland/colors.lua"

  if [[ -f "$MATUGEN_HYPR_TPL" ]] && \
     grep -q 'active_border.*outline_variant.*77' "$MATUGEN_HYPR_TPL" && \
     grep -q 'inactive_border.*surface_container_low.*33' "$MATUGEN_HYPR_TPL" && \
     grep -q 'background_color.*surface\.dark.*FF' "$MATUGEN_HYPR_TPL" && \
     grep -q 'border_color.*primary.*AA.*primary.*77' "$MATUGEN_HYPR_TPL"; then
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

# ===========================================================================
# Section 2: Hyprland Window Borders & Compositor Token Match (SHELL-01, D-01..D-03, D-05..D-12, D-30)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Hyprland Window Borders & Compositor Token Match (SHELL-01, D-01..D-03, D-05..D-12, D-30) ---"

  LIVE_COLORS_LUA="$XDG_CONFIG_HOME/hypr/hyprland/colors.lua"
  expected_active_gradient=""
  expected_inactive_gradient=""

  # 1. Parse active_border: rgba(46474777) -> RGB=464747, Alpha=77 -> Expected gradient hex: 77464747
  lua_active_raw="$(grep -oP '\bactive_border\s*=\s*"rgba\(\K[0-9a-fA-F]{8}' "$LIVE_COLORS_LUA" || true)"
  if [[ -n "$lua_active_raw" && ${#lua_active_raw} -eq 8 ]]; then
    lua_active_rgb="${lua_active_raw:0:6}"
    lua_active_alpha="${lua_active_raw:6:2}"
    expected_active_gradient="${lua_active_alpha}${lua_active_rgb}"
    pass "S2: Parsed active_border from colors.lua: rgba(${lua_active_raw}) -> expected gradient ${expected_active_gradient} (D-01)"
  else
    fail "S2: Failed to parse active_border from colors.lua ($LIVE_COLORS_LUA) (D-01)"
  fi

  # 2. Parse inactive_border: rgba(1b1c1c33) -> RGB=1b1c1c, Alpha=33 -> Expected gradient hex: 331b1c1c
  lua_inactive_raw="$(grep -oP '\binactive_border\s*=\s*"rgba\(\K[0-9a-fA-F]{8}' "$LIVE_COLORS_LUA" || true)"
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

  # 5. Upstream Hyprland decoration geometry, dimming, and snapping assertions (D-05..D-07, D-09..D-12)
  VENDOR_GENERAL="$REPO_ROOT/vendor/dots-hyprland/dots/.config/hypr/hyprland/general.lua"
  if [[ -f "$VENDOR_GENERAL" ]]; then
    if grep -qP 'rounding\s*=\s*18\b' "$VENDOR_GENERAL" && \
       grep -qP 'rounding_power\s*=\s*2\.5\b' "$VENDOR_GENERAL" && \
       grep -qP 'border_size\s*=\s*1\b' "$VENDOR_GENERAL" && \
       grep -qP 'dim_strength\s*=\s*0\.05\b' "$VENDOR_GENERAL" && \
       grep -qP 'dim_special\s*=\s*0\.2\b' "$VENDOR_GENERAL" && \
       grep -qP 'passes\s*=\s*3\b' "$VENDOR_GENERAL" && \
       grep -qP 'xray\s*=\s*true\b' "$VENDOR_GENERAL" && \
       grep -qP 'gaps_in\s*=\s*4\b' "$VENDOR_GENERAL" && \
       grep -qP 'gaps_out\s*=\s*5\b' "$VENDOR_GENERAL" && \
       grep -qP 'gaps_workspaces\s*=\s*50\b' "$VENDOR_GENERAL" && \
       grep -qP 'resize_on_border\s*=\s*true\b' "$VENDOR_GENERAL" && \
       grep -qP 'window_gap\s*=\s*4\b' "$VENDOR_GENERAL" && \
       grep -qP 'monitor_gap\s*=\s*5\b' "$VENDOR_GENERAL"; then
      pass "S2: Upstream Hyprland decoration geometry, dimming, and snapping defaults verified (D-05..D-07, D-09..D-12)"
    else
      fail "S2: Upstream Hyprland decoration geometry defaults missing or mismatch in $VENDOR_GENERAL"
    fi
  else
    fail "S2: Vendor general.lua missing ($VENDOR_GENERAL)"
  fi

  # 6. Live Compositor State Query (D-30)
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl &>/dev/null; then
    info "S2: Active Hyprland compositor detected (signature=$HYPRLAND_INSTANCE_SIGNATURE)"

    # Query active_border
    live_active_gradient="$(hyprctl -j getoption general:col.active_border 2>/dev/null | jq -r '.gradient // empty' | awk '{print $1}')"
    if [[ -n "$live_active_gradient" && -n "$expected_active_gradient" && "${expected_active_gradient,,}" == "${live_active_gradient,,}" ]]; then
      pass "S2: Live compositor active_border matches colors.lua ($live_active_gradient) (SHELL-01, D-01)"
    else
      fail "S2: Live compositor active_border mismatch: expected '${expected_active_gradient,,}', got '${live_active_gradient,,}'"
    fi

    # Query inactive_border
    live_inactive_gradient="$(hyprctl -j getoption general:col.inactive_border 2>/dev/null | jq -r '.gradient // empty' | awk '{print $1}')"
    if [[ -n "$live_inactive_gradient" && -n "$expected_inactive_gradient" && "${expected_inactive_gradient,,}" == "${live_inactive_gradient,,}" ]]; then
      pass "S2: Live compositor inactive_border matches colors.lua ($live_inactive_gradient) (SHELL-01, D-02)"
    else
      fail "S2: Live compositor inactive_border mismatch: expected '${expected_inactive_gradient,,}', got '${live_inactive_gradient,,}'"
    fi
  else
    info "S2: Headless CI or non-GUI environment (HYPRLAND_INSTANCE_SIGNATURE unset); skipping live compositor probe (D-30 fallback)"
  fi
fi

# ===========================================================================
# Section 3: Quickshell ii Token Schema & Appearance Integrity (SHELL-02, D-13..D-15, D-31)
# ===========================================================================
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
    transp="$(jq -r 'if .appearance.transparency.enable != null then .appearance.transparency.enable | tostring else "" end' "$CONFIG_JSON" 2>/dev/null || true)"
    if [[ "$transp" == "false" ]]; then
      pass "S3: Background transparency is disabled (opaque) (D-15)"
    else
      fail "S3: Background transparency expected 'false', got '$transp' (D-15)"
    fi

    # Warning thresholds (D-14)
    cpu_warn="$(jq -r '.bar.resources.cpuWarningThreshold // .resources.cpuWarningThreshold // empty' "$CONFIG_JSON" 2>/dev/null || true)"
    mem_warn="$(jq -r '.bar.resources.memoryWarningThreshold // .resources.memoryWarningThreshold // empty' "$CONFIG_JSON" 2>/dev/null || true)"
    swap_warn="$(jq -r '.bar.resources.swapWarningThreshold // .resources.swapWarningThreshold // empty' "$CONFIG_JSON" 2>/dev/null || true)"
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

# ===========================================================================
# Section 4: Live Coordinated Reload Probe (SHELL-03, D-21, D-22, D-24, D-28, D-32) (stub)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Live Coordinated Reload Probe (stub) ---"
fi

# ===========================================================================
# Section 5: Strict Verification Engine & Zero Git Drift (INTG-01, INTG-02, D-28, D-29) (stub)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Strict Verification Engine & Zero Git Drift (stub) ---"
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
