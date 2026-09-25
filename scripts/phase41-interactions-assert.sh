#!/usr/bin/env bash
# ===========================================================================
# Phase 41: Milestone v0.8 Integration & Verification Engine
# Enforces: INTG-01, INTG-02, INTG-03, POWER-01..03, MEDIA-01..02,
#           NOTIF-01..02, NAV-01..02, OTP-01..02, CLOCK-01, VOL-01..02,
#           T-41-01, T-41-02, T-41-03, T-41-04
#
# Usage (from REPO_ROOT):
#   ./scripts/phase41-interactions-assert.sh [OPTIONS]
#
# Options:
#   -s, --section <1-6>    Execute only the specified section (1-6)
#   -q, --quick,
#       --standalone       Run standalone sections only (skip sub-harnesses)
#   -c, --syntax           Execute static AST and syntax checks only
#   -l, --live-notify,
#       --live             Trigger live desktop notification test
#   -h, --help             Show this help message
#
# Exit 0 if all hard asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root (ASVS V4, T-41-01)
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }
soft() { printf '[SOFT] %s\n' "$1"; }

TMP_FILES=()
INITIAL_PROFILE=""

cleanup_power() {
  if [[ -n "$INITIAL_PROFILE" ]]; then
    local current
    current="$(powerprofilesctl get 2>/dev/null || echo "")"
    if [[ -n "$current" && "$current" != "$INITIAL_PROFILE" ]]; then
      info "Restoring initial power profile '$INITIAL_PROFILE' (was '$current')..."
      powerprofilesctl set "$INITIAL_PROFILE" 2>/dev/null || true
    fi
  fi
}

cleanup() {
  cleanup_power
  if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    rm -f "${TMP_FILES[@]}" 2>/dev/null || true
  fi
  return 0
}
trap cleanup EXIT INT TERM

RUN_SECTION=0
QUICK_MODE=0
SYNTAX_ONLY=0
LIVE_NOTIFY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-6]$ ]]; then
        echo "Error: --section requires an integer from 1 to 6" >&2
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
    --live-notify|--live|-l)
      LIVE_NOTIFY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -s, --section <1-6>    Execute only the specified section (1-6)"
      echo "  -q, --quick,           Run standalone sections only (skip sub-harnesses)"
      echo "      --standalone"
      echo "  -c, --syntax           Execute static AST and syntax checks only"
      echo "  -l, --live-notify,     Trigger live desktop notification test"
      echo "      --live"
      echo "  -h, --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

info "=== Milestone v0.8 Integration & Verification Engine ==="
info "Working directory: $REPO_ROOT"
info "Flags: section=$RUN_SECTION quick=$QUICK_MODE syntax_only=$SYNTAX_ONLY live_notify=$LIVE_NOTIFY"

# ===========================================================================
# Prerequisite Binaries Gate (D-05)
# ===========================================================================
info "--- Prerequisite Binaries Gate ---"
REQUIRED_BINS=(bash jq node lua luac powerprofilesctl wpctl qs git)
for bin in "${REQUIRED_BINS[@]}"; do
  if command -v "$bin" >/dev/null 2>&1; then
    pass "Prereq: Command '$bin' is available on PATH"
  else
    fail "Prereq: Required command '$bin' is MISSING on PATH (D-05)"
  fi
done

# ===========================================================================
# Working-Tree Porcelain Baseline Snapshot (D-09, T-41-04)
# ===========================================================================
porcelain_snapshot_raw() { git status --porcelain --ignored || true; }
porcelain_snapshot() { porcelain_snapshot_raw | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true; }

