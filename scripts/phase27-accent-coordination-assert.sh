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
# Section 2: Hyprland Window Borders & Compositor Token Match (SHELL-01, D-01..D-03, D-08, D-30) (stub)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Hyprland Window Borders & Compositor Token Match (stub) ---"
fi

# ===========================================================================
# Section 3: Quickshell ii Token Schema & Appearance Integrity (SHELL-02, D-13..D-15, D-31) (stub)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Quickshell ii Token Schema & Appearance Integrity (stub) ---"
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
