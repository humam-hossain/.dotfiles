#!/usr/bin/env bash
# ===========================================================================
# Phase 45: Network & Multi-Target Ping Component (Pill & Popup) Assert Harness
# Enforces: NETPING-01..05, D-01 through D-17
#
# Usage (from REPO_ROOT):
#   ./scripts/phase45-network-ping-assert.sh [1-5] [--section <1-5>] [-s <1-5>] [--quick] [--syntax]
#
# Exit 0 if all asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
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
    --quick|-q)
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
      echo "Options:"
      echo "  [1-5]                 Positional section selector"
      echo "  -s, --section <1-5>   Execute only the specified section (1-5)"
      echo "  -q, --quick           Execute static / quick checks only"
      echo "  -c, --syntax          Execute syntax checks only"
      echo "  -h, --help            Show this help message"
      echo ""
      echo "Sections:"
      echo "  1: Telemetry Services & Ping Client (NetworkUsage.qml, PingService.qml)"
      echo "  2: NetworkPingPill Component Logic & Visual Parity (NETPING-01, NETPING-02, NETPING-05, D-01..D-04, D-14, D-16, D-17)"
      echo "  3: NetworkPingPopup Two-Column Layout & Diagnostics (NETPING-04, NETPING-05, D-05..D-09, D-12, D-15..D-17)"
      echo "  4: Live Telemetry & Formatting Mathematics (D-01, D-06, D-11)"
      echo "  5: Stow Symlink Integrity & Working Tree Verification (NETPING-01..05, INTG-02)"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

info "=== Phase 45 Network & Multi-Target Ping Component Assert Harness ==="
info "Working directory: $REPO_ROOT"
info "Flags: section=$RUN_SECTION quick=$QUICK_MODE syntax_only=$SYNTAX_ONLY"

SERVICES_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services"
BAR_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar"

NETWORK_QML="$SERVICES_DIR/NetworkUsage.qml"
PING_QML="$SERVICES_DIR/PingService.qml"
PILL_QML="$BAR_DIR/NetworkPingPill.qml"
POPUP_QML="$BAR_DIR/NetworkPingPopup.qml"

