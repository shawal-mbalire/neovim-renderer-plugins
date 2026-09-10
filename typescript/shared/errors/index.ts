/**
 * Shared Domain Errors
 */

export class DomainError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "DomainError";
  }
}

export class ParseError extends DomainError {
  constructor(
    message: string,
    public readonly line: number,
    public readonly column: number,
  ) {
    super(`Parse error at line ${line}, column ${column}: ${message}`);
    this.name = "ParseError";
  }
}

export class FileNotFoundError extends DomainError {
  constructor(path: string) {
    super(`File not found: ${path}`);
    this.name = "FileNotFoundError";
  }
}

export class InvalidInputError extends DomainError {
  constructor(message: string) {
    super(`Invalid input: ${message}`);
    this.name = "InvalidInputError";
  }
}
