/**
 * HTML Converter Adapter
 * Converts HTML to Markdown AST or plain text
 */

import type { MarkdownASTNode } from "../../domain/models/types";
import type { HtmlConverterPort } from "../../domain/ports";

// ============================================================================
// HTML Tag Definitions
// ============================================================================

interface HtmlTagDef {
  type: MarkdownASTNode["type"];
  selfClosing?: boolean;
  inline?: boolean;
}

const HTML_TAGS: Record<string, HtmlTagDef> = {
  p: { type: "paragraph", inline: false },
  div: { type: "paragraph", inline: false },
  br: { type: "text", selfClosing: true },
  hr: { type: "horizontal_rule", selfClosing: true, inline: false },
  h1: { type: "heading", level: 1, inline: false },
  h2: { type: "heading", level: 2, inline: false },
  h3: { type: "heading", level: 3, inline: false },
  h4: { type: "heading", level: 4, inline: false },
  h5: { type: "heading", level: 5, inline: false },
  h6: { type: "heading", level: 6, inline: false },
  b: { type: "bold", inline: true },
  strong: { type: "bold", inline: true },
  i: { type: "italic", inline: true },
  em: { type: "italic", inline: true },
  del: { type: "strikethrough", inline: true },
  s: { type: "strikethrough", inline: true },
  strike: { type: "strikethrough", inline: true },
  code: { type: "code_inline", inline: true },
  pre: { type: "code_block", inline: false },
  a: { type: "link", inline: true },
  img: { type: "image", selfClosing: true, inline: true },
  ul: { type: "unordered_list", inline: false },
  ol: { type: "ordered_list", inline: false },
  li: { type: "list_item", inline: false },
  table: { type: "table", inline: false },
  tr: { type: "table_row", inline: false },
  td: { type: "table_cell", inline: true },
  th: { type: "table_cell", inline: true },
  blockquote: { type: "blockquote", inline: false },
  span: { type: "text", inline: true },
};

// ============================================================================
// HTML Converter Implementation
// ============================================================================

export class HtmlConverter implements HtmlConverterPort {
  convertToAST(html: string): MarkdownASTNode {
    const root: MarkdownASTNode = {
      type: "document",
      children: [],
    };

    const tokens = this.tokenize(html);
    this.buildAST(root, tokens, 0, tokens.length);

    return root;
  }

  convertToText(html: string): string {
    const ast = this.convertToAST(html);
    return this.astToText(ast);
  }

  // --------------------------------------------------------------------------
  // Tokenizer
  // --------------------------------------------------------------------------

  private tokenize(html: string): HtmlToken[] {
    const tokens: HtmlToken[] = [];
    let i = 0;

    while (i < html.length) {
      if (html[i] === "<") {
        // Comment
        if (html.substring(i, i + 4) === "<!--") {
          const end = html.indexOf("-->", i + 4);
          i = end === -1 ? html.length : end + 3;
          continue;
        }

        // Closing tag
        if (html[i + 1] === "/") {
          const tagMatch = html.substring(i + 2).match(/^([a-zA-Z][a-zA-Z0-9]*)/);
          if (tagMatch) {
            const tagName = tagMatch[1].toLowerCase();
            let j = i + 2 + tagMatch[0].length;
            while (j < html.length && html[j] !== ">") j++;
            tokens.push({ type: "close", tagName });
            i = j + 1;
            continue;
          }
        }

        // Opening tag
        const tagMatch = html.substring(i + 1).match(/^([a-zA-Z][a-zA-Z0-9]*)/);
        if (tagMatch) {
          const tagName = tagMatch[1].toLowerCase();
          let j = i + 1 + tagMatch[0].length;
          const attrs: Record<string, string> = {};

          // Parse attributes
          while (j < html.length && html[j] !== ">" && !(html[j] === "/" && html[j + 1] === ">")) {
            while (j < html.length && /\s/.test(html[j])) j++;
            if (html[j] === ">" || (html[j] === "/" && html[j + 1] === ">")) break;

            const attrMatch = html.substring(j).match(/^([a-zA-Z-]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|(\S+)))?/);
            if (attrMatch) {
              attrs[attrMatch[1].toLowerCase()] = attrMatch[2] ?? attrMatch[3] ?? attrMatch[4] ?? "";
              j += attrMatch[0].length;
            } else {
              j++;
            }
          }

          const selfClosing = html[j - 1] === "/" || HTML_TAGS[tagName]?.selfClosing;
          tokens.push({ type: "open", tagName, attrs, selfClosing });

          while (j < html.length && html[j] !== ">") j++;
          i = j + 1;
          continue;
        }

        // Not a valid tag
        tokens.push({ type: "text", value: "<" });
        i++;
      } else {
        // Text
        let j = i;
        while (j < html.length && html[j] !== "<") j++;
        tokens.push({ type: "text", value: html.substring(i, j) });
        i = j;
      }
    }

