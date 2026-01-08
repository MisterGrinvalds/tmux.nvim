-- Telescope pickers for tmux windows and sessions
local M = {}

--- Create a previewer that shows tmux pane content
---@return table Telescope previewer
local function pane_previewer()
  local ok, previewers = pcall(require, 'telescope.previewers')
  if not ok then
    return nil
  end

  local putils = require('telescope.previewers.utils')

  return previewers.new_buffer_previewer({
    title = 'Pane Content',
    define_preview = function(self, entry, _)
      local cmd = string.format('tmux capture-pane -t :%s -p -S -50', entry.value.index)
      local handle = io.popen(cmd)
      if not handle then
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { 'Failed to capture pane' })
        return
      end

      local content = handle:read('*a')
      handle:close()

      local lines = vim.split(content, '\n', { trimempty = false })
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      putils.highlighter(self.state.bufnr, 'bash')
    end,
  })
end

--- Show tmux window picker
---@param opts table|nil Telescope picker options
function M.windows(opts)
  opts = opts or {}

  local ok, _ = pcall(require, 'telescope')
  if not ok then
    vim.notify('telescope.nvim is required for tmux picker', vim.log.levels.ERROR)
    return
  end

  local utils = require('tmux.utils')
  local window = require('tmux.window')

  if not utils.is_tmux() then
    vim.notify('Not running inside tmux', vim.log.levels.ERROR)
    return
  end

  local windows = window.list()
  if #windows == 0 then
    vim.notify('No tmux windows found', vim.log.levels.WARN)
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local entry_display = require('telescope.pickers.entry_display')

  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = 3 },
      { width = 20 },
      { width = 8 },
    },
  })

  local make_display = function(entry)
    local status = entry.active and '' or ''
    return displayer({
      { tostring(entry.index), 'TelescopeResultsNumber' },
      { entry.name, 'TelescopeResultsIdentifier' },
      { status, entry.active and 'TelescopeResultsFunction' or 'TelescopeResultsComment' },
    })
  end

  pickers
    .new(opts, {
      prompt_title = ' tmux Windows',
      results_title = 'Windows',
      preview_title = 'Pane Content',
      finder = finders.new_table({
        results = windows,
        entry_maker = function(entry)
          return {
            value = entry,
            display = make_display,
            ordinal = entry.name .. ' ' .. entry.index,
            index = entry.index,
            name = entry.name,
            active = entry.active,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = pane_previewer(),
      layout_strategy = 'horizontal',
      layout_config = {
        horizontal = {
          preview_width = 0.6,
          width = 0.8,
          height = 0.8,
        },
      },
      attach_mappings = function(prompt_bufnr, map)
        -- Enter: goto window
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            window.goto(selection.value.index)
          end
        end)

        -- Ctrl-x: delete window
        map('i', '<C-x>', function()
          local selection = action_state.get_selected_entry()
          if selection and #windows > 1 then
            actions.close(prompt_bufnr)
            window.delete(selection.value.index)
          else
            vim.notify("Can't delete last window", vim.log.levels.WARN)
          end
        end)

        -- Ctrl-r: rename window
        map('i', '<C-r>', function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            vim.ui.input({ prompt = 'New name: ', default = selection.value.name }, function(name)
              if name and name ~= '' then
                window.goto(selection.value.index)
                window.rename(name)
              end
            end)
          end
        end)

        -- Ctrl-n: new window
        map('i', '<C-n>', function()
          actions.close(prompt_bufnr)
          vim.ui.input({ prompt = 'Window name: ' }, function(name)
            if name and name ~= '' then
              window.create(name)
              window.goto(name)
            end
          end)
        end)

        return true
      end,
    })
    :find()
end

--- Show tmux session picker
---@param opts table|nil Telescope picker options
function M.sessions(opts)
  opts = opts or {}

  local ok, _ = pcall(require, 'telescope')
  if not ok then
    vim.notify('telescope.nvim is required for tmux picker', vim.log.levels.ERROR)
    return
  end

  local utils = require('tmux.utils')
  local session = require('tmux.session')

  if not utils.is_tmux() then
    vim.notify('Not running inside tmux', vim.log.levels.ERROR)
    return
  end

  local sessions = session.list()
  if #sessions == 0 then
    vim.notify('No tmux sessions found', vim.log.levels.WARN)
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local entry_display = require('telescope.pickers.entry_display')

  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = 20 },
      { width = 10 },
      { width = 8 },
    },
  })

  local make_display = function(entry)
    local status = entry.attached and '' or ''
    local windows_str = entry.windows .. ' win'
    return displayer({
      { entry.name, 'TelescopeResultsIdentifier' },
      { windows_str, 'TelescopeResultsNumber' },
      { status, entry.attached and 'TelescopeResultsFunction' or 'TelescopeResultsComment' },
    })
  end

  pickers
    .new(opts, {
      prompt_title = ' tmux Sessions',
      results_title = 'Sessions',
      finder = finders.new_table({
        results = sessions,
        entry_maker = function(entry)
          return {
            value = entry,
            display = make_display,
            ordinal = entry.name,
            name = entry.name,
            attached = entry.attached,
            windows = entry.windows,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        -- Enter: switch to session
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            session.switch(selection.value.name)
          end
        end)

        -- Ctrl-x: kill session
        map('i', '<C-x>', function()
          local selection = action_state.get_selected_entry()
          if selection and #sessions > 1 then
            actions.close(prompt_bufnr)
            session.kill(selection.value.name)
          else
            vim.notify("Can't kill last session", vim.log.levels.WARN)
          end
        end)

        -- Ctrl-n: new session
        map('i', '<C-n>', function()
          actions.close(prompt_bufnr)
          vim.ui.input({ prompt = 'Session name: ' }, function(name)
            if name and name ~= '' then
              session.create(name)
              session.switch(name)
            end
          end)
        end)

        return true
      end,
    })
    :find()
end

return M
