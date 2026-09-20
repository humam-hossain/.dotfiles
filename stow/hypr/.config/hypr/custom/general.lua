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

-- Layout geometry: zero gaps, 2px border, refined corners
hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 2,
    },
    decoration = {
        rounding = 5,
        rounding_power = 2,
    },
    animations = {
        enabled = true,
    },
})

-- Smooth & fluid window animations (speed ~4-5, elegant deceleration)
hl.curve("easeOutQuint", {
    type = "bezier",
    points = {{0.23, 1}, {0.32, 1}},
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 4.5,
    bezier = "easeOutQuint",
    style = "popin 80%",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3.5,
    bezier = "easeOutQuint",
    style = "popin 85%",
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 4.5,
    bezier = "easeOutQuint",
    style = "slide",
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 4,
    bezier = "easeOutQuint",
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4.5,
    bezier = "easeOutQuint",
    style = "slide",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 5,
    bezier = "easeOutQuint",
})
