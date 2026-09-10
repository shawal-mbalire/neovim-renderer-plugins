/**
 * ipynb Domain Models
 * Pure data structures for Jupyter notebooks
 */

// ============================================================================
// Cell Types (StrEnum pattern)
// ============================================================================

export type CellType = "code" | "markdown" | "raw";
export type OutputType = "stream" | "execute_result" | "display_data" | "error";

// ============================================================================
// Notebook Types
// ============================================================================

export interface Notebook {
  readonly cells: ReadonlyArray<Cell>;
  readonly metadata: Record<string, unknown>;
  readonly nbformat: number;
  readonly nbformat_minor: number;
}

export interface Cell {
  readonly cell_type: CellType;
  readonly source: ReadonlyArray<string>;
  readonly outputs?: ReadonlyArray<Output>;
  readonly execution_count?: number | null;
  readonly metadata?: Record<string, unknown>;
}

export interface Output {
  readonly output_type: OutputType;
  readonly name?: string;
  readonly text?: ReadonlyArray<string>;
  readonly data?: Record<string, unknown>;
  readonly ename?: string;
  readonly evalue?: string;
  readonly traceback?: ReadonlyArray<string>;
}

export interface KernelDefinition {
  readonly name: string;
  readonly display_name: string;
  readonly language: string;
  readonly recommended: boolean;
}

// ============================================================================
// Factory Functions
// ============================================================================

export function getKernelDefinitions(): KernelDefinition[] {
  return [
    { name: "python3", display_name: "Python 3", language: "python", recommended: true },
    { name: "python2", display_name: "Python 2", language: "python", recommended: false },
    { name: "julia", display_name: "Julia", language: "julia", recommended: false },
    { name: "r", display_name: "R", language: "r", recommended: false },
    { name: "bash", display_name: "Bash", language: "bash", recommended: false },
    { name: "javascript", display_name: "JavaScript", language: "javascript", recommended: false },
    { name: "typescript", display_name: "TypeScript", language: "typescript", recommended: false },
  ];
}

export function findKernelByName(name: string): KernelDefinition | undefined {
  return getKernelDefinitions().find(k => k.name === name);
}

export function detectKernel(metadata: Record<string, unknown>): KernelDefinition | undefined {
  const kernelspec = metadata.kernelspec as Record<string, string> | undefined;
  if (kernelspec?.name) {
    return findKernelByName(kernelspec.name);
  }

  const languageInfo = metadata.language_info as Record<string, string> | undefined;
  if (languageInfo?.name) {
    return getKernelDefinitions().find(k => k.language === languageInfo.name);
  }

  return undefined;
}
