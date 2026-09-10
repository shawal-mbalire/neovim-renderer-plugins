/**
 * Shared Domain Ports
 * Interfaces defining required I/O contracts
 * Adapters must implement these interfaces
 */

import type { RenderResult, PluginMessage } from "../models/types";

// ============================================================================
// Parser Port - Input → AST
// ============================================================================

export interface ParserPort<TInput = string, TOutput = unknown> {
  parse(input: TInput): TOutput;
}

// ============================================================================
// Renderer Port - AST → Render commands
// ============================================================================

export interface RendererPort<TInput = unknown> {
  render(input: TInput, startLine?: number): RenderResult;
}

// ============================================================================
// FileSystem Port - File operations
// ============================================================================

export interface FileSystemPort {
  readFile(path: string): Promise<string>;
  readBinary(path: string): Promise<Buffer>;
  fileExists(path: string): Promise<boolean>;
}

// ============================================================================
// Communication Port - Bun ↔ Neovim
// ============================================================================

export interface CommunicationPort {
  send(message: PluginMessage): void;
  onMessage(handler: (message: PluginMessage) => void): void;
}

// ============================================================================
// Terminal Detection Port
// ============================================================================

export interface TerminalDetectionPort {
  detect(): TerminalInfo;
  getProtocol(): string;
}

export interface TerminalInfo {
  readonly protocol: string;
  readonly supported: ReadonlyArray<string>;
  readonly maxImageWidth: number;
  readonly maxImageHeight: number;
  readonly tmux: boolean;
  readonly zellij: boolean;
}
