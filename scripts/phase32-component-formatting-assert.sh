#!/usr/bin/env bash
# Phase 32: Component Representation & Formatting Customization Assert Harness
# Enforces: COMP-01 through COMP-10, D-01 through D-20, INTG-02
#
# Usage (from REPO_ROOT):
#   ./scripts/phase32-component-formatting-assert.sh [--section <1-4>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

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

PORCELAIN_BEFORE="$(mktemp /tmp/p32-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p32-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Tier 1 Native JSON Configuration Integrity
# (COMP-03, COMP-05, COMP-06, COMP-09, D-05, D-06, D-07, D-17, D-19, D-20)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Tier 1 Native JSON Configuration Integrity ---"

  REPO_CFG="$REPO_ROOT/capture/ii/.config/illogical-impulse/config.json"
  LIVE_CFG="$HOME/.config/illogical-impulse/config.json"

  # 1. Validate JSON syntax with jq empty
  if [[ -f "$REPO_CFG" ]] && jq empty "$REPO_CFG" 2>/dev/null; then
    pass "S1: $REPO_CFG exists and is valid JSON"
  else
    fail "S1: $REPO_CFG is missing or contains invalid JSON syntax"
  fi

  if [[ -f "$LIVE_CFG" ]] && jq empty "$LIVE_CFG" 2>/dev/null; then
    pass "S1: $LIVE_CFG exists and is valid JSON"
  else
    fail "S1: $LIVE_CFG is missing or contains invalid JSON syntax"
  fi

  # 2. Time & Date format asserts (D-06, D-07, COMP-03)
  if [[ -f "$REPO_CFG" ]]; then
    time_fmt="$(jq -r '.time.format // empty' "$REPO_CFG" 2>/dev/null || true)"
    time_sec="$(jq -r '.time.secondPrecision // empty' "$REPO_CFG" 2>/dev/null || true)"
    date_fmt="$(jq -r '.time.dateFormat // empty' "$REPO_CFG" 2>/dev/null || true)"

    if [[ "$time_fmt" == "hh:mm:ss AP" ]]; then
      pass "S1: time.format is 'hh:mm:ss AP' (D-06, COMP-03)"
    else
      fail "S1: time.format is '$time_fmt', expected 'hh:mm:ss AP'"
    fi

    if [[ "$time_sec" == "true" ]]; then
      pass "S1: time.secondPrecision is true (D-06, COMP-03)"
    else
      fail "S1: time.secondPrecision is '$time_sec', expected true"
    fi

    if [[ "$date_fmt" == "ddd, dd-MM-yyyy" ]]; then
      pass "S1: time.dateFormat is 'ddd, dd-MM-yyyy' (D-07, COMP-03)"
    else
      fail "S1: time.dateFormat is '$date_fmt', expected 'ddd, dd-MM-yyyy'"
    fi
  fi

  # 3. Utility Buttons suite asserts (D-17, COMP-06)
  if [[ -f "$REPO_CFG" ]]; then
    rec_btn="$(jq -r '.bar.utilButtons.showScreenRecord // empty' "$REPO_CFG" 2>/dev/null || true)"
    snip_btn="$(jq -r '.bar.utilButtons.showScreenSnip // empty' "$REPO_CFG" 2>/dev/null || true)"
    cp_btn="$(jq -r '.bar.utilButtons.showColorPicker // empty' "$REPO_CFG" 2>/dev/null || true)"

    if [[ "$rec_btn" == "true" ]]; then
      pass "S1: bar.utilButtons.showScreenRecord is true (D-17, COMP-06)"
    else
      fail "S1: bar.utilButtons.showScreenRecord is '$rec_btn', expected true"
    fi

    if [[ "$snip_btn" == "true" && "$cp_btn" == "true" ]]; then
      pass "S1: bar.utilButtons.showScreenSnip and showColorPicker are true (COMP-06)"
    else
      fail "S1: utility buttons suite missing showScreenSnip or showColorPicker"
    fi
  fi

  # 4. Weather representation asserts (D-19, COMP-05)
  if [[ -f "$REPO_CFG" ]]; then
    w_city="$(jq -r '.bar.weather.city // empty' "$REPO_CFG" 2>/dev/null || true)"
    w_uscs="$(jq -r '.bar.weather.useUSCS // empty' "$REPO_CFG" 2>/dev/null || true)"

    if [[ "$w_city" == "Dhaka" ]]; then
      pass "S1: bar.weather.city is 'Dhaka' (D-19, COMP-05)"
    else
      fail "S1: bar.weather.city is '$w_city', expected 'Dhaka'"
    fi

    if [[ "$w_uscs" == "false" ]]; then
      pass "S1: bar.weather.useUSCS is false (metric Celsius) (D-19, COMP-05)"
    else
      fail "S1: bar.weather.useUSCS is '$w_uscs', expected false"
    fi
  fi

  # 5. Base Resource Thresholds asserts (D-05, COMP-01, COMP-02)
  if [[ -f "$REPO_CFG" ]]; then
    mem_thresh="$(jq -r '.bar.resources.memoryWarningThreshold // empty' "$REPO_CFG" 2>/dev/null || true)"
    cpu_thresh="$(jq -r '.bar.resources.cpuWarningThreshold // empty' "$REPO_CFG" 2>/dev/null || true)"
    swap_thresh="$(jq -r '.bar.resources.swapWarningThreshold // empty' "$REPO_CFG" 2>/dev/null || true)"

    if [[ "$mem_thresh" == "80" && "$cpu_thresh" == "60" && "$swap_thresh" == "70" ]]; then
      pass "S1: bar.resources warning thresholds RAM 80%, CPU 60%, Swap 70% (D-05, COMP-01, COMP-02)"
    else
      fail "S1: bar.resources thresholds mismatch (mem: $mem_thresh, cpu: $cpu_thresh, swap: $swap_thresh)"
    fi
  fi

  # 6. Sidebar active customizations preservation asserts
  if [[ -f "$REPO_CFG" ]]; then
    bright="$(jq -r '.sidebar.quickSliders.showBrightness // empty' "$REPO_CFG" 2>/dev/null || true)"
    toggle_count="$(jq -r '.sidebar.quickToggles.android.toggles | length // 0' "$REPO_CFG" 2>/dev/null || true)"

    if [[ "$bright" == "true" ]]; then
      pass "S1: sidebar.quickSliders.showBrightness is true (live state preserved)"
    else
      fail "S1: sidebar.quickSliders.showBrightness is '$bright', expected true"
    fi

    if [[ "$toggle_count" -ge 10 ]]; then
      pass "S1: sidebar.quickToggles.android.toggles preserves custom toggles (count: $toggle_count >= 10)"
    else
      fail "S1: sidebar.quickToggles.android.toggles count ($toggle_count) < 10"
    fi
  fi

  # 7. Dual synchronization assert (capture/ii matches ~/.config/illogical-impulse)
  if [[ -f "$REPO_CFG" && -f "$LIVE_CFG" ]]; then
    if cmp -s "$REPO_CFG" "$LIVE_CFG"; then
      pass "S1: $REPO_CFG and $LIVE_CFG are byte-identical"
    else
      fail "S1: $REPO_CFG and $LIVE_CFG differ (out of sync)"
    fi
  fi
