import { createMarkdownPlugin } from "./markdown/index.ts";

const plugin = createMarkdownPlugin();
let input = "";

process.stdin.on("data", (chunk) => {
  input += chunk.toString();
  console.error("Received data:", chunk.length, "bytes");
});

process.stdin.on("end", () => {
  console.error("Input length:", input.length);
  try {
    const msg = JSON.parse(input);
    console.error("Message type:", msg.type);
    
    if (msg.type === "render" && msg.content) {
      console.error("Content length:", msg.content.length);
      const result = plugin.process(msg.content);
      console.error("Result lines:", result.lines.length);
      process.stdout.write(JSON.stringify(result));
    } else {
      process.stdout.write(JSON.stringify({ lines: [], errors: [] }));
    }
  } catch (error) {
    console.error("Error:", error);
    process.stdout.write(JSON.stringify({ lines: [], errors: [] }));
  }
});
