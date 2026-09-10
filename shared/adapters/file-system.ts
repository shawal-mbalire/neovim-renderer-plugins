/**
 * File System Adapter - Implements FileSystemPort
 */

import { readFile, writeFile, unlink, access, mkdtemp } from "fs/promises";
import { join } from "path";
import { tmpdir } from "os";
import type { FileSystemPort } from "../domain/ports";
import { FileNotFoundError } from "../domain/errors";

export class FileSystemAdapter implements FileSystemPort {
  async readFile(path: string): Promise<string> {
    try {
      return await readFile(path, "utf-8");
    } catch {
      throw new FileNotFoundError(path);
    }
  }

  async readBinary(path: string): Promise<Buffer> {
    try {
      return await readFile(path);
    } catch {
      throw new FileNotFoundError(path);
    }
  }

  async fileExists(path: string): Promise<boolean> {
    try {
      await access(path);
      return true;
    } catch {
      return false;
    }
  }

  getTempDir(): string {
    return tmpdir();
  }

  async writeTempFile(name: string, content: string | Buffer): Promise<string> {
    const tempDir = await mkdtemp(join(tmpdir(), "neovim-renderer-"));
    const filePath = join(tempDir, name);
    await writeFile(filePath, content);
    return filePath;
  }

  async deleteFile(path: string): Promise<void> {
    try {
      await unlink(path);
    } catch {
      // Ignore errors on delete
    }
  }
}
