# Phase 38: Power Profiles Daemon System Integration - Pattern Map

**Mapped:** 2026-09-22
**Files analyzed:** 3 (2 modified, 1 new)
**Analogs found:** 3 / 3 (100% coverage)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `arch/pkglist-native.txt` | config | batch | `arch/pkglist-native.txt` | exact |
| `bootstrap.sh` | utility | batch / event-driven | `bootstrap.sh` & `arch/bluetooth.sh` | exact |
| `scripts/phase38-power-profiles-assert.sh` | test | batch / request-response | `scripts/phase23-bootstrap-assert.sh` & `scripts/phase37-voice-pill-assert.sh` | role-match |

---

## Pattern Assignments

### 1. `arch/pkglist-native.txt` (config, batch)

**Analog:** `arch/pkglist-native.txt` (lines 1-10, 132-145)

**Manifest Header Pattern** (`arch/pkglist-native.txt` lines 1-6):
```text
# arch/pkglist-native.txt — explicitly installed native packages
# Hostname: arch
# Timestamp: 2026-09-15T06:12:28Z
# Kernel: 7.2.4-arch1-2
# Pacman: Pacman v7.1.0 - libalpm v16.0.1
# Count: 207
```

**Alphabetical Insertion Pattern** (`arch/pkglist-native.txt` lines 135-142):
```text
pipewire
pipewire-alsa
pipewire-pulse
playerctl
python
python-pip
python-pipx
python-pynvim
```

**Pattern Application for Phase 38:**
Insert `power-profiles-daemon` strictly in alphabetical order between `playerctl` and `python` (`LC_ALL=C` sorting invariant):
```text
pipewire
pipewire-alsa
pipewire-pulse
playerctl
power-profiles-daemon
python
python-pip
python-pipx
python-pynvim
```
Optionally increment the header `# Count:` field if regenerating snapshot or updating manually.

---

### 2. `bootstrap.sh` (utility, batch / event-driven)

**Analog 1 (Package Checking Structure):** `bootstrap.sh` (`step_packages`, lines 349-375)
**Analog 2 (System Service Enablement):** `arch/bluetooth.sh` (lines 6-14) & `arch/wifi.sh` (lines 24-27)
**Analog 3 (Idempotent Service Query):** `bootstrap.sh` (`step_verify`, lines 748-758)

**Package Check & Dry-Run Pattern** (`bootstrap.sh` lines 349-375):
```bash
step_packages() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] Checking base prerequisites (git, stow, jq, yay)..."
    return 0
  fi
  echo "[STEP 2/7] Checking base prerequisites..."
  local missing=()
  for pkg in git stow jq; do
    if ! command -v "$pkg" &>/dev/null; then
      missing+=("$pkg")
    fi
  done
  if ((${#missing[@]} > 0)); then
    echo "[FAIL] Missing required base prerequisite(s): ${missing[*]}" >&2
    return 1
  fi
  if ! command -v yay &>/dev/null; then
    if [[ -x "$REPO_ROOT/arch/aur.sh" ]]; then
      echo "[INFO] yay not found; installing via arch/aur.sh..."
      "$REPO_ROOT/arch/aur.sh"
    else
      echo "[FAIL] yay not found and arch/aur.sh is missing or not executable." >&2
      return 1
    fi
  fi
}
```

**Service Enablement Pattern** (`arch/bluetooth.sh` lines 6-13):
```bash
echo "[INSTALL] bluetooth pkg"
sudo pacman -Sy --noconfirm --needed bluez bluez-utils blueman

echo "[CONFIG] Enabling and starting bluetooth service"
sudo systemctl enable --now bluetooth

echo "[VERIFY] Bluetooth service status"
sudo systemctl status bluetooth
```

**Idempotent Active Service Check Pattern** (`bootstrap.sh` lines 748-757):
```bash
  if command -v systemctl &>/dev/null; then
    echo "[SYSTEMD] Reloading user systemd daemon..."
    systemctl --user daemon-reload 2>/dev/null || true
    echo "[SYSTEMD] Enabling and starting dotfiles-capture.timer..."
    systemctl --user --now enable dotfiles-capture.timer 2>/dev/null || true
    if ! systemctl --user is-active --quiet dotfiles-capture.timer 2>/dev/null; then
      echo "[WARN] dotfiles-capture.timer is not active (user D-Bus session may be unavailable)." >&2
    else
      echo "[PASS] dotfiles-capture.timer is active."
    fi
  fi
```

**Pattern Application for Phase 38:**
In `bootstrap.sh` within `step_packages()`:
1. Dry-run branch preview:
   ```bash
   if [[ "$DRY_RUN" -eq 1 ]]; then
     echo "[DRY-RUN] Checking base prerequisites (git, stow, jq, yay)..."
     echo "[DRY-RUN] Checking and activating power-profiles-daemon..."
     return 0
   fi
   ```
2. Idempotent package installation check (non-root caller using sudo on-demand):
   ```bash
   if ! pacman -Q power-profiles-daemon &>/dev/null; then
     echo "[INFO] power-profiles-daemon not installed; installing via pacman..."
     sudo pacman -S --needed --noconfirm power-profiles-daemon
   fi
   ```
