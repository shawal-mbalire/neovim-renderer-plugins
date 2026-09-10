---
--- E2E Test: Image Rendering
--- Tests actual image rendering with various formats
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
      table.insert(test_results, string.format("  ✗ %s: %s (%.2f ms)", name, tostring(error), test_time))
    end
    timings[name] = test_time
  end

  local function create_test_image(format, filename)
    local temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, "p")
    local file_path = temp_dir .. "/" .. filename

    -- Create minimal PNG (1x1 pixel)
    local png_data = vim.fn.system("base64 -d", "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")
    local file_handle = io.open(file_path, "wb")
    file_handle:write(png_data)
    file_handle:close()

    return file_path, temp_dir
  end

  local function get_content(buffer)
    return table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
  end

  local function cleanup(buffer, temp_dir)
    pcall(function() vim.api.nvim_buf_delete(buffer, { force = true }) end)
    if temp_dir then
      vim.fn.delete(temp_dir, "rf")
    end
  end

  -- Test: PNG image rendering
  test("render PNG image", function()
    local plugin = require("renderer-image")
    plugin.setup({ show_render_time = false })

    local file_path, temp_dir = create_test_image("png", "test.png")
    local buffer = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buffer, file_path)

    local content = get_content(buffer)
    assert(content:find("Image") or content:find("test.png"), "Should contain image info")

    cleanup(buffer, temp_dir)
  end)

  -- Test: Different image formats
  test("render different image formats", function()
    local plugin = require("renderer-image")
    plugin.setup({ show_render_time = false })

    local formats = { "png", "jpg", "gif" }
    for _, format in ipairs(formats) do
      local file_path, temp_dir = create_test_image(format, "test." .. format)
      local buffer = vim.api.nvim_create_buf(true, true)
      vim.api.nvim_buf_set_name(buffer, file_path)

      local content = get_content(buffer)
      assert(content:find("test." .. format) or content:find("Image"), "Should handle " .. format)

      cleanup(buffer, temp_dir)
    end
  end)

  -- Test: Image info display
  test("display image info", function()
    local plugin = require("renderer-image")
    plugin.setup({ show_render_time = false })

    local file_path, temp_dir = create_test_image("png", "info.png")
    local buffer = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buffer, file_path)

    local content = get_content(buffer)
    assert(content:find("File:") or content:find("info.png"), "Should contain file info")

    cleanup(buffer, temp_dir)
  end)

  -- Test: File size formatting
  test("format file sizes correctly", function()
    local plugin = require("renderer-image")
    plugin.setup({ show_render_time = false })

    -- Create a larger test file
    local temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, "p")
    local file_path = temp_dir .. "/large.png"

    -- Create a larger PNG (simulate)
    local large_data = string.rep("A", 1024 * 102) -- 100KB
    local file_handle = io.open(file_path, "wb")
    file_handle:write(large_data)
    file_handle:close()

    local buffer = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buffer, file_path)

    local content = get_content(buffer)
    assert(content:find("KB") or content:find("Size"), "Should format file size")

    cleanup(buffer, temp_dir)
  end)

  -- Test: Non-image file handling
  test("handle non-image files gracefully", function()
    local plugin = require("renderer-image")
    plugin.setup({ show_render_time = false })

    local temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, "p")
    local file_path = temp_dir .. "/test.txt"

    local file_handle = io.open(file_path, "w")
    file_handle:write("Not an image")
    file_handle:close()

    local buffer = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buffer, file_path)

    -- Should not crash
    local content = get_content(buffer)

    cleanup(buffer, temp_dir)
  end)

  -- Print results with timing
  local total_time = stop_timing(total_start)

  print("\n=== Image Rendering Tests ===")
  for _, result in ipairs(test_results) do
    print(result)
  end
  print(string.format("\n%d passed, %d failed", passed, failed))
  print(string.format("Total time: %.2f ms", total_time))

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

local success = run_tests()
if not success then
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
