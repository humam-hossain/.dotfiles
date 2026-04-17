--- TODO: Which-key group registration ---

-- ============================================================================
-- KEYMAP WHICHKEY - Registry-driven which-key group registration
-- ============================================================================
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

  -- Register domain groups
  local groups = registry.groups
  for _, g in ipairs(groups) do
    which_key.add({
      { "<leader>" .. g.prefix, group = g.label },
    })
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