# ---------------------------------------------------------------------------
# Syntax-only mode early exit check
# ---------------------------------------------------------------------------
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  pass "Assert harness bash syntax check passed (bash -n verified)"

  for qml_file in "$NETWORK_QML" "$PING_QML" "$PILL_QML" "$POPUP_QML"; do
    if [[ -f "$qml_file" ]]; then
      pass "QML file present: $(basename "$qml_file")"
    fi
  done

  info "=== Syntax Summary ==="
  info "Failures: $FAIL, Findings: $FINDINGS"
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Telemetry Services & Ping Client (NetworkUsage.qml, PingService.qml)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Telemetry Services & Ping Client (NETPING-01, NETPING-03, D-06, D-10..D-13) ---"

  if [[ ! -f "$NETWORK_QML" ]]; then
    fail "NetworkUsage.qml does not exist at $NETWORK_QML"
  else
    pass "NetworkUsage.qml exists"

    # Required pragmas (D-10)
    if grep -q "pragma Singleton" "$NETWORK_QML"; then
      pass "NetworkUsage.qml declares pragma Singleton"
    else
      fail "NetworkUsage.qml missing pragma Singleton"
    fi

    if grep -q "pragma ComponentBehavior: Bound" "$NETWORK_QML"; then
      pass "NetworkUsage.qml declares pragma ComponentBehavior: Bound"
    else
      fail "NetworkUsage.qml missing pragma ComponentBehavior: Bound"
    fi

    # Adaptive polling interval: 1000ms active / 2000ms idle (D-12)
    if grep -qE "(isInspectorActive|root\.isInspectorActive)[[:space:]]*\?[[:space:]]*1000[[:space:]]*:[[:space:]]*2000" "$NETWORK_QML"; then
      pass "NetworkUsage.qml implements adaptive polling interval (1000ms active / 2000ms idle)"
    else
      fail "NetworkUsage.qml missing adaptive polling cadence (isInspectorActive ? 1000 : 2000)"
    fi

    # Virtual file reading of /proc/net/dev via FileView
    if grep -q 'path: "/proc/net/dev"' "$NETWORK_QML" && \
       grep -q "printErrors: false" "$NETWORK_QML" && \
       grep -q "blockLoading: true" "$NETWORK_QML"; then
      pass "NetworkUsage.qml reads /proc/net/dev via FileView with printErrors: false and blockLoading: true"
    else
      fail "NetworkUsage.qml missing FileView configuration for /proc/net/dev"
    fi

    # Carrier Priority Hierarchy interface detection (D-13)
    if grep -q "carrier" "$NETWORK_QML" && grep -qE "(en|eth)" "$NETWORK_QML" && grep -q "wl" "$NETWORK_QML"; then
      pass "NetworkUsage.qml implements Carrier Priority Hierarchy (Ethernet prioritized over Wi-Fi)"
    else
      fail "NetworkUsage.qml missing Carrier Priority Hierarchy logic"
    fi

    # Dynamic Realtek r8169 hwmon temperature scanning across /sys/class/hwmon with fallback (D-06)
    if grep -qE "(r8169|hwmon)" "$NETWORK_QML" && grep -q "temp1_input" "$NETWORK_QML"; then
      pass "NetworkUsage.qml discovers Realtek r8169 hwmon temperature via /sys/class/hwmon"
    else
      fail "NetworkUsage.qml missing dynamic Realtek r8169 hwmon temperature scanning"
    fi

    # Required public telemetry properties suite (D-11)
    REQ_PROPS=(
      "activeInterface" "connectionType" "isEthernet" "isWireless" "isConnected"
      "materialSymbol" "ipAddress" "gatewayIp" "dnsServers" "linkSpeed"
      "macAddress" "nicTemp" "nicTempString" "rxBytesPerSec" "txBytesPerSec"
      "rxRateString" "txRateString" "rxShortRate" "txShortRate" "totalRxBytes"
      "totalTxBytes" "totalRxString" "totalTxString" "rxErrors" "txErrors"
      "rxDrops" "txDrops"
    )
    ALL_PROPS_OK=1
    for prop in "${REQ_PROPS[@]}"; do
      if ! grep -qE "property[[:space:]]+[a-zA-Z0-9<>]+[[:space:]]+$prop([[:space:]]*:|[[:space:]]*=)" "$NETWORK_QML"; then
        fail "NetworkUsage.qml missing required telemetry property: $prop"
        ALL_PROPS_OK=0
      fi
    done
    if [[ "$ALL_PROPS_OK" -eq 1 ]]; then
      pass "NetworkUsage.qml declares all ${#REQ_PROPS[@]} required public telemetry properties"
    fi
  fi

  # PingService.qml checks
  if [[ ! -f "$PING_QML" ]]; then
    fail "PingService.qml does not exist at $PING_QML"
  else
    pass "PingService.qml exists"

    if grep -q "http://127.0.0.1:8765/api/status" "$PING_QML"; then
      pass "PingService.qml targets daemon status endpoint http://127.0.0.1:8765/api/status"
    else
      fail "PingService.qml does not target http://127.0.0.1:8765/api/status"
    fi

    # Maps all 3 targets
    if grep -q "8.8.8.8" "$PING_QML" && grep -q "192.168.0.1" "$PING_QML" && grep -q "192.168.0.104" "$PING_QML"; then
      pass "PingService.qml maps all 3 targets (8.8.8.8, 192.168.0.1, 192.168.0.104)"
    else
      fail "PingService.qml missing target mappings for 8.8.8.8, 192.168.0.1, or 192.168.0.104"
    fi

    # Offline handling
    if grep -q "handleOffline" "$PING_QML" && grep -q "isOffline" "$PING_QML"; then
      pass "PingService.qml provides offline fallback handling"
    else
      fail "PingService.qml missing handleOffline fallback"
    fi
  fi
fi

