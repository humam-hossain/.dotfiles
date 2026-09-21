# Phase 35: Voice Telemetry & State Service Architecture - Pattern Map

**Mapped:** 2026-09-21  
**Files analyzed:** 3  
**Analogs found:** 3 / 3  

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `restow/quickshell/.config/quickshell/ii/services/Voice.qml` | service | file-I/O / pub-sub | `vendor/dots-hyprland/dots/.config/quickshell/ii/services/ResourceUsage.qml` | exact |
| `/home/pera/github_repo/Voice/voice.py` | service | file-I/O / event-driven | `/home/pera/github_repo/Voice/voice.py` | exact |
| `scripts/phase35-voice-telemetry-assert.sh` | test | batch / request-response | `scripts/phase34-verification-assert.sh` | exact |

---

## Pattern Assignments

### `restow/quickshell/.config/quickshell/ii/services/Voice.qml` (service, file-I/O / pub-sub)

**Primary Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/services/ResourceUsage.qml`  
**Location & Overlay Analog:** `restow/quickshell/.config/quickshell/ii/services/Privacy.qml`  
**Process Execution Helper Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/services/Battery.qml`  

**Imports pattern** (`vendor/dots-hyprland/dots/.config/quickshell/ii/services/ResourceUsage.qml` lines 1-8):
```qml
pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
```

**Singleton root & property definition pattern** (`ResourceUsage.qml` lines 12-33):
```qml
Singleton {
    id: root

    property real memoryTotal: 1
    property real memoryFree: 0
    property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    ...
```

**Non-blocking file observation pattern** (`ResourceUsage.qml` lines 62-77, 100-101):
```qml
    FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }

    Timer {
        interval: 1
        running: true 
        repeat: true
        onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()

            // Parse text
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
        }
    }
```

**Silent cold-boot error suppression (`FileView` configuration):**
*(Note: Quickshell `FileView` defaults `printErrors: true`. For `/proc/` and `$XDG_RUNTIME_DIR/` files that may not exist on startup, explicitly disable error printing to avoid console spam per D-03)*
```qml
FileView {
    id: recorderFile
    path: root.recorderPidPath
    printErrors: false
    blockLoading: true
}
```

**Detached process execution pattern for stale PID purging** (`vendor/dots-hyprland/dots/.config/quickshell/ii/services/Battery.qml` lines 55-62):
```qml
Quickshell.execDetached([
    "notify-send", 
    Translation.tr("Low battery"), 
    Translation.tr("Consider plugging in your device"), 
    "-u", "critical",
    "-a", "Shell",
    "--hint=int:transient:1",
])
```
*Applied to stale lock purging (D-10, D-11):*
```qml
console.warn("[Voice] Purged stale PID lock: " + pid);
Quickshell.execDetached(["rm", "-f", root.recorderPidPath]);
```

**Visual linger timer pattern** (`restow/quickshell/.config/quickshell/ii/services/Privacy.qml` lines 20-30):
```qml
Timer {
    id: typingLingerTimer
    interval: 1000
    repeat: false
    onTriggered: {
        if (root.sttState === "typing") {
            root.sttState = "idle";
            root.resetDuration();
        }
    }
}
```

---

### `/home/pera/github_repo/Voice/voice.py` (service, file-I/O / event-driven)

**Analog:** `/home/pera/github_repo/Voice/voice.py` (lines 588–615, 1170–1210, 1430–1470)

**Imports pattern** (`voice.py` lines 1-25):
```python
import argparse
import os
import signal
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path
from typing import Optional
```

**PID state reading & writing pattern** (`voice.py` lines 588-615):
```python
def read_pid_state(path: Path = PID_FILE) -> tuple[int | None, str]:
    try:
        content = path.read_text(encoding="utf-8").strip()
        if not content:
            return None, "idle"
        parts = content.split()
        if not parts:
            return None, "idle"
        pid = int(parts[0])
        state = parts[1] if len(parts) > 1 else "recording"
        return pid, state
    except (FileNotFoundError, ValueError, OSError):
        return None, "idle"


def write_pid_state(pid: int, state: str, path: Path = PID_FILE) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f"{pid} {state}\n", encoding="utf-8")


def write_pid(path: Path = PID_FILE) -> None:
    write_pid_state(os.getpid(), "recording", path)
```

**TTS process lifecycle state emission pattern** (`voice.py` lines 1178-1181):
```python
    signal.signal(signal.SIGTERM, request_stop)
    signal.signal(signal.SIGUSR1, request_stop)
    # REPLACE: write_pid(TTS_PID_FILE)
    # WITH:
    write_pid_state(pid, "speaking", TTS_PID_FILE)
```

**STT text insertion typing state emission pattern** (`voice.py` lines 1455-1461):
```python
    if text and args.paste:
        write_pid_state(pid, "typing")
        if insert_text(text, args):
            print("Transcript inserted.", flush=True)
```

**Process liveness & command line validation pattern** (`voice.py` lines 617-637):
```python
def process_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        pass
    except OSError:
        return False

    cmdline_path = Path(f"/proc/{pid}/cmdline")
    try:
        raw = cmdline_path.read_bytes()
        if not raw:
            return False
        cmdline = raw.decode("utf-8", errors="ignore").lower()
        valid_tokens = ("voice", "python", "voicemode")
        return any(tok in cmdline for tok in valid_tokens)
    except (FileNotFoundError, ProcessLookupError, PermissionError, OSError):
        return False
```

