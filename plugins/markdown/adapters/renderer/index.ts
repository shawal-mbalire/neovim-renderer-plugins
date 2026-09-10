/**
 * Markdown Renderer Adapter - Full GitHub Feature Parity
 * Renders Markdown AST to Neovim render commands with all GFM extensions
 */

import type { MarkdownASTNode, AlertType } from "../../domain/models/types";
import type { MarkdownRendererPort } from "../../domain/ports";
import type { RenderResult, RenderLine, RenderMark } from "../../../../shared/domain/models/types";
import { EmojiAdapter } from "../emoji";

// ============================================================================
// Highlight Groups
// ============================================================================

const HIGHLIGHTS = {
  // Headings
  heading1: "Title",
  heading2: "Title",
  heading3: "Identifier",
  heading4: "Identifier",
  heading5: "Type",
  heading6: "Type",
  
  // Inline formatting
  bold: "Bold",
  italic: "Italic",
  strikethrough: "Strikethrough",
  underline: "Underlined",
  highlight: "Highlight",
  keyboard: "Special",
  
  // Code
  code_inline: "Special",
  code_block: "Special",
  code_fence: "Comment",
  
  // Links and images
  link: "Underlined",
  image: "Underlined",
  autolink: "Underlined",
  
  // Lists
  list_marker: "Bullet",
  task_marker: "Identifier",
  task_checked: "Statement",
  
  // Table
  table_header: "Keyword",
  table_border: "Delimiter",
  table_align: "Comment",
  
  // Blockquote
  blockquote: "Comment",
  blockquote_marker: "Special",
  
  // Alerts
  alert_note: "DiagnosticInfo",
  alert_tip: "DiagnosticOk",
  alert_important: "DiagnosticHint",
  alert_warning: "DiagnosticWarn",
  alert_caution: "DiagnosticError",
  alert_icon: "Special",
  alert_title: "Bold",
  
  // Math
  math: "Special",
  
  // Emoji
  emoji: "Special",
  
  // Color
  color: "Constant",
  
  // Footnote
  footnote_ref: "Special",
  footnote_def: "Comment",
  
  // Horizontal rule
  horizontal_rule: "Comment",
  
  // HTML
  html_tag: "PreProc",
  
  // Mermaid
  mermaid: "Special",
} as const;

// ============================================================================
// Alert Icons
// ============================================================================

const ALERT_ICONS: Record<AlertType, string> = {
  note: "ℹ️ ",
  tip: "💡 ",
  important: "❗ ",
  warning: "⚠️ ",
  caution: "🛑 ",
};

const ALERT_TITLES: Record<AlertType, string> = {
  note: "Note",
  tip: "Tip",
  important: "Important",
  warning: "Warning",
  caution: "Caution",
};

// ============================================================================
// Markdown Renderer Implementation
// ============================================================================

export class MarkdownRenderer implements MarkdownRendererPort {
  private currentLine = 0;
  private emojiAdapter: EmojiAdapter;
  private footnoteCounter = 0;

  constructor() {
    this.emojiAdapter = new EmojiAdapter();
  }

  render(ast: MarkdownASTNode, startLine: number = 0): RenderResult {
    this.currentLine = startLine;
    this.footnoteCounter = 0;
    const lines: RenderLine[] = [];
    const errors: RenderResult["errors"] = [];

    this.renderNode(ast, lines);

    return { lines, errors };
  }

  // --------------------------------------------------------------------------
  // Node Renderer
  // --------------------------------------------------------------------------

