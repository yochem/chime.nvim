vim.diagnostic.handlers['chime'] = {
	show = function()
		require('chime').show()
	end
}
