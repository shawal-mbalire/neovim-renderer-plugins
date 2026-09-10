---
--- Image Renderer Plugin
--- Nested Hexagonal Architecture
--- Entry point - Composition Root
---

local timing_utils = require("shared.utils.timing")
local image_models = require("renderer-image.domain.models.types")
local image_renderer_adapter = require("renderer-image.adapters.renderer")

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
-- Highlight Groups
-- ============================================================================

local function ensure_highlights()
	pcall(vim.api.nvim_set_hl, 0, "RendererImageHeader", { link = "Title", default = true })
	pcall(vim.api.nvim_set_hl, 0, "RendererImageInfo", { link = "Comment", default = true })
end

-- ============================================================================
-- Buffer Renderer
-- ============================================================================

local function render_image_buffer(buffer)
	local timing_start = timing_utils.start()

	if not vim.api.nvim_buf_is_valid(buffer) then
		return 0
	end

	local file_path = vim.api.nvim_buf_get_name(buffer)
	if not file_path or not image_models.is_image_file(file_path) then
		return 0
	end

	ensure_highlights()

	local file_size = vim.fn.getfsize(file_path)
	local file_name = vim.fn.fnamemodify(file_path, ":t")
	local terminal = image_renderer_adapter.get_terminal_info()

	local display_lines = {
		string.format("=== Image: %s ===", file_name),
		"",
		string.format("File: %s", file_path),
		string.format("Size: %s", image_models.format_file_size(file_size)),
		string.format("Terminal: %s", terminal.protocol),
		string.format("Protocols: %s", table.concat(terminal.supported, ", ")),
	}

	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, display_lines)
	vim.bo[buffer].filetype = "image"
	vim.bo[buffer].modifiable = false

	local buf_ns = vim.api.nvim_create_namespace("renderer_image_display")
	vim.api.nvim_buf_clear_namespace(buffer, buf_ns, 0, -1)

	pcall(vim.api.nvim_buf_set_extmark, buffer, buf_ns, 0, 0, {
		end_col = #display_lines[1],
		hl_group = "RendererImageHeader",
	})

	image_renderer_adapter.render(file_path)

	local render_time = timing_utils.stop(timing_start)

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

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.bmp", "*.tiff" },
		callback = function(event)
			render_image_buffer(event.buf)
		end,
	})

	vim.api.nvim_create_user_command("ImageShow", function()
		local file_path = vim.fn.expand("%:p")
		image_renderer_adapter.render(file_path)
	end, {})

	vim.api.nvim_create_user_command("ImageInfo", function()
		local file_path = vim.fn.expand("%:p")
		local terminal = image_renderer_adapter.get_terminal_info()
		local info = {
			string.format("File: %s", file_path),
			string.format("Terminal: %s", terminal.protocol),
			string.format("Protocols: %s", table.concat(terminal.supported, ", ")),
			string.format("Last render: %.2f ms", image_renderer_adapter.get_last_render_time()),
		}
		vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
	end, {})
end

return image_plugin