  private renderNode(node: MarkdownASTNode, lines: RenderLine[]): void {
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
      case "text":
        this.renderText(node, lines);
        break;
      case "bold":
        this.renderBold(node, lines);
        break;
      case "italic":
        this.renderItalic(node, lines);
        break;
      case "strikethrough":
        this.renderStrikethrough(node, lines);
        break;
      case "underline":
        this.renderUnderline(node, lines);
        break;
      case "highlight":
        this.renderHighlight(node, lines);
        break;
      case "keyboard":
        this.renderKeyboard(node, lines);
        break;
      case "code_inline":
        this.renderCodeInline(node, lines);
        break;
      case "code_block":
        this.renderCodeBlock(node, lines);
        break;
      case "link":
      case "autolink":
        this.renderLink(node, lines);
        break;
      case "image":
        this.renderImage(node, lines);
        break;
      case "blockquote":
        this.renderBlockquote(node, lines);
        break;
      case "alert":
        this.renderAlert(node, lines);
        break;
      case "unordered_list":
      case "ordered_list":
        this.renderList(node, lines);
        break;
      case "task_list":
        this.renderTaskList(node, lines);
        break;
      case "task_item":
        this.renderTaskItem(node, lines);
        break;
      case "table":
        this.renderTable(node, lines);
        break;
      case "horizontal_rule":
        this.renderHorizontalRule(lines);
        break;
      case "math_inline":
        this.renderMathInline(node, lines);
        break;
      case "math_display":
        this.renderMathDisplay(node, lines);
        break;
      case "emoji":
        this.renderEmoji(node, lines);
        break;
      case "color":
        this.renderColor(node, lines);
        break;
      case "footnote_ref":
        this.renderFootnoteRef(node, lines);
        break;
      case "footnote_def":
        this.renderFootnoteDef(node, lines);
        break;
      case "html_block":
      case "raw_html":
        this.renderHtml(node, lines);
        break;
      case "mermaid":
        this.renderMermaid(node, lines);
        break;
      default:
        this.renderChildren(node, lines);
    }
  }

  // --------------------------------------------------------------------------
  // Specific Renderers
  // --------------------------------------------------------------------------

  private renderChildren(node: MarkdownASTNode, lines: RenderLine[]): void {
    if (node.children) {
      for (const child of node.children) {
        this.renderNode(child, lines);
      }
    }
  }

  private renderHeading(node: MarkdownASTNode, lines: RenderLine[]): void {
    const level = node.level || 1;
    const prefix = "#".repeat(level);
    const childText = this.getTextContent(node);
    const text = `${prefix} ${childText}`;

    const hlGroup = level <= 2 ? HIGHLIGHTS.heading1 : 
                    level <= 4 ? HIGHLIGHTS.heading3 : HIGHLIGHTS.heading5;

    lines.push({
      line: this.currentLine,
      text,
      marks: [{
        col_start: 0,
        col_end: text.length,
        hl_group: hlGroup,
      }],
      images: [],
    });
    this.currentLine++;
  }

  private renderParagraph(node: MarkdownASTNode, lines: RenderLine[]): void {
    const text = this.getTextContent(node);
    if (text.trim()) {
      lines.push({
        line: this.currentLine,
        text,
        marks: this.getInlineMarks(node, 0),
        images: [],
      });
      this.currentLine++;
    }
  }

  private renderText(node: MarkdownASTNode, lines: RenderLine[]): void {
    if (node.content) {
      lines.push({
        line: this.currentLine,
        text: node.content,
        marks: [],
        images: [],
      });
    }
  }

  private renderBold(node: MarkdownASTNode, lines: RenderLine[]): void {
    const text = this.getTextContent(node);
    const boldText = `**${text}**`;
    lines.push({
      line: this.currentLine,
      text: boldText,
      marks: [{
        col_start: 0,
        col_end: boldText.length,
        hl_group: HIGHLIGHTS.bold,
      }],
      images: [],
    });
  }

  private renderItalic(node: MarkdownASTNode, lines: RenderLine[]): void {
    const text = this.getTextContent(node);
    const italicText = `*${text}*`;
    lines.push({
      line: this.currentLine,
      text: italicText,
      marks: [{
        col_start: 0,
        col_end: italicText.length,
        hl_group: HIGHLIGHTS.italic,
      }],
      images: [],
    });
  }

  private renderStrikethrough(node: MarkdownASTNode, lines: RenderLine[]): void {
    const text = this.getTextContent(node);
    const strikeText = `~~${text}~~`;
    lines.push({
      line: this.currentLine,
      text: strikeText,
      marks: [{
        col_start: 0,
        col_end: strikeText.length,
        hl_group: HIGHLIGHTS.strikethrough,
      }],
      images: [],
    });
  }

  private renderUnderline(node: MarkdownASTNode, lines: RenderLine[]): void {
    const text = this.getTextContent(node);
    const uText = `<u>${text}</u>`;
    lines.push({
      line: this.currentLine,
      text: uText,
      marks: [{
        col_start: 0,
        col_end: uText.length,
        hl_group: HIGHLIGHTS.underline,
      }],
      images: [],
    });
  }

  private renderHighlight(node: MarkdownASTNode, lines: RenderLine[]): void {
    const text = this.getTextContent(node);
    const markText = `<mark>${text}</mark>`;
    lines.push({
      line: this.currentLine,
      text: markText,
      marks: [{
        col_start: 0,
        col_end: markText.length,
        hl_group: HIGHLIGHTS.highlight,
      }],
      images: [],
    });
  }

  private renderKeyboard(node: MarkdownASTNode, lines: RenderLine[]): void {
    const text = this.getTextContent(node);
    const kbdText = `<kbd>${text}</kbd>`;
    lines.push({
      line: this.currentLine,
      text: kbdText,
      marks: [{
        col_start: 0,
        col_end: kbdText.length,
        hl_group: HIGHLIGHTS.keyboard,
      }],
      images: [],
    });
  }

  private renderCodeInline(node: MarkdownASTNode, lines: RenderLine[]): void {
    const code = node.content || "";
    const codeText = `\`${code}\``;
    lines.push({
      line: this.currentLine,
      text: codeText,
      marks: [{
        col_start: 0,
        col_end: codeText.length,
        hl_group: HIGHLIGHTS.code_inline,
      }],
      images: [],
    });
  }

  private renderCodeBlock(node: MarkdownASTNode, lines: RenderLine[]): void {
    const lang = node.language || "";
    const code = node.content || "";

    // Opening fence
    lines.push({
      line: this.currentLine,
      text: `\`\`\`${lang}`,
      marks: [{
        col_start: 0,
        col_end: lang ? lang.length + 3 : 3,
        hl_group: HIGHLIGHTS.code_fence,
      }],
      images: [],
    });
    this.currentLine++;

    // Code lines
    for (const codeLine of code.split("\n")) {
      lines.push({
        line: this.currentLine,
        text: codeLine,
        marks: [{
          col_start: 0,
          col_end: codeLine.length,
          hl_group: HIGHLIGHTS.code_block,
        }],
        images: [],
      });
      this.currentLine++;
    }

    // Closing fence
    lines.push({
      line: this.currentLine,
      text: "```",
      marks: [{
        col_start: 0,
        col_end: 3,
        hl_group: HIGHLIGHTS.code_fence,
      }],
      images: [],
    });
    this.currentLine++;
  }

  private renderLink(node: MarkdownASTNode, lines: RenderLine[]): void {
    const text = this.getTextContent(node);
    const href = node.attributes?.href || "";
    const linkText = `[${text}](${href})`;
    lines.push({
      line: this.currentLine,
      text: linkText,
      marks: [{
        col_start: 0,
        col_end: linkText.length,
        hl_group: HIGHLIGHTS.link,
      }],
      images: [],
    });
  }

  private renderImage(node: MarkdownASTNode, lines: RenderLine[]): void {
    const alt = node.content || node.attributes?.alt || "image";
    const src = node.attributes?.src || "";
    lines.push({
      line: this.currentLine,
      text: `![${alt}](${src})`,
      marks: [{
        col_start: 0,
        col_end: `[${alt}]`.length + 2,
        hl_group: HIGHLIGHTS.image,
      }],
      images: [{
        col: 0,
        row: this.currentLine,
        width: 20,
        height: 10,
        path: src,
        placeholder: `[Image: ${alt}]`,
      }],
    });
    this.currentLine++;
  }

  private renderBlockquote(node: MarkdownASTNode, lines: RenderLine[]): void {
    const text = this.getTextContent(node);
    const quoteText = `> ${text}`;
    lines.push({
      line: this.currentLine,
      text: quoteText,
      marks: [{
        col_start: 0,
        col_end: quoteText.length,
        hl_group: HIGHLIGHTS.blockquote,
      }],
      images: [],
    });
    this.currentLine++;
  }

  private renderAlert(node: MarkdownASTNode, lines: RenderLine[]): void {
    const alertType = node.alertType || "note";
    const icon = ALERT_ICONS[alertType];
    const title = ALERT_TITLES[alertType];
    const text = this.getTextContent(node);

    // Alert header
    lines.push({
      line: this.currentLine,
      text: `${icon}**${title}**`,
      marks: [{
        col_start: 0,
        col_end: icon.length + title.length + 2,
        hl_group: HIGHLIGHTS[`alert_${alertType}`],
      }],
      images: [],
    });
    this.currentLine++;

    // Alert content
    if (text.trim()) {
      lines.push({
        line: this.currentLine,
        text: `  ${text}`,
        marks: [{
          col_start: 2,
          col_end: text.length + 2,
          hl_group: HIGHLIGHTS[`alert_${alertType}`],
        }],
        images: [],
      });
      this.currentLine++;
    }
  }

  private renderList(node: MarkdownASTNode, lines: RenderLine[]): void {
    if (!node.children) return;
    const isOrdered = node.type === "ordered_list";
    let index = 1;

    for (const item of node.children) {
      const marker = isOrdered ? `${index}. ` : "• ";
      const text = this.getTextContent(item);
      lines.push({
        line: this.currentLine,
        text: `${marker}${text}`,
        marks: [{
          col_start: 0,
          col_end: marker.length,
          hl_group: HIGHLIGHTS.list_marker,
        }],
        images: [],
      });
      this.currentLine++;
      index++;
    }
  }

  private renderTaskList(node: MarkdownASTNode, lines: RenderLine[]): void {
    if (!node.children) return;
    for (const item of node.children) {
      if (item.type === "task_item") {
        this.renderTaskItem(item, lines);
      }
    }
  }

  private renderTaskItem(node: MarkdownASTNode, lines: RenderLine[]): void {
    const checked = node.checked;
    const marker = checked ? "[x] " : "[ ] ";
    const text = this.getTextContent(node);
    lines.push({
      line: this.currentLine,
      text: `• ${marker}${text}`,
      marks: [
        {
          col_start: 0,
          col_end: 2,
          hl_group: HIGHLIGHTS.list_marker,
        },
        {
          col_start: 2,
          col_end: marker.length + 2,
          hl_group: checked ? HIGHLIGHTS.task_checked : HIGHLIGHTS.task_marker,
        },
      ],
      images: [],
    });
    this.currentLine++;
  }

  private renderTable(node: MarkdownASTNode, lines: RenderLine[]): void {
    if (!node.children || node.children.length === 0) return;
    const rows = node.children.filter((c) => c.type === "table_row");
    if (rows.length === 0) return;

    // Calculate column widths
    const colWidths: number[] = [];
    for (const row of rows) {
      if (row.children) {
        row.children.forEach((cell, i) => {
          const text = this.getTextContent(cell);
          colWidths[i] = Math.max(colWidths[i] || 0, text.length);
        });
      }
    }

    // Render rows
    for (let r = 0; r < rows.length; r++) {
      const row = rows[r];
      if (!row.children) continue;
      const cells: string[] = [];
      const marks: RenderMark[] = [];
      let col = 0;

      for (let c = 0; c < row.children.length; c++) {
        const cell = row.children[c];
        const text = this.getTextContent(cell);
        const padded = text.padEnd(colWidths[c] || 0);
        marks.push({
          col_start: col,
          col_end: col + padded.length + 1,
          hl_group: r === 0 ? HIGHLIGHTS.table_header : HIGHLIGHTS.table_border,
        });
        cells.push(`| ${padded} `);
        col += padded.length + 3;
      }
      cells.push("|");
      lines.push({
        line: this.currentLine,
        text: cells.join(""),
        marks,
        images: [],
      });
      this.currentLine++;

      // Add separator after header
      if (r === 0) {
        const separator = colWidths.map((w) => "-".repeat(w + 2)).join("|");
        lines.push({
          line: this.currentLine,
          text: `|${separator}|`,
          marks: [{
            col_start: 0,
            col_end: separator.length + 2,
            hl_group: HIGHLIGHTS.table_border,
          }],
          images: [],
        });
        this.currentLine++;
      }
    }
  }

  private renderHorizontalRule(lines: RenderLine[]): void {
    lines.push({
      line: this.currentLine,
      text: "─".repeat(60),
      marks: [{
        col_start: 0,
        col_end: 60,
        hl_group: HIGHLIGHTS.horizontal_rule,
      }],
      images: [],
    });
    this.currentLine++;
  }

  private renderMathInline(node: MarkdownASTNode, lines: RenderLine[]): void {
    const math = node.mathContent || "";
    lines.push({
      line: this.currentLine,
      text: `$${math}$`,
      marks: [{
        col_start: 0,
        col_end: math.length + 2,
        hl_group: HIGHLIGHTS.math,
      }],
      images: [],
    });
  }

  private renderMathDisplay(node: MarkdownASTNode, lines: RenderLine[]): void {
    const math = node.mathContent || "";
    lines.push({
      line: this.currentLine,
      text: `$$`,
      marks: [{
        col_start: 0,
        col_end: 2,
        hl_group: HIGHLIGHTS.math,
      }],
      images: [],
    });
    this.currentLine++;

    for (const mathLine of math.split("\n")) {
      lines.push({
        line: this.currentLine,
        text: mathLine,
        marks: [{
          col_start: 0,
          col_end: mathLine.length,
          hl_group: HIGHLIGHTS.math,
        }],
        images: [],
      });
      this.currentLine++;
    }

    lines.push({
      line: this.currentLine,
      text: `$$`,
      marks: [{
        col_start: 0,
        col_end: 2,
        hl_group: HIGHLIGHTS.math,
      }],
      images: [],
    });
    this.currentLine++;
  }

  private renderEmoji(node: MarkdownASTNode, lines: RenderLine[]): void {
    const shortcode = node.emojiName || "";
    const char = this.emojiAdapter.getChar(`:${shortcode}:`);
    const displayText = char || `:${shortcode}:`;
    lines.push({
      line: this.currentLine,
      text: displayText,
      marks: [{
        col_start: 0,
        col_end: displayText.length,
        hl_group: HIGHLIGHTS.emoji,
      }],
      images: [],
    });
  }

  private renderColor(node: MarkdownASTNode, lines: RenderLine[]): void {
    const value = node.colorValue || "";
    lines.push({
      line: this.currentLine,
      text: value,
      marks: [{
        col_start: 0,
        col_end: value.length,
        hl_group: HIGHLIGHTS.color,
      }],
      images: [],
    });
  }

  private renderFootnoteRef(node: MarkdownASTNode, lines: RenderLine[]): void {
    const id = node.footnoteId || "";
    this.footnoteCounter++;
    lines.push({
      line: this.currentLine,
      text: `[^${id}]`,
      marks: [{
        col_start: 0,
        col_end: id.length + 3,
        hl_group: HIGHLIGHTS.footnote_ref,
      }],
      images: [],
    });
  }

  private renderFootnoteDef(node: MarkdownASTNode, lines: RenderLine[]): void {
    const id = node.footnoteId || "";
    const text = node.content || "";
    lines.push({
      line: this.currentLine,
      text: `[^${id}]: ${text}`,
      marks: [{
        col_start: 0,
        col_end: id.length + text.length + 5,
        hl_group: HIGHLIGHTS.footnote_def,
      }],
      images: [],
    });
    this.currentLine++;
  }

  private renderHtml(node: MarkdownASTNode, lines: RenderLine[]): void {
    const content = node.content || "";
    lines.push({
      line: this.currentLine,
      text: content,
      marks: [{
        col_start: 0,
        col_end: content.length,
        hl_group: HIGHLIGHTS.html_tag,
      }],
      images: [],
    });
    this.currentLine++;
  }

  private renderMermaid(node: MarkdownASTNode, lines: RenderLine[]): void {
    lines.push({
      line: this.currentLine,
      text: "[Mermaid Diagram]",
      marks: [{
        col_start: 0,
        col_end: 17,
        hl_group: HIGHLIGHTS.mermaid,
      }],
      images: [{
        col: 0,
        row: this.currentLine,
        width: 40,
        height: 20,
        placeholder: "[Mermaid Diagram]",
      }],
    });
    this.currentLine++;
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  private getTextContent(node: MarkdownASTNode): string {
    if (node.content) return node.content;
    if (node.mathContent) return `$${node.mathContent}$`;
    if (node.type === "emoji") {
      const char = this.emojiAdapter.getChar(`:${node.emojiName}:`);
      return char || `:${node.emojiName}:`;
    }
    if (!node.children) return "";
    return node.children.map((child) => this.getTextContent(child)).join("");
  }

  private getInlineMarks(node: MarkdownASTNode, offset: number): RenderMark[] {
    const marks: RenderMark[] = [];
    if (node.children) {
      for (const child of node.children) {
        const text = this.getTextContent(child);
        let hlGroup: string | undefined;

        switch (child.type) {
          case "bold": hlGroup = HIGHLIGHTS.bold; break;
          case "italic": hlGroup = HIGHLIGHTS.italic; break;
          case "strikethrough": hlGroup = HIGHLIGHTS.strikethrough; break;
          case "underline": hlGroup = HIGHLIGHTS.underline; break;
          case "highlight": hlGroup = HIGHLIGHTS.highlight; break;
          case "keyboard": hlGroup = HIGHLIGHTS.keyboard; break;
          case "code_inline": hlGroup = HIGHLIGHTS.code_inline; break;
          case "link":
          case "autolink": hlGroup = HIGHLIGHTS.link; break;
          case "image": hlGroup = HIGHLIGHTS.image; break;
          case "math_inline": hlGroup = HIGHLIGHTS.math; break;
          case "emoji": hlGroup = HIGHLIGHTS.emoji; break;
          case "color": hlGroup = HIGHLIGHTS.color; break;
          case "footnote_ref": hlGroup = HIGHLIGHTS.footnote_ref; break;
        }

        if (hlGroup) {
          marks.push({
            col_start: offset,
            col_end: offset + text.length,
            hl_group: hlGroup,
          });
        }
        offset += text.length;
      }
    }
    return marks;
  }
}
