/**
 * ipynb Domain Workflows
 */

import type { Notebook, Cell, RenderedCell, IpynbConfig } from "../models/types";
import type { RenderResult } from "../../../../shared/domain/models/types";
import type { NotebookParserPort, NotebookRendererPort } from "../ports";

// ============================================================================
// Parse Notebook Workflow
// ============================================================================

export class ParseNotebookWorkflow {
  constructor(private parser: NotebookParserPort) {}

  execute(json: string): Notebook {
    return this.parser.parse(json);
  }
}

// ============================================================================
// Render Notebook Workflow
// ============================================================================

export class RenderNotebookWorkflow {
  constructor(private renderer: NotebookRendererPort) {}

  execute(notebook: Notebook, startLine: number = 0): RenderResult {
    return this.renderer.render(notebook, startLine);
  }
}

// ============================================================================
// Process Notebook Workflow (Full Pipeline)
// ============================================================================

export class ProcessNotebookWorkflow {
  constructor(
    private parser: NotebookParserPort,
    private renderer: NotebookRendererPort
  ) {}

  execute(json: string, startLine: number = 0): RenderResult {
    const notebook = this.parser.parse(json);
    return this.renderer.render(notebook, startLine);
  }
}

// ============================================================================
// Get Cell Info Workflow
// ============================================================================

export class GetCellInfoWorkflow {
  execute(notebook: Notebook, cellIndex: number): Cell | null {
    if (cellIndex < 0 || cellIndex >= notebook.cells.length) {
      return null;
    }
    return notebook.cells[cellIndex];
  }
}
