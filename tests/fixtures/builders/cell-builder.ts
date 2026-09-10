/**
 * Cell Builder
 * Fluent builder for constructing notebook cells
 */

import type { Cell, Output, CellType } from "../../../plugins/ipynb/domain/models/types";
import { OutputFactory } from "../factories/ipynb-factory";

export class CellBuilder {
  private cellType: CellType = "code";
  private sourceLines: string[] = [];
  private outputs: Output[] = [];
  private executionCount: number | null = null;
  private metadata: Record<string, unknown> = {};

  // ============================================================================
  // Cell Type
  // ============================================================================

  asCode(): this {
    this.cellType = "code";
    return this;
  }

  asMarkdown(): this {
    this.cellType = "markdown";
    return this;
  }

  asRaw(): this {
    this.cellType = "raw";
    return this;
  }

  // ============================================================================
  // Source Content
  // ============================================================================

  source(code: string): this {
    this.sourceLines = code.split("\n");
    return this;
  }

  sourceLines(lines: string[]): this {
    this.sourceLines = [...lines];
    return this;
  }

  addLine(line: string): this {
    this.sourceLines.push(line);
    return this;
  }

  // ============================================================================
  // Outputs (for code cells)
  // ============================================================================

  addOutput(output: Output): this {
    this.outputs.push(output);
    return this;
  }

  addStreamOutput(text: string, name: string = "stdout"): this {
    this.outputs.push(OutputFactory.stream([text], name));
    return this;
  }

  addTextOutput(text: string): this {
    this.outputs.push(OutputFactory.text([text]));
    return this;
  }

  addHtmlOutput(html: string): this {
    this.outputs.push(OutputFactory.html([html]));
    return this;
  }

  addErrorOutput(ename: string, evalue: string, traceback: string[]): this {
    this.outputs.push(OutputFactory.error(ename, evalue, traceback));
    return this;
  }

  addImageOutput(base64: string, format: "png" | "jpeg" = "png"): this {
    if (format === "png") {
      this.outputs.push(OutputFactory.imagePng(base64));
    } else {
      this.outputs.push(OutputFactory.imageJpeg(base64));
    }
    return this;
  }

  addJsonOutput(obj: unknown): this {
    this.outputs.push(OutputFactory.json(obj));
    return this;
  }

  addLatexOutput(latex: string): this {
    this.outputs.push(OutputFactory.latex([latex]));
    return this;
  }

  // ============================================================================
  // Execution
  // ============================================================================

  withExecutionCount(count: number): this {
    this.executionCount = count;
    return this;
  }

  executed(): this {
    this.executionCount = 1;
    return this;
  }

  // ============================================================================
  // Metadata
  // ============================================================================

  withMetadata(key: string, value: unknown): this {
    this.metadata[key] = value;
    return this;
  }

  collapsed(): this {
    this.metadata.collapsed = true;
    return this;
  }

  withTags(tags: string[]): this {
    this.metadata.tags = tags;
    return this;
  }

  // ============================================================================
  // Build
  // ============================================================================

  build(): Cell {
    return {
      cell_type: this.cellType,
      source: this.sourceLines,
      outputs: this.outputs.length > 0 ? this.outputs : undefined,
      execution_count: this.cellType === "code" ? this.executionCount : undefined,
      metadata: this.metadata,
    };
  }

  // Reset builder
  reset(): this {
    this.cellType = "code";
    this.sourceLines = [];
    this.outputs = [];
    this.executionCount = null;
    this.metadata = {};
    return this;
  }

  // ============================================================================
  // Static Factory Methods
  // ============================================================================

  static create(): CellBuilder {
    return new CellBuilder();
  }

  static codeCell(source: string): Cell {
    return CellBuilder.create()
      .asCode()
      .source(source)
      .build();
  }

  static markdownCell(source: string): Cell {
    return CellBuilder.create()
      .asMarkdown()
      .source(source)
      .build();
  }

  static codeCellWithOutput(source: string, outputText: string): Cell {
    return CellBuilder.create()
      .asCode()
      .source(source)
      .addStreamOutput(outputText)
      .executed()
      .build();
  }

  static codeCellWithError(source: string, error: string): Cell {
    return CellBuilder.create()
      .asCode()
      .source(source)
      .addErrorOutput("Error", error, [`Traceback: ${error}`])
      .build();
  }

  static markdownCellWithHeading(text: string): Cell {
    return CellBuilder.create()
      .asMarkdown()
      .source(`# ${text}`)
      .build();
  }
}