PORCELAIN_BEFORE="$(mktemp /tmp/p41-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p41-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Syntax Validation Branch (--syntax)
# ===========================================================================
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Syntax Verification Mode ---"
  if bash -n "$0"; then
    pass "Syntax: Harness bash -n validation passed"
  else
    fail "Syntax: Harness bash -n validation failed"
  fi

  CONFIG_JSON="$REPO_ROOT/capture/ii/.config/illogical-impulse/config.json"
  if [[ -f "$CONFIG_JSON" ]]; then
    if jq . "$CONFIG_JSON" >/dev/null 2>&1; then
      pass "Syntax: config.json is valid JSON"
    else
      fail "Syntax: config.json failed JSON parse"
    fi
  else
    fail "Syntax: config.json not found at $CONFIG_JSON"
  fi

  info "=========================================="
  info "Syntax Summary: FAIL=$FAIL FINDINGS=$FINDINGS"
  info "=========================================="
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Restow Symlink Isolation & Tree Topology (INTG-01, D-02, D-09)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Restow Symlink Isolation & Tree Topology ---"

  # 1. Submodule Cleanliness Check
  sub_status="$(git -C vendor/dots-hyprland status --porcelain 2>/dev/null || true)"
  if [[ -z "$sub_status" ]]; then
    pass "S1: vendor/dots-hyprland submodule has 0 uncommitted changes"
  else
    fail "S1: vendor/dots-hyprland submodule has uncommitted changes:\n$sub_status"
    finding "S1: Submodule vendor/dots-hyprland is dirty"
  fi

  # 2. Overlay Leaf Symlink Assertions
  OVERLAY_FILES=(
    "restow/quickshell/.config/quickshell/ii/GlobalStates.qml"
    "restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
    "restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml"
    "restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml"
    "restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml"
    "restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml"
    "restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml"
    "restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml"
    "restow/quickshell/.config/quickshell/ii/modules/common/Config.qml"
    "restow/quickshell/.config/quickshell/ii/services/Audio.qml"
    "restow/quickshell/.config/quickshell/ii/modules/ii/sidebarRight/QuickSliders.qml"
  )

  for rel in "${OVERLAY_FILES[@]}"; do
    src="$REPO_ROOT/$rel"
    live="$HOME/${rel#restow/quickshell/}"

    if [[ -f "$src" ]]; then
      pass "S1: Repo overlay source exists: $rel"
    else
      fail "S1: Repo overlay source MISSING: $rel"
      continue
    fi

    if [[ -L "$live" ]]; then
      pass "S1: Live target is symbolic link: $live"
    else
      fail "S1: Live target is NOT a symlink: $live"
      finding "S1: Leaf symlink missing or folded: $live"
      continue
    fi

    real_src="$(readlink -f "$src")"
    real_live="$(readlink -f "$live")"
    if [[ "$real_src" == "$real_live" ]]; then
      pass "S1: Symlink target matches canonical repo source for $rel"
    else
      fail "S1: Symlink target mismatch: $real_live != $real_src"
      finding "S1: Symlink target mismatch for $live"
    fi
  done

  # 3. Directory Folding Guard
  TREE_DIRS=(
    "$HOME/.config/quickshell/ii"
    "$HOME/.config/quickshell/ii/modules"
    "$HOME/.config/quickshell/ii/modules/ii"
    "$HOME/.config/quickshell/ii/modules/ii/bar"
    "$HOME/.config/quickshell/ii/modules/ii/mediaControls"
    "$HOME/.config/quickshell/ii/modules/ii/sidebarRight"
    "$HOME/.config/quickshell/ii/modules/ii/verticalBar"
    "$HOME/.config/quickshell/ii/modules/common"
    "$HOME/.config/quickshell/ii/modules/common/functions"
    "$HOME/.config/quickshell/ii/modules/common/widgets"
    "$HOME/.config/quickshell/ii/services"
  )

  for d in "${TREE_DIRS[@]}"; do
    if [[ -d "$d" && ! -L "$d" ]]; then
      pass "S1: Physical directory verified (no folding): $d"
    else
      fail "S1: Directory folding or missing directory detected: $d"
      finding "S1: Directory $d is a symlink or missing"
    fi
  done

  if [[ "$RUN_SECTION" -eq 1 ]]; then
    info "=========================================="
    info "Phase 41 Section 1 Summary: FAIL=$FAIL FINDINGS=$FINDINGS"
    info "=========================================="
    exit "$FAIL"
  fi
fi

