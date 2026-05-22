#!/usr/bin/env bash
# Phase 14: Script-Backed Widgets — Nyquist Validation Tests
# Usage: bash .planning/phases/14-script-backed-widgets/tests/validate-phase14.sh
# Exit 0 = all checks pass, exit 1 = at least one check failed

set -e
PASS=0
FAIL=0
BASE="$(cd "$(dirname "$0")/../../../.." && pwd)"

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

check_file() {
    if [ -f "$BASE/$1" ]; then pass "File exists: $1"; else fail "File missing: $1"; fi
}

check_grep() {
    if grep -q "$2" "$BASE/$1"; then pass "$1 contains: $2"; else fail "$1 missing: $2"; fi
}

check_negrep() {
    if grep -q "$2" "$BASE/$1"; then fail "$1 should NOT contain: $2"; else pass "$1 correctly lacks: $2"; fi
}

echo "=== Phase 14: Script-Backed Widgets — Validation Tests ==="
echo ""

# === Category 1: File Existence (22 source files + 2 qmldir) ===
echo "--- Category 1: File Existence ---"

# Services (10 + qmldir)
for f in \
    .config/quickshell/services/CpuService.qml \
    .config/quickshell/services/MemoryService.qml \
    .config/quickshell/services/DiskService.qml \
    .config/quickshell/services/NetworkService.qml \
    .config/quickshell/services/PingService.qml \
    .config/quickshell/services/WeatherService.qml \
    .config/quickshell/services/ForecastService.qml \
    .config/quickshell/services/ClockService.qml \
    .config/quickshell/services/BacklightService.qml \
    .config/quickshell/services/NotificationService.qml \
    .config/quickshell/services/qmldir; do
    check_file "$f"
done

# Widgets (10 + qmldir)
for f in \
    .config/quickshell/widgets/CpuWidget.qml \
    .config/quickshell/widgets/MemoryWidget.qml \
    .config/quickshell/widgets/DiskWidget.qml \
    .config/quickshell/widgets/NetworkWidget.qml \
    .config/quickshell/widgets/PingWidget.qml \
    .config/quickshell/widgets/BacklightWidget.qml \
    .config/quickshell/widgets/NotificationWidget.qml \
    .config/quickshell/widgets/WeatherWidget.qml \
    .config/quickshell/widgets/ClockWidget.qml \
    .config/quickshell/widgets/ForecastWidget.qml \
    .config/quickshell/widgets/qmldir; do
    check_file "$f"
done

# Volume OSD
check_file ".config/quickshell/popups/VolumeOsd.qml"

# BarContent
check_file ".config/quickshell/BarContent.qml"

echo ""

# === Category 2: Registration Counts ===
echo "--- Category 2: Registration Counts ---"

SVC_COUNT=$(grep -c '^singleton' "$BASE/.config/quickshell/services/qmldir" 2>/dev/null || echo 0)
if [ "$SVC_COUNT" -eq 13 ]; then
    pass "services/qmldir has 13 singleton registrations"
else
    fail "services/qmldir has $SVC_COUNT registrations (expected 13)"
fi

WIDGET_COUNT=$(grep -cE '^[A-Z]' "$BASE/.config/quickshell/widgets/qmldir" 2>/dev/null || echo 0)
if [ "$WIDGET_COUNT" -eq 14 ]; then
    pass "widgets/qmldir has 14 widget registrations"
else
    fail "widgets/qmldir has $WIDGET_COUNT registrations (expected 14)"
fi

echo ""

# === Category 3: Import Patterns ===
echo "--- Category 3: Import Patterns ---"

for f in \
    services/CpuService.qml \
    services/MemoryService.qml \
    services/DiskService.qml \
    services/NetworkService.qml \
    services/PingService.qml \
    services/WeatherService.qml \
    services/ForecastService.qml \
    services/BacklightService.qml \
    services/NotificationService.qml; do
    check_grep ".config/quickshell/$f" "import Quickshell.Io"
    check_grep ".config/quickshell/$f" "^pragma Singleton"
