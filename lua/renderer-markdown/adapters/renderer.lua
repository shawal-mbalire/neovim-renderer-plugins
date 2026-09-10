---
--- Markdown Renderer Adapter - Web-like rendering
--- Uses extmarks, virtual text, window options for rendered appearance
---

local timing_utils = require("shared.utils.timing")

local markdown_renderer = {}

-- ============================================================================
-- State
-- ============================================================================

local ns_id = nil
local last_render_ms = 0

-- ============================================================================
-- Highlight Groups
-- ============================================================================

local hl = {
	heading1 = "MarkdownH1",
	heading2 = "MarkdownH2",
	heading3 = "MarkdownH3",
	heading4 = "MarkdownH4",
	heading5 = "MarkdownH5",
	heading6 = "MarkdownH6",
	bold = "MarkdownBold",
	italic = "MarkdownItalic",
	strikethrough = "MarkdownStrikethrough",
	code = "MarkdownCode",
	code_block = "MarkdownCodeBlock",
	code_fence = "MarkdownCodeFence",
	link = "MarkdownLink",
	link_url = "MarkdownLinkUrl",
	image = "MarkdownImage",
	blockquote = "MarkdownBlockquote",
	blockquote_marker = "MarkdownBlockquoteMarker",
	table_header = "MarkdownTableHeader",
	table_border = "MarkdownTableBorder",
	table_align = "MarkdownTableAlign",
	list_marker = "MarkdownListMarker",
	task_done = "MarkdownTaskDone",
	task_todo = "MarkdownTaskTodo",
	hr = "MarkdownHr",
	html_tag = "MarkdownHtml",
}

local function setup_highlights()
	-- Heading colors (GitHub-style blue)
	vim.api.nvim_set_hl(0, hl.heading1, { fg = "#1f6feb", bold = true, ctermfg = 33 })
	vim.api.nvim_set_hl(0, hl.heading2, { fg = "#1f6feb", bold = true, ctermfg = 33 })
	vim.api.nvim_set_hl(0, hl.heading3, { fg = "#1f6feb", bold = true, ctermfg = 33 })
	vim.api.nvim_set_hl(0, hl.heading4, { fg = "#1f6feb", bold = true, ctermfg = 33 })
	vim.api.nvim_set_hl(0, hl.heading5, { fg = "#1f6feb", bold = true, ctermfg = 33 })
	vim.api.nvim_set_hl(0, hl.heading6, { fg = "#1f6feb", bold = true, ctermfg = 33 })

	-- Formatting
	vim.api.nvim_set_hl(0, hl.bold, { bold = true })
	vim.api.nvim_set_hl(0, hl.italic, { italic = true })
	vim.api.nvim_set_hl(0, hl.strikethrough, { strikethrough = true })

	-- Code
	vim.api.nvim_set_hl(0, hl.code, { fg = "#e06c75", bg = "#282c34", ctermfg = 174, ctermbg = 235 })
	vim.api.nvim_set_hl(0, hl.code_block, { fg = "#abb2bf", bg = "#282c34", ctermfg = 145, ctermbg = 235 })
	vim.api.nvim_set_hl(0, hl.code_fence, { fg = "#5c6370", ctermfg = 241 })

	-- Links
	vim.api.nvim_set_hl(0, hl.link, { fg = "#61afef", underline = true, ctermfg = 75, cterm = "underline" })
	vim.api.nvim_set_hl(0, hl.link_url, { fg = "#5c6370", ctermfg = 241 })

	-- Images
	vim.api.nvim_set_hl(0, hl.image, { fg = "#c678dd", ctermfg = 170 })

	-- Blockquote
	vim.api.nvim_set_hl(0, hl.blockquote, { fg = "#5c6370", italic = true, ctermfg = 241, cterm = "italic" })
	vim.api.nvim_set_hl(0, hl.blockquote_marker, { fg = "#61afef", ctermfg = 75 })

	-- Table
	vim.api.nvim_set_hl(0, hl.table_header, { fg = "#e5c07b", bold = true, ctermfg = 180, cterm = "bold" })
	vim.api.nvim_set_hl(0, hl.table_border, { fg = "#5c6370", ctermfg = 241 })
	vim.api.nvim_set_hl(0, hl.table_align, { fg = "#5c6370", ctermfg = 241 })

	-- Lists
	vim.api.nvim_set_hl(0, hl.list_marker, { fg = "#e06c75", ctermfg = 174 })
	vim.api.nvim_set_hl(0, hl.task_done, { fg = "#98c379", ctermfg = 114 })
	vim.api.nvim_set_hl(0, hl.task_todo, { fg = "#e5c07b", ctermfg = 180 })

	-- Horizontal rule
	vim.api.nvim_set_hl(0, hl.hr, { fg = "#3e4451", ctermfg = 238 })

	-- HTML
	vim.api.nvim_set_hl(0, hl.html_tag, { fg = "#e06c75", ctermfg = 174 })
