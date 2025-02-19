# Chime

Chime is a very little plugin that does a one straightforward thing: it shows
the diagnostic of the current line in the echo / message area.

![Example of Chime](screenshot.png)

## Installation

To install, use your favorite plugin manager. For example with lazy.nvim:

```lua
{ 'yochem/chime.nvim' }
```

For lazy-loading you could try `event = 'DiagnosticsChanged'`, although the
plugin should be very light.

## Configuration

This plugin aims to do everything _the Neovim way_. Because it handles
diagnostics, it's an [`:h
diagnostic-handler`](https://neovim.io/doc/user/diagnostic.html#_handlers).
This means configuration is handled using `vim.diagnostic.config()`, **not**
`setup()`. It also listens to global configuration options for diagnostic
handlers, and you can enable it only for certain namespaces. See [`:h
vim.diagnostic.config()`](https://neovim.io/doc/user/diagnostic.html#vim.diagnostic.config())
for more info.

```lua
vim.diagnostic.config({
  chime = {
    severity_sort = false,
    severity = nil,
    format = ...,
  }
})
```

Chime can be enabled or disabled on the fly:

```vim
" disable Chime
:lua vim.diagnostic.config({ chime = false })
" and enable again
:lua vim.diagnostic.config({ chime = true })
```

## Format

Set the format of the diagnostic message with the `format` config option. It
should be a function that receives a diagnostic and outputs either a string or
a list of colored chunks (like the first argument of `vim.api.nvim_echo()`).

An example that returns the formatted string `[INFO] Unused functions. (luals)`:

```lua
vim.diagnostic.config({
  chime = {
    format = function(diagnostic)
      return ('[%s] %s (%s)'):format(
        -- this assumes the default sign text
        vim.diagnostic.severity[diagnostic.severity],
        diagnostic.message,
        diagnostic.source,
      )
    end
  }
})
```

And the same diagnostic but with the sign text highlighted in its color and the
source in gray:

```lua
vim.diagnostic.config({
  chime = {
    format = function(diagnostic)
      local severity_text = vim.diagnostic.severity[diagnostic.severity]
      local severity_color = ({
          'DiagnosticError',
          'DiagnosticWarn',
          'DiagnosticInfo',
          'DiagnosticHint',
      })[diagnostic.severity]

      return {
        { ('[%s] '):format(severity_text), severity_color },
        { diagnostic.message },
        { (' (%s)'):format(diagnostic.source), "Comment" },
      }
    end
  }
})
```

## Severity

Filter on severities, for example only show errors in Chime. See `:h
diagnostic-severity`.

## Severity Sort

Sort by severity. It is recommended to set this to true. See `:h
vim.diagnostic.Opts`.
