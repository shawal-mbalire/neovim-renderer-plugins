# Neovim Renderer Plugins

Three serverless plugins for rendering Markdown, ipynb, and Images in Neovim with render timing and kernel selection.

## Features

- **Render timing** - Shows how long each render takes in milliseconds
- **Kernel selection** - ipynb plugin auto-detects kernel with selection menu
- **Built-in Neovim features** - Uses extmarks, splits, autocmds, vim.ui.select

## Installation

### lazy.nvim

```lua
-- All three plugins
{
  "shawal-mbalire/neovim-renderer-plugins",
  ft = { "markdown", "ipynb", "png", "jpg" },
  config = function()
    require("renderer-markdown").setup({ show_render_time = true })
    require("renderer-ipynb").setup({ auto_select_kernel = true })
    require("renderer-image").setup({ show_render_time = true })
  end,
}

-- Or install separately
{ "shawal-mbalire/neovim-renderer-plugins", ft = "markdown",
  config = function() require("renderer-markdown").setup() end }

{ "shawal-mbalire/neovim-renderer-plugins", ft = "ipynb",
  config = function() require("renderer-ipynb").setup() end }

{ "shawal-mbalire/neovim-renderer-plugins", ft = { "png", "jpg" },
  config = function() require("renderer-image").setup() end }
```

### plug.nvim

```vim
Plug 'shawal-mbalire/neovim-renderer-plugins'

lua << EOF
require("renderer-markdown").setup()
require("renderer-ipynb").setup()
require("renderer-image").setup()
EOF
```

## Configuration

### Markdown

```lua
require("renderer-markdown").setup({
  preview = {
    enabled = true,
    position = "right",  -- "right" or "bottom"
    width = 50,
    sync_scroll = true,
    auto_open = true,
  },
  debounce_ms = 100,
  show_render_time = true,  -- Shows "[markdown] Rendered in X.XX ms"
})
```

### ipynb

```lua
require("renderer-ipynb").setup({
  show_execution_count = true,
  max_output_lines = 100,
  debounce_ms = 100,
  show_render_time = true,
  auto_select_kernel = true,  -- Auto-detect kernel or show selection menu
})
```

### Image

```lua
require("renderer-image").setup({
  max_width = 800,
  max_height = 600,
  debounce_ms = 100,
  show_render_time = true,
})
```

## Commands

### Markdown
- `:MarkdownPreview` - Open preview split
- `:MarkdownPreviewClose` - Close preview
- `:MarkdownPreviewToggle` - Toggle preview

### ipynb
- `:IpynbRender` - Re-render notebook
- `:IpynbEdit` - Switch to edit mode
- `:IpynbSelectKernel` - Select kernel manually
- `:IpynbShowKernels` - List available kernels

### Image
- `:ImageShow` - Display image
- `:ImageInfo` - Show terminal capabilities

## Kernel Selection

The ipynb plugin supports multiple kernels:
- Python 3 (recommended)
- Python 2
- Julia
- R
- Bash
- JavaScript
- TypeScript
- Markdown

Auto-detection reads from notebook metadata. If no kernel is detected, a selection menu appears.

## Development

```bash
# Run e2e tests with headless Neovim
just test-e2e

# Run specific test
just test-e2e-markdown
just test-e2e-ipynb
just test-e2e-image

# Interactive testing
just nvim-markdown
just nvim-ipynb
```

## Project Structure

```
├── lua/
│   ├── renderer-markdown/    # GitHub MD with side-by-side preview
│   ├── renderer-ipynb/       # Jupyter notebook with kernel selection
│   └── renderer-image/       # Terminal image display
├── domain/                   # Hexagonal architecture
│   ├── shared/              # Common types, ports, constants
│   └── markdown/            # Markdown domain
├── adapters/                # Parser implementations
├── tests/
│   ├── unit/                # Unit tests
│   └── e2e/                 # Headless Neovim tests
└── justfile                 # Task runner
```

## License

MIT