fi

# ===========================================================================
# Section 2: System Resources Overlays & Symlinks (COMP-01, COMP-02, D-01..D-05)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: System Resources Overlays & Symlinks ---"

  QS_ROOT="$HOME/.config/quickshell/ii"

  # 1. Assert leaf symlinks
  for mod in Resource.qml Resources.qml; do
    live_path="$QS_ROOT/modules/ii/bar/$mod"
    repo_target="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/$mod"

    if [[ -L "$live_path" ]]; then
      actual_target="$(readlink -f "$live_path")"
      expected_target="$(readlink -f "$repo_target")"
      if [[ "$actual_target" == "$expected_target" ]]; then
        pass "S2: $live_path is leaf symlink to $repo_target (COMP-01, COMP-02)"
      else
        fail "S2: $live_path points to $actual_target, expected $expected_target"
      fi
    else
      fail "S2: $live_path is not a symlink"
    fi
  done

  # 2. Assert ancestor directories are not folded
  for chk_dir in "$HOME/.config" "$HOME/.config/quickshell" "$QS_ROOT" "$QS_ROOT/modules" "$QS_ROOT/modules/ii" "$QS_ROOT/modules/ii/bar"; do
    if [[ -L "$chk_dir" ]]; then
      fail "S2: ancestor directory $chk_dir is a folded symlink"
    else
      pass "S2: ancestor directory $chk_dir is a real directory"
    fi
  done

  # 3. Resource.qml AST/token asserts
  RES_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml"
  if [[ -f "$RES_QML" ]]; then
    if grep -q 'property string customText: ""' "$RES_QML" && grep -q 'property int criticalThreshold: 100' "$RES_QML"; then
      pass "S2: Resource.qml defines customText and criticalThreshold properties (D-04)"
    else
      fail "S2: Resource.qml missing customText or criticalThreshold definition"
    fi

    if grep -q 'alertColor' "$RES_QML" && \
       grep -q 'colPrimary: (root.isCritical || root.isWarning) ? root.alertColor' "$RES_QML" && \
       grep -q 'color: (root.isCritical || root.isWarning) ? root.alertColor : Appearance.m3colors.m3onSecondaryContainer' "$RES_QML" && \
       grep -q 'color: (root.isCritical || root.isWarning) ? root.alertColor : Appearance.colors.colOnLayer1' "$RES_QML"; then
      pass "S2: Resource.qml enforces synchronous alertColor on ring, icon, and text (D-04)"
    else
      fail "S2: Resource.qml missing synchronous alertColor recoloring across ring, icon, and text"
    fi

    if grep -q 'implicitWidth: root.customText.length > 0 ? percentageText.implicitWidth : fullPercentageTextMetrics.width' "$RES_QML"; then
      pass "S2: Resource.qml calculates dynamic implicitWidth preventing text truncation (D-01)"
    else
      fail "S2: Resource.qml missing dynamic implicitWidth calculation"
    fi
  else
    fail "S2: $RES_QML does not exist"
  fi

  # 4. Resources.qml AST/token asserts
  RESS_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml"
  if [[ -f "$RESS_QML" ]]; then
    if grep -q 'ResourceUsage.memoryUsed / (1024 \* 1024)' "$RESS_QML" && \
       grep -q 'GB (${Math.round(ResourceUsage.memoryUsedPercentage \* 100)}%)' "$RESS_QML"; then
      pass "S2: Resources.qml formats RAM as definite X.X/Y.Y GB (ZZ%) (D-01, COMP-01)"
    else
      fail "S2: Resources.qml missing definite RAM gigabytes format"
    fi

    if grep -q 'shown: ResourceUsage.swapUsed > 0' "$RESS_QML"; then
      pass "S2: Resources.qml dynamically reveals Swap only when swapUsed > 0 (D-03, COMP-02)"
    else
      fail "S2: Resources.qml missing dynamic Swap visibility binding"
    fi

    if grep -q 'warningThreshold: 80' "$RESS_QML" && grep -q 'criticalThreshold: 90' "$RESS_QML" && \
       grep -q 'warningThreshold: 70' "$RESS_QML" && grep -q 'criticalThreshold: 85' "$RESS_QML" && \
       grep -q 'warningThreshold: 60' "$RESS_QML" && grep -q 'criticalThreshold: 90' "$RESS_QML"; then
      pass "S2: Resources.qml sets custom 2-tier thresholds RAM (80/90), Swap (70/85), CPU (60/90) (D-05)"
    else
      fail "S2: Resources.qml missing custom 2-tier thresholds"
    fi

    if grep -q 'iconName: "planner_review"' "$RESS_QML"; then
      pass "S2: Resources.qml CPU uses planner_review Material Symbol icon (D-02)"
    else
      fail "S2: Resources.qml CPU icon is not planner_review"
    fi
  else
    fail "S2: $RESS_QML does not exist"
  fi
