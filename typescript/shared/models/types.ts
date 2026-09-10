/**
 * Shared Domain Models
 * Pure data structures used across all plugins
 */

// ============================================================================
// StrEnum Pattern - Typed string unions
// ============================================================================

export type RenderSeverity = "error" | "warning" | "info";
export type FileType = "markdown" | "ipynb" | "html";
export type ImageFormat = "png" | "jpeg" | "gif" | "webp" | "svg";
export type ImageProtocol = "kgp" | "kgp_old" | "iip" | "sixel" | "none";

// ============================================================================
// Render Types
// ============================================================================

export interface RenderMark {
  readonly line: number;
  readonly col: number;
  readonly end_col: number;
  readonly hl: string;
  readonly virt_text?: string;
}

export interface RenderImage {
  readonly col: number;
  readonly row: number;
  readonly width: number;
  readonly height: number;
  readonly path?: string;
  readonly placeholder?: string;
}

export interface RenderLine {
  readonly line: number;
  readonly text: string;
  readonly marks: ReadonlyArray<RenderMark>;
  readonly images: ReadonlyArray<RenderImage>;
}

export interface RenderResult {
  readonly lines: ReadonlyArray<RenderLine>;
  readonly errors: ReadonlyArray<RenderError>;
}

export interface RenderError {
  readonly line: number;
  readonly column: number;
  readonly message: string;
  readonly severity: RenderSeverity;
}

// ============================================================================
// Plugin Communication
// ============================================================================

export interface PluginMessage {
  readonly type: "update" | "open" | "render" | "error";
  readonly content?: string;
  readonly filetype?: string;
  readonly path?: string;
  readonly data?: RenderResult;
  readonly message?: string;
}

// ============================================================================
// Factory Functions
// ============================================================================

export function createRenderLine(
  line: number,
  text: string,
  marks: RenderMark[] = [],
  images: RenderImage[] = []
): RenderLine {
  return { line, text, marks, images };
}

export function createRenderMark(
  line: number,
  col: number,
  end_col: number,
  hl: string
): RenderMark {
  return { line, col, end_col, hl };
}

export function createRenderResult(
  lines: RenderLine[] = [],
  errors: RenderError[] = []
): RenderResult {
  return { lines, errors };
}

export function createRenderError(
  line: number,
  column: number,
  message: string,
  severity: RenderSeverity = "error"
): RenderError {
  return { line, column, message, severity };
}
