-- tmux.nvim - Neovim tmux integration
-- Provides window/session/pane management and visual alerts
local M = {}

-- Sub-modules (lazy-loaded)
M.utils = require('tmux.utils')
M.window = require('tmux.window')
M.session = require('tmux.session')
M.pane = require('tmux.pane')
M.alerts = require('tmux.alerts')
M.picker = require('tmux.picker')

-- Default configuration
M.config = {
  -- Enable visual window alerts
  alerts = {
    enabled = true,
    -- Colors (Catppuccin Mocha defaults)
    colors = {
      error = '#f38ba8',
      warning = '#fab387',
      success = '#a6e3a1',
      info = '#f9e2af',
      bg = '#45475a',
    },
  },
  -- Clear alerts on FocusGained
  clear_on_focus = true,
  -- Default keymaps (set to false to disable)
  keymaps = false,
}

--- Check if running inside tmux
---@return boolean
function M.is_tmux()
  return M.utils.is_tmux()
end

--- Ensure we're in tmux, show error if not
---@return boolean
function M.check_tmux()
  if not M.is_tmux() then
    vim.notify('Not running inside tmux', vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Quick access: goto or create named window
---@param name string Window name
---@param opts table|nil Options { cwd: string }
function M.goto(name, opts)
  if not M.check_tmux() then
    return
  end
  M.window.goto_or_create(name, opts)
end

--- Send command to a window
---@param window_name string|nil Window name (nil = current)
---@param command string Command to send
---@param submit boolean|nil Auto-submit (default true)
function M.send(window_name, command, submit)
  if not M.check_tmux() then
    return
  end
  window_name = window_name or M.utils.current_window()
  M.window.send_keys(window_name, command, submit)
end

--- Setup default keymaps
---@param prefix string Key prefix (default '<leader>t')
local function setup_keymaps(prefix)
  prefix = prefix or '<leader>t'

  -- Window picker
  vim.keymap.set('n', prefix .. 'p', function()
    M.picker.windows()
  end, { desc = '[T]mux [P]icker' })

  -- Session picker
  vim.keymap.set('n', prefix .. 's', function()
    M.picker.sessions()
  end, { desc = '[T]mux [S]essions' })

  -- New window
  vim.keymap.set('n', prefix .. 'n', function()
    vim.ui.input({ prompt = 'Window name: ' }, function(name)
      if name and name ~= '' then
        M.window.create(name)
        M.window.goto(name)
      end
    end)
  end, { desc = '[T]mux [N]ew window' })

  -- Rename window
  vim.keymap.set('n', prefix .. 'r', function()
    local current = M.utils.current_window_name()
    vim.ui.input({ prompt = 'New name: ', default = current }, function(name)
      if name and name ~= '' then
        M.window.rename(name)
      end
    end)
  end, { desc = '[T]mux [R]ename window' })

  -- Delete window
  vim.keymap.set('n', prefix .. 'x', function()
    local current = M.utils.current_window()
    M.window.delete(current)
  end, { desc = '[T]mux window [X] delete' })

  -- Window navigation
  vim.keymap.set('n', prefix .. 'l', M.window.next, { desc = '[T]mux window next' })
  vim.keymap.set('n', prefix .. 'h', M.window.previous, { desc = '[T]mux window previous' })
  vim.keymap.set('n', prefix .. 'L', M.window.last, { desc = '[T]mux [L]ast window' })

  -- Pane management
  vim.keymap.set('n', prefix .. 'm', M.pane.toggle_zoom, { desc = '[T]mux pane [M]aximize toggle' })
  vim.keymap.set('n', prefix .. '|', M.pane.split_vertical, { desc = '[T]mux split vertical' })
  vim.keymap.set('n', prefix .. '-', M.pane.split_horizontal, { desc = '[T]mux split horizontal' })

  -- Send visual selection
  vim.keymap.set('v', prefix .. 'S', function()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.fn.getline(start_pos[2], end_pos[2])
    local command = table.concat(lines, '\n')
    M.send(nil, command, true)
  end, { desc = '[T]mux [S]end selection' })
end

--- Setup tmux.nvim
---@param opts table|nil Configuration options
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)

  -- Skip setup if not in tmux
  if not M.is_tmux() then
    return
  end

  -- Configure alert colors
  if M.config.alerts.enabled and M.config.alerts.colors then
    M.alerts.colors = vim.tbl_deep_extend('force', M.alerts.colors, M.config.alerts.colors)
  end

  -- Setup alerts (tmux hooks for auto-clear)
  if M.config.alerts.enabled then
    M.alerts.setup()
  end

  -- Clear alerts on FocusGained
  if M.config.clear_on_focus then
    vim.api.nvim_create_autocmd('FocusGained', {
      group = vim.api.nvim_create_augroup('TmuxAlerts', { clear = true }),
      callback = function()
        M.alerts.clear()
      end,
    })
  end

  -- Setup keymaps if enabled
  if M.config.keymaps then
    local prefix = type(M.config.keymaps) == 'string' and M.config.keymaps or '<leader>t'
    setup_keymaps(prefix)
  end
end

return M
