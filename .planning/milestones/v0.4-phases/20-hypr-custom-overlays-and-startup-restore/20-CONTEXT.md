# Phase 20: hypr/custom overlays and startup restore - Context

**Gathered:** 2026-09-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the complete personal Hyprland customization overlay for the Quickshell (ii) desktop shell, restoring lost autostart programs and establishing the first bulk stow link-identity layer:

1. **Overlay Link Inode Identity (HYPR-01):** All six custom overlay files in `~/.config/hypr/custom/{env,execs,general,rules,keybinds,variables}.lua` are managed symlinks resolving into `stow/hypr/.config/hypr/custom/`, verified via `arch/dots-hyprland.sh verify --strict`. No parent directory may be a symlink.
2. **Keybinds & Upstream Conflict Resolution (HYPR-02):** Author `custom/keybinds.lua` using `hl.unbind` for all replaced upstream binds (SUPER+C close, SUPER+D float, SUPER+ALT+D maximize, SUPER+H/L/K/J Vim focus, SUPER+P pseudo, SUPER+Z togglesplit, SUPER+M audio mute, SUPER+Space search, Scroll_Lock lock, SUPER+ALT+Scroll_Lock logout, special workspaces, relative cycling), with each bind labeled with `"Category: Label"` for ii cheatsheet integration.
3. **App Launcher & Defaults (HYPR-03):** Explicitly define user application preferences in `custom/variables.lua` (terminal, browser, fileManager, textEditor, taskManager, officeSoftware, workspaceGroupSize) so upstream discovery loops are bypassed without modifying vendor files.
4. **Startup Restoration (START-01):** Restore the lost autostart programs inside `custom/execs.lua` — Polkit KDE authentication agent, workspace-pinned applications (Chrome, kitty+tmux, btop, Vesktop/Discord), and the Phase 17 screen-share service.
5. **Stow Safety Drill & Verified Escape Route (SAFE-01):** Execute a timestamped `cp -a` backup, perform a `stow -n --no-folding` dry-run, rehearse the one-line undo drill (`stow -D -t ~ hypr` and backup restoration) live, re-stow, and gate completion behind `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`.
6. **Cursor Theme Glitch Purge:** Align GTK-3.0 and xsettingsd configurations to `Bibata-Modern-Classic 24` to eliminate the post-login Catppuccin cursor override.

Out of scope:
- Quickshell ii bar settings and widget layout (Phase 21).
- Full KDE/GTK config redistribution and capture (Phase 22 owns `gtk-3.0/settings.ini`, `kdeglobals`, etc., though cursor setting is aligned here to eliminate live session visual glitch).
- Modifying `vendor/dots-hyprland` submodule code.

</domain>

<decisions>
## Implementation Decisions

### Startup Applications (`custom/execs.lua` — START-01)

- **D-01:** Workspace-pinned applications are launched directly using `hl.exec_cmd("[workspace ...]")` syntax inside `hl.on("hyprland.start", function () ... end)`. Live testing confirmed direct string evaluation succeeds in Hyprland Lua. The autostart set consists of:
  - Chrome on workspace 1: `hl.exec_cmd("[workspace 1] google-chrome-stable --profile-directory='Default' --ozone-platform-hint=auto")`
  - Kitty with tmux on workspace 1: `hl.exec_cmd("[workspace 1] kitty -e tmux")`
  - btop on special:btop: `hl.exec_cmd("[workspace special:btop silent] kitty --class btop -e btop")`
  - Discord/Vesktop on special:social: `hl.exec_cmd("[workspace special:social silent] sh -c 'command -v vesktop >/dev/null 2>&1 && exec vesktop || exec discord'")`
  — **Reversibility:** reversible