# ===========================================================================
# Section 2: Power Profiles Daemon & Safe Rollback (POWER-01..03, D-02, D-07)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Power Profiles Daemon & Safe Rollback ---"

  # 1. Pacman package verification (POWER-01)
  if pacman -Q power-profiles-daemon >/dev/null 2>&1; then
    pass "S2: Pacman package power-profiles-daemon is installed"
  else
    fail "S2: Pacman package power-profiles-daemon is NOT installed (POWER-01)"
    finding "S2: Missing power-profiles-daemon package"
  fi

  # 2. Package manifest verification (POWER-03)
  PKG_FILE="$REPO_ROOT/arch/pkglist-native.txt"
  if [[ -f "$PKG_FILE" ]]; then
    if grep -qx "power-profiles-daemon" "$PKG_FILE"; then
      pass "S2: power-profiles-daemon is present in arch/pkglist-native.txt"
    else
      fail "S2: power-profiles-daemon MISSING from arch/pkglist-native.txt (POWER-03)"
      finding "S2: Unmanifested package power-profiles-daemon"
    fi
  else
    fail "S2: arch/pkglist-native.txt not found at $PKG_FILE"
  fi

  # 3. Upstream toggle parity check (zero local overrides) (POWER-02)
  for override in \
    "restow/quickshell/.config/quickshell/ii/modules/common/models/quickToggles/PowerProfilesToggle.qml" \
    "restow/quickshell/.config/quickshell/ii/modules/ii/sidebarRight/quickToggles/androidStyle/AndroidPowerProfileToggle.qml"; do
    if [[ -e "$REPO_ROOT/$override" ]]; then
      fail "S2: Unauthorized local override found at $override (POWER-02)"
      finding "S2: Local toggle override detected: $override"
    else
      pass "S2: Zero local override confirmed for $override"
    fi
  done

  # 4. Live D-Bus state & atomic cycle test with safe rollback (D-04, D-07)
  if [[ "$SYNTAX_ONLY" -eq 0 ]]; then
    if systemctl is-active --quiet power-profiles-daemon.service 2>/dev/null; then
      pass "S2: power-profiles-daemon.service is active"
      INITIAL_PROFILE="$(powerprofilesctl get 2>/dev/null || echo "")"
      if [[ -n "$INITIAL_PROFILE" ]]; then
        pass "S2: Captured initial system power profile '$INITIAL_PROFILE'"
        for p in power-saver balanced performance; do
          if powerprofilesctl list 2>/dev/null | grep -qE "^[* ]*${p}:"; then
            if powerprofilesctl set "$p" 2>/dev/null; then
              cur="$(powerprofilesctl get 2>/dev/null || echo "")"
              if [[ "$cur" == "$p" ]]; then
                pass "S2: Successfully cycled to power profile '$p'"
              else
                fail "S2: Profile switch to '$p' failed (active is '$cur')"
              fi
            else
              fail "S2: powerprofilesctl set '$p' exited non-zero"
            fi
          else
            info "S2: Power profile '$p' not reported by hardware platform driver"
          fi
        done

        # Explicit restore
        if powerprofilesctl set "$INITIAL_PROFILE" 2>/dev/null; then
          restored="$(powerprofilesctl get 2>/dev/null || echo "")"
          if [[ "$restored" == "$INITIAL_PROFILE" ]]; then
            pass "S2: Successfully restored initial power profile '$INITIAL_PROFILE' (atomic rollback)"
          else
            fail "S2: Rollback verification failed: current '$restored' != initial '$INITIAL_PROFILE'"
          fi
        else
          fail "S2: powerprofilesctl set '$INITIAL_PROFILE' failed during rollback"
        fi
      else
        soft "S2: Could not read power profile via powerprofilesctl get; soft-skipping profile cycle"
      fi
    else
      soft "S2: power-profiles-daemon.service inactive; soft-skipping live transition test (D-04)"
    fi
  else
    info "S2: Syntax-only mode — skipping live D-Bus profile cycling"
  fi

  if [[ "$RUN_SECTION" -eq 2 ]]; then
    info "=========================================="
    info "Phase 41 Section 2 Summary: FAIL=$FAIL FINDINGS=$FINDINGS"
    info "=========================================="
    exit "$FAIL"
  fi
fi

