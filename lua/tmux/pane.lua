-- Pane management functions for tmux
local M = {}
local utils = require('tmux.utils')

--- Get current pane ID
---@return string|nil
function M.current()
  local result = utils.exec({ 'display-message', '-p', '#{pane_id}' })
  return result
end

--- List all panes in current window
---@return table[] List of pane objects { id, index, active, width, height }
function M.list()
  local result = utils.exec({
    'list-panes',
    '-F',
    '#{pane_id}:#{pane_index}:#{pane_active}:#{pane_width}:#{pane_height}',
  })
  if not result then
    return {}
  end

  local panes = {}
  for line in result:gmatch('[^\n]+') do
    local id, index, active, width, height = line:match('([^:]+):(%d+):([01]):(%d+):(%d+)')
    if id then
      table.insert(panes, {
        id = id,
        index = tonumber(index),
        active = active == '1',
        width = tonumber(width),
        height = tonumber(height),
      })
    end
  end

  return panes
end

--- Split pane horizontally (top/bottom)
---@param opts table|nil Options { cwd: string, percent: number }
---@return boolean success
function M.split_horizontal(opts)
  opts = opts or {}
  local args = { 'split-window', '-v' }

  if opts.percent then
    table.insert(args, '-p')
    table.insert(args, tostring(opts.percent))
  end

  if opts.cwd then
    table.insert(args, '-c')
    table.insert(args, vim.fn.shellescape(opts.cwd))
  end

  local _, err = utils.exec(args)
  if err then
    vim.notify('Failed to split pane: ' .. err, vim.log.levels.ERROR)
    return false
  end

  return true
end

--- Split pane vertically (left/right)
---@param opts table|nil Options { cwd: string, percent: number }
---@return boolean success
function M.split_vertical(opts)
  opts = opts or {}
  local args = { 'split-window', '-h' }

  if opts.percent then
    table.insert(args, '-p')
    table.insert(args, tostring(opts.percent))
  end

  if opts.cwd then
    table.insert(args, '-c')
    table.insert(args, vim.fn.shellescape(opts.cwd))
  end

  local _, err = utils.exec(args)
  if err then
    vim.notify('Failed to split pane: ' .. err, vim.log.levels.ERROR)
    return false
  end

  return true
end

--- Toggle pane zoom (maximize/restore)
function M.toggle_zoom()
  utils.exec({ 'resize-pane', '-Z' })
end

--- Kill current pane
---@param confirm boolean|nil Require confirmation (default true)
---@return boolean success
function M.kill(confirm)
  confirm = confirm == nil and true or confirm

  if confirm then
    local choice = vim.fn.confirm('Kill current tmux pane?', '&Yes\n&No', 2)
    if choice ~= 1 then
      return false
    end
  end

  local _, err = utils.exec({ 'kill-pane' })
  if err then
    vim.notify('Failed to kill pane: ' .. err, vim.log.levels.ERROR)
    return false
  end

  return true
end

--- Select pane by direction
---@param direction string 'U'|'D'|'L'|'R' (up/down/left/right)
function M.select(direction)
  utils.exec({ 'select-pane', '-' .. direction })
end

--- Swap pane with another by direction
---@param direction string 'U'|'D'|'L'|'R' (up/down/left/right)
function M.swap(direction)
  utils.exec({ 'swap-pane', '-' .. direction })
end

--- Resize pane
---@param direction string 'U'|'D'|'L'|'R' (up/down/left/right)
---@param amount number|nil Amount to resize (default 5)
function M.resize(direction, amount)
  amount = amount or 5
  utils.exec({ 'resize-pane', '-' .. direction, tostring(amount) })
end

--- Send keys to current pane
---@param keys string Keys to send
---@param literal boolean|nil Send literally (default false)
function M.send_keys(keys, literal)
  local args = { 'send-keys' }
  if literal then
    table.insert(args, '-l')
  end
  table.insert(args, keys)
  utils.exec(args)
end

--- Capture pane content
---@param opts table|nil Options { start: number, end: number, escape: boolean }
---@return string|nil content
function M.capture(opts)
  opts = opts or {}
  local args = { 'capture-pane', '-p' }

  if opts.start then
    table.insert(args, '-S')
    table.insert(args, tostring(opts.start))
  end

  if opts['end'] then
    table.insert(args, '-E')
    table.insert(args, tostring(opts['end']))
  end

  if opts.escape then
    table.insert(args, '-e')
  end

  local result, err = utils.exec(args)
  if err then
    return nil
  end

  return result
end

return M
