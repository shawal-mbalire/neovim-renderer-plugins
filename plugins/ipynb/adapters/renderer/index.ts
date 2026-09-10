/**
 * Notebook Renderer Adapter
 * Renders notebook cells to Neovim render commands
 */

import type { Notebook, Cell, CellType, Output } from "../../domain/models/types";
import type { NotebookRendererPort } from "../../domain/ports";
import type { RenderResult, RenderLine, RenderMark } from "../../../../shared/domain/models/types";
import { OutputRenderer } from "./output-renderer";
import { MarkdownParser } from "../../../markdown/adapters/parser";

// ============================================================================
// Highlight Groups
// ============================================================================

const HIGHLIGHTS = {
  cell_header: "Comment",
  cell_type_code: "Keyword",
  cell_type_markdown: "String",
  cell_type_raw: "Delimiter",
  code_block: "Special",
  output_header: "Comment",
  output_border: "Delimiter",
  error: "ErrorMsg",
  image_placeholder: "Underlined",
  latex_placeholder: "Special",
  html_placeholder: "PreProc",
  json_placeholder: "Constant",
} as const;

// ============================================================================
// Notebook Renderer Implementation
// ============================================================================

export class NotebookRenderer implements NotebookRendererPort {
  private outputRenderer: OutputRenderer;
  private markdownParser: MarkdownParser;
  private currentLine = 0;

  constructor() {
    this.outputRenderer = new OutputRenderer();
    this.markdownParser = new MarkdownParser();
  }

  render(notebook: Notebook, startLine: number = 0): RenderResult {
    this.currentLine = startLine;
    const lines: RenderLine[] = [];
    const errors: RenderResult["errors"] = [];

    // Add notebook header
    this.addNotebookHeader(notebook, lines);

    // Render each cell
    for (let i = 0; i < notebook.cells.length; i++) {
      this.renderCell(notebook.cells[i], i, lines);
    }

    return { lines, errors };
  }

  // --------------------------------------------------------------------------
  // Cell Renderer
  // --------------------------------------------------------------------------

  private renderCell(cell: Cell, index: number, lines: RenderLine[]): void {
    // Cell header
    const header = this.getCellHeader(cell, index);
    lines.push({
      line: this.currentLine,
      text: header,
      marks: [
        {
          col_start: 0,
          col_end: header.length,
          hl_group: HIGHLIGHTS.cell_header,
        },
      ],
      images: [],
    });
    this.currentLine++;

    // Cell source
    const source = cell.source.join("");
    if (source.trim()) {
      if (cell.cell_type === "code") {
        this.renderCodeSource(source, lines);
      } else if (cell.cell_type === "markdown") {
        this.renderMarkdownSource(source, lines);
      } else {
        this.renderRawSource(source, lines);
      }
    }

    // Cell outputs
    if (cell.cell_type === "code" && cell.outputs && cell.outputs.length > 0) {
      this.renderOutputs(cell.outputs, lines);
    }

    // Empty line after cell
    lines.push({
      line: this.currentLine,
      text: "",
      marks: [],
      images: [],
    });
    this.currentLine++;
  }

  private getCellHeader(cell: Cell, index: number): string {
    const typeLabel = cell.cell_type.toUpperCase();
    const execLabel =
      cell.cell_type === "code" && cell.execution_count !== null && cell.execution_count !== undefined
        ? ` [${cell.execution_count}]`
        : "";
    return `─── Cell ${index + 1}: ${typeLabel}${execLabel} ───`;
  }

  // --------------------------------------------------------------------------
  // Source Renderers
  // --------------------------------------------------------------------------

  private renderCodeSource(source: string, lines: RenderLine[]): void {
    const codeLines = source.split("\n");

    for (const line of codeLines) {
      lines.push({
        line: this.currentLine,
        text: line,
        marks: [
          {
            col_start: 0,
            col_end: line.length,
            hl_group: HIGHLIGHTS.code_block,
          },
        ],
        images: [],
      });
      this.currentLine++;
    }
  }

