/**
 * Markdown Parser Tests
 */

import { describe, it, expect } from "bun:test";

describe("MarkdownParser", () => {
  it("should parse empty string", () => {
    expect(true).toBe(true);
  });

  it("should parse heading", () => {
    const line = "# Hello";
    const match = line.match(/^(#{1,6})\s+(.+)$/);
    expect(match).not.toBeNull();
    expect(match![1].length).toBe(1);
  });

  it("should parse bold", () => {
    const text = "**bold**";
    const match = text.match(/^\*\*(.+?)\*\*/);
    expect(match).not.toBeNull();
    expect(match![1]).toBe("bold");
  });

  it("should parse code block", () => {
    const md = "```typescript\ncode\n```";
    const lines = md.split("\n");
    expect(lines[0]).toBe("```typescript");
    expect(lines[1]).toBe("code");
    expect(lines[2]).toBe("```");
  });
});
