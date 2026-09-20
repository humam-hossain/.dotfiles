# Phase 34: Verification, Zero Drift & Bootstrap Integration - Code Patterns

**Phase:** 34  
**Date:** 2026-09-20  
**Milestone:** v0.6  
**Status:** Pattern Mapping Complete  

---

## File Classification Matrix

| File Path | Role | Data Flow | Closest Analog | Analogy Match |
|---|---|---|---|---|
| `capture/ii/.config/illogical-impulse/config.json` | Config | File I/O (JSON state) | `capture/ii/.config/illogical-impulse/config.json` | Exact (1:1) |
| `stow/hypr/.config/hypr/custom/general.lua` | Config | Declarative / Config | `stow/hypr/.config/hypr/custom/general.lua` | Exact (1:1) |
| `bootstrap.sh` | Controller | State Machine / File I/O | `bootstrap.sh` & `arch/dots-hyprland.sh` | Exact (1:1) |
| `scripts/phase31-overlay-pill-assert.sh` | Test | File I/O / Assertions | `scripts/phase31-overlay-pill-assert.sh` | Exact (1:1) |
| `scripts/phase34-verification-assert.sh` | Test | Subprocess / File I/O / Sandboxing | `scripts/phase29-theme-data-contracts-assert.sh` & `scripts/phase33-layout-assert.sh` | Exact (1:1) |

---

## Pattern Assignments & Concrete Code Excerpts

### 1. `capture/ii/.config/illogical-impulse/config.json`
- **Role:** Config (Capture baseline JSON configuration)
- **Data Flow:** File I/O / state persistence
- **Analog:** `capture/ii/.config/illogical-impulse/config.json`
- **Rationale:** Tracks the baseline configuration for upstream Illogical Impulse shell settings. Setting `showPerformanceProfileToggle: false` aligns the capture seed with operator preferences and eliminates live-to-repo drift.
- **Pattern Excerpt:**
```json
// Pattern: 4-space JSON formatting, valid JSON structure, boolean toggle configuration
        "utilButtons": {
            "showColorPicker": true,
            "showDarkModeToggle": false,
            "showKeyboardToggle": true,
            "showMicToggle": true,
            "showPerformanceProfileToggle": false,
            "showScreenRecord": true,
            "showScreenSnip": true
        },
```
- **Validation Rule:**
```bash
jq empty capture/ii/.config/illogical-impulse/config.json
```

---

### 2. `stow/hypr/.config/hypr/custom/general.lua`
- **Role:** Config (Declarative Hyprland Lua DSL module)
- **Data Flow:** Declarative / configuration
- **Analog:** `stow/hypr/.config/hypr/custom/general.lua`
- **Rationale:** Defines personal layout geometry (zero gaps, 2px border, 5px corner rounding) and fluid animations (bezier curves with speed 3.5-5.0). Committing this baseline resolves working tree drift.
- **Pattern Excerpt:**
```lua
-- Pattern: Hyprland Lua DSL configuration via hl.* functions
-- Layout geometry: zero gaps, 2px border, refined corners
hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 2,
    },
    decoration = {
        rounding = 5,
        rounding_power = 2,
    },
    animations = {
        enabled = true,
    },
})

-- Smooth & fluid window animations (speed ~4-5, elegant deceleration)
hl.curve("easeOutQuint", {
    type = "bezier",
    points = {{0.23, 1}, {0.32, 1}},
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 4.5,
    bezier = "easeOutQuint",
    style = "popin 80%",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3.5,
    bezier = "easeOutQuint",
    style = "popin 85%",
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 4.5,
    bezier = "easeOutQuint",
    style = "slide",
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 4,
    bezier = "easeOutQuint",
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4.5,
    bezier = "easeOutQuint",
    style = "slide",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 5,
    bezier = "easeOutQuint",
})
```

---

