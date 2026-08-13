-- lua/config/health.lua
-- Repo-owned vim.health provider — discovered by Neovim at :checkhealth config
-- D-08/D-09: six sections: version, required tools, optional tools, plugin load,
-- config guards, known environment gaps.
-- D-11: every section is wrapped in pcall so a probe crash becomes a health error
--       rather than an uncaught exception that aborts the entire :checkhealth run.
-- D-12: does NOT deduplicate against lazy.nvim's own health provider.

local M = {}

-- Ordered plugin list — must match PLUGIN_LIST in scripts/nvim-validate.sh (D-14)
local PLUGIN_LIST = {
	"snacks",
	"lualine",
	"lspconfig",
	"conform",
	"nvim-treesitter.configs",
	"blink.cmp",
	"gitsigns",
	"ufo",
	"bufferline",
	"which-key",
	"render-markdown",
}

-- ─── Section helpers ──────────────────────────────────────────────────────────

local function section_neovim_version()
	vim.health.start("Neovim version")
	local ok, result = pcall(function()
		local ver = vim.version()
		-- D-19: config targets Neovim >= 0.12.0
		if vim.version.cmp(ver, { 0, 12, 0 }) >= 0 then
			vim.health.ok(string.format("Neovim %s (>= 0.12.0 required)", tostring(ver)))
		else
			vim.health.error(
				string.format("Neovim %s is below the minimum required version (0.12.0)", tostring(ver)),
				{ "Upgrade Neovim: https://github.com/neovim/neovim/releases" }
			)
		end
	end)
	if not ok then
		vim.health.error("Version check crashed: " .. tostring(result))
	end
end

local function section_required_tools(probe_tool, tool_meta)
	-- D-15/D-16: required=true tools emit error(); all others are in the optional section
	vim.health.start("Required tools")
	local ok, result = pcall(function()
		local any_required = false
		for name, meta in pairs(tool_meta) do
			if meta.required then
				any_required = true
				local probe_ok, probe = pcall(probe_tool, name)
				if not probe_ok then
					vim.health.error("Probe for " .. name .. " crashed: " .. tostring(probe))
				elseif probe.available then
					vim.health.ok(string.format("%s found at %s", name, probe.path))
				else
					vim.health.error(
						string.format("%s not found — affects: %s", name, meta.affected_feature),
						{ "Install: " .. meta.install_hint }
					)
				end
			end
		end
		if not any_required then
			vim.health.warn("No required tools registered in TOOL_METADATA")
		end
	end)
	if not ok then
		vim.health.error("Required tools section crashed: " .. tostring(result))
	end
end

local function section_optional_tools(probe_tool, tool_meta)
	-- D-15/D-16: required=false tools emit warn() when missing
	vim.health.start("Optional tools")
	local ok, result = pcall(function()
		local all_ok = true
		for name, meta in pairs(tool_meta) do
			if not meta.required then
				local probe_ok, probe = pcall(probe_tool, name)
				if not probe_ok then
					vim.health.warn("Probe for " .. name .. " crashed: " .. tostring(probe))
				elseif probe.available then
					vim.health.ok(string.format("%s found at %s", name, probe.path))
				else
					all_ok = false
					vim.health.warn(
						string.format("%s not found — affects: %s", name, meta.affected_feature),
						{ "Install: " .. meta.install_hint }
					)
				end
			end
		end
		if all_ok then
			vim.health.ok("All optional tools available")
		end
	end)
	if not ok then
		vim.health.error("Optional tools section crashed: " .. tostring(result))
	end
end

