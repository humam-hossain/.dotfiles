-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.

-- Floating rules for python graphical tools (D-17, docs/archive/hyprland.conf:458-467)
hl.window_rule({ match = { class = "^(main.py)$" }, float = true })
hl.window_rule({ match = { class = "^(python3)$" }, float = true })

-- Social workspace pinning for Discord / Vesktop (G-20-1)
hl.window_rule({ match = { class = "^(discord|vesktop)$" }, workspace = "special:social silent" })

