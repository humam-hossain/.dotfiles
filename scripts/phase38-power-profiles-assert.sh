#!/usr/bin/env bash
# ===========================================================================
# Phase 38: Power Profiles Daemon System Integration Assert Harness
# Enforces: POWER-01, POWER-02, POWER-03, D-01 through D-08
#
# Usage (from REPO_ROOT):
#   ./scripts/phase38-power-profiles-assert.sh [--section <1-5>] [-s <1-5>] [--syntax]
#
# Exit 0 if all hard asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
cleanup() {
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  return 0
}
trap cleanup EXIT

RUN_SECTION=0
SYNTAX_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-5>] [--syntax]"
      echo "  -s, --section <1-5>  Execute only the specified section"
      echo "  -c, --syntax         Execute static AST and syntax checks only"
      echo "  -h, --help           Show this help message"
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

PORCELAIN_BEFORE="$(mktemp /tmp/p38-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p38-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# Helper to run a headless Quickshell QML snippet
run_qs_test() {
  local qml_content="$1"
  local runtime_dir="${2:-}"
  local timeout_sec="${3:-4.5}"

  local runner_file
  runner_file="$(mktemp "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/p38_runner_XXXXXX.qml")"
  TMP_FILES+=("$runner_file")

  printf '%s\n' "$qml_content" > "$runner_file"

  local out=""
  if [[ -n "$runtime_dir" ]]; then
    out="$(XDG_RUNTIME_DIR="$runtime_dir" timeout "${timeout_sec}s" quickshell -p "$runner_file" 2>&1 || true)"
  else
    out="$(timeout "${timeout_sec}s" quickshell -p "$runner_file" 2>&1 || true)"
  fi

  rm -f "$runner_file" 2>/dev/null || true
  printf '%s\n' "$out"
}

# ===========================================================================
# Section 1: Package Manifest & Sorting
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Package Manifest & Sorting ---"

  if pacman -Q power-profiles-daemon >/dev/null 2>&1; then
    pass "S1: Package power-profiles-daemon is installed via pacman"
  else
    fail "S1: Package power-profiles-daemon is NOT installed"
  fi

  PKG_FILE="$REPO_ROOT/arch/pkglist-native.txt"
  if [[ -f "$PKG_FILE" ]]; then
    if grep -qx "power-profiles-daemon" "$PKG_FILE"; then
      pass "S1: power-profiles-daemon is present in arch/pkglist-native.txt"
    else
      fail "S1: power-profiles-daemon is missing from arch/pkglist-native.txt"
    fi

    if LC_ALL=C sort -c <(grep -v '^#' "$PKG_FILE") 2>/dev/null; then
      pass "S1: arch/pkglist-native.txt non-comment lines are strictly sorted (LC_ALL=C)"
    else
      fail "S1: arch/pkglist-native.txt non-comment lines are NOT sorted"
    fi
  else
    fail "S1: arch/pkglist-native.txt not found at $PKG_FILE"
  fi
fi

# ===========================================================================
# Section 2: Systemd Service & D-Bus Interface
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Systemd Service & D-Bus Interface ---"

  if systemctl is-active --quiet power-profiles-daemon.service; then
    pass "S2: power-profiles-daemon.service is active"
  else
    fail "S2: power-profiles-daemon.service is NOT active"
  fi

  if systemctl is-enabled --quiet power-profiles-daemon.service; then
    pass "S2: power-profiles-daemon.service is enabled"
  else
    fail "S2: power-profiles-daemon.service is NOT enabled"
  fi

  if busctl status net.hadess.PowerProfiles >/dev/null 2>&1; then
    pass "S2: net.hadess.PowerProfiles is responding on system D-Bus"
  else
    fail "S2: net.hadess.PowerProfiles is NOT responding on system D-Bus"
  fi

  if powerprofilesctl list >/dev/null 2>&1; then
    pass "S2: powerprofilesctl list executed successfully"
  else
    fail "S2: powerprofilesctl list failed"
  fi
fi

