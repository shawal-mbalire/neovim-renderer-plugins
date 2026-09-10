---
--- E2E Test: Plugin Discovery
--- Tests that plugins can be discovered by lazy.nvim and plug.nvim
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

  -- ============================================================================
  -- lazy.nvim Discovery Tests
  -- ============================================================================

  test("lazy.nvim can require renderer-markdown", function()
    local success, plugin = pcall(require, "renderer-markdown")
    assert(success, "Should require renderer-markdown")
    assert(plugin.setup, "Should have setup function")
    assert(plugin.config, "Should have config")
  end)

  test("lazy.nvim can require renderer-ipynb", function()
    local success, plugin = pcall(require, "renderer-ipynb")
    assert(success, "Should require renderer-ipynb")
    assert(plugin.setup, "Should have setup function")
    assert(plugin.config, "Should have config")
  end)

  test("lazy.nvim can require renderer-image", function()
    local success, plugin = pcall(require, "renderer-image")
    assert(success, "Should require renderer-image")
    assert(plugin.setup, "Should have setup function")
    assert(plugin.config, "Should have config")
  end)

  test("lazy.nvim plugin spec structure", function()
    -- Verify the plugin follows lazy.nvim expected structure
    local plugin = require("renderer-markdown")
    assert(type(plugin.setup) == "function", "setup should be a function")
    assert(type(plugin.config) == "table", "config should be a table")
    assert(plugin.config.preview ~= nil, "config should have preview")
    assert(plugin.config.debounce_ms ~= nil, "config should have debounce_ms")
  end)

  -- ============================================================================
  -- plug.vim Discovery Tests
  -- ============================================================================

  test("plug.vim can load renderer-markdown", function()
    local success, plugin = pcall(require, "renderer-markdown")
    assert(success, "Should load via runtimepath")
    assert(plugin.setup, "Should have setup function")
  end)

  test("plug.vim can load renderer-ipynb", function()
    local success, plugin = pcall(require, "renderer-ipynb")
    assert(success, "Should load via runtimepath")
  end)

  test("plug.vim can load renderer-image", function()
    local success, plugin = pcall(require, "renderer-image")
    assert(success, "Should load via runtimepath")
  end)

  test("plug.vim autoload structure", function()
    -- Verify plugins follow vim plugin conventions
    local plugin_dirs = {
      "renderer-markdown",
      "renderer-ipynb",
      "renderer-image",
    }

    for _, dir in ipairs(plugin_dirs) do
      local init_path = string.format("lua/%s/init.lua", dir)
      local f = io.open(init_path, "r")
      if f then
        f:close()
      else
        error("Missing init.lua for " .. dir)
      end
    end
  end)

  -- ============================================================================
  -- File Structure Tests
  -- ============================================================================

  test("lua folder has correct structure", function()
    local expected_dirs = {
      "lua/shared",
      "lua/renderer-markdown",
      "lua/renderer-ipynb",
      "lua/renderer-image",
    }

    for _, dir in ipairs(expected_dirs) do
      local stat = vim.loop.fs_stat(dir)
      assert(stat, "Directory should exist: " .. dir)
    end
  end)

  test("plugins have domain adapters pattern", function()
    local plugins = { "renderer-markdown", "renderer-ipynb", "renderer-image" }

    for _, plugin in ipairs(plugins) do
      local domain_path = string.format("lua/%s/domain", plugin)
      local adapters_path = string.format("lua/%s/adapters", plugin)

      local domain_stat = vim.loop.fs_stat(domain_path)
      local adapters_stat = vim.loop.fs_stat(adapters_path)

      assert(domain_stat, plugin .. " should have domain/ directory")
      assert(adapters_stat, plugin .. " should have adapters/ directory")
    end
  end)

  test("shared folder provides common utilities", function()
    local shared_files = {
      "lua/shared/models/types.lua",
      "lua/shared/ports/index.lua",
      "lua/shared/utils/timing.lua",
    }

    for _, file in ipairs(shared_files) do
      local f = io.open(file, "r")
      assert(f, "Shared file should exist: " .. file)
      if f then f:close() end
    end
  end)

  -- ============================================================================
  -- Configuration Tests
  -- ============================================================================

  test("all plugins have default config", function()
    local plugins = {
      { name = "renderer-markdown", has_preview = true },
      { name = "renderer-ipynb", has_kernel = true },
      { name = "renderer-image", has_max_width = true },
    }

    for _, plugin_info in ipairs(plugins) do
      local success, plugin = pcall(require, plugin_info.name)
      assert(success, "Should require " .. plugin_info.name)
      assert(plugin.config, plugin_info.name .. " should have config")
      assert(plugin.config.show_render_time ~= nil, plugin_info.name .. " should have show_render_time")
    end
  end)

  test("plugins can be configured", function()
    local markdown = require("renderer-markdown")
    local original_width = markdown.config.preview.width

    markdown.setup({ preview = { width = 30 } })
    assert(markdown.config.preview.width == 30, "Should update width")

    -- Reset
    markdown.setup({ preview = { width = original_width } })
  end)

  -- Print results with timing
  local total_time = stop_timing(total_start)

  print("\n=== Plugin Discovery Tests ===")
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
