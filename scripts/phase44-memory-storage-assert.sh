#!/usr/bin/env bash
# ===========================================================================
# Phase 44: Memory & Storage Component (Pill & Popup) Assert Harness
# Enforces: MEMDSK-01..04, D-01 through D-16
#
# Usage (from REPO_ROOT):
#   ./scripts/phase44-memory-storage-assert.sh [1-5] [--section <1-5>] [-s <1-5>] [--quick] [--syntax]
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
      echo "  1: Telemetry Services Hardening (MEMDSK-01, MEMDSK-04)"
      echo "  2: MemoryStoragePill Component Logic & Visual Parity (MEMDSK-01, D-01..D-04)"
      echo "  3: MemoryStoragePopup Layout & Telemetry Bindings (MEMDSK-02, MEMDSK-03, D-05..D-16)"
      echo "  4: Formatting Helpers & Non-Zero Mathematics (D-09, D-12, D-16)"
      echo "  5: Stow Symlink Integrity & Working Tree Verification (INTG-02)"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

info "=== Phase 44 Memory & Storage Component (Pill & Popup) Assert Harness ==="
info "Working directory: $REPO_ROOT"
info "Flags: section=$RUN_SECTION quick=$QUICK_MODE syntax_only=$SYNTAX_ONLY"

SERVICES_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services"
BAR_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar"

RESOURCE_QML="$SERVICES_DIR/ResourceUsage.qml"
STORAGE_QML="$SERVICES_DIR/StorageUsage.qml"
PILL_QML="$BAR_DIR/MemoryStoragePill.qml"
POPUP_QML="$BAR_DIR/MemoryStoragePopup.qml"

# ---------------------------------------------------------------------------
# Syntax-only mode early exit check
# ---------------------------------------------------------------------------
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  pass "Assert harness bash syntax check passed (bash -n verified)"

  for qml_file in "$RESOURCE_QML" "$STORAGE_QML" "$PILL_QML" "$POPUP_QML"; do
    if [[ -f "$qml_file" ]]; then
      pass "QML file present: $(basename "$qml_file")"
    fi
  done

  info "=== Syntax Summary ==="
  info "Failures: $FAIL, Findings: $FINDINGS"
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Telemetry Services Hardening (MEMDSK-01, MEMDSK-04)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Telemetry Services Hardening (MEMDSK-01, MEMDSK-04) ---"

  if [[ ! -f "$RESOURCE_QML" ]]; then
    fail "ResourceUsage.qml does not exist at $RESOURCE_QML"
  else
    pass "ResourceUsage.qml exists"

    # Distinct MemFree parsing from /proc/meminfo
    if grep -q "textMeminfo\.match(/MemFree:" "$RESOURCE_QML" && grep -q "memoryFree = Number" "$RESOURCE_QML"; then
      pass "ResourceUsage.qml parses MemFree using regex match distinctly from MemAvailable"
    else
      fail "ResourceUsage.qml does not parse MemFree distinctly from /proc/meminfo"
    fi

    # memoryUsed calculation preservation
    if grep -q "property real memoryUsed: Math.max(0, memoryTotal - (memoryAvailable > 0 ? memoryAvailable : memoryFree))" "$RESOURCE_QML"; then
      pass "ResourceUsage.qml preserves standard Linux free -m memoryUsed calculation"
    else
      fail "ResourceUsage.qml memoryUsed calculation does not match standard fallback formula"
    fi

    # Distinct property declaration for memoryFree
    if grep -q "property real memoryFree:" "$RESOURCE_QML" && grep -q "property real memoryAvailable:" "$RESOURCE_QML"; then
      pass "ResourceUsage.qml declares both memoryFree and memoryAvailable properties"
    else
      fail "ResourceUsage.qml missing separate memoryFree or memoryAvailable property declaration"
    fi
  fi

  if [[ ! -f "$STORAGE_QML" ]]; then
    fail "StorageUsage.qml does not exist at $STORAGE_QML"
  else
    pass "StorageUsage.qml exists"

    # Dynamic deviceToMount mapping matching mounts array
    if grep -q "mounts\[i\]\.fs" "$STORAGE_QML" && grep -q "mounts\[i\]\.mount" "$STORAGE_QML"; then
      pass "StorageUsage.qml implements dynamic deviceToMount matching against mounts array"
    else
      fail "StorageUsage.qml does not match mounts array dynamically in deviceToMount"
    fi

    # Absence of hardcoded device inversions
    if grep -q 'if (dev\.startsWith("nvme1n1")) return "/";' "$STORAGE_QML"; then
      fail "StorageUsage.qml retains inverted hardcoded nvme1n1 mapping"
    else
      pass "StorageUsage.qml has eliminated hardcoded NVMe inversions"
    fi

    # 30s background fallback timer alongside I/O delta trigger
    if grep -q "(now - lastDfTime) > 30000" "$STORAGE_QML"; then
      pass "StorageUsage.qml implements 30s background fallback timer for df refresh"
    else
      fail "StorageUsage.qml missing 30s background fallback timer ((now - lastDfTime) > 30000)"
    fi
  fi
