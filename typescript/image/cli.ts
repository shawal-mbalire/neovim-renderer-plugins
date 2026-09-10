/**
 * Image CLI - Entry point for Lua to call
 */

import { createImagePlugin } from "./index.ts";

const plugin = createImagePlugin();
let input = "";

process.stdin.on("data", (chunk) => {
  input += chunk.toString();
});

process.stdin.on("end", async () => {
  try {
    const msg = JSON.parse(input);

    if (msg.type === "render" && msg.path) {
      const result = await plugin.render(msg.path);
      process.stdout.write(JSON.stringify(result));
    } else {
      process.stdout.write(JSON.stringify({ lines: [], errors: [] }));
    }
  } catch (error) {
    process.stdout.write(JSON.stringify({ lines: [], errors: [] }));
  }
});