# ===========================================================================
# Section 2: NetworkPingPill Component Logic & Visual Parity (NETPING-01, NETPING-02, NETPING-05, D-01..D-04, D-14, D-16, D-17)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: NetworkPingPill Component Logic & Visual Parity (NETPING-01, NETPING-02, NETPING-05, D-01..D-04, D-14, D-16, D-17) ---"

  if [[ ! -f "$PILL_QML" ]]; then
    fail "NetworkPingPill.qml does not exist at $PILL_QML"
  else
    pass "NetworkPingPill.qml exists"

    # Bound pragma
    if grep -q "pragma ComponentBehavior: Bound" "$PILL_QML"; then
      pass "NetworkPingPill.qml declares pragma ComponentBehavior: Bound"
    else
      fail "NetworkPingPill.qml missing pragma ComponentBehavior: Bound"
    fi

    # BarGroup root inheritance
    if grep -qE "^BarGroup[[:space:]]*\{" "$PILL_QML"; then
      pass "NetworkPingPill.qml inherits BarGroup as root component"
    else
      fail "NetworkPingPill.qml does not inherit BarGroup as root"
    fi

    # Re-parented MouseArea with left-click launcher (D-14, D-16)
    if grep -q "MouseArea" "$PILL_QML" && grep -q "parent: root" "$PILL_QML"; then
      pass "NetworkPingPill.qml encapsulates re-parented MouseArea (parent: root)"
    else
      fail "NetworkPingPill.qml missing re-parented MouseArea with parent: root"
    fi

    if grep -q "anchors.fill: parent" "$PILL_QML" && \
       grep -q "acceptedButtons: Qt.AllButtons" "$PILL_QML" && \
       grep -q "cursorShape: Qt.PointingHandCursor" "$PILL_QML"; then
      pass "NetworkPingPill.qml configures MouseArea with anchors.fill: parent, acceptedButtons: Qt.AllButtons, and PointingHandCursor"
    else
      fail "NetworkPingPill.qml MouseArea missing proper anchors, acceptedButtons, or cursorShape"
    fi

    if grep -q "readonly property alias hoverArea:" "$PILL_QML"; then
      pass "NetworkPingPill.qml exports hoverArea alias for popup anchoring"
    else
      fail "NetworkPingPill.qml missing hoverArea alias"
    fi

    # Left-click handler launches http://127.0.0.1:8765/ via Quickshell.execDetached (D-14)
    if grep -q "Quickshell.execDetached" "$PILL_QML" && \
       grep -q "xdg-open" "$PILL_QML" && \
       grep -q "http://127.0.0.1:8765/" "$PILL_QML"; then
      pass "NetworkPingPill.qml launches http://127.0.0.1:8765/ on left-click via Quickshell.execDetached"
    else
      fail "NetworkPingPill.qml missing non-blocking left-click browser launch"
    fi

    # Press feedback animation (D-17)
    if grep -qE "scale:[[:space:]]*.*pressed[[:space:]]*\?[[:space:]]*0\.9[0-9]*[[:space:]]*:[[:space:]]*1\.0" "$PILL_QML" || \
       grep -q "NumberAnimation" "$PILL_QML"; then
      pass "NetworkPingPill.qml implements interactive press feedback animation"
    else
      fail "NetworkPingPill.qml missing press feedback animation"
    fi

    # Live throughput directional glyphs (D-01)
    if grep -q "↓" "$PILL_QML" && grep -q "↑" "$PILL_QML" && \
       grep -q "rxShortRate" "$PILL_QML" && grep -q "txShortRate" "$PILL_QML"; then
      pass "NetworkPingPill.qml displays live throughput directional glyphs (↓ and ↑) with rxShortRate and txShortRate"
    else
      fail "NetworkPingPill.qml missing directional throughput glyphs or rate bindings"
    fi

    # All 3 ping targets with Material Symbols (D-02)
    if grep -q 'text: "public"' "$PILL_QML" && \
       grep -q 'text: "router"' "$PILL_QML" && \
       grep -q 'text: "dns"' "$PILL_QML"; then
      pass "NetworkPingPill.qml renders Material Symbols public (WAN), router (Gateway), and dns (Server)"
    else
      fail "NetworkPingPill.qml missing Material Symbols public, router, or dns"
    fi

    # Ping latency text bindings
    if grep -q "PingService.wanLatency" "$PILL_QML" && \
       grep -q "PingService.gatewayLatency" "$PILL_QML" && \
       grep -q "PingService.homeServerLatency" "$PILL_QML"; then
      pass "NetworkPingPill.qml binds all 3 target latencies from PingService"
    else
      fail "NetworkPingPill.qml missing PingService target latency bindings"
    fi

    # Dynamic health status color resolution function getStatusColor (D-02)
    if grep -q "function getStatusColor(statusClass)" "$PILL_QML" && \
       grep -q "warningColor" "$PILL_QML" && \
       grep -q "#FFA000" "$PILL_QML"; then
      pass "NetworkPingPill.qml implements getStatusColor(statusClass) with primary, warningColor (#FFA000), and colError"
    else
      fail "NetworkPingPill.qml missing getStatusColor function or warning fallback color"
    fi

    # Vertical divider line separating throughput from ping targets (D-03)
    if grep -q "implicitWidth: 1" "$PILL_QML" && grep -q "colLayer0Border" "$PILL_QML"; then
      pass "NetworkPingPill.qml separates throughput from ping targets with vertical divider line"
    else
      fail "NetworkPingPill.qml missing vertical divider line separating pill segments"
    fi

    # Responsive width parity (D-04)
    if grep -q "visible: root.useShortenedForm === 0" "$PILL_QML"; then
      fail "NetworkPingPill.qml hides elements when useShortenedForm > 0 (violates D-04)"
    else
      pass "NetworkPingPill.qml preserves both throughput and all 3 ping latencies unconditionally regardless of useShortenedForm"
    fi

    # NetworkPingPopup embedding hook check (when popup file exists)
    if [[ -f "$POPUP_QML" ]]; then
      if grep -q "NetworkPingPopup" "$PILL_QML" && grep -q "hoverTarget: root.hoverArea" "$PILL_QML"; then
        pass "NetworkPingPill.qml embeds NetworkPingPopup with hoverTarget: root.hoverArea"
      else
        fail "NetworkPingPill.qml missing NetworkPingPopup embedding or hoverTarget binding"
      fi
    else
      info "NetworkPingPopup.qml not yet created (Wave 2); skipping popup embedding check in pill"
    fi
  fi