  private renderMarkdownSource(source: string, lines: RenderLine[]): void {
    // Parse markdown and render
    const ast = this.markdownParser.parse(source);
    this.renderMarkdownAST(ast, lines);
  }

  private renderMarkdownAST(
    ast: { type: string; content?: string; children?: unknown[]; level?: number },
    lines: RenderLine[]
  ): void {
    if (ast.content) {
      lines.push({
        line: this.currentLine,
        text: ast.content,
        marks: [],
        images: [],
      });
      this.currentLine++;
    }

    if (ast.children) {
      for (const child of ast.children) {
        this.renderMarkdownAST(child as { type: string; content?: string; children?: unknown[]; level?: number }, lines);
      }
    }
  }

  private renderRawSource(source: string, lines: RenderLine[]): void {
    const rawLines = source.split("\n");

    for (const line of rawLines) {
      lines.push({
        line: this.currentLine,
        text: line,
        marks: [],
        images: [],
      });
      this.currentLine++;
    }
  }

  // --------------------------------------------------------------------------
  // Output Renderers
  // --------------------------------------------------------------------------

  private renderOutputs(outputs: Output[], lines: RenderLine[]): void {
    // Output header
    lines.push({
      line: this.currentLine,
      text: "┌─ Output:",
      marks: [
        {
          col_start: 0,
          col_end: 11,
          hl_group: HIGHLIGHTS.output_header,
        },
      ],
      images: [],
    });
    this.currentLine++;

    for (const output of outputs) {
      this.renderOutput(output, lines);
    }

    // Output footer
    lines.push({
      line: this.currentLine,
      text: "└─────────",
      marks: [
        {
          col_start: 0,
          col_end: 10,
          hl_group: HIGHLIGHTS.output_header,
        },
      ],
      images: [],
    });
    this.currentLine++;
  }

  private renderOutput(output: Output, lines: RenderLine[]): void {
    const outputLines = this.outputRenderer.renderOutput(output);

    for (const line of outputLines) {
      const hlGroup = output.output_type === "error" ? HIGHLIGHTS.error : HIGHLIGHTS.output_border;

      lines.push({
        line: this.currentLine,
        text: `│ ${line}`,
        marks: [
          {
            col_start: 0,
            col_end: 2,
            hl_group: HIGHLIGHTS.output_border,
          },
          {
            col_start: 2,
            col_end: line.length + 2,
            hl_group: hlGroup,
          },
        ],
        images: this.getOutputImages(output),
      });
      this.currentLine++;
    }
  }

  private getOutputImages(output: Output): RenderLine["images"] {
    const images: RenderLine["images"] = [];

    if (output.data) {
      if (output.data["image/png"]) {
        images.push({
          col: 2,
          row: this.currentLine,
          width: 20,
          height: 10,
          data: output.data["image/png"],
          placeholder: "[PNG Image]",
        });
      } else if (output.data["image/jpeg"]) {
        images.push({
          col: 2,
          row: this.currentLine,
          width: 20,
          height: 10,
          data: output.data["image/jpeg"],
          placeholder: "[JPEG Image]",
        });
      } else if (output.data["image/svg+xml"]) {
        images.push({
          col: 2,
          row: this.currentLine,
          width: 20,
          height: 10,
          placeholder: "[SVG Image]",
        });
      }
    }

    return images;
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  private addNotebookHeader(notebook: Notebook, lines: RenderLine[]): void {
    const kernelName = notebook.metadata.kernelspec?.display_name || "Jupyter";
    const langName = notebook.metadata.language_info?.name || "";

    const header = `=== ${kernelName}${langName ? ` (${langName})` : ""} ===`;
    lines.push({
      line: this.currentLine,
      text: header,
      marks: [
        {
          col_start: 0,
          col_end: header.length,
          hl_group: HIGHLIGHTS.cell_header,
        },
      ],
      images: [],
    });
    this.currentLine++;

    // Empty line after header
    lines.push({
      line: this.currentLine,
      text: "",
      marks: [],
      images: [],
    });
    this.currentLine++;
  }
}
