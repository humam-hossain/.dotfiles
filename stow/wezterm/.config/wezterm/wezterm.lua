local wezterm = require("wezterm")

return {
	-- Font
	font = wezterm.font_with_fallback({ "DepartureMono Nerd Font Mono", "Symbols Nerd Font Mono", "JetBrainsMono Nerd Font Mono" }),
	font_size = 11.0,

	-- Window
	window_background_opacity = 1.0,
	window_decorations = "NONE", -- Good for tiling WMs

	-- Colors
	color_scheme = "Dracula",
	colors = { background = "#000000" },

	-- Disable WezTerm's built-in multiplexing (use tmux instead)
	enable_tab_bar = false,

	-- Key bindings - disable conflicts with tmux
	keys = {
		-- Disable WezTerm's Ctrl+Shift+T (new tab)
		{ key = "t", mods = "CTRL|SHIFT", action = "DisableDefaultAssignment" },
		{ key = "n", mods = "CTRL|SHIFT", action = "DisableDefaultAssignment" },
	},
}