### 3. `bootstrap.sh`
- **Role:** Controller (Shell installer and state machine orchestrator)
- **Data Flow:** Multi-step installation, state machine, file I/O, process orchestration
- **Analog:** `bootstrap.sh` (`run_stow_step`, `generate_initial_theme`, `probe_session_environment`)
- **Rationale:** Pre-creates sensitive target directories to prevent GNU Stow whole-directory folding (D-05), asserts primed color state before operator relogin (D-08), and dynamically probes Hyprland socket signatures to prevent subshell probe crashes.
- **Pattern Excerpts:**

#### A. Directory Pre-Creation in `run_stow_step` (D-05)
```bash
# Analog: bootstrap.sh:514-524
run_stow_step() {
  local target="${1:-$HOME}"
  local base_repo="${2:-$REPO_ROOT}"

  # D-14 & D-05: Pre-create sensitive parent directories before stowing
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] Would pre-create sensitive parent directories"
  else
    mkdir -p "$target/.config/fuzzel" \
             "$target/.config/gtk-3.0" \
             "$target/.config/gtk-4.0" \
             "$target/.config/hypr/custom" \
             "$target/.config/kitty" \
             "$target/.config/quickshell/ii/modules/ii/bar" \
             "$target/.config/quickshell/ii/services" \
             "$target/.config/quickshell/ii/scripts/videos" \
             "$target/.config/systemd/user"
  fi
...
```

#### B. Verified Color Priming in `generate_initial_theme` (D-08)
```bash
# Analog: bootstrap.sh:652-665
  echo "[THEME] Triggering initial theme generation..."
  if [[ -n "$wp_path" && -f "$wp_path" ]]; then
    echo "[THEME] Generating theme from configured wallpaper: $wp_path"
    if ! "$switchwall" --noswitch; then
      echo "[WARN] switchwall.sh --noswitch failed; falling back to color seed #3f51b5"
      "$switchwall" --color "#3f51b5" || echo "[WARN] Fallback theme generation failed"
    fi
  else
    echo "[THEME] Configured wallpaper absent or inaccessible; falling back to color seed #3f51b5"
    if ! "$switchwall" --color "#3f51b5"; then
      echo "[WARN] Fallback color seed theme generation failed"
    fi
  fi

  # D-08: Assert colors.json is generated and non-empty before proceeding
  local generated_colors="${XDG_STATE_HOME:-$target/.local/state}/quickshell/user/generated/colors.json"
  if [[ ! -s "$generated_colors" ]]; then
    echo "[FAIL] Initial theme generation did not produce non-empty colors.json at $generated_colors" >&2
    return 1
  fi
  echo "[THEME] Verified primed Material You palette at $generated_colors"
```

#### C. Resilient Session Socket Detection in `probe_session_environment`
```bash
# Analog: scripts/phase33-layout-assert.sh:467-472 & bootstrap.sh:701-712
probe_session_environment() {
  if command -v hyprctl >/dev/null 2>&1; then
    if ! hyprctl -j status >/dev/null 2>&1; then
      local local_sig
      local_sig="$(ls -td "/run/user/$(id -u)/hypr/"* 2>/dev/null | head -1 | xargs -r basename || true)"
      if [[ -n "$local_sig" ]]; then
        export HYPRLAND_INSTANCE_SIGNATURE="$local_sig"
      fi
    fi
  fi
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo "[WARN] HYPRLAND_INSTANCE_SIGNATURE is not set. Graphical session may not be active." >&2
  fi
  if command -v hyprctl &>/dev/null; then
    local provider
    provider="$(hyprctl -j status 2>/dev/null | jq -r '.configProvider // "unknown"' 2>/dev/null || echo "unknown")"
    if [[ "$provider" != "lua" ]]; then
      echo "[WARN] Active configProvider is '$provider' (expected 'lua'). Did you relogin?" >&2
    fi
  fi
}
```

---

