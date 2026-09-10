/**
 * Shared Domain Ports
 */

import type { RenderResult, PluginMessage } from "../models/types";

export interface ParserPort<TInput = string, TOutput = unknown> {
  parse(input: TInput): TOutput;
}

export interface RendererPort<TInput = unknown> {
  render(input: TInput, startLine?: number): RenderResult;
}

export interface FileSystemPort {
  readFile(path: string): Promise<string>;
  readBinary(path: string): Promise<Buffer>;
  fileExists(path: string): Promise<boolean>;
}

export interface CommunicationPort {
  send(message: PluginMessage): void;
  onMessage(handler: (message: PluginMessage) => void): void;
}
