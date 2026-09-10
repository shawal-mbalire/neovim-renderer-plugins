/**
 * Kitty Graphics Protocol Adapter (unicode placeholders + old)
 */

import type { ImageData } from "../../domain/models/types";
import type { ImageRendererPort } from "../../domain/ports";

const ESC = "\x1b";
const APC_START = `${ESC}_G`;
const APC_END = `${ESC}\\`;
const CHUNK_SIZE = 4096;

// ============================================================================
// Kitty Unicode Placeholders (newer)
// ============================================================================

export class KittyKgpRenderer implements ImageRendererPort {
  readonly protocol = "kgp" as const;
  private imageIdCounter = 0;

  isSupported(): boolean {
    return true;
  }

  render(image: ImageData, col: number, row: number, width?: number, height?: number): string {
    const imageId = ++this.imageIdCounter;
    const base64 = image.data.toString("base64");

    const controlData: string[] = [
      `a=T`,
      `f=100`,
      `i=${imageId}`,
      `t=d`,
    ];

    if (width) controlData.push(`c=${width}`);
    if (height) controlData.push(`r=${height}`);

    if (base64.length > CHUNK_SIZE) {
      return this.renderChunked(imageId, base64, controlData);
    }

    const control = controlData.join(",");
    return `${APC_START}${control};${base64}${APC_END}`;
  }

  clear(imageId?: number): string {
    if (imageId) {
      return `${APC_START}a=d,d=i,i=${imageId}${APC_END}`;
    }
    return `${APC_START}a=d,d=a${APC_END}`;
  }

  private renderChunked(imageId: number, base64: string, controlData: string[]): string {
    const chunks: string[] = [];
    for (let i = 0; i < base64.length; i += CHUNK_SIZE) {
      const chunk = base64.slice(i, i + CHUNK_SIZE);
      const isLast = i + CHUNK_SIZE >= base64.length;
      if (i === 0) {
        const control = [...controlData, `m=${isLast ? 0 : 1}`].join(",");
        chunks.push(`${APC_START}${control};${chunk}${APC_END}`);
      } else {
        chunks.push(`${APC_START}m=${isLast ? 0 : 1};${chunk}${APC_END}`);
      }
    }
    return chunks.join("");
  }
}

// ============================================================================
// Kitty Old Protocol (chunked upload)
// ============================================================================

export class KittyKgpOldRenderer implements ImageRendererPort {
  readonly protocol = "kgp_old" as const;
  private imageIdCounter = 0;

  isSupported(): boolean {
    return true;
  }

  render(image: ImageData, col: number, row: number, width?: number, height?: number): string {
    const imageId = ++this.imageIdCounter;
    const base64 = image.data.toString("base64");

    const controlData: string[] = [
      `a=T`,
      `f=100`,
      `i=${imageId}`,
      `t=d`,
    ];

    if (width) controlData.push(`c=${width}`);
    if (height) controlData.push(`r=${height}`);

    if (base64.length > CHUNK_SIZE) {
      return this.renderChunked(imageId, base64, controlData);
    }

    const control = controlData.join(",");
    return `${APC_START}${control};${base64}${APC_END}`;
  }

  clear(imageId?: number): string {
    if (imageId) {
      return `${APC_START}a=d,d=i,i=${imageId}${APC_END}`;
    }
    return `${APC_START}a=d,d=a${APC_END}`;
  }

  private renderChunked(imageId: number, base64: string, controlData: string[]): string {
    const chunks: string[] = [];
    for (let i = 0; i < base64.length; i += CHUNK_SIZE) {
      const chunk = base64.slice(i, i + CHUNK_SIZE);
      const isLast = i + CHUNK_SIZE >= base64.length;
      if (i === 0) {
        const control = [...controlData, `m=${isLast ? 0 : 1}`].join(",");
        chunks.push(`${APC_START}${control};${chunk}${APC_END}`);
      } else {
        chunks.push(`${APC_START}m=${isLast ? 0 : 1};${chunk}${APC_END}`);
      }
    }
    return chunks.join("");
  }
}
