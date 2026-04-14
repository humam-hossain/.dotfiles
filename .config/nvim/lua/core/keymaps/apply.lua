-- ============================================================================
-- KEYMAP APPLY - Applies global/eager mappings from the registry
-- ============================================================================
-- This module applies mappings from the registry that should be active
-- immediately at Neovim startup (scope = "global").

local registry = require("core.keymaps.registry")

local M = {}

-- Apply all global mappings from the registry
function M.apply_global()
  local global_maps = registry.get_by_scope("global")

  for _, map in ipairs(global_maps) do
    local opts = map.opts or {}
    opts.desc = map.desc

    if type(map.action) == "string" then
      vim.keymap.set(map.mode, map.lhs, map.action, opts)
    elseif type(map.action) == "function" then
      vim.keymap.set(map.mode, map.lhs, map.action, opts)
    end
  end
end

-- Apply a single mapping by ID
function M.apply_by_id(id)
  local map = registry.get_by_id(id)
  if not map then
    vim.notify("[keymaps.apply] Unknown mapping ID: " .. id, vim.log.levels.WARN)
    return
  end

  local opts = map.opts or {}
  opts.desc = map.desc

  if type(map.action) == "string" then
    vim.keymap.set(map.mode, map.lhs, map.action, opts)
  elseif type(map.action) == "function" then
    vim.keymap.set(map.mode, map.lhs, map.action, opts)
  end
end

-- Apply multiple mappings by ID
function M.apply_by_ids(ids)
  for _, id in ipairs(ids) do
    M.apply_by_id(id)
  end
end

return M