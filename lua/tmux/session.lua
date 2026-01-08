-- Session management functions for tmux
local M = {}
local utils = require('tmux.utils')

--- Get current session name
---@return string|nil
function M.current()
  local result = utils.exec({ 'display-message', '-p', '#{session_name}' })
  return result
end

--- List all sessions
---@return table[] List of session objects { name, attached, windows }
function M.list()
  local result = utils.exec({ 'list-sessions', '-F', '#{session_name}:#{session_attached}:#{session_windows}' })
  if not result then
    return {}
  end

  local sessions = {}
  for line in result:gmatch('[^\n]+') do
    local name, attached, windows = line:match('([^:]+):([01]):(%d+)')
    if name then
      table.insert(sessions, {
        name = name,
        attached = attached == '1',
        windows = tonumber(windows) or 0,
      })
    end
  end

  return sessions
end

--- Check if session exists
---@param name string Session name
---@return boolean
function M.exists(name)
  local result = utils.exec({ 'has-session', '-t', vim.fn.shellescape(name) })
  return result ~= nil
end

--- Create new session
---@param name string Session name
---@param opts table|nil Options { cwd: string, detach: boolean }
---@return boolean success
function M.create(name, opts)
  opts = opts or {}
  local args = { 'new-session' }

  if opts.detach ~= false then
    table.insert(args, '-d')
  end

  table.insert(args, '-s')
  table.insert(args, vim.fn.shellescape(name))

  if opts.cwd then
    table.insert(args, '-c')
    table.insert(args, vim.fn.shellescape(opts.cwd))
  end

  local _, err = utils.exec(args)
  if err then
    vim.notify('Failed to create session: ' .. err, vim.log.levels.ERROR)
    return false
  end

  return true
end

--- Switch to session
---@param name string Session name
---@return boolean success
function M.switch(name)
  local _, err = utils.exec({ 'switch-client', '-t', vim.fn.shellescape(name) })
  if err then
    vim.notify('Failed to switch session: ' .. err, vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Kill/delete session
---@param name string Session name
---@param confirm boolean|nil Require confirmation (default true)
---@return boolean success
function M.kill(name, confirm)
  confirm = confirm == nil and true or confirm

  if confirm then
    local choice = vim.fn.confirm('Kill tmux session "' .. name .. '"?', '&Yes\n&No', 2)
    if choice ~= 1 then
      return false
    end
  end

  local _, err = utils.exec({ 'kill-session', '-t', vim.fn.shellescape(name) })
  if err then
    vim.notify('Failed to kill session: ' .. err, vim.log.levels.ERROR)
    return false
  end

  return true
end

--- Rename current session
---@param new_name string New session name
---@return boolean success
function M.rename(new_name)
  local _, err = utils.exec({ 'rename-session', vim.fn.shellescape(new_name) })
  if err then
    vim.notify('Failed to rename session: ' .. err, vim.log.levels.ERROR)
    return false
  end

  return true
end

return M
