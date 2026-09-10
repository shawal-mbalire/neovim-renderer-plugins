/**
 * Markdown Plugin - Composition Root
 * Parses markdown and outputs structured render data
 */

import { MarkdownParser } from "./adapters/parser";
import { MarkdownRenderer } from "./adapters/renderer";
import type { RenderResult } from "../shared/models/types";

export interface MarkdownPlugin {
  process(content: string): RenderResult;
}

export function createMarkdownPlugin(): MarkdownPlugin {
  const parser = new MarkdownParser();
  const renderer = new MarkdownRenderer();

  return {
    process(content: string): RenderResult {
      const ast = parser.parse(content);
      return renderer.render(ast);
    },
  };
}

export * from "./domain/models/types";
export * from "./domain/ports";
export * from "./adapters/parser";
export * from "./adapters/renderer";