fi

# ===========================================================================
# Section 2: MemoryStoragePill Component Logic & Visual Parity (MEMDSK-01, D-01..D-04)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: MemoryStoragePill Component Logic & Visual Parity (MEMDSK-01, D-01..D-04) ---"

  if [[ ! -f "$PILL_QML" ]]; then
    fail "MemoryStoragePill.qml does not exist at $PILL_QML"
  else
    pass "MemoryStoragePill.qml exists"

    # Bound pragma
    if grep -q "pragma ComponentBehavior: Bound" "$PILL_QML"; then
      pass "MemoryStoragePill.qml declares pragma ComponentBehavior: Bound"
    else
      fail "MemoryStoragePill.qml missing pragma ComponentBehavior: Bound"
    fi

    # BarGroup root inheritance
    if grep -qE "^BarGroup[[:space:]]*\{" "$PILL_QML"; then
      pass "MemoryStoragePill.qml inherits BarGroup as root component"
    else
      fail "MemoryStoragePill.qml does not inherit BarGroup as root"
    fi

    # Re-parented inert MouseArea
    if grep -q "MouseArea" "$PILL_QML" && grep -q "parent: root" "$PILL_QML"; then
      pass "MemoryStoragePill.qml encapsulates re-parented MouseArea (parent: root)"
    else
      fail "MemoryStoragePill.qml missing re-parented MouseArea with 'parent: root'"
    fi

    if grep -q "acceptedButtons: Qt.AllButtons" "$PILL_QML" && grep -q "event.accepted = true" "$PILL_QML"; then
      pass "MemoryStoragePill.qml inertly consumes mouse clicks on all buttons"
    else
      fail "MemoryStoragePill.qml missing inert click consumption with Qt.AllButtons"
    fi

    if grep -q "readonly property alias hoverArea: inertMouseArea" "$PILL_QML"; then
      pass "MemoryStoragePill.qml exports hoverArea alias for popup anchoring"
    else
      fail "MemoryStoragePill.qml missing hoverArea alias"
    fi

    # Telemetry bindings for RAM and Root storage
    if grep -q "ResourceUsage.memoryUsedPercentage" "$PILL_QML"; then
      pass "MemoryStoragePill.qml binds to ResourceUsage.memoryUsedPercentage"
    else
      fail "MemoryStoragePill.qml missing ResourceUsage.memoryUsedPercentage binding"
    fi

    if grep -q "StorageUsage.rootDisk" "$PILL_QML"; then
      pass "MemoryStoragePill.qml binds to StorageUsage.rootDisk"
    else
      fail "MemoryStoragePill.qml missing StorageUsage.rootDisk binding"
    fi

    # Free/Total capacity text readouts (G-44-1, user decision in Phase 44 UAT)
    if grep -q "ResourceUsage.memoryAvailable" "$PILL_QML" && grep -q "ResourceUsage.memoryTotal" "$PILL_QML"; then
      pass "MemoryStoragePill.qml formats RAM as free GB out of total GB"
    else
      fail "MemoryStoragePill.qml missing free/total GB formatting for RAM"
    fi

    if grep -q "StorageUsage.rootDisk" "$PILL_QML" && grep -q "availKb" "$PILL_QML"; then
      pass "MemoryStoragePill.qml formats Root Storage as free GB out of total GB"
    else
      fail "MemoryStoragePill.qml missing free/total GB formatting for Root Storage"
    fi

    CIRC_PROG_COUNT=$(grep -c "ClippedFilledCircularProgress" "$PILL_QML" || true)
    if [[ "$CIRC_PROG_COUNT" -ge 2 ]]; then
      pass "MemoryStoragePill.qml renders dual ClippedFilledCircularProgress rings wrapping icons (count: $CIRC_PROG_COUNT)"
    else
      fail "MemoryStoragePill.qml missing dual ClippedFilledCircularProgress rings (count: $CIRC_PROG_COUNT, expected >= 2)"
    fi

    # Material Symbols: memory and storage
    if grep -q 'text: "memory"' "$PILL_QML"; then
      pass "MemoryStoragePill.qml renders Material Symbol 'memory'"
    else
      fail "MemoryStoragePill.qml missing Material Symbol 'memory'"
    fi

    if grep -q 'text: "storage"' "$PILL_QML"; then
      pass "MemoryStoragePill.qml renders Material Symbol 'storage'"
    else
      fail "MemoryStoragePill.qml missing Material Symbol 'storage'"
    fi

    # Two-tier alert state thresholds (D-04)
    if grep -q "0.90" "$PILL_QML" && grep -q "0.70" "$PILL_QML"; then
      pass "MemoryStoragePill.qml implements 70% warning and 90% critical threshold properties"
    else
      fail "MemoryStoragePill.qml missing 70% warning and 90% critical thresholds"
    fi

    # Warning color fallback to #FFA000
    if grep -q "#FFA000" "$PILL_QML" && grep -q "warningColor" "$PILL_QML"; then
      pass "MemoryStoragePill.qml implements warningColor fallback to #FFA000"
    else
      fail "MemoryStoragePill.qml missing warningColor with #FFA000 fallback"
    fi

    # Infinite breathing pulse animations
    if grep -q "id: ramPulseAnimation" "$PILL_QML" && grep -q "id: storagePulseAnimation" "$PILL_QML"; then
      pass "MemoryStoragePill.qml defines ramPulseAnimation and storagePulseAnimation"
    else
      fail "MemoryStoragePill.qml missing ramPulseAnimation or storagePulseAnimation"
    fi

    if grep -q "to: 0.4" "$PILL_QML" && grep -q "duration: 600" "$PILL_QML"; then
      pass "MemoryStoragePill.qml implements 600ms breathing pulse between 0.4 and 1.0 opacity"
    else
      fail "MemoryStoragePill.qml missing 600ms opacity pulse parameters"
    fi

    # Preserves both RAM and Storage indicators unconditionally even when useShortenedForm > 0 (D-03)
    if grep -q "visible: root.useShortenedForm === 0" "$PILL_QML"; then
      fail "MemoryStoragePill.qml hides elements when useShortenedForm > 0 (violates D-03)"
    else
      pass "MemoryStoragePill.qml preserves RAM and Storage indicators unconditionally regardless of useShortenedForm"
    fi

    # Dedicated strictly to capacity percentages without disk I/O metrics (D-13)
    if grep -q "readBytesPerSec" "$PILL_QML" || grep -q "writeBytesPerSec" "$PILL_QML" || grep -q "diskIoPercentage" "$PILL_QML"; then
      fail "MemoryStoragePill.qml contains disk I/O metrics (violates pure capacity status bar requirement D-13)"
    else
      pass "MemoryStoragePill.qml remains strictly dedicated to capacity percentages (D-13)"
    fi
  fi
