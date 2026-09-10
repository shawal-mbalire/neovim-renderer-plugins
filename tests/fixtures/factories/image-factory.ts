/**
 * Image Test Factory
 * Creates test image data and terminal capabilities
 */

import type { ImageData, ImageMetadata, TerminalCapabilities, ImageFormat } from "../../../plugins/image/domain/models/types";

// ============================================================================
// Image Data Factory
// ============================================================================

export const ImageFactory = {
  // Minimal PNG (1x1 pixel)
  minimalPng: (): ImageData => ({
    format: "png",
    width: 1,
    height: 1,
    data: Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==", "base64"),
  }),

  // Small PNG (100x100)
  smallPng: (): ImageData => ({
    format: "png",
    width: 100,
    height: 100,
    data: Buffer.alloc(1000), // Dummy data
  }),

  // JPEG image
  jpeg: (): ImageData => ({
    format: "jpeg",
    width: 200,
    height: 150,
    data: Buffer.alloc(5000),
  }),

  // GIF image
  gif: (): ImageData => ({
    format: "gif",
    width: 50,
    height: 50,
    data: Buffer.alloc(2000),
  }),

  // Large image
  large: (): ImageData => ({
    format: "png",
    width: 1920,
    height: 1080,
    data: Buffer.alloc(100000),
  }),

  // Image with alpha
  withAlpha: (): ImageData => ({
    format: "png",
    width: 100,
    height: 100,
    data: Buffer.alloc(4000), // RGBA
  }),

  // Create custom image
  create: (opts: {
    format?: ImageFormat;
    width?: number;
    height?: number;
    data?: Buffer;
  }): ImageData => ({
    format: opts.format || "png",
    width: opts.width || 100,
    height: opts.height || 100,
    data: opts.data || Buffer.alloc(1000),
  }),
};

// ============================================================================
// Image Metadata Factory
// ============================================================================

export const ImageMetadataFactory = {
  png: (): ImageMetadata => ({
    format: "png",
    width: 100,
    height: 100,
    size: 1000,
    hasAlpha: true,
    colorDepth: 32,
  }),

  jpeg: (): ImageMetadata => ({
    format: "jpeg",
    width: 200,
    height: 150,
    size: 5000,
    hasAlpha: false,
    colorDepth: 24,
  }),

  create: (opts: Partial<ImageMetadata> = {}): ImageMetadata => ({
    format: opts.format || "png",
    width: opts.width || 100,
    height: opts.height || 100,
    size: opts.size || 1000,
    hasAlpha: opts.hasAlpha,
    colorDepth: opts.colorDepth,
  }),
};

// ============================================================================
// Terminal Capabilities Factory
// ============================================================================

export const TerminalFactory = {
  // Kitty terminal
  kitty: (): TerminalCapabilities => ({
    protocol: "kgp",
    supported: ["kgp", "kgp_old"],
    maxImageWidth: 800,
    maxImageHeight: 600,
  }),

  // WezTerm (IIP)
  wezterm: (): TerminalCapabilities => ({
    protocol: "iip",
    supported: ["iip"],
    maxImageWidth: 800,
    maxImageHeight: 600,
  }),

  // iTerm2 (IIP)
  iterm2: (): TerminalCapabilities => ({
    protocol: "iip",
    supported: ["iip"],
    maxImageWidth: 800,
    maxImageHeight: 600,
  }),

  // foot (Sixel)
  foot: (): TerminalCapabilities => ({
    protocol: "sixel",
    supported: ["sixel"],
    maxImageWidth: 800,
    maxImageHeight: 600,
  }),

  // Terminal with no image support
  noSupport: (): TerminalCapabilities => ({
    protocol: "chafa",
    supported: ["chafa"],
    maxImageWidth: 0,
    maxImageHeight: 0,
  }),

  // Terminal inside tmux
  tmux: (): TerminalCapabilities => ({
    protocol: "sixel",
    supported: ["sixel", "chafa"],
    maxImageWidth: 800,
    maxImageHeight: 600,
    tmux: true,
  }),

  // Terminal inside zellij
  zellij: (): TerminalCapabilities => ({
    protocol: "sixel",
    supported: ["sixel"],
    maxImageWidth: 800,
    maxImageHeight: 600,
    zellij: true,
  }),

  // Terminal inside WSL
  wsl: (): TerminalCapabilities => ({
    protocol: "iip",
    supported: ["iip"],
    maxImageWidth: 800,
    maxImageHeight: 600,
    wsl: true,
  }),

  // Create custom
  create: (opts: Partial<TerminalCapabilities> = {}): TerminalCapabilities => ({
    protocol: opts.protocol || "kgp",
    supported: opts.supported || ["kgp"],
    maxImageWidth: opts.maxImageWidth || 800,
    maxImageHeight: opts.maxImageHeight || 600,
    tmux: opts.tmux,
    zellij: opts.zellij,
    wsl: opts.wsl,
  }),
};

// ============================================================================
// Base64 Factory
// ============================================================================

export const Base64Factory = {
  // Tiny PNG (1x1 red pixel)
  tinyPng: (): string =>
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==",

  // Create base64 from text (not an image, for testing)
  fromText: (text: string): string => Buffer.from(text).toString("base64"),
  
  // Decode base64 to text
  toText: (base64: string): string => Buffer.from(base64, "base64").toString(),
};
