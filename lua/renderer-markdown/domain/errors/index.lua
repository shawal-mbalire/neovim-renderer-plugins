---
--- Markdown Domain Errors
--- Specific, self-documenting exceptions
---

local markdown_errors = {}

---@class MarkdownError
---@field message string
---@field line? number
---@field column? number

---@param message string
---@param line? number
---@param column? number
---@return MarkdownError
function markdown_errors.create(message, line, column)
	return {
		message = message,
		line = line,
		column = column,
	}
end

---@param line number
---@param column number
---@return MarkdownError
function markdown_errors.parse_error(line, column)
	return markdown_errors.create(
		string.format("Parse error at line %d, column %d", line, column),
		line,
		column
	)
end

return markdown_errors
