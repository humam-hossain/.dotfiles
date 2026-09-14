# Phase 21: ii bar config capture - Pattern Map

**Mapped:** 2026-09-15
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `arch/dots-hyprland.sh` | controller / utility | request-response / file-I/O | `arch/dots-hyprland.sh` (lines 750-875, 1394-1518) | exact |
| `arch/hyprland.sh` | utility / setup script | batch / request-response | `arch/hyprland.sh` (lines 41-47) | exact |
| `capture/ii/.config/illogical-impulse/config.json` | config | file-I/O | `stow/swaync/.config/swaync/config.json` | exact |
| `stow/systemd/.config/systemd/user/dotfiles-capture.service` | config / service unit | event-driven / batch | `stow/systemd/.config/systemd/user/hyprland-session.service` | exact |
| `stow/systemd/.config/systemd/user/dotfiles-capture.timer` | config / timer unit | event-driven | `stow/systemd/.config/systemd/user/hyprland-session.service` | role-match |
| `scripts/phase21-ii-bar-config-capture-assert.sh` | test / assert harness | batch / verification | `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` | exact |

---

## Pattern Assignments

### 1. `arch/dots-hyprland.sh` (controller / utility, request-response / file-I/O)

**Analog:** `arch/dots-hyprland.sh` (`run_verify` at [arch/dots-hyprland.sh:750-875](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L750-L875), `run_capture` at [arch/dots-hyprland.sh:1394-1518](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1394-L1518))

**CLI Flag Parsing & Unknown Flag Guard** ([arch/dots-hyprland.sh:1395-1417](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1395-L1417)):
```bash
  local dry_run=0
  local quiet=0
  local notify=0
  local -a unknown=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      -h|--help)
        usage
        exit 0
        ;;
      --dry-run)
        dry_run=1
        ;;
      --quiet)
        quiet=1
        ;;
      --notify)
        notify=1
        ;;
      *)
        unknown+=("$arg")
        ;;
    esac
  done

  if ((${#unknown[@]} > 0)); then
    echo "[FAIL] Unknown capture flag(s): ${unknown[*]}" >&2
    echo "[FAIL] See: ./arch/dots-hyprland.sh help" >&2
    exit 1
  fi
```

**Quiet Helper Logging (Avoiding short-circuit `&&` under `set -e`)** ([arch/dots-hyprland.sh:867-875](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L867-L875)):
```bash
  # D-20: --quiet suppresses [PASS] lines ONLY. Written as an `if` block, never
  # as a trailing `((quiet)) && return`-style conjunction: as the last command
  # of a function that form leaves the return status at 1 whenever quiet is 0,
  # which aborts the `set -euo pipefail` caller at the first passing check.
  pass() {
    if ((quiet == 0)); then
      printf '[PASS] %s\n' "$1"
    fi
  }
  fail() { printf '[FAIL] %s\n' "$1"; fail_count=$((fail_count + 1)); }
  finding() { printf '[FINDING] %s\n' "$1"; finding_count=$((finding_count + 1)); }
  info() {
    if ((quiet == 0)); then
      printf '[INFO] %s\n' "$1"
    fi
  }
```

**Security Guards and Capturability Checks** ([arch/dots-hyprland.sh:1440-1498](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1440-L1498)):
```bash
  mirror_is_capturable() {
    local p="$1"
    if [[ ! -e "$p" ]]; then
      finding "repo mirror does not exist: $p"
      return 1
    fi
    if ! git ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then
      finding "repo mirror is untracked (no HEAD version to recover): $p"
      return 1
    fi
    if ! git diff --quiet HEAD -- "$p"; then
      finding "repo mirror is dirty against HEAD: $p"
      return 1
    fi
    return 0
  }

  # Under package walk loop:
  # 1. Repo mirror must live under capture/ (resolved paths)
  local repo_real
  repo_real="$(realpath -m -- "$repo_file")"
  if [[ "$repo_real" != "$capture_real"/* ]]; then
    fail "repo mirror not under capture/: $repo_file"
    continue
  fi

  # 2. Test repo mirror capturability (untracked / dirty against HEAD)
  if ! mirror_is_capturable "$repo_file"; then
    continue
  fi

  # 3. Live path must not be a symlink resolving into the repo
  if [[ -L "$live" ]]; then
    local live_target
    live_target="$(readlink -f -- "$live" || true)"
    if [[ "$live_target" == "$main_root"/* || "$live_target" == "$REPO_ROOT"/* ]]; then
      fail "refusing live path that is a symlink resolving into repo: $live -> $live_target"
      continue
    fi
  fi

  # 4. Live counterpart missing check
  if [[ ! -e "$live" && ! -L "$live" ]]; then
    finding "live counterpart missing: $live (repo copy kept intact)"
    continue
  fi
```