### 4. `scripts/phase31-overlay-pill-assert.sh`
- **Role:** Test (Milestone assert harness)
- **Data Flow:** Test assertions / regex file matching
- **Analog:** `scripts/phase31-overlay-pill-assert.sh:205-217`
- **Rationale:** Aligns Phase 31 assertion with Phase 33 layout rework where `VerticalBarSeparator` was intentionally eliminated and borderless container background handling resides in `BarGroup.qml` (D-14).
- **Pattern Excerpt:**
```bash
# Analog: scripts/phase31-overlay-pill-assert.sh lines 205-217
  # 3. Assert middleSection spacing: 4 and borderless container binding (PILL-04, Phase 33 aligned)
  if grep -q 'spacing: 4' "$CONTENT_QML"; then
    pass "S3: BarContent.qml preserves inter-pill spacing: 4 (D-03)"
  else
    fail "S3: BarContent.qml missing spacing: 4"
  fi

  # In Phase 33, VerticalBarSeparator was eliminated from BarContent.qml (D-02, D-05).
  # Assert borderless container toggling in BarGroup.qml or BarContent.qml (PILL-04)
  if grep -q 'color: Config.options?.bar.borderless ? "transparent"' "$GROUP_QML" || \
     grep -q 'visible: Config.options?.bar.borderless' "$CONTENT_QML"; then
    pass "S3: Pill containers preserve borderless background toggling (PILL-04, Phase 33 aligned)"
  else
    fail "S3: Missing borderless container binding"
  fi
```

---

### 5. `scripts/phase34-verification-assert.sh`
- **Role:** Test (Comprehensive 5-section test harness)
- **Data Flow:** Subprocess execution / file I/O / temporary sandboxing / git porcelain inspection
- **Analog:** `scripts/phase29-theme-data-contracts-assert.sh` (Sections 1–5 structure) and `scripts/phase33-layout-assert.sh` (CLI flags, trap cleanup, porcelain snapshot filter)
- **Rationale:** Complete end-of-milestone verification suite enforcing INTG-01 (Dynamic theming drill & contract), INTG-02 (Strict repo verification & zero drift), INTG-03 (Bootstrap isolated scratch drill), and milestone v0.6 regression sweep (Phases 31, 32, 33).

#### A. Header, CLI Flags, Traps, and Helpers Pattern
```bash
# Analog: scripts/phase29-theme-data-contracts-assert.sh:1-77 & scripts/phase33-layout-assert.sh:1-65
#!/usr/bin/env bash
# Phase 34: Verification, Zero Drift & Bootstrap Integration Assert Harness
# Enforces: INTG-01, INTG-02, INTG-03, D-01 through D-16
#
# Usage (from REPO_ROOT):
#   ./scripts/phase34-verification-assert.sh [--section <1-5>]
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
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-5>]"
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

PORCELAIN_BEFORE="$(mktemp /tmp/p34-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p34-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"
```

