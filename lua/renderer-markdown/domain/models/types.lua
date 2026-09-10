---
--- Markdown Domain Models
--- Pure data structures for GFM + GitHub extensions
---

local markdown_models = {}

-- ============================================================================
-- Node Types (StrEnum pattern)
-- ============================================================================

---@alias MarkdownNodeType
---| "document"
---| "heading"
---| "paragraph"
---| "text"
---| "bold"
---| "italic"
---| "strikethrough"
---| "code_inline"
---| "code_block"
---| "link"
---| "image"
---| "blockquote"
---| "list_item"
---| "ordered_list"
---| "unordered_list"
---| "task_list"
---| "task_item"
---| "table"
---| "table_row"
---| "table_cell"
---| "horizontal_rule"

-- ============================================================================
-- AST Node
-- ============================================================================

---@class MarkdownASTNode
---@field type MarkdownNodeType
---@field content? string
---@field children? MarkdownASTNode[]
---@field attributes? table<string, string>
---@field level? number
---@field language? string
---@field ordered? boolean
---@field checked? boolean

-- ============================================================================
-- Factory Functions
-- ============================================================================

---@param type MarkdownNodeType
---@param options? table
---@return MarkdownASTNode
function markdown_models.create_node(type, options)
  local node = { type = type }
  if options then
    for key, value in pairs(options) do
      node[key] = value
    end
  end
  return node
end

---@param level number
---@param content string
---@return MarkdownASTNode
function markdown_models.create_heading(level, content)
  return markdown_models.create_node("heading", {
    level = level,
    children = { markdown_models.create_node("text", { content = content }) },
  })
end

---@param content string
---@return MarkdownASTNode
function markdown_models.create_paragraph(content)
  return markdown_models.create_node("paragraph", {
    children = { markdown_models.create_node("text", { content = content }) },
  })
end

---@param code string
---@param language? string
---@return MarkdownASTNode
function markdown_models.create_code_block(code, language)
  return markdown_models.create_node("code_block", {
    content = code,
    language = language,
  })
end

return markdown_models
