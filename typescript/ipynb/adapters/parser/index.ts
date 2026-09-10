/**
 * ipynb Parser Adapter
 * Parses Jupyter notebook JSON format
 */

import type { Notebook, Cell, Output } from "../../domain/models/types";
import type { NotebookParserPort } from "../../domain/ports";
import { NotebookParseError } from "../../domain/errors";

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

    if (typeof obj.nbformat !== "number") {
      throw new NotebookParseError("Missing or invalid nbformat");
    }

    if (obj.nbformat < 4 || obj.nbformat > 5) {
      throw new NotebookParseError(`Invalid nbformat: expected 4-5, got ${obj.nbformat}`);
    }

    if (!Array.isArray(obj.cells)) {
      throw new NotebookParseError("Missing or invalid cells array");
    }

    const cells: Cell[] = obj.cells.map((cell, index) => this.parseCell(cell, index));
    const metadata = (obj.metadata as Record<string, unknown>) || {};

    return {
      cells,
      metadata,
      nbformat: obj.nbformat as number,
      nbformat_minor: (obj.nbformat_minor as number) || 0,
    };
  }

  private parseCell(raw: unknown, index: number): Cell {
    if (!raw || typeof raw !== "object") {
      throw new NotebookParseError(`Invalid cell at index ${index}`);
    }

    const cell = raw as Record<string, unknown>;
    const cellType = this.parseCellType(cell.cell_type);
    const source = this.parseStringArray(cell.source);

    let outputs: Output[] | undefined;
    if (cellType === "code" && Array.isArray(cell.outputs)) {
      outputs = cell.outputs.map((output, i) => this.parseOutput(output, index, i));
    }

    const execution_count = cellType === "code"
      ? (typeof cell.execution_count === "number" ? cell.execution_count : null)
      : undefined;

    return {
      cell_type: cellType,
      source,
      outputs,
      execution_count,
      metadata: (cell.metadata as Record<string, unknown>) || {},
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

  private parseOutput(raw: unknown, cellIndex: number, outputIndex: number): Output {
    if (!raw || typeof raw !== "object") {
      throw new NotebookParseError(`Invalid output at cell ${cellIndex}, output ${outputIndex}`);
    }

    const output = raw as Record<string, unknown>;
    const outputType = output.output_type as string;

    switch (outputType) {
      case "stream":
        return {
          output_type: "stream",
          name: typeof output.name === "string" ? output.name : "stdout",
          text: this.parseStringArray(output.text),
        };

      case "execute_result":
        return {
          output_type: "execute_result",
          data: (output.data as Record<string, unknown>) || {},
          execution_count: typeof output.execution_count === "number" ? output.execution_count : undefined,
        };

      case "display_data":
        return {
          output_type: "display_data",
          data: (output.data as Record<string, unknown>) || {},
        };

      case "error":
        return {
          output_type: "error",
          ename: typeof output.ename === "string" ? output.ename : "Error",
          evalue: typeof output.evalue === "string" ? output.evalue : "",
          traceback: this.parseStringArray(output.traceback),
        };

      default:
        throw new NotebookParseError(`Unknown output_type: ${outputType}`);
    }
  }

  private parseStringArray(raw: unknown): string[] {
    if (typeof raw === "string") {
      return [raw];
    }

    if (Array.isArray(raw)) {
      return raw.map((item, i) => {
        if (typeof item !== "string") {
          throw new NotebookParseError(`Invalid string at index ${i}`);
        }
        return item;
      });
    }

    return [];
  }
}

type CellType = "code" | "markdown" | "raw";
