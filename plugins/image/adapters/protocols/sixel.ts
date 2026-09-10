/**
 * Sixel Graphics Format Adapter
 */

import type { ImageData } from "../../domain/models/types";
import type { ImageRendererPort } from "../../domain/ports";

const ESC = "\x1b";

// ============================================================================
// Sixel Renderer
// ============================================================================

export class SixelRenderer implements ImageRendererPort {
  readonly protocol = "sixel" as const;

  isSupported(): boolean {
    return true;
  }

  render(image: ImageData, col: number, row: number, width?: number, height?: number): string {
    // Sixel rendering requires conversion to Sixel format
    // This is typically done with tools like `img2sixel` from libsixel
    // For now, we'll provide a placeholder implementation

    // Enter synchronized output mode
    const start = `${ESC}[?2026h`;

    // Position cursor
    const position = `${ESC}[${row + 1};${col + 1}H`;

    // Sixel data would be generated here
    // For now, we'll use a simple placeholder
    const sixelPlaceholder = this.generateSixelPlaceholder(image);

    // Leave synchronized output mode
    const end = `${ESC}[?2026l`;

    return `${start}${position}${sixelPlaceholder}${end}`;
  }

  clear(imageId?: number): string {
    // Clear the area where the image was displayed
    return `${ESC}[2J${ESC}[H`;
  }

  // --------------------------------------------------------------------------
  // Sixel Generation Helpers
  // --------------------------------------------------------------------------

  private generateSixelPlaceholder(image: ImageData): string {
    // This is a simplified placeholder
    // In production, you would use a proper Sixel encoder
    return `\\x1bPq${image.width};${image.height};0\\x1b\\`;
  }
}
