-- ============================================================================
-- CROSS-PLATFORM EXTERNAL OPEN HELPER
-- ============================================================================
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

	local success, err = pcall(vim.ui.open, target)
	if not success then
		notify_error("Failed to open: " .. tostring(err))
		return
	end

	if err == nil or err == false then
		notify_error("Could not open: " .. target)
		return
	end
end

function M.open_current_buffer()
	local buf_name = vim.api.nvim_buf_get_name(0)
	if not buf_name or buf_name == "" then
		notify_error("No file in current buffer to open")
		return
	end

	local target = vim.fn.fnamemodify(buf_name, ":p")
	M.open(target)
end

return M