fi

# ===========================================================================
# Section 3: Status, Clock, Media, Privacy & Tray Overlays & Symlinks
# (COMP-03, COMP-07, COMP-08, COMP-09, D-08, D-13, D-18, D-20)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Status, Clock, Media, Privacy & Tray Overlays & Symlinks ---"

  QS_ROOT="$HOME/.config/quickshell/ii"

  # 1. Assert leaf symlinks
  for mod in ClockWidget.qml SysTray.qml UpdatesButton.qml; do
    live_path="$QS_ROOT/modules/ii/bar/$mod"
    repo_target="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/$mod"
    if [[ -L "$live_path" ]]; then
      actual_target="$(readlink -f "$live_path")"
      expected_target="$(readlink -f "$repo_target")"
      if [[ "$actual_target" == "$expected_target" ]]; then
        pass "S3: $live_path is leaf symlink to $repo_target"
      else
        fail "S3: $live_path points to $actual_target, expected $expected_target"
      fi
    else
      fail "S3: $live_path is not a symlink"
    fi
  done

  for srv in Privacy.qml Updates.qml; do
    live_path="$QS_ROOT/services/$srv"
    repo_target="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/$srv"
    if [[ -L "$live_path" ]]; then
      actual_target="$(readlink -f "$live_path")"
      expected_target="$(readlink -f "$repo_target")"
      if [[ "$actual_target" == "$expected_target" ]]; then
        pass "S3: $live_path is leaf symlink to $repo_target"
      else
        fail "S3: $live_path points to $actual_target, expected $expected_target"
      fi
    else
      fail "S3: $live_path is not a symlink"
    fi
  done

  # 2. Assert services directory is real
  if [[ -L "$QS_ROOT/services" ]]; then
    fail "S3: $QS_ROOT/services is a folded symlink"
  else
    pass "S3: $QS_ROOT/services is a real directory"
  fi

  # 3. ClockWidget.qml non-glyph spacer assert (D-08, COMP-03)
  CLOCK_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml"
  if [[ -f "$CLOCK_QML" ]]; then
    if grep -q '"•"' "$CLOCK_QML"; then
      fail "S3: ClockWidget.qml still contains unicode bullet glyph '•'"
    else
      pass "S3: ClockWidget.qml is free of unicode bullet glyph '•' (D-08)"
    fi

    if grep -q 'implicitWidth: 8' "$CLOCK_QML"; then
      pass "S3: ClockWidget.qml includes non-glyph spacer (implicitWidth: 8) (D-08, COMP-03)"
    else
      fail "S3: ClockWidget.qml missing 8px non-glyph spacer item"
    fi
  else
    fail "S3: $CLOCK_QML does not exist"
  fi

  # 4. SysTray.qml columnSpacing assert (D-20, COMP-09)
  TRAY_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/SysTray.qml"
  if [[ -f "$TRAY_QML" ]]; then
    if grep -q 'columnSpacing: 4' "$TRAY_QML"; then
      pass "S3: SysTray.qml sets columnSpacing: 4 in GridLayout (D-20, COMP-09)"
    else
      fail "S3: SysTray.qml missing columnSpacing: 4"
    fi
  else
    fail "S3: $TRAY_QML does not exist"
  fi

  # 5. Privacy.qml boolean telemetry assert (D-13, COMP-08)
  PRIV_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/Privacy.qml"
  if [[ -f "$PRIV_QML" ]]; then
    if grep -q 'Pipewire.linkGroups.values.some' "$PRIV_QML"; then
      pass "S3: Privacy.qml uses Array.some returning primitive booleans (D-13, COMP-08)"
    else
      fail "S3: Privacy.qml missing Array.some primitive boolean evaluation"
    fi
  else
    fail "S3: $PRIV_QML does not exist"
  fi

  # 6. Updates.qml Arch + AUR poller assert (D-18, COMP-07)
  UPD_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/Updates.qml"
  if [[ -f "$UPD_QML" ]]; then
    if grep -q 'checkupdates' "$UPD_QML" && grep -q 'yay -Qua' "$UPD_QML"; then
      pass "S3: Updates.qml aggregates checkupdates and yay -Qua non-blocking (D-18, COMP-07)"
    else
      fail "S3: Updates.qml missing aggregated checkupdates and yay -Qua poller"
    fi
  else
    fail "S3: $UPD_QML does not exist"
  fi

  # 7. UpdatesButton.qml dedicated pill assert (D-18, COMP-07)
  UPDBTN_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml"
  if [[ -f "$UPDBTN_QML" ]]; then
    if grep -q 'text: "system_update_alt"' "$UPDBTN_QML" && \
       grep -q 'yay -Syu' "$UPDBTN_QML" && \
       grep -q 'Updates.count > 0' "$UPDBTN_QML"; then
      pass "S3: UpdatesButton.qml renders system_update_alt pill launching yay -Syu (D-18, COMP-07)"
    else
      fail "S3: UpdatesButton.qml missing system_update_alt glyph, count condition, or yay -Syu execution"
    fi
  else
    fail "S3: $UPDBTN_QML does not exist"
  fi