**Core Ingest Pipeline: `cmp -s`, `jq empty` & Atomic Replace (BAR-01, D-01–D-06)**:
```bash
  # 5. Change detection: skip byte-identical files (avoids disk writes & jq forks)
  if cmp -s -- "$live" "$repo_file"; then
    info "unchanged: $live"
    continue
  fi

  # 6. Format validation: generic check for *.json (fails closed on 0-byte or corrupt JSON)
  if [[ "$live" == *.json ]]; then
    if [[ ! -s "$live" ]] || ! jq empty "$live" >/dev/null 2>&1; then
      fail "invalid or empty JSON: $live"
      continue
    fi
  fi

  # 7. Atomic write into git working tree via temporary file rename
  if ((dry_run == 1)); then
    info "dry-run: would copy $live -> $repo_file"
  else
    local tmp_repo="${repo_file}.tmp.$$"
    if cp -p -- "$live" "$tmp_repo" && mv -f -- "$tmp_repo" "$repo_file"; then
      pass "captured: $live -> $repo_file"
      captured_count=$((captured_count + 1))
    else
      rm -f -- "$tmp_repo" 2>/dev/null || true
      fail "failed to copy $live -> $repo_file"
    fi
  fi
```

**Notification Dispatch Pattern (D-12, D-13)**:
```bash
  # Desktop notification only when updates were written and --notify passed
  if ((notify == 1 && captured_count > 0)); then
    notify-send "Dotfiles Capture" "Captured updates to repository" -a "Shell" -u low || true
  fi
```

---

### 2. `arch/hyprland.sh` (utility / setup script, batch / request-response)

