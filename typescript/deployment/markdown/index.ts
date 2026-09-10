/**
 * Markdown Renderer - Composition Root
 */

import { MarkdownParser } from "../../adapters/markdown/parser";

const parser = new MarkdownParser();

process.stdin.on("data", (chunk: Buffer) => {
  const lines = chunk.toString().split("\n").filter(l => l.trim());

  for (const line of lines) {
    try {
      const msg = JSON.parse(line);
      if (msg.type === "update" && msg.content) {
        const ast = parser.parse(msg.content);
        process.stdout.write(JSON.stringify({ type: "render", data: { ast } }) + "\n");
      }
    } catch (e) {
      process.stdout.write(JSON.stringify({ type: "error", message: (e as Error).message }) + "\n");
    }
  }
});