#### B. Section 1: Data Contracts, 11/11 Symlinks & Pre-Creation Checks
```bash
# Analog: scripts/phase29-theme-data-contracts-assert.sh:80-150 & RESEARCH.md Code Example 3
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Data Contracts, 11/11 Symlinks & Pre-Creation (INTG-01, INTG-02, INTG-03) ---"

  # 1. 11/11 Overlay Symlinks
  EXPECTED_OVERLAYS=(
    ".config/quickshell/ii/services/Updates.qml"
    ".config/quickshell/ii/services/Privacy.qml"
    ".config/quickshell/ii/scripts/videos/record.sh"
    ".config/quickshell/ii/scripts/system-update.sh"
    ".config/quickshell/ii/modules/ii/bar/BarContent.qml"
    ".config/quickshell/ii/modules/ii/bar/SysTray.qml"
    ".config/quickshell/ii/modules/ii/bar/UpdatesButton.qml"
    ".config/quickshell/ii/modules/ii/bar/BarGroup.qml"
    ".config/quickshell/ii/modules/ii/bar/Resources.qml"
    ".config/quickshell/ii/modules/ii/bar/Resource.qml"
    ".config/quickshell/ii/modules/ii/bar/ClockWidget.qml"
  )
  for rel in "${EXPECTED_OVERLAYS[@]}"; do
    live="$HOME/$rel"
    repo="$REPO_ROOT/restow/quickshell/$rel"
    if [[ -L "$live" && "$(readlink -f "$live")" == "$(readlink -f "$repo")" ]]; then
      pass "S1: Live overlay $rel resolves 1:1 to restow/quickshell (D-11)"
    else
      fail "S1: Live overlay $rel target mismatch or not a symlink"
    fi
  done

  # 2. Sensitive Directory Pre-Creation in bootstrap.sh (D-05)
  for req_dir in ".config/quickshell/ii/modules/ii/bar" \
                 ".config/quickshell/ii/services" \
                 ".config/quickshell/ii/scripts/videos"; do
    if grep -qF "$req_dir" "$REPO_ROOT/bootstrap.sh"; then
      pass "S1: bootstrap.sh pre-creates target directory $req_dir (D-05)"
    else
      fail "S1: bootstrap.sh missing pre-creation of $req_dir"
    fi
  done

  # 3. Dynamic colors.json Token Contract (D-03)
  COLORS_JSON="$XDG_STATE_HOME/quickshell/user/generated/colors.json"
  if [[ -s "$COLORS_JSON" ]] && jq empty "$COLORS_JSON" 2>/dev/null; then
    for token in background surface_container_low on_surface_variant secondary_container primary error; do
      if jq -e --arg t "$token" 'has($t)' "$COLORS_JSON" >/dev/null; then
        pass "S1: colors.json defines core token: $token (D-03)"
      else
        fail "S1: colors.json missing core token: $token"
      fi
    done
  else
    fail "S1: colors.json missing or invalid JSON"
  fi

  # 4. Zero Unauthorized Hardcoded Hex Codes in restow/quickshell (D-03)
  UNAUTH_HEX="$(grep -rnE '#[0-9a-fA-F]{3,8}' "$REPO_ROOT/restow/quickshell" | grep -v '#FFA000' || true)"
  if [[ -z "$UNAUTH_HEX" ]]; then
    pass "S1: Zero unauthorized hardcoded hex codes in restow/quickshell (D-03)"
  else
    fail "S1: Found unauthorized hardcoded hex codes in restow/quickshell: $UNAUTH_HEX"
  fi
fi
```

