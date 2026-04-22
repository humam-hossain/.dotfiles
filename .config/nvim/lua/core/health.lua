local M = {}

-- TOOL_METADATA: required=true  => vim.health.error() if missing (and FAIL in nvim-validate.sh health)
--                required=false => vim.health.warn() only (optional/degraded silently at runtime)
local TOOL_METADATA = {
	-- Required tools — their absence crashes core functionality
	["git"]                 = { required = true,  affected_feature = "gitsigns, lazy plugin manager, diff/blame", install_hint = "distro package: pacman -S git (Arch)  OR  apt install git (Debian)" },
	["rg"]                  = { required = true,  affected_feature = "snacks.picker live grep, file search",      install_hint = "distro package: pacman -S ripgrep (Arch)  OR  apt install ripgrep (Debian)" },
	-- Optional tools — missing tools degrade the corresponding feature silently
	["stylua"]              = { required = false, affected_feature = "Lua formatting (conform)",                  install_hint = "mason: :MasonInstall stylua  OR  cargo install stylua" },
	["black"]               = { required = false, affected_feature = "Python formatting (conform)",               install_hint = "mason: :MasonInstall black  OR  pipx install black" },
	["isort"]               = { required = false, affected_feature = "Python import sorting (conform)",           install_hint = "mason: :MasonInstall isort  OR  pipx install isort" },
	["prettierd"]           = { required = false, affected_feature = "JS/TS/CSS/HTML formatting (conform)",       install_hint = "mason: :MasonInstall prettierd  OR  npm i -g @fsouza/prettierd" },
	["prettier"]            = { required = false, affected_feature = "JS/TS/CSS/HTML formatting fallback",        install_hint = "mason: :MasonInstall prettier  OR  npm i -g prettier" },
	["clang-format"]        = { required = false, affected_feature = "C/C++ formatting (conform)",               install_hint = "distro package: pacman -S clang (Arch)  OR  apt install clang-format (Debian)" },
	["shfmt"]               = { required = false, affected_feature = "Shell formatting (conform)",               install_hint = "mason: :MasonInstall shfmt  OR  go install mvdan.cc/sh/v3/cmd/shfmt@latest" },
	["node"]                = { required = false, affected_feature = "ts-ls, eslint-d, prettierd runtime",       install_hint = "distro package: pacman -S nodejs (Arch)  OR  apt install nodejs (Debian)" },
	["go"]                  = { required = false, affected_feature = "gopls, shfmt build",                       install_hint = "distro package: pacman -S go (Arch)  OR  apt install golang (Debian)" },
	["clangd"]              = { required = false, affected_feature = "C/C++ LSP",                               install_hint = "mason: :MasonInstall clangd  OR  pacman -S clang (Arch)" },
	["gopls"]               = { required = false, affected_feature = "Go LSP",                                  install_hint = "mason: :MasonInstall gopls" },
	["lua-language-server"] = { required = false, affected_feature = "Lua LSP",                                 install_hint = "mason: :MasonInstall lua-language-server  OR  pacman -S lua-language-server (Arch)" },
	["eslint_d"]            = { required = false, affected_feature = "ESLint LSP / linting",                    install_hint = "mason: :MasonInstall eslint_d" },
	["ts_ls"]               = { required = false, affected_feature = "TypeScript LSP",                          install_hint = "mason: :MasonInstall ts_ls" },
	["jdtls"]               = { required = false, affected_feature = "Java LSP",                               install_hint = "mason: :MasonInstall jdtls" },
	["texlab"]              = { required = false, affected_feature = "LaTeX LSP",                               install_hint = "mason: :MasonInstall texlab" },
}

-- probe_plugin: exported for reuse by lua/config/health.lua (D-13)
function M.probe_plugin(name)
	local ok, err = pcall(require, name)
	return {
		name = name,
		loaded = ok and true or false,
		error = (not ok) and tostring(err) or vim.NIL,
	}
end

-- probe_tool: exported for reuse by lua/config/health.lua (D-13)
function M.probe_tool(name)
	local available = vim.fn.executable(name) == 1
	local path = available and vim.fn.exepath(name) or ""
	local meta = TOOL_METADATA[name] or { required = false, affected_feature = "unknown", install_hint = "no hint registered" }
	return {
		name             = name,
		available        = available,
		path             = path,
		required         = meta.required,
		affected_feature = meta.affected_feature,
		install_hint     = meta.install_hint,
	}
end

-- Expose TOOL_METADATA so config/health.lua can iterate required vs optional
M.TOOL_METADATA = TOOL_METADATA

local function probe_lazy()
	local ok_lazy, lazy = pcall(require, "lazy")
	if not ok_lazy then
		return { installed = -1, loaded = -1, problems = {} }
	end
	local stats = lazy.stats() or {}
	local problems = {}
	local ok_plugins, plugins_mod = pcall(require, "lazy.core.config")
	if ok_plugins and plugins_mod.plugins then
		for pname, pspec in pairs(plugins_mod.plugins) do
			if pspec._ and pspec._.loaded == nil and pspec.lazy == false then
				table.insert(problems, { name = pname, reason = "eager plugin never marked loaded" })
			end
		end
	end
	return {
		installed = stats.count or -1,
		loaded = stats.loaded or -1,
		problems = problems,
	}
end

function M.snapshot(opts)
	opts = opts or {}
	local out_path = opts.out_path
	if type(out_path) ~= "string" or out_path == "" then
		vim.api.nvim_echo({ { "core.health.snapshot: opts.out_path required", "ErrorMsg" } }, true, {})
		return 1
	end

	local plugins = opts.plugins or {}
	local tools = opts.tools or {}

	local plugin_results = {}
	for _, name in ipairs(plugins) do
		table.insert(plugin_results, M.probe_plugin(name))
	end

	local tool_results = {}
	for _, name in ipairs(tools) do
		table.insert(tool_results, M.probe_tool(name))
	end

	local snapshot = {
		neovim_version = tostring(vim.version()),
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		plugins = plugin_results,
		tools = tool_results,
		lazy = probe_lazy(),
	}

	local ok_enc, encoded = pcall(vim.json.encode, snapshot)
	if not ok_enc then
		vim.api.nvim_echo({ { "core.health.snapshot: json encode failed: " .. tostring(encoded), "ErrorMsg" } }, true, {})
		return 1
	end

	local dir = vim.fn.fnamemodify(out_path, ":h")
	if dir ~= "" and vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end

	local fd, ferr = io.open(out_path, "w")
	if not fd then
		vim.api.nvim_echo({ { "core.health.snapshot: open failed: " .. tostring(ferr), "ErrorMsg" } }, true, {})
		return 1
	end
	fd:write(encoded)
	fd:close()
	return 0
end

-- M.check: compatibility shim so Neovim's auto-discovery of core/health.lua
-- as a health provider does not crash :checkhealth core. Delegates to
-- config.health when available; emits an error section if the real provider
-- is missing. This keeps core.health as shared probe infrastructure rather
-- than a duplicate full-report provider.
function M.check()
	local ok, config_health = pcall(require, "config.health")
	if ok and type(config_health.check) == "function" then
		config_health.check()
	else
		vim.health.start("core (compatibility shim)")
		vim.health.warn(
			"':checkhealth core' delegates to ':checkhealth config'. " ..
			"Run ':checkhealth config' for the full report.",
			{ "The real health provider lives in lua/config/health.lua" }
		)
	end
end

return M
