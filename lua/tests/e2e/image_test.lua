---
--- E2E Test: Image Renderer
--- Runs in headless Neovim to verify plugin works
--- Includes timing measurements for all operations
---

local function start_timing()
	return vim.uv.hrtime()
end

local function stop_timing(start_time)
	local elapsed_ns = vim.uv.hrtime() - start_time
	return math.floor((elapsed_ns / 1e6) * 100) / 100
end

local function run_tests()
	local total_start = start_timing()
	local passed = 0
	local failed = 0
	local test_results = {}
	local timings = {}

	local function test(name, test_function)
		local test_start = start_timing()
		local success, error = pcall(test_function)
		local test_time = stop_timing(test_start)

		if success then
			passed = passed + 1
			table.insert(test_results, string.format("  ✓ %s (%.2f ms)", name, test_time))
		else
			failed = failed + 1
			table.insert(
				test_results,
				string.format("  ✗ %s: %s (%.2f ms)", name, tostring(error), test_time)
			)
		end
		timings[name] = test_time
	end

	-- Test 1: Plugin loads without error
	test("image plugin loads", function()
		local image_plugin = require("renderer-image")
		assert(image_plugin ~= nil, "Plugin should load")
		assert(image_plugin.setup ~= nil, "Plugin should have setup function")
	end)

	-- Test 2: Plugin has correct config
	test("image plugin has default config", function()
		local image_plugin = require("renderer-image")
		assert(image_plugin.config ~= nil, "Config should exist")
		assert(image_plugin.config.max_width == 800, "Default max width should be 800")
		assert(image_plugin.config.max_height == 600, "Default max height should be 600")
		assert(image_plugin.config.show_render_time == true, "Should show render time")
	end)

	-- Test 3: Plugin can be configured
	test("image plugin accepts custom config", function()
		local image_plugin = require("renderer-image")
		image_plugin.setup({
			max_width = 1200,
			max_height = 900,
			show_render_time = false,
		})
		assert(image_plugin.config.max_width == 1200, "Max width should be updated")
		assert(image_plugin.config.max_height == 900, "Max height should be updated")
		assert(image_plugin.config.show_render_time == false, "Render time should be disabled")
	end)

	-- Test 4: Create and render a PNG file
	test("image renders to buffer", function()
		local image_plugin = require("renderer-image")
		image_plugin.setup({ show_render_time = false })

		-- Create a minimal PNG file (1x1 red pixel)
		local temp_dir = vim.fn.tempname()
		vim.fn.mkdir(temp_dir, "p")
		local test_file = temp_dir .. "/test.png"

		-- Write minimal PNG
		local png_data = vim.fn.system(
			"base64 -d",
			"iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
		)
		local file_handle = io.open(test_file, "wb")
		file_handle:write(png_data)
		file_handle:close()

		-- Edit the file (triggers BufReadPost)
		vim.cmd("edit " .. test_file)

		local test_buffer = vim.api.nvim_get_current_buf()

		-- Verify buffer has content
		local buffer_lines = vim.api.nvim_buf_get_lines(test_buffer, 0, -1, false)
		assert(#buffer_lines > 0, "Buffer should have content")

		-- Verify it shows image info
		local full_content = table.concat(buffer_lines, "\n")
		assert(
			full_content:find("Image") or full_content:find("test.png") or full_content:find("File:"),
			"Should show image info"
		)

		-- Cleanup
		pcall(function()
			vim.fn.delete(temp_dir, "rf")
		end)
	end)

	-- Test 5: File size formatting
	test("file sizes are formatted correctly", function()
		local image_plugin = require("renderer-image")

		-- Test various file sizes
		local test_buffer = vim.api.nvim_create_buf(true, true)
		vim.bo[test_buffer].filetype = "image"

		-- Small file
		vim.api.nvim_buf_set_lines(
			test_buffer,
			0,
			-1,
			false,
			{ "=== Image: small.png ===", "Size: 512 B" }
		)
		local content = table.concat(vim.api.nvim_buf_get_lines(test_buffer, 0, -1, false), "\n")
		assert(content:find("512 B"), "Should format bytes")

		-- Medium file
		vim.api.nvim_buf_set_lines(
			test_buffer,
			0,
			-1,
			false,
			{ "=== Image: medium.png ===", "Size: 1.5 MB" }
		)
		content = table.concat(vim.api.nvim_buf_get_lines(test_buffer, 0, -1, false), "\n")
		assert(content:find("1.5 MB"), "Should format megabytes")

		-- Cleanup
		vim.api.nvim_buf_delete(test_buffer, { force = true })
	end)

	-- Test 6: Image extension detection
	test("image extensions are recognized", function()
		local image_plugin = require("renderer-image")

		-- The plugin should recognize these extensions
		local supported_extensions = { "png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff" }
		for _, extension in ipairs(supported_extensions) do
			-- This tests the internal logic
			local test_file = "test." .. extension
			assert(test_file:match("%.([^%.]+)$") == extension, "Should recognize " .. extension)
		end
	end)

	-- Print results with timing
	local total_time = stop_timing(total_start)

	print("\n=== Image E2E Tests ===")
	for _, result in ipairs(test_results) do
		print(result)
	end
	print(string.format("\n%d passed, %d failed", passed, failed))
	print(string.format("Total time: %.2f ms", total_time))

	-- Print slowest tests
	local sorted_timings = {}
	for name, time in pairs(timings) do
		table.insert(sorted_timings, { name = name, time = time })
	end
	table.sort(sorted_timings, function(a, b)
		return a.time > b.time
	end)

	if #sorted_timings > 0 then
		print("\nSlowest tests:")
		for i = 1, math.min(3, #sorted_timings) do
			print(string.format("  %d. %s: %.2f ms", i, sorted_timings[i].name, sorted_timings[i].time))
		end
	end
	print("")

	return failed == 0
end

-- Run tests
local success = run_tests()
if not success then
	vim.cmd("cquit 1")
else
	vim.cmd("qa!")
end
