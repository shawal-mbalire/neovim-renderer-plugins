/**
 * Markdown CLI - Entry point for Lua to call
 * Reads JSON from stdin, outputs render data as JSON
 */

import { createMarkdownPlugin } from "./index";

const plugin = createMarkdownPlugin();

// Read from stdin
let input = "";
process.stdin.on("data", (chunk) => {
  input += chunk.toString();
});

process.stdin.on("end", () => {
  try {
    const msg = JSON.parse(input);

    if (msg.type === "render" && msg.content) {
      const result = plugin.process(msg.content);
      process.stdout.write(JSON.stringify(result));
    } else {
      process.stdout.write(JSON.stringify({ lines: [], errors: [] }));
    }
  } catch (error) {
    process.stdout.write(JSON.stringify({ lines: [], errors: [] }));
  }
});
