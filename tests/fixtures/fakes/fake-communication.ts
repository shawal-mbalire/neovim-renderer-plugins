/**
 * Fake Communication Adapter
 * In-memory fake implementation for testing
 */

import type { CommunicationPort } from "../../../shared/domain/ports";
import type { PluginMessage } from "../../../shared/domain/models/types";

export class FakeCommunication implements CommunicationPort {
  public messagesSent: PluginMessage[] = [];
  public messageHandlers: ((message: PluginMessage) => void)[] = [];
  public errorHandlers: ((error: Error) => void)[] = [];
  public shouldThrowOnSend = false;
  public sendErrorMessage = "Send error";

  send(message: PluginMessage): void {
    if (this.shouldThrowOnSend) {
      throw new Error(this.sendErrorMessage);
    }
    this.messagesSent.push(message);
  }

  onMessage(handler: (message: PluginMessage) => void): void {
    this.messageHandlers.push(handler);
  }

  onError(handler: (error: Error) => void): void {
    this.errorHandlers.push(handler);
  }

  // ============================================================================
  // Test Helpers
  // ============================================================================

  simulateMessage(message: PluginMessage): void {
    for (const handler of this.messageHandlers) {
      handler(message);
    }
  }

  simulateError(error: Error): void {
    for (const handler of this.errorHandlers) {
      handler(error);
    }
  }

  getLastMessage(): PluginMessage | undefined {
    return this.messagesSent[this.messagesSent.length - 1];
  }

  getMessageCount(): number {
    return this.messagesSent.length;
  }

  findMessage(type: string): PluginMessage | undefined {
    return this.messagesSent.find((m) => m.type === type);
  }

  filterMessages(type: string): PluginMessage[] {
    return this.messagesSent.filter((m) => m.type === type);
  }

  setShouldThrow(shouldThrow: boolean, errorMessage?: string): void {
    this.shouldThrowOnSend = shouldThrow;
    if (errorMessage) {
      this.sendErrorMessage = errorMessage;
    }
  }

  reset(): void {
    this.messagesSent = [];
    this.messageHandlers = [];
    this.errorHandlers = [];
    this.shouldThrowOnSend = false;
    this.sendErrorMessage = "Send error";
  }
}
