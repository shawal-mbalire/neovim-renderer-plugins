/**
 * Markdown Builder
 * Fluent builder for constructing complex markdown content
 */

import type { MarkdownASTNode } from "../../../plugins/markdown/domain/models/types";

export class MarkdownBuilder {
  private parts: string[] = [];
  private astNodes: MarkdownASTNode[] = [];

  // ============================================================================
  // Content Methods
  // ============================================================================

  heading(level: number, text: string): this {
    const prefix = "#".repeat(level);
    this.parts.push(`${prefix} ${text}`);
    return this;
  }

  paragraph(text: string): this {
    this.parts.push(text);
    return this;
  }

  blankLine(): this {
    this.parts.push("");
    return this;
  }

  // ============================================================================
  // Inline Formatting
  // ============================================================================

  bold(text: string): this {
    this.parts.push(`**${text}**`);
    return this;
  }

  italic(text: string): this {
    this.parts.push(`*${text}*`);
    return this;
  }

  strikethrough(text: string): this {
    this.parts.push(`~~${text}~~`);
    return this;
  }

  code(text: string): this {
    this.parts.push(`\`${text}\``);
    return this;
  }

  link(text: string, href: string): this {
    this.parts.push(`[${text}](${href})`);
    return this;
  }

  image(alt: string, src: string): this {
    this.parts.push(`![${alt}](${src})`);
    return this;
  }

  // ============================================================================
  // Block Elements
  // ============================================================================

  codeBlock(code: string, language?: string): this {
    const lang = language || "";
    this.parts.push(`\`\`\`${lang}`);
    this.parts.push(code);
    this.parts.push("```");
    return this;
  }

  blockquote(text: string): this {
    this.parts.push(`> ${text}`);
    return this;
  }

  horizontalRule(): this {
    this.parts.push("---");
    return this;
  }

  // ============================================================================
  // Lists
  // ============================================================================

  unorderedList(items: string[]): this {
    for (const item of items) {
      this.parts.push(`- ${item}`);
    }
    return this;
  }

  orderedList(items: string[]): this {
    items.forEach((item, i) => {
      this.parts.push(`${i + 1}. ${item}`);
    });
    return this;
  }

  taskList(items: { text: string; checked: boolean }[]): this {
    for (const item of items) {
      const check = item.checked ? "[x]" : "[ ]";
      this.parts.push(`- ${check} ${item.text}`);
    }
    return this;
  }

  // ============================================================================
  // Tables
  // ============================================================================

  table(headers: string[], rows: string[][]): this {
    // Header row
    this.parts.push(`| ${headers.join(" | ")} |`);
    
    // Separator
    this.parts.push(`| ${headers.map(() => "---").join(" | ")} |`);
    
    // Data rows
    for (const row of rows) {
      this.parts.push(`| ${row.join(" | ")} |`);
    }
    
    return this;
  }

  // ============================================================================
  // GitHub Extensions
  // ============================================================================

  alert(type: "note" | "tip" | "important" | "warning" | "caution", text: string): this {
    this.parts.push(`> [!${type.toUpperCase()}]`);
    this.parts.push(`> ${text}`);
    return this;
  }

  mathInline(math: string): this {
    this.parts.push(`$${math}$`);
    return this;
  }

  mathDisplay(math: string): this {
    this.parts.push("$$");
    this.parts.push(math);
    this.parts.push("$$");
    return this;
  }

  emoji(shortcode: string): this {
    this.parts.push(`:${shortcode}:`);
    return this;
  }

  footnote(id: string, text: string): this {
    this.parts.push(`[^${id}]: ${text}`);
    return this;
  }

  footnoteRef(id: string): this {
    this.parts.push(`[^${id}]`);
    return this;
  }

  // ============================================================================
  // HTML Extensions
  // ============================================================================

  subscript(text: string): this {
    this.parts.push(`<sub>${text}</sub>`);
    return this;
  }

  superscript(text: string): this {
    this.parts.push(`<sup>${text}</sup>`);
    return this;
  }

  underline(text: string): this {
    this.parts.push(`<u>${text}</u>`);
    return this;
  }

  highlight(text: string): this {
    this.parts.push(`<mark>${text}</mark>`);
    return this;
  }

  keyboard(key: string): this {
    this.parts.push(`<kbd>${key}</kbd>`);
    return this;
  }

  // ============================================================================
  // Raw Content
  // ============================================================================

  raw(text: string): this {
    this.parts.push(text);
    return this;
  }

  newline(): this {
    this.parts.push("\n");
    return this;
  }

  // ============================================================================
  // Build Methods
  // ============================================================================

  build(): string {
    return this.parts.join("\n");
  }

  buildAst(): MarkdownASTNode {
    return {
      type: "document",
      children: this.astNodes,
    };
  }

  // Reset builder
  reset(): this {
    this.parts = [];
    this.astNodes = [];
    return this;
  }

  // ============================================================================
  // Static Factory Methods
  // ============================================================================

  static create(): MarkdownBuilder {
    return new MarkdownBuilder();
  }

  static simpleDocument(): string {
    return MarkdownBuilder.create()
      .heading(1, "Title")
      .blankLine()
      .paragraph("Simple document with ")
      .bold("bold")
      .raw(" and ")
      .italic("italic")
      .raw(" text.")
      .build();
  }

  static complexDocument(): string {
    return MarkdownBuilder.create()
      .heading(1, "Project Documentation")
      .blankLine()
      .paragraph("This is a complex document with many features.")
      .blankLine()
      .heading(2, "Features")
      .unorderedList(["Feature 1", "Feature 2", "Feature 3"])
      .blankLine()
      .heading(2, "Code Example")
      .codeBlock('console.log("Hello");', "typescript")
      .blankLine()
      .heading(2, "Table")
      .table(
        ["Name", "Type", "Description"],
        [
          ["foo", "string", "Foo value"],
          ["bar", "number", "Bar value"],
        ]
      )
      .blankLine()
      .alert("note", "This is an important note.")
      .blankLine()
      .heading(2, "Math")
      .paragraph("Inline math: ")
      .mathInline("x^2 + y^2 = z^2")
      .blankLine()
      .horizontalRule()
      .paragraph("*Last updated: 2024*")
      .build();
  }
}
