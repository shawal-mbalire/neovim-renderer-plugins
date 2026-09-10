# Detailed Implementation Guide

## 1. Markdown Parser Algorithm

### Lexer Design
The lexer tokenizes markdown text into tokens:

```typescript
enum TokenType {
  HEADING,
  BOLD,
  ITALIC,
  STRIKETHROUGH,
  CODE_INLINE,
  CODE_BLOCK,
  LINK,
  IMAGE,
  TABLE,
  BLOCKQUOTE,
  LIST_ITEM,
  HORIZONTAL_RULE,
  PARAGRAPH,
  TEXT,
  NEWLINE,
  HTML_TAG,
}

interface Token {
  type: TokenType;
  content: string;
  level?: number;      // For headings
  url?: string;        // For links/images
  alt?: string;        // For images
  language?: string;   // For code blocks
  columns?: string[];  // For tables
  raw?: string;        // Original text
}
```

### Parser Algorithm
```
function parseMarkdown(input: string): AST
  1. Split input into lines
  2. For each line:
     a. Check for block-level elements (headings, code blocks, tables, etc.)
     b. If inside a block (code block, table), accumulate content
     c. Otherwise, tokenize inline elements
  3. Build AST from tokens
  4. Handle nested elements (bold inside italic, etc.)
```

### Key Parsing Rules

**Headings:**
```
/^#{1,6}\s+(.+)$/
→ { type: HEADING, level: 1-6, content: "text" }
```

**Bold:**
```
/\*\*(.+?)\*\*/
→ { type: BOLD, content: "text" }
```

**Italic:**
```
/\*(.+?)\*/
→ { type: ITALIC, content: "text" }
```

**Links:**
```
/\[(.+?)\]\((.+?)\)/
→ { type: LINK, content: "text", url: "url" }
```

**Images:**
```
/!\[(.+?)\]\((.+?)\)/
→ { type: IMAGE, alt: "alt", url: "url" }
```

**Code Blocks:**
```
/^`{3,}(\w+)?$/  (opening)
/^`{3,}$/        (closing)
→ { type: CODE_BLOCK, language: "lang", content: "code" }
```

**Tables:**
```
| col1 | col2 |
|------|------|
| a    | b    |
→ { type: TABLE, columns: ["col1", "col2"], rows: [["a", "b"]] }
```

**Blockquotes:**
```
/^>\s+(.+)$/
→ { type: BLOCKQUOTE, content: "text" }
```

## 2. HTML to Text Conversion

