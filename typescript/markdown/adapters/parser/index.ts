/**
 * Markdown Parser Adapter
 * Pure TypeScript implementation
 */

import type { MarkdownASTNode } from "../../domain/models/types";
import type { MarkdownParserPort } from "../../domain/ports";
import { createMarkdownNode, createHeading, createParagraph, createCodeBlock } from "../../domain/models/types";

export class MarkdownParser implements MarkdownParserPort {
  parse(markdown: string): MarkdownASTNode {
    const lines = markdown.split("\n");
    const root: MarkdownASTNode = { type: "document", children: [] };

    let lineIndex = 0;
    while (lineIndex < lines.length) {
      const line = lines[lineIndex];

      // Code blocks
      if (line.trimStart().startsWith("```")) {
        const result = this.parseCodeBlock(lines, lineIndex);
        (root.children as MarkdownASTNode[]).push(result.node);
        lineIndex = result.nextLine;
        continue;
      }

      // Headings
      const headingMatch = line.match(/^(#{1,6})\s+(.+)$/);
      if (headingMatch) {
        (root.children as MarkdownASTNode[]).push(
          createHeading(headingMatch[1].length, headingMatch[2])
        );
        lineIndex++;
        continue;
      }

      // Horizontal rule
      if (/^(\*{3,}|-{3,}|_{3,})\s*$/.test(line.trim())) {
        (root.children as MarkdownASTNode[]).push(
          createMarkdownNode("horizontal_rule")
        );
        lineIndex++;
        continue;
      }

      // Blockquote
      if (line.trimStart().startsWith("> ")) {
        const result = this.parseBlockquote(lines, lineIndex);
        (root.children as MarkdownASTNode[]).push(result.node);
        lineIndex = result.nextLine;
        continue;
      }

      // Task list
      if (/^\s*[-*+]\s+\[[ x]\]/.test(line)) {
        const result = this.parseTaskList(lines, lineIndex);
        (root.children as MarkdownASTNode[]).push(result.node);
        lineIndex = result.nextLine;
        continue;
      }

      // Unordered list
      if (/^(\s*)([-*+])\s+/.test(line)) {
        const result = this.parseList(lines, lineIndex, false);
        (root.children as MarkdownASTNode[]).push(result.node);
        lineIndex = result.nextLine;
        continue;
      }

      // Ordered list
      if (/^(\s*)\d+[.)]\s+/.test(line)) {
        const result = this.parseList(lines, lineIndex, true);
        (root.children as MarkdownASTNode[]).push(result.node);
        lineIndex = result.nextLine;
        continue;
      }

      // Table
      if (line.includes("|") && lineIndex + 1 < lines.length && /^\|?\s*[-:]+/.test(lines[lineIndex + 1])) {
        const result = this.parseTable(lines, lineIndex);
        (root.children as MarkdownASTNode[]).push(result.node);
        lineIndex = result.nextLine;
        continue;
      }

      // Empty line
      if (line.trim() === "") {
        lineIndex++;
        continue;
      }

      // Paragraph
      const result = this.parseParagraph(lines, lineIndex);
      (root.children as MarkdownASTNode[]).push(result.node);
      lineIndex = result.nextLine;
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
          node: createCodeBlock(codeLines.join("\n"), language),
          nextLine: i + 1,
        };
      }
      codeLines.push(lines[i]);
      i++;
    }

    return {
      node: createCodeBlock(codeLines.join("\n"), language),
      nextLine: i,
    };
  }

  private parseBlockquote(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const contentLines: string[] = [];
    let i = start;

    while (i < lines.length && lines[i].trimStart().startsWith("> ")) {
      contentLines.push(lines[i].replace(/^>\s?/, ""));
      i++;
    }

    return {
      node: createMarkdownNode("blockquote", {
        children: [createParagraph(contentLines.join("\n"))],
      }),
      nextLine: i,
    };
  }

  private parseTaskList(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const items: MarkdownASTNode[] = [];
    let i = start;

    while (i < lines.length) {
      const doneMatch = lines[i].match(/^\s*[-*+]\s+\[x\]\s+(.+)$/);
      const todoMatch = lines[i].match(/^\s*[-*+]\s+\[\s\]\s+(.+)$/);

      if (doneMatch) {
        items.push(createMarkdownNode("task_item", {
          checked: true,
          children: [{ type: "text", content: doneMatch[1] }],
        }));
        i++;
      } else if (todoMatch) {
        items.push(createMarkdownNode("task_item", {
          checked: false,
          children: [{ type: "text", content: todoMatch[1] }],
        }));
        i++;
      } else {
        break;
      }
    }

    return {
      node: createMarkdownNode("task_list", { children: items }),
      nextLine: i,
    };
  }

  private parseList(lines: string[], start: number, ordered: boolean): { node: MarkdownASTNode; nextLine: number } {
    const items: MarkdownASTNode[] = [];
    let i = start;
    const pattern = ordered ? /^\s*\d+[.)]\s+(.+)$/ : /^\s*[-*+]\s+(.+)$/;

    while (i < lines.length) {
      const match = lines[i].match(pattern);
      if (match) {
        items.push(createMarkdownNode("list_item", {
          children: [{ type: "text", content: match[1] }],
        }));
        i++;
      } else {
        break;
      }
    }

    return {
      node: createMarkdownNode(ordered ? "ordered_list" : "unordered_list", { children: items }),
      nextLine: i,
    };
  }

  private parseTable(lines: string[], start: number): { node: MarkdownASTNode; nextLine: number } {
    const rows: MarkdownASTNode[] = [];
    let i = start;

    // Header
    const headerCells = lines[i].split("|").map(c => c.trim()).filter(c => c);
    rows.push(createMarkdownNode("table_row", {
      children: headerCells.map(c => createMarkdownNode("table_cell", {
        children: [{ type: "text", content: c }],
      })),
    }));
    i++;

    // Skip separator
    if (i < lines.length && /^\|?\s*[-:]+/.test(lines[i])) i++;

    // Data rows
    while (i < lines.length && lines[i].includes("|")) {
      const cells = lines[i].split("|").map(c => c.trim()).filter(c => c);
      rows.push(createMarkdownNode("table_row", {
        children: cells.map(c => createMarkdownNode("table_cell", {
          children: [{ type: "text", content: c }],
        })),
      }));
      i++;
    }

    return {
      node: createMarkdownNode("table", { children: rows }),
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
      node: createParagraph(contentLines.join(" ")),
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
      /^\d+[.)]\s/.test(trimmed)
    );
  }
}
