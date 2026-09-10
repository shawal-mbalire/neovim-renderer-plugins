/**
 * Markdown Plugin - Main entry point
 */

import { MarkdownParser } from "./adapters/parser";
import { MarkdownRenderer } from "./adapters/renderer";
import { ProcessMarkdownWorkflow } from "./domain/workflows";
import type { RenderResult } from "../../shared/domain/models/types";

// ============================================================================
// Plugin Factory
// ============================================================================

export interface MarkdownPlugin {
  process(content: string): RenderResult;
}

export function createMarkdownPlugin(): MarkdownPlugin {
  const parser = new MarkdownParser();
  const renderer = new MarkdownRenderer();
  const workflow = new ProcessMarkdownWorkflow(parser, renderer);

  return {
    process(content: string): RenderResult {
      return workflow.execute(content);
    },
  };
}

// ============================================================================
// Re-exports
// ============================================================================

export * from "./domain";
export * from "./adapters";
