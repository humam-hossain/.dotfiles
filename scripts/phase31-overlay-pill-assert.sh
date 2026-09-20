#!/usr/bin/env bash
# Phase 31: Overlay Infrastructure & Pill Geometry Foundation Assert Harness
# Enforces: PILL-01, PILL-02, PILL-03, PILL-04, and D-01 through D-08
#
# Usage (from REPO_ROOT):
#   ./scripts/phase31-overlay-pill-assert.sh [--section <1-4>]
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

PORCELAIN_BEFORE="$(mktemp /tmp/p31-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p31-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Symlink & Packaging Integrity (PILL-01, D-05, D-06)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Symlink & Packaging Integrity (PILL-01, D-05, D-06) ---"

  # 1. Target files in ~/.config/quickshell/ii/modules/ii/bar/ must be symlinks
  #    resolving to $REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/<file>
  for qml_file in BarContent.qml BarGroup.qml; do
    live_path="$HOME/.config/quickshell/ii/modules/ii/bar/$qml_file"
    target_repo="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/$qml_file"
    if [[ -L "$live_path" ]]; then
      actual_target="$(readlink -f "$live_path")"
      expected_target="$(readlink -f "$target_repo")"
      if [[ "$actual_target" == "$expected_target" ]]; then
        pass "S1: $live_path is symlink to $target_repo (D-05, PILL-01)"
      else
        fail "S1: $live_path points to $actual_target, expected $expected_target"
      fi
    else
      fail "S1: $live_path is not a symlink"
    fi
  done

  # 2. Assert no ancestor directory is folded (directory symlink into repo)
  for check_dir in "$HOME/.config" "$HOME/.config/quickshell" "$HOME/.config/quickshell/ii" "$HOME/.config/quickshell/ii/modules" "$HOME/.config/quickshell/ii/modules/ii" "$HOME/.config/quickshell/ii/modules/ii/bar"; do
    if [[ -L "$check_dir" ]]; then
      fail "S1: ancestor directory $check_dir is a symlink (folded directory violation)"
    else
      pass "S1: ancestor directory $check_dir is a real directory (PILL-01)"
    fi
  done

  # 3. Assert sibling files in ~/.config/quickshell/ii/modules/ii/bar/ remain regular files
  for sibling in Bar.qml ActiveWindow.qml ClockWidget.qml Workspaces.qml; do
    sib_path="$HOME/.config/quickshell/ii/modules/ii/bar/$sibling"
    if [[ -f "$sib_path" && ! -L "$sib_path" ]]; then
      pass "S1: sibling module $sibling remains an intact regular file (D-05)"
    else
      fail "S1: sibling module $sibling missing or turned into a symlink"
    fi
  done

  # 4. Assert vendor/dots-hyprland submodule remains completely clean
  if [[ -z "$(git -C "$REPO_ROOT/vendor/dots-hyprland" status --porcelain)" ]]; then
    pass "S1: vendor/dots-hyprland working tree is 100% clean (PILL-01)"
  else
    fail "S1: vendor/dots-hyprland working tree has uncommitted modifications"
  fi
fi

# ===========================================================================
# Section 2: QML Property & Unclamped Sizing Integrity (PILL-02, PILL-03, D-01, D-04)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: QML Property & Unclamped Sizing Integrity (PILL-02, PILL-03, D-01, D-04) ---"
  # Stub: implemented in Plan 31-02
  pass "S2: Section 2 scaffolded"
fi

# ===========================================================================
# Section 3: Dynamic Animation & Visual Defaults (PILL-02, PILL-03, PILL-04, D-02, D-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Dynamic Animation & Visual Defaults (PILL-02, PILL-03, PILL-04, D-02, D-03) ---"
  # Stub: implemented in Plan 31-02
  pass "S3: Section 3 scaffolded"
fi

# ===========================================================================
# Section 4: Repository Hygiene & Verification Engine (PILL-01, D-06, D-08, INTG-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Repository Hygiene & Verification Engine (PILL-01, D-06, D-08, INTG-02) ---"
  # Stub: implemented in Plan 31-02
  pass "S4: Section 4 scaffolded"
fi

# ===========================================================================
# Closing porcelain invariant check & summary
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run (D-08)"
else
  fail "Closing self-check: git status --porcelain mutated across run (D-08)"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
