---
--- E2E Test: Markdown Rendering
--- Tests actual markdown rendering with various syntax
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

	local function create_buffer(lines)
		local buffer = vim.api.nvim_create_buf(true, true)
		vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
		vim.bo[buffer].filetype = "markdown"
		return buffer
	end

	local function get_content(buffer)
		return table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
	end

	local function cleanup(buffer)
		pcall(function()
			vim.api.nvim_buf_delete(buffer, { force = true })
		end)
	end

	-- Test: Headings
	test("render headings", function()
		local plugin = require("renderer-markdown")
		plugin.setup({ show_render_time = false, preview = { auto_open = false } })

		local buffer = create_buffer({
			"# Heading 1",
			"## Heading 2",
			"### Heading 3",
			"#### Heading 4",
			"##### Heading 5",
			"###### Heading 6",
		})

		local content = get_content(buffer)
		assert(content:find("Heading 1"), "Should contain h1")
		assert(content:find("Heading 2"), "Should contain h2")
		assert(content:find("Heading 6"), "Should contain h6")
		cleanup(buffer)
	end)

	-- Test: Bold and Italic
	test("render bold and italic", function()
		local plugin = require("renderer-markdown")
		plugin.setup({ show_render_time = false, preview = { auto_open = false } })

		local buffer = create_buffer({
			"This is **bold text**",
			"This is *italic text*",
			"This is ***bold and italic***",
			"This is ~~strikethrough~~",
		})

		local content = get_content(buffer)
		assert(content:find("bold text"), "Should contain bold text")
		assert(content:find("italic text"), "Should contain italic text")
		assert(content:find("strikethrough"), "Should contain strikethrough")
		cleanup(buffer)
	end)

	-- Test: Code blocks
	test("render code blocks", function()
		local plugin = require("renderer-markdown")
		plugin.setup({ show_render_time = false, preview = { auto_open = false } })

		local buffer = create_buffer({
			"Inline `code` here",
			"",
			"```lua",
			"local x = 1",
			"print(x)",
			"```",
		})

		local content = get_content(buffer)
		assert(content:find("code"), "Should contain inline code")
		assert(content:find("local x = 1"), "Should contain code block")
		cleanup(buffer)
	end)

	-- Test: Links
	test("render links", function()
		local plugin = require("renderer-markdown")
		plugin.setup({ show_render_time = false, preview = { auto_open = false } })

		local buffer = create_buffer({
			"[GitHub](https://github.com)",
			"![Image](image.png)",
		})

		local content = get_content(buffer)
		assert(content:find("GitHub"), "Should contain link text")
		assert(content:find("https://github.com"), "Should contain URL")
		assert(content:find("Image"), "Should contain image alt")
		cleanup(buffer)
	end)

	-- Test: Lists
	test("render lists", function()
		local plugin = require("renderer-markdown")
		plugin.setup({ show_render_time = false, preview = { auto_open = false } })

		local buffer = create_buffer({
			"- Item 1",
			"- Item 2",
			"- Item 3",
			"",
			"1. First",
			"2. Second",
			"3. Third",
		})

		local content = get_content(buffer)
		assert(content:find("Item 1"), "Should contain list item")
		assert(content:find("First"), "Should contain ordered list item")
		cleanup(buffer)
	end)

	-- Test: Task lists
	test("render task lists", function()
		local plugin = require("renderer-markdown")
		plugin.setup({ show_render_time = false, preview = { auto_open = false } })

		local buffer = create_buffer({
			"- [x] Completed task",
			"- [ ] Incomplete task",
			"- [x] Another completed",
		})

		local content = get_content(buffer)
		assert(content:find("Completed task"), "Should contain completed task")
		assert(content:find("Incomplete task"), "Should contain incomplete task")
		cleanup(buffer)
	end)

	-- Test: Blockquotes
	test("render blockquotes", function()
		local plugin = require("renderer-markdown")
		plugin.setup({ show_render_time = false, preview = { auto_open = false } })

		local buffer = create_buffer({
			"> This is a blockquote",
			"> Multiple lines",
		})

		local content = get_content(buffer)
		assert(content:find("blockquote"), "Should contain blockquote text")
		cleanup(buffer)
	end)

	-- Test: Horizontal rule
	test("render horizontal rule", function()
		local plugin = require("renderer-markdown")
		plugin.setup({ show_render_time = false, preview = { auto_open = false } })

		local buffer = create_buffer({
			"Text before",
			"---",
			"Text after",
		})

		local content = get_content(buffer)
		assert(content:find("Text before"), "Should contain text before")
		assert(content:find("Text after"), "Should contain text after")
		cleanup(buffer)
	end)

	-- Test: Tables
	test("render tables", function()
		local plugin = require("renderer-markdown")
		plugin.setup({ show_render_time = false, preview = { auto_open = false } })

		local buffer = create_buffer({
			"| Header 1 | Header 2 |",
			"|----------|----------|",
			"| Cell 1   | Cell 2   |",
			"| Cell 3   | Cell 4   |",
		})

		local content = get_content(buffer)
		assert(content:find("Header 1"), "Should contain table header")
		assert(content:find("Cell 1"), "Should contain table cell")
		cleanup(buffer)
	end)

	-- Test: Mixed content
	test("render mixed content", function()
		local plugin = require("renderer-markdown")
		plugin.setup({ show_render_time = false, preview = { auto_open = false } })

		local buffer = create_buffer({
			"# Title",
			"",
			"This is a paragraph with **bold** and *italic*.",
			"",
			"```python",
			"def hello():",
			"    print('world')",
			"```",
			"",
			"> Blockquote",
			"",
			"- List item",
		})

		local content = get_content(buffer)
		assert(content:find("Title"), "Should contain title")
		assert(content:find("bold"), "Should contain bold")
		assert(content:find("italic"), "Should contain italic")
		assert(content:find("def hello"), "Should contain code")
		assert(content:find("Blockquote"), "Should contain blockquote")
		cleanup(buffer)
	end)

	-- Print results with timing
	local total_time = stop_timing(total_start)

	print("\n=== Markdown Rendering Tests ===")
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
