# Phase 20: hypr-custom-overlays-and-startup-restore - Pattern Map

**Mapped:** 2026-09-14  
**Files analyzed:** 9  
**Analogs found:** 9 / 9  

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `stow/hypr/.config/hypr/custom/keybinds.lua` | config | event-driven | `vendor/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua` | exact |
| `stow/hypr/.config/hypr/custom/variables.lua` | config | file-I/O | `vendor/dots-hyprland/dots/.config/hypr/hyprland/variables.lua` | exact |
| `stow/hypr/.config/hypr/custom/rules.lua` | config | event-driven | `vendor/dots-hyprland/dots/.config/hypr/hyprland/rules.lua` | exact |
| `stow/hypr/.config/hypr/custom/execs.lua` | config | event-driven | `vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua` | exact |
| `stow/hypr/.config/hypr/custom/env.lua` | config | file-I/O | `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` (lines 8–12) | exact |
| `stow/hypr/.config/hypr/custom/general.lua` | config | declaration | `stow/hypr/.config/hypr/custom/general.lua` (lines 1–28) | exact |
| `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` | test | batch | `scripts/phase19-link-aware-verify-assert.sh` | exact |
| `~/.config/gtk-3.0/settings.ini` | config | file-I/O | `~/.config/gtk-3.0/settings.ini` | exact |
| `~/.config/xsettingsd/xsettingsd.conf` | config | file-I/O | `~/.config/xsettingsd/xsettingsd.conf` | exact |

---

## Pattern Assignments

### `stow/hypr/.config/hypr/custom/keybinds.lua` (config, event-driven)

**Analog:** `vendor/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua`  
**API Reference:** `/usr/share/hypr/stubs/hl.meta.lua`  
**Pre-adopt Source:** `docs/archive/hyprland.conf` (lines 260–437)

#### Header & Authoring Pattern
Copied from `stow/hypr/.config/hypr/custom/general.lua` (lines 1–2):
```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.
```

#### Unbind-Before-Bind Pattern
Copied from `/usr/share/hypr/stubs/hl.meta.lua` (line 860) and `20-CONTEXT.md` (D-06):
```lua
-- Upstream unbinds (D-06, HYPR-02)
-- Must execute before binding new actions to avoid dual-action firing on identical key chords
hl.unbind("SUPER + C")     -- upstream code editor
hl.unbind("SUPER + L")     -- upstream lock
hl.unbind("SUPER + K")     -- upstream on-screen keyboard
hl.unbind("SUPER + J")     -- upstream bar toggle
hl.unbind("SUPER + D")     -- upstream maximize
hl.unbind("SUPER + P")     -- upstream window pin
hl.unbind("SUPER + M")     -- upstream media controls
hl.unbind("SUPER + S")     -- upstream special scratchpad
hl.unbind("SUPER + Minus") -- upstream zoom out (conflicts with special:btop)
```

#### Keybind & Cheatsheet Taxonomy Pattern
Pattern from `vendor/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua` (lines 12–36, 181, 189–196):
```lua
-- Window management (D-07, D-08, D-09, D-10)
hl.bind("SUPER + C", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind("SUPER + D", hl.dsp.window.float({ action = "toggle" }), { description = "Window: Float/Tile" })
hl.bind("SUPER + ALT + D", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Window: Toggle maximize" })
hl.bind("SUPER + P", hl.dsp.window.pseudo(), { description = "Window: Toggle pseudo-tile" })
hl.bind("SUPER + Z", hl.dsp.layout("togglesplit"), { description = "Window: Toggle split layout" })

-- Vim-style window focus navigation (D-09)
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }), { description = "Window: Focus left" })
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }), { description = "Window: Focus right" })
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }), { description = "Window: Focus up" })
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }), { description = "Window: Focus down" })

-- Audio controls (D-11)
hl.bind("SUPER + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { description = "Audio: Toggle mute" })

-- Shell search (D-12)
hl.bind("SUPER + Space", hl.dsp.global("quickshell:searchToggleRelease"), { description = "Shell: Toggle search" })

-- Session controls (D-13)
hl.bind("Scroll_Lock", hl.dsp.exec_cmd("hyprlock"), { description = "Session: Lock screen" })
hl.bind("SUPER + ALT + Scroll_Lock", hl.dsp.exit(), { description = "Session: Logout" })

-- Special workspaces (D-14)
hl.bind("SUPER + grave", hl.dsp.workspace.toggle_special("social"), { description = "Workspace: Toggle social" })
hl.bind("SUPER + SHIFT + grave", hl.dsp.window.move({ workspace = "special:social" }), { description = "Window: Move to social" })
hl.bind("SUPER + Minus", hl.dsp.workspace.toggle_special("btop"), { description = "Workspace: Toggle btop" })
hl.bind("SUPER + SHIFT + Minus", hl.dsp.window.move({ workspace = "special:btop" }), { description = "Window: Move to btop" })

-- Relative workspace cycling (D-14)
hl.bind("CTRL + SUPER + H", hl.dsp.focus({ workspace = "e-1" }), { description = "Workspace: Previous (relative)" })
hl.bind("CTRL + SUPER + L", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspace: Next (relative)" })
hl.bind("CTRL + SHIFT + SUPER + H", hl.dsp.window.move({ workspace = "e-1" }), { description = "Window: Move to previous workspace" })
hl.bind("CTRL + SHIFT + SUPER + L", hl.dsp.window.move({ workspace = "e+1" }), { description = "Window: Move to next workspace" })

-- Helper for quick user editing
hl.bind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), { description = "System: Edit user keybinds" })
```

