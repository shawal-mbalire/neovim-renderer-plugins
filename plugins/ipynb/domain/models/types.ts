/**
 * ipynb Domain Models - Full VSCode Feature Parity
 */

// ============================================================================
// Jupyter Notebook Types
// ============================================================================

export interface Notebook {
  cells: Cell[];
  metadata: NotebookMetadata;
  nbformat: number;
  nbformat_minor: number;
}

export interface Cell {
  cell_type: CellType;
  source: string[];
  outputs?: Output[];
  execution_count?: number | null;
  metadata?: CellMetadata;
}

export type CellType = "code" | "markdown" | "raw";

export type OutputType = "stream" | "execute_result" | "display_data" | "error";

export interface Output {
  output_type: OutputType;
  name?: string;
  text?: string[];
  data?: OutputData;
  ename?: string;
  evalue?: string;
  traceback?: string[];
  execution_count?: number;
  metadata?: Record<string, unknown>;
}

export interface OutputData {
  "text/plain"?: string[];
  "text/html"?: string[];
  "text/markdown"?: string[];
  "text/latex"?: string[];
  "image/png"?: string;
  "image/jpeg"?: string;
  "image/gif"?: string;
  "image/svg+xml"?: string;
  "application/json"?: string;
  "application/javascript"?: string;
  "application/vnd.code.notebook.error"?: string;
  "application/vnd.code.notebook.stdout"?: string;
  "application/vnd.code.notebook.stderr"?: string;
  [key: string]: string[] | string | undefined;
}

export interface CellMetadata {
  collapsed?: boolean;
  editable?: boolean;
 执行时间?: number;
  tags?: string[];
  [key: string]: unknown;
}

export interface NotebookMetadata {
  kernelspec?: {
    display_name: string;
    language: string;
    name: string;
  };
  language_info?: {
    name: string;
    version: string;
    mimetype?: string;
    file_extension?: string;
    codemirror_mode?: Record<string, unknown>;
  };
  [key: string]: unknown;
}

// ============================================================================
// Rendered Cell Types
// ============================================================================

export interface RenderedCell {
  index: number;
  cell_type: CellType;
  header: string;
  source_lines: string[];
  output_lines: RenderedOutput[];
  has_outputs: boolean;
  source_highlights: CellHighlight[];
}

export interface RenderedOutput {
  output_type: OutputType;
  lines: string[];
  highlights: CellHighlight[];
  images?: OutputImage[];
}

export interface CellHighlight {
  line: number;
  col_start: number;
  col_end: number;
  hl_group: string;
}

export interface OutputImage {
  format: "png" | "jpeg" | "gif" | "svg";
  data?: string;
  path?: string;
  width?: number;
  height?: number;
}

// ============================================================================
// ipynb-specific Configuration
// ============================================================================

export interface IpynbConfig {
  showCellNumbers: boolean;
  showOutputHeaders: boolean;
  maxOutputLines: number;
  renderAllOutputs: boolean;
  enableImages: boolean;
  enableScrolling: boolean;
  outputLineLimit: number;
}