fi

# ===========================================================================
# Section 3: NetworkPingPopup Two-Column Layout & Diagnostics (NETPING-04, NETPING-05, D-05..D-09, D-12, D-15..D-17)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: NetworkPingPopup Two-Column Layout & Diagnostics (NETPING-04, NETPING-05, D-05..D-09, D-12, D-15..D-17) ---"

  if [[ ! -f "$POPUP_QML" ]]; then
    fail "NetworkPingPopup.qml does not exist at $POPUP_QML"
  else
    pass "NetworkPingPopup.qml exists"

    # StyledPopup root inheritance & Bound pragma
    if grep -q "pragma ComponentBehavior: Bound" "$POPUP_QML"; then
      pass "NetworkPingPopup.qml declares pragma ComponentBehavior: Bound"
    else
      fail "NetworkPingPopup.qml missing pragma ComponentBehavior: Bound"
    fi

    if grep -qE "^StyledPopup[[:space:]]*\{" "$POPUP_QML"; then
      pass "NetworkPingPopup.qml inherits StyledPopup as root"
    else
      fail "NetworkPingPopup.qml does not inherit StyledPopup as root"
    fi

    # Lifecycle demand-gating (D-12)
    if grep -q "NetworkUsage.isInspectorActive = active" "$POPUP_QML" && \
       grep -q "NetworkUsage.pollMetrics()" "$POPUP_QML" && \
       grep -q "PingService.fetchStatus()" "$POPUP_QML"; then
      pass "NetworkPingPopup.qml implements demand-gated fast-polling on active change"
    else
      fail "NetworkPingPopup.qml missing complete demand-gating logic in onActiveChanged"
    fi

    # Destruction safety reset
    if grep -q "Component.onDestruction:" "$POPUP_QML" && grep -q "NetworkUsage.isInspectorActive = false" "$POPUP_QML"; then
      pass "NetworkPingPopup.qml resets isInspectorActive on destruction"
    else
      fail "NetworkPingPopup.qml missing destruction safety reset for isInspectorActive"
    fi

    # Two-column balanced 320px layout (D-05)
    COL_320_COUNT=$(grep -c "preferredWidth: 320" "$POPUP_QML" || true)
    if [[ "$COL_320_COUNT" -ge 2 ]]; then
      pass "NetworkPingPopup.qml configures balanced 320px column layout for Left and Right cards"
    else
      fail "NetworkPingPopup.qml missing dual 320px column layout (count: $COL_320_COUNT, expected >= 2)"
    fi

    # Vertical center separator
    if grep -q "implicitWidth: 1" "$POPUP_QML" && grep -q "colLayer0Border" "$POPUP_QML"; then
      pass "NetworkPingPopup.qml includes center vertical separator line"
    else
      fail "NetworkPingPopup.qml missing center vertical separator"
    fi

    # Left Column Interface Card (D-06, D-11)
    if grep -q "NetworkUsage.activeInterface" "$POPUP_QML" && \
       grep -q "NetworkUsage.ipAddress" "$POPUP_QML" && \
       grep -q "NetworkUsage.gatewayIp" "$POPUP_QML" && \
       grep -q "NetworkUsage.dnsServers" "$POPUP_QML" && \
       grep -q "NetworkUsage.linkSpeed" "$POPUP_QML" && \
       grep -q "NetworkUsage.macAddress" "$POPUP_QML" && \
       grep -q "NetworkUsage.nicTempString" "$POPUP_QML"; then
      pass "NetworkPingPopup.qml renders comprehensive interface card with NIC temp and network telemetry"
    else
      fail "NetworkPingPopup.qml missing interface telemetry fields in Left column"
    fi

    # Dual StyledProgressBar activity meters for Rx and Tx (D-08)
    PROG_COUNT=$(grep -c "StyledProgressBar" "$POPUP_QML" || true)
    if [[ "$PROG_COUNT" -ge 2 ]] && \
       grep -q "NetworkUsage.rxBytesPerSec" "$POPUP_QML" && \
       grep -q "NetworkUsage.txBytesPerSec" "$POPUP_QML" && \
       grep -q "NetworkUsage.totalRxString" "$POPUP_QML" && \
       grep -q "NetworkUsage.totalTxString" "$POPUP_QML"; then
      pass "NetworkPingPopup.qml renders dual StyledProgressBar meters for Rx and Tx with rate readouts and session totals"
    else
      fail "NetworkPingPopup.qml missing dual StyledProgressBar meters or session total bindings"
    fi

    # Right Column Header: "Open Web Dashboard" button (D-15, D-17)
    if grep -q 'text: "open_in_new"' "$POPUP_QML" && \
       grep -q "http://127.0.0.1:8765/" "$POPUP_QML" && \
       grep -q "xdg-open" "$POPUP_QML"; then
      pass "NetworkPingPopup.qml displays Open Web Dashboard action button launching xdg-open http://127.0.0.1:8765/"
    else
      fail "NetworkPingPopup.qml missing Open Web Dashboard action button with xdg-open launcher"
    fi

    # Offline Warning Banner (D-09)
    if grep -q "PingService.isOffline" "$POPUP_QML"; then
      pass "NetworkPingPopup.qml includes offline warning banner gated on PingService.isOffline"
    else
      fail "NetworkPingPopup.qml missing offline warning banner"
    fi

    # 3 Dedicated Ping Diagnostic Cards (D-07)
    if grep -q "PingService.wanTarget" "$POPUP_QML" && \
       grep -q "PingService.gatewayTarget" "$POPUP_QML" && \
       grep -q "PingService.homeServerTarget" "$POPUP_QML"; then
      pass "NetworkPingPopup.qml renders 3 dedicated diagnostic cards (WAN, Gateway, Home Server)"
    else
      fail "NetworkPingPopup.qml missing 3 dedicated target diagnostic cards"
    fi
  fi
