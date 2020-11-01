-- local Config = require'luapad/config'

local function parse_error(str)
  -- if Config.debug then
  --   local internal = str:match('nvim%-luapad.*:%d+:.*')
  --   if internal then return internal end
  -- end
  return str:match("%[string.*%]:(%d*): (.*)")
end

local function tbl_keys(t)
  local keys = {}
  for k, _ in pairs(t) do
    table.insert(keys, k)
  end
  return keys
end

local function get_root_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*)/lua/luapad")
end

return {
  parse_error = parse_error,
  tbl_keys = tbl_keys,
  get_root_path = get_root_path
}
