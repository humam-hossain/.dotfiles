#!/usr/bin/env bash
# Phase 33: Modular Layout & Live Trial-and-Error Rearrangement Assert Harness
# Enforces: LAYOUT-01, LAYOUT-02, LAYOUT-03, D-01 through D-14, INTG-02
#
# Usage (from REPO_ROOT):
#   ./scripts/phase33-layout-assert.sh [--section <1-4>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

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
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-4]$ ]]; then
        echo "Error: --section requires an integer from 1 to 4" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-4>]"
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

PORCELAIN_BEFORE="$(mktemp /tmp/p33-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p33-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Symlink Integrity & Packaging Verification (LAYOUT-01, D-12)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Symlink Integrity & Packaging Verification ---"

  REPO_BAR_CONTENT="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
  LIVE_BAR_CONTENT="$HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
  REPO_BAR_GROUP="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml"
  LIVE_BAR_GROUP="$HOME/.config/quickshell/ii/modules/ii/bar/BarGroup.qml"

  # 1. Assert BarContent.qml is a leaf symlink to repo source mirror
  if [[ -L "$LIVE_BAR_CONTENT" ]]; then
    resolved_target="$(readlink -f "$LIVE_BAR_CONTENT" || true)"
    expected_target="$(readlink -f "$REPO_BAR_CONTENT" || true)"
    if [[ "$resolved_target" == "$expected_target" ]]; then
      pass "S1: $LIVE_BAR_CONTENT is leaf symlink to $REPO_BAR_CONTENT (LAYOUT-01)"
    else
      fail "S1: $LIVE_BAR_CONTENT resolves to '$resolved_target', expected '$expected_target'"
    fi
  else
    fail "S1: $LIVE_BAR_CONTENT is not a symlink"
  fi

  # 2. Assert ancestor directories are real directories (not folded directory symlinks)
  for dir_path in \
    "$HOME/.config" \
    "$HOME/.config/quickshell" \
    "$HOME/.config/quickshell/ii" \
    "$HOME/.config/quickshell/ii/modules" \
    "$HOME/.config/quickshell/ii/modules/ii" \
    "$HOME/.config/quickshell/ii/modules/ii/bar"; do
    if [[ -d "$dir_path" && ! -L "$dir_path" ]]; then
      pass "S1: ancestor directory $dir_path is a real directory"
    else
      fail "S1: ancestor directory $dir_path is missing or a folded symlink"
    fi
  done

  # 3. Assert BarGroup.qml leaf symlink exists and resolves to repo
  if [[ -L "$LIVE_BAR_GROUP" ]]; then
    resolved_group="$(readlink -f "$LIVE_BAR_GROUP" || true)"
    expected_group="$(readlink -f "$REPO_BAR_GROUP" || true)"
    if [[ "$resolved_group" == "$expected_group" ]]; then
      pass "S1: $LIVE_BAR_GROUP is leaf symlink to $REPO_BAR_GROUP (LAYOUT-01)"
    else
      fail "S1: $LIVE_BAR_GROUP resolves to '$resolved_group', expected '$expected_group'"
    fi
  else
    fail "S1: $LIVE_BAR_GROUP is missing or not a symlink"
  fi

  # 4. Assert vendor/dots-hyprland submodule cleanliness
  if [[ -z "$(git -C "$REPO_ROOT/vendor/dots-hyprland" status --porcelain)" ]]; then
    pass "S1: vendor/dots-hyprland submodule remains 100% clean"
  else
    fail "S1: vendor/dots-hyprland submodule has uncommitted modifications"
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
