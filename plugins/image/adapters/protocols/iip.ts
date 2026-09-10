/**
 * Inline Images Protocol (IIP) Adapter - iTerm2/WezTerm
 */

import type { ImageData } from "../../domain/models/types";
import type { ImageRendererPort } from "../../domain/ports";

const ESC = "\x1b";

// ============================================================================
// IIP Renderer (iTerm2-style)
// ============================================================================

export class IipRenderer implements ImageRendererPort {
  readonly protocol = "iip" as const;

  isSupported(): boolean {
    return true;
  }

  render(image: ImageData, col: number, row: number, width?: number, height?: number): string {
    const base64 = image.data.toString("base64");

    // Build OSC 1337 sequence
    const commands: string[] = [];

    // Image dimensions
    if (width) commands.push(`width=${width}`);
    if (height) commands.push(`height=${height}`);

    // Preserve aspect ratio
    commands.push("preserveAspectRatio=1");

    // Inline the image
    const inline = `inline=1`;

    // Build the escape sequence
    const command = [inline, ...commands].join(" ");

    return `${ESC}]1337;File=${command}:${base64}${ESC}\\`;
  }

  clear(imageId?: number): string {
    // IIP doesn't have a clear command - we use newlines or cursor positioning
    return "";
  }

  // --------------------------------------------------------------------------
  // File path based display (for local files)
  // --------------------------------------------------------------------------

  renderFromFile(filePath: string, col: number, row: number, width?: number, height?: number): string {
    const commands: string[] = [];

    if (width) commands.push(`width=${width}`);
    if (height) commands.push(`height=${height}`);
    commands.push("preserveAspectRatio=1");

    const command = commands.join(" ");
    const encodedPath = Buffer.from(filePath).toString("base64");

    return `${ESC}]1337;File=${command};inline=1:${encodedPath}${ESC}\\`;
  }
}
