-- Utility functions for tmux command execution
local M = {}

--- Check if running inside tmux
---@return boolean
function M.is_tmux()
  return vim.env.TMUX ~= nil
end

--- Execute tmux command and return output
---@param args table List of command arguments (will be shell-escaped)
---@return string|nil result Command output
---@return string|nil error Error message if failed
function M.exec(args)
  local escaped_args = {}
  for _, arg in ipairs(args) do
    if arg:match('[%s#{}$]') then
      table.insert(escaped_args, "'" .. arg:gsub("'", "'\\''") .. "'")
    else
      table.insert(escaped_args, arg)
    end
  end

  local cmd = 'tmux ' .. table.concat(escaped_args, ' ')
  local handle = io.popen(cmd .. ' 2>&1')
  if not handle then
    return nil, 'Failed to execute tmux command'
  end

  local result = handle:read('*a')
  local success = handle:close()

  if not success then
    return nil, result
  end

  return result:gsub('%s+$', ''), nil
end

--- Execute tmux command silently (no return value needed)
---@param args table|string Command arguments or full command string
function M.exec_silent(args)
  if type(args) == 'string' then
    vim.fn.system(args)
  else
    local escaped_args = {}
    for _, arg in ipairs(args) do
      if arg:match('[%s#{}$]') then
        table.insert(escaped_args, "'" .. arg:gsub("'", "'\\''") .. "'")
      else
        table.insert(escaped_args, arg)
      end
    end
    vim.fn.system('tmux ' .. table.concat(escaped_args, ' ') .. ' 2>/dev/null')
  end
end

--- Check if a window exists by name
---@param name string Window name
---@return boolean
function M.window_exists(name)
  local result = M.exec({ 'list-windows', '-F', '#{window_name}' })
  if not result then
    return false
  end

  for window in result:gmatch('[^\n]+') do
    if window == name then
      return true
    end
  end
  return false
end

--- Get current window index
---@return string|nil
function M.current_window()
  local result = M.exec({ 'display-message', '-p', '#{window_index}' })
  return result
end

--- Get current window name
---@return string|nil
function M.current_window_name()
  local result = M.exec({ 'display-message', '-p', '#{window_name}' })
  return result
end

--- Get tmux window ID for the pane containing this Neovim instance
---@return string|nil
function M.get_window_id()
  if not M.is_tmux() then
    return nil
  end

  local pane_id = os.getenv('TMUX_PANE')
  local cmd
  if pane_id then
    cmd = string.format("tmux display-message -p -t %s '#{window_id}' 2>/dev/null", pane_id)
  else
    cmd = "tmux display-message -p '#{window_id}' 2>/dev/null"
  end

  local handle = io.popen(cmd)
  if not handle then
    return nil
  end
  local result = handle:read('*a')
  handle:close()
  return result and result:gsub('%s+', '') or nil
end

--- Format tmux target (window name or index)
---@param name_or_index string|number
---@return string Formatted target
function M.format_target(name_or_index)
  if tonumber(name_or_index) then
    return ':' .. name_or_index
  else
    return '=' .. vim.fn.shellescape(name_or_index)
  end
end

--- Get tmux option value (checks window -> session -> global)
---@param window_id string|nil Window ID (nil for current)
---@param option string Option name
---@return string|nil
function M.get_option(window_id, option)
  local sources = {}

  if window_id then
    table.insert(sources, string.format("tmux show-window-options -t %s -v %s 2>/dev/null", window_id, option))
  end
  table.insert(sources, string.format("tmux show-options -wv %s 2>/dev/null", option))
  table.insert(sources, string.format("tmux show-options -gv %s 2>/dev/null", option))

  for _, cmd in ipairs(sources) do
    local handle = io.popen(cmd)
    if handle then
      local result = handle:read('*a')
      handle:close()
      if result and result:gsub('%s+', '') ~= '' then
        return result:gsub('%s+$', '')
      end
    end
  end

  return nil
end

--- Get global tmux option
---@param option string Option name
---@return string|nil
function M.get_global_option(option)
  local cmd = string.format("tmux show-options -gv %s 2>/dev/null", option)
  local handle = io.popen(cmd)
  if handle then
    local result = handle:read('*a')
    handle:close()
    if result and result:gsub('%s+', '') ~= '' then
      return result:gsub('%s+$', '')
    end
  end
  return nil
end

return M
