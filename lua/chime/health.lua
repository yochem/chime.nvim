local M = {}

function M.check()
	vim.health.start('Configuration')

	local cfg = vim.diagnostic.config()['chime']

	if cfg == nil then
		vim.health.error('diagnostic handler for chime not found')
	elseif cfg == false then
		vim.health.warn('chime is disabled')
	elseif cfg == true then
		vim.health.ok('using default configuration')
	else
		vim.health.ok('using custom configuration:\n' .. vim.inspect(cfg))
	end
end

return M
