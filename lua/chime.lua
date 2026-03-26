local M = {}

local augroup = vim.api.nvim_create_augroup('chime', {})
local is_registered = false

local function has_ui2()
  local ui2 = require('vim._core.ui2')
  return ui2.cfg.enable and ui2.bufs.cmd ~= -1
end

--- Trim message to fit the |v:echospace| area.
--- @param chunks [string, integer|string?][]
--- @return [string, integer|string?][]
local function trim_msg(chunks)
  local curlen = 0
  local maxlen = vim.v.echospace

  for i, chunk in ipairs(chunks) do
    local text, _ = unpack(chunk)
    if curlen > maxlen then
      chunks[i] = nil
    elseif curlen + #text > maxlen then
      chunks[i][1] = text:sub(0, maxlen - curlen - 1) .. '…'
    end
    curlen = curlen + #text
  end

  return chunks
end

local function titlecase(first, rest)
  return first:upper() .. rest:lower()
end

--- @param d vim.Diagnostic
--- @return [string, string?][]
local function default_format(d)
  local sev = vim.diagnostic.severity[d.severity]
  local severity_name = sev:gsub('^(.)(%a*)', titlecase)
  local src = d.source or 'unknown'
  return {
    { severity_name, string.format('Diagnostic%s', severity_name) },
    { ': ' },
    { d.message:match('^(.-)\n') or d.message },
    { string.format(' (%s)', src), 'LineNr' },
  }
end

--- @class M.Config
--- @field format fun(vim.Diagnostic): string|([string, integer|string?][])
--- @field severity vim.diagnostic.SeverityFilter?
--- @field severity_sort boolean
--- @field trim boolean
local default_config = {
  format = default_format,
  severity = nil,
  severity_sort = false,
  trim = true,
}

--- Get config value. It first checks the chime-specific config, then the
--- global config (vim.diagnostic.config()) and then the default value.
--- @param key string The config field.
local function config(key)
  local global = assert(vim.diagnostic.config())
  local chime = global['chime']
  -- convert 'true' to empty table to be indexable
  if type(chime) ~= 'table' then
    chime = {}
  end
  return vim.F.if_nil(chime[key], global[key], default_config[key])
end

--- Echo message. Without chunks, clear the msg area.
--- @param chunks [string, integer|string?][]
function M.echo(chunks)
  vim.api.nvim_echo({ { ' ' } }, false, { kind = 'empty', id = 'chime.msg' })
  if #chunks > 0 then
    vim.api.nvim_echo(chunks, false, { id = 'chime.msg' })
  end
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

function M.show(buf)
  buf = buf or 0
  local diagnostics = vim.diagnostic.get(buf, {
    lnum = vim.fn.line('.') - 1,
    severity = config('severity')
  })

  if config('severity_sort') then
    severity_sort(diagnostics)
  end

  -- prevent "Press Enter" prompt on old message grid system
  if not has_ui2() then
    diagnostics = vim.list_slice(diagnostics, 1, 1)
  end

  local formatfunc = config('format')
  local chunks = {}
  for i, d in ipairs(diagnostics) do
    -- each diagnostic should go on its own line
    if has_ui2() and i > 1 then
      chunks[#chunks + 1] = { '\n' }
    end
    local msg = formatfunc(d)
    if type(msg) == 'string' then
      msg = { { msg } }
    end
    vim.list_extend(chunks, msg)
  end

  if not has_ui2() and config('trim') then
    chunks = trim_msg(chunks)
  end

  M.echo(chunks)
end

function M.register(_, buf, _, _)
  if config('chime') == false or is_registered then
    return
  end

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertLeave' }, {
    group = augroup,
    buffer = buf,
    callback = function(ev)
      -- self-destruct if explicitly set to false (and not just `nil`)
      if config('chime') == false then
        M.echo({})
        vim.api.nvim_clear_autocmds({ group = augroup })
        is_registered = false
        return true
      end
      M.show(ev.buf)
    end,
  })

  is_registered = true
end

return M