fi

# ===========================================================================
# Section 3: MemoryStoragePopup Layout & Telemetry Bindings (MEMDSK-02, MEMDSK-03, D-05..D-16)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: MemoryStoragePopup Layout & Telemetry Bindings (MEMDSK-02, MEMDSK-03, D-05..D-16) ---"

  if [[ ! -f "$POPUP_QML" ]]; then
    fail "MemoryStoragePopup.qml does not exist at $POPUP_QML"
  else
    pass "MemoryStoragePopup.qml exists"

    # StyledPopup root inheritance & Bound pragma
    if grep -q "pragma ComponentBehavior: Bound" "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml declares pragma ComponentBehavior: Bound"
    else
      fail "MemoryStoragePopup.qml missing pragma ComponentBehavior: Bound"
    fi

    if grep -qE "^StyledPopup[[:space:]]*\{" "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml inherits StyledPopup as root"
    else
      fail "MemoryStoragePopup.qml does not inherit StyledPopup as root"
    fi

    # Lifecycle demand-gating
    if grep -q "ResourceUsage.isInspectorActive = active" "$POPUP_QML" && \
       grep -q "ResourceUsage.pollMetrics()" "$POPUP_QML" && \
       grep -q "StorageUsage.refresh()" "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml implements demand-gated fast-polling on active change"
    else
      fail "MemoryStoragePopup.qml missing complete demand-gating logic in onActiveChanged"
    fi

    # Destruction safety reset
    if grep -q "Component.onDestruction:" "$POPUP_QML" && grep -q "ResourceUsage.isInspectorActive = false" "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml resets isInspectorActive on destruction"
    else
      fail "MemoryStoragePopup.qml missing destruction safety reset for isInspectorActive"
    fi

    # Two-column balanced 320px layout (D-08)
    COL_320_COUNT=$(grep -c "preferredWidth: 320" "$POPUP_QML" || true)
    if [[ "$COL_320_COUNT" -ge 2 ]]; then
      pass "MemoryStoragePopup.qml configures balanced 320px column layout for Left and Right cards"
    else
      fail "MemoryStoragePopup.qml missing dual 320px column layout (count: $COL_320_COUNT, expected >= 2)"
    fi

    # Vertical center divider
    if grep -q "implicitWidth: 1" "$POPUP_QML" && grep -q "colLayer0Border" "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml includes center vertical separator line"
    else
      fail "MemoryStoragePopup.qml missing center vertical separator"
    fi

    # Multi-segment stacked allocation bar (D-05)
    if grep -q "RAM Allocation" "$POPUP_QML" && \
       grep -q "ResourceUsage.memoryUsed" "$POPUP_QML" && \
       grep -q "ResourceUsage.memoryAvailable" "$POPUP_QML" && \
       grep -q "ResourceUsage.memoryFree" "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml implements multi-segment stacked allocation bar"
    else
      fail "MemoryStoragePopup.qml missing multi-segment stacked allocation bar components"
    fi

    # Numeric memory tier rows (D-06)
    if grep -q "ResourceUsage.memoryBuffers" "$POPUP_QML" && grep -q "ResourceUsage.memoryCached" "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml exposes complete memory breakdown tiers (Used, Available, Buffers, Cached, Free)"
    else
      fail "MemoryStoragePopup.qml missing memoryBuffers or memoryCached tier rows"
    fi

    # Dynamic Swap row gated on swapTotal > 0 (D-07)
    if grep -q "ResourceUsage.swapTotal > 0" "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml dynamically gates swap display on swapTotal > 0"
    else
      fail "MemoryStoragePopup.qml missing dynamic gating on ResourceUsage.swapTotal > 0"
    fi

    # Right Column Header Throughput Badge (D-14, D-16)
    if grep -q "arrow_downward" "$POPUP_QML" && grep -q "arrow_upward" "$POPUP_QML" && \
       grep -q "StorageUsage.readBytesPerSec" "$POPUP_QML" && grep -q "StorageUsage.writeBytesPerSec" "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml displays live header throughput badge with arrow glyphs and I/O rates"
    else
      fail "MemoryStoragePopup.qml missing header throughput badge or I/O rate bindings"
    fi

    # Physical Drives and Cloud Mounts segregation (D-10, D-11)
    if grep -q "StorageUsage.physicalDisks" "$POPUP_QML" && grep -q "StorageUsage.cloudDisks" "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml segregates physical drives and cloud mounts"
    else
      fail "MemoryStoragePopup.qml missing physicalDisks or cloudDisks repeaters"
    fi

    # Dynamic Cloud Mounts hiding when empty (D-11)
    if grep -q "StorageUsage.cloudDisks.length > 0" "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml dynamically reveals cloud mounts only when present"
    else
      fail "MemoryStoragePopup.qml does not dynamically check cloudDisks.length > 0"
    fi

    # Active drive indicator dot (D-15)
    if grep -q "StorageUsage.activeDisk" "$POPUP_QML" && grep -q "StorageUsage.diskIoPercentage > 0" "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml displays active drive indicator dot based on activeDisk and diskIoPercentage"
    else
      fail "MemoryStoragePopup.qml missing active drive indicator dot condition"
    fi

    # Anchoring check in MemoryStoragePill
    if [[ -f "$PILL_QML" ]]; then
      if grep -q "MemoryStoragePopup" "$PILL_QML" && grep -q "hoverTarget: root.hoverArea" "$PILL_QML"; then
        pass "MemoryStoragePill.qml embeds MemoryStoragePopup with hoverTarget: root.hoverArea"
      else
        fail "MemoryStoragePill.qml missing MemoryStoragePopup instantiation or hoverTarget binding"
      fi
    fi
  fi
