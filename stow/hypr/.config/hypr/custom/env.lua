-- Authoring SoT: parent-repo .config/hypr/custom/ (see 13-SOT-APPLY.md). Do not commit into vendor/dots-hyprland.

-- Environment overrides (D-18 / HYPR-01)
-- Upstream hyprland/env.lua already configures Wayland, Qt, and Python virtualenv paths.
-- This file exists as a managed require slot for personal environment additions.

-- Cursor theme environment variables (ensure compositor & applications initialize with Bibata on start)
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")
