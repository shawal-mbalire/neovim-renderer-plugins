---
--- Markdown Renderer Plugin
--- Calls TypeScript renderer via Bun for proper markdown rendering
---

local markdown_plugin = {}

-- ============================================================================
-- Configuration
-- ============================================================================

markdown_plugin.config = {
	preview = {
		enabled = true,
		position = "right",
		width = 50,
		height = 15,
		sync_scroll = true,
		auto_open = false,
	},
	debounce_ms = 100,
	show_render_time = true,
}

-- ============================================================================
-- State
-- ============================================================================

local state = nil
local job_id = nil

local function get_state()
	if state then
		return state
	end
	state = {
		ns = vim.api.nvim_create_namespace("renderer_markdown"),
		preview_wins = {},
		preview_bufs = {},
		timers = {},
		last_render_ms = 0,
		highlights_setup = false,
	}
	return state
end

-- ============================================================================
-- Highlights
-- ============================================================================

local function setup_highlights()
	local current_state = get_state()
	if current_state.highlights_setup then
		return
	end
	current_state.highlights_setup = true

	local hl_map = {
		{ "MarkdownH1", "Title" },
		{ "MarkdownH2", "Title" },
		{ "MarkdownH3", "Identifier" },
		{ "MarkdownH4", "Identifier" },
		{ "MarkdownH5", "Type" },
		{ "MarkdownH6", "Type" },
		{ "MarkdownBold", "Bold" },
		{ "MarkdownItalic", "Italic" },
		{ "MarkdownStrikethrough", "Strike" },
		{ "MarkdownCode", "Special" },
		{ "MarkdownCodeBlock", "Special" },
		{ "MarkdownCodeFence", "Comment" },
		{ "MarkdownLink", "Underlined" },
		{ "MarkdownImage", "Underlined" },
		{ "MarkdownBlockquote", "Comment" },
		{ "MarkdownTableHeader", "Keyword" },
		{ "MarkdownTableBorder", "Delimiter" },
		{ "MarkdownListMarker", "Bullet" },
		{ "MarkdownTaskDone", "Statement" },
		{ "MarkdownTaskTodo", "Identifier" },
		{ "MarkdownHr", "Comment" },
		{ "MarkdownHtml", "PreProc" },
		{ "MarkdownRenderTime", "Comment" },
	}

	for _, mapping in ipairs(hl_map) do
		vim.api.nvim_set_hl(0, mapping[1], { link = mapping[2], default = true })
	end
end

-- ============================================================================
-- Renderer - Uses TypeScript via Bun
-- ============================================================================

local function get_renderer_script()
	local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
	return plugin_dir .. "/../../typescript/markdown/index.ts"
end

local function render_buffer(buffer)
	if not vim.api.nvim_buf_is_valid(buffer) then
		return 0
	end

	local timing_start = vim.uv.hrtime()

	-- Get buffer content
	local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
	local content = table.concat(lines, "\n")

	-- Call TypeScript renderer via Bun
	local script_path = get_renderer_script()
	local cmd = string.format(
		'echo \'{"type":"render","content":%s}\' | bun run %s 2>/dev/null',
		vim.fn.json_encode(content),
		script_path
	)

	local handle = io.popen(cmd, "r")
	if not handle then
		return 0
	end

	local output = handle:read("*a")
	handle:close()

	-- Parse response
	local ok, result = pcall(vim.fn.json_decode, output)
	if not ok or not result or not result.lines then
		-- Fallback to basic rendering
		return render_buffer_basic(buffer)
	end

	-- Apply render data
	local current_state = get_state()
	vim.api.nvim_buf_clear_namespace(buffer, current_state.ns, 0, -1)

	for _, line_data in ipairs(result.lines) do
		if line_data.marks then
			for _, mark in ipairs(line_data.marks) do
				if mark.virt_text then
					vim.api.nvim_buf_set_extmark(buffer, current_state.ns, mark.line, mark.col, {
						virt_text = { { mark.virt_text, mark.hl or "Comment" } },
						virt_text_pos = mark.virt_text_pos or "inline",
					})
				elseif mark.hl and mark.col_end > mark.col_start then
					pcall(vim.api.nvim_buf_set_extmark, buffer, current_state.ns, mark.line, mark.col_start, {
						end_col = mark.col_end,
						hl_group = mark.hl,
					})
				end
			end
		end
	end

	local render_time = (vim.uv.hrtime() - timing_start) / 1e6
	current_state.last_render_ms = render_time

	if markdown_plugin.config.show_render_time then
		local status_msg = string.format("[markdown] %.2f ms", render_time)
		vim.api.nvim_echo({ { status_msg, "MarkdownRenderTime" } }, false, {})
	end

	return render_time
