import { MarkdownParser } from "./markdown/adapters/parser/index.ts";
import { MarkdownRenderer } from "./markdown/adapters/renderer/index.ts";

const parser = new MarkdownParser();
const renderer = new MarkdownRenderer();

const md = `# Hello World

This is **bold** and *italic* text.

## Code Example

\`\`\`javascript
const x = 1;
console.log(x);
\`\`\`

> This is a blockquote

- Item 1
- Item 2

| Header | Value |
|--------|-------|
| A      | 1     |
`;

const ast = parser.parse(md);
const result = renderer.render(ast);

// Output as JSON for Neovim to consume
console.log(JSON.stringify(result));