**Analog:** `arch/hyprland.sh` ([arch/hyprland.sh:41-47](file:///home/pera/github_repo/.dotfiles/arch/hyprland.sh#L41-L47))

**Repository Root Resolution & Strict Shell Header** ([arch/hyprland.sh:1-12](file:///home/pera/github_repo/.dotfiles/arch/hyprland.sh#L1-L12)):
```bash
#!/usr/bin/env bash
set -euo pipefail
set -x

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```

**Stow Invocation and Systemd Unit Activation** ([arch/hyprland.sh:41-44](file:///home/pera/github_repo/.dotfiles/arch/hyprland.sh#L41-L44)):
```bash
echo "[CONFIG] Graphical Session Bootstrap (systemd xdg-desktop-portal fix)"
cd "$REPO_ROOT/stow" && stow --verbose=5 --no-folding -t ~ systemd
systemctl --user daemon-reload || true
```

**Wiring Pattern for `dotfiles-capture.timer` (D-14, CAP-06)**:
```bash
echo "[CONFIG] Graphical Session Bootstrap (systemd xdg-desktop-portal fix)"
cd "$REPO_ROOT/stow" && stow --verbose=5 --no-folding -t ~ systemd
systemctl --user daemon-reload || true
systemctl --user enable --now dotfiles-capture.timer || true
systemctl --user restart dotfiles-capture.timer || true
```

---

### 3. `capture/ii/.config/illogical-impulse/config.json` (config, file-I/O)

**Analog:** `stow/swaync/.config/swaync/config.json` ([stow/swaync/.config/swaync/config.json:1-30](file:///home/pera/github_repo/.dotfiles/stow/swaync/.config/swaync/config.json#L1-L30)) and live `~/.config/illogical-impulse/config.json` ([~/.config/illogical-impulse/config.json:200-245](file:///home/pera/.config/illogical-impulse/config.json#L200-L245))

**Directory Hierarchy Contract (D-15, D-38)**:
`capture/<pkg>/<rel_to_home>`: The package name is `ii`, and relative path is `.config/illogical-impulse/config.json`, mapping to `$HOME/.config/illogical-impulse/config.json`.

**JSON Configuration Layout & Formatting (4-space indentation, no synthetic diffs)**:
```json
{
    "ai": {
        "extraModels": [ ... ],
        "systemPrompt": "...",
        "tool": "functions"
    },
    "appearance": {
        "extraBackgroundTint": true,
        "fakeScreenRounding": 2,
        "fonts": {
            "expressive": "Space Grotesk",
            "iconNerd": "JetBrains Mono NF",
            "main": "Google Sans Flex",
            "monospace": "JetBrains Mono NF",
            "numbers": "Google Sans Flex",
            "reading": "Readex Pro",
            "title": "Google Sans Flex"
        },
        "palette": {
            "accentColor": "",
            "type": "auto"
        },
        "transparency": {
            "automatic": true,
            "backgroundTransparency": 0.11,
            "contentTransparency": 0.57,
            "enable": false
        },
        "wallpaperTheming": {
            "enableAppsAndShell": true,
            "enableQtApps": true,
            "enableTerminal": true
        }
    },
    "bar": {
        "autoHide": {
            "enable": false,
            "hoverRegionWidth": 2,
            "pushWindows": false,
            "showWhenPressingSuper": {
                "delay": 140,
                "enable": true
            }
        },
        "borderless": false,
        "bottom": false,
        "cornerStyle": 0,
        "floatStyleShadow": true,
        "topLeftIcon": "spark",
        "utilButtons": {
            "showColorPicker": true,
            "showDarkModeToggle": false,
            "showKeyboardToggle": true,
            "showMicToggle": true,
            "showPerformanceProfileToggle": true,
            "showScreenRecord": false,
            "showScreenSnip": true
        },
        "weather": {
            "city": "Dhaka",
            "enable": true,
            "enableGPS": false,
            "fetchInterval": 10,
            "useUSCS": false
        },
        "workspaces": {
            "alwaysShowNumbers": true,
            "monochromeIcons": true,
            "numberMap": [],
            "showAppIcons": true,
            "showNumberDelay": 300,
            "shown": 5,
            "useNerdFont": false
        }
    }
}
```

**Scope Exclusions (D-17)**:
- Upstream installer state files (`installed_listfile`, `installed_true`) and runtime directories (`actions/`) must be omitted from `capture/ii/`.

---

### 4. `stow/systemd/.config/systemd/user/dotfiles-capture.service` (config / service unit, event-driven / batch)

**Analog:** `stow/systemd/.config/systemd/user/hyprland-session.service` ([stow/systemd/.config/systemd/user/hyprland-session.service:1-16](file:///home/pera/github_repo/.dotfiles/stow/systemd/.config/systemd/user/hyprland-session.service#L1-L16))

**Unit Structure & Service Pattern**:
```ini
[Unit]
Description=Capture dotfiles from live environment to repository mirror
Documentation=file://%h/github_repo/.dotfiles/capture/README.md

[Service]
Type=oneshot
WorkingDirectory=%h/github_repo/.dotfiles
ExecStart=%h/github_repo/.dotfiles/arch/dots-hyprland.sh capture --quiet --notify
Nice=19
TimeoutStartSec=30s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dotfiles-capture
PassEnvironment=WAYLAND_DISPLAY DISPLAY DBUS_SESSION_BUS_ADDRESS
SuccessExitStatus=0 1
```

**Key Parameters Rationale**:
- `Type=oneshot`: Runs the capture task to completion and exits.
- `Nice=19`: Lowest CPU scheduling priority to guarantee zero desktop stutter during capture ticks.
- `PassEnvironment`: Exports Wayland/DBus session environment variables into the oneshot execution so `notify-send` reaches the desktop notification daemon (`swaync`).
- `SuccessExitStatus=0 1`: Treats exit code 1 (skipped dirty repo mirrors / invalid JSON) as acceptable non-failure in systemd status while logging full output to journal.

---

### 5. `stow/systemd/.config/systemd/user/dotfiles-capture.timer` (config / timer unit, event-driven)

**Analog:** `stow/systemd/.config/systemd/user/hyprland-session.service` ([stow/systemd/.config/systemd/user/hyprland-session.service:7-11](file:///home/pera/github_repo/.dotfiles/stow/systemd/.config/systemd/user/hyprland-session.service#L7-L11))

**Unit & Timer Pattern (D-08, CAP-06)**:
```ini
[Unit]
Description=Periodic capture of live dotfiles to repository mirror
Documentation=file://%h/github_repo/.dotfiles/capture/README.md

[Timer]
OnStartupSec=2m
OnUnitActiveSec=15m
Persistent=true

[Install]
WantedBy=timers.target
```

**Key Parameters Rationale**:
- `OnStartupSec=2m`: Delays initial run until 2 minutes post-boot to allow desktop services (Quickshell, Swaync, Hyprland) to stabilize.
- `OnUnitActiveSec=15m`: Runs every 15 minutes after the previous run completes.
- `Persistent=true`: Ensures that if the machine was sleeping or powered off when a timer tick was scheduled, it executes immediately upon wake/boot.
- `WantedBy=timers.target`: Standard systemd user target for enabling periodic timers.

---

### 6. `scripts/phase21-ii-bar-config-capture-assert.sh` (test / assert harness, batch / verification)

**Analog:** `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` ([scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh:1-63, 553-560](file:///home/pera/github_repo/.dotfiles/scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh#L1-L63)) and `scripts/phase18-capture-model-assert.sh` ([scripts/phase18-capture-model-assert.sh:910-958](file:///home/pera/github_repo/.dotfiles/scripts/phase18-capture-model-assert.sh#L910-L958))

**Harness Boilerplate, Strict Mode & Teardown Trap**:
```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

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
```

**Section-based Execution Pattern (`--section <1-7>`)**:
```bash
RUN_SECTION=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --section)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-7]$ ]]; then
        echo "Error: --section requires an integer from 1 to 7" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-7>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done
```

**Isolated Scratch Fixture Setup (from Phase 18/20)**:
```bash
S_ROOT="$(mktemp -d /tmp/p21-assert-sX-XXXXXX)"
SCRATCH_ROOTS+=("$S_ROOT")

mkdir -p "$S_ROOT/repo/capture/testpkg/.config/testpkg"
mkdir -p "$S_ROOT/home/.config/testpkg"
git init -q "$S_ROOT/repo"
# configure mock repo for tests...
```

**Summary Exit Verdict**:
```bash
echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

---

## Shared Patterns

### Diagnostic Output & Counter Idiom
**Source:** `arch/dots-hyprland.sh` ([arch/dots-hyprland.sh:867-875](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L867-L875)) and `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` ([scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh:18-21](file:///home/pera/github_repo/.dotfiles/scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh#L18-L21))  
**Apply to:** `arch/dots-hyprland.sh` and `scripts/phase21-ii-bar-config-capture-assert.sh`  
All output functions write with explicit tags (`[PASS]`, `[FAIL]`, `[FINDING]`, `[INFO]`). `pass()` and `info()` conditional suppression under `--quiet` must always use full `if ((quiet == 0)); then ... fi` statements to prevent `set -e` aborts when the conditional expression evaluates to false.

### Fail-Closed Validation Guard
**Source:** `arch/dots-hyprland.sh` ([arch/dots-hyprland.sh:1440-1455](file:///home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh#L1440-L1455))  
**Apply to:** `arch/dots-hyprland.sh` (`run_capture`)  
Capture operations must validate untrusted live state before copying into repository mirrors. For JSON files, validation requires both non-zero file size (`[[ -s "$live" ]]`) and syntax validation (`jq empty "$live"`). If validation fails, log `[FAIL]`, skip the file, leave the repository copy intact, and exit non-zero at the end of the run.

### Atomic Ingest via Temp-File Rename
**Source:** `vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh` ([vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh:147](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/scripts/colors/switchwall.sh#L147))  
**Apply to:** `arch/dots-hyprland.sh` (`run_capture`)  
Writes into the git working tree must never use raw stream redirection or direct `cat`. Files are copied with attributes intact (`cp -p -- "$live" "$tmp"`) to a unique temporary file (`$repo_file.tmp.$$`), followed by an atomic replacement (`mv -f -- "$tmp" "$repo_file"`).

### Stow-Managed Systemd User Configuration
**Source:** `stow/systemd/.config/systemd/user/hyprland-session.service` and `arch/hyprland.sh:41-44`  
**Apply to:** `stow/systemd/.config/systemd/user/dotfiles-capture.{service,timer}`  
Systemd user units are versioned in `stow/systemd/` mirroring the user XDG structure `~/.config/systemd/user/`. Activation is performed via `stow --verbose=5 --no-folding -t ~ systemd` followed by `systemctl --user daemon-reload`.

---

## No Analog Found

None. All files have concrete, tracked analogs in the repository.

---

## Metadata

**Analog search scope:**
- `arch/dots-hyprland.sh`
- `arch/hyprland.sh`
- `stow/` (systemd, swaync, hypr, etc.)
- `scripts/` (phase18, phase19, phase20 assert scripts)
- `~/.config/illogical-impulse/config.json`

**Files scanned:** 26  
**Pattern extraction date:** 2026-09-15