fi

# ===========================================================================
# Section 4: BarContent Integration, Quickshell Reload & Verification Engine
# (COMP-04, COMP-08, COMP-10, INTG-02, D-10..D-16)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: BarContent Integration & Verification Engine ---"

  CONTENT_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
  LIVE_CONTENT="$HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml"

  # 1. Assert leaf symlink for BarContent.qml
  if [[ -L "$LIVE_CONTENT" ]]; then
    actual_target="$(readlink -f "$LIVE_CONTENT")"
    expected_target="$(readlink -f "$CONTENT_QML")"
    if [[ "$actual_target" == "$expected_target" ]]; then
      pass "S4: $LIVE_CONTENT is leaf symlink to $CONTENT_QML"
    else
      fail "S4: $LIVE_CONTENT points to $actual_target, expected $expected_target"
    fi
  else
    fail "S4: $LIVE_CONTENT is not a symlink"
  fi

  # 2. BarContent.qml rules
  if [[ -f "$CONTENT_QML" ]]; then
    # Absence of uncommented ActiveWindow
    if grep -E '^[[:space:]]*ActiveWindow[[:space:]]*\{' "$CONTENT_QML" | grep -v '^[[:space:]]*//' >/dev/null; then
      fail "S4: BarContent.qml contains active ActiveWindow module (D-15)"
    else
      pass "S4: BarContent.qml has ActiveWindow removed (D-15)"
    fi

    # Absence of onScrollDown / onScrollUp and ScrollHint
    if grep -E '(onScrollDown|onScrollUp|ScrollHint)' "$CONTENT_QML" >/dev/null; then
      fail "S4: BarContent.qml still contains background scroll handlers or ScrollHint (D-16)"
    else
      pass "S4: BarContent.qml is free of background scroll handlers and ScrollHint (D-16)"
    fi

    # Media player auto-collapse bound to isPlaying
    if grep -q 'MprisController.activePlayer?.isPlaying' "$CONTENT_QML"; then
      pass "S4: BarContent.qml binds Media visible to isPlaying auto-collapse (D-12, COMP-04)"
    else
      fail "S4: BarContent.qml missing Media isPlaying auto-collapse binding"
    fi

    # Privacy revealers (Amber mic & Red screen share)
    if grep -q 'Privacy.micActive' "$CONTENT_QML" && grep -q 'color: "#FFA000"' "$CONTENT_QML" && \
       grep -q 'Privacy.screenSharing' "$CONTENT_QML" && grep -q 'Appearance.colors.colError' "$CONTENT_QML"; then
      pass "S4: BarContent.qml mounts Privacy Amber mic and Red screen share revealers (D-13, COMP-08)"
    else
      fail "S4: BarContent.qml missing Privacy micActive or screenSharing revealers"
    fi

    # UpdatesButton loader
    if grep -q 'UpdatesButton' "$CONTENT_QML"; then
      pass "S4: BarContent.qml mounts UpdatesButton in BarGroup loader (D-18, COMP-07)"
    else
      fail "S4: BarContent.qml missing UpdatesButton mount"
    fi
  else
    fail "S4: $CONTENT_QML does not exist"
  fi

  # 3. Quickshell process check
  if pgrep -f "qs -c ii" >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1; then
    pass "S4: Quickshell process is running"
  else
    finding "S4: Quickshell process is not running (not fatal during test runner)"
  fi

  # 4. vendor/dots-hyprland submodule cleanliness
  if [[ -z "$(git -C "$REPO_ROOT/vendor/dots-hyprland" status --porcelain)" ]]; then
    pass "S4: vendor/dots-hyprland submodule remains 100% clean (D-09)"
  else
    fail "S4: vendor/dots-hyprland submodule has uncommitted modifications"
  fi

  # 5. Collision map table in restow/README.md
  GEN_TABLE="$(mktemp /tmp/p32-gen-table-XXXXXX)"
  TMP_FILES+=("$GEN_TABLE")
  "$REPO_ROOT/scripts/gen-collision-map.sh" --restow-table > "$GEN_TABLE"

  README_TABLE="$(mktemp /tmp/p32-readme-table-XXXXXX)"
  TMP_FILES+=("$README_TABLE")
  awk '/<!-- BEGIN generated: gen-collision-map.sh --restow-table -->/{flag=1; next} /<!-- END generated: gen-collision-map.sh --restow-table -->/{flag=0} flag' "$REPO_ROOT/restow/README.md" > "$README_TABLE"

  if cmp -s "$GEN_TABLE" "$README_TABLE"; then
    pass "S4: restow/README.md generated table matches ./scripts/gen-collision-map.sh --restow-table"
  else
    fail "S4: restow/README.md generated table is out of sync with collision-map generator"
    diff -u "$GEN_TABLE" "$README_TABLE" || true
  fi

  # 6. Strict system verifier gate
  VERIFY_SCRIPT="$REPO_ROOT/arch/dots-hyprland.sh"
  if [[ -x "$VERIFY_SCRIPT" ]]; then
    v_rc=0
    v_out="$("$VERIFY_SCRIPT" verify --strict 2>&1)" || v_rc=$?
    if [[ "$v_rc" -eq 0 ]] && printf '%s\n' "$v_out" | grep -q 'FINDINGS=0'; then
      pass "S4: ./arch/dots-hyprland.sh verify --strict passed with 0 findings (INTG-02)"
    else
      fail "S4: ./arch/dots-hyprland.sh verify --strict failed (exit code $v_rc)"
      printf '%s\n' "$v_out" | tail -n 20 | sed 's/^/       /' >&2
    fi
  else
    fail "S4: arch/dots-hyprland.sh missing or not executable"
  fi
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
