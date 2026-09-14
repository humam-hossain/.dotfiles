# DEBUG: Discord new windows open outside special:social (G-20-1)

**Status:** resolved  
**Phase:** 20-hypr-custom-overlays-and-startup-restore  
**Gap:** G-20-1  
**Discovered:** UAT test 1

## Symptoms

- expected: Discord/Vesktop windows open in special:social workspace (both initial startup and subsequent windows).
- actual: First loading does open in special:social, but subsequent new windows open in whatever workspace is currently active.
- reproduction: Launch Discord/Vesktop, then trigger a new window or launch Discord again while on another workspace.

## Root Cause

`stow/hypr/.config/hypr/custom/execs.lua` launches Discord with `[workspace special:social silent] sh -c 'command -v vesktop >/dev/null 2>&1 && exec vesktop || exec discord'` inside the startup hook. This one-time exec dispatcher assigns only the initial startup process instance to `special:social`.

However, `stow/hypr/.config/hypr/custom/rules.lua` does not define a persistent window rule for `discord` or `vesktop`. In the archived `docs/archive/hyprland.conf:94`, the rule `# windowrulev2 = workspace special:social silent, class:^(discord)$` was commented out pre-adoption and was not brought into `custom/rules.lua`. Without a persistent `hl.window_rule` matching `class = "^(discord|vesktop)$"`, Hyprland routes any new window or instance of Discord to the user's currently focused workspace.

## Evidence

- `stow/hypr/.config/hypr/custom/execs.lua` L28: `hl.exec_cmd("[workspace special:social silent] sh -c 'command -v vesktop >/dev/null 2>&1 && exec vesktop || exec discord'")` (only governs initial exec-once).
- `stow/hypr/.config/hypr/custom/rules.lua` L1-6: contains only floating rules for `main.py` and `python3`, with no rule for `discord` or `vesktop`.
- `docs/archive/hyprland.conf` L94: `# windowrulev2 = workspace special:social silent, class:^(discord)$` was commented out in legacy config.
- `hyprctl -i 0 repl`: verified that `hl.window_rule({ match = { class = "^(discord|vesktop)$" }, workspace = "special:social silent" })` is supported by Hyprland's native Lua runtime.

## Files Involved

- `stow/hypr/.config/hypr/custom/rules.lua`: missing window rule for discord/vesktop workspace assignment.
- `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh`: Section 3 assert checks rules.lua.

## Suggested Fix Direction

Add persistent window rule in `stow/hypr/.config/hypr/custom/rules.lua`:
```lua
-- Social workspace pinning for Discord / Vesktop
hl.window_rule({ match = { class = "^(discord|vesktop)$" }, workspace = "special:social silent" })
```
Update `scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh` to assert this rule's presence, reload compositor (`hyprctl reload`), and verify with `verify --strict`.