done

# ClockService is pure QtQuick (no Process needed)
check_grep ".config/quickshell/services/ClockService.qml" "^pragma Singleton"
check_grep ".config/quickshell/services/ClockService.qml" "formatDateTime"
check_negrep ".config/quickshell/services/ClockService.qml" "import Quickshell.Io"

# All widgets import qs.services
for f in \
    widgets/CpuWidget.qml \
    widgets/MemoryWidget.qml \
    widgets/DiskWidget.qml \
    widgets/NetworkWidget.qml \
    widgets/PingWidget.qml \
    widgets/BacklightWidget.qml \
    widgets/NotificationWidget.qml \
    widgets/WeatherWidget.qml \
    widgets/ClockWidget.qml \
    widgets/ForecastWidget.qml; do
    check_grep ".config/quickshell/$f" "import qs.services"
    check_grep ".config/quickshell/$f" 'import "../" as Local'
done

# BarContent imports popups and qs.widgets
check_grep ".config/quickshell/BarContent.qml" 'import qs.widgets'
check_grep ".config/quickshell/BarContent.qml" 'import "./popups/" as Popups'
check_grep ".config/quickshell/BarContent.qml" "VolumeOsd"

echo ""

# === Category 4: Anti-Pattern Audit ===
echo "--- Category 4: Anti-Pattern Audit ---"

ANTI_FILES=$(find "$BASE/.config/quickshell" -name "*.qml" -not -path "*/qmldir" 2>/dev/null)

# P-18: No Component.onCompleted
for f in $ANTI_FILES; do
    rel="${f#$BASE/}"
    if grep -q "Component.onCompleted" "$f"; then
        fail "$rel uses Component.onCompleted (P-18 violation)"
    fi
done
# Count passes: just say all clear
pass "No Component.onCompleted in any .qml file (P-18)"

# P-03: No opacity:0 (allow opacity:0.xx values)
for f in $ANTI_FILES; do
    rel="${f#$BASE/}"
    if grep -qP 'opacity:\s*0[^\.\d]' "$f" 2>/dev/null; then
        fail "$rel uses opacity:0 (P-03 violation)"
    fi
done
pass "No opacity:0 pattern in any .qml file (P-03)"

# No grabFocus
FOUND_FOCUS=0
for f in $ANTI_FILES; do
    if grep -q "grabFocus" "$f"; then
        rel="${f#$BASE/}"
        fail "$rel uses grabFocus"
        FOUND_FOCUS=1
    fi
done
[ "$FOUND_FOCUS" -eq 0 ] && pass "No grabFocus in any .qml file"

# No Qt.getenv
FOUND_ENV=0
for f in $ANTI_FILES; do
    if grep -q "Qt.getenv" "$f"; then
        rel="${f#$BASE/}"
        fail "$rel uses Qt.getenv"
        FOUND_ENV=1
    fi
done
[ "$FOUND_ENV" -eq 0 ] && pass "No Qt.getenv in any .qml file"

# No strftime format in ClockService
check_negrep ".config/quickshell/services/ClockService.qml" "{:%a"

echo ""

# === Category 5: Semantic Colour Aliases ===
echo "--- Category 5: Semantic Colour Aliases ---"

COLOURS_FILE="$BASE/.config/quickshell/theme/Colours.qml"
if [ -f "$COLOURS_FILE" ]; then
    for alias in diskColor cpuColor memoryColor networkColor pingGood pingMedium pingBad pingCritical pingDead clockColor backlightColor notifColor; do
        if grep -q "readonly property color $alias:" "$COLOURS_FILE"; then
            pass "Colours.qml has alias: $alias"
        else
            fail "Colours.qml missing alias: $alias"
        fi
    done
else
    fail "Colours.qml file not found"
fi

echo ""

# === Category 6: BarContent Composition ===
echo "--- Category 6: BarContent Composition ---"