# ===========================================================================
# Section 3: Dynamic Media Popup Positioning & Clamping (MEDIA-01..02, D-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Dynamic Media Popup Positioning & Clamping ---"

  MC_FILE="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml"
  GS_FILE="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/GlobalStates.qml"

  # 1. Static AST Analysis of MediaControls.qml (MEDIA-01, MEDIA-02)
  if [[ -f "$MC_FILE" ]]; then
    for token in "GlobalStates.mediaPillScreen" "GlobalStates.mediaPillCenterX" "Math.round" "hyprlandGapsOut" "Math.max" "Math.min"; do
      if grep -q "$token" "$MC_FILE"; then
        pass "S3: MediaControls.qml contains AST token: $token"
      else
        fail "S3: MediaControls.qml MISSING required AST token: $token"
        finding "S3: Missing AST token $token in MediaControls.qml"
      fi
    done
  else
    fail "S3: MediaControls.qml not found at $MC_FILE"
  fi

  # 2. Static AST Analysis of GlobalStates.qml
  if [[ -f "$GS_FILE" ]]; then
    for prop in "mediaPillCenterX" "mediaPillCenterY" "mediaPillScreen"; do
      if grep -q "$prop" "$GS_FILE"; then
        pass "S3: GlobalStates.qml defines property: $prop"
      else
        fail "S3: GlobalStates.qml MISSING required property: $prop"
        finding "S3: Missing property $prop in GlobalStates.qml"
      fi
    done
  else
    fail "S3: GlobalStates.qml not found at $GS_FILE"
  fi

  # 3. Headless JavaScript Clamping Simulation
  SIM_RESULT="$(node -e '
function calculatePopupX(pillCenterX, pillWidth, popupWidth, screenX, screenWidth, gaps) {
  if (pillCenterX <= 0) {
    return Math.round(screenX + (screenWidth - popupWidth) / 2);
  }
  const targetX = pillCenterX - (popupWidth / 2);
  const minX = screenX + gaps;
  const maxX = screenX + screenWidth - popupWidth - gaps;
  const clampedX = (maxX < minX) ? minX : Math.max(minX, Math.min(targetX, maxX));
  return Math.round(clampedX);
}

const s1 = calculatePopupX(960, 120, 400, 0, 1920, 10);
const s2 = calculatePopupX(1900, 100, 400, 0, 1920, 10);
const s3 = calculatePopupX(-1, 0, 400, 0, 1920, 10);

const ok = (s1 === 760 && s2 === 1510 && s3 === 760);
console.log(JSON.stringify({ s1, s2, s3, ok }));
process.exit(ok ? 0 : 1);
' 2>/dev/null || echo '{"ok":false}')"

  if echo "$SIM_RESULT" | jq -e '.ok' >/dev/null 2>&1; then
    pass "S3: Headless JS coordinate clamping simulation passed all 3 scenarios (centered: 760, clamped: 1510, fallback: 760)"
  else
    fail "S3: Headless JS coordinate clamping simulation FAILED: $SIM_RESULT"
    finding "S3: Media popup clamping math simulation mismatch"
  fi

  # 4. Two-Tier Live Desktop Probing (D-04, D-06)
  if [[ "$SYNTAX_ONLY" -eq 0 ]]; then
    if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
      if hyprctl monitors -j >/dev/null 2>&1; then
        pass "S3: Live Wayland monitor query via hyprctl succeeded"
      else
        soft "S3: Live hyprctl monitors query failed; soft-skipping"
      fi
    else
      soft "S3: WAYLAND_DISPLAY not set or hyprctl missing; soft-skipping Wayland check (D-04)"
    fi

    if qs -c ii list 2>/dev/null | grep -q "quickshell/ii/shell.qml"; then
      pass "S3: Active Quickshell shell.qml confirmed running under -c ii profile"
    else
      soft "S3: Quickshell shell.qml not currently running under -c ii profile; soft-skipping (D-06)"
    fi
  else
    info "S3: Syntax-only mode — skipping live desktop probes"
  fi

  if [[ "$RUN_SECTION" -eq 3 ]]; then
    info "=========================================="
    info "Phase 41 Section 3 Summary: FAIL=$FAIL FINDINGS=$FINDINGS"
    info "=========================================="
    exit "$FAIL"
  fi
fi


