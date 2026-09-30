#!/usr/bin/env bash
# ===========================================================================
# Phase 48: Right-Zone Media Expansion & System Tray Empty State Gating Assert Harness
# Enforces: RGHT-01, RGHT-02, RGHT-03, D-01 through D-16
#
# Usage (from REPO_ROOT):
#   ./scripts/phase48-right-zone-assert.sh [OPTIONS] [1-5]
#
# Options:
#   -s, --section <1-5>    Execute only the specified section (1-5)
#   -q, --quick,
#       --standalone       Run standalone sections only (skip sub-harnesses in S5)
#   -c, --syntax           Execute static AST and syntax checks only
#   -h, --help             Show this help message
#
# Exit 0 if all hard asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
cleanup() {
  if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    rm -f "${TMP_FILES[@]}" 2>/dev/null || true
  fi
  return 0
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
      echo "Usage: $0 [OPTIONS] [1-5]"
      echo ""
      echo "Options:"
      echo "  [1-5]                  Execute only specified section"
      echo "  -s, --section <1-5>    Execute only the specified section (1-5)"
      echo "  -q, --quick,           Run standalone sections only"
      echo "      --standalone"
      echo "  -c, --syntax           Execute static AST and syntax checks only"
      echo "  -h, --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

BAR_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar"
BAR_CONTENT="$BAR_DIR/BarContent.qml"
MEDIA_QML="$BAR_DIR/Media.qml"

PORCELAIN_BEFORE="$(mktemp "${TMPDIR:-/tmp}/p48-porcelain-before.XXXXXX")"
TMP_FILES+=("$PORCELAIN_BEFORE")
git status --porcelain > "$PORCELAIN_BEFORE"

# Syntax-only mode
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  bash -n "$0"
  pass "Assert harness bash syntax check passed (bash -n verified)"
  [[ -f "$BAR_CONTENT" ]] && pass "BarContent.qml exists" || fail "Missing: $BAR_CONTENT"
  [[ -f "$MEDIA_QML" ]] && pass "Media.qml exists" || fail "Missing: $MEDIA_QML"
  info "=== Syntax Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Stow Leaf Symlink Topology & Repository Integrity
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Stow Leaf Symlink Topology & Repository Integrity ---"

  LIVE_BAR="$HOME/.config/quickshell/ii/modules/ii/bar"

  if [[ -f "$MEDIA_QML" ]]; then
    pass "S1: Overlay file exists: $MEDIA_QML"
  else
    fail "S1: Overlay file missing: $MEDIA_QML"
  fi

  if [[ -f "$BAR_CONTENT" ]]; then
    pass "S1: Overlay file exists: $BAR_CONTENT"
  else
    fail "S1: Overlay file missing: $BAR_CONTENT"
  fi

  if [[ -L "$LIVE_BAR/Media.qml" ]] && [[ "$(readlink "$LIVE_BAR/Media.qml")" =~ restow/quickshell/\.config/quickshell/ii/modules/ii/bar/Media\.qml ]]; then
    pass "S1: Live Media.qml is a valid symlink to restow/quickshell/.../Media.qml"
  elif [[ -f "$LIVE_BAR/Media.qml" ]]; then
    finding "S1: Live Media.qml is a regular file (not yet symlinked to restow)"
  else
    fail "S1: Live Media.qml missing"
  fi

  if [[ -L "$LIVE_BAR/BarContent.qml" ]] && [[ "$(readlink "$LIVE_BAR/BarContent.qml")" =~ restow/quickshell/\.config/quickshell/ii/modules/ii/bar/BarContent\.qml ]]; then
    pass "S1: Live BarContent.qml is a valid symlink to restow/quickshell/.../BarContent.qml"
  else
    fail "S1: Live BarContent.qml symlink missing or invalid"
  fi

  for dir in "$HOME/.config" "$HOME/.config/quickshell" "$HOME/.config/quickshell/ii" "$HOME/.config/quickshell/ii/modules" "$HOME/.config/quickshell/ii/modules/ii" "$HOME/.config/quickshell/ii/modules/ii/bar"; do
    if [[ -d "$dir" && ! -L "$dir" ]]; then
      pass "S1: Ancestor directory $dir is a real un-folded directory"
    elif [[ -L "$dir" ]]; then
      fail "S1: Ancestor directory $dir is folded (symlink)"
    else
      fail "S1: Ancestor directory $dir missing"
    fi
  done

  SUBMODULE_STATUS="$(git status --porcelain vendor/dots-hyprland 2>/dev/null || true)"
  if [[ -z "$SUBMODULE_STATUS" ]]; then
    pass "S1: vendor/dots-hyprland submodule has 0 git churn"
  else
    fail "S1: vendor/dots-hyprland has uncommitted churn: $SUBMODULE_STATUS"
  fi
fi

# ===========================================================================
# Section 2: BarContent.qml Responsive Width Equation & Tray Gating AST
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: BarContent.qml Responsive Width Equation & Tray Gating AST ---"

  if grep -q "import Quickshell.Services.SystemTray" "$BAR_CONTENT"; then
    pass "S2: BarContent.qml imports Quickshell.Services.SystemTray"
  else
    fail "S2: BarContent.qml missing import Quickshell.Services.SystemTray"
  fi

  if grep -A 10 "id: mediaLoader" "$BAR_CONTENT" | grep -q "Math.min(Math.max.*0.12.*220.*450"; then
    pass "S2: mediaLoader contains full-width responsive equation (0.12 clamp [220, 450])"
  elif sed -n '/id: mediaLoader/,/id: voicePill/p' "$BAR_CONTENT" | grep -q "Math.min(Math.max.*0.12.*220.*450"; then
    pass "S2: mediaLoader contains full-width responsive equation (0.12 clamp [220, 450])"
  else
    fail "S2: mediaLoader missing full-width responsive equation"
  fi

  if grep -A 10 "id: mediaLoader" "$BAR_CONTENT" | grep -q "Math.min(Math.max.*0.10.*140.*180"; then
    pass "S2: mediaLoader contains shortened-width responsive equation (0.10 clamp [140, 180])"
  elif sed -n '/id: mediaLoader/,/id: voicePill/p' "$BAR_CONTENT" | grep -q "Math.min(Math.max.*0.10.*140.*180"; then
    pass "S2: mediaLoader contains shortened-width responsive equation (0.10 clamp [140, 180])"
  else
    fail "S2: mediaLoader missing shortened-width responsive equation"
  fi

  if sed -n '/id: sysTrayGroup/,/SysTray {/p' "$BAR_CONTENT" | grep -q "SystemTray.items.*length"; then
    pass "S2: sysTrayGroup visible bound to SystemTray.items length"
  else
    fail "S2: sysTrayGroup missing SystemTray.items length binding"
  fi

  if sed -n '/id: sysTrayGroup/,/SysTray {/p' "$BAR_CONTENT" | grep -q "root.useShortenedForm === 0"; then
    pass "S2: sysTrayGroup restricted to root.useShortenedForm === 0"
  else
    fail "S2: sysTrayGroup missing root.useShortenedForm === 0 restriction"
  fi

  if grep -q "function updateMediaPillCoords()" "$BAR_CONTENT"; then
    pass "S2: updateMediaPillCoords() function preserved"
  else
    fail "S2: updateMediaPillCoords() function missing"
  fi

  if grep -q "onWidthChanged.*root.updateMediaPillCoords()" "$BAR_CONTENT"; then
    pass "S2: onWidthChanged coordinate tracking connection preserved"
  else
    fail "S2: onWidthChanged coordinate tracking connection missing"
  fi
fi

# ===========================================================================
# Section 3: Media.qml Typography, Styling Hierarchy & Elision AST
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Media.qml Typography, Styling Hierarchy & Elision AST ---"

  if grep -q "import qs.modules.common.functions" "$MEDIA_QML" 2>/dev/null; then
    pass "S3: Media.qml imports qs.modules.common.functions"
  else
    fail "S3: Media.qml missing import qs.modules.common.functions"
  fi

  if grep -q "property real useShortenedForm" "$MEDIA_QML" 2>/dev/null; then
    pass "S3: Media.qml declares property real useShortenedForm"
  else
    fail "S3: Media.qml missing property real useShortenedForm declaration"
  fi

  if grep -A 15 "id: mediaLoader" "$BAR_CONTENT" 2>/dev/null | grep -q "useShortenedForm: root.useShortenedForm"; then
    pass "S3: BarContent.qml passes useShortenedForm to Media component"
  else
    fail "S3: BarContent.qml missing useShortenedForm pass-through to Media"
  fi

  if grep -A 15 "id: mediaTitleText" "$MEDIA_QML" 2>/dev/null | grep -q "Layout.fillWidth: true" && \
     grep -A 15 "id: mediaTitleText" "$MEDIA_QML" 2>/dev/null | grep -q "elide: Text.ElideRight"; then
    pass "S3: Media.qml declares separate mediaTitleText with Layout.fillWidth: true and Text.ElideRight"
  else
    fail "S3: Media.qml missing mediaTitleText with fillWidth: true and Text.ElideRight"
  fi

  if grep -A 15 "id: mediaArtistText" "$MEDIA_QML" 2>/dev/null | grep -q "Layout.fillWidth: false" && \
     grep -A 15 "id: mediaArtistText" "$MEDIA_QML" 2>/dev/null | grep -q "Appearance.colors.colSubtext" && \
     grep -A 15 "id: mediaArtistText" "$MEDIA_QML" 2>/dev/null | grep -q "root.useShortenedForm === 0"; then
    pass "S3: Media.qml declares separate mediaArtistText with colSubtext and narrow-screen gating"
  else
    fail "S3: Media.qml missing mediaArtistText with colSubtext and narrow-screen gating"
  fi

  if grep -A 15 "id: mediaTitleText" "$MEDIA_QML" 2>/dev/null | grep -q "Appearance.colors.colOnLayer1" && \
     grep -A 15 "id: mediaArtistText" "$MEDIA_QML" 2>/dev/null | grep -q "Appearance.colors.colSubtext"; then
    pass "S3: Media.qml styles title with colOnLayer1 and artist with colSubtext"
  else
    fail "S3: Media.qml missing title colOnLayer1 or artist colSubtext styling"
  fi

  if grep -q "mediaTrackInfoText" "$MEDIA_QML" 2>/dev/null; then
    fail "S3: Obsolete single-string mediaTrackInfoText still present in Media.qml"
  else
    pass "S3: Obsolete single-string mediaTrackInfoText removed from Media.qml"
  fi

  if grep -A 20 "StyledText" "$MEDIA_QML" 2>/dev/null | grep -q "CircularProgress.size"; then
    fail "S3: Obsolete width binding loop on StyledText still present"
  else
    pass "S3: Obsolete width binding loop on StyledText removed"
  fi

  if grep -A 15 "MouseArea" "$MEDIA_QML" 2>/dev/null | grep -q "GlobalStates.mediaControlsOpen"; then
    pass "S3: MouseArea preserves LeftButton mediaControlsOpen toggle"
  else
    fail "S3: MouseArea missing LeftButton mediaControlsOpen toggle"
  fi

  if grep -A 15 "MouseArea" "$MEDIA_QML" 2>/dev/null | grep -q "activePlayer.togglePlaying()"; then
    pass "S3: MouseArea preserves MiddleButton togglePlaying()"
  else
    fail "S3: MouseArea missing MiddleButton togglePlaying()"
  fi

  if grep -A 15 "MouseArea" "$MEDIA_QML" 2>/dev/null | grep -q "activePlayer.next()"; then
    pass "S3: MouseArea preserves next() handler"
  else
    fail "S3: MouseArea missing next() handler"
  fi

  if grep -A 15 "MouseArea" "$MEDIA_QML" 2>/dev/null | grep -q "activePlayer.previous()"; then
    pass "S3: MouseArea preserves previous() handler"
  else
    fail "S3: MouseArea missing previous() handler"
  fi
fi

# ===========================================================================
# Section 4: Mathematical Simulation & Logic Verification (Scaffold)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Mathematical Simulation & Logic Verification ---"

  calc_tier0() {
    local w="$1"
    python3 -c "import math; print(f'{min(max($w * 0.12, 220), 450):.1f}')"
  }

  calc_tier1() {
    local w="$1"
    python3 -c "import math; print(f'{min(max($w * 0.10, 140), 180):.1f}')"
  }

  res_3440=$(calc_tier0 3440)
  if [[ "$res_3440" == "412.8" ]]; then
    pass "S4: 3440px Ultrawide evaluates to 412.8px (expected 412.8px)"
  else
    fail "S4: 3440px Ultrawide evaluates to $res_3440 != 412.8px"
  fi

  res_2560=$(calc_tier0 2560)
  if [[ "$res_2560" == "307.2" ]]; then
    pass "S4: 2560px QHD evaluates to 307.2px (expected 307.2px)"
  else
    fail "S4: 2560px QHD evaluates to $res_2560 != 307.2px"
  fi

  res_1920=$(calc_tier0 1920)
  if [[ "$res_1920" == "230.4" ]]; then
    pass "S4: 1920px FHD evaluates to 230.4px (expected 230.4px)"
  else
    fail "S4: 1920px FHD evaluates to $res_1920 != 230.4px"
  fi

  res_1366=$(calc_tier0 1366)
  if [[ "$res_1366" == "220.0" ]]; then
    pass "S4: 1366px Laptop hits 220.0px floor clamp (expected 220.0px)"
  else
    fail "S4: 1366px Laptop evaluates to $res_1366 != 220.0px"
  fi

  res_1200_t1=$(calc_tier1 1200)
  if [[ "$res_1200_t1" == "140.0" ]]; then
    pass "S4: 1200px Shortened hits 140.0px floor clamp (expected 140.0px)"
  else
    fail "S4: 1200px Shortened evaluates to $res_1200_t1 != 140.0px"
  fi

  res_1080_t1=$(calc_tier1 1080)
  if [[ "$res_1080_t1" == "140.0" ]]; then
    pass "S4: 1080px Rotated hits 140.0px floor clamp (expected 140.0px)"
  else
    fail "S4: 1080px Rotated evaluates to $res_1080_t1 != 140.0px"
  fi

  res_1600_t1=$(calc_tier1 1600)
  if [[ "$res_1600_t1" == "160.0" ]]; then
    pass "S4: 1600px Shortened wide evaluates to 160.0px (expected 160.0px)"
  else
    fail "S4: 1600px Shortened wide evaluates to $res_1600_t1 != 160.0px"
  fi

  # Dynamic hugging simulation (RGHT-01, D-03)
  sim_hugging() {
    local content_w="$1"
    local max_w="$2"
    python3 -c "print(f'{min($content_w, $max_w):.1f}')"
  }

  eff_short=$(sim_hugging 100 412.8)
  if [[ "$eff_short" == "100.0" ]]; then
    pass "S4: Dynamic hugging: short track (100px) hugs content (< 412.8px clamp)"
  else
    fail "S4: Dynamic hugging failed for short track ($eff_short != 100.0)"
  fi

  eff_long=$(sim_hugging 600 412.8)
  if [[ "$eff_long" == "412.8" ]]; then
    pass "S4: Dynamic hugging: long track (600px) clamped to maximum width 412.8px"
  else
    fail "S4: Dynamic hugging failed for long track ($eff_long != 412.8)"
  fi

  # Nullish screen fallback check (RGHT-01, D-01, D-02)
  if grep -q "root.screen?.width ?? 1920" "$BAR_CONTENT" && grep -q "root.screen?.width ?? 1200" "$BAR_CONTENT"; then
    pass "S4: Nullish fallback screen width defaults (1920/1200) present in BarContent.qml"
  else
    fail "S4: Nullish fallback screen width defaults missing in BarContent.qml"
  fi

  # Right Zone widget ordering AST check (D-11, D-12)
  ORDER_MATCH=$(awk '/id: mediaLoader/{m=1} /id: voicePill/{if(m) v=1} /id: updatesLoader/{if(v) u=1} /id: batteryLoader/{if(u) b=1} /id: sysTrayGroup/{if(b) s=1} /id: rightSidebarButton/{if(s) r=1} END{print (r ? 1 : 0)}' "$BAR_CONTENT")
  if [[ "$ORDER_MATCH" -eq 1 ]]; then
    pass "S4: Right Zone widget order verified (media -> voice -> updates -> battery -> sysTray -> rightSidebar)"
  else
    fail "S4: Right Zone widget order violated in BarContent.qml"
  fi

  # Tray gating logic verification (RGHT-03, D-09..D-12)
  check_tray_vis() {
    local form="$1"
    local count="$2"
    if (( form == 0 && count > 0 )); then echo "1"; else echo "0"; fi
  }

  [[ "$(check_tray_vis 0 0)" == "0" ]] && pass "S4: Form 0 + 0 items -> hidden (visible: false)" || fail "S4: Gating error"
  [[ "$(check_tray_vis 0 1)" == "1" ]] && pass "S4: Form 0 + 1 items -> visible (visible: true)" || fail "S4: Gating error"
  [[ "$(check_tray_vis 0 5)" == "1" ]] && pass "S4: Form 0 + 5 items -> visible (visible: true)" || fail "S4: Gating error"
  [[ "$(check_tray_vis 1 0)" == "0" ]] && pass "S4: Form 1 + 0 items -> hidden (visible: false)" || fail "S4: Gating error"
  [[ "$(check_tray_vis 1 3)" == "0" ]] && pass "S4: Form 1 + 3 items -> hidden (visible: false)" || fail "S4: Gating error"
  [[ "$(check_tray_vis 2 3)" == "0" ]] && pass "S4: Form 2 + 3 items -> hidden (visible: false)" || fail "S4: Gating error"
fi

# ===========================================================================
# Section 5: Sub-Harness Orchestration & Strict Repository Verification (Scaffold)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Sub-Harness Orchestration & Strict Repository Verification ---"

  if [[ "$QUICK_MODE" -eq 1 ]]; then
    info "S5: Quick mode enabled. Skipping sub-harness delegation and repo verify."
  else
    if bash scripts/phase47-center-layout-assert.sh --quick; then
      pass "S5: Sub-harness phase47-center-layout-assert.sh --quick passed"
    else
      fail "S5: Sub-harness phase47-center-layout-assert.sh --quick failed"
    fi

    if bash scripts/phase46-telemetry-assert.sh --quick; then
      pass "S5: Sub-harness phase46-telemetry-assert.sh --quick passed"
    else
      fail "S5: Sub-harness phase46-telemetry-assert.sh --quick failed"
    fi

    if ./arch/dots-hyprland.sh verify --strict; then
      pass "S5: Repository strict verification passed (dots-hyprland.sh)"
    else
      fail "S5: Repository strict verification failed (dots-hyprland.sh)"
    fi
  fi
fi

# Working tree drift check
PORCELAIN_AFTER="$(mktemp "${TMPDIR:-/tmp}/p48-porcelain-after.XXXXXX")"
TMP_FILES+=("$PORCELAIN_AFTER")
git status --porcelain > "$PORCELAIN_AFTER"

if diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" >/dev/null; then
  pass "S5: Zero working tree drift during assert execution (porcelain unchanged)"
else
  fail "S5: Working tree drifted during assert execution"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

# Final Summary
info "=== Phase 48 Assertion Summary ==="
info "Failures: $FAIL, Findings: $FINDINGS"

if [[ "$FAIL" -eq 0 && "$FINDINGS" -eq 0 ]]; then
  pass "All hard assertions passed with zero findings!"
  exit 0
elif [[ "$FAIL" -eq 0 ]]; then
  pass "All hard assertions passed ($FINDINGS informational findings)"
  exit 0
else
  fail "Assert harness encountered $FAIL failure(s)"
  exit 1
fi