# ===========================================================================
# Section 3: Upstream Parity & Zero Local QML Overrides
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Upstream Parity & Zero Local QML Overrides ---"

  for override in \
    "restow/quickshell/.config/quickshell/ii/modules/common/models/quickToggles/PowerProfilesToggle.qml" \
    "restow/quickshell/.config/quickshell/ii/modules/ii/sidebarRight/quickToggles/androidStyle/AndroidPowerProfileToggle.qml"; do
    if [[ -e "$REPO_ROOT/$override" ]]; then
      fail "S3: Unauthorized local override found at $override (violates D-01)"
    else
      pass "S3: Zero local override confirmed for $override"
    fi
  done

  UPSTREAM_TOGGLE="$REPO_ROOT/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/models/quickToggles/PowerProfilesToggle.qml"
  if [[ -f "$UPSTREAM_TOGGLE" ]]; then
    if grep -q "import Quickshell.Services.UPower" "$UPSTREAM_TOGGLE"; then
      pass "S3: Upstream PowerProfilesToggle.qml imports Quickshell.Services.UPower"
    else
      fail "S3: Upstream PowerProfilesToggle.qml missing import Quickshell.Services.UPower"
    fi

    if grep -q "PowerProfile.PowerSaver" "$UPSTREAM_TOGGLE" && \
       grep -q "PowerProfile.Balanced" "$UPSTREAM_TOGGLE" && \
       grep -q "PowerProfile.Performance" "$UPSTREAM_TOGGLE"; then
      pass "S3: Upstream PowerProfilesToggle.qml defines 3-state profile cycle"
    else
      fail "S3: Upstream PowerProfilesToggle.qml does not define all 3 power profiles"
    fi
  else
    fail "S3: Upstream PowerProfilesToggle.qml not found at $UPSTREAM_TOGGLE"
  fi
fi

# ===========================================================================
# Section 4: Bootstrap Static Analysis & Idempotency
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Bootstrap Static Analysis & Idempotency ---"

  BOOTSTRAP_FILE="$REPO_ROOT/bootstrap.sh"
  if [[ -f "$BOOTSTRAP_FILE" ]]; then
    if grep -A 40 "step_packages()" "$BOOTSTRAP_FILE" | grep -q "pacman -Q power-profiles-daemon"; then
      pass "S4: bootstrap.sh contains idempotent pacman -Q power-profiles-daemon check in step_packages"
    else
      fail "S4: bootstrap.sh missing pacman -Q power-profiles-daemon in step_packages"
    fi

    if grep -A 40 "step_packages()" "$BOOTSTRAP_FILE" | grep -q "systemctl is-active --quiet power-profiles-daemon.service"; then
      pass "S4: bootstrap.sh contains idempotent systemctl is-active check before service activation"
    else
      fail "S4: bootstrap.sh missing systemctl is-active check in step_packages"
    fi

    DRY_RUN_OUT="$("$BOOTSTRAP_FILE" --dry-run 2>&1)"
    if echo "$DRY_RUN_OUT" | grep -q "power-profiles-daemon"; then
      pass "S4: bootstrap.sh --dry-run reports power-profiles-daemon checking"
    else
      fail "S4: bootstrap.sh --dry-run did not report power-profiles-daemon"
    fi
  else
    fail "S4: bootstrap.sh not found at $BOOTSTRAP_FILE"
  fi
fi

# ===========================================================================
# Section 5: Headless Quickshell UPower Integration & Repository Integrity
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Headless Quickshell UPower Integration & Repository Integrity ---"

  if [[ "$SYNTAX_ONLY" -eq 0 ]]; then
    QS_SNIPPET='import QtQuick
import Quickshell
import Quickshell.Services.UPower

Scope {
    Component.onCompleted: {
        console.log("UPower PowerProfiles available:", PowerProfiles !== undefined);
        console.log("Active profile:", PowerProfiles.profile);
        console.log("Has performance profile:", PowerProfiles.hasPerformanceProfile);
        Qt.quit();
    }
}'

    QS_OUT="$(run_qs_test "$QS_SNIPPET" "" 4.5)"
    if [[ "$QS_OUT" == *"UPower PowerProfiles available: true"* ]]; then
      pass "S5: Headless Quickshell successfully instantiated PowerProfiles from Quickshell.Services.UPower"
    else
      fail "S5: Headless Quickshell failed to resolve PowerProfiles from Quickshell.Services.UPower: $QS_OUT"
    fi

    STRICT_OUT="$(./arch/dots-hyprland.sh verify --strict 2>&1)" || {
      fail "S5: arch/dots-hyprland.sh verify --strict exited with non-zero status"
    }
    if [[ "$STRICT_OUT" == *"FAIL=0 FINDINGS=0"* ]]; then
      pass "S5: arch/dots-hyprland.sh verify --strict passed with zero findings"
    else
      fail "S5: arch/dots-hyprland.sh verify --strict reported findings or failures"
    fi
  else
    info "S5: Syntax-only mode enabled — skipping live Quickshell and verify --strict runs"
  fi
fi

# ===========================================================================
# Summary & Porcelain Check
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
DIFF_OUT="$(diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true)"
if [[ -n "$DIFF_OUT" ]]; then
  fail "Working tree porcelain drift detected during test execution:"
  printf '%s\n' "$DIFF_OUT" >&2
else
  pass "Working tree porcelain is clean (no drift)"
fi

echo "=========================================="
echo "Phase 38 Test Results: FAIL=$FAIL FINDINGS=$FINDINGS"
echo "=========================================="

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