end

-- ============================================================================
-- Parser - Single pass per line
-- ============================================================================

local function parse_line(line, line_idx)
	local marks = {}

	-- Headings (check first - most common)
	local heading_level = line:match("^(#{1,6})%s")
	if heading_level then
		local level = #heading_level
		marks[1] = {
			line = line_idx,
			col = 0,
			end_col = #line,
			hl = hl["heading" .. level],
			virt_text = { string.rep("═", vim.o.columns), hl.hr },
			virt_text_pos = "overlay",
		}
		return marks
	end

	-- Horizontal rule
	if line:match("^%-%-%-%s*$") or line:match("^%*%*%*%s*$") or line:match("^___%s*$") then
		marks[1] = {
			line = line_idx,
			col = 0,
			end_col = #line,
			hl = hl.hr,
			virt_text = { string.rep("─", vim.o.columns), hl.hr },
			virt_text_pos = "overlay",
		}
		return marks
	end

	-- Task lists (check before general list)
	if line:match("^%s*[-*+] %[[xX]%]") then
		marks[1] = {
			line = line_idx,
			col = 0,
			end_col = #line,
			hl = hl.task_done,
			virt_text = { "✓ ", hl.task_done },
			virt_text_pos = "inline",
		}
		return marks
	end
	if line:match("^%s*[-*+] %[ %]") then
		marks[1] = {
			line = line_idx,
			col = 0,
			end_col = #line,
			hl = hl.task_todo,
			virt_text = { "○ ", hl.task_todo },
			virt_text_pos = "inline",
		}
		return marks
	end

	-- Blockquote
	if line:match("^>%s") then
		marks[1] = {
			line = line_idx,
			col = 0,
			end_col = math.min(2, #line),
			hl = hl.blockquote_marker,
			virt_text = { "█ ", hl.blockquote_marker },
			virt_text_pos = "inline",
		}
		return marks
	end

	-- Table separator row
	if line:match("^|?%s*[-:]+%s*|") then
		marks[1] = {
			line = line_idx,
			col = 0,
			end_col = #line,
			hl = hl.table_border,
		}
		return marks
	end

	-- Table row
	if line:match("|") and not line:match("^%s*$") then
		local col = 0
		for cell in line:gmatch("|([^|]+)") do
			local cell_start = line:find("|" .. cell, col, true)
			if cell_start then
				marks[#marks + 1] = {
					line = line_idx,
					col = cell_start - 1,
					end_col = cell_start + #cell,
					hl = hl.table_border,
				}
				col = cell_start + #cell
			end
		end
		return marks
	end

	-- Unordered list
	if line:match("^%s*[-*+]%s") then
		marks[1] = {
			line = line_idx,
			col = 0,
			end_col = #line,
			hl = hl.list_marker,
			virt_text = { "• ", hl.list_marker },
			virt_text_pos = "inline",
		}
		return marks
	end

	-- Ordered list
	if line:match("^%s*%d+[.)]%s") then
		local num = line:match("^%s*(%d+)")
		marks[1] = {
			line = line_idx,
			col = 0,
			end_col = #line,
			hl = hl.list_marker,
			virt_text = { num .. ". ", hl.list_marker },
			virt_text_pos = "inline",
		}
		return marks
	end

	-- Inline elements (only if line has special chars)
	if not line:find("[*`[!~]") then
		return marks
	end

	local mark_index = 1

	-- Bold
	for bold_text in line:gmatch("%*%*([^*]+)%*%*") do
		local start_pos = line:find("%*%*" .. bold_text .. "%*%*", 1, true)
		if start_pos then
			marks[mark_index] = {
				line = line_idx,
				col = start_pos - 1,
				end_col = start_pos + #bold_text + 3,
				hl = hl.bold,
			}
			mark_index = mark_index + 1
		end
	end

	-- Italic (not inside bold)
	for italic_text in line:gmatch("[^%*]%*([^*]+)%*[^%*]") do
		local start_pos = line:find("[^%*]%*" .. italic_text .. "%*[^%*]")
		if start_pos then
			marks[mark_index] = {
				line = line_idx,
				col = start_pos,
				end_col = start_pos + #italic_text + 1,
				hl = hl.italic,
			}
			mark_index = mark_index + 1
		end
	end

	-- Strikethrough
	for strike_text in line:gmatch("~~([^~]+)~~") do
		local start_pos = line:find("~~" .. strike_text .. "~~", 1, true)
		if start_pos then
			marks[mark_index] = {
				line = line_idx,
				col = start_pos - 1,
				end_col = start_pos + #strike_text + 3,
				hl = hl.strikethrough,
			}
			mark_index = mark_index + 1
		end
	end

	-- Code inline
	for code_text in line:gmatch("`([^`]+)`") do
		local start_pos = line:find("`" .. code_text .. "`", 1, true)
		if start_pos then
			marks[mark_index] = {
				line = line_idx,
				col = start_pos - 1,
				end_col = start_pos + #code_text + 1,
				hl = hl.code,
			}
			mark_index = mark_index + 1
		end
	end

	-- Links [text](url)
	for link_text, link_url in line:gmatch("%[([^%]]+)%]%(([^)]+)%)") do
		local pattern = "%[" .. link_text .. "%]%(" .. link_url .. "%)"
		local start_pos = line:find(pattern, 1, true)
		if start_pos then
			marks[mark_index] = {
				line = line_idx,
				col = start_pos - 1,
				end_col = start_pos + #link_text + #link_url + 3,
				hl = hl.link,
			}
			mark_index = mark_index + 1
		end
	end

	-- Images ![alt](src)
	if line:match("!%[") then
		for alt_text, img_src in line:gmatch("!%[([^%]]+)%]%(([^)]+)%)") do
			local pattern = "!%[" .. alt_text .. "%]%(" .. img_src .. "%)"
			local start_pos = line:find(pattern, 1, true)
			if start_pos then
				marks[mark_index] = {
					line = line_idx,
					col = start_pos - 1,
					end_col = start_pos + #alt_text + #img_src + 3,
					hl = hl.image,
					virt_text = { "🖼 ", hl.image },
					virt_text_pos = "inline",
				}
				mark_index = mark_index + 1
			end
		end
	end

	return marks
end

local function parse_markdown(all_lines)
	local all_marks = {}
	local mark_count = 0

	for line_number, line_content in ipairs(all_lines) do
		local line_idx = line_number - 1
		local line_marks = parse_line(line_content, line_idx)

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

---@param buffer number
---@return number render_time_ms
function markdown_renderer.render(buffer)
	local timing_start = timing_utils.start()

	if not vim.api.nvim_buf_is_valid(buffer) then
		return 0
	end

	if not ns_id then
		ns_id = vim.api.nvim_create_namespace("renderer_markdown")
		setup_highlights()
	end

	local buffer_lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
	local render_marks = parse_markdown(buffer_lines)

	vim.api.nvim_buf_clear_namespace(buffer, ns_id, 0, -1)

	for _, mark in ipairs(render_marks) do
		if mark.virt_text then
			vim.api.nvim_buf_set_extmark(buffer, ns_id, mark.line, mark.col, {
				virt_text = { mark.virt_text },
				virt_text_pos = mark.virt_text_pos or "overlay",
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
function markdown_renderer.get_last_render_time()
	return last_render_ms
end

return markdown_renderer
