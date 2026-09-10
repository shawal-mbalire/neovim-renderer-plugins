/**
 * Markdown Domain Ports - Complete GFM Support
 */

import type { MarkdownASTNode, AlertType } from "../models/types";
import type { RenderResult } from "../../../../shared/domain/models/types";

// ============================================================================
// Markdown Parser Port
// ============================================================================

export interface MarkdownParserPort {
  parse(markdown: string): MarkdownASTNode;
}

// ============================================================================
// Markdown Renderer Port
// ============================================================================

export interface MarkdownRendererPort {
  render(ast: MarkdownASTNode, startLine?: number): RenderResult;
}

// ============================================================================
// HTML Converter Port
// ============================================================================

export interface HtmlConverterPort {
  convertToAST(html: string): MarkdownASTNode;
  convertToText(html: string): string;
}

// ============================================================================
// Mermaid Port
// ============================================================================

export interface MermaidPort {
  isAvailable(): Promise<boolean>;
  render(code: string, theme?: string): Promise<Buffer | null>;
}

// ============================================================================
// Math Port (LaTeX)
// ============================================================================

export interface MathPort {
  isAvailable(): boolean;
  renderLatex(latex: string, display: boolean): string;
}

// ============================================================================
// Emoji Port
// ============================================================================

export interface EmojiPort {
  getChar(shortcode: string): string | null;
  getShortcode(char: string): string | null;
  getAll(): Map<string, string>;
}

// ============================================================================
// Footnote Port
// ============================================================================

export interface FootnotePort {
  parseFootnotes(content: string): { definitions: Map<string, string>; references: Map<string, string> };
  renderFootnoteSection(definitions: Map<string, string>): string;
}
