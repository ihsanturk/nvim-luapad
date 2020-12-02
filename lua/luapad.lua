local Config = require'luapad/config'
local Evaluator = require'luapad/evaluator'
local Statusline = require 'luapad/statusline'
local State = require 'luapad/state'
local path = require 'luapad/tools'.path
local create_file = require 'luapad/tools'.create_file
local remove_file = require 'luapad/tools'.remove_file

local luapad_current_win
local GCounter = 0

local preview = Evaluator.preview
local close_preview = Evaluator.close_preview
local eval = vim.schedule_wrap(Evaluator.eval)

local function on_cursor_hold()
  if Config.preview then preview() end
end

local function on_cursor_moved()
  if Config.eval_on_move then eval() end
end

local function on_luapad_cursor_moved()
  close_preview()
end

local function on_change()
  if Config.eval_on_change then eval() end
end

local function on_detach()
  close_preview()
end

local function init()
  if luapad_current_win and vim.api.nvim_win_is_valid(luapad_current_win) then
    vim.api.nvim_set_current_win(luapad_current_win)
    return
  end

  local start_buf = vim.api.nvim_get_current_buf()

  GCounter = GCounter + 1
  local file_path = path('tmp', 'Luapad_' .. GCounter .. '.lua')

  -- hacky solution to deal with native lsp
  create_file(file_path)
  vim.api.nvim_command('botright vsplit ' .. file_path)
  remove_file(file_path)

  local buf = vim.api.nvim_get_current_buf()

  State.instances[buf] = Evaluator:new{buf = buf}
  State.instances[buf]:start()

  Statusline.current_buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'lua')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  vim.api.nvim_command('augroup LuapadAutogroup')
  vim.api.nvim_command('autocmd!')
  vim.api.nvim_command('au CursorMoved * lua require("luapad/cmds").on_cursor_moved()')
  vim.api.nvim_command('augroup END')
  vim.api.nvim_command('au QuitPre <buffer> set nomodified')
end

return {
  init = init,
  eval = eval,
  config = Config.config,
  on_cursor_moved = on_cursor_moved,
  on_luapad_cursor_moved = on_luapad_cursor_moved,
  on_change = on_change,
  on_detach = on_detach,
  on_cursor_hold = on_cursor_hold
}
