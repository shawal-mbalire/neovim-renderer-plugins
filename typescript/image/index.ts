/**
 * Image Plugin - Composition Root
 */

import { ImageLoader } from "./adapters/loader/index.ts";
import { ImageProtocolRenderer } from "./adapters/protocols/index.ts";
import type { ImageInfo, TerminalInfo } from "./domain/models/types.ts";
import type { RenderResult } from "../shared/models/types.ts";

export interface ImagePlugin {
  load(path: string): Promise<ImageInfo>;
  render(path: string): Promise<RenderResult>;
  getTerminalInfo(): TerminalInfo;
}

export function createImagePlugin(): ImagePlugin {
  const loader = new ImageLoader();
  const renderer = new ImageProtocolRenderer();

  return {
    async load(path: string): Promise<ImageInfo> {
      return loader.load(path);
    },

    async render(path: string): Promise<RenderResult> {
      try {
        const imageInfo = await loader.load(path);
        const terminal = renderer.getTerminalInfo();

        // Create render result with image info
        const lines = [
          { line: 0, text: `=== Image: ${path.split("/").pop()} ===`, marks: [{ line: 0, col: 0, end_col: 30, hl: "Title" }], images: [] },
          { line: 1, text: "", marks: [], images: [] },
          { line: 2, text: `File: ${path}`, marks: [], images: [] },
          { line: 3, text: `Size: ${imageInfo.width}x${imageInfo.height}`, marks: [], images: [] },
          { line: 4, text: `Format: ${imageInfo.format}`, marks: [], images: [] },
          { line: 5, text: `Terminal: ${terminal.protocol}`, marks: [], images: [] },
          { line: 6, text: `Protocols: ${terminal.supported.join(", ")}`, marks: [], images: [] },
        ];

        return { lines, errors: [] };
      } catch (error) {
        return {
          lines: [
            { line: 0, text: `Error: ${error instanceof Error ? error.message : "Unknown error"}`, marks: [{ line: 0, col: 0, end_col: 50, hl: "ErrorMsg" }], images: [] },
          ],
          errors: [],
        };
      }
    },

    getTerminalInfo(): TerminalInfo {
      return renderer.getTerminalInfo();
    },
  };
}

export * from "./domain/models/types.ts";
export * from "./domain/ports/index.ts";
export * from "./adapters/loader/index.ts";
export * from "./adapters/protocols/index.ts";
