local M = {}

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
	return { name = name, available = available, path = path }
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
