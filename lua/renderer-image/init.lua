---
--- Image Renderer Plugin
--- TypeScript handles image protocol logic
---

local image_plugin = {}

-- ============================================================================
-- Configuration
-- ============================================================================

image_plugin.config = {
	max_width = 800,
	max_height = 600,
	debounce_ms = 100,
	show_render_time = true,
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
		ns = vim.api.nvim_create_namespace("renderer_image"),
		last_render_ms = 0,
		terminal = nil,
	}
	return state
end

-- ============================================================================
-- TypeScript Renderer Integration
-- ============================================================================

local function get_renderer_script()
	local paths = {
		"/Volumes/Samsung/GitHub/neovim-plugin/typescript/image/cli.ts",
	}
	for _, path in ipairs(paths) do
		if vim.fn.filereadable(path) == 1 then
			return path
		end
	end
	local rtp = vim.o.runtimepath
	for rtp_path in rtp:gmatch("[^,]+") do
		local cli_path = rtp_path .. "/typescript/image/cli.ts"
		if vim.fn.filereadable(cli_path) == 1 then
			return cli_path
		end
	end
	return ""
end

local function call_ts_renderer(file_path)
	local script_path = get_renderer_script()
	if script_path == "" then
		return nil
	end

	local json = vim.fn.json_encode({ type = "render", path = file_path })
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
-- Terminal Detection
-- ============================================================================

local function detect_terminal()
	local current_state = get_state()
	if current_state.terminal then
		return current_state.terminal
	end

	local term = os.getenv("TERM") or ""
	local term_program = os.getenv("TERM_PROGRAM") or ""
	local is_tmux = os.getenv("TMUX") ~= nil

	local supported = {}

	-- Kitty
	if term_program:lower():find("kitty") or term:lower():find("kitty") then
		if not is_tmux then
			supported[#supported + 1] = "kgp"
		end
		supported[#supported + 1] = "kgp_old"
	end

	-- IIP (iTerm2, WezTerm, etc.)
	local iip_terminals = { "iterm2", "wezterm", "warp", "vscode" }
	for _, terminal_name in ipairs(iip_terminals) do
		if term_program:lower():find(terminal_name) then
			supported[#supported + 1] = "iip"
			break
		end
	end

	-- Sixel
	if term:find("sixel") or term_program:lower():find("foot") then
		supported[#supported + 1] = "sixel"
	end

	current_state.terminal = {
		protocol = supported[1] or "none",
		supported = supported,
		tmux = is_tmux,
	}

	return current_state.terminal
end

-- ============================================================================
-- Fallback Renderer
-- ============================================================================

local function render_fallback(buffer, file_path)
	local timing_start = vim.uv.hrtime()

	if not vim.api.nvim_buf_is_valid(buffer) then
		return 0
	end

	local terminal = detect_terminal()
	local file_name = vim.fn.fnamemodify(file_path, ":t")
	local file_size = vim.fn.getfsize(file_path)

	local display_lines = {
		string.format("=== Image: %s ===", file_name),
		"",
		string.format("File: %s", file_path),
		string.format("Size: %s", format_file_size(file_size)),
		string.format("Terminal: %s", terminal.protocol),
		string.format("Protocols: %s", table.concat(terminal.supported, ", ")),
	}

	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, display_lines)
	vim.bo[buffer].filetype = "image"
	vim.bo[buffer].modifiable = false

	-- Apply highlight
	local ns = vim.api.nvim_create_namespace("renderer_image_display")
	pcall(vim.api.nvim_buf_set_extmark, buffer, ns, 0, 0, {
		end_col = #display_lines[1],
		hl_group = "Title",
	})

	return (vim.uv.hrtime() - timing_start) / 1e6
end

local function format_file_size(size_bytes)
	if size_bytes < 1024 then
		return string.format("%d B", size_bytes)
	elseif size_bytes < 1024 * 1024 then
		return string.format("%.1f KB", size_bytes / 1024)
	else
		return string.format("%.1f MB", size_bytes / (1024 * 1024))
	end
end

-- ============================================================================
-- Image File Detection
-- ============================================================================

local image_extensions = {
	png = true, jpeg = true, jpg = true, gif = true,
	webp = true, bmp = true, tiff = true,
}

local function is_image_file(file_path)
	local ext = file_path:match("%.([^%.]+)$")
	return ext and image_extensions[ext:lower()] or false
end

-- ============================================================================
-- Main Renderer
-- ============================================================================

local function render_image_buffer(buffer, file_path)
	if not vim.api.nvim_buf_is_valid(buffer) then
		return 0
	end

	local timing_start = vim.uv.hrtime()

	-- Try TypeScript renderer
	local result = call_ts_renderer(file_path)

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

		-- Replace buffer content
		if result.lines and #result.lines > 0 then
			local lines = {}
			for _, line_data in ipairs(result.lines) do
				lines[#lines + 1] = line_data.text or ""
			end
			vim.api.nvim_buf_set_option(buffer, "modifiable", true)
			vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
			vim.api.nvim_buf_set_option(buffer, "modifiable", false)
			vim.bo[buffer].filetype = "image"
		end

		render_time = (vim.uv.hrtime() - timing_start) / 1e6
	else
		-- Fallback
		render_time = render_fallback(buffer, file_path)
	end

	local current_state = get_state()
	current_state.last_render_ms = render_time

	if image_plugin.config.show_render_time then
		local status_msg = string.format("[image] %.2f ms", render_time)
		vim.api.nvim_echo({ { status_msg, "Comment" } }, false, {})
	end

	return render_time
end

-- ============================================================================
-- Setup
-- ============================================================================

function image_plugin.setup(opts)
	image_plugin.config = vim.tbl_deep_extend("force", image_plugin.config, opts or {})

	local augroup = vim.api.nvim_create_augroup("RendererImage", { clear = true })

	-- Render on file open
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.bmp", "*.tiff" },
		callback = function(event)
			local file_path = vim.api.nvim_buf_get_name(event.buf)
			if file_path and is_image_file(file_path) then
				render_image_buffer(event.buf, file_path)
			end
		end,
	})

	-- Commands
	vim.api.nvim_create_user_command("ImageShow", function()
		local file_path = vim.fn.expand("%:p")
		render_image_buffer(vim.api.nvim_get_current_buf(), file_path)
	end, {})

	vim.api.nvim_create_user_command("ImageInfo", function()
		local file_path = vim.fn.expand("%:p")
		local terminal = detect_terminal()
		local info = {
			string.format("File: %s", file_path),
			string.format("Terminal: %s", terminal.protocol),
			string.format("Protocols: %s", table.concat(terminal.supported, ", ")),
		}
		vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
	end, {})
end

return image_plugin