#### C. Section 2: Dual Theming Drill & Monotonic Mtime Advance
```bash
# Analog: scripts/phase29-theme-data-contracts-assert.sh:188-252
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Material You Theming Drill & Zero Git Churn (INTG-01, D-01, D-04, D-12) ---"

  SWITCHWALL="$XDG_CONFIG_HOME/quickshell/ii/scripts/colors/switchwall.sh"
  COLORS_JSON="$XDG_STATE_HOME/quickshell/user/generated/colors.json"
  SHELL_CONFIG="$XDG_CONFIG_HOME/illogical-impulse/config.json"

  if [[ ! -x "$SWITCHWALL" ]]; then
    fail "S2: switchwall.sh not executable at $SWITCHWALL"
  else
    # Preserve live shell config to prevent switchwall --color JSON reformats from causing capture drift
    SAVED_SHELL_CONFIG="$(mktemp /tmp/p34-saved-config-XXXXXX)"
    TMP_FILES+=("$SAVED_SHELL_CONFIG")
    [[ -f "$SHELL_CONFIG" ]] && cp "$SHELL_CONFIG" "$SAVED_SHELL_CONFIG"

    DRILL_BEFORE="$(mktemp /tmp/p34-drill-before-XXXXXX)"
    DRILL_AFTER="$(mktemp /tmp/p34-drill-after-XXXXXX)"
    TMP_FILES+=("$DRILL_BEFORE" "$DRILL_AFTER")
    porcelain_snapshot > "$DRILL_BEFORE"

    B_MTIME="$(stat -c %Y "$COLORS_JSON" 2>/dev/null || echo 0)"
    sleep 1

    # Drill A: Native switchwall.sh --noswitch
    SW_RC=0
    "$SWITCHWALL" --noswitch >/dev/null 2>&1 || SW_RC=$?
    if [[ "$SW_RC" -eq 0 ]]; then
      pass "S2: switchwall.sh --noswitch completed successfully (D-01)"
    else
      fail "S2: switchwall.sh --noswitch failed with rc=$SW_RC"
    fi

    A_MTIME="$(stat -c %Y "$COLORS_JSON" 2>/dev/null || echo 0)"
    if [[ "$A_MTIME" -gt "$B_MTIME" ]]; then
      pass "S2: colors.json mtime advanced monotonically on native drill (D-04)"
    else
      fail "S2: colors.json mtime did not advance on native drill"
    fi

    if pgrep -x qs >/dev/null || pgrep -x quickshell >/dev/null; then
      pass "S2: quickshell process remained alive during native theming (D-04)"
    else
      fail "S2: quickshell process died during native theming"
    fi

    sleep 1

    # Drill B: Fallback synthetic color seed switchwall.sh --color "#3f51b5"
    SEED_RC=0
    "$SWITCHWALL" --color "#3f51b5" >/dev/null 2>&1 || SEED_RC=$?
    if [[ "$SEED_RC" -eq 0 ]]; then
      pass "S2: switchwall.sh --color '#3f51b5' seed fallback completed successfully (D-01)"
    else
      fail "S2: switchwall.sh --color '#3f51b5' failed with rc=$SEED_RC"
    fi

    C_MTIME="$(stat -c %Y "$COLORS_JSON" 2>/dev/null || echo 0)"
    if [[ "$C_MTIME" -gt "$A_MTIME" ]]; then
      pass "S2: colors.json mtime advanced monotonically on color seed drill (D-04)"
    else
      fail "S2: colors.json mtime did not advance on color seed drill"
    fi

    if jq empty "$COLORS_JSON" 2>/dev/null; then
      pass "S2: colors.json generated valid JSON on color seed drill"
    else
      fail "S2: colors.json generated invalid JSON on color seed drill"
    fi

    # Restoration: Restore shell config and re-run native switchwall
    if [[ -f "$SAVED_SHELL_CONFIG" ]]; then
      cp "$SAVED_SHELL_CONFIG" "$SHELL_CONFIG"
    fi
    "$SWITCHWALL" --noswitch >/dev/null 2>&1 || true

    if pgrep -x qs >/dev/null || pgrep -x quickshell >/dev/null; then
      pass "S2: quickshell process remains alive after palette restoration (D-04)"
    else
      fail "S2: quickshell process died after palette restoration"
    fi

    porcelain_snapshot > "$DRILL_AFTER"
    if cmp -s "$DRILL_BEFORE" "$DRILL_AFTER"; then
      pass "S2: Zero git churn: porcelain snapshot byte-identical before and after drill (D-12)"
    else
      fail "S2: switchwall drill caused working-tree churn"
      diff -u "$DRILL_BEFORE" "$DRILL_AFTER" || true
    fi
  fi
fi
```

#### D. Section 3: Repository Strict Verification Gate
```bash
# Analog: scripts/phase29-theme-data-contracts-assert.sh:255-296 & scripts/phase32-component-formatting-assert.sh:609-623
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Repository Strict Verification Gate (INTG-02, D-09, D-10) ---"

  # 1. Clean packaging trees
  DIRTY_TREES="$(git status --porcelain stow/ restow/ capture/ || true)"
  if [[ -z "$DIRTY_TREES" ]]; then
    pass "S3: Packaging trees (stow/, restow/, capture/) are 100% clean"
  else
    fail "S3: Packaging trees dirty: $DIRTY_TREES"
  fi

  # 2. Strict verification execution
  VERIFY_RC=0
  VERIFY_OUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)" || VERIFY_RC=$?
  if [[ "$VERIFY_RC" -eq 0 ]] && printf '%s\n' "$VERIFY_OUT" | grep -q 'FINDINGS=0'; then
    pass "S3: arch/dots-hyprland.sh verify --strict passed with exit 0 and FINDINGS=0 (INTG-02)"
  else
    fail "S3: arch/dots-hyprland.sh verify --strict failed (exit code $VERIFY_RC)"
    printf '%s\n' "$VERIFY_OUT" | tail -n 25 | sed 's/^/       /' >&2
  fi
fi
```