---

### `stow/hypr/.config/hypr/custom/variables.lua` (config, file-I/O)

**Analog:** `vendor/dots-hyprland/dots/.config/hypr/hyprland/variables.lua` (lines 1–20)  
**Upstream Hook:** `vendor/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua` (lines 3–5)

#### Upstream Hook Pattern
Upstream `hyprland/keybinds.lua` lines 3–5 sources `custom.variables`:
```lua
require("hyprland.lib")
require("hyprland.variables")
if is_file_exists(HOME .. "/.config/hypr/custom/variables.lua") then
    require("custom.variables")
end
```

#### Application Preferences Pattern
Copied from `vendor/dots-hyprland/dots/.config/hypr/hyprland/variables.lua` (lines 4–19) and adjusted per `20-CONTEXT.md` (D-16):
```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.

-- Primary application preferences (HYPR-03 / D-16)
-- Explicit strings bypass upstream launch_first_available.sh discovery loops
terminal = "kitty"
browser = "google-chrome-stable"
fileManager = "dolphin"
textEditor = "kitty -e nvim"
taskManager = "kitty --class btop -e btop"
officeSoftware = "libreoffice"
workspaceGroupSize = 10

-- Quickshell config directory name
hl.env("qsConfig", "ii")

-- Note: Secondary variables (codeEditor, volumeMixer, settingsApp) intentionally
-- fall back to upstream launch_first_available.sh defined in hyprland/variables.lua.
```

---

### `stow/hypr/.config/hypr/custom/rules.lua` (config, event-driven)

**Analog:** `vendor/dots-hyprland/dots/.config/hypr/hyprland/rules.lua` (lines 10–13, 29–31)  
**Pre-adopt Source:** `docs/archive/hyprland.conf` (lines 458–467)

#### Window Rule Pattern
Copied from `vendor/dots-hyprland/dots/.config/hypr/hyprland/rules.lua` (lines 29–30) and adapted for pre-adopt Python graphic tools (D-17):
```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.

-- Floating rules for python graphical tools (D-17, docs/archive/hyprland.conf:458-467)
hl.window_rule({ match = { class = "^(main.py)$" }, float = true })
hl.window_rule({ match = { class = "^(python3)$" }, float = true })
```

---

### `stow/hypr/.config/hypr/custom/execs.lua` (config, event-driven)

**Analog:** `vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua` (lines 1–25)  
**Existing Source:** `stow/hypr/.config/hypr/custom/execs.lua` (lines 1–21)  
**Pre-adopt Source:** `docs/archive/hyprland.conf` (lines 55–106)

#### Autostart Lifecycle Pattern
Copied from `stow/hypr/.config/hypr/custom/execs.lua` (lines 18–20) and `vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua` (lines 1–25):
```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.

-- SCREEN-SHARE FIX (START-02). xdg-desktop-portal's ScreenCast path needs
-- graphical-session.target, and that target sets RefuseManualStart=yes, so
-- nothing can start it directly. hyprland-session.service carries
-- Wants=graphical-session.target, so starting the unit is what pulls the target
-- up; that dependency edge is the only reachable path to it.
--
-- Start only, never `enable`: the unit is Type=oneshot with RemainAfterExit=yes,
-- so one start per session is enough, and staying in state `linked` keeps the
-- `systemctl --user disable` footgun (START-03, docs/dots-hyprland-workflow.md)
-- out of reach.
--
-- The call sits INSIDE the handler because it is a former `exec-once`: it must
-- fire once per session, not on every config reload. This handler coexists with
-- the vendor one at hyprland/execs.lua because hyprland.lua requires
-- custom.execs after hyprland.execs.
hl.on("hyprland.start", function ()
    hl.exec_cmd("systemctl --user start hyprland-session.service")

    -- Authentication Agent (START-01 / D-02)
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    -- Workspace-pinned autostart applications (START-01 / D-01)
    hl.exec_cmd("[workspace 1] google-chrome-stable --profile-directory='Default' --ozone-platform-hint=auto")
    hl.exec_cmd("[workspace 1] kitty -e tmux")
    hl.exec_cmd("[workspace special:btop silent] kitty --class btop -e btop")
    hl.exec_cmd("[workspace special:social silent] sh -c 'command -v vesktop >/dev/null 2>&1 && exec vesktop || exec discord'")
end)
```

