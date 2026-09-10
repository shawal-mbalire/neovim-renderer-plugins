/**
 * Shared Domain Ports - Common interfaces for all plugins
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
// Graphics Port
// ============================================================================

export interface GraphicsPort {
  isSupported(): boolean;
  renderImage(data: Buffer, width: number, height: number): string;
  detectCapabilities(): GraphicsCapabilities;
}

export interface GraphicsCapabilities {
  kitty: boolean;
  sixel: boolean;
  unicode: boolean;
}

// ============================================================================
// File System Port
// ============================================================================

export interface FileSystemPort {
  readFile(path: string): Promise<string>;
  readBinary(path: string): Promise<Buffer>;
  fileExists(path: string): Promise<boolean>;
  getTempDir(): string;
  writeTempFile(name: string, content: string | Buffer): Promise<string>;
  deleteFile(path: string): Promise<void>;
}

// ============================================================================
// Communication Port
// ============================================================================

export interface CommunicationPort {
  send(message: PluginMessage): void;
  onMessage(handler: (message: PluginMessage) => void): void;
  onError(handler: (error: Error) => void): void;
}

// ============================================================================
// External Tool Port
// ============================================================================

export interface ExternalToolPort {
  isAvailable(): Promise<boolean>;
  execute(args: string[]): Promise<string>;
}
