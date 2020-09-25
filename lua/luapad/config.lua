local Config = {
  prefix = 'luapad_',
  bool_values = {
    preview = true,
    error_indicator = true,
    eval_on_move = true,
    eval_on_change = true
  },
  default = {
    preview = true,
    error_indicator = true,
    count_limit = 2 * 1e5,
    print_highlight = 'Comment',
    error_highlight = 'ErrorMsg',
    eval_on_move = false,
    eval_on_change = true
  },
  meta = {}
}

local function get_var(key)
  s, v = pcall(function()
    return vim.api.nvim_get_var(key)
  end)
  if s then return v end
end

local function set_var(key, value)
  if Config.bool_values[key] then
    if value then value = 1 else value = 0 end
  end
  vim.api.nvim_set_var(Config.prefix .. key, value)
end


Config.meta.__index = function(self, key)
  local vim_key = self.prefix .. key

  if self.bool_values[key] then
    local v = get_var(vim_key)
    if v and tonumber(v) == 0 then return false end
    return v or self.default[key]
  else
    return get_var(vim_key) or self.default[key]
  end
end

Config.meta.__newindex = function(self, key, value)
  set_var(key, value)
end

Config.config = function(tbl)
  for k, v in pairs(tbl) do
    set_var(k, v)
  end
end

setmetatable(Config, Config.meta)

return Config
