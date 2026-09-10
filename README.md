# Neovim Renderer Plugins

Serverless Markdown, ipynb, and Image renderer plugins for Neovim using Bun.

## Features

### Markdown (GitHub Feature Parity)
- **GFM Extensions**: Tables, task lists, strikethrough, autolinks
- **GitHub Alerts**: NOTE, TIP, IMPORTANT, WARNING, CAUTION
- **Math**: LaTeX equations ($...$ and $$...$$)
- **Mermaid**: Diagram rendering via mmdc
- **Emoji**: :rocket: → 🚀
- **Color Models**: #RRGGBB, rgb(), hsl()
- **HTML Extensions**: <sub>, <sup>, <u>, <mark>, <kbd>
- **Footnotes**: [^1] references
- **Side-by-side Preview**: Auto-updating split view

### ipynb (VSCode Feature Parity)
- **All Output Types**: Text, HTML, images, JSON, LaTeX, errors
- **Stream Output**: stdout/stderr
- **Rich Outputs**: PNG, JPEG, SVG, GIF
- **Error Tracebacks**: ANSI-stripped, formatted
- **Cell Numbers**: Execution count display

### Image (yazi-like Support)
- **Kitty Graphics Protocol**: Unicode placeholders
- **Inline Images Protocol**: iTerm2/WezTerm
- **Sixel**: foot, Windows Terminal
- **Fallback**: Placeholder for unsupported terminals

## Requirements

- [Neovim](https://neovim.io/) 0.8+
- [Bun](https://bun.sh/) 1.0+
- [mermaid-cli](https://github.com/mermaid-js/mermaid-cli) (optional) for Mermaid diagrams

## Installation

### lazy.nvim

```lua
{
  "yourusername/neovim-renderer-plugins",
  ft = { "markdown", "ipynb", "html" },
  dependencies = {
    "bun-sh/bun.nvim",  -- Optional: if using bun integration
  },
  config = function()
    require("renderer").setup({
      -- Preview settings
      preview = {
        enabled = true,
        position = "right",  -- "right" or "bottom"
        width = 50,          -- For right split (percentage)
        height = 15,         -- For bottom split (lines)
        sync_scroll = true,
        auto_open = true,
      },
      -- Other settings
      debounce_ms = 100,
      kitty = true,
      mermaid = true,
    })
  end,
}
```

### plug.nvim

```vim
Plug 'yourusername/neovim-renderer-plugins'

" In init.lua or after plugin load:
lua << EOF
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
EOF
```

### With Dependencies

```lua
-- lazy.nvim with all dependencies
{
  "yourusername/neovim-renderer-plugins",
  ft = { "markdown", "ipynb", "html" },
  dependencies = {
    { "nvim-lua/plenary.nvim" },
  },
  build = function()
    -- Install Bun dependencies
    vim.fn.system("cd " .. vim.fn.stdpath("data") .. "/lazy/neovim-renderer-plugins && bun install")
  end,
  config = function()
    require("renderer").setup()
  end,
}
```

## Usage

### Markdown Preview

Open a markdown file - preview opens automatically in a split:

```bash
nvim README.md
```

**Commands:**
- `:RendererPreviewOpen` - Open preview split
- `:RendererPreviewClose` - Close preview split
- `:RendererPreviewToggle` - Toggle preview
- `:RendererRefresh` - Force refresh

### ipynb Files

Open Jupyter notebooks directly:

```bash
nvim notebook.ipynb
```

The notebook renders directly in the buffer with:
- Cell headers with execution counts
- Syntax-highlighted code
- Rendered outputs (text, images, errors)

### Images

View images in supported terminals (Kitty, WezTerm, iTerm2):

```bash
nvim image.png
```

## Configuration

```lua
require("renderer").setup({
  -- General
  enabled = true,
  debounce_ms = 100,

  -- Preview (Markdown)
  preview = {
    enabled = true,
    position = "right",  -- "right" or "bottom"
    width = 50,          -- Percentage for right split
    height = 15,         -- Lines for bottom split
    sync_scroll = true,
    auto_open = true,
  },

  -- Terminal
  kitty = true,          -- Enable Kitty graphics
  mermaid = true,        -- Enable Mermaid rendering

  -- Paths
  bun_path = "bun",
  renderer_script = nil, -- Auto-detect
})
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Neovim (Lua)                           │
│  - Buffer management, autocmds, extmarks                    │
│  - Split view for markdown preview                          │
│  - Spawns Bun process via vim.fn.jobstart()                 │
└──────────────────────────┬──────────────────────────────────┘
                           │ stdio (JSON)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Bun Engine (TypeScript)                   │
│  ├── shared/       Common types, ports, config              │
│  ├── plugins/                                            │
│  │   ├── markdown/  GFM parser, GitHub extensions          │
│  │   ├── ipynb/     Jupyter notebook parser                │
│  │   └── image/     Kitty/IIP/Sixel protocols              │
│  └── src/          Composition root                        │
└─────────────────────────────────────────────────────────────┘
```

Each plugin follows **hexagonal architecture**:
- **Domain**: Models, ports, workflows (zero dependencies)
- **Adapters**: Parser, renderer implementations
- **Infrastructure**: Config, logging

## Keyboard Shortcuts

Add these to your config for quick access:

```lua
vim.keymap.set("n", "<leader>mp", "<cmd>RendererPreviewToggle<cr>", { desc = "Toggle Markdown Preview" })
vim.keymap.set("n", "<leader>mr", "<cmd>RendererRefresh<cr>", { desc = "Refresh Renderer" })
vim.keymap.set("n", "<leader>ms", "<cmd>RendererStatus<cr>", { desc = "Renderer Status" })
```

## Supported Terminals for Images

| Terminal | Protocol | Support |
|----------|----------|---------|
| Kitty | Kitty Graphics | ✅ |
| WezTerm | IIP | ✅ |
| iTerm2 | IIP | ✅ |
| Ghostty | Kitty Graphics | ✅ |
| foot | Sixel | ✅ |
| Windows Terminal | Sixel | ✅ |
| VSCode | IIP | ✅ |

## Development

```bash
# Clone
git clone https://github.com/yourusername/neovim-renderer-plugins
cd neovim-renderer-plugins

# Install dependencies
bun install

# Run tests
bun test

# Build
bun run build
```

## License

MIT
