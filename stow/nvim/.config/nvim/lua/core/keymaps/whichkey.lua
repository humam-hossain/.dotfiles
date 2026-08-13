--- TODO: Which-key group registration ---

-- KEYMAP WHICHKEY - Registry-driven which-key group registration
-- This module registers domain groups and mapping hints from the registry
-- for which-key popup display.

local registry = require("core.keymaps.registry")

local M = {}

-- Setup which-key with all domain groups and individual key descriptions
function M.setup()
	local ok, which_key = pcall(require, "which-key")
	if not ok then
		vim.notify("[keymaps.whichkey] which-key not loaded", vim.log.levels.DEBUG)
		return
	end

	-- Build a set of lhs values already claimed by real mappings (global + lazy).
	-- Group registration is skipped for any <leader><prefix> whose exact lhs
	-- is already a real mapping — which-key would otherwise emit a "Duplicates"
	-- warning for that key (e.g. <leader>e "Explorer" group vs. <leader>e
	-- "Toggle file explorer" mapping both registering for the same lhs).
	local claimed = {}
	for _, m in ipairs(registry.get_by_scope("global")) do
		claimed[m.lhs] = true
	end
	for _, m in ipairs(registry.get_by_scope("lazy")) do
		claimed[m.lhs] = true
	end

	-- Register domain groups (skip any whose <leader><prefix> is already a mapping)
	local groups = registry.groups
	for _, g in ipairs(groups) do
		local group_lhs = "<leader>" .. g.prefix
		if not claimed[group_lhs] then
			which_key.add({
				{ group_lhs, group = g.label },
			})
		end
	end

	-- Register global mappings with descriptions
	local global_maps = registry.get_by_scope("global")
	local global_specs = {}
	for _, map in ipairs(global_maps) do
		if map.lhs:match("^<leader>") then
			table.insert(global_specs, {
				map.lhs,
				desc = map.desc,
			})
		end
	end
	if #global_specs > 0 then
		which_key.add(global_specs)
	end

	-- Register lazy mappings with descriptions
	local lazy_maps = registry.get_by_scope("lazy")
	local lazy_specs = {}
	for _, map in ipairs(lazy_maps) do
		table.insert(lazy_specs, {
			map.lhs,
			desc = map.desc,
		})
	end
	if #lazy_specs > 0 then
		which_key.add(lazy_specs)
	end
end

return M

