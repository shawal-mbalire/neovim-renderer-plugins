---
--- ipynb Renderer Plugin
--- TypeScript handles all parsing and rendering
---

local ipynb_plugin = {}

-- ============================================================================
-- Configuration
-- ============================================================================

ipynb_plugin.config = {
	show_execution_count = true,
	max_output_lines = 100,
	debounce_ms = 100,
	show_render_time = true,
	auto_select_kernel = true,
}

-- ============================================================================
-- State
-- ============================================================================

local state = nil

local function get_state()
	if state then
		return state
	end
	state = {
		ns = vim.api.nvim_create_namespace("renderer_ipynb"),
		timers = {},
		selected_kernel = nil,
		last_render_ms = 0,
	}
	return state
end

-- ============================================================================
-- TypeScript Renderer Integration
-- ============================================================================

local function get_renderer_script()
	local paths = {
		"/Volumes/Samsung/GitHub/neovim-plugin/typescript/ipynb/cli.ts",
	}
	for _, path in ipairs(paths) do
		if vim.fn.filereadable(path) == 1 then
			return path
		end
	end
	local rtp = vim.o.runtimepath
	for rtp_path in rtp:gmatch("[^,]+") do
		local cli_path = rtp_path .. "/typescript/ipynb/cli.ts"
		if vim.fn.filereadable(cli_path) == 1 then
			return cli_path
		end
	end
	return ""
end

local function call_ts_renderer(content)
	local script_path = get_renderer_script()
	if script_path == "" then
		return nil
	end

	local json = vim.fn.json_encode({ type = "render", content = content })
	local escaped_json = json:gsub("'", "'\\''")
	local cmd = string.format("echo '%s' | bun run %s 2>/dev/null", escaped_json, script_path)
	local output = vim.fn.system(cmd)

	if not output or output == "" then
		return nil
	end

	local ok, result = pcall(vim.fn.json_decode, output)
	if not ok then
		return nil
	end

	return result
end

-- ============================================================================
-- Fallback Renderer (pure Lua)
-- ============================================================================

