/**
 * Image Protocols Adapter
 * Handles terminal image display protocols (Kitty, IIP)
 */

import type { ImageInfo, TerminalInfo } from "../../domain/models/types";
import type { ImageRendererPort } from "../../domain/ports";
import { createTerminalInfo } from "../../domain/models/types";

const KITTY_CHUNK_SIZE = 4096;

export class ImageProtocolRenderer implements ImageRendererPort {
  private imageIdCounter = 0;
  private terminalInfo: TerminalInfo | null = null;

  getTerminalInfo(): TerminalInfo {
    if (!this.terminalInfo) {
      this.terminalInfo = createTerminalInfo();
    }
    return this.terminalInfo;
  }

  render(imageInfo: ImageInfo): string {
    const terminal = this.getTerminalInfo();

    switch (terminal.protocol) {
      case "kgp":
      case "kgp_old":
        return this.renderKitty(imageInfo);
      case "iip":
        return this.renderIip(imageInfo);
      default:
        return "";
    }
  }

  private renderKitty(imageInfo: ImageInfo): string {
    // Placeholder - actual implementation would read file and encode
    this.imageIdCounter++;
    const ctrl = `a=T,f=100,i=${this.imageIdCounter},t=d,c=${Math.ceil(imageInfo.width / 8)},r=${Math.ceil(imageInfo.height / 16)}`;
    return `\x1b_${ctrl};PLACEHOLDER\x1b\\`;
  }

  private renderIip(imageInfo: ImageInfo): string {
    // Placeholder - actual implementation would read file and base64 encode
    return `\x1b]1337;File=inline=1:PLACEHOLDER\x1b\\`;
  }
}