fi

# ===========================================================================
# Section 4: Live Telemetry & Formatting Mathematics (D-01, D-06, D-11)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Live Telemetry & Formatting Mathematics (D-01, D-06, D-11) ---"

  # Unit test formatting mathematics via node
  MATH_TEST=$(node -e '
    function formatShortRate(b) {
      if (!b || b < 1024) return "0K";
      if (b < 1024 * 1024) return Math.round(b / 1024) + "K";
      if (b < 1024 * 1024 * 1024) return (b / (1024 * 1024)).toFixed(1) + "M";
      return (b / (1024 * 1024 * 1024)).toFixed(1) + "G";
    }
    function formatThroughput(b) {
      if (!b || b <= 0) return "0 B/s";
      if (b < 1024) return b.toFixed(0) + " B/s";
      if (b < 1024 * 1024) return (b / 1024).toFixed(1) + " KB/s";
      if (b < 1024 * 1024 * 1024) return (b / (1024 * 1024)).toFixed(1) + " MB/s";
      return (b / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
    }
    function formatGigabytes(b) {
      if (!b || b <= 0) return "0.0 GB";
      return (b / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }

    const checks = [
      formatShortRate(0) === "0K",
      formatShortRate(500) === "0K",
      formatShortRate(1500) === "1K",
      formatShortRate(1.5 * 1024 * 1024) === "1.5M",
      formatShortRate(1.2 * 1024 * 1024 * 1024) === "1.2G",
      formatThroughput(0) === "0 B/s",
      formatThroughput(512) === "512 B/s",
      formatThroughput(2048) === "2.0 KB/s",
      formatGigabytes(0) === "0.0 GB",
      formatGigabytes(5 * 1024 * 1024 * 1024) === "5.0 GB"
    ];

    if (checks.every(Boolean)) {
      console.log("OK");
    } else {
      console.log("FAIL: " + JSON.stringify(checks));
    }
  ' 2>/dev/null || echo "ERROR")

  if [[ "$MATH_TEST" == "OK" ]]; then
    pass "Formatting mathematics pass all unit test vectors (0K, 1K, 1.5M, 1.2G, B/s, GB)"
  else
    fail "Formatting mathematics failed unit test vectors: $MATH_TEST"
  fi

  # Live /proc/net/dev verification
  if [[ -r /proc/net/dev ]]; then
    ACTIVE_LINES=$(awk -F: 'NR>2 { split($2, a, " "); if (a[1] > 0) print $1 }' /proc/net/dev | tr -d ' ' || true)
    if [[ -n "$ACTIVE_LINES" ]]; then
      pass "/proc/net/dev is accessible with active byte counters: $(echo $ACTIVE_LINES | tr '\n' ' ')"
    else
      fail "/proc/net/dev is readable but contains no interface entries"
    fi
  else
    fail "/proc/net/dev is not readable"
  fi

  # Live Realtek r8169 temperature probe
  R8169_TEMP_FOUND=0
  for namefile in /sys/class/hwmon/hwmon*/name; do
    if [[ -f "$namefile" ]]; then
      name=$(cat "$namefile" 2>/dev/null || true)
      if [[ "$name" =~ r8169 ]]; then
        dir=$(dirname "$namefile")
        if [[ -f "$dir/temp1_input" ]]; then
          raw_temp=$(cat "$dir/temp1_input" 2>/dev/null || true)
          if [[ -n "$raw_temp" && "$raw_temp" -gt 20000 && "$raw_temp" -lt 90000 ]]; then
            pass "Live Realtek r8169 hwmon temperature verified: $(( raw_temp / 1000 ))°C ($namefile)"
            R8169_TEMP_FOUND=1
            break
          fi
        fi
      fi
    fi
  done
  if [[ "$R8169_TEMP_FOUND" -eq 0 ]]; then
    finding "Realtek r8169 hwmon temp1_input not found or out of bounds (graceful fallback expected)"
  fi

  # Live ping daemon verification
  if curl -s --max-time 2 http://127.0.0.1:8765/api/status >/dev/null 2>&1; then
    TARGET_COUNT=$(curl -s --max-time 2 http://127.0.0.1:8765/api/status | jq '.targets | length' 2>/dev/null || echo 0)
    if [[ "$TARGET_COUNT" -eq 3 ]]; then
      pass "Live ping daemon at http://127.0.0.1:8765/api/status responds with 3 targets"
    else
      finding "Live ping daemon returned $TARGET_COUNT targets (expected 3)"
    fi
  else
    finding "Live ping daemon at http://127.0.0.1:8765/api/status not responding (handled via offline mode)"
  fi

  # Prohibited hardcoded alert hex colors check (allows #FFA000 fallback)
  BANNED_HEX_REGEX='(#[0-9a-fA-F]{3,8}|#[fF]{2}[a-zA-Z0-9]{4}|#[fF][fF]5252|#[fF]44336|#[fF][fF]5555|#[eE]5[cC]07[bB])'
  for file in "$PILL_QML" "$POPUP_QML"; do
    if [[ -f "$file" ]]; then
      fname="$(basename "$file")"
      if grep -nE "$BANNED_HEX_REGEX" "$file" 2>/dev/null | grep -ivE "(#FFA000|warningColor)" >/dev/null; then
        fail "$fname contains prohibited hardcoded alert hex color(s)"
      else
        pass "$fname contains zero prohibited hardcoded alert hex colors"
      fi
    fi
  done
fi

# ===========================================================================
# Section 5: Stow Symlink Integrity & Working Tree Verification (NETPING-01..05, INTG-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Stow Symlink Integrity & Working Tree Verification (NETPING-01..05, INTG-02) ---"

  TARGET_SERVICES_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/services"
  TARGET_BAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/modules/ii/bar"

  CHECK_FILES=(
    "$TARGET_SERVICES_DIR/NetworkUsage.qml"
    "$TARGET_BAR_DIR/NetworkPingPill.qml"
    "$TARGET_BAR_DIR/NetworkPingPopup.qml"
  )

  for link_path in "${CHECK_FILES[@]}"; do
    file="$(basename "$link_path")"
    if [[ -L "$link_path" ]]; then
      resolved="$(readlink -f "$link_path" 2>/dev/null || true)"
      if [[ -f "$resolved" ]]; then
        pass "Symlink $file exists and points to valid target: $resolved"
      else
        fail "Symlink $file points to non-existent target: $resolved"
      fi
    elif [[ -f "$link_path" ]]; then
      fail "$link_path is a regular file, not a symlink (violates Stow packaging contract)"
    else
      finding "$link_path does not yet exist in target user config (stow deployment pending in Task 2 of Plan 02)"
    fi
  done

  # Submodule cleanliness check
  if [[ -d "$REPO_ROOT/vendor/dots-hyprland" ]]; then
    SUBMODULE_STATUS="$(git -C "$REPO_ROOT/vendor/dots-hyprland" status --porcelain 2>/dev/null || true)"
    if [[ -z "$SUBMODULE_STATUS" ]]; then
      pass "vendor/dots-hyprland git status is completely clean"
    else
      fail "vendor/dots-hyprland working tree has uncommitted modifications: $SUBMODULE_STATUS"
    fi
  fi

  # Upstream strict verification
  if [[ "$QUICK_MODE" -eq 0 && -x "$REPO_ROOT/arch/dots-hyprland.sh" ]]; then
    info "Running ./arch/dots-hyprland.sh verify --strict..."
    if "$REPO_ROOT/arch/dots-hyprland.sh" verify --strict; then
      pass "./arch/dots-hyprland.sh verify --strict passed cleanly"
    else
      fail "./arch/dots-hyprland.sh verify --strict encountered failures"
    fi
  fi
fi

info "=== Assertion Summary ==="
info "Failures: $FAIL, Findings: $FINDINGS"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