local function render_fallback(buffer)
	local timing_start = vim.uv.hrtime()

	if not vim.api.nvim_buf_is_valid(buffer) then
		return 0
	end

	local current_state = get_state()
	local content = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")

	-- Check if already rendered
	if content:match("^=== Jupyter Notebook") then
		return 0
	end

	-- Parse notebook
	local ok, notebook = pcall(vim.fn.json_decode, content)
	if not ok or not notebook.cells then
		return 0
	end

	-- Render cells
	local rendered_lines = {}
	local rendered_marks = {}

	-- Header
	local kernel = notebook.metadata and notebook.metadata.kernelspec
	local header = "=== Jupyter Notebook"
	if kernel and kernel.display_name then
		header = header .. " (" .. kernel.display_name .. ")"
	end
	header = header .. " ==="

	rendered_lines[1] = header
	rendered_marks[1] = { line = 0, col = 0, end_col = #header, hl = "Comment" }
	rendered_lines[2] = ""

	-- Cells
	for cell_index, cell in ipairs(notebook.cells) do
		local cell_type = cell.cell_type or "code"
		local source_lines = cell.source or {}
		local execution_count = cell.execution_count

		-- Cell header
		local header_text = string.format("─── Cell %d: %s", cell_index, cell_type:upper())
		if execution_count and type(execution_count) == "number" then
			header_text = header_text .. string.format(" [%d]", execution_count)
		end
		header_text = header_text .. " ───"

		rendered_lines[#rendered_lines + 1] = header_text
		rendered_marks[#rendered_marks + 1] = { line = #rendered_lines - 1, col = 0, end_col = #header_text, hl = "Comment" }

		-- Source
		for _, line in ipairs(source_lines) do
			rendered_lines[#rendered_lines + 1] = line:gsub("\n$", ""):gsub("\r$", "")
		end

		-- Outputs
		if cell_type == "code" and cell.outputs and #cell.outputs > 0 then
			rendered_lines[#rendered_lines + 1] = "┌─ Output:"
			for _, output in ipairs(cell.outputs) do
				if output.output_type == "stream" and output.text then
					for _, text_line in ipairs(output.text) do
						rendered_lines[#rendered_lines + 1] = "│ " .. text_line:gsub("\n$", "")
					end
				elseif output.output_type == "error" and output.traceback then
					for _, trace_line in ipairs(output.traceback) do
						rendered_lines[#rendered_lines + 1] = "│ " .. trace_line:gsub("\27%[[0-9;]*m", ""):gsub("\n$", "")
					end
				elseif output.output_type == "execute_result" or output.output_type == "display_data" then
					if output.data and output.data["text/plain"] then
						local text = output.data["text/plain"]
						if type(text) == "string" then text = { text } end
						for _, text_line in ipairs(text) do
							rendered_lines[#rendered_lines + 1] = "│ " .. text_line:gsub("\n$", "")
						end
					end
				end
			end
			rendered_lines[#rendered_lines + 1] = "└─────────"
		end

		rendered_lines[#rendered_lines + 1] = ""
	end

	-- Replace buffer
	vim.api.nvim_buf_set_option(buffer, "modifiable", true)
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, rendered_lines)
	vim.api.nvim_buf_set_option(buffer, "modifiable", false)
	vim.bo[buffer].filetype = "ipynb"

	-- Apply highlights
	vim.api.nvim_buf_clear_namespace(buffer, current_state.ns, 0, -1)
	for _, mark in ipairs(rendered_marks) do
		pcall(vim.api.nvim_buf_set_extmark, buffer, current_state.ns, mark.line, mark.col, {
			end_col = mark.end_col,
			hl_group = mark.hl,
		})
	end

	return (vim.uv.hrtime() - timing_start) / 1e6
end

-- ============================================================================
-- Main Renderer
-- ============================================================================

local function render_buffer(buffer)
	if not vim.api.nvim_buf_is_valid(buffer) then
		return 0
	end

	local timing_start = vim.uv.hrtime()

	-- Get buffer content
	local content = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")

	-- Check if already rendered
	if content:match("^=== Jupyter Notebook") then
		return 0
	end

	-- Try TypeScript renderer
	local result = call_ts_renderer(content)

	local render_time
	if result and result.lines then
		-- Apply TypeScript render data
		local current_state = get_state()
		vim.api.nvim_buf_clear_namespace(buffer, current_state.ns, 0, -1)

		for _, line_data in ipairs(result.lines) do
			if line_data.marks then
				for _, mark in ipairs(line_data.marks) do
					if mark.hl and mark.col_end and mark.col_start and mark.col_end > mark.col_start then
						pcall(vim.api.nvim_buf_set_extmark, buffer, current_state.ns, mark.line, mark.col_start, {
							end_col = mark.col_end,
							hl_group = mark.hl,
						})
					end
				end
			end
		end

		-- Replace buffer content if TypeScript returned lines
		if result.lines and #result.lines > 0 then
			local lines = {}
			for _, line_data in ipairs(result.lines) do
				lines[#lines + 1] = line_data.text or ""
			end
			vim.api.nvim_buf_set_option(buffer, "modifiable", true)
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
			vim.api.nvim_buf_set_option(buffer, "modifiable", false)
			vim.bo[buffer].filetype = "ipynb"
		end

		render_time = (vim.uv.hrtime() - timing_start) / 1e6
	else
		-- Fallback
		render_time = render_fallback(buffer)
	end

	local current_state = get_state()
	current_state.last_render_ms = render_time

	if ipynb_plugin.config.show_render_time then
		local status_msg = string.format("[ipynb] %.2f ms", render_time)
		vim.api.nvim_echo({ { status_msg, "Comment" } }, false, {})
	end

	return render_time
end

-- ============================================================================
-- Setup
-- ============================================================================

function ipynb_plugin.setup(opts)
	ipynb_plugin.config = vim.tbl_deep_extend("force", ipynb_plugin.config, opts or {})

	local augroup = vim.api.nvim_create_augroup("RendererIpynb", { clear = true })

	-- Render on file open
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		pattern = "*.ipynb",
		callback = function(event)
			render_buffer(event.buf)
		end,
	})

	-- Render on changes
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = augroup,
		pattern = "*.ipynb",
		callback = function(event)
			local current_state = get_state()
			if current_state.timers[event.buf] then
				current_state.timers[event.buf]:stop()
			end
			current_state.timers[event.buf] = vim.defer_fn(function()
				render_buffer(event.buf)
			end, ipynb_plugin.config.debounce_ms)
		end,
	})

	-- Cleanup
	vim.api.nvim_create_autocmd("BufDelete", {
		group = augroup,
		callback = function(event)
			local current_state = get_state()
			current_state.timers[event.buf] = nil
		end,
	})

	-- Commands
	vim.api.nvim_create_user_command("IpynbRender", function()
		render_buffer(vim.api.nvim_get_current_buf())
	end, {})

	vim.api.nvim_create_user_command("IpynbEdit", function()
		local buffer = vim.api.nvim_get_current_buf()
		vim.bo[buffer].modifiable = true
		vim.bo[buffer].filetype = "json"
		vim.notify("[ipynb] Edit mode", vim.log.levels.INFO)
	end, {})

	vim.api.nvim_create_user_command("IpynbShowKernels", function()
		vim.notify("Kernels:\n★ Python 3\n  Julia\n  R\n  Bash", vim.log.levels.INFO)
	end, {})
end

return ipynb_plugin
