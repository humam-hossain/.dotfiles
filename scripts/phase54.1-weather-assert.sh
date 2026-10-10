#!/usr/bin/env bash
# ===========================================================================
# Phase 54.1: Top Status Bar Weather Component Polish Assert Harness
# Enforces: BAR-01, BAR-02, BAR-03, BAR-04, INTG-02, ASVS L1
# Decisions: D-54.1-01 through D-54.1-37
#
# Usage (from REPO_ROOT):
#   ./scripts/phase54.1-weather-assert.sh [1-5] [OPTIONS]
#
# Options:
#   -s, --section <1-5>    Execute only the specified section (1-5)
#   -q, --quick            Run fast static checks only (skips dots-hyprland.sh)
#       --standalone       Alias for --quick
#   -c, --syntax           Execute static bash syntax checks only
#   -h, --help             Show this help message
#
# Exit 0 if all hard asserts pass (FAIL=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if executed as root (ASVS L1 Root Privilege Prevention / T-54.1-01)
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Error: Do not run as root" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass()    { printf '[PASS] %s\n' "$1"; }
fail()    { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info()    { printf '[INFO] %s\n' "$1"; }

TMP_DIRS=()
cleanup() {
  local exit_code=$?
  if [[ ${#TMP_DIRS[@]} -gt 0 ]]; then
    for d in "${TMP_DIRS[@]}"; do
      rm -rf "$d" 2>/dev/null || true
    done
  fi
  return "$exit_code"
}
trap cleanup EXIT INT TERM

RUN_SECTION=0
QUICK_MODE=0
SYNTAX_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    1|2|3|4|5)
      RUN_SECTION="$1"
      shift
      ;;
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    --quick|--standalone|-q)
      QUICK_MODE=1
      shift
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [1-5] [OPTIONS]"
      echo ""
      echo "Sections:"
      echo "  1: Stow Leaf Symlink Topology & Packaging Integrity (BAR-01, INTG-02, D-54.1-34..37)"
      echo "  2: BarContent.qml Center Zone Integration & Non-Mutation Invariants (BAR-01, D-54.1-09..12)"
      echo "  3: WeatherBar Temperature Parsing & Multi-Tier Responsive Formatting (BAR-02, D-54.1-13..23, D-54.1-28)"
      echo "  4: Alert Precedence, Imminent Rain Badge & Breathing Pulse Logic (BAR-03, D-54.1-15..17, D-54.1-22, D-54.1-25..26, D-54.1-32)"
      echo "  5: Pure Hover Trigger, M3 Surface Highlight & Pointer Ergonomics (BAR-04, D-54.1-01..08, D-54.1-24, D-54.1-29, D-54.1-31, D-54.1-33)"
      echo ""
      echo "Options:"
      echo "  -s, --section <1-5>    Execute only the specified section (1-5)"
      echo "  -q, --quick            Run fast static checks only (skips dots-hyprland.sh)"
      echo "      --standalone       Alias for --quick"
      echo "  -c, --syntax           Execute static bash syntax checks only"
      echo "  -h, --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

WEATHERBAR_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml"
BARCONTENT_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
TARGET_DIR="$HOME/.config/quickshell/ii/modules/ii/bar/weather"

# Syntax-only mode
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  bash -n "$0"
  pass "Assert harness bash syntax check passed (bash -n verified)"
  info "=== Syntax Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Stow Leaf Symlink Topology & Packaging Integrity (BAR-01, INTG-02, D-54.1-34..37)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Stow Leaf Symlink Topology & Packaging Integrity ---"

  if [[ -s "$WEATHERBAR_SRC" ]]; then
    pass "S1: restow/quickshell/.../WeatherBar.qml exists and is non-empty"
  else
    fail "S1: Missing or empty source file: $WEATHERBAR_SRC"
  fi

  if [[ -L "$TARGET_DIR/WeatherBar.qml" ]]; then
    local_target="$(readlink -f "$TARGET_DIR/WeatherBar.qml" || true)"
    canonical_src="$(readlink -f "$WEATHERBAR_SRC" || true)"
    if [[ "$local_target" == "$canonical_src" ]]; then
      pass "S1: $TARGET_DIR/WeatherBar.qml is a valid symlink to restow overlay"
    else
      fail "S1: $TARGET_DIR/WeatherBar.qml points to $local_target, expected $canonical_src"
    fi
  elif [[ -f "$TARGET_DIR/WeatherBar.qml" ]]; then
    fail "S1: $TARGET_DIR/WeatherBar.qml exists as regular file, expected leaf symlink"
  else
    fail "S1: $TARGET_DIR/WeatherBar.qml is missing"
  fi

  if [[ -f "$TARGET_DIR/WeatherBar.qml.bak" && ! -L "$TARGET_DIR/WeatherBar.qml.bak" ]]; then
    pass "S1: Installer backup artifact $TARGET_DIR/WeatherBar.qml.bak preserved as regular file"
  else
    fail "S1: Missing or invalid installer backup artifact $TARGET_DIR/WeatherBar.qml.bak"
  fi

  # Assert all parent directories in ~/.config/quickshell/ii/modules/ii/bar/weather are real un-folded directories
  for check_dir in "$HOME/.config" "$HOME/.config/quickshell" "$HOME/.config/quickshell/ii" "$HOME/.config/quickshell/ii/modules" "$HOME/.config/quickshell/ii/modules/ii" "$HOME/.config/quickshell/ii/modules/ii/bar" "$TARGET_DIR"; do
    if [[ -d "$check_dir" && ! -L "$check_dir" ]]; then
      pass "S1: Directory $(basename "$check_dir") is an un-folded real directory"
    else
      fail "S1: Expected real directory (not symlink or missing): $check_dir"
    fi
  done

  # Assert git status vendor/dots-hyprland is empty
  vendor_churn="$(git status --porcelain vendor/dots-hyprland 2>/dev/null || true)"
  if [[ -z "$vendor_churn" ]]; then
    pass "S1: vendor/dots-hyprland has 0 working tree modifications (pristine vendor hygiene)"
  else
    fail "S1: Detected vendor/dots-hyprland git churn: $vendor_churn"
  fi

  if [[ "$QUICK_MODE" -eq 0 ]]; then
    info "S1: Executing dots-hyprland strict verification..."
    if ./arch/dots-hyprland.sh verify --strict >/dev/null 2>&1; then
      pass "S1: ./arch/dots-hyprland.sh verify --strict completed with FAIL=0 FINDINGS=0"
    else
      fail "S1: ./arch/dots-hyprland.sh verify --strict reported failures"
    fi
  else
    info "S1: Quick mode active: skipping dots-hyprland.sh verify --strict"
  fi
fi

# ===========================================================================
# Section 2: BarContent.qml Center Zone Integration & Non-Mutation Invariants (BAR-01, D-54.1-09..12)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: BarContent.qml Center Zone Integration & Non-Mutation ---"

  barcontent_churn="$(git status --porcelain "$BARCONTENT_SRC" 2>/dev/null || true)"
  if [[ -z "$barcontent_churn" ]]; then
    pass "S2: BarContent.qml is 100% UNTOUCHED (0 working tree modifications per D-54.1-10)"
  else
    fail "S2: BarContent.qml has been modified: $barcontent_churn"
  fi

  if [[ ! -f "$BARCONTENT_SRC" ]]; then
    fail "S2: Missing BarContent.qml file ($BARCONTENT_SRC)"
  else
    bc_content="$(cat "$BARCONTENT_SRC")"

    # a. Assert id: weatherGroup Loader exists in Center Zone
    if echo "$bc_content" | grep -q 'id:\s*weatherGroup'; then
      pass "S2: Loader with id: weatherGroup exists in BarContent.qml"
    else
      fail "S2: Missing id: weatherGroup Loader in BarContent.qml"
    fi

    # b. Assert anchors.left: middleCenterGroup.right and anchors.leftMargin: 4
    if echo "$bc_content" | grep -q 'anchors\.left:\s*middleCenterGroup\.right' && echo "$bc_content" | grep -q 'anchors\.leftMargin:\s*4'; then
      pass "S2: weatherGroup anchors to middleCenterGroup.right with 4px leftMargin (D-54.1-10)"
    else
      fail "S2: Missing middleCenterGroup.right anchor or 4px leftMargin in weatherGroup"
    fi

    # c. Assert sourceComponent: BarGroup { WeatherBar {} }
    if echo "$bc_content" | grep -A 10 'id:\s*weatherGroup' | grep -q 'WeatherBar'; then
      pass "S2: weatherGroup loads WeatherBar inside BarGroup component wrapper (D-54.1-09)"
    else
      fail "S2: weatherGroup does not load WeatherBar inside BarGroup"
    fi

    # d. Assert active: Config.options.bar.weather.enable
    if echo "$bc_content" | grep -B 2 -A 5 'id:\s*weatherGroup' | grep -q 'active:\s*Config\.options\.bar\.weather\.enable'; then
      pass "S2: weatherGroup active property bound to Config.options.bar.weather.enable"
    else
      fail "S2: Missing active: Config.options.bar.weather.enable binding"
    fi

    # e. Assert standard BarGroup background styling without custom highlights
    if grep -q 'WeatherBar' "$BARCONTENT_SRC" && ! grep -A 5 'WeatherBar' "$BARCONTENT_SRC" | grep -q 'hoverColor'; then
      pass "S2: Standard BarGroup background styling preserved without custom hover highlights (D-54.1-09)"
    else
      fail "S2: Detected unwanted custom hover styling around WeatherBar"
    fi
  fi
fi

# ===========================================================================
# Section 3: WeatherBar Temperature Parsing & Multi-Tier Responsive Formatting (Stub)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: WeatherBar Temperature Parsing & Multi-Tier Formatting ---"
  info "Section 3 will be tested in Plan 54.1-02"
fi

# ===========================================================================
# Section 4: Alert Precedence, Imminent Rain Badge & Breathing Pulse Logic (Stub)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Alert Precedence, Imminent Rain Badge & Breathing Pulse ---"
  info "Section 4 will be tested in Plan 54.1-02"
fi

# ===========================================================================
# Section 5: Pure Hover Trigger, M3 Surface Highlight & Pointer Ergonomics (Stub)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Pure Hover Trigger, M3 Surface Highlight & Pointer Ergonomics ---"
  info "Section 5 will be tested in Plan 54.1-03"
fi

info "=== Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
exit "$FAIL"
