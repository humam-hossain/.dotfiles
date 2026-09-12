# Feature Research

**Domain:** Personal config layer on top of an installed illogical-impulse (dots-hyprland) shell — capture, override, reproduce
**Researched:** 2026-09-12
**Confidence:** HIGH (ii override surface, installer write-modes, capture-mechanism safety — all read from vendored source and/or empirically tested on this machine); MEDIUM on upstream's *intent* docs; see Open Questions for the LOW items
**Milestone:** v0.4 Personal config layer

---

## Executive framing

Three findings reshape the milestone before any phase is planned:

1. **The personal surface is tiny and already discoverable.** Every ii-shipped config on this machine except five files is byte-identical to the vendored pin `1a9ffb78`. A `diff -rq vendor/dots-hyprland/dots/.config ~/.config` is a complete, zero-effort "what have I touched" oracle. "Capture as touched" is not a compromise here — it is the *correct* strategy, because the baseline is exact.

2. **Whether stow-symlink capture survives depends on which installer helper writes the path — and that is knowable per file, not per guess.** `install_file` (`cp -f`) preserves the symlink and clobbers the repo copy (loud, visible in `git status`). `install_dir__sync` (`rsync -a --delete`) *deletes the symlink*, writes a plain file, and orphans the repo copy silently. `install_dir__ignore_existing` is a total no-op once the directory exists. Both behaviors were tested empirically, not inferred.

3. **D-41's stated reason for the `config.json` copy-capture exception is wrong, but its conclusion is right.** Quickshell's `FileView` atomic write goes through Qt's `QSaveFile`, which *resolves symlink chains and writes through to the target* — empirically verified against the exact `qt6-base 6.11.2` this machine links. The symlink survives. The actual symlink-killer is **`switchwall.sh`**, which rewrites `config.json` with `jq … > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"` — a shell `mv` that *does* replace the symlink. Every wallpaper change (`CTRL+SUPER+T`) destroys a stow symlink at `config.json`. The exception must exist; PROJECT.md's rationale for it needs correcting.

---

## 1. The ii `custom/` override surface

### Ground truth

`~/.config/hypr/hyprland.lua` on this machine is byte-identical to `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua`. `hyprctl -j status` reports `configProvider: lua` on Hyprland 0.56.2. Upstream's move to a Lua config provider is **confirmed**: the entry point is `hyprland.lua`, the API object is the global `hl` provided by Hyprland itself (documented in `/usr/share/hypr/stubs/hl.meta.lua`, a 1777-line LuaLS meta file shipped by the `hyprland` package), and `hyprland.conf` was renamed `.old` at install.

### Load order (verified, `hyprland.lua` lines 1–43)

| # | Loaded | Kind | Notes |
|---|--------|------|-------|
| 1 | `hyprland.lib` | upstream | Defines `HOME`, `is_file_exists`, `create_if_not_exists`, `workspace_in_group` |
| 2 | `hyprland.services` | upstream | Registers a `hyprland.start` hook that **auto-creates any missing `custom/*.lua`** (all six, incl. `variables.lua`) |
| 3 | `hyprland.env` | upstream | `hl.env` for Qt/XDG/venv |
| 4 | **`custom.env`** | **yours** | guarded by `is_file_exists` |
| 5 | `hyprland.execs` | upstream | registers a `hyprland.start` callback (autostart) |
| 6 | `hyprland.general` | upstream | monitors, input, decoration, animations |
| 7 | `hyprland.rules` | upstream | 61 window rules + 74 layer rules |
| 8 | `hyprland.colors` | **generated** | matugen writes this file on every wallpaper change |
| 9 | `hyprland.keybinds` | upstream | **first requires `hyprland.variables`, then `custom.variables`**, *then* defines 194 binds |
| 10 | **`custom.execs`** | **yours** | |
| 11 | **`custom.general`** | **yours** | |
| 12 | **`custom.rules`** | **yours** | |
| 13 | **`custom.keybinds`** | **yours** | |
| 14 | `workspaces.lua` / `monitors.lua` | optional | nwg-displays interop, at `~/.config/hypr/`, not under `custom/` |
| 15 | `hyprland.shellOverrides.main` | upstream | **loads last — overrides even your custom files** |

### Per-file contract

| File | Sourced by | Position | Can override | Cannot override |
|------|-----------|----------|--------------|-----------------|
| `custom/env.lua` | `hyprland.lua:11` | after upstream env | Any `hl.env(...)` — last write wins | Anything Hyprland reads before config load |
| `custom/variables.lua` | **`hyprland/keybinds.lua:4`** | *before* upstream binds are defined | The plain Lua globals `terminal`, `fileManager`, `browser`, `codeEditor`, `officeSoftware`, `textEditor`, `volumeMixer`, `settingsApp`, `taskManager`, `workspaceGroupSize`, and `hl.env("qsConfig", …)` | Nothing that is not one of those globals — it is not a general prelude |
| `custom/execs.lua` | `hyprland.lua:23` | after upstream execs | Adds a second `hl.on("hyprland.start", …)` callback that runs after upstream's | Cannot *remove* an upstream `hl.exec_cmd` — only shadow its effect (e.g. re-issue `hyprctl setcursor`) |
| `custom/general.lua` | `hyprland.lua:26` | after upstream general | `hl.monitor`, `hl.workspace_rule`, `hl.config{…}` (all of `general/decoration/input/animations/…`) | — |
| `custom/rules.lua` | `hyprland.lua:29` | after upstream rules | Adds window/layer rules | Cannot delete an upstream rule; `HL.WindowRule`/`HL.LayerRule` expose `set_enabled` but upstream keeps no handles |
| `custom/keybinds.lua` | `hyprland.lua:32` | after upstream binds | `hl.unbind(key)` removes; re-`hl.bind` on the same chord shadows | — |
| `custom/scripts/` | *not sourced* | — | A plain directory. Referenced only by `hyprland/execs.lua:7` for `__restore_video_wallpaper.sh` | **Not an override point.** See hazard below |

**`custom/` is never touched by the installer once it exists.** `3.files-legacy.sh:73` calls `install_dir__ignore_existing "dots/.config/hypr/custom" …`, and that helper (`3.files.sh:150`) prints a message and does *nothing at all* when the destination directory exists. It is not per-file ignore-existing — it is a whole-directory no-op. This is the single safest capture surface in the project.

**Hazard — `custom/scripts/` is a generated-output directory.** `switchwall.sh` writes `__restore_video_wallpaper.sh` there via `cat > "$X.tmp"` + `mv`, and drops `mpvpaper_thumbnails/` alongside it. A blanket stow package over `custom/` would capture generated shell scripts and binary thumbnails, and the `mv` would replace a symlinked `__restore_video_wallpaper.sh` with a plain file. Capture `custom/*.lua` and your *own* scripts; exclude `__restore_video_wallpaper.sh` and `mpvpaper_thumbnails/`.