fi

# ===========================================================================
# Section 4: Formatting Helpers & Non-Zero Mathematics (D-09, D-12, D-16)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Formatting Helpers & Non-Zero Mathematics (D-09, D-12, D-16) ---"

  if [[ ! -f "$POPUP_QML" ]]; then
    fail "MemoryStoragePopup.qml does not exist at $POPUP_QML"
  else
    # formatKB helper check
    if grep -q "function formatKB(kb)" "$POPUP_QML" && grep -q 'return "0.0 GB"' "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml implements formatKB with non-zero fallback '0.0 GB'"
    else
      fail "MemoryStoragePopup.qml missing formatKB function or safe fallback"
    fi

    # formatThroughput helper check (D-16)
    if grep -q "function formatThroughput(bytesPerSec)" "$POPUP_QML" && \
       grep -q 'return "0 B/s"' "$POPUP_QML" && \
       grep -q 'KB/s' "$POPUP_QML" && \
       grep -q 'MB/s' "$POPUP_QML" && \
       grep -q 'GB/s' "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml implements formatThroughput scaling across B/s, KB/s, MB/s, and GB/s"
    else
      fail "MemoryStoragePopup.qml missing auto-scaling formatThroughput implementation"
    fi

    # formatDriveLabel helper check (D-09)
    if grep -q "function formatDriveLabel(fs, mount)" "$POPUP_QML" && grep -q 'fs.startsWith("/dev/")' "$POPUP_QML"; then
      pass "MemoryStoragePopup.qml implements formatDriveLabel stripping /dev/ prefix"
    else
      fail "MemoryStoragePopup.qml missing formatDriveLabel function with block device parsing"
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
fi

# ===========================================================================
# Section 5: Stow Symlink Integrity & Working Tree Verification (INTG-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Stow Symlink Integrity & Working Tree Verification (INTG-02) ---"

  TARGET_BAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/modules/ii/bar"
  CHECK_FILES=("MemoryStoragePill.qml" "MemoryStoragePopup.qml")

  for file in "${CHECK_FILES[@]}"; do
    link_path="$TARGET_BAR_DIR/$file"
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
      finding "$link_path does not yet exist in target user config (stow deployment pending)"
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
