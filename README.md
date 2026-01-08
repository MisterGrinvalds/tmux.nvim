# tmux.nvim

Neovim plugin for tmux integration. Provides window, session, and pane management with visual alerts and telescope pickers.

## Features

- **Window Management** - Create, rename, delete, navigate windows
- **Session Management** - List, switch, create, kill sessions
- **Pane Operations** - Split, zoom, resize, capture pane content
- **Visual Alerts** - Color-coded window status based on state
- **Telescope Pickers** - Fuzzy find windows and sessions with preview
- **`:Tmux` Command** - Full CLI with tab completion

## Installation

### lazy.nvim

```lua
{
  'yourusername/tmux.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim', -- optional, for pickers
  },
  config = function()
    require('tmux').setup()
  end
}
```

### packer.nvim

```lua
use {
  'yourusername/tmux.nvim',
  requires = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require('tmux').setup()
  end
}
```

## Configuration

```lua
require('tmux').setup({
  -- Visual window alerts
  alerts = {
    enabled = true,
    colors = {
      error = '#f38ba8',    -- red
      warning = '#fab387',  -- orange
      success = '#a6e3a1',  -- green
      info = '#f9e2af',     -- yellow
      bg = '#45475a',       -- background
    },
  },
  -- Clear alerts when Neovim gains focus
  clear_on_focus = true,
  -- Enable default keymaps (false to disable, or string for prefix)
  keymaps = '<leader>t',
})
```

## Commands

```vim
:Tmux windows          " Open window picker
:Tmux sessions         " Open session picker
:Tmux goto <name>      " Switch to window by name
:Tmux new <name>       " Create new window
:Tmux rename <name>    " Rename current window
:Tmux delete           " Delete current window
:Tmux next             " Next window
:Tmux prev             " Previous window
:Tmux last             " Last used window
:Tmux zoom             " Toggle pane zoom
:Tmux split h|v        " Split pane horizontal/vertical
:Tmux alert <level>    " Set alert (success/warning/error/info)
:Tmux clear            " Clear alert
```

## Default Keymaps

When `keymaps = '<leader>t'` (or any prefix):

| Key | Action |
|-----|--------|
| `<leader>tp` | Window picker |
| `<leader>ts` | Session picker |
| `<leader>tn` | New window |
| `<leader>tr` | Rename window |
| `<leader>tx` | Delete window |
| `<leader>th` | Previous window |
| `<leader>tl` | Next window |
| `<leader>tL` | Last window |
| `<leader>tm` | Toggle pane zoom |
| `<leader>t\|` | Split vertical |
| `<leader>t-` | Split horizontal |
| `<leader>tS` | Send selection (visual) |

## Lua API

```lua
local tmux = require('tmux')

-- Check if in tmux
tmux.is_tmux()

-- Window operations
tmux.window.create('name', { cwd = '/path' })
tmux.window.goto('name')
tmux.window.goto_or_create('name')
tmux.window.delete('name')
tmux.window.rename('new-name')
tmux.window.list()
tmux.window.send_keys('name', 'echo hello', true)
tmux.window.next()
tmux.window.previous()
tmux.window.last()

-- Session operations
tmux.session.current()
tmux.session.list()
tmux.session.create('name', { cwd = '/path' })
tmux.session.switch('name')
tmux.session.kill('name')
tmux.session.rename('new-name')

-- Pane operations
tmux.pane.split_horizontal()
tmux.pane.split_vertical()
tmux.pane.toggle_zoom()
tmux.pane.resize('U', 5)  -- U/D/L/R
tmux.pane.capture({ start = -50 })

-- Alerts
tmux.alerts.success()
tmux.alerts.warning()
tmux.alerts.error()
tmux.alerts.info()
tmux.alerts.clear()
tmux.alerts.on_state('processing')  -- idle/processing/waiting/done/error

-- Pickers
tmux.picker.windows()
tmux.picker.sessions()

-- Quick helpers
tmux.goto('name')  -- goto_or_create
tmux.send('window', 'command', true)
```

## Picker Keymaps

In telescope picker:

| Key | Action |
|-----|--------|
| `<CR>` | Select (goto window/switch session) |
| `<C-x>` | Delete window/kill session |
| `<C-r>` | Rename window |
| `<C-n>` | Create new window/session |

## Integration with claude-code.nvim

This plugin can be used with [claude-code.nvim](https://github.com/yourusername/claude-code.nvim) for visual feedback:

```lua
-- In claude-code.nvim state change handler
local tmux = require('tmux')
tmux.alerts.on_state(state)  -- 'processing', 'waiting', 'done', 'error', 'idle'
```

## License

MIT
