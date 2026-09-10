/**
 * Markdown Domain Errors
 */

export class MarkdownParseError extends Error {
  constructor(
    message: string,
    public readonly line: number,
    public readonly column: number
  ) {
    super(`Markdown parse error at line ${line}, column ${column}: ${message}`);
    this.name = "MarkdownParseError";
  }
}

export class InvalidMarkdownError extends Error {
  constructor(message: string) {
    super(`Invalid markdown: ${message}`);
    this.name = "InvalidMarkdownError";
  }
}

export class MermaidRenderError extends Error {
  constructor(message: string) {
    super(`Mermaid render failed: ${message}`);
    this.name = "MermaidRenderError";
  }
}