- **D-02:** Polkit KDE authentication agent is restored via direct execution: `hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")` inside `hl.on("hyprland.start", ...)`. Verified installed at `/usr/lib/polkit-kde-authentication-agent-1`. — **Reversibility:** reversible
- **D-03:** `wl-clip-persist` is dropped. Upstream dots-hyprland runs `cliphist` integrated with Quickshell's clipboard service, which captures text and image clips upon copy events. Skipping `wl-clip-persist` avoids introducing uninstalled AUR packages and duplicate daemons. — **Reversibility:** reversible
- **D-04:** Session cursor theme remains the dots-hyprland default (`Bibata-Modern-Classic 24`) without an override in `custom/execs.lua`. Residual occurrences of `catppuccin-mocha-blue-cursors` in `~/.config/gtk-3.0/settings.ini` and `~/.config/xsettingsd/xsettingsd.conf` are aligned to `Bibata-Modern-Classic` (size 24) to prevent legacy cursor themes from leaking into GTK/XWayland applications after login. — **Reversibility:** reversible
- **D-05:** The Phase 17 screen-share service start (`systemctl --user start hyprland-session.service`) remains preserved in `custom/execs.lua` (START-02). — **Reversibility:** costly — required for xdg-desktop-portal graphical-session.target dependency

### Keybind Overrides & Upstream Conflicts (`custom/keybinds.lua` — HYPR-02)

- **D-06:** Upstream unbinds are executed at the top of `custom/keybinds.lua` using `hl.unbind`:
  - `hl.unbind("SUPER + C")` *(upstream code editor)*
  - `hl.unbind("SUPER + L")` *(upstream lock)*
  - `hl.unbind("SUPER + K")` *(upstream on-screen keyboard)*
  - `hl.unbind("SUPER + J")` *(upstream bar toggle)*
  - `hl.unbind("SUPER + D")` *(upstream maximize)*
  - `hl.unbind("SUPER + P")` *(upstream window pin)*
  - `hl.unbind("SUPER + M")` *(upstream media controls)*
  - `hl.unbind("SUPER + S")` *(upstream special scratchpad)*
- **D-07:** Window closing: `SUPER + C` is bound to `hl.dsp.window.close()` with cheatsheet description `"Window: Close"`. Code editor has no dedicated keybind and is accessed via menus/launcher.
- **D-08:** Window floating and maximizing: `SUPER + D` is bound to `hl.dsp.window.float({ action = "toggle" })` (`"Window: Float/Tile"`). `SUPER + ALT + D` is bound to `hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })` (`"Window: Toggle maximize"`). `SUPER + S` is unbound.
- **D-09:** Vim-style window focus navigation: `SUPER + H / L / K / J` are bound to `hl.dsp.focus({ direction = "l" / "r" / "u" / "d" })`. Arrows (`SUPER + Left/Right/Up/Down`) remain functional as secondary upstream binds.
- **D-10:** Dwindle pseudo-tiling and split toggling: `SUPER + P` is bound to `hl.dsp.window.pseudo()` (`"Window: Toggle pseudo-tile"`). `SUPER + Z` is bound to `hl.dsp.layout("togglesplit")` (`"Window: Toggle split layout"`).
- **D-11:** Audio mute: `SUPER + M` is bound to `hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")` (`"Audio: Toggle mute"`).
- **D-12:** App search & clipboard: `SUPER + Space` is bound to `hl.dsp.global("quickshell:searchToggleRelease")` (`"Shell: Toggle search"`). `SUPER + V` remains upstream `quickshell:overviewClipboardToggle`.
- **D-13:** Session locking and logout: `Scroll_Lock` is bound to `hl.dsp.exec_cmd("hyprlock")` (`"Session: Lock screen"`). `SUPER + ALT + Scroll_Lock` is bound to `hl.dsp.exit()` (`"Session: Logout"`).
- **D-14:** Special workspaces and relative workspace cycling:
  - `SUPER + \`` toggles `special:social` (`"Workspace: Toggle social"`)
  - `SUPER + SHIFT + \`` moves window to `special:social` (`"Window: Move to social"`)
  - `SUPER + -` toggles `special:btop` (`"Workspace: Toggle btop"`)
  - `SUPER + SHIFT + -` moves window to `special:btop` (`"Window: Move to btop"`)
  - `CTRL + SUPER + H / L` cycles relative workspaces (`e-1` / `e+1`)
  - `CTRL + SHIFT + SUPER + H / L` moves window to relative workspace (`e-1` / `e+1`)
