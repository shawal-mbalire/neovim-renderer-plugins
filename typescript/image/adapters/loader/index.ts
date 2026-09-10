/**
 * Image Loader Adapter
 * Loads image files and extracts metadata
 */

import type { ImageInfo, ImageFormat } from "../../domain/models/types";
import type { ImageLoaderPort } from "../../domain/ports";
import { readFile } from "fs/promises";

export class ImageLoader implements ImageLoaderPort {
  async load(path: string): Promise<ImageInfo> {
    const buffer = await readFile(path);
    const format = this.detectFormat(path);

    // Parse PNG header for dimensions
    let width = 100;
    let height = 100;

    if (buffer.length >= 24 && buffer[0] === 0x89 && buffer[1] === 0x50) {
      // PNG
      width = buffer.readUInt32BE(16);
      height = buffer.readUInt32BE(20);
    }

    return {
      format,
      width,
      height,
      size: buffer.length,
      path,
    };
  }

  async getInfo(path: string): Promise<ImageInfo> {
    return this.load(path);
  }

  private detectFormat(path: string): ImageFormat {
    const ext = path.match(/\.([^\.]+)$/)?.[1]?.toLowerCase();

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
      case "bmp":
        return "bmp";
      case "tiff":
        return "tiff";
      default:
        return "png";
    }
  }
}
