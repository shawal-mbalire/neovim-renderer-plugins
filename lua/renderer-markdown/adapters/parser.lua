---
--- Markdown Parser Adapter
--- Implements MarkdownParserPort
--- Pure Lua implementation - zero dependencies
---

local markdown_models = require("renderer-markdown.domain.models.types")

local markdown_parser = {}

-- ============================================================================
-- Parser Implementation
-- ============================================================================

---@param markdown string
---@return MarkdownASTNode
function markdown_parser.parse(markdown)
  local lines = vim.split(markdown, "\n")
  local root = markdown_models.create_node("document", { children = {} })

  local line_index = 1
  while line_index <= #lines do
    local line = lines[line_index]

    -- Code blocks
    if line:match("^```") then
      local result = markdown_parser.parse_code_block(lines, line_index)
      table.insert(root.children, result.node)
      line_index = result.next_line
    -- Headings
    elseif line:match("^#{1,6}%s") then
      local level = #line:match("^(#{1,6})")
      local content = line:match("^#{1,6}%s+(.+)$")
      table.insert(root.children, markdown_models.create_heading(level, content))
      line_index = line_index + 1
    -- Horizontal rule
    elseif line:match("^%-%-%-%s*$") or line:match("^%*%*%*%s*$") then
      table.insert(root.children, markdown_models.create_node("horizontal_rule"))
      line_index = line_index + 1
    -- Blockquote
    elseif line:match("^>%s") then
      local result = markdown_parser.parse_blockquote(lines, line_index)
      table.insert(root.children, result.node)
      line_index = result.next_line
    -- Task list
    elseif line:match("^%s*[-*+] %[[ xX]%]") then
      local result = markdown_parser.parse_task_list(lines, line_index)
      table.insert(root.children, result.node)
      line_index = result.next_line
    -- Unordered list
    elseif line:match("^%s*[-*+]%s") then
      local result = markdown_parser.parse_list(lines, line_index, false)
      table.insert(root.children, result.node)
      line_index = result.next_line
    -- Ordered list
    elseif line:match("^%s*%d+[.)]%s") then
      local result = markdown_parser.parse_list(lines, line_index, true)
      table.insert(root.children, result.node)
      line_index = result.next_line
    -- Table
    elseif line:match("|") and line_index + 1 <= #lines and lines[line_index + 1]:match("^|?[%s:]+%-") then
      local result = markdown_parser.parse_table(lines, line_index)
      table.insert(root.children, result.node)
      line_index = result.next_line
    -- Empty line
    elseif line:match("^%s*$") then
      line_index = line_index + 1
    -- Paragraph
    else
      local result = markdown_parser.parse_paragraph(lines, line_index)
      table.insert(root.children, result.node)
      line_index = result.next_line
    end
  end

  return root
end

-- ============================================================================
-- Block Parsers
-- ============================================================================

---@param lines string[]
---@param start number
---@return { node: MarkdownASTNode, next_line: number }
function markdown_parser.parse_code_block(lines, start)
  local lang_match = lines[start]:match("^```(%w*)")
  local language = lang_match ~= "" and lang_match or nil
  local code_lines = {}
  local i = start + 1

  while i <= #lines do
    if lines[i]:match("^```") then
      return {
        node = markdown_models.create_code_block(table.concat(code_lines, "\n"), language),
        next_line = i + 1,
      }
    end
    table.insert(code_lines, lines[i])
    i = i + 1
  end

  return {
    node = markdown_models.create_code_block(table.concat(code_lines, "\n"), language),
    next_line = i,
  }
end

---@param lines string[]
---@param start number
---@return { node: MarkdownASTNode, next_line: number }
function markdown_parser.parse_blockquote(lines, start)
  local content_lines = {}
  local i = start

  while i <= #lines and lines[i]:match("^>%s") do
    table.insert(content_lines, lines[i]:gsub("^>%s?", ""))
    i = i + 1
  end

  return {
    node = markdown_models.create_node("blockquote", {
      children = { markdown_models.create_node("text", { content = table.concat(content_lines, "\n") }) },
    }),
    next_line = i,
  }
