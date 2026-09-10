/**
 * Markdown Test Factory
 * Creates test markdown content and AST nodes
 */

import type { MarkdownASTNode } from "../../../plugins/markdown/domain/models/types";

// ============================================================================
// Markdown Content Factory
// ============================================================================

export const MarkdownFactory = {
  // Simple content
  simpleText: (): string => "Hello, world!",
  
  paragraph: (): string => "This is a simple paragraph with some text.",
  
  multipleParagraphs: (): string => `
First paragraph with some content.

Second paragraph with more content.

Third paragraph.
`.trim(),

  // Headings
  heading: (level: number = 1): string => {
    const prefix = "#".repeat(level);
    return `${prefix} Heading Level ${level}`;
  },
  
  allHeadings: (): string => `
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6
`.trim(),

  // Inline formatting
  bold: (): string => "This is **bold** text.",
  
  italic: (): string => "This is *italic* text.",
  
  strikethrough: (): string => "This is ~~strikethrough~~ text.",
  
  boldItalic: (): string => "This is ***bold and italic*** text.",
  
  codeInline: (): string => "Use `console.log()` for debugging.",
  
  mixedInline: (): string => "Text with **bold**, *italic*, ~~strikethrough~~, and `code`.",

  // Links and images
  link: (): string => "[GitHub](https://github.com)",
  
  image: (): string => "![Alt text](image.png)",
  
  autolink: (): string => "<https://github.com>",
  
  referenceLink: (): string => `[link][ref]

[ref]: https://github.com`,

  // Code blocks
  codeBlock: (): string => '```typescript\nconst x = 1;\nconsole.log(x);\n```',
  
  codeBlockWithLanguage: (lang: string): string => `\`\`\`${lang}\n// Code in ${lang}\n\`\`\``,
  
  indentedCodeBlock: (): string => "    const x = 1;\n    console.log(x);",

  // Lists
  unorderedList: (): string => `- Item 1
- Item 2
- Item 3`,
  
  orderedList: (): string => `1. First
2. Second
3. Third`,
  
  nestedList: (): string => `- Level 1
  - Level 2
    - Level 3`,
  
  taskList: (): string => `- [x] Completed task
- [ ] Incomplete task
- [x] Another completed`,

  // Tables
  simpleTable: (): string => `| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
| Cell 3   | Cell 4   |`,
  
  tableWithAlignment: (): string => `| Left | Center | Right |
|:-----|:------:|------:|
| L1   |   C1   |    R1 |
| L2   |   C2   |    R2 |`,

  // Blockquotes
  blockquote: (): string => "> This is a blockquote.",
  
  nestedBlockquote: (): string => `> Level 1
>> Level 2
>>> Level 3`,

  // GitHub Alerts
  alertNote: (): string => "> [!NOTE]\n> This is a note.",
  
  alertTip: (): string => "> [!TIP]\n> This is a tip.",
  
  alertImportant: (): string => "> [!IMPORTANT]\n> This is important.",
  
  alertWarning: (): string => "> [!WARNING]\n> This is a warning.",
  
  alertCaution: (): string => "> [!CAUTION]\n> This is a caution.",

  // Math
  mathInline: (): string => "The equation $E = mc^2$ is famous.",
  
  mathDisplay: (): string => `$$
\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}
$$`,

  // Emoji
  emoji: (): string => "Hello :rocket: world!",
  
  multipleEmoji: (): string => ":smile: :heart: :thumbsup: :fire:",

  // Color models
  colorHex: (): string => "`#0969DA`",
  
  colorRgb: (): string => "`rgb(9, 105, 218)`",
  
  colorHsl: (): string => "`hsl(212, 92%, 45%)`",

  // HTML extensions
  subscript: (): string => "H<sub>2</sub>O",
  
  superscript: (): string => "E = mc<sup>2</sup>",
  
  underline: (): string => "<u>This is underlined.</u>",
  
  highlight: (): string => "<mark>This is highlighted.</mark>",
  
  keyboard: (): string => "Press <kbd>Ctrl</kbd> + <kbd>C</kbd>",

  // Footnotes
  footnote: (): string => `This has a footnote[^1].

[^1]: This is the footnote content.`,

  // Details/Summary
  details: (): string => `<details>
<summary>Click to expand</summary>

This is the hidden content.

</details>`,

  // Horizontal rule
  horizontalRule: (): string => `---

Text after rule.`,

  // Complex document
  complexDocument: (): string => `
# Project Title

## Overview

This is a **complex** document with *multiple* features.

### Features

- Feature 1
- Feature 2
- Feature 3

### Code Example

\`\`\`typescript
function greet(name: string): string {
  return \`Hello, \${name}!\`;
}
\`\`\`

### Table

| Name | Type | Description |
|------|------|-------------|
| foo  | string | Foo value |
| bar  | number | Bar value |

> [!NOTE]
> This is an important note.

### Math

Inline math: $x^2 + y^2 = z^2$

Display math:
$$
\\sum_{i=1}^{n} i = \\frac{n(n+1)}{2}
$$

---

*Last updated: 2024*
`.trim(),

  // Edge cases
  emptyDocument: (): string => "",
  
  whitespaceOnly: (): string => "   \n  \n   ",
  
  specialCharacters: (): string => "Special chars: < > & \" ' / \\",
  
  unicode: (): string => "Unicode: 🚀 ⭐ ❤️ é ñ ü",
  
  longLine: (): string => "A".repeat(1000),
  
  manyNewlines: (): string => "\n\n\n\n\n\n\n\n\n\n",
};

