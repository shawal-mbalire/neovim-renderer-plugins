/**
 * Markdown Renderer Adapter
 * Converts AST to render commands
 */

import type { MarkdownASTNode } from "../../domain/models/types";
import type { MarkdownRendererPort } from "../../domain/ports";
import type { RenderResult, RenderMark } from "../../../shared/models/types";
import { createRenderResult, createRenderMark } from "../../../shared/models/types";

// ============================================================================
// Highlight Groups
// ============================================================================

const HIGHLIGHT_MAP: Record<string, string> = {
  heading1: "Title",
  heading2: "Title",
  heading3: "Identifier",
  heading4: "Identifier",
  heading5: "Type",
  heading6: "Type",
  bold: "Bold",
  italic: "Italic",
  strikethrough: "Strike",
  code: "Special",
  link: "Underlined",
  image: "Underlined",
  list: "Bullet",
  task_done: "Statement",
  task_todo: "Identifier",
  table: "Delimiter",
  blockquote: "Comment",
  hr: "Comment",
};

// ============================================================================
// Renderer Implementation
// ============================================================================

export class MarkdownRenderer implements MarkdownRendererPort {
  private currentLine = 0;

  render(ast: MarkdownASTNode, startLine: number = 0): RenderResult {
    this.currentLine = startLine;
    const lines: RenderResult["lines"] = [];
    const errors: RenderResult["errors"] = [];

    this.renderNode(ast, lines);

    return createRenderResult(lines as any[], errors);
  }

  private renderNode(node: MarkdownASTNode, lines: any[]): void {
    switch (node.type) {
      case "document":
        this.renderChildren(node, lines);
        break;
      case "heading":
        this.renderHeading(node, lines);
        break;
      case "paragraph":
        this.renderParagraph(node, lines);
        break;
      case "bold":
      case "italic":
      case "strikethrough":
        this.renderInlineFormatting(node, lines);
        break;
      case "code_block":
        this.renderCodeBlock(node, lines);
        break;
      case "blockquote":
        this.renderBlockquote(node, lines);
        break;
      case "unordered_list":
      case "ordered_list":
        this.renderList(node, lines);
        break;
      case "task_list":
        this.renderTaskList(node, lines);
        break;
      case "table":
        this.renderTable(node, lines);
        break;
      case "horizontal_rule":
        this.renderHorizontalRule(lines);
        break;
      default:
        this.renderChildren(node, lines);
    }
  }

  private renderChildren(node: MarkdownASTNode, lines: any[]): void {
    if (node.children) {
      for (const child of node.children) {
        this.renderNode(child, lines);
      }
    }
  }

  private renderHeading(node: MarkdownASTNode, lines: any[]): void {
    const level = node.level || 1;
    const content = this.getTextContent(node);
    const text = `${"#".repeat(level)} ${content}`;

    lines.push({
      line: this.currentLine,
      text,
      marks: [createRenderMark(this.currentLine, 0, text.length, `heading${level}`)],
      images: [],
    });
    this.currentLine++;
  }

  private renderParagraph(node: MarkdownASTNode, lines: any[]): void {
    const text = this.getTextContent(node);
    if (text.trim()) {
      lines.push({
        line: this.currentLine,
        text,
        marks: [],
        images: [],
      });
      this.currentLine++;
    }
  }

  private renderInlineFormatting(node: MarkdownASTNode, lines: any[]): void {
    const content = this.getTextContent(node);
    const prefix = node.type === "bold" ? "**" : node.type === "italic" ? "*" : "~~";
    const text = `${prefix}${content}${prefix}`;

    lines.push({
      line: this.currentLine,
      text,
      marks: [createRenderMark(this.currentLine, 0, text.length, node.type)],
      images: [],
    });
  }

  private renderCodeBlock(node: MarkdownASTNode, lines: any[]): void {
    const lang = node.language || "";
    const code = node.content || "";

    lines.push({
      line: this.currentLine,
      text: `\`\`\`${lang}`,
      marks: [createRenderMark(this.currentLine, 0, 3, "code")],
      images: [],
    });
    this.currentLine++;

    for (const codeLine of code.split("\n")) {
      lines.push({
        line: this.currentLine,
        text: codeLine,
        marks: [createRenderMark(this.currentLine, 0, codeLine.length, "code")],
        images: [],
      });
      this.currentLine++;
    }

    lines.push({
      line: this.currentLine,
      text: "```",
      marks: [createRenderMark(this.currentLine, 0, 3, "code")],
      images: [],
    });
    this.currentLine++;
  }

  private renderBlockquote(node: MarkdownASTNode, lines: any[]): void {
    const text = this.getTextContent(node);

    lines.push({
      line: this.currentLine,
      text: `> ${text}`,
      marks: [createRenderMark(this.currentLine, 0, 2, "blockquote")],
      images: [],
    });
    this.currentLine++;
  }

  private renderList(node: MarkdownASTNode, lines: any[]): void {
    if (!node.children) return;
    const isOrdered = node.type === "ordered_list";
    let index = 1;

    for (const item of node.children) {
      const marker = isOrdered ? `${index}. ` : "• ";
      const text = this.getTextContent(item);

      lines.push({
        line: this.currentLine,
        text: `${marker}${text}`,
        marks: [createRenderMark(this.currentLine, 0, marker.length, "list")],
        images: [],
      });
      this.currentLine++;
      index++;
    }
  }

  private renderTaskList(node: MarkdownASTNode, lines: any[]): void {
    if (!node.children) return;

    for (const item of node.children) {
      const checked = item.checked;
      const marker = checked ? "[x] " : "[ ] ";
      const text = this.getTextContent(item);
      const hl = checked ? "task_done" : "task_todo";

      lines.push({
        line: this.currentLine,
        text: `• ${marker}${text}`,
        marks: [createRenderMark(this.currentLine, 2, marker.length + 2, hl)],
        images: [],
      });
      this.currentLine++;
    }
  }

  private renderTable(node: MarkdownASTNode, lines: any[]): void {
    if (!node.children) return;

    for (const row of node.children) {
      if (!row.children) continue;

      const cells: string[] = [];
      const marks: RenderMark[] = [];
      let col = 0;

      for (const cell of row.children) {
        const text = this.getTextContent(cell);
        cells.push(`| ${text} `);
        marks.push(createRenderMark(this.currentLine, col, col + text.length + 3, "table"));
        col += text.length + 3;
      }
      cells.push("|");

      lines.push({
        line: this.currentLine,
        text: cells.join(""),
        marks,
        images: [],
      });
      this.currentLine++;
    }
  }

  private renderHorizontalRule(lines: any[]): void {
    const text = "─".repeat(60);

    lines.push({
      line: this.currentLine,
      text,
      marks: [createRenderMark(this.currentLine, 0, 60, "hr")],
      images: [],
    });
    this.currentLine++;
  }

  private getTextContent(node: MarkdownASTNode): string {
    if (node.content) return node.content;
    if (!node.children) return "";
    return node.children.map((child) => this.getTextContent(child)).join("");
  }
}
