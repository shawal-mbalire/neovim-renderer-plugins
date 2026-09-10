/**
 * Shared Domain Errors
 */

export class ParseError extends Error {
  constructor(
    message: string,
    public readonly line: number,
    public readonly column: number
  ) {
    super(`Parse error at line ${line}, column ${column}: ${message}`);
    this.name = "ParseError";
  }
}

export class RenderError extends Error {
  constructor(
    message: string,
    public readonly line: number
  ) {
    super(`Render error at line ${line}: ${message}`);
    this.name = "RenderError";
  }
}

export class FileNotFoundError extends Error {
  constructor(path: string) {
    super(`File not found: ${path}`);
    this.name = "FileNotFoundError";
  }
}

export class InvalidInputError extends Error {
  constructor(message: string) {
    super(`Invalid input: ${message}`);
    this.name = "InvalidInputError";
  }
}

export class ToolNotAvailableError extends Error {
  constructor(tool: string) {
    super(`External tool not available: ${tool}`);
    this.name = "ToolNotAvailableError";
  }
}