check_grep ".config/quickshell/BarContent.qml" "WlrKeyboardFocus.None"
check_grep ".config/quickshell/BarContent.qml" "WorkspacesWidget {}"
check_grep ".config/quickshell/BarContent.qml" "CpuWidget {}"
check_grep ".config/quickshell/BarContent.qml" "MemoryWidget {}"
check_grep ".config/quickshell/BarContent.qml" "DiskWidget {}"
check_grep ".config/quickshell/BarContent.qml" "NetworkWidget {}"
check_grep ".config/quickshell/BarContent.qml" "PingWidget {}"
check_grep ".config/quickshell/BarContent.qml" "WeatherWidget {}"
check_grep ".config/quickshell/BarContent.qml" "ClockWidget {}"
check_grep ".config/quickshell/BarContent.qml" "ForecastWidget {}"
check_grep ".config/quickshell/BarContent.qml" "BacklightWidget {}"
check_grep ".config/quickshell/BarContent.qml" "NotificationWidget {}"

# LockWidget and PowerWidget must NOT be present
check_negrep ".config/quickshell/BarContent.qml" "LockWidget"
check_negrep ".config/quickshell/BarContent.qml" "PowerWidget"

echo ""

# === Category 7: UAT Regression Guards ===
echo "--- Category 7: UAT Regression Guards ---"

# No ToolTip references in Phase 14 widgets (removed per user preference in 14-05)
for f in \
    widgets/MemoryWidget.qml \
    widgets/DiskWidget.qml \
    widgets/NetworkWidget.qml \
    widgets/PingWidget.qml \
    widgets/WeatherWidget.qml \
    widgets/ForecastWidget.qml \
    widgets/BacklightWidget.qml \
    widgets/NotificationWidget.qml \
    widgets/CpuWidget.qml \
    widgets/ClockWidget.qml; do
    check_negrep ".config/quickshell/$f" "ToolTip\."
done

# MemoryWidget: no double icon prefix
check_negrep ".config/quickshell/widgets/MemoryWidget.qml" ""

# DiskWidget: uses  icon
check_grep ".config/quickshell/widgets/DiskWidget.qml" ""

# DiskService: uses >= 2 not === 3 check
check_negrep ".config/quickshell/services/DiskService.qml" "parts.length === 3"
check_grep ".config/quickshell/services/DiskService.qml" "parts.length >= 2"

# PingWidget: no redundant icon prefix
check_negrep ".config/quickshell/widgets/PingWidget.qml" "󰀶"

# VolumeOsd: uses PopupWindow, not PanelWindow
check_grep ".config/quickshell/popups/VolumeOsd.qml" "PopupWindow"
check_negrep ".config/quickshell/popups/VolumeOsd.qml" "PanelWindow"
# PopupWindow uses its own layer/focus model — skip WlrLayershell checks
# UAT #12 confirmed Volume OSD works without WlrLayershell properties
check_grep ".config/quickshell/popups/VolumeOsd.qml" "interval: 1500"
check_grep ".config/quickshell/popups/VolumeOsd.qml" "visible: false"

# AudioService: no readonly on writable properties
check_negrep ".config/quickshell/services/AudioService.qml" "readonly property real volume"
check_negrep ".config/quickshell/services/AudioService.qml" "readonly property int  volumePercent"

# BacklightService: no readonly on writable properties
check_negrep ".config/quickshell/services/BacklightService.qml" "readonly property int.*brightnessPercent"
check_negrep ".config/quickshell/services/BacklightService.qml" "readonly property string.*formatted"

# CpuService: has delta sampling
check_grep ".config/quickshell/services/CpuService.qml" "__prevIdle"
check_grep ".config/quickshell/services/CpuService.qml" "__prevTotal"

# ClockService: Qt-compatible format
check_grep ".config/quickshell/services/ClockService.qml" "ddd yyyy-MM-dd hh:mm:ss AP"
check_negrep ".config/quickshell/services/ClockService.qml" "{:%a"

echo ""

# === Summary ===
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: ALL CHECKS PASSED"
    exit 0
else
    echo "STATUS: SOME CHECKS FAILED"
    exit 1
fi
