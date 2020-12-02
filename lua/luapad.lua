local Config = require'luapad/config'
local Evaluator = require'luapad/evaluator'
local Statusline = require 'luapad/statusline'
local path = require 'luapad/tools'.path
local create_file = require 'luapad/tools'.create_file
local remove_file = require 'luapad/tools'.remove_file

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
  if Evaluator.current_win and vim.api.nvim_win_is_valid(Evaluator.current_win) then
    vim.api.nvim_set_current_win(Evaluator.current_win)
    return
  end

  Evaluator.start_buf = vim.api.nvim_get_current_buf()

  GCounter = GCounter + 1
  local file_path = path('tmp', 'Luapad_' .. GCounter .. '.lua')

  -- hacky solution to deal with native lsp
  create_file(file_path)
  vim.api.nvim_command('botright vsplit ' .. file_path)
  remove_file(file_path)

  Evaluator.current_win = vim.api.nvim_get_current_win()
  Evaluator.current_buf = vim.api.nvim_get_current_buf()
  Statusline.current_buf = vim.api.nvim_get_current_buf()

  -- vim.api.nvim_buf_set_name(0, 'Luapad #' .. vim.api.nvim_get_current_buf())
  vim.api.nvim_buf_set_option(0, 'swapfile', false)
  vim.api.nvim_buf_set_option(0, 'filetype', 'lua')
  vim.api.nvim_buf_set_option(0, 'bufhidden', 'wipe')

  vim.api.nvim_command('augroup LuapadAutogroup')
  vim.api.nvim_command('autocmd!')
  vim.api.nvim_command('au CursorHold <buffer> lua require("luapad").on_cursor_hold()')
  vim.api.nvim_command('au CursorMoved <buffer> lua require("luapad").on_luapad_cursor_moved()')
  vim.api.nvim_command('au CursorMovedI <buffer> lua require("luapad").on_luapad_cursor_moved()')
  vim.api.nvim_command('au CursorMoved * lua require("luapad").on_cursor_moved()')
  vim.api.nvim_command('au QuitPre <buffer> set nomodified')
  vim.api.nvim_command('augroup END')

  vim.api.nvim_buf_attach(0, false, {
    on_lines = on_change,
    on_changedtick = on_change,
    on_detach = on_detach
  })

  if Config.on_init then Config.on_init() end
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
