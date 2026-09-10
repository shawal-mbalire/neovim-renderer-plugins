/**
 * Shared Domain Constants
 * Named business constants - no magic numbers
 */

// ============================================================================
// Rendering Constants
// ============================================================================

export const MAX_HEADING_LEVEL = 6;
export const MIN_HEADING_LEVEL = 1;
export const HORIZONTAL_RULE_MIN_LENGTH = 3;
export const TABLE_SEPARATOR_PATTERN = /^[-:]+$/;

// ============================================================================
// Image Constants
// ============================================================================

export const DEFAULT_MAX_IMAGE_WIDTH = 800;
export const DEFAULT_MAX_IMAGE_HEIGHT = 600;
export const KITTY_CHUNK_SIZE = 4096;
export const IMAGE_EXTENSIONS: ReadonlySet<string> = new Set([
  "png", "jpeg", "jpg", "gif", "webp", "bmp", "tiff",
]);

// ============================================================================
// Debounce Constants
// ============================================================================

export const DEFAULT_DEBOUNCE_MS = 100;
export const MIN_DEBOUNCE_MS = 10;
export const MAX_DEBOUNCE_MS = 1000;

// ============================================================================
// Output Constants
// ============================================================================

export const DEFAULT_MAX_OUTPUT_LINES = 100;
export const MAX_OUTPUT_LINES = 1000;

// ============================================================================
// Highlight Group Names
// ============================================================================

export const HIGHLIGHT_GROUPS = {
  HEADING_1: "RendererHeading1",
  HEADING_2: "RendererHeading2",
  HEADING_3: "RendererHeading3",
  HEADING_4: "RendererHeading4",
  HEADING_5: "RendererHeading5",
  HEADING_6: "RendererHeading6",
  BOLD: "RendererBold",
  ITALIC: "RendererItalic",
  STRIKETHROUGH: "RendererStrike",
  CODE: "RendererCode",
  CODE_BLOCK: "RendererCodeBlock",
  LINK: "RendererLink",
  IMAGE: "RendererImage",
  LIST: "RendererList",
  TASK_DONE: "RendererTaskDone",
  TASK_TODO: "RendererTaskTodo",
  TABLE: "RendererTable",
  BLOCKQUOTE: "RendererBlockquote",
  ALERT: "RendererAlert",
  MATH: "RendererMath",
  HR: "RendererHr",
  CELL_HEADER: "RendererCellHeader",
  OUTPUT: "RendererOutput",
  ERROR: "RendererError",
} as const;
