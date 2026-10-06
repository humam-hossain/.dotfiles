-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.

-- Floating rules for python graphical tools (D-17, docs/archive/hyprland.conf:458-467)
hl.window_rule({ match = { class = "^(main.py)$" }, float = true })
hl.window_rule({ match = { class = "^(python3)$" }, float = true })

-- Social workspace pinning for Discord / Vesktop (G-20-1)
hl.window_rule({ match = { class = "^(discord|vesktop)$" }, workspace = "special:social silent" })

-- Thunderbird workspace pinning and silent background start
hl.window_rule({ match = { class = "^([Tt]hunderbird|org\\.mozilla\\.Thunderbird)$" }, workspace = "special:office silent" })
hl.window_rule({ match = { class = "^([Tt]hunderbird|org\\.mozilla\\.Thunderbird)$" }, no_initial_focus = true })
hl.window_rule({ match = { class = "^([Tt]hunderbird|org\\.mozilla\\.Thunderbird)$" }, suppress_event = "activate activatefocus" })

-- Slack workspace pinning and silent background start
hl.window_rule({ match = { class = "^([Ss]lack|com\\.slack\\.Slack)$" }, workspace = "special:office silent" })
hl.window_rule({ match = { class = "^([Ss]lack|com\\.slack\\.Slack)$" }, no_initial_focus = true })
hl.window_rule({ match = { class = "^([Ss]lack|com\\.slack\\.Slack)$" }, suppress_event = "activate activatefocus" })