---

### `stow/hypr/.config/hypr/custom/env.lua` (config, file-I/O)

**Analog:** `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` (lines 8–12)

#### Sourcing & Require Slot Pattern
Upstream `hyprland.lua` checks for existence and requires `custom.env`:
```lua
-- Environment variables --
require("hyprland.env")
if is_file_exists(HOME .. "/.config/hypr/custom/env.lua") then
    require("custom.env")
end
```
`stow/hypr/.config/hypr/custom/env.lua` pattern (D-18):
```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.

-- Environment overrides (D-18 / HYPR-01)
-- Upstream hyprland/env.lua already configures Wayland, Qt, and Python virtualenv paths.
-- This file exists as a managed require slot for personal environment additions.
```

---

### `stow/hypr/.config/hypr/custom/general.lua` (config, declaration)

**Analog:** `stow/hypr/.config/hypr/custom/general.lua` (lines 1–28)

#### Dual Monitor & Workspace Allocation Pattern
Existing pattern preserved intact (D-19):
```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.

hl.monitor({
    output = "DP-1",
    mode = "preferred",
    position = "auto",
    scale = "auto"
})
hl.monitor({
    output = "HDMI-A-2",
    mode = "preferred",
    position = "auto",
    scale = 1.5,
    transform = 1
})

hl.workspace_rule({ workspace = "1", monitor = "DP-1" })
hl.workspace_rule({ workspace = "2", monitor = "DP-1" })
hl.workspace_rule({ workspace = "3", monitor = "DP-1" })
hl.workspace_rule({ workspace = "4", monitor = "DP-1" })
hl.workspace_rule({ workspace = "5", monitor = "DP-1" })
hl.workspace_rule({ workspace = "special:social", monitor = "DP-1" })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "9", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-2" })
```

---

### `~/.config/gtk-3.0/settings.ini` & `~/.config/xsettingsd/xsettingsd.conf` (config, file-I/O)

**Analog:** Live settings files in `~/.config/gtk-3.0/settings.ini` and `~/.config/xsettingsd/xsettingsd.conf`  
**Compositor Alignment:** `vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua` (line 24: `hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")`)

#### GTK-3.0 INI Cursor Setting Pattern
In `~/.config/gtk-3.0/settings.ini` (lines 5–6):
```ini
[Settings]
...
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
...
```

#### XSettings Configuration Pattern
In `~/.config/xsettingsd/xsettingsd.conf` (line 3):
```
Net/ThemeName "catppuccin-mocha-teal-standard+default"
Net/IconThemeName "Tela-circle-dracula-dark"
Gtk/CursorThemeName "Bibata-Modern-Classic"
Gtk/CursorThemeSize 24
Net/EnableEventSounds 1
EnableInputFeedbackSounds 0
Xft/Antialias 1
Xft/Hinting 1
Xft/HintStyle "hintslight"
Xft/RGBA "rgb"
```

---

### `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` (test, batch)

**Analog:** `scripts/phase19-link-aware-verify-assert.sh` (lines 1–142, 1720–1732)  
**Sibling Reference:** `scripts/phase18-capture-model-assert.sh` (lines 34–83)

#### Assert Framework Pattern
Copied from `scripts/phase19-link-aware-verify-assert.sh` (lines 64–80):
```bash
#!/usr/bin/env bash
# Phase 20 hypr/custom overlays and startup restore asserts (D-22).
# One script, one section per ROADMAP criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

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

#### Link & Inode Assertion Pattern (HYPR-01)
Adapted from `arch/dots-hyprland.sh` (lines 1010–1035) and `scripts/phase19-link-aware-verify-assert.sh`:
```bash
# Check that ~/.config/hypr/custom is a real directory, NOT a symlink (no folding)
if [[ -L "$HOME/.config/hypr/custom" ]]; then
  fail "HYPR-01: ~/.config/hypr/custom is a symlink (folding detected)"
