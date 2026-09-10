/**
 * Shared Domain Models
 */

export interface RenderMark {
  col_start: number;
  col_end: number;
  hl_group: string;
  virt_text?: string;
  virt_text_pos?: "inline" | "overlay" | "right_align";
}

export interface RenderImage {
  col: number;
  row: number;
  width: number;
  height: number;
  data?: string;
  path?: string;
  placeholder?: string;
}

export interface RenderLine {
  line: number;
  text: string;
  marks: RenderMark[];
  images: RenderImage[];
}

export interface RenderResult {
  lines: RenderLine[];
  errors: RenderError[];
}

export interface RenderError {
  line: number;
  column: number;
  message: string;
  severity: "error" | "warning" | "info";
}

export interface PluginMessage {
  type: "update" | "open" | "render" | "error";
  content?: string;
  filetype?: string;
  path?: string;
  data?: RenderResult;
  message?: string;
}