    return tokens;
  }

  // --------------------------------------------------------------------------
  // AST Builder
  // --------------------------------------------------------------------------

  private buildAST(parent: MarkdownASTNode, tokens: HtmlToken[], start: number, end: number): number {
    let i = start;

    while (i < end) {
      const token = tokens[i];

      if (token.type === "text") {
        const text = this.decodeEntities(token.value);
        if (text.trim()) {
          parent.children!.push({ type: "text", content: text });
        }
        i++;
      } else if (token.type === "open") {
        const tag = HTML_TAGS[token.tagName];

        if (tag?.selfClosing) {
          if (token.tagName === "img") {
            parent.children!.push({
              type: "image",
              attributes: token.attrs,
            });
          } else if (token.tagName === "br") {
            parent.children!.push({ type: "text", content: "\n" });
          } else if (token.tagName === "hr") {
            parent.children!.push({ type: "horizontal_rule" });
          }
          i++;
        } else {
          // Find matching close tag
          let depth = 1;
          let j = i + 1;
          while (j < end && depth > 0) {
            if (tokens[j].type === "open" && tokens[j].tagName === token.tagName) depth++;
            if (tokens[j].type === "close" && tokens[j].tagName === token.tagName) depth--;
            j++;
          }

          const node: MarkdownASTNode = {
            type: tag?.type || "text",
            attributes: token.attrs,
            children: [],
          };

          if (tag?.level) node.level = tag.level;

          this.buildAST(node, tokens, i + 1, j - 1);
          parent.children!.push(node);
          i = j;
        }
      } else {
        i++;
      }
    }

    return i;
  }

  // --------------------------------------------------------------------------
  // Text Extraction
  // --------------------------------------------------------------------------

  private astToText(node: MarkdownASTNode): string {
    if (node.content) return node.content;

    const childTexts = (node.children || []).map((child) => this.astToText(child));

    switch (node.type) {
      case "heading":
        return childTexts.join("") + "\n";
      case "paragraph":
        return childTexts.join("") + "\n\n";
      case "bold":
        return childTexts.join("");
      case "italic":
        return childTexts.join("");
      case "code_inline":
        return node.content || "";
      case "code_block":
        return (node.content || "") + "\n";
      case "link":
        return childTexts.join("");
      case "image":
        return `[${node.content || node.attributes?.alt || "image"}]`;
      case "blockquote":
        return childTexts.map((t) => `> ${t}`).join("\n");
      case "list_item":
        return `• ${childTexts.join("")}`;
      case "horizontal_rule":
        return "---\n";
      case "table":
        return childTexts.join("\n");
      case "raw_html":
        return node.content || "";
      default:
        return childTexts.join("");
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  private decodeEntities(text: string): string {
    return text
      .replace(/&amp;/g, "&")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .replace(/&quot;/g, '"')
      .replace(/&#39;/g, "'")
      .replace(/&#x([0-9a-f]+);/gi, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
      .replace(/&#(\d+);/g, (_, dec) => String.fromCharCode(parseInt(dec, 10)));
  }
}

// ============================================================================
// Token Types
// ============================================================================

interface HtmlTokenBase {
  type: "text" | "open" | "close";
}

interface HtmlTextToken extends HtmlTokenBase {
  type: "text";
  value: string;
}

interface HtmlOpenToken extends HtmlTokenBase {
  type: "open";
  tagName: string;
  attrs: Record<string, string>;
  selfClosing?: boolean;
}

interface HtmlCloseToken extends HtmlTokenBase {
  type: "close";
  tagName: string;
}

type HtmlToken = HtmlTextToken | HtmlOpenToken | HtmlCloseToken;
