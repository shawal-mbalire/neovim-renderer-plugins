/**
 * ipynb Domain Errors
 */

export class NotebookParseError extends Error {
  constructor(message: string) {
    super(`Notebook parse error: ${message}`);
    this.name = "NotebookParseError";
  }
}

export class InvalidNotebookFormatError extends Error {
  constructor(expected: number, actual: number) {
    super(`Invalid notebook format: expected nbformat ${expected}, got ${actual}`);
    this.name = "InvalidNotebookFormatError";
  }
}

export class CellRenderError extends Error {
  constructor(cellIndex: number, message: string) {
    super(`Cell ${cellIndex} render error: ${message}`);
    this.name = "CellRenderError";
  }
}

export class OutputRenderError extends Error {
  constructor(outputType: string, message: string) {
    super(`Output render error (${outputType}): ${message}`);
    this.name = "OutputRenderError";
  }
}
