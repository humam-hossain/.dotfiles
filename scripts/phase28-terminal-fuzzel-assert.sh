#!/usr/bin/env bash
# Phase 28 Terminal & Fuzzel Launcher Dynamic Palette assert harness (TERM-01, TERM-02, INTG-01, INTG-02).
# One script, one section per requirement criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase28-terminal-fuzzel-assert.sh [--section <1-5>]
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

PORCELAIN_BEFORE="$(mktemp /tmp/p28-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p28-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Template & Config Readiness (INTG-01, TERM-01, TERM-02, D-01, D-03, D-12, D-16)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Template & Config Readiness (INTG-01, TERM-01, TERM-02, D-01, D-03, D-12, D-16) ---"

  # 1. Matugen Fuzzel template exists and contains M3 tokens
  FUZZEL_TPL="$REPO_ROOT/vendor/dots-hyprland/dots/.config/matugen/templates/fuzzel/fuzzel_theme.ini"
  [[ -f "$FUZZEL_TPL" ]] || FUZZEL_TPL="$XDG_CONFIG_HOME/matugen/templates/fuzzel/fuzzel_theme.ini"
  if [[ -f "$FUZZEL_TPL" ]] && \
     grep -q 'background={{colors.background.default.hex_stripped}}ff' "$FUZZEL_TPL" && \
     grep -q 'text={{colors.on_background.default.hex_stripped}}ff' "$FUZZEL_TPL" && \
     grep -q 'border={{colors.surface_variant.default.hex_stripped}}dd' "$FUZZEL_TPL"; then
    pass "S1: Matugen Fuzzel template declares M3 background, text, and border tokens (D-12, D-13)"
  else
    fail "S1: Matugen Fuzzel template missing or lacks required token bindings ($FUZZEL_TPL)"
  fi

  # 2. Matugen config.toml contains [templates.fuzzel] mapping
  MATUGEN_CFG="$XDG_CONFIG_HOME/matugen/config.toml"
  if [[ -f "$MATUGEN_CFG" ]] && \
     grep -q '^\[templates\.fuzzel\]' "$MATUGEN_CFG" && \
     grep -E -q 'output_path = ["'\'']~/\.config/fuzzel/fuzzel_theme\.ini["'\'']' "$MATUGEN_CFG"; then
    pass "S1: ~/.config/matugen/config.toml registers [templates.fuzzel] output path (D-12)"
  else
    fail "S1: ~/.config/matugen/config.toml missing [templates.fuzzel] configuration"
  fi

  # 3. stow/kitty kitty.conf include statement and cold-start seed target
  REPO_KITTY_CONF="$REPO_ROOT/stow/kitty/.config/kitty/kitty.conf"
  SEED_KITTY_THEME="$XDG_STATE_HOME/quickshell/user/generated/terminal/kitty-theme.conf"
  if [[ -f "$REPO_KITTY_CONF" ]] && grep -q '^include ~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf' "$REPO_KITTY_CONF"; then
    pass "S1: stow/kitty kitty.conf includes generated kitty-theme.conf (D-01)"
  else
    fail "S1: stow/kitty kitty.conf missing required theme include statement"
  fi
  if [[ -f "$SEED_KITTY_THEME" ]]; then
    pass "S1: cold-start seed kitty-theme.conf exists on disk (D-07)"
  else
    fail "S1: cold-start seed kitty-theme.conf missing ($SEED_KITTY_THEME)"
  fi

  # 4. stow/fuzzel fuzzel.ini include statement & defaults
  REPO_FUZZEL_INI="$REPO_ROOT/stow/fuzzel/.config/fuzzel/fuzzel.ini"
  if [[ -f "$REPO_FUZZEL_INI" ]] && \
     grep -q '^include="~/.config/fuzzel/fuzzel_theme.ini"' "$REPO_FUZZEL_INI" && \
     grep -q '^terminal=kitty -1' "$REPO_FUZZEL_INI" && \
     grep -q '^radius=17' "$REPO_FUZZEL_INI" && \
     grep -q '^prompt=">>  "' "$REPO_FUZZEL_INI" && \
     grep -q '^exit-immediately-if-empty=yes' "$REPO_FUZZEL_INI"; then
    pass "S1: stow/fuzzel fuzzel.ini declares theme include, terminal=kitty -1, and squircle radius 17 (D-14..D-16)"
  else
    fail "S1: stow/fuzzel fuzzel.ini missing required options ($REPO_FUZZEL_INI)"
  fi

  # 5. guard-paths.tsv contract for fuzzel_theme.ini
  GUARD_TSV="$REPO_ROOT/guard-paths.tsv"
  if grep -qF '$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini' "$GUARD_TSV"; then
    pass "S1: guard-paths.tsv guards \$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini (D-16)"
  else
    fail "S1: guard-paths.tsv missing fuzzel_theme.ini guard entry"
  fi
  ROW="$(grep -F '$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini' "$GUARD_TSV" || true)"
  IFS=$'\t' read -r c1 c2 c3 c4 <<< "$ROW"
  if [[ "$c1" == '$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini' && "$c2" == "generated_theme" && "$c3" == "matugen" && -n "$c4" && ! "$c1" =~ [[:space:]] && ! "$c2" =~ [[:space:]] && ! "$c3" =~ [[:space:]] ]]; then
    pass "S1: fuzzel_theme.ini guard entry strictly tab-separated as generated_theme (INTG-01, D-16)"
  else
    fail "S1: fuzzel_theme.ini guard entry not properly tab-separated (INTG-01, D-16)"
  fi

  # 6. Claimed helper kittens in stow/kitty
  if [[ -f "$REPO_ROOT/stow/kitty/.config/kitty/search.py" && -f "$REPO_ROOT/stow/kitty/.config/kitty/scroll_mark.py" ]]; then
    pass "S1: Helper kittens search.py and scroll_mark.py present in stow/kitty package (D-03)"
  else
    fail "S1: Helper kittens missing from stow/kitty package (D-03)"
  fi
fi

# ===========================================================================
# Section 2: Fuzzel Theme Syntax & Configuration Integrity (TERM-01, D-13, D-14)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Fuzzel Theme Syntax & Configuration Integrity (TERM-01, D-13, D-14) ---"
  # Stub: implemented in Plan 28-02
fi

# ===========================================================================
# Section 3: Terminal Theme Syntax & Configuration Integrity (TERM-02, D-01, D-02, D-08..D-11)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Terminal Theme Syntax & Configuration Integrity (TERM-02, D-01, D-02, D-08..D-11) ---"
  # Stub: implemented in Plan 28-02
fi

# ===========================================================================
# Section 4: Live Reload Drill & Process Signaling (TERM-01, TERM-02, D-05, D-18)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Live Reload Drill & Process Signaling (TERM-01, TERM-02, D-05, D-18) ---"
  # Stub: implemented in Plan 28-03
fi

# ===========================================================================
# Section 5: Strict Verification Engine & Zero Git Drift (INTG-01, INTG-02, D-17, D-19)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Strict Verification Engine & Zero Git Drift (INTG-01, INTG-02, D-17, D-19) ---"
  # Stub: implemented in Plan 28-03
fi

# ===========================================================================
# Closing porcelain invariant check & summary
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run (D-19)"
else
  fail "Closing self-check: git status --porcelain mutated across run (D-19)"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
