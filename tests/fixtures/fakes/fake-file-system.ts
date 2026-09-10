/**
 * Fake File System Adapter
 * In-memory fake implementation for testing
 */

import type { FileSystemPort } from "../../../shared/domain/ports";

export class FakeFileSystem implements FileSystemPort {
  public readFileCalled = 0;
  public readBinaryCalled = 0;
  public fileExistsCalled = 0;
  public writeFileCalled = 0;
  public deleteFileCalled = 0;
  
  public files: Map<string, string> = new Map();
  public binaryFiles: Map<string, Buffer> = new Map();
  public tempFiles: string[] = [];

  async readFile(path: string): Promise<string> {
    this.readFileCalled++;
    const content = this.files.get(path);
    if (content === undefined) {
      throw new Error(`File not found: ${path}`);
    }
    return content;
  }

  async readBinary(path: string): Promise<Buffer> {
    this.readBinaryCalled++;
    const content = this.binaryFiles.get(path);
    if (content === undefined) {
      throw new Error(`File not found: ${path}`);
    }
    return content;
  }

  async fileExists(path: string): Promise<boolean> {
    this.fileExistsCalled++;
    return this.files.has(path) || this.binaryFiles.has(path);
  }

  getTempDir(): string {
    return "/tmp/test";
  }

  async writeTempFile(name: string, content: string | Buffer): Promise<string> {
    this.writeFileCalled++;
    const path = `/tmp/test/${name}`;
    if (typeof content === "string") {
      this.files.set(path, content);
    } else {
      this.binaryFiles.set(path, content);
    }
    this.tempFiles.push(path);
    return path;
  }

  async deleteFile(path: string): Promise<void> {
    this.deleteFileCalled++;
    this.files.delete(path);
    this.binaryFiles.delete(path);
  }

  // ============================================================================
  // Test Helpers
  // ============================================================================

  addFile(path: string, content: string): void {
    this.files.set(path, content);
  }

  addBinaryFile(path: string, content: Buffer): void {
    this.binaryFiles.set(path, content);
  }

  getFileContent(path: string): string | undefined {
    return this.files.get(path);
  }

  getBinaryFileContent(path: string): Buffer | undefined {
    return this.binaryFiles.get(path);
  }

  hasFile(path: string): boolean {
    return this.files.has(path) || this.binaryFiles.has(path);
  }

  getTempFiles(): string[] {
    return [...this.tempFiles];
  }

  reset(): void {
    this.readFileCalled = 0;
    this.readBinaryCalled = 0;
    this.fileExistsCalled = 0;
    this.writeFileCalled = 0;
    this.deleteFileCalled = 0;
    this.files.clear();
    this.binaryFiles.clear();
    this.tempFiles = [];
  }
}
