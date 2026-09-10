/**
 * Shared Domain Errors
 * Specific, self-documenting exceptions
 */

// ============================================================================
// Base Error
// ============================================================================

export class DomainError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "DomainError";
  }
}

// ============================================================================
// Parse Errors
// ============================================================================

export class ParseError extends DomainError {
  constructor(
    message: string,
    public readonly line: number,
    public readonly column: number
  ) {
    super(`Parse error at line ${line}, column ${column}: ${message}`);
    this.name = "ParseError";
  }
}

export class InvalidInputError extends DomainError {
  constructor(message: string) {
    super(`Invalid input: ${message}`);
    this.name = "InvalidInputError";
  }
}

// ============================================================================
// Notebook Errors
// ============================================================================

export class NotebookParseError extends DomainError {
  constructor(message: string) {
    super(`Notebook parse error: ${message}`);
    this.name = "NotebookParseError";
  }
}

export class InvalidNotebookFormatError extends DomainError {
  constructor(expected: number, actual: number) {
    super(`Invalid notebook format: expected nbformat ${expected}, got ${actual}`);
    this.name = "InvalidNotebookFormatError";
  }
}

// ============================================================================
// Image Errors
// ============================================================================

export class ImageLoadError extends DomainError {
  constructor(path: string, message: string) {
    super(`Failed to load image ${path}: ${message}`);
    this.name = "ImageLoadError";
  }
}

export class TerminalNotSupportedError extends DomainError {
  constructor(feature: string) {
    super(`Terminal does not support ${feature}`);
    this.name = "TerminalNotSupportedError";
  }
}

// ============================================================================
// File Errors
// ============================================================================

export class FileNotFoundError extends DomainError {
  constructor(path: string) {
    super(`File not found: ${path}`);
    this.name = "FileNotFoundError";
  }
}
