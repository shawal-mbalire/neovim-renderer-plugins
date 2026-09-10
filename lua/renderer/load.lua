---
--- Auto-load handler for lazy.nvim and plug.nvim
--- Detects plugin manager and sets up accordingly
---

local M = {}

function M.setup(opts)
  -- Check if renderer is already loaded
  if vim.g.loaded_renderer then
    return
  end

  -- Check if bun is available
  local bun_available = vim.fn.executable("bun") == 1
  if not bun_available then
    vim.notify("[Renderer] bun not found. Please install bun: https://bun.sh", vim.log.levels.WARN)
    return
  end

  -- Check if renderer script exists
  local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
  local renderer_script = plugin_dir .. "/../../src/index.ts"
  if vim.fn.filereadable(renderer_script) ~= 1 then
    -- Try compiled version
    renderer_script = plugin_dir .. "/../../renderer"
    if vim.fn.filereadable(renderer_script) ~= 1 then
      vim.notify("[Renderer] Renderer script not found. Run 'bun install' first.", vim.log.levels.WARN)
      return
    end
  end

  -- Load the renderer
  local renderer = require("renderer")
  renderer.setup(opts)

  vim.g.loaded_renderer = true
end

return M
