---
--- ipynb Renderer Adapter
--- Implements NotebookRendererPort
--- Converts notebook to Neovim extmarks
---

local shared_models = require("shared.models.types")
local timing_utils = require("shared.utils.timing")
local ipynb_models = require("renderer-ipynb.domain.models.types")

local ipynb_renderer_adapter = {}

-- ============================================================================
-- Highlight Groups
-- ============================================================================

local highlight_map = {
	cell_header = "Comment",
	code_cell = "Special",
	markdown_cell = "String",
	output = "Delimiter",
	output_text = "Normal",
	error = "ErrorMsg",
	image = "Underlined",
	kernel_name = "Identifier",
}

local function ensure_highlights()
	for _, hl_group in pairs(highlight_map) do
		pcall(vim.api.nvim_set_hl, 0, hl_group, { link = hl_group, default = true })
	end
end

-- ============================================================================
-- Output Renderer
-- ============================================================================

local function render_output(output, output_lines, output_marks)
	local output_type = output.output_type

	if output_type == "stream" then
		local stream_text = output.text or {}
		if type(stream_text) == "string" then
			stream_text = vim.split(stream_text, "\n")
		end
		for _, stream_line in ipairs(stream_text) do
			local content = stream_line:gsub("\n$", ""):gsub("\r$", "")
			local line_num = #output_lines
			output_lines[line_num + 1] = "│ " .. content
			output_marks[line_num + 1] = {
				line = line_num,
				col = 0,
				end_col = 2,
				hl = "output",
			}
		end
	elseif output_type == "error" then
		local traceback_lines = output.traceback or {}
		for _, traceback_line in ipairs(traceback_lines) do
			local content = traceback_line:gsub("\27%[[0-9;]*m", ""):gsub("\n$", ""):gsub("\r$", "")
			local line_num = #output_lines
			output_lines[line_num + 1] = "│ " .. content
			output_marks[line_num + 1] = {
				line = line_num,
				col = 0,
				end_col = #content + 2,
				hl = "error",
			}
		end
	elseif output_type == "execute_result" or output_type == "display_data" then
		local output_data = output.data or {}
		if output_data["text/plain"] then
			local text_content = output_data["text/plain"]
			if type(text_content) == "string" then
				text_content = vim.split(text_content, "\n")
			end
			for _, text_line in ipairs(text_content) do
				local content = text_line:gsub("\n$", ""):gsub("\r$", "")
				local line_num = #output_lines
				output_lines[line_num + 1] = "│ " .. content
				output_marks[line_num + 1] = {
					line = line_num,
					col = 2,
					end_col = #content + 2,
					hl = "output_text",
				}
			end
		elseif output_data["image/png"] or output_data["image/jpeg"] then
			local line_num = #output_lines
			output_lines[line_num + 1] = "│ [Image]"
			output_marks[line_num + 1] = {
				line = line_num,
				col = 0,
				end_col = 10,
				hl = "image",
			}
		end
	end
end

-- ============================================================================
-- Cell Renderer
-- ============================================================================

local function render_cell(cell, cell_index, output_lines, output_marks)
	local cell_type = cell.cell_type or "code"
	local source_lines = cell.source or {}
	local cell_outputs = cell.outputs or {}
	local execution_count = cell.execution_count

	-- Cell header
	local header_text = string.format("─── Cell %d: %s", cell_index, cell_type:upper())
	if execution_count then
		header_text = header_text .. string.format(" [%d]", execution_count)
	end
	header_text = header_text .. " ───"

	local header_line_num = #output_lines
	output_lines[header_line_num + 1] = header_text
	output_marks[header_line_num + 1] = {
		line = header_line_num,
		col = 0,
		end_col = #header_text,
		hl = "cell_header",
	}

	-- Source code
	if type(source_lines) == "string" then
		source_lines = vim.split(source_lines, "\n")
	end

	local hl_group = cell_type == "code" and "code_cell" or nil
	for _, source_line in ipairs(source_lines) do
		local sub_lines = vim.split(source_line, "\n")
		for _, sub_line in ipairs(sub_lines) do
			local content = sub_line:gsub("\n$", ""):gsub("\r$", "")
			local line_num = #output_lines
			output_lines[line_num + 1] = content
			if hl_group then
				output_marks[line_num + 1] = {
					line = line_num,
					col = 0,
					end_col = #content,
					hl = hl_group,
				}
			end
		end
	end

	-- Outputs
	if cell_type == "code" and #cell_outputs > 0 then
		local output_header_num = #output_lines
		output_lines[output_header_num + 1] = "┌─ Output:"
		output_marks[output_header_num + 1] = {
			line = output_header_num,
			col = 0,
			end_col = 10,
			hl = "output",
		}

		for _, output in ipairs(cell_outputs) do
			render_output(output, output_lines, output_marks)
		end

		local output_footer_num = #output_lines
		output_lines[output_footer_num + 1] = "└─────────"
		output_marks[output_footer_num + 1] = {
			line = output_footer_num,
			col = 0,
			end_col = 10,
			hl = "output",
		}
	end

	output_lines[#output_lines + 1] = ""
end

-- ============================================================================
-- Renderer
-- ============================================================================

local ns_id = nil
local last_render_ms = 0

---@param buffer number
---@param notebook? table
---@return number render_time_ms
function ipynb_renderer_adapter.render(buffer, notebook)
	local timing_start = timing_utils.start()

	if not vim.api.nvim_buf_is_valid(buffer) then
		return 0
	end

	if not ns_id then
		ns_id = vim.api.nvim_create_namespace("renderer_ipynb")
	end

	ensure_highlights()

	-- Parse notebook from buffer if not provided
	if not notebook then
		local content = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
		local success, parsed = pcall(vim.fn.json_decode, content)
		if not success or not parsed.cells then
			return 0
		end
		notebook = parsed
	end

	local rendered_lines = {}
	local rendered_marks = {}

	-- Notebook header
	local kernel = notebook.metadata and notebook.metadata.kernelspec
	local header = "=== Jupyter Notebook"
	if kernel and kernel.display_name then
		header = header .. " (" .. kernel.display_name .. ")"
	end
	header = header .. " ==="

	rendered_lines[1] = header
	rendered_marks[1] = {
		line = 0,
		col = 0,
		end_col = #header,
		hl = "cell_header",
	}
	rendered_lines[2] = ""

	-- Render cells
	for cell_index, cell in ipairs(notebook.cells) do
		render_cell(cell, cell_index, rendered_lines, rendered_marks)
	end

	-- Replace buffer content
	vim.api.nvim_buf_set_option(buffer, "modifiable", true)
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, rendered_lines)
	vim.api.nvim_buf_set_option(buffer, "modifiable", false)
	vim.bo[buffer].filetype = "ipynb"

	-- Apply highlights
	vim.api.nvim_buf_clear_namespace(buffer, ns_id, 0, -1)
	for _, mark in ipairs(rendered_marks) do
		pcall(vim.api.nvim_buf_set_extmark, buffer, ns_id, mark.line, mark.col, {
			end_col = mark.end_col,
			hl_group = mark.hl,
		})
	end

	last_render_ms = timing_utils.stop(timing_start)
	return last_render_ms
end

---@return number
function ipynb_renderer_adapter.get_last_render_time()
	return last_render_ms
end

return ipynb_renderer_adapter
