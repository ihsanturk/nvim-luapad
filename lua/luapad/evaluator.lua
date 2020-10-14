local Statusline = require 'luapad/statusline'
local Config = require'luapad/config'
local helper = require'luapad/helper'

local parse_error = require'luapad/tools'.parse_error

local ns = vim.api.nvim_create_namespace('luapad_namespace')

local M = {
  start_buf = nil,
  current_buf = nil,
  preview_win = nil,
  output = {}
}

local function set_virtual_text(line, str, color)
  if not M.current_buf then return end
  if not vim.api.nvim_buf_is_valid(M.current_buf) then return end

  vim.api.nvim_buf_set_virtual_text(
    M.current_buf,
    ns,
    line,
    {{tostring(str), color}},
    {}
    )
end

local function tcall(fun)
  local count_limit = Config.count_limit < 1000 and 1000 or Config.count_limit

  success, result = pcall(function()
    debug.sethook(function() error('LuapadTimeoutError') end, "", count_limit)
    fun()
  end)

  if not success then
    if result:find('LuapadTimeoutError') then
      Statusline:set_status('timeout')
    else
      print(result)
      Statusline:set_status('error')
      local line, error_msg = parse_error(result)
      Statusline:set_msg(('%s: %s'):format((line or ''), (error_msg or '')))

      if Config.error_indicator and line then
        set_virtual_text(tonumber(line) - 1, '<-- '..error_msg, Config.error_highlight)
      end
    end
  end

  debug.sethook()
end

local function single_line(arr)
  local result = {}
  for _, v in ipairs(arr) do
    local str = v:gsub("\n", ''):gsub(' +', ' ')
    table.insert(result, str)
  end
  return table.concat(result, ', ')
end

function luapad_print(...)
  if not ... then return end
  local arg = {...}
  local str = {}

  for _,v in ipairs(arg) do
    table.insert(str, tostring(vim.inspect(v)))
  end

  local line = debug.traceback('', 2):match(':(%d*):')
  if not line then return end
  line = tonumber(line)

  if not M.output[line] then
    M.output[line] = {}
  end

  table.insert(M.output[line], str)
end

function M.eval()
  local context = Config.context or {}
  context.p = luapad_print;
  context.print = luapad_print;
  context.luapad = helper.new(M.start_buf)
  setmetatable(context, { __index = _G})

  Statusline:clear()

  vim.api.nvim_buf_clear_namespace(M.current_buf, ns, 0, -1)

  M.output = {}

  local code = vim.api.nvim_buf_get_lines(M.current_buf, 0, -1, {})
  local f, result = loadstring(table.concat(code, '\n'))

  if not f then
    local _, msg = parse_error(result)
    Statusline:set_status('syntax')
    Statusline:set_msg(msg)
    return
  end

  setfenv(f, context)
  tcall(f)

  for line, arr in pairs(M.output) do
    local res = {}

    for _, v in ipairs(arr) do
      table.insert(res, single_line(v))
    end

    set_virtual_text(line - 1, '  '..table.concat(res, ' | '), Config.print_highlight)
  end
end

function M.close_preview()
  vim.schedule(function()
    if M.preview_win and vim.api.nvim_win_is_valid(M.preview_win) then
      vim.api.nvim_win_close(M.preview_win, false)
    end
  end)
end

function M.preview()
  local line = vim.api.nvim_win_get_cursor(0)[1]

  if not M.output[line] then return end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'lua')

  local content = vim.split(table.concat(vim.tbl_flatten(M.output[line]), "\n"), "\n")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

  local lines = tonumber(vim.api.nvim_win_get_height(0)) - 10
  local cols = tonumber(vim.api.nvim_win_get_width(0))
  if vim.api.nvim_call_function('screenrow', {}) >= lines then lines = 0 end

  if M.preview_win and vim.api.nvim_win_is_valid(M.preview_win) then
    vim.api.nvim_win_set_buf(M.preview_win, buf)
    return
  end

  M.preview_win = vim.api.nvim_open_win(buf, false, {
      relative = 'win',
      col = 0,
      row = lines,
      height = 10,
      width = cols - 1,
      style = 'minimal'
    })
  vim.api.nvim_win_set_option(M.preview_win, 'signcolumn', 'no')
end

return M
