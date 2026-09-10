---
--- ipynb Renderer Plugin
--- Nested Hexagonal Architecture
--- Entry point - Composition Root
---

local timing_utils = require("shared.utils.timing")
local ipynb_models = require("renderer-ipynb.domain.models.types")
local ipynb_renderer_adapter = require("renderer-ipynb.adapters.renderer")

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

local plugin_state = nil

local function get_state()
	if plugin_state then
		return plugin_state
	end
	plugin_state = {
		timers = {},
		selected_kernel = nil,
		last_render_ms = 0,
	}
	return plugin_state
end

-- ============================================================================
-- Kernel Selection
-- ============================================================================

local function select_kernel(notebook_metadata)
	if not ipynb_plugin.config.auto_select_kernel then
		return
	end

	local detected = ipynb_models.detect_kernel(notebook_metadata)
	local current_state = get_state()

	if detected then
		current_state.selected_kernel = detected
	else
		vim.defer_fn(function()
			local kernels = ipynb_models.get_kernel_definitions()
			local display_strings = {}
			for i, kernel in ipairs(kernels) do
				local prefix = kernel.recommended and "★ " or "  "
				display_strings[i] = prefix .. kernel.display_name
			end

			vim.ui.select(display_strings, {
				prompt = "Select Jupyter Kernel:",
			}, function(selected_index)
				if selected_index and kernels[selected_index] then
					current_state.selected_kernel = kernels[selected_index]
					vim.notify(
						string.format("[ipynb] Kernel: %s", current_state.selected_kernel.display_name),
						vim.log.levels.INFO
					)
				end
			end)
		end, 100)
	end
end

-- ============================================================================
-- Render
-- ============================================================================

local function render_buffer(buffer)
	local timing_start = timing_utils.start()

	if not vim.api.nvim_buf_is_valid(buffer) then
		return 0
	end

	local render_time = ipynb_renderer_adapter.render(buffer)

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

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		pattern = "*.ipynb",
		callback = function(event)
			-- Parse notebook for kernel detection
			local content = table.concat(vim.api.nvim_buf_get_lines(event.buf, 0, -1, false), "\n")
			local success, notebook = pcall(vim.fn.json_decode, content)
			if success and notebook then
				select_kernel(notebook.metadata)
			end
			render_buffer(event.buf)
		end,
	})

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

	vim.api.nvim_create_autocmd("BufDelete", {
		group = augroup,
		callback = function(event)
			local current_state = get_state()
			current_state.timers[event.buf] = nil
		end,
	})

	vim.api.nvim_create_user_command("IpynbRender", function()
		render_buffer(vim.api.nvim_get_current_buf())
	end, {})

	vim.api.nvim_create_user_command("IpynbEdit", function()
		local buffer = vim.api.nvim_get_current_buf()
		vim.bo[buffer].modifiable = true
		vim.bo[buffer].filetype = "json"
		vim.notify("[ipynb] Edit mode", vim.log.levels.INFO)
	end, {})

	vim.api.nvim_create_user_command("IpynbSelectKernel", function()
		local current_buffer = vim.api.nvim_get_current_buf()
		local content = table.concat(vim.api.nvim_buf_get_lines(current_buffer, 0, -1, false), "\n")
		local success, notebook = pcall(vim.fn.json_decode, content)
		if success and notebook then
			select_kernel(notebook.metadata)
		else
			select_kernel(nil)
		end
	end, {})

	vim.api.nvim_create_user_command("IpynbShowKernels", function()
		local kernels = ipynb_models.get_kernel_definitions()
		local kernel_list = {}
		for _, kernel in ipairs(kernels) do
			local marker = kernel.recommended and "★" or " "
			kernel_list[#kernel_list + 1] = string.format("%s %s", marker, kernel.display_name)
		end
		vim.notify("Kernels:\n" .. table.concat(kernel_list, "\n"), vim.log.levels.INFO)
	end, {})
end

return ipynb_plugin
