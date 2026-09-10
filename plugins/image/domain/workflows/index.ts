/**
 * Image Domain Workflows
 */

import type { ImageData, TerminalCapabilities } from "../models/types";
import type { ImageLoaderPort, ImageRendererPort, TerminalDetectionPort } from "../ports";
import { TerminalNotSupportedError, ImageTooLargeError } from "../errors";

// ============================================================================
// Load Image Workflow
// ============================================================================

export class LoadImageWorkflow {
  constructor(private loader: ImageLoaderPort) {}

  async execute(path: string): Promise<ImageData> {
    return this.loader.load(path);
  }

  async executeFromBase64(base64: string, format: string): Promise<ImageData> {
    return this.loader.loadFromBase64(base64, format);
  }
}

// ============================================================================
// Render Image Workflow
// ============================================================================

export class RenderImageWorkflow {
  constructor(
    private renderer: ImageRendererPort,
    private terminalDetection: TerminalDetectionPort,
    private maxWidth: number,
    private maxHeight: number
  ) {}

  execute(
    image: ImageData,
    col: number,
    row: number,
    maxWidth?: number,
    maxHeight?: number
  ): string {
    const capabilities = this.terminalDetection.detect();

    if (!capabilities.kitty && !capabilities.sixel) {
      throw new TerminalNotSupportedError("image rendering");
    }

    // Check image size
    const effectiveMaxWidth = maxWidth || this.maxWidth;
    const effectiveMaxHeight = maxHeight || this.maxHeight;

    if (image.width > effectiveMaxWidth || image.height > effectiveMaxHeight) {
      throw new ImageTooLargeError(
        image.width,
        image.height,
        effectiveMaxWidth,
        effectiveMaxHeight
      );
    }

    return this.renderer.render(image, col, row, maxWidth, maxHeight);
  }
}

// ============================================================================
// Clear Image Workflow
// ============================================================================

export class ClearImageWorkflow {
  constructor(private renderer: ImageRendererPort) {}

  execute(imageId?: number): string {
    return this.renderer.clear(imageId);
  }
}

// ============================================================================
// Detect Terminal Workflow
// ============================================================================

export class DetectTerminalWorkflow {
  constructor(private terminalDetection: TerminalDetectionPort) {}

  execute(): TerminalCapabilities {
    return this.terminalDetection.detect();
  }

  async query(): Promise<TerminalCapabilities> {
    return this.terminalDetection.querySupport();
  }
}