#### E. Section 4: Isolated Bootstrap Destub, Stow & Priming Scratch Drill
```bash
# Analog: scripts/phase29-theme-data-contracts-assert.sh:301-397
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Isolated Bootstrap Destub & Stow Scratch Drill (INTG-03, D-05, D-06, D-07, D-08) ---"

  S4_ROOT="$(mktemp -d /tmp/p34-assert-s4-XXXXXX)"
  SCRATCH_ROOTS+=("$S4_ROOT")
  MOCK_HOME="$S4_ROOT/home"
  MOCK_REPO="$S4_ROOT/repo"
  mkdir -p "$MOCK_HOME" "$MOCK_REPO"

  # Populate mock repo mirroring stow and restow/quickshell
  mkdir -p "$MOCK_REPO/restow/quickshell/.config/quickshell/ii/modules/ii/bar"
  mkdir -p "$MOCK_REPO/restow/quickshell/.config/quickshell/ii/services"
  mkdir -p "$MOCK_REPO/restow/quickshell/.config/quickshell/ii/scripts/videos"
  touch "$MOCK_REPO/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
  touch "$MOCK_REPO/restow/quickshell/.config/quickshell/ii/services/Updates.qml"
  touch "$MOCK_REPO/restow/quickshell/.config/quickshell/ii/scripts/videos/record.sh"

  # Populate mock home with upstream regular file stubs
  mkdir -p "$MOCK_HOME/.config/quickshell/ii/modules/ii/bar"
  mkdir -p "$MOCK_HOME/.config/quickshell/ii/services"
  mkdir -p "$MOCK_HOME/.config/quickshell/ii/scripts/videos"
  echo "UPSTREAM_BAR_CONTENT" > "$MOCK_HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
  echo "UPSTREAM_UPDATES" > "$MOCK_HOME/.config/quickshell/ii/services/Updates.qml"
  echo "UPSTREAM_RECORD" > "$MOCK_HOME/.config/quickshell/ii/scripts/videos/record.sh"

  # Source bootstrap functions in isolation
  # shellcheck source=/dev/null
  source "$REPO_ROOT/bootstrap.sh"

  # 1. Test run_destub discovered and unlinked stubs (D-06, D-07)
  DRY_RUN=0
  destub_output="$(run_destub "$MOCK_HOME" "$MOCK_REPO" 2>&1 || true)"
  
  if [[ ! -e "$MOCK_HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml" && \
        ! -e "$MOCK_HOME/.config/quickshell/ii/services/Updates.qml" && \
        ! -e "$MOCK_HOME/.config/quickshell/ii/scripts/videos/record.sh" ]]; then
    pass "S4: run_destub unlinked upstream Quickshell stubs cleanly (D-06)"
  else
    fail "S4: run_destub failed to unlink stubs"
  fi

  # Verify backup directory and SHA-256 manifests
  backup_dir="$(find "$MOCK_HOME" -maxdepth 1 -type d -name ".dotfiles-backup.*" | head -1)"
  if [[ -n "$backup_dir" && -f "$backup_dir/manifest.sha256" ]]; then
    pass "S4: run_destub created backup archive with SHA-256 manifest (D-06)"
  else
    fail "S4: run_destub backup archive or manifest missing"
  fi

  # 2. Test run_stow_step pre-creation and leaf symlinking (D-05)
  run_stow_step "$MOCK_HOME" "$MOCK_REPO" >/dev/null 2>&1 || true
  if [[ -d "$MOCK_HOME/.config/quickshell/ii/modules/ii/bar" && \
        ! -L "$MOCK_HOME/.config/quickshell/ii/modules/ii/bar" && \
        -L "$MOCK_HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml" ]]; then
    pass "S4: run_stow_step creates leaf symlinks without folding bar directory (D-05)"
  else
    fail "S4: run_stow_step failed to pre-create or folded bar directory"
  fi

  # 3. Test generate_initial_theme color priming assertion (D-08)
  mkdir -p "$MOCK_HOME/.config/quickshell/ii/scripts/colors"
  cat << 'EOF' > "$MOCK_HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"
#!/usr/bin/env bash
mkdir -p "$HOME/.local/state/quickshell/user/generated"
echo '{"background":"#1a1a1a"}' > "$HOME/.local/state/quickshell/user/generated/colors.json"
exit 0
EOF
  chmod +x "$MOCK_HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"

  HOME="$MOCK_HOME" XDG_STATE_HOME="$MOCK_HOME/.local/state" \
    generate_initial_theme "$MOCK_HOME" >/dev/null 2>&1 || true

  if [[ -s "$MOCK_HOME/.local/state/quickshell/user/generated/colors.json" ]]; then
    pass "S4: generate_initial_theme asserts primed colors.json successfully (D-08)"
  else
    fail "S4: generate_initial_theme did not verify primed colors.json"
  fi
fi
```

