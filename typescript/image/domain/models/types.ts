/**
 * Image Domain Models
 * Pure data structures for image rendering
 */

// ============================================================================
// Image Types (StrEnum pattern)
// ============================================================================

export type ImageFormat = "png" | "jpeg" | "gif" | "webp" | "bmp" | "tiff";
export type ImageProtocol = "kgp" | "kgp_old" | "iip" | "sixel" | "none";

// ============================================================================
// Image Types
// ============================================================================

export interface ImageInfo {
  readonly format: ImageFormat;
  readonly width: number;
  readonly height: number;
  readonly size: number;
  readonly path: string;
}

export interface TerminalInfo {
  readonly protocol: ImageProtocol;
  readonly supported: ReadonlyArray<ImageProtocol>;
  readonly tmux: boolean;
}

// ============================================================================
// Constants
// ============================================================================

const IMAGE_EXTENSIONS: Record<string, boolean> = {
  png: true,
  jpeg: true,
  jpg: true,
  gif: true,
  webp: true,
  bmp: true,
  tiff: true,
};

// ============================================================================
// Factory Functions
// ============================================================================

export function createTerminalInfo(): TerminalInfo {
  const termValue = process.env.TERM || "";
  const termProgram = process.env.TERM_PROGRAM || "";
  const isTmux = !!process.env.TMUX;

  const supported: ImageProtocol[] = [];

  // Kitty
  if (termProgram.toLowerCase().includes("kitty") || termValue.toLowerCase().includes("kitty")) {
    if (!isTmux) {
      supported.push("kgp");
    }
    supported.push("kgp_old");
  }

  // IIP (iTerm2, WezTerm, etc.)
  const iipTerminals = ["iterm2", "wezterm", "warp", "vscode"];
  for (const terminalName of iipTerminals) {
    if (termProgram.toLowerCase().includes(terminalName)) {
      supported.push("iip");
      break;
    }
  }

  if (process.env.VSCODE_INJECTION === "1") {
    supported.push("iip");
  }

  // Sixel
  if (termValue.includes("sixel") || termProgram.toLowerCase().includes("foot")) {
    supported.push("sixel");
  }

  return {
    protocol: supported[0] || "none",
    supported,
    tmux: isTmux,
  };
}

export function isImageFile(filePath: string): boolean {
  const ext = filePath.match(/\.([^\.]+)$/)?.[1]?.toLowerCase();
  return ext ? !!IMAGE_EXTENSIONS[ext] : false;
}

export function formatFileSize(sizeBytes: number): string {
  if (sizeBytes < 1024) {
    return `${sizeBytes} B`;
  } else if (sizeBytes < 1024 * 1024) {
    return `${(sizeBytes / 1024).toFixed(1)} KB`;
  } else {
    return `${(sizeBytes / (1024 * 1024)).toFixed(1)} MB`;
  }
}