end

-- ============================================================================
-- Basic Renderer (fallback when Bun not available)
-- ============================================================================

local function render_buffer_basic(buffer)
	local timing_start = vim.uv.hrtime()

	if not vim.api.nvim_buf_is_valid(buffer) then
		return 0
	end

	local current_state = get_state()
	setup_highlights()

	local buffer_lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
	vim.api.nvim_buf_clear_namespace(buffer, current_state.ns, 0, -1)

	for line_idx, line in ipairs(buffer_lines) do
		local line_num = line_idx - 1

		-- Headings
		local heading_level = line:match("^(#{1,6})%s")
		if heading_level then
			pcall(vim.api.nvim_buf_set_extmark, buffer, current_state.ns, line_num, 0, {
				end_col = #line,
				hl_group = "MarkdownH" .. #heading_level,
			})
		end

		-- Bold
		for bold_text in line:gmatch("%*%*([^*]+)%*%*") do
			local start_pos = line:find("%*%*" .. bold_text .. "%*%*", 1, true)
			if start_pos then
				pcall(vim.api.nvim_buf_set_extmark, buffer, current_state.ns, line_num, start_pos - 1, {
					end_col = start_pos + #bold_text + 3,
					hl_group = "MarkdownBold",
				})
			end
		end

		-- Italic
		for italic_text in line:gmatch("%*([^*]+)%*") do
			local start_pos = line:find("%*" .. italic_text .. "%*", 1, true)
			if start_pos then
				pcall(vim.api.nvim_buf_set_extmark, buffer, current_state.ns, line_num, start_pos - 1, {
					end_col = start_pos + #italic_text + 1,
					hl_group = "MarkdownItalic",
				})
			end
		end

		-- Code
		for code_text in line:gmatch("`([^`]+)`") do
			local start_pos = line:find("`" .. code_text .. "`", 1, true)
			if start_pos then
				pcall(vim.api.nvim_buf_set_extmark, buffer, current_state.ns, line_num, start_pos - 1, {
					end_col = start_pos + #code_text + 1,
					hl_group = "MarkdownCode",
				})
			end
		end

		-- Links
		for link_text, link_url in line:gmatch("%[([^%]]+)%]%(([^)]+)%)") do
			local start_pos = line:find("%[" .. link_text .. "%]%(" .. link_url .. "%)", 1, true)
			if start_pos then
				pcall(vim.api.nvim_buf_set_extmark, buffer, current_state.ns, line_num, start_pos - 1, {
					end_col = start_pos + #link_text + #link_url + 3,
					hl_group = "MarkdownLink",
				})
			end
		end

		-- Blockquote
		if line:match("^>%s") then
			pcall(vim.api.nvim_buf_set_extmark, buffer, current_state.ns, line_num, 0, {
				end_col = 2,
				hl_group = "MarkdownBlockquote",
			})
		end

		-- Horizontal rule
		if line:match("^%-%-%-%s*$") or line:match("^%*%*%*%s*$") then
			pcall(vim.api.nvim_buf_set_extmark, buffer, current_state.ns, line_num, 0, {
				end_col = #line,
				hl_group = "MarkdownHr",
				virt_text = { { string.rep("─", vim.o.columns), "MarkdownHr" } },
				virt_text_pos = "overlay",
			})
		end
	end

	local render_time = (vim.uv.hrtime() - timing_start) / 1e6
	current_state.last_render_ms = render_time

	return render_time
end

-- ============================================================================
-- Preview Window
-- ============================================================================

function markdown_plugin.open_preview(source_buffer)
	if not markdown_plugin.config.preview.enabled then
		return
	end

	local current_state = get_state()

	if current_state.preview_wins[source_buffer] then
		local existing_window = current_state.preview_wins[source_buffer]
		if vim.api.nvim_win_is_valid(existing_window) then
			return
		end
	end

	local preview_buffer = vim.api.nvim_create_buf(false, true)
	vim.bo[preview_buffer].buftype = "nofile"
	vim.bo[preview_buffer].bufhidden = "wipe"
	vim.bo[preview_buffer].filetype = "markdown"

	current_state.preview_bufs[source_buffer] = preview_buffer

	local split_cmd
	if markdown_plugin.config.preview.position == "right" then
		local split_width = math.floor(vim.o.columns * markdown_plugin.config.preview.width / 100)
		split_cmd = string.format("botright vertical %dvnew", split_width)
	else
		split_cmd = string.format("botright %dnew", markdown_plugin.config.preview.height)
	end

	vim.cmd(split_cmd)
	local preview_window = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(preview_window, preview_buffer)

	vim.wo[preview_window].wrap = true
	vim.wo[preview_window].number = false
	vim.wo[preview_window].relativenumber = false
	vim.wo[preview_window].signcolumn = "no"

	current_state.preview_wins[source_buffer] = preview_window

	local success, source_window = pcall(vim.fn.winbufwin, source_buffer)
	if success and source_window > 0 then
		vim.api.nvim_set_current_win(source_window)
	end

	markdown_plugin.update_preview(source_buffer)
