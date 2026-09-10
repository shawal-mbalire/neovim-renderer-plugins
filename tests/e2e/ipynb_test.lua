---
--- E2E Test: ipynb Renderer
--- Runs in headless Neovim to verify plugin works
---

local function run_tests()
  local passed = 0
  local failed = 0
  local test_results = {}

  local function test(name, test_function)
    local success, error = pcall(test_function)
    if success then
      passed = passed + 1
      table.insert(test_results, string.format("  ✓ %s", name))
    else
      failed = failed + 1
      table.insert(test_results, string.format("  ✗ %s: %s", name, tostring(error)))
    end
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
    vim.bo[test_buffer].filetype = "json"

    -- Trigger render
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

  -- Print results
  print("\n=== ipynb E2E Tests ===")
  for _, result in ipairs(test_results) do
    print(result)
  end
  print(string.format("\n%d passed, %d failed\n", passed, failed))

  return failed == 0
end

-- Run tests
local success = run_tests()
if not success then
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
