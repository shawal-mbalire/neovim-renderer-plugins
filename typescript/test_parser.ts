import { MarkdownParser } from "./markdown/adapters/parser/index.ts";
import { MarkdownRenderer } from "./markdown/adapters/renderer/index.ts";

const parser = new MarkdownParser();
const renderer = new MarkdownRenderer();

const md = "# Hello\n\n**Bold** and *italic*\n";
const ast = parser.parse(md);
console.log("AST children:", ast.children?.length);

const result = renderer.render(ast);
console.log("Lines:", result.lines.length);
if (result.lines.length > 0) {
  console.log("First line:", JSON.stringify(result.lines[0]));
}
