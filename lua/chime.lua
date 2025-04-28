local M = {}

--- Trim message to fit the |v:echospace| area.
--- @param msg_chunks { [1]: string, [2]: string }[]
--- @return { [1]: string, [2]: string }[]
local function trim_msg(msg_chunks)
	local curlen = 0
	local maxlen = vim.v.echospace

	for i, chunk in ipairs(msg_chunks) do
		local text, _ = unpack(chunk)
		if curlen + #text > maxlen then
			msg_chunks[i][1] = text:sub(0, maxlen - curlen - 1) .. '…'
		end
		curlen = curlen + #text
	end

	return msg_chunks
end

--- @param diagnostic vim.Diagnostic
--- @return string
local function default_format(diagnostic)
	local fmt = ('[%s] %s (%s)'):format(
		vim.diagnostic.severity[diagnostic.severity],
		diagnostic.message,
		diagnostic.source
	)
	return fmt
end

--- @param key string The config field.
local function config(key)
	-- straight from :h vim.diagnostic.Opts
	local default = {
		format = default_format,
		severity = nil,
		severity_sort = false,
		trim = true,
	}
	local global = vim.diagnostic.config() or {}
	local chime = global['chime']
	if type(chime) ~= 'table' then chime = {} end

	return vim.F.if_nil(chime[key], global[key], default[key])
end

--- Sorts diagnostics based on severity *in-place*.
--- @param diagnostics vim.Diagnostic[]
local function severity_sort(diagnostics)
	local sort = config('severity_sort')
	local reverse = type(sort) == 'table' and sort.reverse == true
	table.sort(diagnostics, function(a, b)
		return reverse and (a.severity > b.severity) or (a.severity < b.severity)
	end)
end

local function clear_msg_on_move()
	vim.api.nvim_create_autocmd('CursorMoved', {
		command = 'echo',
		once = true,
		group = vim.api.nvim_create_augroup('chime.clear', {}),
	})
end

function M.show()
	local diagnostics = vim.diagnostic.get(0, {
		lnum = vim.fn.line('.') - 1,
		severity = config('severity')
	})

	if not vim.tbl_isempty(diagnostics) then
		if config('severity_sort') then
			severity_sort(diagnostics)
		end

		local formatfunc = config('format')
		local msg = formatfunc(diagnostics[1])
		-- TODO: this just assumes that it's a table otherwise
		local chunks = type(msg) == 'string' and { { vim.split(msg, '\n')[1] } } or msg

		if config('trim') then
			chunks = trim_msg(chunks)
		end

		vim.api.nvim_echo(chunks, false, {})
		clear_msg_on_move()
	end
end

function M.handler()
	local augroup = vim.api.nvim_create_augroup('chime', {})
	vim.api.nvim_create_autocmd({ 'WinResized', 'CursorMoved', 'DiagnosticChanged' }, {
		group = augroup,
		callback = function()
			-- self-destruct if explicitly set to false (and not just `nil`)
			if config('chime') == false then
				vim.api.nvim_del_augroup_by_id(augroup)
				return
			end
			M.show()
		end,
	})
end

return M