end

---@param lines string[]
---@param start number
---@return { node: MarkdownASTNode, next_line: number }
function markdown_parser.parse_task_list(lines, start)
  local items = {}
  local i = start

  while i <= #lines do
    local match = lines[i]:match("^%s*[-*+] %[(%s)%]%s+(.+)$")
    local done_match = lines[i]:match("^%s*[-*+] %[(x)%]%s+(.+)$")

    if done_match then
      table.insert(items, markdown_models.create_node("task_item", {
        checked = true,
        children = { markdown_models.create_node("text", { content = done_match }) },
      }))
      i = i + 1
    elseif match then
      table.insert(items, markdown_models.create_node("task_item", {
        checked = false,
        children = { markdown_models.create_node("text", { content = match }) },
      }))
      i = i + 1
    else
      break
    end
  end

  return {
    node = markdown_models.create_node("task_list", { children = items }),
    next_line = i,
  }
end

---@param lines string[]
---@param start number
---@param ordered boolean
---@return { node: MarkdownASTNode, next_line: number }
function markdown_parser.parse_list(lines, start, ordered)
  local items = {}
  local i = start
  local pattern = ordered and "^%s*%d+[.)]%s+(.+)$" or "^%s*[-*+]%s+(.+)$"

  while i <= #lines do
    local content = lines[i]:match(pattern)
    if content then
      table.insert(items, markdown_models.create_node("list_item", {
        children = { markdown_models.create_node("text", { content = content }) },
      }))
      i = i + 1
    else
      break
    end
  end

  return {
    node = markdown_models.create_node(ordered and "ordered_list" or "unordered_list", { children = items }),
    next_line = i,
  }
end

---@param lines string[]
---@param start number
---@return { node: MarkdownASTNode, next_line: number }
function markdown_parser.parse_table(lines, start)
  local rows = {}
  local i = start

  -- Parse header
  local header_cells = markdown_parser.parse_table_row(lines[i])
  table.insert(rows, markdown_models.create_node("table_row", {
    children = vim.tbl_map(function(cell)
      return markdown_models.create_node("table_cell", {
        children = { markdown_models.create_node("text", { content = cell }) },
      })
    end, header_cells),
  }))
  i = i + 1

  -- Skip separator
  if i <= #lines and lines[i]:match("^|?[%s:]+%-") then
    i = i + 1
  end

  -- Parse data rows
  while i <= #lines and lines[i]:match("|") do
    local cells = markdown_parser.parse_table_row(lines[i])
    table.insert(rows, markdown_models.create_node("table_row", {
      children = vim.tbl_map(function(cell)
        return markdown_models.create_node("table_cell", {
          children = { markdown_models.create_node("text", { content = cell }) },
        })
      end, cells),
    }))
    i = i + 1
  end

  return {
    node = markdown_models.create_node("table", { children = rows }),
    next_line = i,
  }
end

---@param line string
---@return string[]
function markdown_parser.parse_table_row(line)
  local cells = {}
  for cell in line:gmatch("|([^|]+)") do
    table.insert(cells, vim.trim(cell))
  end
  return cells
end

---@param lines string[]
---@param start number
---@return { node: MarkdownASTNode, next_line: number }
function markdown_parser.parse_paragraph(lines, start)
  local content_lines = {}
  local i = start

  while i <= #lines and lines[i]:match("^%s*$") == nil and not markdown_parser.is_block_start(lines[i]) do
    table.insert(content_lines, lines[i])
    i = i + 1
  end

  return {
    node = markdown_models.create_paragraph(table.concat(content_lines, " ")),
    next_line = i,
  }
end

---@param line string
---@return boolean
function markdown_parser.is_block_start(line)
  local trimmed = line:match("^%s*(.+)$")
  return trimmed:match("^#") ~= nil
    or trimmed:match("^```") ~= nil
    or trimmed:match("^>") ~= nil
    or trimmed:match("^[-*+]%s") ~= nil
    or trimmed:match("^%d+[.)]%s") ~= nil
end

return markdown_parser
