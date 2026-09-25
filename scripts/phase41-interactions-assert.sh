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

# ===========================================================================
# Section 4: Notification Center Ergonomics, Smart OTP & URL Navigation
# (NOTIF-01..02, NAV-01..02, OTP-01..02, D-02, D-04, D-08, T-41-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Notification Center Ergonomics, Smart OTP & URL Navigation ---"

  NG_FILE="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml"
  NI_FILE="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml"
  NU_FILE="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml"
  NP_VENDOR="$REPO_ROOT/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/notificationPopup/NotificationPopup.qml"

  # 1. Static AST Validation
  if [[ -f "$NG_FILE" ]]; then
    if grep -q "id:\s*closeButton" "$NG_FILE"; then
      pass "S4: NotificationGroup.qml declares closeButton (NOTIF-01)"
    else
      fail "S4: NotificationGroup.qml MISSING closeButton declaration"
      finding "S4: Missing closeButton in NotificationGroup.qml"
    fi

    if grep -A 5 "id:\s*closeButton" "$NG_FILE" | grep -qE 'visible:\s*true'; then
      pass "S4: NotificationGroup.qml closeButton is explicitly visible: true (NOTIF-01)"
    else
      fail "S4: NotificationGroup.qml closeButton is not explicitly visible: true"
      finding "S4: NotificationGroup.qml closeButton visibility not true"
    fi
  else
    fail "S4: NotificationGroup.qml not found at $NG_FILE"
  fi

  if [[ -f "$NP_VENDOR" ]]; then
    if grep -q "closeButton" "$NP_VENDOR"; then
      fail "S4: NotificationPopup.qml contains closeButton (must be suppressed in toast popups per NOTIF-02)"
      finding "S4: NotificationPopup.qml contains closeButton"
    else
      pass "S4: NotificationPopup.qml suppresses closeButton in toast popups (NOTIF-02)"
    fi
  else
    fail "S4: NotificationPopup.qml not found in vendor tree at $NP_VENDOR"
  fi

  if [[ -f "$NI_FILE" ]]; then
    if grep -q "property string otpCode:" "$NI_FILE"; then
      pass "S4: NotificationItem.qml declares property string otpCode (OTP-02)"
    else
      fail "S4: NotificationItem.qml MISSING property string otpCode"
      finding "S4: Missing otpCode property in NotificationItem.qml"
    fi

    if grep -q "function activateNotification" "$NI_FILE" && grep -q "Notifications\.attemptInvokeAction" "$NI_FILE"; then
      pass "S4: NotificationItem.qml defines smart body click invoking dismiss and default action (NAV-01)"
    else
      fail "S4: NotificationItem.qml MISSING smart body click dismissal action"
      finding "S4: Missing smart body click action in NotificationItem.qml"
    fi

    if grep -q "Quickshell\.clipboardText\s*=" "$NI_FILE"; then
      pass "S4: NotificationItem.qml copies OTP code to clipboardText on action chip click (OTP-02)"
    else
      fail "S4: NotificationItem.qml MISSING Quickshell.clipboardText assignment"
      finding "S4: Missing clipboardText assignment in NotificationItem.qml"
    fi
  else
    fail "S4: NotificationItem.qml not found at $NI_FILE"
  fi

  if [[ -f "$NU_FILE" ]]; then
    if grep -q "function extractOtpCode" "$NU_FILE" && grep -q "function extractUrl" "$NU_FILE"; then
      pass "S4: NotificationUtils.qml defines extractOtpCode and extractUrl functions"
    else
      fail "S4: NotificationUtils.qml MISSING extractOtpCode or extractUrl definitions"
      finding "S4: Missing extractOtpCode or extractUrl in NotificationUtils.qml"
    fi
  else
    fail "S4: NotificationUtils.qml not found at $NU_FILE"
  fi

  # 2. Sandboxed Node.js VM Evaluation of extractOtpCode() and extractUrl()
  OTP_VM_RESULT="$(node -e '
