import { createMarkdownPlugin } from "./markdown/index.ts";

const plugin = createMarkdownPlugin();

// Test with direct content
const result1 = plugin.process("# Test\n\nHello");
console.log("Direct call:", JSON.stringify(result1));

// Test with JSON parsing
const json = '{"type":"render","content":"# Test\\n\\nHello"}';
const msg = JSON.parse(json);
console.log("Parsed message:", JSON.stringify(msg));

const result2 = plugin.process(msg.content);
console.log("After parse:", JSON.stringify(result2));
