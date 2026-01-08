-- Window status alerts for tmux
-- Visual feedback by changing window status colors
local M = {}
local utils = require('tmux.utils')

-- Default colors (Catppuccin Mocha)
M.colors = {
  error = '#f38ba8', -- red - errors/failures
  warning = '#fab387', -- orange/peach - needs attention
  success = '#a6e3a1', -- green - success/complete
  info = '#f9e2af', -- yellow - processing/working
  bg = '#45475a', -- surface1 - background
}

-- Cache for original window formats
M._original_format = nil
M._original_current_format = nil
M._current_window_id = nil

--- Check if format contains our alert colors
---@param format string|nil Format string to check
---@return boolean
local function is_our_format(format)
  if not format then
    return false
  end
  for _, color in pairs(M.colors) do
    if format:match(color:gsub('#', '#')) then
      return true
    end
  end
  return false
end

--- Strip tmux style codes from format string
---@param format string Format string with #[...] codes
---@return string Plain format without style codes
local function strip_style_codes(format)
  return format:gsub('#%[[^%]]*%]', '')
end

--- Save the original window formats for later restoration
---@param window_id string
local function save_original_format(window_id)
  if M._original_format and M._current_window_id == window_id and not is_our_format(M._original_format) then
    return
  end

  M._original_format = utils.get_global_option('window-status-format') or '#I:#W#F'
  M._original_current_format = utils.get_global_option('window-status-current-format') or '#I:#W#F'
  M._current_window_id = window_id
end

--- Set tmux window alert with color
---@param color string|nil Hex color (default: success green)
function M.alert(color)
  if not utils.is_tmux() then
    return
  end

  color = color or M.colors.success
  local window_id = utils.get_window_id()
  if not window_id then
    return
  end

  save_original_format(window_id)

  -- Set alert flag and store original formats
  utils.exec_silent(string.format("tmux set-window-option -t %s @alert 1 2>/dev/null", window_id))
  utils.exec_silent(string.format("tmux set-window-option -t %s @original_format '%s' 2>/dev/null", window_id, M._original_format))
  utils.exec_silent(string.format("tmux set-window-option -t %s @original_current_format '%s' 2>/dev/null", window_id, M._original_current_format))

  -- Apply colored format
  local plain_format = strip_style_codes(M._original_format)
  local plain_current_format = strip_style_codes(M._original_current_format)
  local colored_format = string.format('#[fg=%s,bold,bg=%s]%s#[default]', color, M.colors.bg, plain_format)
  local colored_current_format = string.format('#[fg=%s,bold,bg=%s]%s#[default]', color, M.colors.bg, plain_current_format)

  utils.exec_silent(string.format("tmux set-window-option -t %s window-status-format '%s' 2>/dev/null", window_id, colored_format))
  utils.exec_silent(string.format("tmux set-window-option -t %s window-status-current-format '%s' 2>/dev/null", window_id, colored_current_format))
end

--- Clear tmux window alert, restore original format
function M.clear()
  if not utils.is_tmux() then
    return
  end

  local window_id = utils.get_window_id()
  if not window_id then
    return
  end

  -- Clear alert flag
  utils.exec_silent(string.format("tmux set-window-option -t %s @alert 0 2>/dev/null", window_id))

  -- Unset window-specific format overrides
  utils.exec_silent(string.format("tmux set-window-option -t %s -u window-status-format 2>/dev/null", window_id))
  utils.exec_silent(string.format("tmux set-window-option -t %s -u window-status-current-format 2>/dev/null", window_id))
  utils.exec_silent(string.format("tmux set-window-option -t %s -u @original_format 2>/dev/null", window_id))
  utils.exec_silent(string.format("tmux set-window-option -t %s -u @original_current_format 2>/dev/null", window_id))

  -- Reset cache
  M._original_format = nil
  M._original_current_format = nil
  M._current_window_id = nil
end

--- Alert: success (green)
function M.success()
  M.alert(M.colors.success)
end

--- Alert: warning/attention needed (orange)
function M.warning()
  M.alert(M.colors.warning)
end

--- Alert: error/failure (red)
function M.error()
  M.alert(M.colors.error)
end

--- Alert: info/processing (yellow)
function M.info()
  M.alert(M.colors.info)
end

--- Trigger alert based on state string
---@param state string 'idle'|'processing'|'waiting'|'done'|'error'
function M.on_state(state)
  if state == 'done' or state == 'success' then
    M.success()
  elseif state == 'waiting' or state == 'warning' then
    M.warning()
  elseif state == 'processing' or state == 'info' then
    M.info()
  elseif state == 'error' then
    M.error()
  elseif state == 'idle' or state == 'clear' then
    M.clear()
  end
end

--- Setup alerts with hooks to auto-clear on window switch
function M.setup()
  if not utils.is_tmux() then
    return
  end

  -- Enable focus-events for FocusGained autocmd
  utils.exec_silent('tmux set-option -g focus-events on 2>/dev/null')

  -- Register hooks to clear alerts when switching windows
  local clear_cmd = 'if-shell -F "#{@alert}" "set-window-option @alert 0 ; set-window-option -u window-status-format ; set-window-option -u window-status-current-format ; set-window-option -u @original_format ; set-window-option -u @original_current_format"'
  utils.exec_silent(string.format("tmux set-hook -g after-select-window '%s' 2>/dev/null", clear_cmd))
  utils.exec_silent(string.format("tmux set-hook -g session-window-changed '%s' 2>/dev/null", clear_cmd))
end

return M
