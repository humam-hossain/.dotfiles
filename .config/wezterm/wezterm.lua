local wezterm = require("wezterm")

return {
	-- Font
	font = wezterm.font("JetBrains Mono"),
	font_size = 11.0,

	-- Window
	window_background_opacity = 0.9,
	window_decorations = "NONE", -- Good for tiling WMs

	-- Colors
	color_scheme = "Dracula",

	-- Disable WezTerm's built-in multiplexing (use tmux instead)
	enable_tab_bar = false,

	-- Key bindings - disable conflicts with tmux
	keys = {
		-- Disable WezTerm's Ctrl+Shift+T (new tab)
		{ key = "t", mods = "CTRL|SHIFT", action = "DisableDefaultAssignment" },
		{ key = "n", mods = "CTRL|SHIFT", action = "DisableDefaultAssignment" },
	},
}
