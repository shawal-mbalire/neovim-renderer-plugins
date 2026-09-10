/**
 * Markdown Parser Adapter - Pure TypeScript
 */

import type { MarkdownASTNode } from "../../domain/markdown/models/types";
import type { ParserPort } from "../../domain/shared/ports";

export class MarkdownParser implements ParserPort<string, MarkdownASTNode> {
  parse(markdown: string): MarkdownASTNode {
    const lines = markdown.split("\n");
    const root: MarkdownASTNode = { type: "document", children: [] };

    let i = 0;
    while (i < lines.length) {
      const line = lines[i];

      // Code blocks
      if (line.trimStart().startsWith("```")) {
        const result = this.parseCodeBlock(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Headings
      const headingMatch = line.match(/^(#{1,6})\s+(.+)$/);
      if (headingMatch) {
        root.children!.push({
          type: "heading",
          level: headingMatch[1].length,
          children: [{ type: "text", content: headingMatch[2] }],
        });
        i++;
        continue;
      }

      // Horizontal rule
      if (/^(\*{3,}|-{3,}|_{3,})\s*$/.test(line.trim())) {
        root.children!.push({ type: "horizontal_rule" });
        i++;
        continue;
      }

      // Alert
      const alertMatch = line.match(/^>\s*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]/i);
      if (alertMatch) {
        const result = this.parseAlert(lines, i, alertMatch[1].toLowerCase() as any);
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

      // Task list
      if (/^\s*[-*+]\s+\[[ x]\]/.test(line)) {
        const result = this.parseTaskList(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Unordered list
      if (/^(\s*)([-*+])\s+/.test(line)) {
        const result = this.parseList(lines, i, false);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Ordered list
      if (/^(\s*)\d+[.)]\s+/.test(line)) {
        const result = this.parseList(lines, i, true);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Table
      if (line.includes("|") && i + 1 < lines.length && /^\|?\s*[-:]+/.test(lines[i + 1])) {
        const result = this.parseTable(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Math display
      if (line.trimStart().startsWith("$$")) {
        const result = this.parseMathBlock(lines, i);
        root.children!.push(result.node);
        i = result.nextLine;
        continue;
      }

      // Empty line
      if (line.trim() === "") {
        i++;
        continue;
      }

      // Paragraph
      const result = this.parseParagraph(lines, i);
      root.children!.push(result.node);
      i = result.nextLine;
    }

    return root;
  }

  private parseCodeBlock(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const langMatch = lines[start].trimStart().match(/^```(\w*)/);
    const language = langMatch?.[1] || undefined;
    const codeLines: string[] = [];
    let i = start + 1;

    while (i < lines.length) {
      if (lines[i].trimStart().startsWith("```")) {
        return {
          node: { type: "code_block", content: codeLines.join("\n"), language },
          nextLine: i + 1,
        };
      }
      codeLines.push(lines[i]);
      i++;
    }

    return { node: { type: "code_block", content: codeLines.join("\n"), language }, nextLine: i };
  }

  private parseAlert(lines: string[], start: number, alertType: string): { node: MarkdownASTNode; nextLine: number } {
    const contentLines: string[] = [];
    let i = start + 1;
    while (i < lines.length && (lines[i].trimStart().startsWith("> ") || lines[i].trim() === ">")) {
      contentLines.push(lines[i].replace(/^>\s?/, ""));
      i++;
    }
    return {
      node: { type: "alert", alertType: alertType as any, children: this.parseInline(contentLines.join("\n")) },
      nextLine: i,
    };
  }

  private parseBlockquote(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const contentLines: string[] = [];
    let i = start;
    while (i < lines.length && (lines[i].trimStart().startsWith("> ") || lines[i].trim() === ">")) {
      contentLines.push(lines[i].replace(/^>\s?/, ""));
      i++;
    }
    return {
      node: { type: "blockquote", children: this.parseInline(contentLines.join("\n")) },
      nextLine: i,
    };
  }

  private parseTaskList(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const items: MarkdownASTNode[] = [];
    let i = start;
    while (i < lines.length) {
      const match = lines[i].match(/^(\s*)([-*+])\s+\[([ x])\]\s+(.+)$/);
      if (!match) break;
      items.push({ type: "task_item", checked: match[3] === "x", children: [{ type: "text", content: match[4] }] });
      i++;
    }
    return { node: { type: "task_list", children: items }, nextLine: i };
  }

  private parseList(lines: string[], start: number, ordered: boolean): { node: MarkdownASTNode; nextLine: number } {
    const items: MarkdownASTNode[] = [];
    let i = start;
    const pattern = ordered ? /^(\s*)\d+[.)]\s+(.+)$/ : /^(\s*)([-*+])\s+(.+)$/;
    while (i < lines.length) {
      const match = lines[i].match(pattern);
      if (!match) break;
      items.push({ type: "list_item", children: [{ type: "text", content: ordered ? match[2] : match[3] }] });
      i++;
    }
    return {
      node: { type: ordered ? "ordered_list" : "unordered_list", children: items },
      nextLine: i,
    };
  }

  private parseTable(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const rows: MarkdownASTNode[] = [];
    let i = start;

    // Header
    const headerCells = lines[i].split("|").map(c => c.trim()).filter(c => c);
    rows.push({
      type: "table_row",
      children: headerCells.map(c => ({ type: "table_cell", children: [{ type: "text", content: c }] })),
    });
    i++;

    // Skip separator
    if (i < lines.length && /^\|?\s*[-:]+/.test(lines[i])) i++;

    // Data rows
    while (i < lines.length && lines[i].includes("|")) {
      const cells = lines[i].split("|").map(c => c.trim()).filter(c => c);
      rows.push({
        type: "table_row",
        children: cells.map(c => ({ type: "table_cell", children: [{ type: "text", content: c }] })),
      });
      i++;
    }

    return { node: { type: "table", children: rows }, nextLine: i };
  }

  private parseMathBlock(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const mathLines: string[] = [];
    let i = start + 1;
    while (i < lines.length) {
      if (lines[i].trimEnd().endsWith("$$")) {
        return { node: { type: "math_display", mathContent: mathLines.join("\n") }, nextLine: i + 1 };
      }
      mathLines.push(lines[i]);
      i++;
    }
    return { node: { type: "math_display", mathContent: mathLines.join("\n") }, nextLine: i };
  }

  private parseParagraph(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const contentLines: string[] = [];
    let i = start;
    while (i < lines.length && lines[i].trim() !== "" && !this.isBlockStart(lines[i])) {
      contentLines.push(lines[i]);
      i++;
    }
    return {
      node: { type: "paragraph", children: this.parseInline(contentLines.join(" ")) },
      nextLine: i,
    };
  }

  private isBlockStart(line: string): boolean {
    const t = line.trimStart();
    return t.startsWith("#") || t.startsWith("```") || t.startsWith(">") ||
      t.startsWith("-") || t.startsWith("*") || t.startsWith("+") ||
      /^\d+[.)]\s/.test(t);
  }

  private parseInline(text: string): MarkdownASTNode[] {
    const nodes: MarkdownASTNode[] = [];
    let remaining = text;

    while (remaining.length > 0) {
      // Code
      const codeMatch = remaining.match(/^`([^`]+)`/);
      if (codeMatch) {
        nodes.push({ type: "code_inline", content: codeMatch[1] });
        remaining = remaining.slice(codeMatch[0].length);
        continue;
      }

      // Math
      const mathMatch = remaining.match(/^\$([^$]+)\$/);
      if (mathMatch) {
        nodes.push({ type: "math_inline", mathContent: mathMatch[1] });
        remaining = remaining.slice(mathMatch[0].length);
        continue;
      }

      // Bold+Italic
      const biMatch = remaining.match(/^\*\*\*(.+?)\*\*\*/);
      if (biMatch) {
        nodes.push({ type: "bold", children: [{ type: "italic", children: [{ type: "text", content: biMatch[1] }] }] });
        remaining = remaining.slice(biMatch[0].length);
        continue;
      }

      // Bold
      const boldMatch = remaining.match(/^\*\*(.+?)\*\*/);
      if (boldMatch) {
        nodes.push({ type: "bold", children: [{ type: "text", content: boldMatch[1] }] });
        remaining = remaining.slice(boldMatch[0].length);
        continue;
      }

      // Italic
      const italicMatch = remaining.match(/^\*(.+?)\*/);
      if (italicMatch) {
        nodes.push({ type: "italic", children: [{ type: "text", content: italicMatch[1] }] });
        remaining = remaining.slice(italicMatch[0].length);
        continue;
      }

      // Strikethrough
      const strikeMatch = remaining.match(/^~~(.+?)~~/);
      if (strikeMatch) {
        nodes.push({ type: "strikethrough", children: [{ type: "text", content: strikeMatch[1] }] });
        remaining = remaining.slice(strikeMatch[0].length);
        continue;
      }

      // Image
      const imgMatch = remaining.match(/^!\[([^\]]*)\]\(([^)]+)\)/);
      if (imgMatch) {
        nodes.push({ type: "image", content: imgMatch[1], attributes: { src: imgMatch[2] } });
        remaining = remaining.slice(imgMatch[0].length);
        continue;
      }

      // Link
      const linkMatch = remaining.match(/^\[([^\]]+)\]\(([^)]+)\)/);
      if (linkMatch) {
        nodes.push({ type: "link", content: linkMatch[1], attributes: { href: linkMatch[2] } });
        remaining = remaining.slice(linkMatch[0].length);
        continue;
      }

      // Footnote ref
      const fnMatch = remaining.match(/^\[\^([^\]]+)\]/);
      if (fnMatch) {
        nodes.push({ type: "footnote_ref", footnoteId: fnMatch[1] });
        remaining = remaining.slice(fnMatch[0].length);
        continue;
      }

      // Emoji
      const emojiMatch = remaining.match(/^:([a-zA-Z0-9_]+):/);
      if (emojiMatch) {
        nodes.push({ type: "emoji", emojiName: emojiMatch[1] });
        remaining = remaining.slice(emojiMatch[0].length);
        continue;
      }

      // Text
      const textMatch = remaining.match(/^[^*_~`!\[<:$]+/);
      if (textMatch) {
        nodes.push({ type: "text", content: textMatch[0] });
        remaining = remaining.slice(textMatch[0].length);
        continue;
      }

      // Single char
      nodes.push({ type: "text", content: remaining[0] });
      remaining = remaining.slice(1);
    }

    return nodes;
  }
}
