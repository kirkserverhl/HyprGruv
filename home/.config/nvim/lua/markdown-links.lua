local M = {}

---@param node vim.treesitter.TSNode
---@return string?
local function destination_from_node(node)
  if node:type() == "uri_autolink" then
    local text = vim.treesitter.get_node_text(node, 0)
    return text:match("^<(.+)>$") or text
  end

  if node:type() == "email_autolink" then
    return "mailto:" .. vim.treesitter.get_node_text(node, 0)
  end

  if node:type() == "inline_link" or node:type() == "image" then
    for child in node:iter_children() do
      if child:type() == "link_destination" then
        local text = vim.treesitter.get_node_text(child, 0)
        return text:match("%((.+)%)") or text:match("<(.+)>")
      end
    end
  end

  return nil
end

---@param row integer
---@param col integer
---@return string?
local function url_from_treesitter(row, col)
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then
    return nil
  end

  local current = node
  while current do
    local url = destination_from_node(current)
    if url then
      return url
    end
    current = current:parent()
  end

  local parser = vim.treesitter.get_parser(0, "markdown")
  if not parser then
    return nil
  end

  local root = parser:parse()[1]:root()
  for _, n in ipairs(root:descendants()) do
    if destination_from_node(n) then
      local start_row, start_col, end_row, end_col = n:range()
      if row >= start_row and row <= end_row and col >= start_col and col <= end_col then
        return destination_from_node(n)
      end
    end
  end

  return nil
end

---@param line string
---@param col integer
---@return string?
local function url_from_line(line, col)
  for text, dest in line:gmatch("%[([^%]]*)%]%(([^%)]*)%)") do
    local pattern = "%[" .. vim.pesc(text) .. "%]%(" .. vim.pesc(dest) .. "%)"
    local start, end_col = line:find(pattern)
    if start and col >= start and col <= end_col then
      return dest
    end
  end

  for url in line:gmatch("https?://[%w%-_%.%?%/%%&=#:+~]+") do
    local start = line:find(url, 1, true)
    if start and col >= start and col <= start + #url - 1 then
      return url
    end
  end

  local cfile = vim.fn.expand("<cfile>")
  if cfile:match("^https?://") or cfile:match("^mailto:") then
    return cfile
  end

  return nil
end

---@return string?
function M.url_at_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  col = col + 1

  return url_from_treesitter(row, col) or url_from_line(vim.api.nvim_get_current_line(), col)
end

function M.open()
  local url = M.url_at_cursor()
  if url then
    vim.ui.open(url)
    return
  end

  vim.cmd("normal! gx")
end

return M