const parser = await import("./markdown/adapters/parser/index.ts");
const renderer = await import("./markdown/adapters/renderer/index.ts");

const p = new parser.MarkdownParser();
const r = new renderer.MarkdownRenderer();

const md = "# Hello\n\n**Bold** and *italic*\n";
const ast = p.parse(md);
console.log("AST:", JSON.stringify(ast).substring(0, 200));

const result = r.render(ast);
console.log("Lines:", result.lines.length);
