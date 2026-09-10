---
--- Plugin Entry Point
--- Automatically loads and initializes the renderer
---

if vim.g.loaded_renderer then
  return
end

vim.g.loaded_renderer = true

local renderer = require("renderer")

-- Auto-setup with default config
renderer.setup()
