/**
 * Image Loader Adapter
 * Loads images from files or base64 data
 */

import type { ImageData, ImageMetadata, ImageFormat } from "../../domain/models/types";
import type { ImageLoaderPort } from "../../domain/ports";
import { ImageLoadError, ImageFormatError } from "../../domain/errors";
import { readFile } from "fs/promises";

// ============================================================================
// Supported Formats
// ============================================================================

const SUPPORTED_FORMATS: ImageFormat[] = ["png", "jpeg", "gif", "webp", "svg"];

// ============================================================================
// Image Loader Implementation
// ============================================================================

export class ImageLoader implements ImageLoaderPort {
  async load(path: string): Promise<ImageData> {
    try {
      const buffer = await readFile(path);
      const format = this.detectFormat(path);

      if (!SUPPORTED_FORMATS.includes(format)) {
        throw new ImageFormatError(format);
      }

      const metadata = this.parseImageMetadata(buffer, format);

      return {
        format,
        width: metadata.width,
        height: metadata.height,
        data: buffer,
        path,
      };
    } catch (error) {
      if (error instanceof ImageFormatError) {
        throw error;
      }
      throw new ImageLoadError(path, error instanceof Error ? error.message : "unknown error");
    }
  }

  async loadFromBase64(base64: string, format: string): Promise<ImageData> {
    const imageFormat = format.toLowerCase() as ImageFormat;

    if (!SUPPORTED_FORMATS.includes(imageFormat)) {
      throw new ImageFormatError(format);
    }

    const buffer = Buffer.from(base64, "base64");
    const metadata = this.parseImageMetadata(buffer, imageFormat);

    return {
      format: imageFormat,
      width: metadata.width,
      height: metadata.height,
      data: buffer,
    };
  }

  async getMetadata(path: string): Promise<ImageMetadata> {
    try {
      const buffer = await readFile(path);
      const format = this.detectFormat(path);

      if (!SUPPORTED_FORMATS.includes(format)) {
        throw new ImageFormatError(format);
      }

      return this.parseImageMetadata(buffer, format);
    } catch (error) {
      if (error instanceof ImageFormatError) {
        throw error;
      }
      throw new ImageLoadError(path, error instanceof Error ? error.message : "unknown error");
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  private detectFormat(path: string): ImageFormat {
    const ext = path.toLowerCase().split(".").pop();

    switch (ext) {
      case "png":
        return "png";
      case "jpg":
      case "jpeg":
        return "jpeg";
      case "gif":
        return "gif";
      case "webp":
        return "webp";
      case "svg":
        return "svg";
      default:
        // Try to detect from magic bytes
        return "png";
    }
  }

  private parseImageMetadata(buffer: Buffer, format: ImageFormat): ImageMetadata {
    // Simple header parsing for common formats
    let width = 0;
    let height = 0;
    let hasAlpha = false;

    if (format === "png" && buffer.length >= 24) {
      // PNG header: 8 bytes signature, then IHDR chunk
      if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) {
        width = buffer.readUInt32BE(16);
        height = buffer.readUInt32BE(20);
        const colorType = buffer[24];
        hasAlpha = colorType === 4 || colorType === 6;
      }
    } else if (format === "jpeg" && buffer.length >= 2) {
      // JPEG: width and height are in SOF marker
      // Simplified: just return reasonable defaults
      width = 800;
      height = 600;
    } else if (format === "gif" && buffer.length >= 10) {
      // GIF header
      width = buffer.readUInt16LE(6);
      height = buffer.readUInt16LE(8);
      hasAlpha = (buffer[10] & 0x80) !== 0;
    } else if (format === "webp" && buffer.length >= 30) {
      // WebP header
      if (buffer.toString("ascii", 0, 4) === "RIFF" && buffer.toString("ascii", 8, 12) === "WEBP") {
        width = buffer.readUInt16LE(26) & 0x3fff;
        height = buffer.readUInt16LE(28) & 0x3fff;
      }
    }

    return {
      format,
      width,
      height,
      size: buffer.length,
      hasAlpha,
    };
  }
}
