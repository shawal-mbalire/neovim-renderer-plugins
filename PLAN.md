# Neovim Markdown & ipynb Renderer - Implementation Plan

## Overview

Build a serverless, zero-npm-package renderer for Markdown and .ipynb files in Neovim using Bun and pure TypeScript.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Neovim (Lua)                           │
│  - Buffer management, autocmds, extmarks                    │
│  - Spawns Bun process via vim.fn.jobstart()                 │
│  - Receives structured JSON output from Bun                 │
└──────────────────────────┬──────────────────────────────────┘
                           │ stdio (JSON)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Bun Engine (TypeScript)                   │
│  - Pure TypeScript markdown parser (no npm)                 │
│  - HTML to text converter                                   │
│  - ipynb JSON parser                                        │
│  - Kitty graphics protocol for images                       │
│  - Mermaid rendering via mmdc                               │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Markdown Parser (`src/markdown/parser.ts`)
Pure TypeScript implementation - NO npm packages.

**Supported Syntax:**
- Headings (h1-h6)
- Bold (`**text**`), Italic (`*text*`), Strikethrough (`~~text~~`)
- Links (`[text](url)`)
- Images (`![alt](url)`)
- Code blocks (``` ``` ```)
- Inline code (`` `code` ``)
- Tables
- Blockquotes (`> text`)
- Ordered/Unordered lists
- Horizontal rules (`---`)
- HTML inline tags (`<b>`, `<i>`, `<a>`, `<code>`, etc.)

**Output:** Structured AST (Abstract Syntax Tree) as JSON

### 2. HTML to Text Converter (`src/markdown/html.ts`)
Convert HTML tags to terminal-friendly output:
- `<b>`, `<strong>` → ANSI bold or extmark
- `<i>`, `<em>` → ANSI italic or extmark
- `<a href="url">` → `text (url)`
- `<img src="url">` → Kitty image or placeholder
- `<table>` → Text table
- `<code>` → Inline code style
- `<pre>` → Code block
- `<br>` → Newline
- `<p>` → Paragraph break
- `<ul>`, `<ol>`, `<li>` → List items
- `<h1>`-`<h6>` → Headings
- `<blockquote>` → Indented text
- `<hr>` → Horizontal rule

### 3. Kitty Graphics Protocol (`src/graphics/kitty.ts`)
- Detect terminal support via query action
- Transmit PNG images via APC escape codes
- Handle chunked transfer for large images (4096 byte chunks)
- Support cell-based placement for inline images

### 4. Mermaid Renderer (`src/graphics/mermaid.ts`)
- Extract mermaid code blocks
- Call `mmdc` CLI to render to PNG
- Display via Kitty protocol
- Cache rendered diagrams

### 5. ipynb Parser (`src/ipynb/parser.ts`)
Parse Jupyter notebook JSON:
- Code cells with source
- Markdown cells
- Output types:
  - `text/plain` → Text display
  - `text/html` → HTML conversion
  - `image/png` → Kitty image
  - `image/svg+xml` → SVG to text or placeholder
  - `application/json` → Formatted JSON
  - `text/latex` → LaTeX placeholder
  - `error` → Traceback display

### 6. Neovim Lua Integration

**`lua/renderer/init.lua`:**
- Setup autocmds for `.md` and `.ipynb` files
- Spawn Bun process
- Handle JSON communication
- Apply extmarks for styling

**`lua/renderer/kitty.lua`:**
- Kitty protocol escape code helpers
- Terminal support detection

## File Structure

```
neovim-plugin/
├── PLAN.md
├── README.md
├── bun.lockb
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts              # Main entry point
│   ├── markdown/
│   │   ├── parser.ts         # Pure TS markdown parser
│   │   ├── ast.ts            # AST type definitions
│   │   ├── html.ts           # HTML to text converter
│   │   └── renderer.ts       # Markdown to Neovim render data
│   ├── ipynb/
│   │   ├── parser.ts         # ipynb JSON parser
│   │   └── renderer.ts       # ipynb to Neovim render data
│   ├── graphics/
│   │   ├── kitty.ts          # Kitty graphics protocol
│   │   └── mermaid.ts        # Mermaid CLI integration
│   └── types.ts              # Shared types
├── lua/
│   └── renderer/
│       ├── init.lua          # Main Lua module
│       ├── kitchen.lua       # Kitty escape helpers
│       └── extmarks.lua      # Extmark rendering
└── plugin/
    └── renderer.lua          # Plugin entry point
```

## Implementation Order

### Phase 1: Core Infrastructure
1. Project setup (package.json, tsconfig.json)
2. Type definitions
3. Communication protocol (JSON over stdio)

### Phase 2: Markdown Parser
4. Lexer (tokenize markdown)
5. Parser (build AST)
6. HTML converter

### Phase 3: Rendering
7. Markdown to render data converter
8. Neovim extmark renderer
9. Basic text styling (bold, italic, code)

### Phase 4: Advanced Features
10. Table rendering
11. Kitty graphics protocol
12. Image display
13. Mermaid integration

### Phase 5: ipynb Support
14. ipynb JSON parser
15. Cell output renderer
16. All output types

### Phase 6: Polish
17. Error handling
18. Performance optimization
19. Documentation

## Communication Protocol

### Bun → Neovim (JSON)
```json
{
  "type": "render",
  "data": {
    "lines": [
      {
        "line": 0,
        "text": "# Heading",
        "marks": [
          {
            "col_start": 0,
            "col_end": 8,
            "hl_group": "Title",
            "virt_text": "█▌ "
          }
        ],
        "images": [
          {
            "col": 0,
            "path": "/path/to/image.png",
            "width": 40,
            "height": 10
          }
        ]
      }
    ]
  }
}
```

### Neovim → Bun (JSON)
```json
{
  "type": "update",
  "filetype": "markdown",
  "content": "# Hello\n\nThis is **bold**..."
}
```

## Dependencies

### Runtime
- **Bun** - JavaScript runtime (single binary)
- **Neovim** - Text editor
- **mmdc** (optional) - Mermaid CLI for diagram rendering

### Development
- None (zero npm packages)

## Terminal Requirements

### Image Support
- **Kitty** - Full support
- **WezTerm** - Full support
- **iTerm2** - Sixel fallback (future)
- **Other** - Text placeholder

### Fallback Behavior
- No Kitty support → Show `[Image: path/to/image.png]`
- No mmdc → Show mermaid code block as highlighted code
- No Bun → Show raw markdown text