else
  pass "HYPR-01: ~/.config/hypr/custom is a real directory"
fi

# Check each of the 6 files for symlink validity and exact inode equality
OVERLAY_FILES=(env.lua execs.lua general.lua keybinds.lua rules.lua variables.lua)
for f in "${OVERLAY_FILES[@]}"; do
  live="$HOME/.config/hypr/custom/$f"
  repo="$REPO_ROOT/stow/hypr/.config/hypr/custom/$f"
  if [[ ! -L "$live" ]]; then
    fail "HYPR-01: $live is not a symlink"
  elif [[ ! -e "$live" ]]; then
    fail "HYPR-01: $live is a dangling symlink"
  elif [[ "$live" -ef "$repo" ]]; then
    pass "HYPR-01: $live is identical inode to $repo"
  else
    fail "HYPR-01: $live does not resolve to $repo"
  fi
done

# Check that dots-hyprland.sh verify --strict exits 0
if "$REPO_ROOT/arch/dots-hyprland.sh" verify --strict >/dev/null 2>&1; then
  pass "HYPR-01: arch/dots-hyprland.sh verify --strict exited 0"
else
  fail "HYPR-01: arch/dots-hyprland.sh verify --strict exited non-zero"
fi
```

#### Keybind Conflict & Taxonomy Verification Pattern (HYPR-02)
Using Python or JQ to inspect `hyprctl binds -j`:
```bash
# Verify no duplicate keybinds exist for replaced combinations and all custom binds match "Category: Label"
python3 - << 'EOF'
import json, subprocess, sys

raw = subprocess.check_output(["hyprctl", "binds", "-j"])
binds = json.loads(raw)

# Check replaced combinations (SUPER + C, L, K, J, D, P, M, S, Minus)
# modmask: 64 = SUPER
conflicts = {"C": 64, "L": 64, "K": 64, "J": 64, "D": 64, "P": 64, "M": 64, "S": 64, "minus": 64}
counts = {}
for b in binds:
    key = b.get("key", "").lower()
    mod = b.get("modmask", 0)
    for ck, cm in conflicts.items():
        if key == ck.lower() and mod == cm:
            counts[ck] = counts.get(ck, 0) + 1

duplicates = [k for k, v in counts.items() if v > 1]
if duplicates:
    print(f"[FAIL] Duplicate keybinds detected for: {duplicates}", file=sys.stderr)
    sys.exit(1)

# Check custom bind descriptions follow Category: Label format
# ...
EOF
```

#### Non-Destructive Drill Logic Verification Pattern (SAFE-01)
Copied from `scripts/phase19-link-aware-verify-assert.sh` (fixture isolation pattern):
```bash
# Build isolated scratch fixture for backup, stow, undo drill, and restore
DRILL_ROOT="$(mktemp -d /tmp/p20-drill-XXXXXX)"
SCRATCH_ROOTS+=("$DRILL_ROOT")

mkdir -p "$DRILL_ROOT/repo/stow/pkg/.config/sample" "$DRILL_ROOT/home/.config/sample"
printf 'v1\n' > "$DRILL_ROOT/repo/stow/pkg/.config/sample/file.txt"
printf 'legacy\n' > "$DRILL_ROOT/home/.config/sample/file.txt"

# 1. Backup
BACKUP_DIR="$DRILL_ROOT/home/.config/sample.backup"
cp -a "$DRILL_ROOT/home/.config/sample" "$BACKUP_DIR"

# 2. Remove stub
rm "$DRILL_ROOT/home/.config/sample/file.txt"

# 3. Stow dry-run & stow
( cd "$DRILL_ROOT/repo/stow" && stow -n --no-folding -t "$DRILL_ROOT/home" pkg )
( cd "$DRILL_ROOT/repo/stow" && stow --no-folding -t "$DRILL_ROOT/home" pkg )
test -L "$DRILL_ROOT/home/.config/sample/file.txt"

# 4. Rehearse undo
( cd "$DRILL_ROOT/repo/stow" && stow -D -t "$DRILL_ROOT/home" pkg )
cp -a "$BACKUP_DIR/." "$DRILL_ROOT/home/.config/sample/"
[[ "$(cat "$DRILL_ROOT/home/.config/sample/file.txt")" == "legacy" ]]
test ! -L "$DRILL_ROOT/home/.config/sample/file.txt"

