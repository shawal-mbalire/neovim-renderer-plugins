import { createMarkdownPlugin } from "./markdown/index.ts";

const plugin = createMarkdownPlugin();
const result = plugin.process("# Hello\n\n**Bold**");
console.log(JSON.stringify(result, null, 2));
