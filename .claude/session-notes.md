# tmux.nvim - Session Notes

## Session: 2026-01-08

### What We Did

#### 1. Created tmux.nvim Plugin Structure

Reviewed existing .nvim plugins in the repo to understand patterns:
- `claude-code.nvim` - had tmux alerts code (236 lines)
- `greenforests.nvim` - had custom/tmux module (window, session, picker, utils)
- `command-palette.nvim` - had tmux provider

Consolidated all tmux functionality into standalone plugin.

#### 2. Implemented Core Modules

| Module | Lines | Purpose |
|--------|-------|---------|
| `utils.lua` | 155 | Command execution, tmux detection, option getters |
| `window.lua` | 152 | Create, goto, delete, rename, list, send_keys, next/prev |
| `session.lua` | 115 | List, create, switch, kill, rename sessions |
| `pane.lua` | 175 | Split, zoom, resize, capture, select, swap |
| `alerts.lua` | 148 | Visual window status with color-coded states |
| `picker.lua` | 235 | Telescope pickers for windows and sessions |
| `init.lua` | 168 | Main module with setup(), config, public API |
| `plugin/tmux.lua` | 97 | `:Tmux` command with subcommand completion |

**Total: 1,245 lines of Lua**

#### 3. Features Implemented

- **Window management**: create, goto, goto_or_create, delete, rename, list, send_keys, next, previous, last
- **Session management**: current, list, exists, create, switch, kill, rename
- **Pane management**: split_horizontal, split_vertical, toggle_zoom, kill, select, swap, resize, send_keys, capture
- **Visual alerts**: success (green), warning (orange), error (red), info (yellow), clear, on_state()
- **Telescope pickers**: windows picker with pane preview, sessions picker, keymaps for CRUD
- **:Tmux command**: 13 subcommands with tab completion

---

### Architecture

```
tmux.nvim/
├── lua/tmux/
│   ├── init.lua      # Main entry, setup(), exports
│   ├── utils.lua     # Low-level tmux command execution
│   ├── window.lua    # Window operations
│   ├── session.lua   # Session operations
│   ├── pane.lua      # Pane operations
│   ├── alerts.lua    # Visual window status alerts
│   └── picker.lua    # Telescope integration
├── plugin/
│   └── tmux.lua      # :Tmux command loader
└── README.md
```

---

### Commits

1. `da9c741` - feat: initial tmux.nvim structure with core modules
   - utils.lua, window.lua, session.lua

2. `79e8735` - feat: add pane, alerts, picker modules and plugin loader
   - pane.lua, alerts.lua, picker.lua, init.lua, plugin/tmux.lua

---

### Next Steps / TODOs

- [ ] Update `claude-code.nvim` to use `tmux.nvim` as dependency for alerts
  - Remove `lua/claude-code/tmux.lua`
  - Add `require('tmux').alerts.on_state(state)` calls

- [ ] Update `greenforests.nvim` to use `tmux.nvim` instead of `custom/tmux`
  - Remove `lua/custom/tmux/` directory
  - Update `lua/plugins/terminal.lua` to use tmux.nvim
  - Update keymaps to use new API

- [ ] Update `command-palette.nvim` tmux provider
  - Change `require('custom.tmux')` to `require('tmux')`

- [ ] Add health check (`lua/tmux/health.lua`)
  - Check if running in tmux
  - Check tmux version
  - Check telescope availability

- [ ] Add tests
  - Mock tmux commands for unit testing
  - Test picker functionality

- [ ] Publish to GitHub
  - Update README with actual username
  - Add LICENSE file
  - Add GitHub Actions for CI

---

### Integration Points

**claude-code.nvim:**
```lua
-- Before (in claude-code.nvim)
local tmux = require('claude-code.tmux')
tmux.on_state_change(state)

-- After (using tmux.nvim)
local tmux = require('tmux')
tmux.alerts.on_state(state)
```

**greenforests.nvim:**
```lua
-- Before
local tmux = require('custom.tmux')
tmux.window.goto_or_create('name')

-- After
local tmux = require('tmux')
tmux.window.goto_or_create('name')
```

---

### Testing Checklist

- [ ] Install plugin via lazy.nvim
- [ ] Verify `:Tmux` command works with completion
- [ ] Test window picker (`<leader>tp` or `:Tmux windows`)
- [ ] Test session picker (`:Tmux sessions`)
- [ ] Test window create/delete/rename
- [ ] Test pane split/zoom
- [ ] Test alerts (success/warning/error/info/clear)
- [ ] Test FocusGained auto-clear
- [ ] Verify works outside tmux (graceful no-op)
