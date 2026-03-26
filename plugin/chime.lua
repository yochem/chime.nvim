if vim.g.loaded_chime ~= nil then
  return
end
vim.g.loaded_chime = true

vim.diagnostic.handlers['chime'] = {
  show = function(ns, buf, diagnostics, opts)
    require('chime').register(ns, buf, diagnostics, opts)
  end,

  hide = function()
    require('chime').echo({})
  end,
}