**Second-order hazard — `create_custom_config.lua` auto-creates missing files.** Its `is_file_exists` is `io.open(name, "r")`, which follows symlinks, so a valid stow symlink is correctly seen as existing. But a **dangling** symlink (repo not yet cloned/stowed correctly) reads as missing, and `create_if_not_exists` then runs `echo … > "$path"`, which writes *through* the dangling link and creates the repo-side file with an upstream comment banner. Order of operations on a fresh machine matters.

---

## 2. Keybind customization idioms

### The API actually available on Hyprland 0.56.2

From `/usr/share/hypr/stubs/hl.meta.lua` (`HL.API`, lines 820–864) and confirmed in `Hyprland` binary strings:

- `hl.bind(keys, dispatcher|function, opts?) -> HL.Keybind`
- **`hl.unbind(key) -> nil`** — the removal primitive
- `HL.Keybind:unbind()`, `:remove()`, `:set_enabled()`, `:is_enabled()` — on the handle `hl.bind` returns
- `hl.define_submap(name, reset_or_fn, fn?)` + `hl.dsp.submap(…)` — upstream uses one submap (`virtual-machine`, `keybinds.lua:305`)
- `HL.BindOptions`: `repeating`, `locked`, `release`, `non_consuming`, `transparent`, `ignore_mods`, `dont_inhibit`, `long_press`, `submap_universal`, `click`, `drag`, **`description`/`desc`**, `device`, `allow_input_capture`

There is no `bindd` in the Lua provider — `description` on the options table is the Lua equivalent of hyprlang's `bindd`.

### Remove vs. shadow

