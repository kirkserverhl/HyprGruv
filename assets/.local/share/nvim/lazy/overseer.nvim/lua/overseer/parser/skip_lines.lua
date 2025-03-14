local parser = require("overseer.parser")
local SkipLines = {
  desc = "Skip over a set number of lines",
  doc_args = {
    {
      name = "count",
      type = "integer",
      desc = "How many lines to skip",
    },
  },
}

function SkipLines.new(count)
  return setmetatable({ count = count, idx = 0 }, { __index = SkipLines })
end

function SkipLines:reset()
  self.idx = 0
end

function SkipLines:ingest()
  self.idx = self.idx + 1
  if self.idx <= self.count then
    return parser.STATUS.RUNNING
  else
    return parser.STATUS.SUCCESS
  end
end

return SkipLines
