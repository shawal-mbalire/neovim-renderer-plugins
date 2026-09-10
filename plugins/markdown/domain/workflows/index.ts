/**
 * Markdown Domain Workflows
 */

import type { MarkdownASTNode, MarkdownConfig } from "../models/types";
import type { RenderResult } from "../../../../shared/domain/models/types";
import type { MarkdownParserPort, MarkdownRendererPort } from "../ports";

// ============================================================================
// Parse Markdown Workflow
// ============================================================================

export class ParseMarkdownWorkflow {
  constructor(private parser: MarkdownParserPort) {}

  execute(content: string): MarkdownASTNode {
    return this.parser.parse(content);
  }
}

// ============================================================================
// Render Markdown Workflow
// ============================================================================

export class RenderMarkdownWorkflow {
  constructor(private renderer: MarkdownRendererPort) {}

  execute(ast: MarkdownASTNode, startLine: number = 0): RenderResult {
    return this.renderer.render(ast, startLine);
  }
}

// ============================================================================
// Process Markdown Workflow (Full Pipeline)
// ============================================================================

export class ProcessMarkdownWorkflow {
  constructor(
    private parser: MarkdownParserPort,
    private renderer: MarkdownRendererPort
  ) {}

  execute(content: string, startLine: number = 0): RenderResult {
    const ast = this.parser.parse(content);
    return this.renderer.render(ast, startLine);
  }
}
