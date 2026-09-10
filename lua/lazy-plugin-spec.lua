---
--- Lazy.nvim plugin specification
--- Use this file for lazy.nvim integration
---

return {
  "yourusername/neovim-renderer-plugins",
  ft = { "markdown", "ipynb", "html", "htm" },
  dependencies = {
    { "nvim-lua/plenary.nvim", optional = true },
  },
  build = function()
    local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
    vim.fn.system("cd " .. plugin_dir .. " && bun install")
  end,
  config = function()
    require("renderer").setup({
      preview = {
        enabled = true,
        position = "right",
        width = 50,
        sync_scroll = true,
        auto_open = true,
      },
      debounce_ms = 100,
      kitty = true,
      mermaid = true,
    })
  end,
  keys = {
    { "<leader>mp", "<cmd>RendererPreviewToggle<cr>", desc = "Toggle Markdown Preview" },
    { "<leader>mr", "<cmd>RendererRefresh<cr>", desc = "Refresh Renderer" },
    { "<leader>ms", "<cmd>RendererStatus<cr>", desc = "Renderer Status" },
  },
}