// ============================================================================
// AST Node Factory
// ============================================================================

export const ASTFactory = {
  document: (children: MarkdownASTNode[] = []): MarkdownASTNode => ({
    type: "document",
    children,
  }),

  heading: (level: number, text: string): MarkdownASTNode => ({
    type: "heading",
    level,
    children: [{ type: "text", content: text }],
  }),

  paragraph: (text: string): MarkdownASTNode => ({
    type: "paragraph",
    children: [{ type: "text", content: text }],
  }),

  text: (content: string): MarkdownASTNode => ({
    type: "text",
    content,
  }),

  bold: (text: string): MarkdownASTNode => ({
    type: "bold",
    children: [{ type: "text", content: text }],
  }),

  italic: (text: string): MarkdownASTNode => ({
    type: "italic",
    children: [{ type: "text", content: text }],
  }),

  strikethrough: (text: string): MarkdownASTNode => ({
    type: "strikethrough",
    children: [{ type: "text", content: text }],
  }),

  codeInline: (code: string): MarkdownASTNode => ({
    type: "code_inline",
    content: code,
  }),

  codeBlock: (code: string, language?: string): MarkdownASTNode => ({
    type: "code_block",
    content: code,
    language,
  }),

  link: (text: string, href: string): MarkdownASTNode => ({
    type: "link",
    content: text,
    attributes: { href },
  }),

  image: (alt: string, src: string): MarkdownASTNode => ({
    type: "image",
    content: alt,
    attributes: { src },
  }),

  blockquote: (children: MarkdownASTNode[] = []): MarkdownASTNode => ({
    type: "blockquote",
    children,
  }),

  alert: (alertType: "note" | "tip" | "important" | "warning" | "caution", children: MarkdownASTNode[] = []): MarkdownASTNode => ({
    type: "alert",
    alertType,
    children,
  }),

  unorderedList: (items: MarkdownASTNode[] = []): MarkdownASTNode => ({
    type: "unordered_list",
    children: items,
  }),

  orderedList: (items: MarkdownASTNode[] = []): MarkdownASTNode => ({
    type: "ordered_list",
    children: items,
  }),

  listItem: (children: MarkdownASTNode[] = []): MarkdownASTNode => ({
    type: "list_item",
    children,
  }),

  taskItem: (checked: boolean, children: MarkdownASTNode[] = []): MarkdownASTNode => ({
    type: "task_item",
    checked,
    children,
  }),

  taskList: (items: MarkdownASTNode[] = []): MarkdownASTNode => ({
    type: "task_list",
    children: items,
  }),

  table: (rows: MarkdownASTNode[] = []): MarkdownASTNode => ({
    type: "table",
    children: rows,
  }),

  tableRow: (cells: MarkdownASTNode[] = []): MarkdownASTNode => ({
    type: "table_row",
    children: cells,
  }),

  tableCell: (children: MarkdownASTNode[] = []): MarkdownASTNode => ({
    type: "table_cell",
    children,
  }),

  horizontalRule: (): MarkdownASTNode => ({
    type: "horizontal_rule",
  }),

  mathInline: (math: string): MarkdownASTNode => ({
    type: "math_inline",
    mathContent: math,
  }),

  mathDisplay: (math: string): MarkdownASTNode => ({
    type: "math_display",
    mathContent: math,
  }),

  emoji: (name: string, char?: string): MarkdownASTNode => ({
    type: "emoji",
    emojiName: name,
    emojiChar: char,
  }),

  footnoteRef: (id: string): MarkdownASTNode => ({
    type: "footnote_ref",
    footnoteId: id,
  }),

  footnoteDef: (id: string, content: string): MarkdownASTNode => ({
    type: "footnote_def",
    footnoteId: id,
    content,
  }),

  htmlBlock: (content: string): MarkdownASTNode => ({
    type: "html_block",
    content,
    isHTML: true,
  }),

  mermaid: (code: string): MarkdownASTNode => ({
    type: "mermaid",
    content: code,
  }),
};
