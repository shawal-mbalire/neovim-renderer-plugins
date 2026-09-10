---
--- E2E Test: ipynb Renderer
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
  test("ipynb plugin loads", function()
    local ipynb_plugin = require("renderer-ipynb")
    assert(ipynb_plugin ~= nil, "Plugin should load")
    assert(ipynb_plugin.setup ~= nil, "Plugin should have setup function")
  end)

  -- Test 2: Plugin has correct config
  test("ipynb plugin has default config", function()
    local ipynb_plugin = require("renderer-ipynb")
    assert(ipynb_plugin.config ~= nil, "Config should exist")
    assert(ipynb_plugin.config.show_execution_count == true, "Should show execution count")
    assert(ipynb_plugin.config.show_render_time == true, "Should show render time")
    assert(ipynb_plugin.config.auto_select_kernel == true, "Should auto-select kernel")
  end)

  -- Test 3: Plugin can be configured
  test("ipynb plugin accepts custom config", function()
    local ipynb_plugin = require("renderer-ipynb")
    ipynb_plugin.setup({
      show_execution_count = false,
      show_render_time = false,
      auto_select_kernel = false,
    })
    assert(ipynb_plugin.config.show_execution_count == false, "Execution count should be disabled")
    assert(ipynb_plugin.config.show_render_time == false, "Render time should be disabled")
    assert(ipynb_plugin.config.auto_select_kernel == false, "Auto kernel should be disabled")
  end)

  -- Test 4: Create and render an ipynb file
  test("ipynb renders to buffer", function()
    local ipynb_plugin = require("renderer-ipynb")
    ipynb_plugin.setup({
      show_render_time = false,
      auto_select_kernel = false,
    })

    -- Create a test notebook JSON
    local notebook_json = vim.fn.json_encode({
      cells = {
        {
          cell_type = "markdown",
          source = { "# Test Notebook" },
          metadata = {},
        },
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
      },
      metadata = {
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
    })

    -- Create a test buffer
    local test_buffer = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_lines(test_buffer, 0, -1, false, vim.split(notebook_json, "\n"))
    vim.bo[test_buffer].filetype = "ipynb"

    -- Switch to buffer to trigger BufReadPost autocmd
    local render_command = string.format("buffer %d", test_buffer)
    vim.cmd(render_command)

    -- Verify buffer has content
    local buffer_lines = vim.api.nvim_buf_get_lines(test_buffer, 0, -1, false)
    assert(#buffer_lines > 0, "Buffer should have content")

    -- Verify it contains notebook elements
    local full_content = table.concat(buffer_lines, "\n")
    assert(full_content:find("Jupyter Notebook"), "Should contain notebook header")
    assert(full_content:find("Cell 1"), "Should contain cell headers")

    -- Cleanup
    vim.api.nvim_buf_delete(test_buffer, { force = true })
  end)

  -- Test 5: Kernel detection
  test("kernel is detected from notebook", function()
    local ipynb_plugin = require("renderer-ipynb")
    ipynb_plugin.setup({
      show_render_time = false,
      auto_select_kernel = true,
    })

    -- Create a notebook with Python kernel
    local notebook_json = vim.fn.json_encode({
      cells = {},
      metadata = {
        kernelspec = {
          display_name = "Python 3",
          language = "python",
          name = "python3",
        },
      },
      nbformat = 4,
      nbformat_minor = 5,
    })

    local test_buffer = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_lines(test_buffer, 0, -1, false, vim.split(notebook_json, "\n"))

    -- Render
    local render_command = string.format("buffer %d", test_buffer)
    vim.cmd(render_command)

    -- Verify kernel info is displayed
    local buffer_lines = vim.api.nvim_buf_get_lines(test_buffer, 0, -1, false)
    local full_content = table.concat(buffer_lines, "\n")
    assert(full_content:find("Python 3"), "Should display detected kernel name")

    -- Cleanup
    vim.api.nvim_buf_delete(test_buffer, { force = true })
  end)

  -- Test 6: Error output rendering
  test("error outputs are rendered", function()
    local ipynb_plugin = require("renderer-ipynb")
    ipynb_plugin.setup({
      show_render_time = false,
      auto_select_kernel = false,
    })

    local notebook_json = vim.fn.json_encode({
      cells = {
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
      },
      metadata = {},
      nbformat = 4,
      nbformat_minor = 5,
    })

    local test_buffer = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_lines(test_buffer, 0, -1, false, vim.split(notebook_json, "\n"))

    local render_command = string.format("buffer %d", test_buffer)
    vim.cmd(render_command)

    local buffer_lines = vim.api.nvim_buf_get_lines(test_buffer, 0, -1, false)
    local full_content = table.concat(buffer_lines, "\n")
    assert(full_content:find("ZeroDivisionError"), "Should display error name")
    assert(full_content:find("division by zero"), "Should display error message")

    -- Cleanup
    vim.api.nvim_buf_delete(test_buffer, { force = true })
  end)

  -- Print results with timing
  local total_time = stop_timing(total_start)

  print("\n=== ipynb E2E Tests ===")
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
