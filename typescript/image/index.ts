/**
 * Image Plugin - Composition Root
 */

import { ImageLoader } from "./adapters/loader";
import { ImageProtocolRenderer } from "./adapters/protocols";
import type { ImageInfo, TerminalInfo } from "./domain/models/types";

export interface ImagePlugin {
  load(path: string): Promise<ImageInfo>;
  render(path: string): Promise<string>;
  getTerminalInfo(): TerminalInfo;
}

export function createImagePlugin(): ImagePlugin {
  const loader = new ImageLoader();
  const renderer = new ImageProtocolRenderer();

  return {
    async load(path: string): Promise<ImageInfo> {
      return loader.load(path);
    },

    async render(path: string): Promise<string> {
      const imageInfo = await loader.load(path);
      return renderer.render(imageInfo);
    },

    getTerminalInfo(): TerminalInfo {
      return renderer.getTerminalInfo();
    },
  };
}

export * from "./domain/models/types";
export * from "./domain/ports";
export * from "./adapters/loader";
export * from "./adapters/protocols";
