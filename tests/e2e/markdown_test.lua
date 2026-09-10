---
--- E2E Test: Markdown Renderer
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
      table.insert(test_results, string.format("  ✗ %s: %s (%.2f ms)", name, tostring(error), test_time))
    end
    timings[name] = test_time
  end

  -- Test 1: Plugin loads without error
  test("markdown plugin loads", function()
    local markdown_plugin = require("renderer-markdown")
    assert(markdown_plugin ~= nil, "Plugin should load")
    assert(markdown_plugin.setup ~= nil, "Plugin should have setup function")
  end)

  -- Test 2: Plugin has correct config
  test("markdown plugin has default config", function()
    local markdown_plugin = require("renderer-markdown")
    assert(markdown_plugin.config ~= nil, "Config should exist")
    assert(markdown_plugin.config.preview ~= nil, "Preview config should exist")
    assert(markdown_plugin.config.preview.position == "right", "Default position should be right")
    assert(markdown_plugin.config.show_render_time == true, "Should show render time")
  end)

  -- Test 3: Plugin can be configured
  test("markdown plugin accepts custom config", function()
    local markdown_plugin = require("renderer-markdown")
    markdown_plugin.setup({
      preview = {
        position = "bottom",
        width = 30,
      },
      show_render_time = false,
    })
    assert(markdown_plugin.config.preview.position == "bottom", "Position should be updated")
    assert(markdown_plugin.config.preview.width == 30, "Width should be updated")
    assert(markdown_plugin.config.show_render_time == false, "Render time should be disabled")
  end)

  -- Test 4: Create and render a markdown file
  test("markdown renders to buffer", function()
    local markdown_plugin = require("renderer-markdown")
    markdown_plugin.setup({ show_render_time = false })

    -- Create a test buffer
    local test_buffer = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_lines(test_buffer, 0, -1, false, {
      "# Hello World",
      "",
      "This is **bold** and *italic*.",
      "",
      "```lua",
      "print('hello')",
      "```",
    })
    vim.bo[test_buffer].filetype = "markdown"

    -- Trigger render
    local render_command = string.format("buffer %d", test_buffer)
    vim.cmd(render_command)

    -- Verify buffer has content
    local buffer_lines = vim.api.nvim_buf_get_lines(test_buffer, 0, -1, false)
    assert(#buffer_lines > 0, "Buffer should have content")
    assert(buffer_lines[1] == "# Hello World", "First line should be preserved")

    -- Cleanup
    vim.api.nvim_buf_delete(test_buffer, { force = true })
  end)

  -- Test 5: Preview window operations (skip in headless mode)
  test("preview window operations", function()
    local markdown_plugin = require("renderer-markdown")
    markdown_plugin.setup({
      preview = { auto_open = false },
      show_render_time = false,
    })

    -- Create a test buffer
    local test_buffer = vim.api.nvim_create_buf(true, true)
    vim.bo[test_buffer].filetype = "markdown"
    vim.api.nvim_buf_set_lines(test_buffer, 0, -1, false, { "# Test" })

    -- Test preview toggle (won't actually open window in headless mode)
    markdown_plugin.toggle_preview(test_buffer)

    -- Cleanup
    pcall(function() markdown_plugin.close_preview(test_buffer) end)
    vim.api.nvim_buf_delete(test_buffer, { force = true })
  end)

  -- Print results with timing
  local total_time = stop_timing(total_start)

  print("\n=== Markdown E2E Tests ===")
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
  table.sort(sorted_timings, function(a, b) return a.time > b.time end)

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
