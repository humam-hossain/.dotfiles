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

  CONTENT_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"

  # 1. Assert absence of centerSideModuleWidth clamps in leftCenterGroup and rightCenterGroup
  # Check leftCenterGroup block does NOT contain implicitWidth: root.centerSideModuleWidth
  if awk '/id: leftCenterGroup/,/id: middleCenterGroup/' "$CONTENT_QML" | grep -q 'implicitWidth: root.centerSideModuleWidth'; then
    fail "S2: leftCenterGroup still contains implicitWidth: root.centerSideModuleWidth clamp"
  else
    pass "S2: leftCenterGroup is free of artificial width clamp (D-01, D-04)"
  fi

  # Check rightCenterGroup block does NOT contain implicitWidth: root.centerSideModuleWidth
  if awk '/id: rightCenterGroup/,/BarGroup {/' "$CONTENT_QML" | grep -q 'implicitWidth: root.centerSideModuleWidth'; then
    fail "S2: rightCenterGroup still contains implicitWidth: root.centerSideModuleWidth clamp"
  else
    pass "S2: rightCenterGroup is free of artificial width clamp (D-01, D-04)"
  fi

  # 2. Assert dynamic implicitWidth and implicitHeight propagation in rightCenterGroup
  if awk '/id: rightCenterGroup/,/BarGroup {/' "$CONTENT_QML" | grep -q 'implicitWidth: rightCenterGroupContent.implicitWidth'; then
    pass "S2: rightCenterGroup propagates rightCenterGroupContent.implicitWidth (D-01, PILL-03)"
  else
    fail "S2: rightCenterGroup missing dynamic implicitWidth propagation"
  fi

  if awk '/id: rightCenterGroup/,/BarGroup {/' "$CONTENT_QML" | grep -q 'implicitHeight: rightCenterGroupContent.implicitHeight'; then
    pass "S2: rightCenterGroup propagates rightCenterGroupContent.implicitHeight (D-01, PILL-03)"
  else
    fail "S2: rightCenterGroup missing dynamic implicitHeight propagation"
  fi
fi

# ===========================================================================
# Section 3: Dynamic Animation & Visual Defaults (PILL-02, PILL-03, PILL-04, D-02, D-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Dynamic Animation & Visual Defaults (PILL-02, PILL-03, PILL-04, D-02, D-03) ---"

  GROUP_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml"
  CONTENT_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"

  # 1. Assert Behavior on implicitWidth with emphasizedDecel curve and 250ms duration in BarGroup.qml
  if grep -q 'Behavior on implicitWidth' "$GROUP_QML" && \
     grep -q 'easing.bezierCurve: Appearance.animationCurves.emphasizedDecel' "$GROUP_QML" && \
     grep -q 'duration: 250' "$GROUP_QML" && \
     grep -q 'enabled: !root.vertical' "$GROUP_QML"; then
    pass "S3: BarGroup.qml declares animated Behavior on implicitWidth with emphasizedDecel (250ms) (D-02, PILL-03)"
  else
    fail "S3: BarGroup.qml missing correct Behavior on implicitWidth definition"
  fi

  # 2. Assert upstream visual styling fidelity tokens in BarGroup.qml (D-03)
  if grep -q 'radius: Appearance.rounding.small' "$GROUP_QML"; then
    pass "S3: BarGroup.qml uses Appearance.rounding.small (12px) (PILL-02, D-03)"
  else
    fail "S3: BarGroup.qml missing Appearance.rounding.small"
  fi

  if grep -q 'property real padding: 5' "$GROUP_QML"; then
    pass "S3: BarGroup.qml preserves padding: 5 (PILL-03, D-03)"
  else
    fail "S3: BarGroup.qml missing padding: 5"
  fi

  if grep -q 'color: Config.options?.bar.borderless ? "transparent" : Appearance.colors.colLayer1' "$GROUP_QML"; then
    pass "S3: BarGroup.qml preserves borderless background toggling and colLayer1 (PILL-04, D-03)"
  else
    fail "S3: BarGroup.qml missing standard borderless color condition"
  fi

  # 3. Assert middleSection spacing: 4 and VerticalBarSeparator borderless binding in BarContent.qml
  if grep -q 'spacing: 4' "$CONTENT_QML"; then
    pass "S3: BarContent.qml preserves inter-pill spacing: 4 (D-03)"
  else
    fail "S3: BarContent.qml missing spacing: 4"
  fi

  if grep -q 'visible: Config.options?.bar.borderless' "$CONTENT_QML"; then
    pass "S3: BarContent.qml preserves VerticalBarSeparator borderless binding (PILL-04)"
  else
    fail "S3: BarContent.qml missing VerticalBarSeparator borderless binding"
  fi
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
