/**
 * ipynb Plugin - Main entry point
 */

import { IpynbParser } from "./adapters/parser";
import { NotebookRenderer } from "./adapters/renderer";
import { ProcessNotebookWorkflow } from "./domain/workflows";
import type { RenderResult } from "../../shared/domain/models/types";

// ============================================================================
// Plugin Factory
// ============================================================================

export interface IpynbPlugin {
  process(json: string): RenderResult;
}

export function createIpynbPlugin(): IpynbPlugin {
  const parser = new IpynbParser();
  const renderer = new NotebookRenderer();
  const workflow = new ProcessNotebookWorkflow(parser, renderer);

  return {
    process(json: string): RenderResult {
      return workflow.execute(json);
    },
  };
}

// ============================================================================
// Re-exports
// ============================================================================

export * from "./domain";
export * from "./adapters";
