#!/usr/bin/env bash
# ===========================================================================
# Phase 40: Notification Center Quick-Dismiss & Smart Interaction Assert Harness
# Enforces: NOTIF-01, NOTIF-02, NAV-01, NAV-02, OTP-01, OTP-02, INTG-01, INTG-02
#
# Usage (from REPO_ROOT):
#   ./scripts/phase40-notification-interaction-assert.sh [--section <1-5>] [-s <1-5>] [--syntax]
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

PORCELAIN_BEFORE="$(mktemp /tmp/p40-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p40-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# Helper to run headless Quickshell QML snippet
run_qs_test() {
  local qml_content="$1"
  local timeout_sec="${2:-4.5}"

  local runner_file
  runner_file="$(mktemp "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/p40_runner_XXXXXX.qml")"
  TMP_FILES+=("$runner_file")

  printf '%s\n' "$qml_content" > "$runner_file"
  local out=""
  out="$(timeout "${timeout_sec}s" quickshell -p "$runner_file" 2>&1 || true)"
  rm -f "$runner_file" 2>/dev/null || true
  printf '%s\n' "$out"
}

# Helper to run Node.js on extracted NotificationUtils
run_js_eval() {
  local js_code="$1"
  local qml_path="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml"
  if [[ ! -f "$qml_path" ]]; then
    qml_path="$HOME/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml"
  fi

  node -e '
const fs = require("fs");
const qmlPath = process.argv[1];
const testCode = process.argv[2];

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
  return {
    findSuitableMaterialSymbol,
    getFriendlyNotifTimeString,
    processNotificationBody,
    extractOtpCode,
    extractUrl
  };
`);
const NotificationUtils = fn(sandbox);

const runTest = new Function("NotificationUtils", testCode);
runTest(NotificationUtils);
' "$qml_path" "$js_code"
}

# Paths to restow overlay files
NU_RESTOW="restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml"
NG_RESTOW="restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml"
NI_RESTOW="restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml"

# Home deploy paths
NU_HOME="$HOME/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml"
NG_HOME="$HOME/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml"
NI_HOME="$HOME/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml"

# ===========================================================================
# Section 1: Symlink & Packaging Integrity
# ===========================================================================
if [[ "$SYNTAX_ONLY" -eq 0 ]] && [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Symlink & Packaging Integrity ---"

  # Verify NotificationUtils exists in restow
  if [[ -f "$REPO_ROOT/$NU_RESTOW" ]]; then
    pass "S1: Restow overlay exists: $NU_RESTOW"
  else
    fail "S1: Restow overlay MISSING: $NU_RESTOW"
  fi

  # Verify parent directories are real directories (no folding)
  for dir_path in \
    "$HOME/.config/quickshell/ii" \
    "$HOME/.config/quickshell/ii/modules" \
    "$HOME/.config/quickshell/ii/modules/common" \
    "$HOME/.config/quickshell/ii/modules/common/functions" \
    "$HOME/.config/quickshell/ii/modules/common/widgets"; do
    if [[ -d "$dir_path" ]] && [[ ! -L "$dir_path" ]]; then
      pass "S1: Parent directory is a real dir (no folding): $dir_path"
    else
      fail "S1: Parent directory is NOT a real dir or is a symlink (folding): $dir_path"
    fi
  done

  # Verify NotificationUtils is a symlink into restow
  if [[ -L "$NU_HOME" ]]; then
    link_target="$(readlink -f "$NU_HOME")"
    if [[ "$link_target" == *"/restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml"* ]]; then
      pass "S1: $NU_HOME is a symlink resolving into restow/quickshell/"
    else
      fail "S1: $NU_HOME symlink resolves to unexpected target: $link_target"
    fi
  else
    fail "S1: $NU_HOME is NOT a symlink in home deploy"
  fi

  # Verify widget overlays exist in restow and are symlinked into home deploy
  for widget_rel in "$NG_RESTOW" "$NI_RESTOW"; do
    widget_name="$(basename "$widget_rel")"
    home_path="$HOME/.config/quickshell/ii/modules/common/widgets/$widget_name"
    if [[ -f "$REPO_ROOT/$widget_rel" ]]; then
      pass "S1: Restow overlay exists: $widget_rel"
    else
      fail "S1: Restow overlay MISSING: $widget_rel"
    fi
    if [[ -L "$home_path" ]]; then
      link_target="$(readlink -f "$home_path")"
      if [[ "$link_target" == *"/restow/quickshell/.config/quickshell/ii/modules/common/widgets/$widget_name"* ]]; then
        pass "S1: $home_path is a symlink resolving into restow/quickshell/"
      else
        fail "S1: $home_path symlink resolves to unexpected target: $link_target"
      fi
    else
      fail "S1: $home_path is NOT a symlink in home deploy"
    fi
  done

  # Verify vendor/dots-hyprland submodule has zero diff
  if git -C vendor/dots-hyprland status --porcelain | grep -q .; then
    fail "S1: vendor/dots-hyprland submodule has unstaged or untracked changes"
  else
    pass "S1: vendor/dots-hyprland submodule is 100% clean"
  fi
fi

# ===========================================================================
# Section 2: Static AST & QML Property Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 || "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Section 2: Static AST & QML Property Verification ---"

  # NotificationUtils.qml checks
  if [[ -f "$REPO_ROOT/$NU_RESTOW" ]]; then
    if grep -q "pragma Singleton" "$REPO_ROOT/$NU_RESTOW" && grep -q "Singleton\s*{" "$REPO_ROOT/$NU_RESTOW"; then
      pass "S2: NotificationUtils.qml declares pragma Singleton and Singleton root"
    else
      fail "S2: NotificationUtils.qml missing pragma Singleton or Singleton declaration"
    fi

    if grep -q "function extractOtpCode" "$REPO_ROOT/$NU_RESTOW"; then
      pass "S2: NotificationUtils.qml declares function extractOtpCode"
      if grep -q "code|otp|verify" "$REPO_ROOT/$NU_RESTOW"; then
        pass "S2: NotificationUtils.extractOtpCode includes security keywords"
      else
        fail "S2: NotificationUtils.extractOtpCode missing security keywords"
      fi
      if grep -q "\[-/0-9\]" "$REPO_ROOT/$NU_RESTOW"; then
        pass "S2: NotificationUtils.extractOtpCode includes negative lookaround boundary assertions"
      else
        fail "S2: NotificationUtils.extractOtpCode missing negative lookaround bounds"
      fi

      if grep -qE '\(\?<!|\(\?<=' "$REPO_ROOT/$NU_RESTOW"; then
        fail "S2: NotificationUtils.qml contains unsupported RegExp lookbehind syntax (?<! or (?<="
      else
        pass "S2: NotificationUtils.qml contains no RegExp lookbehinds (QV4 engine compatible)"
      fi
    else
      info "S2: extractOtpCode not yet declared in NotificationUtils.qml (Task 2 target)"
    fi

    if grep -q "function extractUrl" "$REPO_ROOT/$NU_RESTOW"; then
      pass "S2: NotificationUtils.qml declares function extractUrl"
      if grep -qE 'https?://' "$REPO_ROOT/$NU_RESTOW"; then
        pass "S2: NotificationUtils.extractUrl validates http/https scheme"
      else
        fail "S2: NotificationUtils.extractUrl missing http/https scheme pattern"
      fi
    else
      info "S2: extractUrl not yet declared in NotificationUtils.qml (Task 2 target)"
    fi
  else
    fail "S2: $NU_RESTOW does not exist"
  fi

  # NotificationGroup.qml checks (Plan 40-02 & Plan 40-03)
  if [[ -f "$REPO_ROOT/$NG_RESTOW" ]]; then
    if grep -qE '^import qs\b' "$REPO_ROOT/$NG_RESTOW"; then
      pass "S2: NotificationGroup.qml imports qs (GlobalStates in scope)"
    else
      fail "S2: NotificationGroup.qml missing 'import qs'"
    fi

    if grep -q "id:\s*closeButton" "$REPO_ROOT/$NG_RESTOW"; then
      pass "S2: NotificationGroup.qml declares closeButton"
    else
      fail "S2: NotificationGroup.qml missing closeButton declaration"
    fi

    if grep -qE 'visible:\s*!root\.multipleNotifications\s*$' "$REPO_ROOT/$NG_RESTOW"; then
      pass "S2: NotificationGroup.qml closeButton visible on single notifications (including popups)"
    else
      fail "S2: NotificationGroup.qml closeButton visibility condition missing or contains !root.popup"
    fi

    if grep -q "root\.destroyWithAnimation()" "$REPO_ROOT/$NG_RESTOW"; then
      pass "S2: NotificationGroup.qml closeButton invokes root.destroyWithAnimation()"
    else
      fail "S2: NotificationGroup.qml closeButton missing destroyWithAnimation invocation"
    fi

    if grep -qE 'visible:\s*root\.multipleNotifications\s*$' "$REPO_ROOT/$NG_RESTOW"; then
      pass "S2: NotificationGroup.qml expandButton visible exclusively for multiple notifications"
    else
      fail "S2: NotificationGroup.qml expandButton visibility condition missing or contains || root.popup"
    fi

    if grep -q "root\.expanded\s*||\s*!root\.multipleNotifications" "$REPO_ROOT/$NG_RESTOW"; then
      pass "S2: NotificationGroup.qml card height clamping bypassed for single notifications"
    else
      fail "S2: NotificationGroup.qml card height clamping fix missing"
    fi
  else
    info "S2: NotificationGroup.qml not yet in restow (Plan 40-02 target)"
  fi

  # NotificationItem.qml checks (Plan 40-02)
  if [[ -f "$REPO_ROOT/$NI_RESTOW" ]]; then
    if grep -q "property string otpCode:" "$REPO_ROOT/$NI_RESTOW"; then
      pass "S2: NotificationItem.qml declares property string otpCode"
    else
      fail "S2: NotificationItem.qml missing property string otpCode declaration"
    fi

    if grep -q "function activateNotification()" "$REPO_ROOT/$NI_RESTOW"; then
      pass "S2: NotificationItem.qml declares function activateNotification"
    else
      fail "S2: NotificationItem.qml missing activateNotification function"
    fi

    if grep -q "Quickshell\.clipboardText\s*=" "$REPO_ROOT/$NI_RESTOW"; then
      pass "S2: NotificationItem.qml copies OTP code to Quickshell.clipboardText"
    else
      fail "S2: NotificationItem.qml missing Quickshell.clipboardText assignment"
    fi

    if grep -q "colSecondaryContainer" "$REPO_ROOT/$NI_RESTOW"; then
      pass "S2: NotificationItem.qml uses Appearance.colors.colSecondaryContainer styling"
    else
      fail "S2: NotificationItem.qml missing colSecondaryContainer styling"
    fi

    # Verify no decorative icons (key icon, etc.) used on OTP chip (D-08)
    if grep -A 10 "id:\s*otpChip" "$REPO_ROOT/$NI_RESTOW" | grep -qi "materialsymbol\|icon"; then
      fail "S2: NotificationItem.qml OTP pill chip must NOT contain decorative icons (D-08)"
    else
      pass "S2: NotificationItem.qml OTP pill chip is icon-free (D-08)"
    fi
  else
    info "S2: NotificationItem.qml not yet in restow (Plan 40-02 target)"
  fi
fi

# ===========================================================================
# Section 3: OTP Code Regex Extraction Test Matrix
# ===========================================================================
if [[ "$SYNTAX_ONLY" -eq 0 ]] && [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: OTP Code Regex Extraction Test Matrix ---"

  if grep -q "function extractOtpCode" "$REPO_ROOT/$NU_RESTOW" 2>/dev/null; then
    js_test='
    const cases = [
      // 14 Positive Cases
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

      // 5 Negative Cases (must strictly return empty string)
      { body: "Meeting on 2026-09-24 at room 4B", summary: "", expected: "", desc: "Calendar date rejection" },
      { body: "Event scheduled at 14:30 today", summary: "", expected: "", desc: "Timestamp rejection" },
      { body: "Call us at +1-800-555-0199 for assistance", summary: "", expected: "", desc: "Phone number rejection" },
      { body: "Order #9482103 has been placed successfully", summary: "", expected: "", desc: "Order ID without security keywords" },
      { body: "Downloaded 1048576 bytes in 2 seconds", summary: "", expected: "", desc: "Counter metric rejection" }
    ];

    let passed = 0;
    let failed = 0;

    for (const c of cases) {
      const actual = NotificationUtils.extractOtpCode(c.body, c.summary);
      if (actual === c.expected) {
        console.log(`[PASS] S3: ${c.desc} -> "${actual}"`);
        passed++;
      } else {
        console.log(`[FAIL] S3: ${c.desc} -> Expected "${c.expected}", got "${actual}"`);
        failed++;
      }
    }

    if (failed > 0) {
      process.exit(1);
    }
    '

    if run_js_eval "$js_test"; then
      pass "S3: All 19 OTP extraction test cases passed"
    else
      fail "S3: One or more OTP extraction test cases failed"
    fi
  else
    info "S3: extractOtpCode not yet declared in NotificationUtils.qml (Task 2 target)"
  fi
fi

# ===========================================================================
# Section 4: URL Extraction & Navigation Test Suite
# ===========================================================================
if [[ "$SYNTAX_ONLY" -eq 0 ]] && [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: URL Extraction & Navigation Test Suite ---"

  if grep -q "function extractUrl" "$REPO_ROOT/$NU_RESTOW" 2>/dev/null; then
    js_url_test='
    const cases = [
      {
        body: "<a href=\"https://web.whatsapp.com\">web.whatsapp.com</a>\n\nNew message from Alice",
        expected: "https://web.whatsapp.com",
        desc: "Chromium HTML anchor href extraction"
      },
      {
        body: "<a href=\"https://youtube.com/watch?v=123&amp;t=10\">Video Title</a>",
        expected: "https://youtube.com/watch?v=123&t=10",
        desc: "HTML anchor entity unescaping (&amp; to &)"
      },
      {
        body: "Check out https://github.com/pera. It has new commits!",
        expected: "https://github.com/pera",
        desc: "Raw URL trailing punctuation stripping"
      },
      {
        body: "Visit https://example.com/api?user=1&amp;test=2, right now",
        expected: "https://example.com/api?user=1&test=2",
        desc: "Raw URL parameter unescaping and trailing comma stripping"
      },
      {
        body: "javascript:alert(1)",
        expected: "",
        desc: "Untrusted scheme rejection: javascript:"
      },
      {
        body: "file:///etc/passwd",
        expected: "",
        desc: "Untrusted scheme rejection: file:"
      },
      {
        body: "data:text/html,<html>alert(1)</html>",
        expected: "",
        desc: "Untrusted scheme rejection: data:"
      }
    ];

    let passed = 0;
    let failed = 0;

    for (const c of cases) {
      const actual = NotificationUtils.extractUrl(c.body);
      if (actual === c.expected) {
        console.log(`[PASS] S4: ${c.desc} -> "${actual}"`);
        passed++;
      } else {
        console.log(`[FAIL] S4: ${c.desc} -> Expected "${c.expected}", got "${actual}"`);
        failed++;
      }
    }

    if (failed > 0) {
      process.exit(1);
    }
    '

    if run_js_eval "$js_url_test"; then
      pass "S4: All URL extraction test cases passed"
    else
      fail "S4: One or more URL extraction test cases failed"
    fi

    # Test Body Click Activation Routing Precedence (D-04, D-05, D-06, NAV-01)
    js_activation_test='
    function simulateActivation(notif, NotificationUtils) {
      let invokedAction = null;
      let openedUrl = null;
      let discardedId = null;

      const Notifications = {
        attemptInvokeAction: (id, action) => { invokedAction = action; },
        discardNotification: (id) => { discardedId = id; }
      };
      const Qt = {
        openUrlExternally: (url) => { openedUrl = url; }
      };
      const GlobalStates = {
        sidebarRightOpen: true
      };

      function activateNotification() {
        if (!notif) return;
        const hasDefaultAction = notif.actions?.some(a => a.identifier === "default");
        const extractedUrl = NotificationUtils.extractUrl(notif.body);

        if (hasDefaultAction) {
          Notifications.attemptInvokeAction(notif.notificationId, "default");
        } else if (extractedUrl) {
          Qt.openUrlExternally(extractedUrl);
          Notifications.discardNotification(notif.notificationId);
        } else {
          Notifications.discardNotification(notif.notificationId);
        }
        GlobalStates.sidebarRightOpen = false;
      }

      activateNotification();
      return { invokedAction, openedUrl, discardedId, sidebarOpen: GlobalStates.sidebarRightOpen };
    }

    let actFailed = 0;

    // Case 1: D-Bus action takes precedence over embedded URL
    const r1 = simulateActivation({ notificationId: 101, actions: [{ identifier: "default" }], body: "Check https://github.com" }, NotificationUtils);
    if (r1.invokedAction === "default" && r1.openedUrl === null && r1.sidebarOpen === false) {
      console.log("[PASS] S4: Precedence 1 - D-Bus default action prioritized over URL");
    } else {
      console.log("[FAIL] S4: Precedence 1 - Expected D-Bus action invocation");
      actFailed++;
    }

    // Case 2: URL fallback when no D-Bus default action exists
    const r2 = simulateActivation({ notificationId: 102, actions: [{ identifier: "other" }], body: "Check https://github.com" }, NotificationUtils);
    if (r2.openedUrl === "https://github.com" && r2.discardedId === 102 && r2.sidebarOpen === false) {
      console.log("[PASS] S4: Precedence 2 - Embedded URL fallback opened externally and discarded");
    } else {
      console.log("[FAIL] S4: Precedence 2 - Expected URL fallback");
      actFailed++;
    }

    // Case 3: Passive notification without actions or URLs simply discards and closes sidebar
    const r3 = simulateActivation({ notificationId: 103, actions: [], body: "Simple notice text" }, NotificationUtils);
    if (r3.discardedId === 103 && r3.openedUrl === null && r3.sidebarOpen === false) {
      console.log("[PASS] S4: Precedence 3 - Passive notification discarded and sidebar closed");
    } else {
      console.log("[FAIL] S4: Precedence 3 - Expected passive notification discard");
      actFailed++;
    }

    if (actFailed > 0) {
      process.exit(1);
    }
    '

    if run_js_eval "$js_activation_test"; then
      pass "S4: Smart body click activation precedence tests passed"
    else
      fail "S4: Smart body click activation precedence tests failed"
    fi
  else
    fail "S4: extractUrl missing in NotificationUtils.qml"
  fi
fi

# ===========================================================================
# Section 5: Repository Integrity & Strict Verification
# ===========================================================================
if [[ "$SYNTAX_ONLY" -eq 0 ]] && [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Repository Integrity & Strict Verification ---"

  # Run dots-hyprland verify --strict
  set +e
  DOTS_OUTPUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)"
  DOTS_EXIT=$?
  set -e

  if [[ $DOTS_EXIT -eq 0 ]] && echo "$DOTS_OUTPUT" | grep -q "=== done: FAIL=0 FINDINGS=0 ==="; then
    pass "S5: ./arch/dots-hyprland.sh verify --strict passed with FAIL=0 FINDINGS=0"
  else
    fail "S5: ./arch/dots-hyprland.sh verify --strict failed (exit $DOTS_EXIT)"
    echo "$DOTS_OUTPUT" | tail -n 15 >&2
  fi

  # Verify git porcelain status before and after execution
  porcelain_snapshot > "$PORCELAIN_AFTER"
  if diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" >/dev/null 2>&1; then
    pass "S5: Git porcelain status is identical before and after harness execution"
  else
    fail "S5: Git porcelain status drifted during harness execution"
    diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
  fi
fi

# ===========================================================================
# Summary
# ===========================================================================
echo ""
echo "=== Phase 40 Assertion Summary ==="
echo "Failures: $FAIL"
echo "Findings: $FINDINGS"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi

exit 0
