/**
 * Image Domain Errors
 */

export class ImageLoadError extends Error {
  constructor(path: string, message: string) {
    super(`Failed to load image ${path}: ${message}`);
    this.name = "ImageLoadError";
  }
}

export class ImageFormatError extends Error {
  constructor(format: string) {
    super(`Unsupported image format: ${format}`);
    this.name = "ImageFormatError";
  }
}

export class TerminalNotSupportedError extends Error {
  constructor(feature: string) {
    super(`Terminal does not support ${feature}`);
    this.name = "TerminalNotSupportedError";
  }
}

export class ImageTooLargeError extends Error {
  constructor(width: number, height: number, maxWidth: number, maxHeight: number) {
    super(
      `Image too large: ${width}x${height} (max: ${maxWidth}x${maxHeight})`
    );
    this.name = "ImageTooLargeError";
  }
}
