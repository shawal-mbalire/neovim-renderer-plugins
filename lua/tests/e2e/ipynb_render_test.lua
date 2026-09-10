---
--- E2E Test: ipynb Rendering
--- Tests actual notebook rendering with various cell types
--- Includes timing measurements
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

	local function create_notebook(cells, metadata)
		local notebook = {
			cells = cells,
			metadata = metadata or {
				kernelspec = {
					display_name = "Python 3",
					language = "python",
					name = "python3",
				},
				language_info = {
					name = "python",
					version = "3.9.7",
				},
			},
			nbformat = 4,
			nbformat_minor = 5,
		}
		-- Pretty print JSON with newlines
		local json = vim.fn.json_encode(notebook)
		json = json:gsub("{", "{\n")
		json = json:gsub("}", "\n}")
		json = json:gsub(",", ",\n")
		return json
	end

	local function create_buffer(cells, metadata)
		local plugin = require("renderer-ipynb")
		plugin.setup({ show_render_time = false, auto_select_kernel = true })

		local notebook_json = create_notebook(cells, metadata)

		-- Create temp file with .ipynb extension
		local temp_dir = vim.fn.tempname()
		vim.fn.mkdir(temp_dir, "p")
		local file_path = temp_dir .. "/test.ipynb"

		local file_handle = io.open(file_path, "w")
		file_handle:write(notebook_json)
		file_handle:close()

		-- Edit the file (triggers BufReadPost)
		vim.cmd("edit " .. file_path)

		local buffer = vim.api.nvim_get_current_buf()
		return buffer, temp_dir
	end

	local function get_content(buffer)
		return table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
	end

	local function cleanup(buffer)
		pcall(function()
			vim.api.nvim_buf_delete(buffer, { force = true })
		end)
	end

	-- Test: Markdown cells
	test("render markdown cells", function()
		local buffer = create_buffer({
			{
				cell_type = "markdown",
				source = { "# Title", "", "This is a paragraph." },
				metadata = {},
			},
		})

		local content = get_content(buffer)
		assert(content:find("Jupyter Notebook"), "Should contain notebook header")
		assert(content:find("Cell 1"), "Should contain cell header")
		assert(content:find("# Title"), "Should contain markdown content")
		cleanup(buffer)
	end)

	-- Test: Code cells with stream output
	test("render code cells with stream output", function()
		local buffer = create_buffer({
			{
				cell_type = "code",
				source = { "print('hello')" },
				outputs = {
					{
						output_type = "stream",
						name = "stdout",
						text = { "hello\n" },
					},
				},
				execution_count = 1,
				metadata = {},
			},
		})

		local content = get_content(buffer)
		assert(content:find("Cell 1: CODE"), "Should contain code cell header")
		assert(content:find("print"), "Should contain code")
		assert(content:find("Output"), "Should contain output header")
		assert(content:find("hello"), "Should contain output text")
		cleanup(buffer)
	end)

	-- Test: Code cells with execute_result
	test("render code cells with execute_result", function()
		local buffer = create_buffer({
			{
				cell_type = "code",
				source = { "42" },
				outputs = {
					{
						output_type = "execute_result",
						data = {
							["text/plain"] = { "42" },
						},
						execution_count = 1,
						metadata = {},
					},
				},
				execution_count = 1,
				metadata = {},
			},
		})

		local content = get_content(buffer)
		assert(content:find("42"), "Should contain result")
		cleanup(buffer)
	end)

	-- Test: Code cells with error output
	test("render code cells with error output", function()
		local buffer = create_buffer({
			{
				cell_type = "code",
				source = { "1/0" },
				outputs = {
					{
						output_type = "error",
						ename = "ZeroDivisionError",
						evalue = "division by zero",
						traceback = { "Traceback: ZeroDivisionError" },
					},
				},
				execution_count = 1,
				metadata = {},
			},
		})

		local content = get_content(buffer)
		assert(content:find("ZeroDivisionError"), "Should contain error name")
		assert(content:find("division by zero"), "Should contain error message")
		cleanup(buffer)
	end)

	-- Test: Multiple cells
	test("render multiple cells", function()
		local buffer = create_buffer({
			{
				cell_type = "markdown",
				source = { "# Data Analysis" },
				metadata = {},
			},
			{
				cell_type = "code",
				source = { "import pandas as pd" },
				outputs = {},
				execution_count = 1,
				metadata = {},
			},
			{
				cell_type = "code",
				source = { "df.head()" },
				outputs = {
					{
						output_type = "execute_result",
						data = {
							["text/plain"] = { "   a  b\n0  1  3\n1  2  4" },
						},
						execution_count = 2,
						metadata = {},
					},
				},
				execution_count = 2,
				metadata = {},
			},
		})

		local content = get_content(buffer)
		assert(content:find("Cell 1: MARKDOWN"), "Should contain markdown cell")
		assert(content:find("Cell 2: CODE"), "Should contain code cell")
		assert(content:find("Cell 3: CODE"), "Should contain second code cell")
		assert(content:find("Data Analysis"), "Should contain markdown content")
		assert(content:find("pandas"), "Should contain import statement")
		assert(content:find("df.head"), "Should contain second code")
		cleanup(buffer)
	end)

	-- Test: Execution count display
	test("display execution counts", function()
		local buffer = create_buffer({
			{
				cell_type = "code",
				source = { "x = 1" },
				outputs = {},
				execution_count = 5,
				metadata = {},
			},
		})

		local content = get_content(buffer)
		assert(content:find("[5]"), "Should contain execution count")
		cleanup(buffer)
	end)

	-- Test: Image output
	test("render image output", function()
		local buffer = create_buffer({
			{
				cell_type = "code",
				source = { "plt.show()" },
				outputs = {
					{
						output_type = "display_data",
						data = {
							["image/png"] = "base64data",
						},
						metadata = {},
					},
				},
				execution_count = 1,
				metadata = {},
			},
		})

		local content = get_content(buffer)
		assert(content:find("Image"), "Should contain image placeholder")
		cleanup(buffer)
	end)

	-- Print results with timing
	local total_time = stop_timing(total_start)

	print("\n=== ipynb Rendering Tests ===")
	for _, result in ipairs(test_results) do
		print(result)
	end
	print(string.format("\n%d passed, %d failed", passed, failed))
	print(string.format("Total time: %.2f ms", total_time))

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

local success = run_tests()
if not success then
	vim.cmd("cquit 1")
else
	vim.cmd("qa!")
end