### Tag Mapping
```typescript
const htmlTagMap: Record<string, (content: string, attrs?: Record<string, string>) => string> = {
  'b': (c) => `\x1b[1m${c}\x1b[22m`,
  'strong': (c) => `\x1b[1m${c}\x1b[22m`,
  'i': (c) => `\x1b[3m${c}\x1b[23m`,
  'em': (c) => `\x1b[3m${c}\x1b[23m`,
  'code': (c) => `\x1b[36m${c}\x1b[39m`,
  'pre': (c) => `\n${c}\n`,
  'a': (c, attrs) => `${c} (${attrs?.href || ''})`,
  'img': (c, attrs) => `[Image: ${attrs?.alt || attrs?.src || ''}]`,
  'br': () => '\n',
  'p': (c) => `${c}\n\n`,
  'h1': (c) => `\x1b[1m${c}\x1b[0m\n`,
  'h2': (c) => `\x1b[1m${c}\x1b[0m\n`,
  'h3': (c) => `\x1b[1m${c}\x1b[0m\n`,
  'h4': (c) => `\x1b[1m${c}\x1b[0m\n`,
  'h5': (c) => `\x1b[1m${c}\x1b[0m\n`,
  'h6': (c) => `\x1b[1m${c}\x1b[0m\n`,
  'blockquote': (c) => c.split('\n').map(l => `> ${l}`).join('\n'),
  'ul': (c) => c,
  'ol': (c) => c,
  'li': (c) => `• ${c}\n`,
  'hr': () => '─'.repeat(40),
  'table': (c) => c,
  'tr': (c) => c,
  'td': (c) => `| ${c} `,
  'th': (c) => `| ${c} `,
  'div': (c) => c,
  'span': (c) => c,
};
```

### HTML Parser Algorithm
```
function convertHtmlToText(html: string): string
  1. Create a stack for nested tags
  2. Scan through html string:
     a. When encountering <tag>, push to stack
     b. When encountering </tag>, pop from stack and apply transformation
     c. Text content is transformed using current tag context
  3. Handle self-closing tags (<br/>, <img/>)
  4. Handle attributes (href, src, alt, etc.)
```

## 3. Kitty Graphics Protocol Implementation

### Support Detection
```typescript
async function detectKittySupport(): Promise<boolean> {
  // Send query action
  const query = `\x1b_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\x1b\\`;
  process.stdout.write(query);

  // Wait for response
  // If response contains "OK", Kitty is supported
  // If no response or error, not supported
}
```

### Image Transmission
```typescript
function transmitImagePng(pngData: Buffer, id: number): string {
  const base64 = pngData.toString('base64');
  const chunkSize = 4096;
  const chunks: string[] = [];

  for (let i = 0; i < base64.length; i += chunkSize) {
    const chunk = base64.slice(i, i + chunkSize);
    const isLast = i + chunkSize >= base64.length;

    if (i === 0) {
      // First chunk with full control data
      chunks.push(`\x1b_Gf=100,t=d,i=${id},m=${isLast ? 0 : 1};${chunk}\x1b\\`);
    } else {
      // Subsequent chunks
      chunks.push(`\x1b_Gm=${isLast ? 0 : 1};${chunk}\x1b\\`);
    }
  }

  return chunks.join('');
}
```

### Image Placement
```typescript
function placeImage(
  id: number,
  col: number,
  row: number,
  width: number,
  height: number
): string {
  return `\x1b_Ga=p,i=${id},x=${col},y=${row},w=${width},h=${height}\x1b\\`;
}
```

## 4. Mermaid Rendering

### mmdc Integration
```typescript
async function renderMermaid(
  code: string,
  outputPath: string
): Promise<boolean> {
  const tmpFile = `/tmp/mermaid_${Date.now()}.mmd`;

  // Write mermaid code to temp file
  await Bun.write(tmpFile, code);

  try {
    // Call mmdc
    const proc = Bun.spawn([
      'mmdc',
      '-i', tmpFile,
      '-o', outputPath,
      '-b', 'transparent',
      '-t', 'dark',
    ]);

    await proc.exited;
    return proc.exitCode === 0;
  } catch {
    return false;
  } finally {
    // Cleanup temp file
    await Bun.file(tmpFile).delete();
  }
}
```

## 5. ipynb Parser

### JSON Structure
```typescript
interface IpynbNotebook {
  cells: IpynbCell[];
  metadata: {
    kernelspec?: {
      display_name: string;
      language: string;
      name: string;
    };
    language_info?: {
      name: string;
      version: string;
    };
  };
  nbformat: number;
  nbformat_minor: number;
}

interface IpynbCell {
  cell_type: 'code' | 'markdown' | 'raw';
  source: string[];
  outputs?: IpynbOutput[];
  execution_count?: number | null;
  metadata?: Record<string, any>;
}

interface IpynbOutput {
  output_type: 'stream' | 'execute_result' | 'display_data' | 'error';
  name?: string;          // For stream
  text?: string[];        // For stream/execute_result
  data?: {                // For execute_result/display_data
    'text/plain'?: string[];
    'text/html'?: string[];
    'image/png'?: string;
    'image/jpeg'?: string;
    'image/svg+xml'?: string;
    'application/json'?: string;
    'text/latex'?: string[];
  };
  ename?: string;         // For error
  evalue?: string;        // For error
  traceback?: string[];   // For error
}
```

### Cell Rendering
```typescript
function renderCell(cell: IpynbCell, cellIndex: number): RenderLine[] {
  const lines: RenderLine[] = [];

  // Cell header
  lines.push({
    text: `─── Cell ${cellIndex + 1}: ${cell.cell_type.toUpperCase()} ───`,
    marks: [{ hl_group: 'Comment' }]
  });

  // Cell source
  const source = cell.source.join('');
  if (cell.cell_type === 'code') {
    // Render with syntax highlighting
    lines.push(...renderCodeBlock(source));
  } else if (cell.cell_type === 'markdown') {
    // Render markdown
    lines.push(...renderMarkdown(source));
  }

  // Outputs
  if (cell.outputs && cell.outputs.length > 0) {
    lines.push({ text: '┌─ Output:', marks: [{ hl_group: 'Comment' }] });

    for (const output of cell.outputs) {
      lines.push(...renderOutput(output));
    }

    lines.push({ text: '└─────────', marks: [{ hl_group: 'Comment' }] });
  }

  return lines;
}
```

## 6. Neovim Lua Integration

### Extmark Rendering
```lua
local ns_id = vim.api.nvim_create_namespace('markdown_renderer')

function render_line(buf, line_idx, render_data)
  -- Clear existing extmarks
  vim.api.nvim_buf_clear_namespace(buf, ns_id, line_idx, line_idx + 1)

  -- Apply text styling
  for _, mark in ipairs(render_data.marks or {}) do
    vim.api.nvim_buf_set_extmark(buf, ns_id, line_idx, mark.col_start, {
      end_col = mark.col_end,
      hl_group = mark.hl_group,
    })
  end

  -- Apply virtual text (for prefixes like █▌)
  if render_data.virt_text then
    vim.api.nvim_buf_set_extmark(buf, ns_id, line_idx, 0, {
      virt_text = { { render_data.virt_text, render_data.virt_hl_group } },
      virt_text_pos = 'inline',
    })
  end

  -- Place images (Kitty protocol)
  if render_data.images then
    for _, img in ipairs(render_data.images) do
      place_kitty_image(buf, line_idx, img)
    end
  end
end
```

### Autocmds
```lua
vim.api.nvim_create_autocmd({ 'BufReadPost', 'TextChanged', 'InsertLeave' }, {
  pattern = { '*.md', '*.ipynb' },
  callback = function(ev)
    local content = table.concat(
      vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false),
      '\n'
    )

    -- Send to Bun process
    send_to_renderer({
      type = 'update',
      filetype = vim.bo[ev.buf].filetype,
      content = content,
    })
  end,
})
```

## 7. Error Handling

### Bun Process
```typescript
process.on('uncaughtException', (err) => {
  // Send error to Neovim
  process.stdout.write(JSON.stringify({
    type: 'error',
    message: err.message,
  }));
  process.exit(1);
});
```

### Graceful Degradation
- If Kitty not supported → Show image placeholder
- If mmdc not installed → Show mermaid code as highlighted text
- If parse error → Show raw text with error message

## 8. Performance Considerations

### Debouncing
```typescript
let updateTimer: Timer | null = null;

function scheduleUpdate(content: string) {
  if (updateTimer) {
    clearTimeout(updateTimer);
  }
  updateTimer = setTimeout(() => {
    render(content);
  }, 100); // 100ms debounce
}
```

### Incremental Parsing
- Only re-parse changed sections
- Cache parsed AST
- Use line-based diffing for large files

### Lazy Image Loading
- Only render visible images
- Use placeholder for off-screen images
- Implement virtual scrolling
