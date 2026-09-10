import { MarkdownParser } from "./markdown/adapters/parser/index.ts";
import { MarkdownRenderer } from "./markdown/adapters/renderer/index.ts";

const md = `# Hello World

This is **bold** and *italic* text.

## Code Example

\`\`\`javascript
const x = 1;
\`\`\`

> This is a blockquote

- Item 1
- Item 2

| Header | Value |
|--------|-------|
| A      | 1     |
`;

const p = new MarkdownParser();
const r = new MarkdownRenderer();

const ast = p.parse(md);
const result = r.render(ast);

console.log(JSON.stringify(result, null, 2));
