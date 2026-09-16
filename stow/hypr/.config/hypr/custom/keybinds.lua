-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.

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
hl.unbind("SUPER + Q")     -- upstream close window (replaced by SUPER + C)
hl.unbind("SUPER + Left")  -- upstream focus left (replaced by SUPER + H)
hl.unbind("SUPER + Right") -- upstream focus right (replaced by SUPER + L)
hl.unbind("SUPER + Up")    -- upstream focus up (replaced by SUPER + K)
hl.unbind("SUPER + Down")  -- upstream focus down (replaced by SUPER + J)
hl.unbind("SUPER + ALT + M")   -- upstream mic toggle (reassigned)
hl.unbind("SUPER + SHIFT + M") -- upstream volume mute (conflicting)
hl.unbind("SUPER + SUPER_L")   -- upstream bare super search trigger
hl.unbind("SUPER + SUPER_R")   -- upstream bare super search trigger
hl.unbind("Print")             -- upstream fullscreen screenshot
hl.unbind("SUPER + SHIFT + S") -- upstream screen snip (reassigned to SHIFT + Print)
hl.unbind("SUPER + SHIFT + L") -- upstream sleep (reassigned to SUPER + Scroll_Lock)

-- Window management (D-07, D-08, D-10)
hl.bind("SUPER + C", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind("SUPER + D", hl.dsp.window.float({ action = "toggle" }), { description = "Window: Float/Tile" })
hl.bind("SUPER + ALT + D", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Window: Toggle maximize" })
hl.bind("SUPER + P", hl.dsp.window.pseudo(), { description = "Window: Toggle pseudo-tile" })
hl.bind("SUPER + Z", hl.dsp.layout("togglesplit"), { description = "Window: Toggle split layout" })

-- Window movement to numbered workspaces (1-10)
hl.bind("SUPER + SHIFT + 1", function() hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(1), follow = true })) end, { description = "Window: Move to workspace 1" })
hl.bind("SUPER + SHIFT + 2", function() hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(2), follow = true  })) end, { description = "Window: Move to workspace 2" })
hl.bind("SUPER + SHIFT + 3", function() hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(3), follow = true  })) end, { description = "Window: Move to workspace 3" })
hl.bind("SUPER + SHIFT + 4", function() hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(4), follow = true  })) end, { description = "Window: Move to workspace 4" })
hl.bind("SUPER + SHIFT + 5", function() hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(5), follow = true  })) end, { description = "Window: Move to workspace 5" })
hl.bind("SUPER + SHIFT + 6", function() hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(6), follow = true  })) end, { description = "Window: Move to workspace 6" })
hl.bind("SUPER + SHIFT + 7", function() hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(7), follow = true  })) end, { description = "Window: Move to workspace 7" })
hl.bind("SUPER + SHIFT + 8", function() hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(8), follow = true  })) end, { description = "Window: Move to workspace 8" })
hl.bind("SUPER + SHIFT + 9", function() hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(9), follow = true  })) end, { description = "Window: Move to workspace 9" })
hl.bind("SUPER + SHIFT + 0", function() hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(10), follow = true  })) end, { description = "Window: Move to workspace 10" })

-- Vim-style window focus navigation (D-09)
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }), { description = "Window: Focus left" })
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }), { description = "Window: Focus right" })
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }), { description = "Window: Focus up" })
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }), { description = "Window: Focus down" })

-- Audio controls (D-11, G-20-2)
hl.bind("SUPER + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, description = "Audio: Toggle mic" })
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, description = "Audio: Toggle mute" })

-- Shell search (D-12)
hl.bind("SUPER + Space", hl.dsp.global("quickshell:searchToggle"), { description = "Shell: Toggle search" })

-- Utilities: Screenshot and screen snip
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m window --freeze -o $HOME/Pictures/Screenshots"), { locked = true, description = "Utilities: Screenshot window" })
hl.bind("SHIFT + Print", hl.dsp.global("quickshell:regionScreenshot"), { description = "Utilities: Screen snip" })

-- Session controls (D-12, D-13)
hl.bind("Scroll_Lock", hl.dsp.exec_cmd("hyprlock"), { description = "Session: Lock screen" })
hl.bind("SUPER + Scroll_Lock", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"), { locked = true, description = "Session: Sleep" })
hl.bind("SUPER + SHIFT + Scroll_Lock", hl.dsp.exit(), { description = "Session: Logout" })

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
