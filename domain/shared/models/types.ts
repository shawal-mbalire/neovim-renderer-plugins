/**
 * Shared Domain Models
 * Pure data structures with zero external dependencies
 */

// ============================================================================
// StrEnum Pattern - Typed string unions
// ============================================================================

export type RenderSeverity = "error" | "warning" | "info";
export type FileType = "markdown" | "ipynb" | "html";
export type ImageFormat = "png" | "jpeg" | "gif" | "webp" | "svg";
export type ImageProtocol = "kgp" | "kgp_old" | "iip" | "sixel" | "none";
export type OutputType = "stream" | "execute_result" | "display_data" | "error";
export type CellType = "code" | "markdown" | "raw";

// ============================================================================
// Dataclass Pattern - Immutable record types
// ============================================================================

export interface RenderMark {
  readonly col_start: number;
  readonly col_end: number;
  readonly hl_group: string;
  readonly virt_text?: string;
  readonly virt_text_pos?: "inline" | "overlay" | "right_align";
}

export interface RenderImage {
  readonly col: number;
  readonly row: number;
  readonly width: number;
  readonly height: number;
  readonly data?: string;
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
// Factory Functions - Immutable construction
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
  col_start: number,
  col_end: number,
  hl_group: string,
  virt_text?: string
): RenderMark {
  return { col_start, col_end, hl_group, virt_text };
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
