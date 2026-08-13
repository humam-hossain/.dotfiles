--- TODO: Buffer-local mappings on LSP attach ---

-- ============================================================================
-- KEYMAP ATTACH - Apply registry-owned scoped mappings for known contexts
-- ============================================================================
-- This module applies buffer-local and plugin-local mappings from the registry
-- for contexts like LspAttach, neo-tree windows, Treesitter, and CSV view.

local registry = require("core.keymaps.registry")

local M = {}

--- Apply buffer-local mappings for LSP context
--- @param bufnr number buffer number to apply mappings to
function M.apply_lsp(bufnr)
  local buffer_maps = registry.get_by_scope("buffer")
  for _, map in ipairs(buffer_maps) do
    if map.attach == "LspAttach" then
      local opts = {
        buffer = bufnr,
        desc = map.desc,
      }
      if map.opts then
        for k, v in pairs(map.opts) do
          opts[k] = v
        end
      end

      local modes = type(map.mode) == "table" and map.mode or { map.mode }
      for _, mode in ipairs(modes) do
        if type(map.action) == "function" then
          vim.keymap.set(mode, map.lhs, map.action, opts)
        else
          vim.keymap.set(mode, map.lhs, map.action, opts)
        end
      end
    end
  end
end

--- Get all buffer-scope mappings for LSP
--- @return table[] mapping specs
function M.get_lsp_maps()
  local buffer_maps = registry.get_by_scope("buffer")
  local lsp_maps = {}
  for _, map in ipairs(buffer_maps) do
    if map.attach == "LspAttach" then
      table.insert(lsp_maps, map)
    end
  end
  return lsp_maps
end

--- Apply plugin-local mappings for neo-tree context
--- @param bufnr number buffer number for neo-tree window
function M.apply_neotree(bufnr)
  local scoped_maps = registry.get_by_scope("plugin-local")
  for _, map in ipairs(scoped_maps) do
    if map.attach == "neo-tree" then
      local opts = {
        buffer = bufnr,
        desc = map.desc,
        noremap = true,
        nowait = true,
      }
      vim.keymap.set("n", map.lhs, map.action, opts)
    end
  end
end

--- Get all plugin-local mappings
--- @return table[] mapping specs
function M.get_plugin_local_maps()
  return registry.get_by_scope("plugin-local")
end

--- Register LspAttach autocmd to apply buffer-local mappings
function M.setup_lsp_attach()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("keymaps-attach-lsp", { clear = true }),
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        M.apply_lsp(bufnr)
      end
    end,
  })
end

return M