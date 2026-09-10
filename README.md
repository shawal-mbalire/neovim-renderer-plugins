# Neovim Renderer Plugins

Three serverless plugins for rendering Markdown, ipynb, and Images in Neovim.

## Structure

```
├── lua/                          # Lua plugins (pure Neovim)
│   ├── renderer-markdown/        # Markdown with side-by-side preview
│   ├── renderer-ipynb/           # Jupyter notebook rendering
│   └── renderer-image/           # Terminal image display
│
├── typescript/                   # TypeScript (hexagonal architecture)
│   ├── domain/                   # Business logic
│   │   ├── shared/              # Common types, ports
│   │   ├── markdown/            # Markdown domain
│   │   ├── ipynb/               # Notebook domain
│   │   └── image/               # Image domain
│   ├── adapters/                # Implementations
│   │   ├── markdown/
│   │   ├── ipynb/
│   │   └── image/
│   ├── infra/                   # Config, logging
│   └── deployment/              # Build configs for separate plugins
│       ├── markdown/
│       ├── ipynb/
│       └── image/
│
└── tests/                       # Test fixtures and tests
```

## Installation

### lazy.nvim

```lua
-- All three plugins
{
  "shawal-mbalire/neovim-renderer-plugins",
  ft = { "markdown", "ipynb", "png", "jpg" },
  config = function()
    require("renderer-markdown").setup()
    require("renderer-ipynb").setup()
    require("renderer-image").setup()
  end,
}

-- Or install separately:
-- Markdown only
{ "shawal-mbalire/neovim-renderer-plugins", ft = "markdown", config = function() require("renderer-markdown").setup() end }

-- ipynb only
{ "shawal-mbalire/neovim-renderer-plugins", ft = "ipynb", config = function() require("renderer-ipynb").setup() end }

-- Image only
{ "shawal-mbalire/neovim-renderer-plugins", ft = { "png", "jpg", "gif" }, config = function() require("renderer-image").setup() end }
```

### plug.nvim

```vim
Plug 'shawal-mbalire/neovim-renderer-plugins'

" Then in init.lua:
lua << EOF
require("renderer-markdown").setup()
require("renderer-ipynb").setup()
require("renderer-image").setup()
EOF
```

## Features

### Markdown (GitHub Parison)
- GFM tables, task lists, strikethrough
- Alerts (NOTE, TIP, IMPORTANT, WARNING, CAUTION)
- Math ($...$ and $$...$$)
- Side-by-side preview with scroll sync
- Built-in extmarks for styling

### ipynb (VSCode Parity)
- All output types (text, HTML, images, errors)
- Stream output (stdout/stderr)
- Error tracebacks
- Cell execution counts

### Image (yazi-like)
- Kitty Graphics Protocol
- Inline Images Protocol (iTerm2/WezTerm)
- Sixel support
- Auto-detect terminal

## Built-in Neovim Features Used

- **Extmarks** - Non-destructive highlighting
- **Autocmds** - Auto-render on file changes
- **Splits** - Side-by-side preview
- **Virtual text** - Decorations without buffer modification
- **JSON decode** - Parse ipynb files
- **Base64** - Image encoding for protocols
- **Jobstart** - Background process communication

## Commands

### Markdown
- `:MarkdownPreview` - Open preview split
- `:MarkdownPreviewClose` - Close preview
- `:MarkdownPreviewToggle` - Toggle preview

### ipynb
- `:IpynbRender` - Re-render notebook
- `:IpynbEdit` - Switch to edit mode

### Image
- `:ImageShow` - Display image
- `:ImageInfo` - Show terminal capabilities

## Configuration

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
})

require("renderer-ipynb").setup({
  show_execution_count = true,
  max_output_lines = 100,
  debounce_ms = 100,
})

require("renderer-image").setup({
  max_width = 800,
  max_height = 600,
})
```

## Development

```bash
# Run tests
bun test

# Build separate plugins
cd typescript/deployment/markdown && bun run build
cd typescript/deployment/ipynb && bun run build
cd typescript/deployment/image && bun run build
```

## License

MIT
