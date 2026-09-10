/**
 * Image Domain Models - Full yazi-like Support
 */

// ============================================================================
// Image Types
// ============================================================================

export type ImageFormat = "png" | "jpeg" | "gif" | "webp" | "svg" | "bmp" | "tiff";

export interface ImageData {
  format: ImageFormat;
  width: number;
  height: number;
  data: Buffer;
  path?: string;
}

export interface ImageMetadata {
  format: ImageFormat;
  width: number;
  height: number;
  size: number;
  hasAlpha?: boolean;
  colorDepth?: number;
}

// ============================================================================
// Terminal Protocols (like yazi)
// ============================================================================

export type ImageProtocol = 
  | "kgp"           // Kitty Graphics Protocol (unicode placeholders)
  | "kgp_old"       // Kitty old protocol (chunked upload)
  | "iip"           // Inline Images Protocol (iTerm2/WezTerm)
  | "sixel"         // Sixel graphics format
  | "x11"           // X11 window overlay (Überzug++)
  | "wayland"       // Wayland window overlay (Überzug++)
  | "chafa";        // ASCII art fallback

export interface TerminalCapabilities {
  protocol: ImageProtocol;
  supported: ImageProtocol[];
  maxImageWidth: number;
  maxImageHeight: number;
  tmux?: boolean;
  zellij?: boolean;
  wsl?: boolean;
}

// ============================================================================
// Image Render Command
// ============================================================================

export interface ImageRenderCommand {
  action: "display" | "clear" | "query" | "preload";
  imageId?: number;
  path?: string;
  data?: Buffer;
  col?: number;
  row?: number;
  width?: number;
  height?: number;
  z?: number;
  // For unicode placeholders
  placeholder?: string;
}

// ============================================================================
// Image Configuration (like yazi)
// ============================================================================

export interface ImageConfig {
  enabled: boolean;
  max_width: number;
  max_height: number;
  quality: number;
  filter: "nearest" | "bilinear" | "catmulrom" | "lanczos3";
  cache_images: boolean;
  preload?: {
    enabled: boolean;
    timeout: number;
  };
}

// ============================================================================
// Image Cache (for performance)
// ============================================================================

export interface ImageCacheEntry {
  key: string;
  image: ImageData;
  timestamp: number;
  size: number;
}

// ============================================================================
// Überzug++ Configuration (for X11/Wayland)
// ============================================================================

export interface UeberzugConfig {
  scale: number;
  offset: { x: number; y: number; width: number; height: number };
}

// ============================================================================
// Chafa Configuration (ASCII fallback)
// ============================================================================

export interface ChafaConfig {
  format: "sixels" | "kitty" | "iterm2" | "symbols" | "truecolor" | "256" | "240" | "16" | "8" | "1";
  size: { width: number; height: number };
  symbols: string;
}