**To remove an upstream bind you don't want:** `hl.unbind("SUPER + T")` in `custom/keybinds.lua`. This works because `custom.keybinds` is required at `hyprland.lua:32`, after `hyprland.keybinds` at line 19 — the bind exists by the time you unbind it. This is also upstream's documented answer ("you may need to use some techniques, such as `hl.unbind()` for keybinds" — [ii.clsty.link/en/ii-qs/03config](https://ii.clsty.link/en/ii-qs/03config/)).

**To shadow:** re-`hl.bind` the same chord. Note upstream deliberately stacks multiple binds on one chord as a fallback chain (`SUPER + V` is bound twice: the Quickshell global *and* a `qs … TEST_ALIVE || fuzzel` fallback). Shadowing adds a third handler rather than replacing the pair. When you want one behavior, `hl.unbind` first, then bind.

**To change what an app-launcher bind launches:** don't touch the bind at all — set `terminal`/`fileManager`/`browser`/`codeEditor` in `custom/variables.lua`. `hyprland/keybinds.lua:345-350` interpolates those Lua globals at load time, and `custom.variables` is loaded four lines earlier. This is the update-friendliest idiom and upstream says so explicitly in `hyprland/variables.lua:2`.

**Last-resort escape hatch (documented upstream, an anti-feature here):** copy an upstream file from `hyprland/` into `custom/` and comment out the `require` in `hyprland.lua`. But `hyprland.lua` is installed with `install_file` (plain `cp -f`) on every run, so the edit is reverted on every update — unless you also pass `--skip-hyprland-entry` (a real flag, `sdata/subcmd-install/options.sh:87`). That is two coupled forks to maintain; see Anti-Features.

### Does the cheatsheet break?

**No — overriding is cheatsheet-native.** `services/HyprlandKeybinds.qml` runs `hyprctl binds -j` at startup and re-runs it on every `configreloaded` event. It groups by the substring *before the first `:`* in `description`. Live check right now: 195 binds, 90 with descriptions, grouped into `Shell / Utilities / Screen / Media / Window / Workspace / Session / App` — plus one junk category, `Edit user keybinds`, produced by the stock `custom/keybinds.lua` stub whose description has no colon.

**Actionable convention:** every personal bind gets `{ description = "Category: Label" }` using an existing category (or a deliberate new one). Binds without a description are invisible to the cheatsheet but still work. Unbinding an upstream bind correctly removes its cheatsheet row.

---

## 3. Quickshell ii bar configuration surface

### What `config.json` covers

`~/.config/illogical-impulse/config.json` is a `JsonAdapter` over `modules/common/Config.qml` — **41 top-level groups, 95 nested `JsonObject`s, 284 leaf values** in the live file. Live top-level keys:

`ai · appearance · apps · audio · background · bar · battery · calendar · cheatsheet · conflictKiller · crosshair · dock · hacks · interactions · language · launcher · light · lock · media · musicRecognition · networking · notifications · osd · osk · overlay · overview · panelFamily · policies · regionSelector · resources · screenRecord · screenSnip · search · sidebar · sounds · time · tray · updates · waffles · wallpaperSelector · windows · workSafety`

The `bar` group specifically (`Config.qml:226-285`):

| Key | Effect |
|-----|--------|
| `bar.bottom` | Move the bar to the bottom |
| `bar.vertical` | Vertical bar |
| `bar.cornerStyle` | `0` Hug / `1` Float / `2` Plain rectangle |
| `bar.floatStyleShadow`, `bar.showBackground`, `bar.borderless` | Chrome |
| `bar.verbose` | Long vs. shortened form |
| `bar.topLeftIcon` | `"distro"` or any icon in `~/.config/quickshell/ii/assets/icons` |
| `bar.screenList` | **Which monitors get a bar** — `[]` = all. Machine-specific (`DP-1`, `HDMI-A-2`) |
| `bar.autoHide.*` | Auto-hide, hover region width, push-windows, show-on-Super with delay |
| `bar.resources.*` | Always-show swap/CPU, warning thresholds |
| `bar.utilButtons.*` | **Seven independent booleans** — screen snip, color picker, mic toggle, keyboard toggle, dark-mode toggle, performance profile, screen record |
| `bar.workspaces.*` | Count shown, monochrome icons, app icons, number display + delay, `numberMap`, nerd font |
| `bar.weather.*` | Enable, GPS vs. `city`, units, fetch interval |
| `bar.indicators.notifications.showUnreadCount` | |
| `bar.tooltips.clickToShow` | |

Plus `panelFamily` (`"ii"` \| `"waffle"`) — a whole alternate bar/panel family switch at the top level.

### Can you add / remove / reorder bar widgets from `config.json`?

**No. Confirmed by source.** `modules/ii/bar/BarContent.qml` (343 lines) is a hardcoded three-section composition: `ActiveWindow`, then a `BarGroup` with `Resources` + `Media`, a `BarGroup` with `Workspaces`, a `BarGroup` with `ClockWidget` + `UtilButtons` + `BatteryIndicator`, then a right section with indicators and `SysTray`. There is **no widget list, no model, no ordering key, and no plugin/extension point** anywhere in the config schema.

What `config.json` *can* do is toggle a fixed set of pre-wired things (the seven `utilButtons`, weather on/off, resources visibility, notification count, bar position/orientation/style). Anything else — adding a ping widget, reordering clock and tray, removing Media — requires editing QML under `~/.config/quickshell/ii/`.

### What editing that QML costs

`3.files-legacy.sh:26` is `install_dir__sync dots/.config/quickshell "$XDG_CONFIG_HOME/quickshell"` — `rsync -a --delete` over the **entire** `~/.config/quickshell` tree (upstream widened this from `ii/` to the whole directory deliberately; see the comment citing [issue #2294](https://github.com/end-4/dots-hyprland/issues/2294)). Consequences, all verified:

- Every QML edit is destroyed on every `install`/`install-files` run.
- A stow symlink inside that tree is **deleted and replaced with a plain file** (empirically tested), silently, with the repo copy left orphaned.
- New files you add are deleted by `--delete`.

**The only durable way to carry QML changes is a commit on the personal fork `humam-hossain/dots-hyprland`, carried across pin bumps by rebase** — which is exactly the ownership model v0.2 already built and has never been exercised. Today, `diff -rq vendor/…/quickshell/ii ~/.config/quickshell/ii` returns **zero differences**: the live tree is pristine. That is a clean starting point and also the reason a drift check over this tree is trivially cheap.

**Scoping call:** bar *composition* changes are a fork-commit workflow, not a dotfiles-capture workflow. They belong in the CUST-01..04 backlog, not in v0.4. v0.4 should own `config.json` and prove the capture mechanism; it should not open the QML fork.

---

## 4. Startup applications

### What ii itself does — no uwsm, no systemd target

`hyprland/execs.lua` registers one `hl.on("hyprland.start", …)` callback issuing plain `hl.exec_cmd` calls:

`start_geoclue_agent.sh` · `qs -c $qsConfig` · `__restore_video_wallpaper.sh` · `gnome-keyring-daemon --start --components=secrets` · `hypridle` · `dbus-update-activation-environment --all` · `sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP` · `easyeffects --hide-window --service-mode` · two `wl-paste --watch … cliphist store && qs … ipc call cliphistService update` · `hyprctl setcursor Bibata-Modern-Classic 24`

Searching the whole vendored tree for `uwsm` / `graphical-session` / `systemctl --user` returns **only** `2.setups.sh`, which enables `ydotool.service` (user) and `bluetooth.service` (system). **ii does not use uwsm and does not start `graphical-session.target`.** It pushes the Wayland env into the systemd/dbus activation environment and stops there.

### D-38, resolved with a mechanism rather than a guess

Live state right now: `systemctl --user is-active graphical-session.target` → **`inactive`**; `hyprland-session.service` → **`inactive`**. The unit file itself is intact and already stow-symlinked from `stow/systemd/.config/systemd/user/hyprland-session.service`. The archived `hyprland.conf.old:57` shows what was lost: `exec-once = systemctl --user start hyprland-session.service`.

**The unit is the right mechanism and needs no redesign.** It is a `Type=oneshot RemainAfterExit=yes` shim with `Wants=graphical-session.target` / `Before=graphical-session.target`, existing precisely because a bare `Hyprland`-from-TTY session has no systemd session manager to pull the target up, and `xdg-desktop-portal` has `Requisite=graphical-session.target`. The fix is **one line in `custom/execs.lua`**:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprland-session.service")
end)
```

Switching the session to `uwsm` would also fix it, and more correctly, but it replaces the session entry point and invalidates the Phase 14 adopt verification. Out of scope for v0.4; note it as a future option.

### Everything else lost at the adopt (from `hyprland.conf.old`)

| Old `exec-once` | Status under ii | Restore where |
|---|---|---|
| `systemctl --user start hyprland-session.service` | **lost** (D-38) | `custom/execs.lua` |
| `/usr/lib/polkit-kde-authentication-agent-1` | **lost** — ii ships no polkit agent exec (only a Fedora-only branch appends one) | `custom/execs.lua` |
| `wl-clip-persist --clipboard both` | **lost** | `custom/execs.lua` |
| `[workspace 1] google-chrome-stable …` | **lost** | `custom/execs.lua` with rules arg |
| `[workspace 1] kitty -e tmux` | **lost** | same |
| `[workspace special:btop silent] kitty --class btop -e btop` | **lost** | same |
| `[workspace special:social silent] vesktop\|\|discord` | **lost** (the `special:social` workspace pin *did* survive in `custom/general.lua`) | same |
| `hyprctl setcursor catppuccin-mocha-dark-cursors 30` | **superseded** — ii sets Bibata 24 | `custom/execs.lua` (runs after upstream's; last write wins) |
| `waybar & swaync & hyprpaper &` | **accept-removed** (D-11); `hyprpaper` is not running and ii owns the wallpaper via Quickshell | do not restore |
| `qs -c ii` | **owned by ii now** | do not restore (would double-launch) |
| `wl-paste … cliphist store` (×2) | **superseded** — ii's variants also fire the shell IPC update | do not restore (would double-store) |

`hl.exec_cmd` takes an optional rules table (`hl.meta.lua:830`: `exec_cmd fun(cmd: string, rules?: table<string, string|number|boolean>)`) — the Lua equivalent of `exec-once = [workspace 1] …`. Upstream never uses the rules argument, so the exact key spelling is **UNVERIFIED**; test `{ workspace = "1" }` and fall back to `hl.exec_cmd("hyprctl dispatch exec '[workspace 1 silent] …'")` if the table form doesn't take.

### Mechanism selection guide

| Mechanism | Use it when | Don't |
|---|---|---|
| `custom/execs.lua` (`hl.on("hyprland.start")` + `hl.exec_cmd`) | **Default for this project.** Anything that needs the Hyprland socket, a workspace/window rule on launch, or must die with the session | Long-lived daemons that should restart on failure |
| Systemd user unit + `graphical-session.target` | Something another unit declares a dependency on (portals), or that wants `Restart=`/ordering | One-shot GUI apps — you gain a unit file and lose the workspace rule |
| `~/.config/autostart/*.desktop` | Apps that ship their own `.desktop` autostart and are picked up by a generic XDG autostart runner | **Nothing starts these today.** Hyprland does not read XDG autostart, ii does not run `dex`/`xdg-autostart`. `~/.config/autostart/FDM.desktop` exists and is dead weight |
| `uwsm` | A future session-model change | v0.4 — it replaces the session entry |

---

## 5. Dolphin / KDE / Qt / GTK capture inventory

### Live drift against the vendored pin — the whole personal surface

`diff` of every ii-shipped `dots/.config` entry against live, run today:

| Surface | Installer helper | Drift from pin | Verdict |
|---|---|---|---|
| `dolphinrc` | `install_file` (`cp -f`) | **9 lines** | capture |
| `kdeglobals` | `install_file` | **14 lines** | capture with care |
| `chrome-flags.conf` | `install_file` | **1 line** (`--hide-crash-restore-bubble`) | capture |
| `kitty/` | `install_dir__sync` | **2** (`kitty.conf` + a stray `kitty.conf.upstream`) | already stow-managed; hazard |
| `fish/` | `install_dir__sync_exclude … conf.d` | **2** (`conf.d/` extra, `fish_variables` differs) | already stow-managed |
| `darklyrc`, `konsolerc`, `starship.toml`, `code-flags.conf`, `thorium-flags.conf` | `install_file` | **identical** | leave alone |
| `foot/`, `fuzzel/`, `Kvantum/`, `kde-material-you-colors/`, `matugen/`, `mpv/`, `wlogout/`, `xdg-desktop-portal/`, `zshrc.d/`, `fontconfig/`, `quickshell/` | `install_dir__sync` | **identical, 0 diffs** | leave alone |

Five drifted files and two already-managed dirs. That is the entire ii-adjacent personal surface today.

### Per-file assessment

| File | Controls | Portable? | ii-managed? | Verdict |
|---|---|---|---|---|
| `dolphinrc` | Menu bar, tab bar, full path, status bar, tooltips, relative dates, details-mode preview size, preview plugin list, KFileDialog places-icon sizing | **Mostly.** The `Plugins=` list names thumbnailer packages that must be installed; `Version=202` is a KConfig migration marker | **Yes** — `install_file`, so a stow symlink survives but upstream content lands in the repo on every install (shows in `git status`) | **Capture.** Accept the update-time clobber as a visible, revertable git diff |
| `kdeglobals` | Two things at once: (a) the entire Material You color scheme — nine `[Colors:*]` blocks, `[ColorEffects:*]`, `[WM]` — and (b) genuine preferences: `[General]` fonts, `TerminalApplication`, `XftHintStyle`, `[Icons] Theme`, `[KDE] widgetStyle`, `[KFileDialog Settings]`, `[Sounds]` | **Mixed and volatile.** The color blocks are wallpaper-derived output of `kde-material-you-colors`; `ColorSchemeHash` is a content hash. KConfig also **reorders keys on every save** (today's diff shows `XftHintStyle` and `activeFont` relocated with no value change) → permanent phantom churn in `git diff` | **Yes** — shipped *and* rewritten by the theming pipeline | **Capture-hazard.** Do not stow the whole file. Either capture it read-only as a drifting archive, or (better) narrow to the ~6 preference keys that actually diverge and re-apply them |
| `kiorc` | Delete/trash/empty-trash confirmation prompts, `behaviourOnLaunch=alwaysAsk` for executable scripts | **Fully portable**, 7 lines, no paths | **No** — not shipped by ii at all | **Capture. Cleanest file in the set** |
| `ktrashrc` | Trash size/time limits | Portable *except* the group header is the literal path `[/home/pera/.local/share/Trash]` | No | **Capture**, with the username caveat noted |
| `kservicemenurc` | Which Dolphin right-click service menus show | Portable; each key names an installed KDE service menu that must exist | No | **Capture** |
| `darklyrc` | One key: `WidgetDrawShadow=false` | Portable | **Yes**, identical to pin | **Skip** — nothing personal in it |
| `Kvantum/` | `kvantum.kvconfig` + two bundled themes (Colloid, MaterialAdw) | Portable | **Yes**, `install_dir__sync`, identical to pin | **Skip.** Capturing a `--delete`-synced directory is the worst-case combination |
| `gtk-3.0/settings.ini` | GTK3 theme (`catppuccin-mocha-teal-standard+default`), icons (`Tela-circle-dracula-dark`), cursor (`catppuccin-mocha-blue-cursors` @30), font, hinting, dark preference | Portable; every name is a package that must be installed | **No** — but matugen targets `~/.config/gtk-3.0/gtk.css` (a *different* file in the same dir) | **Capture `settings.ini` only**, never the directory |
| `gtk-3.0/bookmarks` | GTK file-chooser sidebar places | Portable-ish; six `file:///home/pera/…` absolute paths | No | **Capture** — genuinely personal, trivially small |
| `gtk-4.0/settings.ini` | Same as GTK3 | Portable | No | **Capture** |
| `gtk-4.0/{gtk.css,gtk-dark.css,assets}` | Currently **symlinks into `/usr/share/themes/catppuccin-mocha-teal-standard+default/`** | Not portable — they point at a theme package | **Conflict:** `matugen/config.toml` declares `output_path = '~/.config/gtk-4.0/gtk.css'`. A wallpaper re-theme will fight these symlinks | **Do not capture. Resolve the conflict first** — pick matugen-generated *or* catppuccin, not both |
| `qt6ct/qt6ct.conf` | `style=breeze`, `color_scheme_path=/usr/share/qt6ct/colors/darker.conf`, custom palette | Portable, but contains an absolute `/usr/share` path | No | **Low value.** ii sets `QT_QPA_PLATFORMTHEME=kde` in `hyprland/env.lua`, so qt6ct is likely inert. Capture only if proven to have effect |
| `qt5ct/` | — | — | — | **Absent on this machine.** Skip |
| `~/.local/share/user-places.xbel` | Dolphin **Places** sidebar | Portable-ish; `file://` absolute paths, and device entries carry UDIs/UUIDs when present | No | **Not yet** — currently pure defaults. Document it as the file to capture *when* Places are customized |
| `~/.local/share/dolphin/view_properties/` | Per-directory view mode, sort, hidden-files | **Volatile, path-keyed, machine-specific** | No | **Anti-feature. Never capture** |

### The two capture hazards worth naming explicitly

- **`kdeglobals` mixes durable preferences with generated theme output and reorders itself on every write.** It is the single file in this milestone most likely to produce a noisy, meaningless git history and to be silently reverted by the theming pipeline.
- **`gtk-4.0/gtk.css` is contested territory** between a pre-existing catppuccin symlink and matugen's declared output path. Capturing either side without deciding the theme question first bakes in a conflict.

---

## 6. The capture-mechanism × installer-write-mode matrix

**This is the decision table the whole milestone hinges on.** All three behaviors were tested empirically today in a scratch directory, not inferred.

| Installer helper | Mechanism | Effect on a stow symlink at the destination | Failure mode | Verdict for stow capture |
|---|---|---|---|---|
| `install_dir__ignore_existing` | no-op if dir exists | **Untouched** | none | **Safe.** Only `hypr/custom/` |
| `install_file` | `cp -f` | **Symlink preserved**; write goes *through* it, repo file gets upstream content | Loud — `git status` shows the change; `git checkout` restores it | **Acceptable.** Content clobber, not capture loss |
| `install_file__auto_backup` | `cp` to `$T.new` on non-firstrun | Symlink untouched; a `.new` sibling appears | Harmless | **Safe.** (`hyprlock.conf`, `hypridle.conf` — both `.new` files are sitting there now from the Sep 4 install) |
| `install_dir__sync_exclude … conf.d` | `rsync -a --delete --exclude conf.d` | Excluded paths untouched; everything else destroyed | Silent inside, safe outside | **Only the excluded subtree** (`fish/conf.d`) |
| `install_dir__sync` | `rsync -a --delete` | **Symlink deleted, replaced by a plain upstream file; extra files deleted** | **Silent.** Repo copy orphaned, live diverges, nothing errors | **Unsafe. Do not stow into these trees** |

Empirical proof, run 2026-09-12:

```
rsync -a --delete src/ dest/   →  dest/a.conf is now a regular file "upstream";
                                  repo/a.conf still says "personal"; dest/extra.conf gone
cp -f src/a.conf dest/a.conf   →  dest/a.conf still a symlink; repo/a.conf now says "upstream"
```

The live `~/.config/kitty/` is a standing instance of the unsafe case: `kitty.conf` is a stow symlink into `stow/kitty/`, `kitty.conf.upstream` sits beside it as a manual side-by-side, and `kitty/` is an `install_dir__sync` target. Whatever happened at the Sep 4 adopt, the arrangement only holds because someone re-established it by hand afterwards.

### The self-rewriting-file question (D-41), answered

| Writer | Mechanism | Symlink survives? | Evidence |
|---|---|---|---|
| Quickshell `FileView.writeAdapter()` | `atomicWrites` defaults true → Qt `QSaveFile` | **YES** | `QSaveFile::open()` walks the symlink chain (max depth 128) and writes the temp file at the *resolved* target. **Empirically confirmed on this machine's `qt6-base 6.11.2`**: symlink intact, link target updated |
| `switchwall.sh` (wallpaper change) | `jq … > "$F.tmp" && mv "$F.tmp" "$F"` | **NO** | Shell `mv` over a symlink path replaces the link. Empirically confirmed. Writes `.background.wallpaperPath` and `.background.thumbnailPath` |
| `gemini-translate.sh` | same `jq`+`mv` pattern on `config.json` | **NO** | same |
| `switchwall.sh` → `custom/scripts/__restore_video_wallpaper.sh` | `cat > "$X.tmp"` + `mv` | **NO** | same |
| Quickshell `Persistent.qml` → `~/.local/state/quickshell/states.json` | `writeAdapter()` | n/a | state file, never capture |

**Conclusion:** `config.json` still needs the copy-capture exception, but PROJECT.md's stated reason ("proven against ii's `FileView.writeAdapter()` atomic write") is factually wrong and should be amended to name `switchwall.sh`. The distinction matters for scope: the exception is triggered by *wallpaper changes and the translator*, not by the settings GUI. Toggling a bar option in the Super+I settings panel is symlink-safe.

Also note `config.json` is **not in `dots/.config` at all** — `~/.config/illogical-impulse/` is a runtime directory (`installed_listfile`, `installed_true`, `actions/`) created by the installer, never rsynced. So the installer poses no threat to it; only the shell's own scripts do.

---

## Table Stakes

Miss any of these and the milestone hasn't delivered its stated goal.

| # | Feature | Why expected | Complexity | Notes |
|---|---|---|---|---|
| T1 | **`hypr/custom/` fully under repo SoT** — all six `*.lua` plus owned scripts | Explicit milestone requirement; live already drifted past repo (`keybinds.lua`, `rules.lua`, `variables.lua` untracked) | LOW | Safest surface in the project: `install_dir__ignore_existing` makes it a no-op for the installer. Stow it. Exclude `scripts/__restore_video_wallpaper.sh` and `mpvpaper_thumbnails/` |
| T2 | **Personal keybinds in `custom/keybinds.lua`** with `hl.unbind` for removals and `"Category: Label"` descriptions | User's first-named want | LOW-MED | Replace the stub's colon-less description so the cheatsheet stops showing an `Edit user keybinds` category |
| T3 | **App-launcher choices in `custom/variables.lua`** | Upstream's own recommended override path; currently an untracked empty stub | LOW | `terminal`, `fileManager`, `browser`, `codeEditor`, `workspaceGroupSize` |
| T4 | **Startup applications restored in `custom/execs.lua`** | Explicit requirement; seven things died at the adopt | MED | Restore polkit agent, `wl-clip-persist`, four workspace-pinned apps, cursor override. Do **not** restore `qs -c ii`, cliphist, waybar/swaync/hyprpaper |
| T5 | **D-38 closed on the right mechanism** — `systemctl --user start hyprland-session.service` from `custom/execs.lua` | Open debt with no owning phase since Phase 14; `graphical-session.target` is inactive *right now* | LOW | ii provides no target bootstrap and no uwsm — verified. The unit is already stow-symlinked and intact |
| T6 | **`config.json` captured via copy-capture with a documented trigger** | Explicit requirement (D-41) | MED | Copy-capture because `switchwall.sh` `mv`s over it, not because of `FileView`. Verify by changing the wallpaper and checking `ls -l` |
| T7 | **The five drifted KDE/GTK files captured** — `dolphinrc`, `kiorc`, `ktrashrc`, `kservicemenurc`, `gtk-{3,4}.0/settings.ini` | Explicit requirement | LOW | Four of these ii doesn't ship at all → zero installer conflict. `dolphinrc` is `install_file` → symlink-safe |
| T8 | **`verify` drift check (POLISH-01)** — asserts live == repo for every captured path, and live == pin for everything else | "No manual sync" must be asserted, not assumed | MED | The pin makes the second half nearly free: `diff -rq vendor/…/dots/.config ~/.config`. Must catch the silent `rsync --delete` symlink-replacement class |
| T9 | **One-command fresh-machine bootstrap** | Explicit requirement; the user's verbatim "exact setup instantly" | HIGH | Does not exist today — the repo has 34 separate `arch/*.sh` scripts each ending in its own `stow`. Needs an ordered top-level entry: packages → ii install → stow → post-install re-stow → verify |
| T10 | **Documented capture procedure for "I just changed X"** | The user's actual loop is *configure, then save* | LOW | Must answer: which mechanism for this path, and what to run |

## Differentiators

High value for this machine specifically; not strictly required to call v0.4 shipped.

| # | Feature | Value | Complexity | Notes |
|---|---|---|---|---|
| D1 | **Installer write-mode map as a checked-in table** — every `~/.config` path → `install_file` / `sync` / `ignore_existing` / not-shipped | Turns "is this path safe to stow?" from a research question into a lookup. Directly derivable from `3.files-legacy.sh` | LOW | The single highest-leverage artifact in this milestone. Makes "capture as touched" safe forever |
| D2 | **Pin-baseline drift oracle** — `diff -rq vendor/…/dots/.config ~/.config` as a first-class command | Zero-cost complete inventory *without* the upfront audit the user rejected. Proves the surface is 5 files today | LOW | Exactly the "capture as touched" enabler. Folds into T8 |
| D3 | **Post-install re-stow step in the wrapper** | `install_dir__sync` will keep eating symlinks on every pin bump. Automating re-stow turns a silent loss into a routine step | MED | The `kitty.conf.upstream` artifact is what this prevents |
| D4 | **Explicit package list capture** (`pacman -Qqen` / `-Qqem` to two files) | 261 explicit packages, 56 AUR, 15 of them ii metas. Cheap snapshot, high recovery value | LOW | Snapshot ≠ installer. See A6 |
| D5 | **Narrowed `kdeglobals` capture** — the ~6 preference keys, re-applied rather than the whole file | Avoids permanent phantom churn from KConfig key reordering and from wallpaper re-theming | MED | Alternative: archive-only, accept it drifts |
| D6 | **Machine-specific value inventory for `config.json`** | Only 5 of 284 leaves are machine-specific: `background.wallpaperPath`, `bar.weather.city` (`Dhaka`), `screenRecord.savePath`, `screenSnip.savePath`, `overlay.floatingImage.imageSource`. Plus `bar.screenList` when set | LOW | Makes a second machine a 5-line delta, not a fork |
| D7 | **Resolve the GTK4 theme conflict** — catppuccin symlinks vs. matugen's declared `gtk.css` output | An unresolved conflict that will surface as "my GTK theme randomly changed" | LOW-MED | Decide before capturing anything in `gtk-4.0/` |
| D8 | **Dead-config cleanup** — `hyprpaper.conf` (hyprpaper not running, ii owns the wallpaper), `~/.config/autostart/FDM.desktop` (nothing reads XDG autostart), `hyprland-gui.conf`, the `.new`/`.old`/`.bak` litter in `~/.config/hypr/` | Stops the repo from capturing config that has no effect | LOW | Cheap, and it shrinks T1/T7 |

## Anti-Features

| Anti-feature | Why it gets requested | Why it's harmful | Do instead |
|---|---|---|---|
| **A1. Stow-symlink everything uniformly** | "One mechanism, no special cases" is clean | `install_dir__sync` silently deletes symlinks in 11 shipped directories and orphans the repo copy with no error. Uniformity here means silent, undetectable capture loss | Mechanism chosen per path from the write-mode map (D1). Non-uniform by necessity |
| **A2. Capture `~/.config/quickshell/ii/` (fork the QML in the dotfiles repo)** | It's the only way to add or reorder bar widgets | `rsync -a --delete` over the whole `~/.config/quickshell` tree destroys it on every install. It also duplicates the vendored submodule into the parent repo | Bar composition changes are **fork commits on `humam-hossain/dots-hyprland`**, carried by rebase at pin bump. Defer to CUST-* |
| **A3. Fork `hyprland.lua` and comment out upstream requires** | Upstream documents it as the escape hatch when `custom/` can't override something | Requires permanently passing `--skip-hyprland-entry`, creates a second file to reconcile at every update, and silently diverges from the load order every other override assumes | `hl.unbind` + re-bind covers keybinds; `custom/variables.lua` covers launcher choices; `hl.config` in `custom/general.lua` covers settings. Reach for A3 only with a named, demonstrated failure |
| **A4. Capture `kdeglobals` verbatim as a stow symlink** | "It's a config file, capture it" | It is the output of the Material You theming pipeline *and* KConfig reorders its keys on every save. Every wallpaper change and every KDE app launch produces a meaningless diff, and the pipeline will silently overwrite your values | D5 — narrow to the preference keys, or archive-only |
| **A5. Capture `~/.local/state/quickshell/`, `~/.local/share/dolphin/view_properties/`, `~/.config/illogical-impulse/installed_listfile`, `Trash`, thumbnail caches** | They live under a config-ish path | Pure machine state: generated colors, per-directory view modes, a 77 KB install manifest, path-keyed cruft. Restoring them on a new machine is at best useless, at worst wrong | Exclude explicitly and write down why |
| **A6. Make the package list a reproducible installer** | "One command should install everything" | 261 explicit packages with 56 from AUR, tangled with ii's own metas and `./setup`'s `install-deps`. Getting ordering, AUR-helper bootstrap and ii interleaving right is a milestone of its own | D4 — capture the list as a snapshot and a manual diff aid. `./setup` stays the SoT for ii's deps |
| **A7. Upfront inventory of everything dots-hyprland installs** | Feels thorough | Already rejected by the user, and the pin makes it unnecessary: diffing the vendored tree against live returns 5 files. An upfront inventory would re-do Phase 10 for no new information | D2 — the pin baseline *is* the inventory, computed on demand |
| **A8. Port the Waybar custom modules (ping/weather/earthquake) into the bar** | It's the long-standing parity gap and "bar configuration" is in the milestone title | Requires exactly the QML fork A2 rules out. Scope explosion on top of an already four-surface milestone | CUST-01..03 backlog, after the fork workflow has been exercised once |
| **A9. Switch the session to `uwsm` to fix D-38 properly** | It is the architecturally correct autostart mechanism | Replaces the session entry point and invalidates the Phase 14 adopt verification, to fix a problem one `exec_cmd` line already fixes | T5 now; log uwsm as a future session-model decision |
| **A10. Restore `hyprpaper`, `waybar`, `swaync`, `rofi` autostarts while restoring the others** | They were in the same `exec-once` block that was lost | Accept-removed at Phase 14 (D-11), configs deliberately archived (D-12). ii owns the wallpaper, bar, notifications and launcher. Restoring them re-creates the dual-run | Restore only the seven rows marked *lost* in §4 |
| **A11. Capture `Kvantum/`, `foot/`, `fuzzel/`, `matugen/`, `mpv/`, `wlogout/`, `zshrc.d/`, `kde-material-you-colors/`** | They're in `~/.config` and look like dotfiles | All eight are byte-identical to the pin — there is nothing personal in them — *and* all eight are `install_dir__sync` targets, the unsafe class. Maximum risk, zero value | Leave them. The pin already reproduces them |

---

## Per-surface capture inventory

Legend — **Mechanism:** `stow` = symlink into repo · `copy` = copy-capture + verify · `fork` = commit on `humam-hossain/dots-hyprland` · `skip` = don't capture.

### Surface 1 — Hypr custom overlays

| Path | Mechanism | Installer risk | Status today |
|---|---|---|---|
| `hypr/custom/general.lua` | stow | none (`ignore_existing`) | tracked in repo; live matches |
| `hypr/custom/env.lua` | stow | none | tracked (1-byte slot) |
| `hypr/custom/execs.lua` | stow | none | tracked (1-byte slot) — **T4/T5 land here** |
| `hypr/custom/keybinds.lua` | stow | none | **untracked**; live holds the upstream stub |
| `hypr/custom/rules.lua` | stow | none | **untracked** (1-byte) |
| `hypr/custom/variables.lua` | stow | none | **untracked** (1-byte) — *not required by `hyprland.lua`; it is required by `hyprland/keybinds.lua`* |
| `hypr/custom/scripts/<your own>` | stow | none | none exist yet |
| `hypr/custom/scripts/__restore_video_wallpaper.sh` | **skip** | generated by `switchwall.sh` via `mv` | present; upstream placeholder |
| `hypr/custom/scripts/mpvpaper_thumbnails/` | **skip** | generated | absent |
| `hypr/hyprland/**` | **skip** | `install_dir__sync` — `--delete` | repo tracks `hyprland/scripts/launch_first_available.sh`; it is in the sync path and will be clobbered |
| `hypr/hyprland.lua` | **skip** | `install_file` every run | identical to pin |
| `hypr/hyprlock.conf`, `hypridle.conf` | skip or stow | `install_file__auto_backup` — writes a `.new` sibling, symlink safe | `.new` files from Sep 4 are sitting unreviewed |
| `hypr/hyprpaper.conf`, `hyprland-gui.conf`, `*.old`, `*.bak` | **skip / delete** | — | dead — hyprpaper is not running |

### Surface 2 — Quickshell ii

| Path | Mechanism | Installer risk | Notes |
|---|---|---|---|
| `~/.config/illogical-impulse/config.json` | **copy** | none (dir not shipped) | Symlink-unsafe due to `switchwall.sh`'s `mv`, *not* `FileView`. 284 leaves, 5 machine-specific |
| `~/.config/illogical-impulse/{installed_listfile,installed_true,actions/}` | **skip** | — | install state |
| `~/.config/quickshell/ii/**` | **fork** (out of scope for v0.4) | `install_dir__sync` over the whole tree | Zero drift from pin today — a pristine starting point |
| `~/.local/state/quickshell/**` | **skip** | — | generated colors, `states.json`, todo, AI history |

### Surface 3 — Startup

| Path | Mechanism | Notes |
|---|---|---|
| `hypr/custom/execs.lua` | stow | All seven restorations + D-38 |
| `stow/systemd/.config/systemd/user/hyprland-session.service` | stow (**already**) | Unit intact; only its trigger was lost |
| `~/.config/autostart/FDM.desktop` | **skip / delete** | Nothing reads XDG autostart in this session |
| enabled systemd user units (`ydotool`, `pipewire*`, `wireplumber`, `gnome-keyring`, `xdg-user-dirs`) | document | ii's `2.setups.sh` enables `ydotool`; the rest are package presets |

### Surface 4 — Dolphin / KDE / Qt / GTK

| Path | Mechanism | Installer helper | Portable | Notes |
|---|---|---|---|---|
| `dolphinrc` | **stow** | `install_file` | mostly | 9 lines of drift; symlink-safe, content clobbered visibly at update |
| `kiorc` | **stow** | not shipped | yes | Cleanest file in the set |
| `ktrashrc` | **stow** | not shipped | username in group header | |
| `kservicemenurc` | **stow** | not shipped | yes | keys name installed service menus |
| `gtk-3.0/settings.ini` | **stow** | not shipped | yes | never stow the *directory* — matugen targets `gtk.css` in it |
| `gtk-3.0/bookmarks` | **stow** | not shipped | absolute `file://` paths | |
| `gtk-4.0/settings.ini` | **stow** | not shipped | yes | |
| `gtk-4.0/{gtk.css,gtk-dark.css,assets}` | **skip until D7** | not shipped | no | catppuccin symlinks vs. matugen output path — unresolved conflict |
| `kdeglobals` | **copy, narrowed (D5)** | `install_file` | mixed | Generated colors + KConfig key reordering = permanent churn |
| `chrome-flags.conf` | stow | `install_file` | yes | 1 line of drift |
| `qt6ct/qt6ct.conf` | skip (low value) | not shipped | absolute `/usr/share` path | ii sets `QT_QPA_PLATFORMTHEME=kde`; likely inert |
| `darklyrc`, `konsolerc`, `starship.toml`, `code-flags.conf`, `thorium-flags.conf` | **skip** | `install_file` | — | identical to pin — nothing personal |
| `Kvantum/`, `foot/`, `fuzzel/`, `matugen/`, `mpv/`, `wlogout/`, `xdg-desktop-portal/`, `zshrc.d/`, `kde-material-you-colors/`, `fontconfig/` | **skip** | `install_dir__sync` | — | identical to pin, and the unsafe write mode |
| `kitty/`, `fish/` | stow (**already**) — needs post-install re-stow | `install_dir__sync` / `sync_exclude conf.d` | — | `kitty.conf.upstream` is the scar tissue from the last collision |
| `~/.local/share/user-places.xbel` | document, capture when customized | not shipped | `file://` paths + device UUIDs | currently pure defaults |
| `~/.local/share/dolphin/view_properties/` | **skip** | not shipped | no | volatile, path-keyed |

### Surface 5 — Reproduction (what "one command" includes)

| Item | Cheap? | Include in v0.4? |
|---|---|---|
| Clone + `git submodule update --init --recursive` | yes | **yes** |
| `arch/dots-hyprland.sh install` (ii deps + files) | yes — already exists | **yes** |
| Stow all packages in one ordered pass | yes | **yes** |
| Copy-capture restore (`config.json`) | yes | **yes** |
| Post-install re-stow of `install_dir__sync` casualties | yes | **yes** (D3) |
| `verify` drift check as the final gate | medium | **yes** (T8) |
| Explicit package list snapshot (`pacman -Qqen`/`-Qqem`) | yes | **yes as data** (D4) |
| Enabled systemd user units | yes — 9 units, one `systemctl --user enable` line | **yes** |
| GTK/Qt theme, icon, cursor, font *selection* | yes — it's `settings.ini` + `kdeglobals` keys | **yes** |
| The theme/icon/cursor **packages** those names refer to | no — AUR, versions, `/usr/share` contents | **no** — document the names as a prerequisite list |
| Wallpaper image file | no — a binary in `~/Pictures`, and `background.wallpaperPath` is absolute | **no** — capture the *path convention*, not the image |
| Fully reproducible package installation incl. AUR ordering | no | **no** (A6) |
| ii QML customizations | no | **no** (A2) |

---

## Feature dependencies

```
Installer write-mode map (D1)  ──┐
Pin-baseline drift oracle (D2) ──┤
                                 ├──> Capture mechanism decision per path
config.json writer analysis ─────┘            │
   (switchwall.sh mv, not FileView)           │
                                              ├──> T1 hypr/custom under SoT
                                              │       ├──> T2 keybinds
                                              │       ├──> T3 variables
                                              │       └──> T4 execs ──> T5 D-38 closed
                                              ├──> T6 config.json copy-capture
                                              ├──> T7 KDE/GTK files
                                              │       └── blocked on D7 for gtk-4.0/*
                                              │       └── blocked on D5 for kdeglobals
                                              └──> T8 verify drift check
                                                       └──> T9 one-command bootstrap
                                                                └──> requires D3 post-install re-stow
                                                                └──> requires D4 package snapshot
```

**Ordering notes.**
- **D1/D2 come first.** They are cheap (both derive from files already in the repo) and every capture decision downstream depends on them. Planning T1/T7 before D1 means guessing which paths are symlink-safe.
- **T5 is independent and one line.** It can ship in the first phase regardless of the capture mechanism — it is a `custom/execs.lua` edit, and `custom/` is the no-risk surface. Given `graphical-session.target` has been inactive since Sep 4, front-load it.
- **T8 must exist before T9 is meaningful.** "One command reproduces the exact setup" is unfalsifiable without a drift check to compare against.
- **D7 blocks part of T7.** Don't capture `gtk-4.0/` until the catppuccin-vs-matugen conflict is decided.

## Research flags for phases

| Phase topic | Needs deeper research? | Why |
|---|---|---|
| `hypr/custom` capture | **No** | Override contract fully mapped; installer is a proven no-op |
| Keybinds | **No** | `hl.unbind` confirmed in the shipped meta + binary; cheatsheet path confirmed live |
| `config.json` capture | **Light** | One empirical confirmation: change the wallpaper, then `ls -l ~/.config/illogical-impulse/config.json` |
| Startup restore | **Light** | Only unknown is the `hl.exec_cmd` rules-table key spelling for workspace pinning |
| KDE/GTK capture | **Yes, narrowly** | `kdeglobals` narrowing strategy (D5) and the GTK4 conflict (D7) are both open design questions |
| One-command bootstrap | **Yes** | No precedent in this repo — 34 independent scripts today; ordering and idempotence are unexplored |

---

## Open questions / UNVERIFIED

- **`hl.exec_cmd` rules-table key spelling** for workspace-pinned autostart (`{ workspace = "1", silent = true }`?). The meta declares `rules?: table<string, string|number|boolean>` but upstream never uses it. **UNVERIFIED** — test, with `hyprctl dispatch exec '[workspace 1 silent] …'` as fallback.
- **End-to-end Quickshell write through a symlink.** `QSaveFile` symlink-resolution is proven on this machine's Qt; `fileview.cpp` using `QSaveFile` is from a `webfetch` of the mirror's `master` (LOW confidence provider) while the installed build is `illogical-impulse-quickshell-git 0.1.0.r1-8`. The composed claim is **MEDIUM**. One live toggle confirms it.
- **Exact sequence that produced `kitty.conf.upstream`.** `rsync --delete` should have removed it at the Sep 4 install; its Jul 25 mtime suggests a `cp -a` restore from backup. **UNVERIFIED** and not worth chasing — the collision *class* is proven independently.
- **Whether `qt6ct.conf` has any effect** given `QT_QPA_PLATFORMTHEME=kde`. **UNVERIFIED.**
- **Whether `kde-material-you-colors` currently runs at all.** `~/.config/gtk-3.0/gtk.css` is absent despite matugen declaring it as an output, and live `kdeglobals` `[Colors:*]` blocks are byte-identical to the pin — suggesting the theming pipeline has not fired since the adopt. If true, the `kdeglobals` churn hazard is latent rather than active, and will surface on the first wallpaper change. **UNVERIFIED** — worth one deliberate `CTRL+SUPER+T` before deciding D5.
- **Whether GNU stow folds or unfolds `~/.config/hypr/custom/`.** The directory already exists with real files, so stow should create per-file symlinks rather than a directory symlink — which is what `install_dir__ignore_existing`'s "does nothing if the dir exists" check needs. **UNVERIFIED**; a directory symlink would still satisfy the check, so either outcome is safe, but per-file is preferable.

---

## Sources

**Primary (HIGH — read directly, or empirically tested on this machine 2026-09-12)**

- `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` — load order; byte-identical to live `~/.config/hypr/hyprland.lua`
- `vendor/dots-hyprland/dots/.config/hypr/hyprland/{keybinds,variables,execs,env}.lua`, `hyprland/lib/init.lua`, `hyprland/services/create_custom_config.lua`
- `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh` (helper definitions, lines 44–180) and `3.files-legacy.sh` (per-surface dispatch)
- `vendor/dots-hyprland/sdata/subcmd-install/{2.setups.sh,options.sh}` — no uwsm; `--skip-hyprland-entry` exists
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Config.qml` (633 lines, 95 `JsonObject`s), `modules/ii/bar/BarContent.qml`, `services/HyprlandKeybinds.qml`, `scripts/colors/{applycolor.sh,switchwall.sh}`, `dots/.config/matugen/config.toml`
- `/usr/share/hypr/stubs/hl.meta.lua` — `HL.API` incl. `hl.unbind`; `HL.BindOptions`; `HL.Keybind`
- Live system: `hyprctl version` (0.56.2), `hyprctl -j status` (`configProvider: lua`), `hyprctl binds -j` (195 binds / 90 described / 9 categories), `systemctl --user is-active graphical-session.target` (**inactive**), `~/.config/hypr/hyprland.conf.old`, `pacman -Qqe` (261 / 56 AUR / 15 ii metas)
- Empirical tests run 2026-09-12 in scratch: `rsync -a --delete` vs. symlink; `cp -f` vs. symlink; shell `mv` vs. symlink; `QSaveFile` vs. symlink on `qt6-base 6.11.2` via PySide6 6.11.2
- Full `diff -rq` of every ii-shipped `dots/.config` entry against live

**Secondary (MEDIUM)**

- Quickshell `FileView` / `JsonAdapter` API docs via Context7 (`/websites/quickshell_master`) — `atomicWrites` default true, implemented as temp-file + rename
- Qt `qsavefile.cpp` (`qt/qtbase` dev branch) — symlink-chain resolution in `QSaveFile::open()`

**Tertiary (LOW)**

- [illogical-impulse — Configuration](https://ii.clsty.link/en/ii-qs/03config/) — `custom/` is the override area, `hyprland/` is overwritten on update, `hl.unbind()` is the documented removal technique, advanced customization means editing `~/.config/quickshell/ii` directly
- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) and [issue #2294](https://github.com/end-4/dots-hyprland/issues/2294) (cited in `3.files-legacy.sh:25` as the reason the whole `quickshell` dir is synced)
- [Hyprland wiki — Binds](https://wiki.hypr.land/Configuring/Basics/Binds/)

**Repo context**

- `.planning/PROJECT.md` (v0.4 goal, D-41), `.planning/STATE.md` (D-38 open/unowned), `.planning/MILESTONES.md`, `.planning/research/v0.3/FEATURES.md`, `docs/dots-hyprland-workflow.md:339`

---
*FEATURES research for v0.4 — 2026-09-12*