end

function markdown_plugin.close_preview(source_buffer)
	local current_state = get_state()
	local preview_window = current_state.preview_wins[source_buffer]
	if preview_window and vim.api.nvim_win_is_valid(preview_window) then
		vim.api.nvim_win_close(preview_window, true)
	end
	current_state.preview_wins[source_buffer] = nil
	current_state.preview_bufs[source_buffer] = nil
end

function markdown_plugin.toggle_preview(source_buffer)
	local current_state = get_state()
	if current_state.preview_wins[source_buffer] then
		markdown_plugin.close_preview(source_buffer)
	else
		markdown_plugin.open_preview(source_buffer)
	end
end

function markdown_plugin.update_preview(source_buffer)
	local current_state = get_state()
	local preview_buffer = current_state.preview_bufs[source_buffer]
	if not preview_buffer or not vim.api.nvim_buf_is_valid(preview_buffer) then
		return
	end
	local source_lines = vim.api.nvim_buf_get_lines(source_buffer, 0, -1, false)
	vim.api.nvim_buf_set_lines(preview_buffer, 0, -1, false, source_lines)
	render_buffer(preview_buffer)
end

-- ============================================================================
-- Setup
-- ============================================================================

function markdown_plugin.setup(opts)
	markdown_plugin.config = vim.tbl_deep_extend("force", markdown_plugin.config, opts or {})
	setup_highlights()

	local augroup = vim.api.nvim_create_augroup("RendererMarkdown", { clear = true })

	-- Render on file open
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		pattern = { "*.md", "*.markdown" },
		callback = function(event)
			render_buffer(event.buf)
		end,
	})

	-- Render on changes
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = augroup,
		pattern = { "*.md", "*.markdown" },
		callback = function(event)
			local current_state = get_state()
			if current_state.timers[event.buf] then
				current_state.timers[event.buf]:stop()
			end
			current_state.timers[event.buf] = vim.defer_fn(function()
				render_buffer(event.buf)
				markdown_plugin.update_preview(event.buf)
			end, markdown_plugin.config.debounce_ms)
		end,
	})

	-- Sync scroll
	if markdown_plugin.config.preview.sync_scroll then
		vim.api.nvim_create_autocmd("CursorMoved", {
			group = augroup,
			pattern = { "*.md", "*.markdown" },
			callback = function(event)
				local current_state = get_state()
				local preview_window = current_state.preview_wins[event.buf]
				if not preview_window or not vim.api.nvim_win_is_valid(preview_window) then
					return
				end
				local success, source_window = pcall(vim.fn.winbufwin, event.buf)
				if not success or source_window <= 0 then
					return
				end
				local cursor_pos = vim.api.nvim_win_get_cursor(source_window)
				local preview_buffer = current_state.preview_bufs[event.buf]
				local max_line = vim.api.nvim_buf_line_count(preview_buffer)
				pcall(vim.api.nvim_win_set_cursor, preview_window, { math.min(cursor_pos[1], max_line), 0 })
			end,
		})
	end

	-- Cleanup
	vim.api.nvim_create_autocmd("BufDelete", {
		group = augroup,
		callback = function(event)
			markdown_plugin.close_preview(event.buf)
			local current_state = get_state()
			current_state.timers[event.buf] = nil
		end,
	})

	-- Commands
	vim.api.nvim_create_user_command("MarkdownPreview", function()
		markdown_plugin.open_preview(vim.api.nvim_get_current_buf())
	end, {})

	vim.api.nvim_create_user_command("MarkdownPreviewClose", function()
		markdown_plugin.close_preview(vim.api.nvim_get_current_buf())
	end, {})

	vim.api.nvim_create_user_command("MarkdownPreviewToggle", function()
		markdown_plugin.toggle_preview(vim.api.nvim_get_current_buf())
	end, {})
end

return markdown_plugin
