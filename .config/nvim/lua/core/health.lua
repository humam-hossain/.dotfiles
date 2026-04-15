local M = {}

local TOOL_METADATA = {
	["stylua"]              = { affected_feature = "Lua formatting",              install_hint = "mason: :MasonInstall stylua  OR  cargo install stylua" },
	["black"]               = { affected_feature = "Python formatting",           install_hint = "mason: :MasonInstall black  OR  pipx install black" },
	["isort"]               = { affected_feature = "Python import sorting",       install_hint = "mason: :MasonInstall isort  OR  pipx install isort" },
	["prettierd"]           = { affected_feature = "JS/TS/CSS/HTML formatting",   install_hint = "mason: :MasonInstall prettierd  OR  npm i -g @fsouza/prettierd" },
	["prettier"]            = { affected_feature = "JS/TS/CSS/HTML fallback",     install_hint = "mason: :MasonInstall prettier  OR  npm i -g prettier" },
	["clang-format"]        = { affected_feature = "C/C++ formatting",            install_hint = "distro package: pacman -S clang (Arch)  OR  apt install clang-format (Debian)" },
	["shfmt"]               = { affected_feature = "Shell formatting",            install_hint = "go install mvdan.cc/sh/v3/cmd/shfmt@latest" },
	["rg"]                  = { affected_feature = "fzf-lua live grep",           install_hint = "distro package ripgrep" },
	["git"]                 = { affected_feature = "gitsigns, fugitive, lazy",    install_hint = "distro package git" },
	["node"]                = { affected_feature = "ts-ls, eslint-d, prettierd runtime", install_hint = "distro package nodejs" },
	["go"]                  = { affected_feature = "gopls, shfmt build",          install_hint = "distro package go" },
	["clangd"]              = { affected_feature = "C/C++ LSP",                   install_hint = "mason: :MasonInstall clangd" },
	["gopls"]               = { affected_feature = "Go LSP",                      install_hint = "mason: :MasonInstall gopls" },
	["lua-language-server"] = { affected_feature = "Lua LSP",                     install_hint = "mason: :MasonInstall lua-language-server" },
	["eslint_d"]            = { affected_feature = "ESLint LSP",                  install_hint = "mason: :MasonInstall eslint_d" },
	["ts_ls"]               = { affected_feature = "TypeScript LSP",              install_hint = "mason: :MasonInstall ts_ls" },
	["jdtls"]               = { affected_feature = "Java LSP",                    install_hint = "mason: :MasonInstall jdtls" },
	["texlab"]              = { affected_feature = "LaTeX LSP",                   install_hint = "mason: :MasonInstall texlab" },
}

local function probe_plugin(name)
	local ok, err = pcall(require, name)
	return {
		name = name,
		loaded = ok and true or false,
		error = (not ok) and tostring(err) or vim.NIL,
	}
end

local function probe_tool(name)
	local available = vim.fn.executable(name) == 1
	local path = available and vim.fn.exepath(name) or ""
	local meta = TOOL_METADATA[name] or { affected_feature = "unknown", install_hint = "no hint registered" }
	return {
		name             = name,
		available        = available,
		path             = path,
		affected_feature = meta.affected_feature,
		install_hint     = meta.install_hint,
	}
end

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
		table.insert(plugin_results, probe_plugin(name))
	end

	local tool_results = {}
	for _, name in ipairs(tools) do
		table.insert(tool_results, probe_tool(name))
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

return M
