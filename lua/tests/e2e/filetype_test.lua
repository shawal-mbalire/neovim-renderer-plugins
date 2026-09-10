---
--- E2E Test: File Type Detection
--- Tests that plugins properly detect respective file types
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
  -- Markdown File Type Detection
  -- ============================================================================

  test("markdown detects .md files", function()
    local plugin = require("renderer-markdown")
    plugin.setup({ preview = { auto_open = false } })

    local augroups = vim.api.nvim_get_autocmds({ group = "RendererMarkdown" })
    local found = false
    for _, autocmd in ipairs(augroups) do
      if autocmd.pattern == "*.md" then
        found = true
        break
      end
    end
    assert(found, "Should have autocmd for .md files")
  end)

  test("markdown detects .markdown files", function()
    local plugin = require("renderer-markdown")
    plugin.setup({ preview = { auto_open = false } })

    local augroups = vim.api.nvim_get_autocmds({ group = "RendererMarkdown" })
    local found = false
    for _, autocmd in ipairs(augroups) do
      if autocmd.pattern == "*.markdown" then
        found = true
        break
      end
    end
    assert(found, "Should have autocmd for .markdown files")
  end)

  test("markdown sets filetype correctly", function()
    local plugin = require("renderer-markdown")
    plugin.setup({ preview = { auto_open = false } })

    local buffer = vim.api.nvim_create_buf(true, true)
    vim.bo[buffer].filetype = "markdown"
    assert(vim.bo[buffer].filetype == "markdown", "Filetype should be markdown")
    vim.api.nvim_buf_delete(buffer, { force = true })
  end)

  -- ============================================================================
  -- ipynb File Type Detection
  -- ============================================================================

  test("ipynb detects .ipynb files", function()
    local plugin = require("renderer-ipynb")
    plugin.setup({})

    local augroups = vim.api.nvim_get_autocmds({ group = "RendererIpynb" })
    local found = false
    for _, autocmd in ipairs(augroups) do
      if autocmd.pattern == "*.ipynb" then
        found = true
        break
      end
    end
    assert(found, "Should have autocmd for .ipynb files")
  end)

  test("ipynb sets filetype correctly", function()
    local plugin = require("renderer-ipynb")
    plugin.setup({})

    local buffer = vim.api.nvim_create_buf(true, true)
    vim.bo[buffer].filetype = "ipynb"
    assert(vim.bo[buffer].filetype == "ipynb", "Filetype should be ipynb")
    vim.api.nvim_buf_delete(buffer, { force = true })
  end)

  test("ipynb parses notebook JSON", function()
    local plugin = require("renderer-ipynb")
    plugin.setup({})

    local notebook_json = [[{
      "cells": [
        { "cell_type": "code", "source": ["print(1)"], "outputs": [], "execution_count": 1, "metadata": {} }
      ],
      "metadata": { "kernelspec": { "display_name": "Python 3", "language": "python", "name": "python3" } },
      "nbformat": 4,
      "nbformat_minor": 5
    }]]

    local success, notebook = pcall(vim.fn.json_decode, notebook_json)
    assert(success, "Should parse valid JSON")
    assert(notebook.cells, "Should have cells")
    assert(#notebook.cells == 1, "Should have 1 cell")
    assert(notebook.cells[1].cell_type == "code", "Cell should be code type")
  end)

  -- ============================================================================
  -- Image File Type Detection
  -- ============================================================================

  test("image detects .png files", function()
    local image_models = require("renderer-image.domain.models.types")
    assert(image_models.is_image_file("test.png"), "Should detect .png")
    assert(image_models.is_image_file("photo.PNG"), "Should detect .PNG (case insensitive)")
  end)

  test("image detects .jpg files", function()
    local image_models = require("renderer-image.domain.models.types")
    assert(image_models.is_image_file("test.jpg"), "Should detect .jpg")
    assert(image_models.is_image_file("photo.jpeg"), "Should detect .jpeg")
  end)

  test("image detects .gif files", function()
    local image_models = require("renderer-image.domain.models.types")
    assert(image_models.is_image_file("animation.gif"), "Should detect .gif")
  end)

  test("image detects .webp files", function()
    local image_models = require("renderer-image.domain.models.types")
    assert(image_models.is_image_file("modern.webp"), "Should detect .webp")
  end)

  test("image rejects non-image files", function()
    local image_models = require("renderer-image.domain.models.types")
    assert(not image_models.is_image_file("document.txt"), "Should reject .txt")
    assert(not image_models.is_image_file("script.lua"), "Should reject .lua")
    assert(not image_models.is_image_file("data.json"), "Should reject .json")
  end)

  test("image sets filetype correctly", function()
    local plugin = require("renderer-image")
    plugin.setup({})

    local buffer = vim.api.nvim_create_buf(true, true)
    vim.bo[buffer].filetype = "image"
    assert(vim.bo[buffer].filetype == "image", "Filetype should be image")
    vim.api.nvim_buf_delete(buffer, { force = true })
  end)

  -- ============================================================================
  -- Cross-Plugin File Type Isolation
  -- ============================================================================

  test("markdown plugin does not affect ipynb files", function()
    local markdown_plugin = require("renderer-markdown")
    markdown_plugin.setup({ preview = { auto_open = false } })

    local buffer = vim.api.nvim_create_buf(true, true)
    vim.bo[buffer].filetype = "ipynb"
    assert(vim.bo[buffer].filetype == "ipynb", "Filetype should remain ipynb")
    vim.api.nvim_buf_delete(buffer, { force = true })
  end)

  test("ipynb plugin does not affect markdown files", function()
    local ipynb_plugin = require("renderer-ipynb")
    ipynb_plugin.setup({})

    local buffer = vim.api.nvim_create_buf(true, true)
    vim.bo[buffer].filetype = "markdown"
    assert(vim.bo[buffer].filetype == "markdown", "Filetype should remain markdown")
    vim.api.nvim_buf_delete(buffer, { force = true })
  end)

  -- ============================================================================
  -- File Size Formatting
  -- ============================================================================

  test("formats file sizes correctly", function()
    local image_models = require("renderer-image.domain.models.types")

    assert(image_models.format_file_size(512):find("B"), "Should format bytes")
    assert(image_models.format_file_size(1024 * 5):find("KB"), "Should format KB")
    assert(image_models.format_file_size(1024 * 1024 * 5):find("MB"), "Should format MB")
  end)

  -- Print results with timing
  local total_time = stop_timing(total_start)

  print("\n=== File Type Detection Tests ===")
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
