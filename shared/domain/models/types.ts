/**
 * Shared Domain Models - Common types used across all plugins
 */

// ============================================================================
// Render Types (Output to Neovim)
// ============================================================================

export interface RenderMark {
  col_start: number;
  col_end: number;
  hl_group: string;
  virt_text?: string;
  virt_text_pos?: "inline" | "overlay" | "right_align";
  conceal?: string;
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
  is_virtual?: boolean;
}

export interface RenderResult {
  lines: RenderLine[];
  errors: RenderError[];
}

// ============================================================================
// Error Types
// ============================================================================

export interface RenderError {
  line: number;
  column: number;
  message: string;
  severity: "error" | "warning" | "info";
}

// ============================================================================
// Configuration
// ============================================================================

export interface PluginConfig {
  enabled: boolean;
  debounceMs: number;
}

// ============================================================================
// Communication Protocol
// ============================================================================

export interface PluginMessage {
  type: "update" | "open" | "render" | "error";
  content?: string;
  filetype?: string;
  path?: string;
  data?: RenderResult;
  message?: string;
}
