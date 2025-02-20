vim.diagnostic.handlers['chime'] = {
	show = function()
		require('chime').handler()
	end
}
