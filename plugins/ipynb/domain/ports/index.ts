/**
 * ipynb Domain Ports
 */

import type { Notebook, Cell, Output, RenderedCell } from "../models/types";
import type { RenderResult } from "../../../../shared/domain/models/types";

// ============================================================================
// Notebook Parser Port
// ============================================================================

export interface NotebookParserPort {
  parse(json: string): Notebook;
}

// ============================================================================
// Cell Renderer Port
// ============================================================================

export interface CellRendererPort {
  renderCell(cell: Cell, index: number): RenderedCell;
  renderOutput(output: Output): string[];
}

// ============================================================================
// Notebook Renderer Port
// ============================================================================

export interface NotebookRendererPort {
  render(notebook: Notebook, startLine?: number): RenderResult;
}

// ============================================================================
// Output Renderer Port
// ============================================================================

export interface OutputRendererPort {
  renderStream(text: string[]): string[];
  renderExecuteResult(data: Record<string, unknown>, execution_count?: number): string[];
  renderDisplayData(data: Record<string, unknown>): string[];
  renderError(ename: string, evalue: string, traceback: string[]): string[];
  renderImage(data: string, format: string): string[];
  renderSvg(svg: string): string[];
  renderHtml(html: string[]): string[];
  renderJson(json: string): string[];
  renderLatex(latex: string[]): string[];
}
