/**
 * Image Domain Ports
 */

import type { ImageInfo, TerminalInfo } from "../models/types";

// ============================================================================
// Image Loader Port
// ============================================================================

export interface ImageLoaderPort {
  load(path: string): Promise<ImageInfo>;
  getInfo(path: string): Promise<ImageInfo>;
}

// ============================================================================
// Image Renderer Port
// ============================================================================

export interface ImageRendererPort {
  render(imageInfo: ImageInfo): string;
  getTerminalInfo(): TerminalInfo;
}
