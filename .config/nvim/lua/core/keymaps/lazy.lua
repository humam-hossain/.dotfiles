--- TODO: Lazy keymap compilation for plugin specs ---

-- KEYMAP LAZY - Compile registry entries to lazy.nvim key specs
-- This module compiles registry entries into plugin-facing `keys` specs
-- for lazy.nvim key-trigger loading.

local registry = require("core.keymaps.registry")

local M = {}

--- Get lazy keys for a specific plugin domain
--- @param domain string? optional domain filter (e.g., "f", "c", "g")
--- @return table[] keys specs for lazy.nvim
function M.get_keys(domain)
	local lazy_maps = registry.get_by_scope("lazy")
	local keys = {}

	for _, map in ipairs(lazy_maps) do
		if not domain or map.domain == domain then
			local key_spec = {
				map.lhs,
				function()
					local ok, mod = pcall(require, map.plugin)
					if ok and mod and mod[map.action] then
						mod[map.action]()
					elseif type(map.action) == "function" then
						map.action()
					else
						vim.cmd(map.action)
					end
				end,
				desc = map.desc,
			}
			table.insert(keys, key_spec)
		end
	end

	return keys
end

--- Get all lazy keys
--- @return table[] keys specs for lazy.nvim
function M.get_all_keys()
	return M.get_keys(nil)
end

--- Get search domain lazy keys (f prefix)
--- @return table[] keys specs for lazy.nvim
function M.search_keys()
	return M.get_keys("f")
end

--- Get code domain lazy keys (c prefix)
--- @return table[] keys specs for lazy.nvim
function M.code_keys()
	return M.get_keys("c")
end

--- Get git domain lazy keys (g prefix)
--- @return table[] keys specs for lazy.nvim
function M.git_keys()
	return M.get_keys("g")
end

--- Get explorer domain lazy keys (e prefix)
--- @return table[] keys specs for lazy.nvim
function M.explorer_keys()
	return M.get_keys("e")
end

--- Get buffer domain lazy keys (b prefix)
--- @return table[] keys specs for lazy.nvim
function M.buffer_keys()
	return M.get_keys("b")
end

--- Get window domain lazy keys (w prefix)
--- @return table[] keys specs for lazy.nvim
function M.window_keys()
	return M.get_keys("w")
end

--- Get toggle domain lazy keys (t prefix)
--- @return table[] keys specs for lazy.nvim
function M.toggle_keys()
	return M.get_keys("t")
end

--- Get save domain lazy keys (s prefix)
--- @return table[] keys specs for lazy.nvim
function M.save_keys()
	return M.get_keys("s")
end

--- Get fold domain lazy keys (ufo plugin)
--- @return table[] keys specs for lazy.nvim
function M.fold_keys()
	local fold_maps = {}
	local lazy_maps = registry.get_by_scope("lazy")
	for _, map in ipairs(lazy_maps) do
		if map.plugin == "ufo" then
			table.insert(fold_maps, {
				map.lhs,
				function()
					local ok, mod = pcall(require, map.plugin)
					if ok and mod and mod[map.action] then
						mod[map.action]()
					elseif type(map.action) == "function" then
						map.action()
					else
						vim.cmd(map.action)
					end
				end,
				desc = map.desc,
			})
		end
	end
	return fold_maps
end

return M

