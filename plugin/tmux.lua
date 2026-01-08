-- tmux.nvim plugin loader
if vim.g.loaded_tmux_nvim then
  return
end
vim.g.loaded_tmux_nvim = true

-- Create :Tmux command with subcommands
vim.api.nvim_create_user_command('Tmux', function(opts)
  local tmux = require('tmux')
  local args = vim.split(opts.args, '%s+', { trimempty = true })
  local cmd = args[1] or 'windows'

  if cmd == 'windows' or cmd == 'w' then
    tmux.picker.windows()
  elseif cmd == 'sessions' or cmd == 's' then
    tmux.picker.sessions()
  elseif cmd == 'goto' or cmd == 'g' then
    local name = args[2]
    if name then
      tmux.goto(name)
    else
      vim.notify('Usage: :Tmux goto <window_name>', vim.log.levels.WARN)
    end
  elseif cmd == 'new' or cmd == 'n' then
    local name = args[2]
    if name then
      tmux.window.create(name)
      tmux.window.goto(name)
    else
      vim.ui.input({ prompt = 'Window name: ' }, function(input)
        if input and input ~= '' then
          tmux.window.create(input)
          tmux.window.goto(input)
        end
      end)
    end
  elseif cmd == 'rename' or cmd == 'r' then
    local name = args[2]
    if name then
      tmux.window.rename(name)
    else
      local current = tmux.utils.current_window_name()
      vim.ui.input({ prompt = 'New name: ', default = current }, function(input)
        if input and input ~= '' then
          tmux.window.rename(input)
        end
      end)
    end
  elseif cmd == 'delete' or cmd == 'd' or cmd == 'kill' then
    local target = args[2] or tmux.utils.current_window()
    tmux.window.delete(target)
  elseif cmd == 'next' then
    tmux.window.next()
  elseif cmd == 'prev' or cmd == 'previous' then
    tmux.window.previous()
  elseif cmd == 'last' then
    tmux.window.last()
  elseif cmd == 'zoom' or cmd == 'z' then
    tmux.pane.toggle_zoom()
  elseif cmd == 'split' then
    local direction = args[2] or 'h'
    if direction == 'h' or direction == 'horizontal' then
      tmux.pane.split_horizontal()
    else
      tmux.pane.split_vertical()
    end
  elseif cmd == 'alert' then
    local level = args[2] or 'info'
    tmux.alerts.on_state(level)
  elseif cmd == 'clear' then
    tmux.alerts.clear()
  else
    vim.notify('Unknown command: ' .. cmd .. '\nAvailable: windows, sessions, goto, new, rename, delete, next, prev, last, zoom, split, alert, clear', vim.log.levels.WARN)
  end
end, {
  nargs = '*',
  complete = function(_, line)
    local args = vim.split(line, '%s+', { trimempty = true })
    local commands = { 'windows', 'sessions', 'goto', 'new', 'rename', 'delete', 'next', 'prev', 'last', 'zoom', 'split', 'alert', 'clear' }

    if #args <= 2 then
      return vim.tbl_filter(function(c)
        return c:find(args[2] or '', 1, true) == 1
      end, commands)
    end

    if args[2] == 'alert' then
      local levels = { 'success', 'warning', 'error', 'info', 'clear' }
      return vim.tbl_filter(function(l)
        return l:find(args[3] or '', 1, true) == 1
      end, levels)
    end

    if args[2] == 'split' then
      local directions = { 'horizontal', 'vertical' }
      return vim.tbl_filter(function(d)
        return d:find(args[3] or '', 1, true) == 1
      end, directions)
    end

    if args[2] == 'goto' or args[2] == 'delete' then
      local tmux = require('tmux')
      local windows = tmux.window.list()
      local names = vim.tbl_map(function(w)
        return w.name
      end, windows)
      return vim.tbl_filter(function(n)
        return n:find(args[3] or '', 1, true) == 1
      end, names)
    end

    return {}
  end,
  desc = 'Tmux integration commands',
})
