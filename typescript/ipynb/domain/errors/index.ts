/**
 * ipynb Domain Errors
 */

import { DomainError } from "../../../shared/errors";

export class NotebookParseError extends DomainError {
  constructor(message: string) {
    super(`Notebook parse error: ${message}`);
    this.name = "NotebookParseError";
  }
}

export class InvalidNotebookFormatError extends DomainError {
  constructor(expected: number, actual: number) {
    super(
      `Invalid notebook format: expected nbformat ${expected}, got ${actual}`,
    );
    this.name = "InvalidNotebookFormatError";
  }
}