pass "SAFE-01: non-destructive stow backup-undo-restore rehearsal succeeded in isolated fixture"
```

#### Closing Verdict Pattern
Copied from `scripts/phase19-link-aware-verify-assert.sh` (lines 1727–1731):
```bash
echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

---

## Shared Patterns

### 1. File Header & Single Source of Truth
**Source:** `stow/hypr/.config/hypr/custom/general.lua` (lines 1–2)  
**Apply to:** All authored files under `stow/hypr/.config/hypr/custom/*.lua`
```lua
-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.
```
*Rationale:* Clarifies repo ownership and prevents accidental commits into the `vendor/dots-hyprland` git submodule.

### 2. Quickshell Cheatsheet Taxonomy
**Source:** `vendor/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua` & `~/.config/quickshell/ii/services/HyprlandKeybinds.qml`  
**Apply to:** All keybind descriptions in `stow/hypr/.config/hypr/custom/keybinds.lua`
```lua
-- Format: "Category: Action label"
hl.bind("SUPER + C", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind("SUPER + D", hl.dsp.window.float({ action = "toggle" }), { description = "Window: Float/Tile" })
hl.bind("SUPER + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { description = "Audio: Toggle mute" })
hl.bind("SUPER + Space", hl.dsp.global("quickshell:searchToggleRelease"), { description = "Shell: Toggle search" })
hl.bind("Scroll_Lock", hl.dsp.exec_cmd("hyprlock"), { description = "Session: Lock screen" })
```
*Rationale:* Quickshell's cheatsheet module parses `description` on `:` to group bindings under tabbed category cards. Omission or non-standard formatting results in unorganized or missing UI items.

### 3. Former `exec-once` Autostart Encapsulation
**Source:** `vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua` (lines 1–3) & `stow/hypr/.config/hypr/custom/execs.lua` (lines 14–20)  
**Apply to:** All autostart and daemon commands in `stow/hypr/.config/hypr/custom/execs.lua`
```lua
hl.on("hyprland.start", function ()
    -- commands executed strictly once at session start
end)
```
*Rationale:* Hyprland re-evaluates top-level Lua code on every `hyprctl reload`. Commands outside `hl.on("hyprland.start", ...)` would re-execute on every reload, spawning duplicate browser and terminal windows.

### 4. GNU Stow Universal `--no-folding`
**Source:** `arch/dots-hyprland.sh` & Phase 17/18/19 conventions  
**Apply to:** All `stow` CLI operations across migrations, rehearsals, and assert fixtures
```bash
stow -v --no-folding -t ~ <package>
```
*Rationale:* Without `--no-folding`, GNU Stow folds entire directories (e.g. `~/.config/hypr/custom/`) into a single symlink, breaking local file additions and violating HYPR-01 ("no parent directory is itself a symlink").

### 5. Inode Link Identity Verification
**Source:** `arch/dots-hyprland.sh` (lines 1010–1035)  
**Apply to:** Assert checks verifying live configuration links
```bash
test "$repo_file" -ef "$live_file"
```
*Rationale:* `test -ef` verifies that the live symlink resolves to the exact file inode in the git repository, proving real-time bidirectionality and preventing silent copy drift.

### 6. Cursor Consistency Parity
**Source:** `vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua` (line 24)  
**Apply to:** `~/.config/gtk-3.0/settings.ini` & `~/.config/xsettingsd/xsettingsd.conf`
```ini
# Bibata-Modern-Classic size 24 unified across all toolkits
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
```
*Rationale:* Aligns Wayland compositor, GTK-3, and XWayland cursor definitions, preventing cursor visual jumping and size popping during window transitions.

### 7. Phase Assert Harness Contract
**Source:** `scripts/phase19-link-aware-verify-assert.sh` (lines 64–80, 1727–1731)  
**Apply to:** `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`
```bash
set -euo pipefail
FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
# ...
echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
```
*Rationale:* Adheres to dotfiles repo test harness standards (four prefixes `[PASS]`, `[FAIL]`, `[FINDING]`, `[INFO]`, two counters `FAIL` and `FINDINGS`, and strict exit 0/1 gate).

---

## No Analog Found

*None. All 9 files have exact analogs in the existing repository or vendor codebase.*

---

## Metadata

**Analog search scope:**  
- `stow/hypr/.config/hypr/custom/`  
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/`  
- `scripts/`  
- `~/.config/gtk-3.0/`  
- `~/.config/xsettingsd/`  
- `/usr/share/hypr/stubs/`  
- `docs/archive/hyprland.conf`  

**Files scanned:** 16  
**Pattern extraction date:** 2026-09-14  
