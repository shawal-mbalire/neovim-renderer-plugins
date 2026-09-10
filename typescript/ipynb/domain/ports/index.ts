/**
 * ipynb Domain Ports
 */

import type { Notebook } from "../models/types";
import type { RenderResult } from "../../../shared/models/types";
import type { ParserPort, RendererPort } from "../../../shared/ports";

// ============================================================================
// Notebook Parser Port
// ============================================================================

export interface NotebookParserPort extends ParserPort<string, Notebook> {
  parse(json: string): Notebook;
}

// ============================================================================
// Notebook Renderer Port
// ============================================================================

export interface NotebookRendererPort extends RendererPort<Notebook> {
  render(notebook: Notebook, startLine?: number): RenderResult;
}
