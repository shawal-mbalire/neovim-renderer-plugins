/**
 * ipynb Plugin - Composition Root
 */

import { IpynbParser } from "./adapters/parser";
import { NotebookRenderer } from "./adapters/renderer";
import type { RenderResult } from "../shared/models/types";

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

export * from "./domain/models/types";
export * from "./domain/ports";
export * from "./domain/errors";
export * from "./adapters/parser";
export * from "./adapters/renderer";
