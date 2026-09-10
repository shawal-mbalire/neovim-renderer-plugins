# Neovim Renderer Plugins

Three serverless plugins for rendering Markdown, ipynb, and Images in Neovim.

## Features

- **Markdown**: GitHub-flavored with side-by-side preview
- **ipynb**: Jupyter notebook rendering with kernel selection
- **Image**: Terminal image display (Kitty/IIP/Sixel)
- **Render timing**: Shows how long each render takes

## Installation

### lazy.nvim

```lua
-- All plugins
{
  "shawal-mbalire/neovim-renderer-plugins",
  ft = { "markdown", "ipynb", "png", "jpg", "jpeg", "gif", "webp" },
  config = function()
    require("renderer-markdown").setup()
    require("renderer-ipynb").setup()
    require("renderer-image").setup()
  end,
}

-- Or install individually
{ "shawal-mbalire/neovim-renderer-plugins", ft = "markdown",
  config = function() require("renderer-markdown").setup() end }

{ "shawal-mbalire/neovim-renderer-plugins", ft = "ipynb",
  config = function() require("renderer-ipynb").setup() end }

{ "shawal-mbalire/neovim-renderer-plugins",
  ft = { "png", "jpg", "jpeg", "gif", "webp" },
  config = function() require("renderer-image").setup() end }
```

### plug.vim

```vim
Plug 'shawal-mbalire/neovim-renderer-plugins'

" Then in init.lua:
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
  show_render_time = true,
})
```

### ipynb

```lua
require("renderer-ipynb").setup({
  show_execution_count = true,
  debounce_ms = 100,
  show_render_time = true,
  auto_select_kernel = true,
})
```

### Image

```lua
require("renderer-image").setup({
  max_width = 800,
  max_height = 600,
  show_render_time = true,
})
```

## Commands

| Plugin | Command | Description |
|--------|---------|-------------|
| Markdown | `:MarkdownPreview` | Open preview split |
| Markdown | `:MarkdownPreviewClose` | Close preview |
| Markdown | `:MarkdownPreviewToggle` | Toggle preview |
| ipynb | `:IpynbRender` | Re-render notebook |
| ipynb | `:IpynbEdit` | Switch to edit mode |
| ipynb | `:IpynbSelectKernel` | Select kernel |
| ipynb | `:IpynbShowKernels` | List kernels |
| Image | `:ImageShow` | Display image |
| Image | `:ImageInfo` | Show terminal info |

## Requirements

- Neovim 0.8+
- Terminal with image support (optional): Kitty, WezTerm, iTerm2

## Development

```bash
# Run tests
just test

# Run specific tests
just test-markdown
just test-ipynb
just test-image
just test-filetype
```

## License

MIT