- **D-15:** Cheatsheet taxonomy: All authored custom binds strictly follow the `"Category: Label"` format (`Window: ...`, `Workspace: ...`, `Shell: ...`, `Session: ...`, `Audio: ...`) ensuring clean grouping in Quickshell's `SUPER + /` cheatsheet.

### App Defaults & Overlay Files (`custom/variables.lua`, `custom/rules.lua`, `custom/env.lua` — HYPR-03, HYPR-01)

- **D-16:** Primary application variables are explicitly locked in `custom/variables.lua`:
  - `terminal = "kitty"`
  - `browser = "google-chrome-stable"`
  - `fileManager = "dolphin"`
  - `textEditor = "kitty -e nvim"`
  - `taskManager = "kitty --class btop -e btop"`
  - `officeSoftware = "libreoffice"`
  - `workspaceGroupSize = 10`
  - `hl.env("qsConfig", "ii")`
  Secondary variables (`codeEditor`, `volumeMixer`, `settingsApp`) use upstream `launch_first_available.sh` fallbacks.
- **D-17:** Custom window rules in `custom/rules.lua`: float rules for python tools from pre-adopt config:
  - `hl.window_rule({ match = { class = "^(main.py)$" }, float = true })`
  - `hl.window_rule({ match = { class = "^(python3)$" }, float = true })`
- **D-18:** `custom/env.lua` remains an empty require slot. Upstream `hyprland/env.lua` already sets Wayland, Qt platform themes, and virtualenv paths.
- **D-19:** `custom/general.lua` remains unchanged from Phase 13/18 (DP-1 and HDMI-A-2 dual-monitor layout and workspace 1–10 rules).

### Stow Migration & Safety Drill (`SAFE-01`, `HYPR-01`)

- **D-20:** Timestamped backup is created at `~/.config/hypr/custom.backup.<epoch>`.
- **D-21:** Migration drill procedure:
  1. Create timestamped backup of `~/.config/hypr/custom/`.
  2. Remove the 3 unmanaged plain stub files (`keybinds.lua`, `rules.lua`, `variables.lua`) from live `~/.config/hypr/custom/`.
  3. Dry-run stow: `stow -n -v --no-folding -t ~ hypr` from `stow/`.
  4. Execute bulk stow: `stow -v --no-folding -t ~ hypr`.
  5. Rehearse escape route live: `stow -D -t ~ hypr`, restore from `custom.backup.<epoch>`, verify state, then re-stow with clean links.
- **D-22:** Dedicated phase assert script `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` asserting:
  - All 6 files in `~/.config/hypr/custom/` are valid symlinks resolving into `stow/hypr/.config/hypr/custom/`.
  - No parent directory is a symlink.
  - `arch/dots-hyprland.sh verify --strict` exits 0.
  - No duplicate keybinds exist (`hyprctl binds -j` JSON parse).
  - Pre-adopt `exec-once` list is accounted for in `custom/execs.lua`.
- **D-23:** Two-stage verification: automated assertions run immediately; operator re-login check documented as an explicit manual post-step to verify window placement on fresh boot.

### Claude's Discretion

- Exact formatting and order of require/bind statements in `custom/keybinds.lua` and `custom/execs.lua`.
- Temporary directory structure used in assert script for non-destructive unit testing of the backup-undo drill logic.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §Phase 20 — goal statement, dependencies, 5 success criteria, verification risk
- `.planning/REQUIREMENTS.md` lines 33-59 — HYPR-01, HYPR-02, HYPR-03, START-01, SAFE-01

