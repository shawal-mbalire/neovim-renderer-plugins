/**
 * Image Plugin - Main entry point
 */

import { ImageLoader } from "./adapters/loader";
import { KittyRenderer } from "./adapters/kitty";
import { TerminalDetection } from "./adapters/terminal";
import { LoadImageWorkflow, RenderImageWorkflow, ClearImageWorkflow, DetectTerminalWorkflow } from "./domain/workflows";
import type { ImageData, TerminalCapabilities } from "./domain/models/types";

// ============================================================================
// Plugin Factory
// ============================================================================

export interface ImagePlugin {
  load(path: string): Promise<ImageData>;
  render(image: ImageData, col: number, row: number): string;
  clear(imageId?: number): string;
  getCapabilities(): TerminalCapabilities;
}

export function createImagePlugin(config?: { maxWidth?: number; maxHeight?: number }): ImagePlugin {
  const loader = new ImageLoader();
  const renderer = new KittyRenderer();
  const terminalDetection = new TerminalDetection();

  const loadWorkflow = new LoadImageWorkflow(loader);
  const renderWorkflow = new RenderImageWorkflow(
    renderer,
    terminalDetection,
    config?.maxWidth || 800,
    config?.maxHeight || 600
  );
  const clearWorkflow = new ClearImageWorkflow(renderer);
  const detectWorkflow = new DetectTerminalWorkflow(terminalDetection);

  return {
    async load(path: string): Promise<ImageData> {
      return loadWorkflow.execute(path);
    },

    render(image: ImageData, col: number, row: number): string {
      return renderWorkflow.execute(image, col, row);
    },

    clear(imageId?: number): string {
      return clearWorkflow.execute(imageId);
    },

    getCapabilities(): TerminalCapabilities {
      return detectWorkflow.execute();
    },
  };
}

// ============================================================================
// Re-exports
// ============================================================================

export * from "./domain";
export * from "./adapters";
