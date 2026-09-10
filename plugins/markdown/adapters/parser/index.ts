/**
 * Markdown Parser Adapter - Full GFM + GitHub Extensions Support
 * Pure TypeScript implementation - zero npm packages
 */

import type { MarkdownASTNode, AlertType } from "../../domain/models/types";
import type { MarkdownParserPort } from "../../domain/ports";
import { MarkdownParseError } from "../../domain/errors";

// ============================================================================
// Markdown Parser Implementation - Complete GFM Support
// ============================================================================

export class MarkdownParser implements MarkdownParserPort {
  parse(markdown: string): MarkdownASTNode {
    const lines = markdown.split("\n");
    const root: MarkdownASTNode = {
      type: "document",
      children: [],
    };

    let i = 0;
    while (i < lines.length) {
      const line = lines[i];

      // Code blocks (fenced)
      if (line.trimStart().startsWith("```")) {
        const result = this.parseCodeBlock(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Headings (ATX)
      const headingMatch = line.match(/^(#{1,6})\s+(.+)$/);
      if (headingMatch) {
        root.children!.push({
          type: "heading",
          level: headingMatch[1].length,
          children: this.parseInline(headingMatch[2]),
        });
        i++;
        continue;
      }

      // Horizontal rule (GFM: three or more -, *, _)
      if (/^(\*{3,}|-{3,}|_{3,})\s*$/.test(line.trim())) {
        root.children!.push({ type: "horizontal_rule" });
        i++;
        continue;
      }

      // GitHub Alerts (> [!NOTE], > [!TIP], etc.)
      const alertMatch = line.match(/^>\s*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]/i);
      if (alertMatch) {
        const result = this.parseAlert(lines, i, alertMatch[1].toLowerCase() as AlertType);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Blockquote
      if (line.trimStart().startsWith("> ")) {
        const result = this.parseBlockquote(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Task list (- [ ] or - [x])
      if (/^\s*[-*+]\s+\[[ x]\]/.test(line)) {
        const result = this.parseTaskList(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Unordered list
      if (/^(\s*)([-*+])\s+/.test(line)) {
        const result = this.parseUnorderedList(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Ordered list
      if (/^(\s*)\d+[.)]\s+/.test(line)) {
        const result = this.parseOrderedList(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Table (GFM tables)
      if (line.includes("|") && i + 1 < lines.length && /^\|?\s*[-:]+/.test(lines[i + 1])) {
        const result = this.parseTable(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Math display ($$...$$)
      if (line.trimStart().startsWith("$$")) {
        const result = this.parseMathBlock(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Mermaid block
      if (line.trimStart().startsWith("```mermaid")) {
        const result = this.parseMermaidBlock(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // HTML block (GFM allows certain tags)
      if (this.isHtmlBlock(line)) {
        const result = this.parseHtmlBlock(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Footnote definition [^label]:
      const footnoteMatch = line.match(/^\[\^([^\]]+)\]:\s*(.+)$/);
      if (footnoteMatch) {
        root.children!.push({
          type: "footnote_def",
          footnoteId: footnoteMatch[1],
          content: footnoteMatch[2],
        });
        i++;
        continue;
      }

      // Empty line
      if (line.trim() === "") {
        i++;
        continue;
      }

      // Paragraph (default)
      const result = this.parseParagraph(lines, i);
      root.children!.push(result.node);
      i = result.nextLine;
    }

    return root;
  }

  // --------------------------------------------------------------------------
  // Block Parsers
  // --------------------------------------------------------------------------

  private parseCodeBlock(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const firstLine = lines[start].trimStart();
    const langMatch = firstLine.match(/^```(\w*)/);
    const language = langMatch?.[1] || undefined;

    const codeLines: string[] = [];
    let i = start + 1;

    while (i < lines.length) {
      if (lines[i].trimStart().startsWith("```")) {
        return {
          node: {
            type: "code_block",
            content: codeLines.join("\n"),
            language,
          },
          nextLine: i + 1,
        };
      }
      codeLines.push(lines[i]);
      i++;
    }

    return {
      node: {
        type: "code_block",
        content: codeLines.join("\n"),
        language,
      },
      nextLine: i,
    };
  }

  private parseAlert(lines: string[], start: number, alertType: AlertType): { node: MarkdownASTNode; nextLine: number } {
    const contentLines: string[] = [];
    let i = start;

    // Skip the first line with the alert marker
    i++;

    while (i < lines.length && (lines[i].trimStart().startsWith("> ") || lines[i].trim() === ">")) {
      const lineContent = lines[i].replace(/^>\s?/, "");
      contentLines.push(lineContent);
      i++;
    }

    return {
      node: {
        type: "alert",
        alertType,
        children: this.parseInline(contentLines.join("\n")),
      },
      nextLine: i,
    };
  }

  private parseBlockquote(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const contentLines: string[] = [];
    let i = start;

    while (i < lines.length && (lines[i].trimStart().startsWith("> ") || lines[i].trim() === ">")) {
      const lineContent = lines[i].replace(/^>\s?/, "");
      contentLines.push(lineContent);
      i++;
    }

    // Parse the content as inline markdown
    return {
      node: {
        type: "blockquote",
        children: this.parseInline(contentLines.join("\n")),
      },
      nextLine: i,
    };
  }

  private parseTaskList(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const items: MarkdownASTNode[] = [];
    let i = start;

    while (i < lines.length) {
      const match = lines[i].match(/^(\s*)([-*+])\s+\[([ x])\]\s+(.+)$/);
      if (!match) break;

      const checked = match[3] === "x";
      items.push({
        type: "task_item",
        checked,
        children: this.parseInline(match[4]),
      });
      i++;
    }

    return {
      node: {
        type: "task_list",
        children: items,
      },
      nextLine: i,
    };
  }

  private parseUnorderedList(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const items: MarkdownASTNode[] = [];
    let i = start;

    while (i < lines.length) {
      const match = lines[i].match(/^(\s*)([-*+])\s+(.+)$/);
      if (!match) break;

      items.push({
        type: "list_item",
        children: this.parseInline(match[3]),
      });
      i++;
    }

    return {
      node: {
        type: "unordered_list",
        children: items,
      },
      nextLine: i,
    };
  }

  private parseOrderedList(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const items: MarkdownASTNode[] = [];
    let i = start;

    while (i < lines.length) {
      const match = lines[i].match(/^(\s*)\d+[.)]\s+(.+)$/);
      if (!match) break;

      items.push({
        type: "list_item",
        children: this.parseInline(match[2]),
      });
      i++;
    }

    return {
      node: {
        type: "ordered_list",
        children: items,
      },
      nextLine: i,
    };
  }

  private parseTable(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const rows: MarkdownASTNode[] = [];
    let i = start;

    // Parse header row
    const headerCells = this.parseTableRow(lines[i]);
    rows.push({
      type: "table_row",
      children: headerCells.map((cell) => ({
        type: "table_cell" as const,
        children: this.parseInline(cell),
      })),
    });
    i++;

    // Skip separator row
    if (i < lines.length && /^\|?\s*[-:]+/.test(lines[i])) {
      i++;
    }

    // Parse data rows
    while (i < lines.length && lines[i].includes("|")) {
      const cells = this.parseTableRow(lines[i]);
      rows.push({
        type: "table_row",
        children: cells.map((cell) => ({
          type: "table_cell" as const,
          children: this.parseInline(cell),
        })),
      });
      i++;
    }

    return {
      node: {
        type: "table",
        children: rows,
      },
      nextLine: i,
    };
  }

  private parseTableRow(line: string): string[] {
    return line
      .split("|")
      .map((cell) => cell.trim())
      .filter((cell) => cell !== "");
  }

  private parseMathBlock(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const mathLines: string[] = [];
    let i = start;

    // Skip opening $$
    if (lines[i].trimStart().startsWith("$$")) {
      const rest = lines[i].trimStart().slice(2);
      if (rest.endsWith("$$") && rest.length > 2) {
        // Single line math
        return {
          node: {
            type: "math_display",
            mathContent: rest.slice(0, -2),
          },
          nextLine: i + 1,
        };
      }
      i++;
    }

    while (i < lines.length) {
      if (lines[i].trimEnd().endsWith("$$")) {
        const line = lines[i].trimEnd();
        mathLines.push(line.slice(0, -2));
        return {
          node: {
            type: "math_display",
            mathContent: mathLines.join("\n"),
          },
          nextLine: i + 1,
        };
      }
      mathLines.push(lines[i]);
      i++;
    }

    return {
      node: {
        type: "math_display",
        mathContent: mathLines.join("\n"),
      },
      nextLine: i,
    };
  }

  private parseMermaidBlock(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const codeLines: string[] = [];
    let i = start + 1;

    while (i < lines.length) {
      if (lines[i].trimStart().startsWith("```")) {
        return {
          node: {
            type: "mermaid",
            content: codeLines.join("\n"),
          },
          nextLine: i + 1,
        };
      }
      codeLines.push(lines[i]);
      i++;
    }

    return {
      node: {
        type: "mermaid",
        content: codeLines.join("\n"),
      },
      nextLine: i,
    };
  }

  private isHtmlBlock(line: string): boolean {
    const htmlBlockTags = [
      "div", "p", "ul", "ol", "li", "table", "tr", "td", "th",
      "thead", "tbody", "blockquote", "pre", "code", "details", "summary",
      "h1", "h2", "h3", "h4", "h5", "h6", "span", "a", "img", "br", "hr",
      "b", "i", "strong", "em", "del", "s", "sub", "sup", "u", "mark", "kbd",
      "picture", "source",
    ];

    const trimmed = line.trimStart();
    for (const tag of htmlBlockTags) {
      if (trimmed.startsWith(`<${tag}`) || trimmed.startsWith(`</${tag}`)) {
        return true;
      }
    }
    return false;
  }

  private parseHtmlBlock(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const htmlLines: string[] = [];
    let i = start;

    while (i < lines.length) {
      htmlLines.push(lines[i]);
      if (lines[i].includes("</") && !lines[i].includes("<br")) {
        i++;
        break;
      }
      i++;
    }

    return {
      node: {
        type: "html_block",
        content: htmlLines.join("\n"),
        isHTML: true,
      },
      nextLine: i,
    };
  }

  private parseParagraph(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const contentLines: string[] = [];
    let i = start;

    while (i < lines.length && lines[i].trim() !== "" && !this.isBlockStart(lines[i])) {
      contentLines.push(lines[i]);
      i++;
    }

    return {
      node: {
        type: "paragraph",
        children: this.parseInline(contentLines.join(" ")),
      },
      nextLine: i,
    };
  }

  private isBlockStart(line: string): boolean {
    const trimmed = line.trimStart();
    return (
      trimmed.startsWith("#") ||
      trimmed.startsWith("```") ||
      trimmed.startsWith(">") ||
      trimmed.startsWith("-") ||
      trimmed.startsWith("*") ||
      trimmed.startsWith("+") ||
      /^\d+[.)]\s/.test(trimmed) ||
      trimmed.startsWith("<") ||
      trimmed.startsWith("[^") // Footnote definition
    );
  }

  // --------------------------------------------------------------------------
  // Inline Parser - Complete GFM + GitHub Extensions
  // --------------------------------------------------------------------------

  private parseInline(text: string): MarkdownASTNode[] {
    const nodes: MarkdownASTNode[] = [];
    let remaining = text;

    while (remaining.length > 0) {
      // Code inline (highest priority)
      const codeMatch = remaining.match(/^`([^`]+)`/);
      if (codeMatch) {
        nodes.push({ type: "code_inline", content: codeMatch[1] });
        remaining = remaining.slice(codeMatch[0].length);
        continue;
      }

      // Math inline $...$
      const mathMatch = remaining.match(/^\$([^$]+)\$/);
      if (mathMatch) {
        nodes.push({
          type: "math_inline",
          mathContent: mathMatch[1],
        });
        remaining = remaining.slice(mathMatch[0].length);
        continue;
      }

      // Bold + Italic ***...***
      const boldItalicMatch = remaining.match(/^\*\*\*(.+?)\*\*\*/);
      if (boldItalicMatch) {
        nodes.push({
          type: "bold",
          children: [{ type: "italic", children: [{ type: "text", content: boldItalicMatch[1] }] }],
        });
        remaining = remaining.slice(boldItalicMatch[0].length);
        continue;
      }

      // Bold **...**
      const boldMatch = remaining.match(/^\*\*(.+?)\*\*/);
      if (boldMatch) {
        nodes.push({
          type: "bold",
          children: [{ type: "text", content: boldMatch[1] }],
        });
        remaining = remaining.slice(boldMatch[0].length);
        continue;
      }

      // Italic *...*
      const italicMatch = remaining.match(/^\*(.+?)\*/);
      if (italicMatch) {
        nodes.push({
          type: "italic",
          children: [{ type: "text", content: italicMatch[1] }],
        });
        remaining = remaining.slice(italicMatch[0].length);
        continue;
      }

      // Strikethrough ~~...~~
      const strikeMatch = remaining.match(/^~~(.+?)~~/);
      if (strikeMatch) {
        nodes.push({
          type: "strikethrough",
          children: [{ type: "text", content: strikeMatch[1] }],
        });
        remaining = remaining.slice(strikeMatch[0].length);
        continue;
      }

      // Subscript <sub>...</sub> (GFM extension)
      const subMatch = remaining.match(/^<sub>(.+?)<\/sub>/);
      if (subMatch) {
        nodes.push({
          type: "subscript",
          children: [{ type: "text", content: subMatch[1] }],
        });
        remaining = remaining.slice(subMatch[0].length);
        continue;
      }

      // Superscript <sup>...</sup> (GFM extension)
      const supMatch = remaining.match(/^<sup>(.+?)<\/sup>/);
      if (supMatch) {
        nodes.push({
          type: "superscript",
          children: [{ type: "text", content: supMatch[1] }],
        });
        remaining = remaining.slice(supMatch[0].length);
        continue;
      }

      // Underline <u>...</u> (GFM extension)
      const uMatch = remaining.match(/^<u>(.+?)<\/u>/);
      if (uMatch) {
        nodes.push({
          type: "underline",
          children: [{ type: "text", content: uMatch[1] }],
        });
        remaining = remaining.slice(uMatch[0].length);
        continue;
      }

      // Highlight <mark>...</mark> (GFM extension)
      const markMatch = remaining.match(/^<mark>(.+?)<\/mark>/);
      if (markMatch) {
        nodes.push({
          type: "highlight",
          children: [{ type: "text", content: markMatch[1] }],
        });
        remaining = remaining.slice(markMatch[0].length);
        continue;
      }

      // Keyboard <kbd>...</kbd> (GFM extension)
      const kbdMatch = remaining.match(/^<kbd>(.+?)<\/kbd>/);
      if (kbdMatch) {
        nodes.push({
          type: "keyboard",
          children: [{ type: "text", content: kbdMatch[1] }],
        });
        remaining = remaining.slice(kbdMatch[0].length);
        continue;
      }

      // Footnote reference [^label]
      const footnoteRefMatch = remaining.match(/^\[\^([^\]]+)\]/);
      if (footnoteRefMatch) {
        nodes.push({
          type: "footnote_ref",
          footnoteId: footnoteRefMatch[1],
        });
        remaining = remaining.slice(footnoteRefMatch[0].length);
        continue;
      }

      // Image ![alt](src)
      const imageMatch = remaining.match(/^!\[([^\]]*)\]\(([^)]+)\)/);
      if (imageMatch) {
        nodes.push({
          type: "image",
          content: imageMatch[1],
          attributes: { src: imageMatch[2] },
        });
        remaining = remaining.slice(imageMatch[0].length);
        continue;
      }

      // Link [text](href)
      const linkMatch = remaining.match(/^\[([^\]]+)\]\(([^)]+)\)/);
      if (linkMatch) {
        nodes.push({
          type: "link",
          content: linkMatch[1],
          attributes: { href: linkMatch[2] },
        });
        remaining = remaining.slice(linkMatch[0].length);
        continue;
      }

      // Autolink <url> or bare URL
      const autolinkMatch = remaining.match(/^<(https?:\/\/[^>]+)>/);
      if (autolinkMatch) {
        nodes.push({
          type: "autolink",
          content: autolinkMatch[1],
          attributes: { href: autolinkMatch[1] },
        });
        remaining = remaining.slice(autolinkMatch[0].length);
        continue;
      }

      // Emoji :shortcode:
      const emojiMatch = remaining.match(/^:([a-zA-Z0-9_]+):/);
      if (emojiMatch) {
        nodes.push({
          type: "emoji",
          emojiName: emojiMatch[1],
        });
        remaining = remaining.slice(emojiMatch[0].length);
        continue;
      }

      // Color model #RRGGBB, rgb(), hsl()
      const colorHexMatch = remaining.match(/^`#([0-9a-fA-F]{6})`/);
      if (colorHexMatch) {
        nodes.push({
          type: "color",
          colorValue: `#${colorHexMatch[1]}`,
          colorFormat: "hex",
        });
        remaining = remaining.slice(colorHexMatch[0].length);
        continue;
      }

      const colorRgbMatch = remaining.match(/^`rgb\((\d+),\s*(\d+),\s*(\d+)\)`/);
      if (colorRgbMatch) {
        nodes.push({
          type: "color",
          colorValue: `rgb(${colorRgbMatch[1]}, ${colorRgbMatch[2]}, ${colorRgbMatch[3]})`,
          colorFormat: "rgb",
        });
        remaining = remaining.slice(colorRgbMatch[0].length);
        continue;
      }

      const colorHslMatch = remaining.match(/^`hsl\((\d+),\s*(\d+)%,\s*(\d+)%\)`/);
      if (colorHslMatch) {
        nodes.push({
          type: "color",
          colorValue: `hsl(${colorHslMatch[1]}, ${colorHslMatch[2]}%, ${colorHslMatch[3]}%)`,
          colorFormat: "hsl",
        });
        remaining = remaining.slice(colorHslMatch[0].length);
        continue;
      }

      // HTML tag (pass through)
      const htmlMatch = remaining.match(/^<[^>]+>/);
      if (htmlMatch) {
        nodes.push({
          type: "raw_html",
          content: htmlMatch[0],
          isHTML: true,
        });
        remaining = remaining.slice(htmlMatch[0].length);
        continue;
      }

      // Text (consume until next special character)
      const textMatch = remaining.match(/^[^*_~`!\[<:$]+/);
      if (textMatch) {
        nodes.push({ type: "text", content: textMatch[0] });
        remaining = remaining.slice(textMatch[0].length);
        continue;
      }

      // Single special character
      nodes.push({ type: "text", content: remaining[0] });
      remaining = remaining.slice(1);
    }

    return nodes;
  }
}