3. Idempotent system-level systemd service activation (zero overhead on already-running systems):
   ```bash
   if command -v systemctl &>/dev/null; then
     if ! systemctl is-active --quiet power-profiles-daemon.service 2>/dev/null; then
       echo "[CONFIG] Enabling and starting power-profiles-daemon.service..."
       sudo systemctl enable --now power-profiles-daemon.service
     else
       echo "[PASS] power-profiles-daemon.service is already active."
     fi
   fi
   ```

---

### 3. `scripts/phase38-power-profiles-assert.sh` (test, batch / request-response)

**Analog 1 (Harness Structure, Flags, Cleanup):** `scripts/phase37-voice-pill-assert.sh` (lines 1-96)
**Analog 2 (Systemd & Bootstrap Verification):** `scripts/phase23-bootstrap-assert.sh` (lines 65-105, 300-345)
**Analog 3 (Headless Quickshell Runner):** `scripts/phase37-voice-pill-assert.sh` (lines 98-118)
**Analog 4 (Upstream QML Contract):** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/models/quickToggles/PowerProfilesToggle.qml` (lines 1-40)

**Harness Boilerplate & Porcelain Bracket** (`scripts/phase37-voice-pill-assert.sh` lines 1-50, 82-96):
```bash
#!/usr/bin/env bash
# ===========================================================================
# Phase 38: Power Profiles Daemon System Integration Assert Harness
# Enforces: POWER-01, POWER-02, POWER-03, D-01 through D-08
#
# Usage (from REPO_ROOT):
#   ./scripts/phase38-power-profiles-assert.sh [--section <1-5>] [-s <1-5>]
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
```

**Quickshell Headless Execution Snippet** (`scripts/phase37-voice-pill-assert.sh` lines 98-118):
```bash
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
```

**D-Bus and CLI Query Pattern** (System bus verification):
```bash
# Verify power-profiles-daemon responds on system D-Bus
if busctl status net.hadess.PowerProfiles >/dev/null 2>&1; then
  pass "Section 2: net.hadess.PowerProfiles is active on system bus"
else
  fail "Section 2: net.hadess.PowerProfiles not responding on system bus"
fi

# Verify powerprofilesctl lists profiles
if powerprofilesctl list >/dev/null 2>&1; then
  pass "Section 2: powerprofilesctl list executes successfully"
else
  fail "Section 2: powerprofilesctl list command failed"
fi
```

**Upstream Zero-Drift Assert Pattern** (`scripts/phase34-verification-assert.sh` lines 180-210):
```bash
# Verify no conflicting QML overrides exist in restow/
for p in "restow/quickshell/.config/quickshell/ii/modules/common/models/quickToggles/PowerProfilesToggle.qml" \
         "restow/quickshell/.config/quickshell/ii/modules/ii/sidebarRight/quickToggles/androidStyle/AndroidPowerProfileToggle.qml"; do
  if [[ -e "$REPO_ROOT/$p" ]]; then
    fail "Section 3: Found unauthorized local override for upstream power profile toggle at $p (violates D-01)"
  else
    pass "Section 3: Zero local override verified for $p"
  fi
done
```

---

## Shared Patterns

### Non-Root Execution Gate & Sudo Elevation
**Source:** `bootstrap.sh` (lines 8-13), `scripts/phase37-voice-pill-assert.sh` (lines 13-15)  
**Apply to:** All bash entry points and assertion harnesses  
```bash
CURRENT_EUID="${DOTFILES_MOCK_EUID:-${EUID:-$(id -u)}}"
if [[ "$CURRENT_EUID" -eq 0 ]]; then
  echo "[FAIL] Script must NOT be run as root. Run as regular operator." >&2
  exit 1
fi
```
Sub-commands requiring root privileges invoke `sudo` explicitly (`sudo pacman ...`, `sudo systemctl ...`).

### Idempotent Service & Package Verification
**Source:** `bootstrap.sh` (lines 748-758), `arch/audio.sh` (lines 20-25)  
**Apply to:** `bootstrap.sh` step_packages and system setup  
```bash
# Check if package installed before invoking pacman
pacman -Q <pkg> &>/dev/null || sudo pacman -S --needed --noconfirm <pkg>

# Check if service is active before invoking systemctl mutation
systemctl is-active --quiet <unit>.service || sudo systemctl enable --now <unit>.service
```

### Git Working-Tree Porcelain Bracket
**Source:** `scripts/phase23-bootstrap-assert.sh` (lines 65-80), `scripts/phase37-voice-pill-assert.sh` (lines 82-96)  
**Apply to:** `scripts/phase38-power-profiles-assert.sh`  
Ensures test scripts create zero untracked artifacts or persistent modifications in the git working tree.

---

## No Analog Found

None. All files and modifications in Phase 38 map directly to exact or role-matched patterns in the existing codebase.

---

## Metadata

**Analog search scope:** `arch/`, `bootstrap.sh`, `scripts/`, `vendor/dots-hyprland/`  
**Files scanned:** 12  
**Pattern extraction date:** 2026-09-22  
