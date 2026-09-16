# Phase 20: hypr/custom overlays and startup restore - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-14
**Phase:** 20-hypr-custom-overlays-and-startup-restore
**Areas discussed:** Startup Applications (custom/execs.lua), Keybind Overrides & Conflicts (custom/keybinds.lua), Default App Variables (custom/variables.lua), Stow Migration & Safety Drill (SAFE-01)

---

## Startup Applications (custom/execs.lua)

| Option | Description | Selected |
|--------|-------------|----------|
| Direct `hl.exec_cmd("[workspace ...]")` | Direct prefix inside `hl.on("hyprland.start", ...)` (mirrors pre-adopt lines) | ✓ |
| `hyprctl dispatch exec` wrapper | Explicit IPC dispatch fallback documented in Q4 | |
| Split rules and execs | Launch raw binaries in execs and window rules in rules.lua | |

**User's choice:** Direct `hl.exec_cmd` with workspace rules prefix. Live testing with `hyprctl eval` confirmed valid syntax.

| Option | Description | Selected |
|--------|-------------|----------|
| Direct execution | `hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")` | ✓ |
| Existence-guarded launch | Guard with `test -x /usr/lib/polkit-kde-authentication-agent-1` | |

**User's choice:** Direct execution: `hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")`. Verified installed.

| Option | Description | Selected |
|--------|-------------|----------|
| Guarded execution + ensure installed | Guard command and install from AUR | |
| Strict execution | Enforce package installation | |
| Skip `wl-clip-persist` | Rely on upstream cliphist + quickshell clipboard service | ✓ |

**User's choice:** Skip it, relying on default dots-hyprland behavior (Quickshell clipboard + cliphist).

| Option | Description | Selected |
|--------|-------------|----------|
| Upstream dots-hyprland default | `Bibata-Modern-Classic 24` | ✓ |
| Restore personal Catppuccin cursor | `hyprctl setcursor catppuccin-mocha-dark-cursors 30` | |

**User's choice:** Keep dots-hyprland default. Note from operator: personal Catppuccin cursor was leaking after login; investigation showed `gtk-3.0/settings.ini` and `xsettingsd.conf` hardcoding it, so both will be cleansed to Bibata-Modern-Classic 24.

---

## Keybind Overrides & Conflicts (custom/keybinds.lua)

| Option | Description | Selected |
|--------|-------------|----------|
| Adopt upstream ii standard | Use `SUPER + Q` to close windows, keep `SUPER + C` for code editor | |
| Restore personal bind | `hl.unbind("SUPER + C")` and bind `SUPER + C` to close window; no bind for code editor | ✓ |

**User's choice:** Restore personal bind for `SUPER + C` (close window); code editor left to menus.

| Option | Description | Selected |
|--------|-------------|----------|
| Use Quickshell native clipboard & search | Keep `SUPER + V` as native clipboard; bind `SUPER + Space` to search | ✓ |
| Restore rofi clipboard & menu | Unbind `SUPER + V` for rofi; `SUPER + Space` for rofi drun | |

**User's choice:** Native Quickshell clipboard (`SUPER + V`) and native Quickshell search (`SUPER + Space`).

| Option | Description | Selected |
|--------|-------------|----------|
| Use Quickshell right sidebar | Keep `SUPER + N` as `quickshell:sidebarRightToggle` | ✓ |
| Restore swaync | `hl.unbind("SUPER + N")` and bind to `swaync-client -t -sw` | |

**User's choice:** Keep upstream `SUPER + N` for Quickshell right sidebar & notifications.

| Option | Description | Selected |
|--------|-------------|----------|
| Restore special workspaces and lock | `Super + \`` (social), `Super + -` (btop), `Scroll_Lock` -> hyprlock; native screenshots | ✓ |
| Full personal set including hyprshot | Special workspaces + hyprshot scripts | |

**User's choice:** Restore special workspaces and lock key; use native Quickshell screenshot selector.

