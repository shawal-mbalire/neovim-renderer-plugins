/**
 * Kitty Graphics Protocol Adapter
 * Renders images using Kitty terminal graphics protocol
 */

import type { ImageData } from "../../domain/models/types";
import type { ImageRendererPort } from "../../domain/ports";

// ============================================================================
// Kitty Protocol Constants
// ============================================================================

const ESC = "\x1b";
const APC_START = `${ESC}_G`;
const APC_END = `${ESC}\\`;

const CHUNK_SIZE = 4096;

// ============================================================================
// Kitty Renderer Implementation
// ============================================================================

export class KittyRenderer implements ImageRendererPort {
  private imageIdCounter = 0;

  isSupported(): boolean {
    // This will be detected at runtime via terminal query
    return true;
  }

  render(
    image: ImageData,
    col: number,
    row: number,
    width?: number,
    height?: number
  ): string {
    const imageId = ++this.imageIdCounter;
    const base64 = image.data.toString("base64");

    // Build control data
    const controlData: string[] = [
      `a=T`, // Transmit and display
      `f=100`, // PNG format
      `i=${imageId}`, // Image ID
      `t=d`, // Direct transmission
    ];

    if (width) controlData.push(`c=${width}`);
    if (height) controlData.push(`r=${height}`);

    // For chunked transfer
    if (base64.length > CHUNK_SIZE) {
      return this.renderChunked(imageId, base64, controlData, col, row);
    }

    // Single chunk
    const control = controlData.join(",");
    return `${APC_START}${control};${base64}${APC_END}`;
  }

  clear(imageId?: number): string {
    if (imageId) {
      return `${APC_START}a=d,d=i,i=${imageId}${APC_END}`;
    }
    return `${APC_START}a=d,d=a${APC_END}`;
  }

  // --------------------------------------------------------------------------
  // Chunked Transfer
  // --------------------------------------------------------------------------

  private renderChunked(
    imageId: number,
    base64: string,
    controlData: string[],
    col: number,
    row: number
  ): string {
    const chunks: string[] = [];

    for (let i = 0; i < base64.length; i += CHUNK_SIZE) {
      const chunk = base64.slice(i, i + CHUNK_SIZE);
      const isLast = i + CHUNK_SIZE >= base64.length;

      if (i === 0) {
        // First chunk with full control data
        const control = [...controlData, `m=${isLast ? 0 : 1}`].join(",");
        chunks.push(`${APC_START}${control};${chunk}${APC_END}`);
      } else {
        // Subsequent chunks
        chunks.push(`${APC_START}m=${isLast ? 0 : 1};${chunk}${APC_END}`);
      }
    }

    return chunks.join("");
  }

  // --------------------------------------------------------------------------
  // Utility Methods
  // --------------------------------------------------------------------------

  place(imageId: number, col: number, row: number, width?: number, height?: number): string {
    const controlData: string[] = [
      `a=p`, // Place image
      `i=${imageId}`, // Image ID
      `x=${col}`,
      `y=${row}`,
    ];

    if (width) controlData.push(`c=${width}`);
    if (height) controlData.push(`r=${height}`);

    return `${APC_START}${controlData.join(",")}${APC_END}`;
  }

  virtualPlacement(imageId: number, columns: number, rows: number): string {
    return `${APC_START}a=p,i=${imageId},U=1,c=${columns},r=${rows}${APC_END}`;
  }

  deleteAll(): string {
    return `${APC_START}a=d,d=a${APC_END}`;
  }

  query(): string {
    return `${APC_START}a=q,i=1,s=1,v=1,t=d,f=24;AAAA${APC_END}`;
  }
}