### Pre-adopt sources and historical contracts
- `docs/archive/hyprland.conf` — pre-adopt Hyprland configuration; lines 51-106 (`exec-once` list), 260-437 (binds), 458-475 (rules and env)
- `.planning/phases/13-personal-hypr-custom-overlays/13-CONTEXT.md` — monitors/workspaces layout contract (DP-1 and HDMI-A-2) and initial overlay require architecture
- `.planning/phases/18-capture-model-three-trees-and-the-collision-map/18-CONTEXT.md` — three-tree taxonomy (`stow/hypr/` ownership of `custom/`, `hyprland-gui.conf`, `hyprpaper.conf`)
- `.planning/phases/19-link-aware-verify/19-CONTEXT.md` — link verification contract, `--strict` and `--quiet` flags

### Upstream vendor contracts
- `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` — require order for `custom.{env,execs,general,rules,keybinds}`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/keybinds.lua` — upstream keybind definitions and `custom.variables` require hook
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/variables.lua` — default app launcher variables
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/execs.lua` — upstream default autostart processes and Bibata cursor invocation
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/rules.lua` — upstream window, layer, and workspace rules
- `/usr/share/hypr/stubs/hl.meta.lua` — Hyprland Lua API stubs documenting `hl.unbind`, `hl.dsp.exit()`, `hl.dsp.window.pseudo()`, `hl.dsp.layout()`

### System configurations touched
- `stow/hypr/.config/hypr/custom/` — repo tree receiving overlay files
- `~/.config/gtk-3.0/settings.ini` — GTK-3 cursor setting
- `~/.config/xsettingsd/xsettingsd.conf` — XSettings cursor setting

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `stow/hypr/.config/hypr/custom/execs.lua`: Already contains the START-02 `systemctl --user start hyprland-session.service` call inside `hl.on("hyprland.start", ...)`. The remaining autostart entries slot directly into this function.
- `stow/hypr/.config/hypr/custom/general.lua`: Already holds the complete DP-1 and HDMI-A-2 monitor specs and workspace rules (D-11/D-14 from Phase 13).
- `arch/dots-hyprland.sh verify`: Link-aware verification engine shipped in Phase 19.
- `scripts/phase19-link-aware-verify-assert.sh`: Established assert script pattern using `set -euo pipefail`, trap cleanup, and stderr/stdout separation.

### Established Patterns
- Link identity asserted before content: Every file in `stow/hypr/` must be an identical inode live (`test "$repo_file" -ef "$live_file"`).
- Universal `--no-folding`: Stow invocations must use `--no-folding` so ancestor directories (`~/.config/hypr/custom/`) remain real directories containing individual symlinks.
- Cheatsheet categorization: Every keybind description formatted as `"Category: Label"`.

### Integration Points
- `~/.config/hypr/custom/`: Live directory containing unmanaged upstream stubs (`keybinds.lua`, `rules.lua`, `variables.lua`) that will be transitioned to repo symlinks.
- `hyprctl reload`: IPC command to trigger dynamic reloading of Hyprland Lua configurations without restarting the compositor.

</code_context>

<specifics>
## Specific Ideas

- Direct evaluation of `[workspace N]` inside `hl.exec_cmd` was verified live using `hyprctl eval "return hl.exec_cmd('[workspace 1] true')"`.
- Session logout is mapped to `hl.dsp.exit()`.
- Catppuccin cursor override in GTK-3.0 and xsettingsd was diagnosed during discussion as the root cause of cursor visual discrepancies after login; aligning both to Bibata-Modern-Classic 24 fixes the issue across the desktop.

</specifics>

<deferred>
## Deferred Ideas

- Phase 21: Quickshell ii bar settings capture and dynamic theme handling.
- Phase 22: Full GTK/KDE tree capture into `restow/` and `stow/`.

</deferred>

---

*Phase: 20-hypr-custom-overlays-and-startup-restore*
*Context gathered: 2026-09-14*
