/**
 * Markdown Domain Ports
 */

import type { MarkdownASTNode } from "../models/types";
import type { RenderResult } from "../../../shared/models/types";
import type { ParserPort, RendererPort } from "../../../shared/ports";

// ============================================================================
// Markdown Parser Port
// ============================================================================

export interface MarkdownParserPort extends ParserPort<string, MarkdownASTNode> {
  parse(markdown: string): MarkdownASTNode;
}

// ============================================================================
// Markdown Renderer Port
// ============================================================================

export interface MarkdownRendererPort extends RendererPort<MarkdownASTNode> {
  render(ast: MarkdownASTNode, startLine?: number): RenderResult;
}
