/**
 * Image Domain Ports - Full yazi-like Support
 */

import type { ImageData, ImageMetadata, TerminalCapabilities, ImageProtocol, ImageRenderCommand } from "../models/types";

// ============================================================================
// Image Loader Port
// ============================================================================

export interface ImageLoaderPort {
  load(path: string): Promise<ImageData>;
  loadFromBase64(base64: string, format: string): Promise<ImageData>;
  getMetadata(path: string): Promise<ImageMetadata>;
  getSupportedFormats(): string[];
}

// ============================================================================
// Image Renderer Port (per protocol)
// ============================================================================

export interface ImageRendererPort {
  readonly protocol: ImageProtocol;
  isSupported(): boolean;
  render(image: ImageData, col: number, row: number, width?: number, height?: number): string;
  clear(imageId?: number): string;
}

// ============================================================================
// Terminal Detection Port
// ============================================================================

export interface TerminalDetectionPort {
  detect(): TerminalCapabilities;
  getProtocol(): ImageProtocol;
  isInsideTmux(): boolean;
  isInsideZellij(): boolean;
  isInsideWsl(): boolean;
}

// ============================================================================
// Image Cache Port
// ============================================================================

export interface ImageCachePort {
  get(key: string): ImageData | null;
  set(key: string, image: ImageData): void;
  has(key: string): boolean;
  clear(): void;
  size(): number;
}

// ============================================================================
// Image Preprocessor Port
// ============================================================================

export interface ImagePreprocessorPort {
  resize(image: ImageData, maxWidth: number, maxHeight: number): Promise<ImageData>;
  convert(image: ImageData, format: string): Promise<ImageData>;
  compress(image: ImageData, quality: number): Promise<ImageData>;
}

// ============================================================================
// External Tool Port (Überzug++, Chafa)
// ============================================================================

export interface ExternalToolPort {
  isAvailable(tool: string): Promise<boolean>;
  execute(command: string[]): Promise<string>;
}
