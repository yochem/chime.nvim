local clear_augroup = vim.api.nvim_create_augroup('chime.clear', {})

local M = {}

--- @param diagnostic vim.Diagnostic
--- @return string
local function format(diagnostic)
	local fmt = ('[%s] %s (%s)'):format(
		vim.diagnostic.severity[diagnostic.severity],
		diagnostic.message,
		diagnostic.source
	)
	local win_width = vim.api.nvim_win_get_width(0)
	if #fmt >= win_width - 10 then
		fmt = fmt:sub(0, win_width - 15) .. " …"
	end
	return fmt
end

--- @param key string The config field.
local function config(key)
	-- straight from :h vim.diagnostic.Opts
	local default = {
		severity_sort = false,
		severity = nil,
		format = format,
	}
	local global = vim.diagnostic.config() or {}
	local chime = global['chime']
	if type(chime) ~= 'table' then chime = {} end

	return vim.F.if_nil(chime[key], global[key], default[key])
end

--- Create an empty message that is only printed once.
local function clear_msg_area()
	vim.api.nvim_create_autocmd('User', {
		once = true,
		group = clear_augroup,
		callback = function()
			vim.api.nvim_echo({ { '' } }, false, {})
		end,
	})
end

--- @param diagnostics vim.Diagnostic[]
local function severity_sort(diagnostics)
	local sort = config('severity_sort')
	local reverse = type(sort) == 'table' and sort.reverse == true
	table.sort(diagnostics, function (a, b)
		if reverse then
			return a.severity > b.severity
		else
			return a.severity < b.severity
		end
	end)
end

local function line_diagnostic()
	-- clear first
	vim.api.nvim_exec_autocmds('User', { group = clear_augroup })

	local lnum, _ = unpack(vim.api.nvim_win_get_cursor(0))
	local diagnostics = vim.diagnostic.get(0, {
		lnum = lnum - 1,
		severity = config('severity')
	})

	if not vim.tbl_isempty(diagnostics) then
		if config('severity_sort') then
			severity_sort(diagnostics)
		end

		-- TODO: config: severity_sort
		local formatfunc = config('format')
		local msg = formatfunc(diagnostics[1])
		-- TODO: check if otherwise table of pairs
		local chunks = type(msg) == 'string' and { { vim.split(msg, '\n')[1] } } or msg
		vim.api.nvim_echo(chunks, false, {})
		clear_msg_area()
	end
end

function M.show()
	local augroup = vim.api.nvim_create_augroup('chime', {})
	vim.api.nvim_create_autocmd('CursorMoved', {
		group = augroup,
		callback = function()
			-- self-destruct if explicitly set to false
			if config('chime') == false then
				vim.api.nvim_del_augroup_by_id(augroup)
				return
			end
			line_diagnostic()
		end,
	})
end

return M
