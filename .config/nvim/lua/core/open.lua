--- TODO: External file open via vim.ui.open() - cross-platform ---

-- CROSS-PLATFORM EXTERNAL OPEN HELPER
-- Provides OS-aware external open functionality that works across
-- Linux, macOS, and Windows using the system default application.

local M = {}

local function notify_error(msg)
	vim.notify(msg, vim.log.levels.ERROR, { title = "External Open" })
end

function M.open(target)
	if not target or target == "" then
		notify_error("No target provided to open")
		return
	end

	-- vim.ui.open() returns (cmd, errmsg?) — capture both values directly.
	-- Do NOT wrap in pcall; doing so drops the returned errmsg and replaces
	-- it with a Lua exception string that is often empty or misleading.
	local cmd, err = vim.ui.open(target)
	if err then
		notify_error("Failed to open: " .. err)
		return
	end

	-- cmd is the SystemObj / job handle.  A nil cmd with no err means the
	-- opener was called but produced no usable handle; surface that too.
	if not cmd then
		notify_error("Could not open: " .. target)
		return
	end
end

local function get_snacks_picker_path()
	local ft = vim.bo.filetype
	if ft ~= "snacks_picker_list" and ft ~= "snacks_picker_input" then
		return nil
	end

	local snacks = package.loaded["snacks"]
	if not snacks then
		return nil
	end

	local pickers = snacks.picker.get()
	if not pickers or #pickers == 0 then
		return nil
	end

	local picker = pickers[#pickers]
	local item = picker:current()
	if not item then
		return nil
	end

	return item.file or item.dir or (snacks.picker.util and snacks.picker.util.path(item))
end

function M.open_current_buffer()
	local target = get_snacks_picker_path()

	if not target then
		local buf_name = vim.api.nvim_buf_get_name(0)
		if buf_name and buf_name ~= "" then
			target = vim.fn.fnamemodify(buf_name, ":p")
		end
	end

	if not target then
		notify_error("No file in current buffer to open")
		return
	end

	M.open(target)
end

return M
