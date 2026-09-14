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