---

### `scripts/phase35-voice-telemetry-assert.sh` (test, batch / request-response)

**Primary Analog:** `scripts/phase34-verification-assert.sh`  
**Secondary Analog:** `scripts/phase31-overlay-pill-assert.sh`  

**Script boilerplate, environment & safety guards** (`scripts/phase34-verification-assert.sh` lines 1-22):
```bash
#!/usr/bin/env bash
# ===========================================================================
# Phase 35: Voice Telemetry & State Service Architecture Assert Harness
# Enforces: TELEM-01 through TELEM-05, D-01 through D-11
# ===========================================================================

set -euo pipefail

# Fail closed if run as root
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
```

**Assertion functions & counters** (`scripts/phase34-verification-assert.sh` lines 33-40):
```bash
FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }
```

**Scratch & temporary file cleanup trap** (`scripts/phase34-verification-assert.sh` lines 41-63):
```bash
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
```

**CLI section flag parser** (`scripts/phase34-verification-assert.sh` lines 65-88):
```bash
RUN_SECTION=0

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
    -h|--help)
      echo "Usage: $0 [--section <1-6>]"
      echo "  -s, --section <1-6>  Execute only the specified section"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done
```

**Git porcelain invariance check** (`scripts/phase34-verification-assert.sh` lines 90-104, 401-413):
```bash
porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p35-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p35-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ... sections run here ...

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

**Live restow symlink & directory non-folding assertion** (`scripts/phase31-overlay-pill-assert.sh` lines 85-110):
```bash
# 1. Target files in ~/.config/quickshell/ii/services/ must be symlinks resolving to repo
live_path="$HOME/.config/quickshell/ii/services/Voice.qml"
target_repo="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/Voice.qml"
if [[ -L "$live_path" ]]; then
  actual_target="$(readlink -f "$live_path")"
  expected_target="$(readlink -f "$target_repo")"
  if [[ "$actual_target" == "$expected_target" ]]; then
    pass "S1: $live_path is symlink to $target_repo (D-05, PILL-01)"
  else
    fail "S1: $live_path points to $actual_target, expected $expected_target"
  fi
else
  fail "S1: $live_path is not a symlink"
fi

# 2. Assert ancestor directory is not folded
if [[ -L "$HOME/.config/quickshell/ii/services" ]]; then
  fail "S1: ancestor directory ~/.config/quickshell/ii/services is a symlink (folded directory violation)"
else
  pass "S1: ancestor directory ~/.config/quickshell/ii/services is a real directory"
fi
```

**Headless QML execution assertion pattern** (`quickshell -p` integration):
```bash
# Headless test runner executes test harness QML script validating singleton state logic
QS_OUT="$(quickshell -p "$TEST_QML_FILE" 2>&1)" || q_rc=$?
if [[ "$q_rc" -eq 0 ]] && printf '%s\n' "$QS_OUT" | grep -q 'ALL_TESTS_PASSED'; then
  pass "S2: Headless Quickshell validated Voice.qml state machine successfully"
else
  fail "S2: Headless Quickshell validation failed"
  printf '%s\n' "$QS_OUT" | sed 's/^/       /' >&2
fi
```

---

## Shared Patterns

### Pattern 1: Non-Blocking Procfs / tmpfs FileView Reading
**Source:** `vendor/dots-hyprland/dots/.config/quickshell/ii/services/ResourceUsage.qml`  
**Apply to:** `restow/quickshell/.config/quickshell/ii/services/Voice.qml` and future desktop telemetry services
```qml
// Non-blocking inotify/RAM reads; no child subprocess forks
FileView {
    id: monitorFile
    path: root.filePath
    printErrors: false
    blockLoading: true
}
```

### Pattern 2: Safe Detached Command Execution
**Source:** `vendor/dots-hyprland/dots/.config/quickshell/ii/services/Battery.qml`  
**Apply to:** `Voice.qml` (`Quickshell.execDetached(["rm", "-f", path])`)
```qml
// Always pass argument arrays, never raw strings to bash -c, to prevent shell injection
Quickshell.execDetached(["rm", "-f", root.targetPath]);
```

### Pattern 3: Test Assertion Script Lifecycle & Porcelain Discipline
**Source:** `scripts/phase34-verification-assert.sh`  
**Apply to:** `scripts/phase35-voice-telemetry-assert.sh`
```bash
# Fail closed on root, trap cleanup, verify porcelain status invariance
trap cleanup EXIT
porcelain_snapshot > "$PORCELAIN_BEFORE"
# execute sections
porcelain_snapshot > "$PORCELAIN_AFTER"
cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"
```

### Pattern 4: Restow Symlink & No-Folding Verification
**Source:** `scripts/phase31-overlay-pill-assert.sh`  
**Apply to:** `scripts/phase35-voice-telemetry-assert.sh`
```bash
# Verify individual files are symlinks, while ancestor directories are real directories
test -L "$HOME/$FILE" && test ! -L "$(dirname "$HOME/$FILE")"
```

---

## No Analog Found

*None. All files planned for creation or modification in Phase 35 have exact analogs in the existing repository codebase or tracked submodules.*

---

## Metadata

**Analog search scope:**
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/`
- `restow/quickshell/.config/quickshell/ii/services/`
- `scripts/phase*.sh`
- `/home/pera/github_repo/Voice/voice.py`

**Files scanned:** 64  
**Pattern extraction date:** 2026-09-21  