| Conflict | Old Config | Upstream | Selected Resolution |
|----------|------------|----------|---------------------|
| Window focus HJKL | Focus l/r/u/d | Arrow keys / lock / OSK / bar | Unbind upstream L, K, J; restore Vim HJKL focus |
| `SUPER + D` / `SUPER + S` | S = float, D = define.sh | D = maximize, S = scratchpad | `SUPER + D` = float; `SUPER + ALT + D` = maximize; `SUPER + S` = unbound |
| Pseudo-tiling & split | P = pseudo, Z = togglesplit | P = pin, Z = unbound | Unbind P; `SUPER + P` = pseudo; `SUPER + Z` = togglesplit |
| Audio Mute & Logout | M = exit | M = media controls | Unbind M; `SUPER + M` = mute (`wpctl`); `SUPER + ALT + Scroll_Lock` = logout |
| Relative cycling | CTRL + SUPER + H/L | Unbound | Restore `CTRL + SUPER + H/L` (cycle) & with Shift (move) |

**User's choice:** Adopt the unified keybind table with all conflicts resolved and `"Category: Label"` cheatsheet taxonomy.

---

## Default App Variables (custom/variables.lua)

| Option | Description | Selected |
|--------|-------------|----------|
| Explicitly pin primary apps | Terminal (kitty), browser (chrome), fileManager (dolphin), textEditor (kitty -e nvim), taskManager (btop), officeSoftware (libreoffice) | ✓ |
| Rely on upstream search scripts | Fallback list | |

**User's choice:**
- `terminal = "kitty"`
- `browser = "google-chrome-stable"`
- `fileManager = "dolphin"`
- `textEditor = "kitty -e nvim"`
- `taskManager = "kitty --class btop -e btop"`
- `officeSoftware = "libreoffice"`
- `workspaceGroupSize = 10`
- `hl.env("qsConfig", "ii")`
- Secondary apps (code editor, volume mixer, settings) use upstream fallbacks.

| Option | Description | Selected |
|--------|-------------|----------|
| Include python float rules in `custom/rules.lua` | Float `^(main.py)$` and `^(python3)$` | ✓ |
| Keep `custom/rules.lua` empty | Upstream rules only | |

**User's choice:** Include python float window rules in `custom/rules.lua`. `custom/env.lua` remains an empty require slot.

---

## Stow Migration & Safety Drill (SAFE-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Config-scoped timestamped backup | `~/.config/hypr/custom.backup.<epoch>` | ✓ |
| Central dotfiles cache backup | `~/.cache/dotfiles-backups/...` | |

**User's choice:** Create timestamped backup at `~/.config/hypr/custom.backup.<epoch>`.

| Option | Description | Selected |
|--------|-------------|----------|
| Live drill execution | Backup -> dry-run -> stow -> test undo (`stow -D` & restore) -> re-stow -> verify | ✓ |
| Harness-only rehearsal | Temporary subshell fixture | |

**User's choice:** Rehearse the undo drill live to fulfill SAFE-01 criterion 5.

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated phase assert script | `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` | ✓ |
| Inline checks only | Run ad-hoc checks | |

**User's choice:** Create dedicated assert script asserting all 6 links, `verify --strict` exit 0, and no duplicate binds.

| Option | Description | Selected |
|--------|-------------|----------|
| Two-stage verification | Automated checks run immediately; fresh login checklist documented for operator | ✓ |
| Prompt operator during run | Interactive block | |

**User's choice:** Two-stage verification.

---

## Claude's Discretion

- Exact code ordering and formatting in `custom/keybinds.lua`, `custom/variables.lua`, `custom/rules.lua`, and `custom/execs.lua`.
- Temp fixture construction inside the phase assert script.

## Deferred Ideas

- Phase 21: Quickshell ii bar settings and dynamic wallpaper theming capture.
- Phase 22: Full GTK/KDE tree capture into `restow/` and `stow/`.
