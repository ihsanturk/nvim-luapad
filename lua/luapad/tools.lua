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

return {
  parse_error = parse_error,
  tbl_keys = tbl_keys
}
