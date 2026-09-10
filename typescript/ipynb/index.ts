/**
 * ipynb Plugin - Composition Root
 */

import { IpynbParser } from "./adapters/parser/index.ts";
import { NotebookRenderer } from "./adapters/renderer/index.ts";
import type { RenderResult } from "../shared/models/types.ts";

export interface IpynbPlugin {
  process(json: string): RenderResult;
}

export function createIpynbPlugin(): IpynbPlugin {
  const parser = new IpynbParser();
  const renderer = new NotebookRenderer();

  return {
    process(json: string): RenderResult {
      const notebook = parser.parse(json);
      return renderer.render(notebook);
    },
  };
}

export * from "./domain/models/types.ts";
export * from "./domain/ports/index.ts";
export * from "./domain/errors/index.ts";
export * from "./adapters/parser/index.ts";
export * from "./adapters/renderer/index.ts";