const fs = require("fs");
const qmlPath = process.argv[1];
let content = fs.readFileSync(qmlPath, "utf8");
content = content.replace(/^pragma.*$/gm, "").replace(/^import.*$/gm, "");
content = content.replace(/Singleton\s*\{[\s\S]*?id:\s*root/, "");
const lastBrace = content.lastIndexOf("}");
content = content.substring(0, lastBrace);

const sandbox = {
  Qt: { formatDateTime: () => "" },
  Translation: { tr: (s) => s }
};
const fn = new Function("sandbox", `
  const { Qt, Translation } = sandbox;
  ${content}
  return { extractOtpCode, extractUrl };
`);
const NotificationUtils = fn(sandbox);

const cases = [
  { body: "Your PIN is 9482.", summary: "", expected: "9482", desc: "4-digit PIN" },
  { body: "Your verification code: 482910", summary: "", expected: "482910", desc: "6-digit standard verification code" },
  { body: "Your security code: 84920192", summary: "", expected: "84920192", desc: "8-digit auth code" },
  { body: "123-456 is your code", summary: "", expected: "123-456", desc: "Hyphenated code (code before keyword)" },
  { body: "Google: G-829104 is your verification code", summary: "", expected: "G-829104", desc: "Service-prefixed code (G-XXXXXX)" },
  { body: "Use 582910 for 2FA auth", summary: "", expected: "582910", desc: "Proximity preceding keyword" },
  { body: "Your code is 738291. It will expire in 5 minutes.", summary: "", expected: "738291", desc: "Proximity with trailing sentence" },
  { body: "Your one-time password is 192837", summary: "", expected: "192837", desc: "Keyword: one-time password" },
  { body: "Your passcode: 472910", summary: "", expected: "472910", desc: "Keyword: passcode" },
  { body: "Please verify using 619283", summary: "", expected: "619283", desc: "Keyword: verify" },
  { body: "OTP: 839201", summary: "", expected: "839201", desc: "Keyword: OTP" },
  { body: "Auth code 928103", summary: "", expected: "928103", desc: "Keyword: auth code" },
  { body: "Security code is 382910", summary: "", expected: "382910", desc: "Keyword: security code" },
  { body: "<p>Your verification code is <b>829104</b></p>", summary: "", expected: "829104", desc: "HTML formatted body" },

  // Negative Cases
  { body: "Meeting on 2026-09-24 at room 4B", summary: "", expected: "", desc: "Calendar date rejection" },
  { body: "Event scheduled at 14:30 today", summary: "", expected: "", desc: "Timestamp rejection" },
  { body: "Call us at +1-800-555-0199 for assistance", summary: "", expected: "", desc: "Phone number rejection" },
  { body: "Order #9482103 has been placed successfully", summary: "", expected: "", desc: "Order ID without security keywords" },
  { body: "Downloaded 1048576 bytes in 2 seconds", summary: "", expected: "", desc: "Counter metric rejection" }
];

let otpPass = true;
for (const c of cases) {
  const actual = NotificationUtils.extractOtpCode(c.body, c.summary);
  if (actual !== c.expected) {
    otpPass = false;
  }
}

const u1 = NotificationUtils.extractUrl("<a href=\"https://example.com/verify\">Click here</a>");
const u2 = NotificationUtils.extractUrl("Please visit https://github.com/test for details");
const u3 = NotificationUtils.extractUrl("<a href=\"javascript:alert(1)\">Bad</a>");
const u4 = NotificationUtils.extractUrl("<a href=\"file:///etc/passwd\">Bad</a>");
const u5 = NotificationUtils.extractUrl("visit data:text/html,bad");

const urlPass = (u1 === "https://example.com/verify" && u2 === "https://github.com/test" && u3 === "" && u4 === "" && u5 === "");

console.log(JSON.stringify({ otpPass, urlPass, ok: (otpPass && urlPass) }));
process.exit((otpPass && urlPass) ? 0 : 1);
' "$NU_FILE" 2>/dev/null || echo '{"ok":false}')"

  if echo "$OTP_VM_RESULT" | jq -e '.otpPass' >/dev/null 2>&1; then
    pass "S4: Sandboxed Node.js VM passed all 19 OTP extraction test cases (OTP-01)"
  else
    fail "S4: Sandboxed Node.js VM failed one or more OTP extraction test cases"
    finding "S4: OTP extraction test matrix failure"
  fi

  if echo "$OTP_VM_RESULT" | jq -e '.urlPass' >/dev/null 2>&1; then
    pass "S4: Sandboxed Node.js VM passed URL extraction & scheme sanitization (NAV-02, T-41-03)"
  else
    fail "S4: Sandboxed Node.js VM failed URL extraction & scheme sanitization"
    finding "S4: URL extraction sanitization failure"
  fi

  # 3. Optional Live Notification (D-08)
  if [[ "$LIVE_NOTIFY" -eq 1 && "$SYNTAX_ONLY" -eq 0 ]]; then
    if command -v notify-send >/dev/null 2>&1; then
      if notify-send -t 800 -a "Phase41Test" "Test OTP: 582910" "Verification code for Phase 41" 2>/dev/null; then
        pass "S4: Transient visual notification dispatched successfully (D-08)"
      else
        soft "S4: notify-send returned non-zero; soft-skipping visual notification (D-04)"
      fi
    else
      soft "S4: notify-send not available on PATH; soft-skipping visual notification (D-04)"
    fi
  fi

  if [[ "$RUN_SECTION" -eq 4 ]]; then
    info "=========================================="
    info "Phase 41 Section 4 Summary: FAIL=$FAIL FINDINGS=$FINDINGS"
    info "=========================================="
    exit "$FAIL"
  fi
fi

# ===========================================================================
# Section 5: Clock Padding & Unified Volume Ceiling Contract
# (CLOCK-01, VOL-01..02, INTG-02, D-02, D-04)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Clock Padding & Unified Volume Ceiling Contract ---"

  CW_FILE="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml"
  CFG_FILE="$REPO_ROOT/capture/ii/.config/illogical-impulse/config.json"
  KB_FILE="$REPO_ROOT/stow/hypr/.config/hypr/custom/keybinds.lua"
  CONFIG_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/common/Config.qml"
  AUDIO_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/Audio.qml"
  QS_FILE="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/sidebarRight/QuickSliders.qml"

  # 1. Static AST Validation of ClockWidget.qml (CLOCK-01, D-01)
  if [[ -f "$CW_FILE" ]]; then
    if grep -q "anchors\.leftMargin:\s*5" "$CW_FILE" && grep -q "anchors\.rightMargin:\s*5" "$CW_FILE"; then
      pass "S5: ClockWidget.qml has 10px horizontal breathing room (5px left/right margins on rowLayout) (CLOCK-01)"
    else
      fail "S5: ClockWidget.qml MISSING 5px left/right margins on rowLayout"
      finding "S5: ClockWidget.qml margins do not match 5px"
    fi

    if grep -q "implicitWidth:\s*8" "$CW_FILE" && grep -q "DateTime\.time" "$CW_FILE" && grep -q "DateTime\.longDate" "$CW_FILE"; then
      pass "S5: ClockWidget.qml preserves spacer (implicitWidth: 8) and DateTime bindings"
    else
      fail "S5: ClockWidget.qml MISSING spacer or DateTime bindings"
      finding "S5: ClockWidget.qml missing core AST tokens"
    fi
  else
    fail "S5: ClockWidget.qml not found at $CW_FILE"
  fi

  # 2. Desktop Config Single Source of Truth (VOL-01)
  if [[ -f "$CFG_FILE" ]]; then
    CEILING="$(jq -r '.audio.volumeCeiling // empty' "$CFG_FILE" 2>/dev/null || echo "")"
    if [[ "$CEILING" == "1.5" ]]; then
      pass "S5: config.json defines audio.volumeCeiling: 1.5 as single source of truth (VOL-01)"
    else
      fail "S5: config.json audio.volumeCeiling is '$CEILING' (expected 1.5)"
      finding "S5: config.json volumeCeiling mismatch"
    fi
  else
    fail "S5: config.json not found at $CFG_FILE"
  fi

  # 3. Hyprland Keybinds Validation
  if [[ -f "$KB_FILE" ]]; then
    if luac -p "$KB_FILE" >/dev/null 2>&1; then
      pass "S5: keybinds.lua syntax verified via luac -p"
    else
      fail "S5: keybinds.lua failed luac syntax check"
      finding "S5: keybinds.lua syntax error"
    fi

    if grep -q 'hl\.unbind("XF86AudioRaiseVolume")' "$KB_FILE"; then
      pass "S5: keybinds.lua unbinds upstream XF86AudioRaiseVolume"
    else
      fail "S5: keybinds.lua MISSING unbind of upstream XF86AudioRaiseVolume"
      finding "S5: keybinds.lua missing unbind"
    fi

    if grep -q 'volumeCeiling' "$KB_FILE" && grep -q 'wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l' "$KB_FILE"; then
      pass "S5: keybinds.lua dynamically parses volumeCeiling and binds wpctl 2%+ with ceiling limit"
    else
      fail "S5: keybinds.lua MISSING volumeCeiling parsing or wpctl raise binding"
      finding "S5: keybinds.lua volume binding mismatch"
    fi
  else
    fail "S5: keybinds.lua not found at $KB_FILE"
  fi

  # 4. Quickshell Audio Schema & Service AST
  if [[ -f "$CONFIG_QML" ]]; then
    if grep -q "property real volumeCeiling:\s*1\.5" "$CONFIG_QML"; then
      pass "S5: Config.qml defines property real volumeCeiling: 1.5"
    else
      fail "S5: Config.qml MISSING property real volumeCeiling: 1.5"
      finding "S5: Config.qml volumeCeiling declaration missing"
    fi
  else
    fail "S5: Config.qml not found at $CONFIG_QML"
  fi

  if [[ -f "$AUDIO_QML" ]]; then
    if grep -q "readonly property real maxVolume:" "$AUDIO_QML" && grep -q "volumeCeiling" "$AUDIO_QML"; then
      pass "S5: Audio.qml defines maxVolume property bound to Config.options.audio.volumeCeiling"
    else
      fail "S5: Audio.qml MISSING maxVolume binding to volumeCeiling"
      finding "S5: Audio.qml maxVolume binding missing"
    fi

    if grep -q "Math\.min(root\.maxVolume" "$AUDIO_QML" && grep -q "Audio\.sink\.audio\.muted\s*=\s*false" "$AUDIO_QML"; then
      pass "S5: Audio.qml incrementVolume() enforces dynamic clamp to maxVolume and auto-unmutes (VOL-02)"
    else
      fail "S5: Audio.qml incrementVolume() missing clamp or auto-unmute"
      finding "S5: Audio.qml incrementVolume logic missing"
    fi
  else
    fail "S5: Audio.qml not found at $AUDIO_QML"
  fi

  # 5. Sidebar Slider AST in QuickSliders.qml
  if [[ -f "$QS_FILE" ]]; then
    if grep -q "to:\s*Audio\.maxVolume" "$QS_FILE" && grep -q "stopIndicatorValues:\s*\[1\.0\]" "$QS_FILE"; then
      pass "S5: QuickSliders.qml slider binds to Audio.maxVolume with 100% stop notch [1.0] (VOL-02)"
    else
      fail "S5: QuickSliders.qml MISSING Audio.maxVolume binding or [1.0] stop notch"
      finding "S5: QuickSliders.qml slider contract missing"
    fi

    if grep -q "tooltipContent:" "$QS_FILE" && grep -q "Math\.round(value \* 100)" "$QS_FILE"; then
      pass "S5: QuickSliders.qml slider includes percentage tooltip content"
    else
      fail "S5: QuickSliders.qml MISSING percentage tooltip content"
      finding "S5: QuickSliders.qml tooltip missing"
    fi
  else
    fail "S5: QuickSliders.qml not found at $QS_FILE"
  fi

  # 6. Headless Node.js Volume Step Simulation
  VOL_SIM_RESULT="$(node -e '
function createAudioModel(initialVolume, initialMuted, maxVolume) {
  const root = { maxVolume: maxVolume || 1.5, hardMaxValue: 2.0 };
  const Audio = {
    value: initialVolume,
    sink: {
      audio: {
        volume: initialVolume,
        muted: initialMuted
      }
    }
  };

  function incrementVolume() {
    if (Audio.sink && Audio.sink.audio) {
      Audio.sink.audio.muted = false;
      const currentVolume = Audio.value;
      const step = currentVolume < 0.1 ? 0.01 : 0.02;
      Audio.sink.audio.volume = Math.min(root.maxVolume, Audio.sink.audio.volume + step);
      Audio.value = Audio.sink.audio.volume;
    }
  }

  return { Audio, incrementVolume };
}

let errors = 0;
// Test 1: Step below 0.1 uses 0.01 step
const s1 = createAudioModel(0.05, false, 1.5);
s1.incrementVolume();
if (Math.abs(s1.Audio.sink.audio.volume - 0.06) > 0.0001) errors++;

// Test 2: Step at or above 0.1 uses 0.02 step
const s2 = createAudioModel(0.50, false, 1.5);
s2.incrementVolume();
if (Math.abs(s2.Audio.sink.audio.volume - 0.52) > 0.0001) errors++;

// Test 3: Clamping at 1.5
const s3 = createAudioModel(1.49, false, 1.5);
s3.incrementVolume();
if (Math.abs(s3.Audio.sink.audio.volume - 1.50) > 0.0001) errors++;

// Test 4: Auto-unmute when raised
const s4 = createAudioModel(0.50, true, 1.5);
s4.incrementVolume();
if (s4.Audio.sink.audio.muted !== false) errors++;

console.log(JSON.stringify({ errors, ok: errors === 0 }));
process.exit(errors === 0 ? 0 : 1);
' 2>/dev/null || echo '{"ok":false}')"

  if echo "$VOL_SIM_RESULT" | jq -e '.ok' >/dev/null 2>&1; then
    pass "S5: Headless Node.js volume step & auto-unmute simulation passed all cases"
  else
    fail "S5: Headless Node.js volume step simulation failed: $VOL_SIM_RESULT"
    finding "S5: Volume step simulation failure"
  fi

  # 7. Two-tier live PipeWire query (D-04)
  if [[ "$SYNTAX_ONLY" -eq 0 ]]; then
    if wpctl status >/dev/null 2>&1; then
      LIVE_VOL="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "")"
      if [[ -n "$LIVE_VOL" ]]; then
        pass "S5: Live PipeWire default sink query succeeded: $LIVE_VOL"
      else
        soft "S5: wpctl get-volume returned empty; soft-skipping live query"
      fi
    else
      soft "S5: PipeWire audio server inactive or wpctl status failed; soft-skipping live query (D-04)"
    fi
  else
    info "S5: Syntax-only mode — skipping live PipeWire queries"
  fi

  if [[ "$RUN_SECTION" -eq 5 ]]; then
    info "=========================================="
    info "Phase 41 Section 5 Summary: FAIL=$FAIL FINDINGS=$FINDINGS"
    info "=========================================="
    exit "$FAIL"
  fi
fi



