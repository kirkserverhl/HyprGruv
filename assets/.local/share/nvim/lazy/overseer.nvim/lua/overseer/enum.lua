local Enum = setmetatable({}, {
  __index = function(_, key)
    error(string.format("Unknown constant value '%s'", key))
  end,
})

function Enum:contains(value)
  for k in pairs(self) do
    if k == value then
      return true
    end
  end
  return false
end

function Enum.new(values)
  local ret = {}
  for _, v in ipairs(values) do
    ret[v] = v
  end
  ret.values = values
  return setmetatable(ret, { __index = Enum })
end

return Enum
