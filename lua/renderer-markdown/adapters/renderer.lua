---
--- Markdown Renderer Adapter
--- Implements MarkdownRendererPort
--- Converts AST to Neovim extmarks
---

local shared_models = require("shared.models.types")
local timing_utils = require("shared.utils.timing")

local markdown_renderer_adapter = {}

-- ============================================================================
-- Highlight Groups
-- ============================================================================

local highlight_map = {
	heading1 = "Title",
	heading2 = "Title",
	heading3 = "Identifier",
	heading4 = "Identifier",
	heading5 = "Type",
	heading6 = "Type",
	bold = "Bold",
	italic = "Italic",
	strikethrough = "Strike",
	code = "Special",
	link = "Underlined",
	image = "Underlined",
	list = "Bullet",
	task_done = "Statement",
	task_todo = "Identifier",
	table = "Delimiter",
	blockquote = "Comment",
	hr = "Comment",
	render_time = "Comment",
}

---@return string hl
local function ensure_highlights()
	for _, hl_group in pairs(highlight_map) do
		pcall(vim.api.nvim_set_hl, 0, hl_group, { link = hl_group, default = true })
	end
end

-- ============================================================================
-- Parser
-- ============================================================================

local function parse_single_line(line_content, line_index)
	local marks = {}

	-- Headings
	local heading_prefix = line_content:match("^(#{1,6})%s")
	if heading_prefix then
		marks[1] = {
			line = line_index,
			col = 0,
			end_col = #line_content,
			hl = "heading" .. #heading_prefix,
		}
		return marks
	end

	-- Horizontal rule
	if line_content:match("^%-%-%-%s*$") or line_content:match("^%*%*%*%s*$") then
		marks[1] = {
			line = line_index,
			col = 0,
			end_col = #line_content,
			hl = "hr",
			virt_text = string.rep("─", vim.o.columns),
		}
		return marks
	end

	-- Task lists
	if line_content:match("^%s*[-*+] %[[xX]%]") then
		marks[1] = {
			line = line_index,
			col = 0,
			end_col = #line_content,
			hl = "task_done",
		}
		return marks
	end
	if line_content:match("^%s*[-*+] %[ %]") then
		marks[1] = {
			line = line_index,
			col = 0,
			end_col = #line_content,
			hl = "task_todo",
		}
		return marks
	end

	-- Blockquote
	if line_content:match("^>%s") then
		marks[1] = {
			line = line_index,
			col = 0,
			end_col = 2,
			hl = "blockquote",
		}
		return marks
	end

	-- Inline formatting
	if not line_content:find("[*`[!") then
		return marks
	end

	local mark_index = 1

	-- Bold
	for bold_text in line_content:gmatch("%*%*([^*]+)%*%*") do
		local start_pos = line_content:find("%*%*" .. bold_text .. "%*%*", 1, true)
		if start_pos then
			marks[mark_index] = {
				line = line_index,
				col = start_pos - 1,
				end_col = start_pos + #bold_text + 3,
				hl = "bold",
			}
			mark_index = mark_index + 1
		end
	end

	-- Inline code
	for code_text in line_content:gmatch("`([^`]+)`") do
		local start_pos = line_content:find("`" .. code_text .. "`", 1, true)
		if start_pos then
			marks[mark_index] = {
				line = line_index,
				col = start_pos - 1,
				end_col = start_pos + #code_text + 1,
				hl = "code",
			}
			mark_index = mark_index + 1
		end
	end

	return marks
end

local function parse_markdown(all_lines)
	local all_marks = {}
	local mark_count = 0

	for line_number, line_content in ipairs(all_lines) do
		local line_index = line_number - 1
		local line_marks = parse_single_line(line_content, line_index)

		for _, mark in ipairs(line_marks) do
			mark_count = mark_count + 1
			all_marks[mark_count] = mark
		end
	end

	return all_marks
end

-- ============================================================================
-- Renderer
-- ============================================================================

local ns_id = nil
local last_render_ms = 0

---@param buffer number
---@return number render_time_ms
function markdown_renderer_adapter.render(buffer)
	local timing_start = timing_utils.start()

	if not vim.api.nvim_buf_is_valid(buffer) then
		return 0
	end

	if not ns_id then
		ns_id = vim.api.nvim_create_namespace("renderer_markdown")
	end

	ensure_highlights()

	local buffer_lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
	local render_marks = parse_markdown(buffer_lines)

	vim.api.nvim_buf_clear_namespace(buffer, ns_id, 0, -1)

	for _, mark in ipairs(render_marks) do
		if mark.virt_text then
			vim.api.nvim_buf_set_extmark(buffer, ns_id, mark.line, mark.col, {
				virt_text = { { mark.virt_text, mark.hl } },
				virt_text_pos = "overlay",
			})
		else
			pcall(vim.api.nvim_buf_set_extmark, buffer, ns_id, mark.line, mark.col, {
				end_col = mark.end_col,
				hl_group = mark.hl,
			})
		end
	end

	last_render_ms = timing_utils.stop(timing_start)
	return last_render_ms
end

---@return number
function markdown_renderer_adapter.get_last_render_time()
	return last_render_ms
end

return markdown_renderer_adapter
