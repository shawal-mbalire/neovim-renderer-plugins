/**
 * Fake Graphics Adapter
 * In-memory fake implementation for testing
 */

import type { GraphicsPort, TerminalCapabilities } from "../../../shared/domain/ports";

export class FakeGraphics implements GraphicsPort {
  public isSupportedCalled = 0;
  public renderImageCalled = 0;
  public detectCapabilitiesCalled = 0;
  
  private supported = true;
  private capabilities: TerminalCapabilities = {
    kitty: true,
    sixel: false,
    unicode: true,
  };

  isSupported(): boolean {
    this.isSupportedCalled++;
    return this.supported;
  }

  renderImage(data: Buffer, width: number, height: number): string {
    this.renderImageCalled++;
    return `\x1b_Gf=100,t=d;${data.toString("base64")}\x1b\\`;
  }

  detectCapabilities(): TerminalCapabilities {
    this.detectCapabilitiesCalled++;
    return this.capabilities;
  }

  setSupported(supported: boolean): void {
    this.supported = supported;
  }

  setCapabilities(capabilities: TerminalCapabilities): void {
    this.capabilities = capabilities;
  }

  reset(): void {
    this.isSupportedCalled = 0;
    this.renderImageCalled = 0;
    this.detectCapabilitiesCalled = 0;
    this.supported = true;
    this.capabilities = {
      kitty: true,
      sixel: false,
      unicode: true,
    };
  }
}

export class FakeKittyRenderer implements GraphicsPort {
  public isSupportedCalled = 0;
  public renderImageCalled = 0;
  public detectCapabilitiesCalled = 0;
  public lastImageData: Buffer | null = null;
  
  private supported = true;
  private capabilities: TerminalCapabilities = {
    kitty: true,
    sixel: false,
    unicode: true,
  };

  isSupported(): boolean {
    this.isSupportedCalled++;
    return this.supported;
  }

  renderImage(data: Buffer, width: number, height: number): string {
    this.renderImageCalled++;
    this.lastImageData = data;
    const base64 = data.toString("base64");
    return `\x1b_Gf=100,t=d,i=1;${base64}\x1b\\`;
  }

  detectCapabilities(): TerminalCapabilities {
    this.detectCapabilitiesCalled++;
    return this.capabilities;
  }

  setSupported(supported: boolean): void {
    this.supported = supported;
  }

  setCapabilities(capabilities: TerminalCapabilities): void {
    this.capabilities = capabilities;
  }

  reset(): void {
    this.isSupportedCalled = 0;
    this.renderImageCalled = 0;
    this.detectCapabilitiesCalled = 0;
    this.lastImageData = null;
    this.supported = true;
    this.capabilities = {
      kitty: true,
      sixel: false,
      unicode: true,
    };
  }
}