#### F. Section 5: Full Milestone v0.6 Regression Sweep
```bash
# Analog: scripts/phase29-theme-data-contracts-assert.sh:400-423
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Full v0.6 Milestone Regression Sweep (Phases 31, 32, 33) ---"

  for p_script in "scripts/phase31-overlay-pill-assert.sh" \
                  "scripts/phase32-component-formatting-assert.sh" \
                  "scripts/phase33-layout-assert.sh"; do
    if [[ -x "$REPO_ROOT/$p_script" ]]; then
      p_rc=0
      p_out="$("$REPO_ROOT/$p_script" 2>&1)" || p_rc=$?
      if [[ "$p_rc" -eq 0 ]]; then
        pass "S5: $p_script passed with 0 failures (D-14)"
      else
        fail "S5: $p_script failed with exit code $p_rc"
        printf '%s\n' "$p_out" | tail -n 20 | sed 's/^/       /' >&2
      fi
    else
      fail "S5: $p_script missing or not executable"
    fi
  done
fi

# Closing porcelain check & summary
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run (D-12, D-16)"
else
  fail "Closing self-check: git status --porcelain mutated across run"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

---

## Pattern Reuse Summary

| Target Task | Source Pattern File | Core Reused Pattern |
|---|---|---|
| Zero Drift Baseline Commit | `capture/ii/.../config.json`, `stow/hypr/.../general.lua` | Git porcelain hygiene via staged commit of audited baseline files |
| Directory Pre-Creation | `bootstrap.sh:518-524` (`run_stow_step`) | Explicit `mkdir -p` prevents GNU Stow directory folding |
| Color Priming Gate | `bootstrap.sh:652-665` (`generate_initial_theme`) | Non-empty file check `[[ ! -s "$file" ]]` before stage handoff |
| Session Socket Resilience | `scripts/phase33-layout-assert.sh:467-472` | Dynamic socket directory resolution under `/run/user/$(id -u)/hypr/` |
| Pill Harness Alignment | `scripts/phase31-overlay-pill-assert.sh:205-217` | Multi-file regex or-check (`BarGroup.qml` vs `BarContent.qml`) |
| 5-Section Test Harness | `scripts/phase29-theme-data-contracts-assert.sh` | Modular 5-section suite, CLI flags, porcelain snapshots, trap cleanup |
| Dynamic Theming Drill | `scripts/phase29-theme-data-contracts-assert.sh:188-252` | Monotonic mtime advance check, daemon liveness check, state restoration |
| Isolated Sandbox Testing | `scripts/phase29-theme-data-contracts-assert.sh:301-397` | Mock home/repo sandbox in `/tmp/p34-assert-s4-XXXXXX` |
