/**
 * ipynb Parser Adapter
 * Parses Jupyter notebook JSON format
 */

import type { Notebook, Cell, Output, CellType, OutputType } from "../../domain/models/types";
import type { NotebookParserPort } from "../../domain/ports";
import { NotebookParseError, InvalidNotebookFormatError } from "../../domain/errors";

// ============================================================================
// ipynb Parser Implementation
// ============================================================================

export class IpynbParser implements NotebookParserPort {
  parse(json: string): Notebook {
    let raw: unknown;

    try {
      raw = JSON.parse(json);
    } catch (e) {
      throw new NotebookParseError(`Invalid JSON: ${e instanceof Error ? e.message : "unknown error"}`);
    }

    if (!raw || typeof raw !== "object") {
      throw new NotebookParseError("Input is not a JSON object");
    }

    const obj = raw as Record<string, unknown>;

    // Validate nbformat
    if (typeof obj.nbformat !== "number") {
      throw new NotebookParseError("Missing or invalid nbformat");
    }

    if (obj.nbformat < 4 || obj.nbformat > 5) {
      throw new InvalidNotebookFormatError(4, obj.nbformat);
    }

    // Parse cells
    if (!Array.isArray(obj.cells)) {
      throw new NotebookParseError("Missing or invalid cells array");
    }

    const cells: Cell[] = obj.cells.map((cell, index) => this.parseCell(cell, index));

    // Parse metadata
    const metadata = this.parseMetadata(obj.metadata);

    return {
      cells,
      metadata,
      nbformat: obj.nbformat as number,
      nbformat_minor: (obj.nbformat_minor as number) || 0,
    };
  }

  // --------------------------------------------------------------------------
  // Cell Parser
  // --------------------------------------------------------------------------

  private parseCell(raw: unknown, index: number): Cell {
    if (!raw || typeof raw !== "object") {
      throw new NotebookParseError(`Invalid cell at index ${index}`);
    }

    const cell = raw as Record<string, unknown>;

    // Validate cell_type
    const cellType = this.parseCellType(cell.cell_type);

    // Parse source
    const source = this.parseStringArray(cell.source, `cell ${index} source`);

    // Parse outputs (only for code cells)
    let outputs: Output[] | undefined;
    if (cellType === "code" && Array.isArray(cell.outputs)) {
      outputs = cell.outputs.map((output, i) => this.parseOutput(output, index, i));
    }

    // Parse execution_count
    let execution_count: number | null = null;
    if (cellType === "code") {
      execution_count = typeof cell.execution_count === "number" ? cell.execution_count : null;
    }

    // Parse metadata
    const metadata = (cell.metadata as Record<string, unknown>) || {};

    return {
      cell_type: cellType,
      source,
      outputs,
      execution_count,
      metadata,
    };
  }

  private parseCellType(value: unknown): CellType {
    if (typeof value !== "string") {
      throw new NotebookParseError("Invalid cell_type: not a string");
    }

    const validTypes: CellType[] = ["code", "markdown", "raw"];
    if (!validTypes.includes(value as CellType)) {
      throw new NotebookParseError(`Invalid cell_type: ${value}`);
    }

    return value as CellType;
  }

  // --------------------------------------------------------------------------
  // Output Parser
  // --------------------------------------------------------------------------

  private parseOutput(raw: unknown, cellIndex: number, outputIndex: number): Output {
    if (!raw || typeof raw !== "object") {
      throw new NotebookParseError(`Invalid output at cell ${cellIndex}, output ${outputIndex}`);
    }

    const output = raw as Record<string, unknown>;

    // Validate output_type
    const outputType = this.parseOutputType(output.output_type);

    // Parse based on output_type
    switch (outputType) {
      case "stream":
        return this.parseStreamOutput(output, cellIndex, outputIndex);

      case "execute_result":
        return this.parseExecuteResultOutput(output, cellIndex, outputIndex);

      case "display_data":
        return this.parseDisplayDataOutput(output, cellIndex, outputIndex);

      case "error":
        return this.parseErrorOutput(output, cellIndex, outputIndex);

      default:
        throw new NotebookParseError(`Unknown output_type: ${outputType}`);
    }
  }

  private parseOutputType(value: unknown): OutputType {
    if (typeof value !== "string") {
      throw new NotebookParseError("Invalid output_type: not a string");
    }

    const validTypes: OutputType[] = ["stream", "execute_result", "display_data", "error"];
    if (!validTypes.includes(value as OutputType)) {
      throw new NotebookParseError(`Invalid output_type: ${value}`);
    }

    return value as OutputType;
  }

  private parseStreamOutput(
    output: Record<string, unknown>,
    cellIndex: number,
    outputIndex: number
  ): Output {
    const name = typeof output.name === "string" ? output.name : "stdout";
    const text = this.parseStringArray(output.text, `cell ${cellIndex} output ${outputIndex} text`);

    return {
      output_type: "stream",
      name,
      text,
    };
  }

  private parseExecuteResultOutput(
    output: Record<string, unknown>,
    cellIndex: number,
    outputIndex: number
  ): Output {
    const data = this.parseOutputData(output.data, cellIndex, outputIndex);
    const execution_count =
      typeof output.execution_count === "number" ? output.execution_count : undefined;

    return {
      output_type: "execute_result",
      data,
      execution_count,
    };
  }

  private parseDisplayDataOutput(
    output: Record<string, unknown>,
    cellIndex: number,
    outputIndex: number
  ): Output {
    const data = this.parseOutputData(output.data, cellIndex, outputIndex);

    return {
      output_type: "display_data",
      data,
    };
  }

  private parseErrorOutput(
    output: Record<string, unknown>,
    cellIndex: number,
    outputIndex: number
  ): Output {
    const ename = typeof output.ename === "string" ? output.ename : "Error";
    const evalue = typeof output.evalue === "string" ? output.evalue : "";
    const traceback = this.parseStringArray(
      output.traceback,
      `cell ${cellIndex} output ${outputIndex} traceback`
    );

    return {
      output_type: "error",
      ename,
      evalue,
      traceback,
    };
  }

  private parseOutputData(
    raw: unknown,
    cellIndex: number,
    outputIndex: number
  ): Record<string, unknown> {
    if (!raw || typeof raw !== "object") {
      return {};
    }

    return raw as Record<string, unknown>;
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  private parseStringArray(raw: unknown, context: string): string[] {
    if (typeof raw === "string") {
      return [raw];
    }

    if (Array.isArray(raw)) {
      return raw.map((item, i) => {
        if (typeof item !== "string") {
          throw new NotebookParseError(`Invalid string in ${context} at index ${i}`);
        }
        return item;
      });
    }

    throw new NotebookParseError(`Invalid ${context}: expected string or array`);
  }

  private parseMetadata(raw: unknown): Record<string, unknown> {
    if (!raw || typeof raw !== "object") {
      return {};
    }

    return raw as Record<string, unknown>;
  }
}
