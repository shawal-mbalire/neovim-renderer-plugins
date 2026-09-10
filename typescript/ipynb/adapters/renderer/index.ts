/**
 * ipynb Renderer Adapter
 * Converts notebook to render commands
 */

import type { Notebook, Cell, Output } from "../../domain/models/types";
import type { NotebookRendererPort } from "../../domain/ports";
import type { RenderResult, RenderMark } from "../../../shared/models/types";
import { createRenderResult, createRenderMark } from "../../../shared/models/types";

// ============================================================================
// Highlight Groups
// ============================================================================

const HIGHLIGHT_MAP: Record<string, string> = {
  cell_header: "Comment",
  code_cell: "Special",
  output: "Delimiter",
  output_text: "Normal",
  error: "ErrorMsg",
  image: "Underlined",
  kernel_name: "Identifier",
};

// ============================================================================
// Renderer Implementation
// ============================================================================

export class NotebookRenderer implements NotebookRendererPort {
  private currentLine = 0;

  render(notebook: Notebook, startLine: number = 0): RenderResult {
    this.currentLine = startLine;
    const lines: any[] = [];
    const errors: RenderResult["errors"] = [];

    // Notebook header
    const kernel = notebook.metadata.kernelspec as Record<string, string> | undefined;
    let header = "=== Jupyter Notebook";
    if (kernel?.display_name) {
      header += ` (${kernel.display_name})`;
    }
    header += " ===";

    lines.push({
      line: this.currentLine,
      text: header,
      marks: [createRenderMark(this.currentLine, 0, header.length, "cell_header")],
      images: [],
    });
    this.currentLine++;

    lines.push({
      line: this.currentLine,
      text: "",
      marks: [],
      images: [],
    });
    this.currentLine++;

    // Render cells
    for (let i = 0; i < notebook.cells.length; i++) {
      this.renderCell(notebook.cells[i], i + 1, lines);
    }

    return createRenderResult(lines, errors);
  }

  private renderCell(cell: Cell, cellIndex: number, lines: any[]): void {
    const cellType = cell.cell_type;
    const source = cell.source;
    const outputs = cell.outputs || [];
    const executionCount = cell.execution_count;

    // Cell header
    let headerText = `─── Cell ${cellIndex}: ${cellType.toUpperCase()}`;
    if (executionCount !== null && executionCount !== undefined) {
      headerText += ` [${executionCount}]`;
    }
    headerText += " ───";

    lines.push({
      line: this.currentLine,
      text: headerText,
      marks: [createRenderMark(this.currentLine, 0, headerText.length, "cell_header")],
      images: [],
    });
    this.currentLine++;

    // Source code
    const hlGroup = cellType === "code" ? "code_cell" : undefined;
    for (const sourceLine of source) {
      const content = sourceLine.replace(/\n$/, "").replace(/\r$/, "");
      lines.push({
        line: this.currentLine,
        text: content,
        marks: hlGroup ? [createRenderMark(this.currentLine, 0, content.length, hlGroup)] : [],
        images: [],
      });
      this.currentLine++;
    }

    // Outputs
    if (cellType === "code" && outputs.length > 0) {
      lines.push({
        line: this.currentLine,
        text: "┌─ Output:",
        marks: [createRenderMark(this.currentLine, 0, 10, "output")],
        images: [],
      });
      this.currentLine++;

      for (const output of outputs) {
        this.renderOutput(output, lines);
      }

      lines.push({
        line: this.currentLine,
        text: "└─────────",
        marks: [createRenderMark(this.currentLine, 0, 10, "output")],
        images: [],
      });
      this.currentLine++;
    }

    lines.push({
      line: this.currentLine,
      text: "",
      marks: [],
      images: [],
    });
    this.currentLine++;
  }

  private renderOutput(output: Output, lines: any[]): void {
    switch (output.output_type) {
      case "stream":
        this.renderStreamOutput(output, lines);
        break;
      case "error":
        this.renderErrorOutput(output, lines);
        break;
      case "execute_result":
      case "display_data":
        this.renderDataOutput(output, lines);
        break;
    }
  }

  private renderStreamOutput(output: Output, lines: any[]): void {
    const text = output.text || [];
    for (const line of text) {
      const content = line.replace(/\n$/, "").replace(/\r$/, "");
      lines.push({
        line: this.currentLine,
        text: `│ ${content}`,
        marks: [createRenderMark(this.currentLine, 0, 2, "output")],
        images: [],
      });
      this.currentLine++;
    }
  }

  private renderErrorOutput(output: Output, lines: any[]): void {
    const traceback = output.traceback || [];
    for (const line of traceback) {
      const content = line.replace(/\x1B\[[0-9;]*m/g, "").replace(/\n$/, "").replace(/\r$/, "");
      lines.push({
        line: this.currentLine,
        text: `│ ${content}`,
        marks: [createRenderMark(this.currentLine, 0, content.length + 2, "error")],
        images: [],
      });
      this.currentLine++;
    }
  }

  private renderDataOutput(output: Output, lines: any[]): void {
    const data = output.data || {};

    if (data["text/plain"]) {
      const textContent = Array.isArray(data["text/plain"])
        ? data["text/plain"]
        : [data["text/plain"] as string];

      for (const textLine of textContent) {
        const content = (textLine as string).replace(/\n$/, "").replace(/\r$/, "");
        lines.push({
          line: this.currentLine,
          text: `│ ${content}`,
          marks: [createRenderMark(this.currentLine, 2, content.length + 2, "output_text")],
          images: [],
        });
        this.currentLine++;
      }
    } else if (data["image/png"] || data["image/jpeg"]) {
      lines.push({
        line: this.currentLine,
        text: "│ [Image]",
        marks: [createRenderMark(this.currentLine, 0, 10, "image")],
        images: [],
      });
      this.currentLine++;
    }
  }
}