local function section_plugin_load(probe_plugin)
	vim.health.start("Plugin load status")
	local ok, result = pcall(function()
		local all_loaded = true
		for _, name in ipairs(PLUGIN_LIST) do
			local probe_ok, probe = pcall(probe_plugin, name)
			if not probe_ok then
				all_loaded = false
				vim.health.error("Probe for " .. name .. " crashed: " .. tostring(probe))
			elseif probe.loaded then
				vim.health.ok(name .. " loaded")
			else
				all_loaded = false
				vim.health.error(
					name .. " failed to load",
					{ tostring(probe.error) }
				)
			end
		end
		if all_loaded then
			vim.health.ok("All " .. #PLUGIN_LIST .. " monitored plugins loaded successfully")
		end
	end)
	if not ok then
		vim.health.error("Plugin load section crashed: " .. tostring(result))
	end
end

local function section_config_guards()
	-- D-19: Neovim >= 0.12.0 guard (summarised here alongside other config-level checks)
	vim.health.start("Config guards")
	local ok, result = pcall(function()
		-- Neovim version gate
		local ver = vim.version()
		if vim.version.cmp(ver, { 0, 12, 0 }) >= 0 then
			vim.health.ok("Neovim >= 0.12.0 — native LSP config() and enable() APIs available")
		else
			vim.health.error(
				"Neovim < 0.12.0 — native LSP registration (vim.lsp.config/enable) will not work",
				{ "Upgrade Neovim to 0.12.0 or later" }
			)
		end

		-- core.health probe infrastructure reachable
		local core_ok, _ = pcall(require, "core.health")
		if core_ok then
			vim.health.ok("core.health probe infrastructure loaded")
		else
			vim.health.error("core.health failed to load — health probes unavailable")
		end

		-- lazy.nvim plugin manager reachable
		local lazy_ok, lazy = pcall(require, "lazy")
		if lazy_ok then
			local stats = lazy.stats() or {}
			vim.health.ok(string.format(
				"lazy.nvim: %d/%d plugins loaded",
				stats.loaded or 0, stats.count or 0
			))
		else
			vim.health.warn("lazy.nvim not reachable from config guard check")
		end
	end)
	if not ok then
		vim.health.error("Config guards section crashed: " .. tostring(result))
	end
end

local function section_known_environment_gaps()
	-- D-20/D-21/D-22: always rendered unconditionally — no OS or $TMUX gating.
	-- Plain language, no BUG IDs. Copy-paste ready guidance (D-21).
	vim.health.start("Known environment gaps")
	local ok, result = pcall(function()
		-- tmux cross-pane navigation
		-- The four bind-key entries must be present in ~/.tmux.conf (or ~/.config/.tmux.conf)
		-- for vim-tmux-navigator to forward <C-h/j/k/l> across tmux pane boundaries.
		vim.health.warn(
			"tmux companion bindings: if <C-h/j/k/l> do not cross pane boundaries inside tmux, " ..
			"add these four lines to ~/.tmux.conf (or ~/.config/.tmux.conf if that is your active config):",
			{
				"bind-key -n 'C-h' if-shell \"$is_vim\" 'send-keys C-h'  'select-pane -L'",
				"bind-key -n 'C-j' if-shell \"$is_vim\" 'send-keys C-j'  'select-pane -D'",
				"bind-key -n 'C-k' if-shell \"$is_vim\" 'send-keys C-k'  'select-pane -U'",
				"bind-key -n 'C-l' if-shell \"$is_vim\" 'send-keys C-l'  'select-pane -R'",
				"Then reload: tmux source-file ~/.tmux.conf",
			}
		)

		-- Linux external-open via <leader>o
		-- <C-S-o> was rebound to <leader>o because terminals strip the chord.
		-- vim.ui.open() also requires DISPLAY or WAYLAND_DISPLAY to be set when
		-- launched inside Neovim — test with: :lua vim.ui.open(vim.fn.expand('%:p'))
		-- If that returns silently without opening, check the environment:
		--   :lua print(vim.fn.getenv('DISPLAY'), vim.fn.getenv('WAYLAND_DISPLAY'))
		-- xdg-open from a terminal shell will work regardless.
		vim.health.warn(
			"Linux external-open (<leader>o): opens the current file with xdg-open via vim.ui.open(). " ..
			"If nothing happens, DISPLAY or WAYLAND_DISPLAY may not be propagated into the Neovim process.",
			{
				"Diagnose: :lua vim.ui.open(vim.fn.expand('%:p'))",
				"Check env: :lua print(vim.fn.getenv('DISPLAY'), vim.fn.getenv('WAYLAND_DISPLAY'))",
				"Shell fallback: xdg-open <file> works from a terminal even when the env gap is present",
			}
		)
	end)
	if not ok then
		vim.health.error("Known environment gaps section crashed: " .. tostring(result))
	end
end

-- ─── Public entry point ───────────────────────────────────────────────────────

function M.check()
	-- Load core.health once; wrap in pcall per D-11
	local core_ok, core = pcall(require, "core.health")
	if not core_ok then
		vim.health.start("config")
		vim.health.error(
			"Failed to load core.health — required probe infrastructure is missing: " .. tostring(core),
			{ "Ensure .config/nvim/lua/core/health.lua exists and has no syntax errors" }
		)
		return
	end

	section_neovim_version()
	section_required_tools(core.probe_tool, core.TOOL_METADATA)
	section_optional_tools(core.probe_tool, core.TOOL_METADATA)
	section_plugin_load(core.probe_plugin)
	section_config_guards()
	section_known_environment_gaps()
end

return M
