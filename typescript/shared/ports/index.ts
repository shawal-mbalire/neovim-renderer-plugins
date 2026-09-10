/**
 * Shared Domain Ports
 * Interfaces that adapters must implement
 */

import type { RenderResult, PluginMessage } from "../models/types";

// ============================================================================
// Parser Port
// ============================================================================

export interface ParserPort<TInput = string, TOutput = unknown> {
  parse(input: TInput): TOutput;
}

// ============================================================================
// Renderer Port
// ============================================================================

export interface RendererPort<TInput = unknown> {
  render(input: TInput, startLine?: number): RenderResult;
}

// ============================================================================
// Communication Port
// ============================================================================

export interface CommunicationPort {
  send(message: PluginMessage): void;
  onMessage(handler: (message: PluginMessage) => void): void;
}

// ============================================================================
// FileSystem Port
// ============================================================================

export interface FileSystemPort {
  readFile(path: string): Promise<string>;
  readBinary(path: string): Promise<Buffer>;
  fileExists(path: string): Promise<boolean>;
}
