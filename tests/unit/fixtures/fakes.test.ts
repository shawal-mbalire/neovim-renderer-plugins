/**
 * Test Fixtures Unit Tests
 * Demonstrates how to use the test fixtures
 */

import { describe, it, expect, beforeEach } from "bun:test";
import {
  MarkdownFactory,
  ASTFactory,
  NotebookFactory,
  CellFactory,
  OutputFactory,
  ImageFactory,
  TerminalFactory,
  MarkdownBuilder,
  CellBuilder,
  OutputBuilder,
  FakeMarkdownParser,
  FakeNotebookParser,
  FakeRenderer,
  FakeGraphics,
  FakeFileSystem,
  FakeCommunication,
} from "../../fixtures";

describe("Test Fixtures", () => {
  // ============================================================================
  // Markdown Factory
  // ============================================================================

  describe("MarkdownFactory", () => {
    it("should create simple text", () => {
      const text = MarkdownFactory.simpleText();
      expect(text).toBe("Hello, world!");
    });

    it("should create paragraph", () => {
      const text = MarkdownFactory.paragraph();
      expect(text).toContain("paragraph");
    });

    it("should create headings", () => {
      for (let i = 1; i <= 6; i++) {
        const text = MarkdownFactory.heading(i);
        expect(text).toMatch(new RegExp(`^${"#".repeat(i)}`));
      }
    });

    it("should create bold text", () => {
      const text = MarkdownFactory.bold();
      expect(text).toContain("**bold**");
    });

    it("should create code block", () => {
      const text = MarkdownFactory.codeBlock();
      expect(text).toContain("```");
    });

    it("should create table", () => {
      const text = MarkdownFactory.simpleTable();
      expect(text).toContain("|");
    });

    it("should create alert", () => {
      const text = MarkdownFactory.alertNote();
      expect(text).toContain("> [!NOTE]");
    });

    it("should create math", () => {
      const text = MarkdownFactory.mathInline();
      expect(text).toContain("$");
    });

    it("should create emoji", () => {
      const text = MarkdownFactory.emoji();
      expect(text).toContain(":rocket:");
    });
  });

  // ============================================================================
  // AST Factory
  // ============================================================================

  describe("ASTFactory", () => {
    it("should create document node", () => {
      const node = ASTFactory.document();
      expect(node.type).toBe("document");
      expect(node.children).toHaveLength(0);
    });

    it("should create heading node", () => {
      const node = ASTFactory.heading(1, "Title");
      expect(node.type).toBe("heading");
      expect(node.level).toBe(1);
    });

    it("should create paragraph node", () => {
      const node = ASTFactory.paragraph("Text");
      expect(node.type).toBe("paragraph");
    });

    it("should create bold node", () => {
      const node = ASTFactory.bold("bold");
      expect(node.type).toBe("bold");
    });

    it("should create code block node", () => {
      const node = ASTFactory.codeBlock("code", "typescript");
      expect(node.type).toBe("code_block");
      expect(node.language).toBe("typescript");
    });

    it("should create alert node", () => {
      const node = ASTFactory.alert("note", []);
      expect(node.type).toBe("alert");
      expect(node.alertType).toBe("note");
    });
  });

  // ============================================================================
  // Notebook Factory
  // ============================================================================

  describe("NotebookFactory", () => {
    it("should create empty notebook", () => {
      const notebook = NotebookFactory.empty();
      expect(notebook.cells).toHaveLength(0);
      expect(notebook.nbformat).toBe(4);
    });

    it("should create simple notebook", () => {
      const notebook = NotebookFactory.simple();
      expect(notebook.cells).toHaveLength(1);
      expect(notebook.cells[0].cell_type).toBe("code");
    });

    it("should create notebook with outputs", () => {
      const notebook = NotebookFactory.withOutputs();
      expect(notebook.cells[0].outputs).toHaveLength(1);
    });

    it("should create notebook with rich outputs", () => {
      const notebook = NotebookFactory.withRichOutputs();
      expect(notebook.cells[0].outputs!.length).toBeGreaterThan(0);
    });

    it("should create notebook with errors", () => {
      const notebook = NotebookFactory.withErrors();
      expect(notebook.cells[0].outputs![0].output_type).toBe("error");
    });

    it("should create complex notebook", () => {
      const notebook = NotebookFactory.complex();
      expect(notebook.cells.length).toBeGreaterThan(3);
    });
  });

  // ============================================================================
  // Cell Factory
  // ============================================================================

  describe("CellFactory", () => {
    it("should create code cell", () => {
      const cell = CellFactory.code("x = 1");
      expect(cell.cell_type).toBe("code");
      expect(cell.source).toContain("x = 1");
    });

    it("should create markdown cell", () => {
      const cell = CellFactory.markdown("# Title");
      expect(cell.cell_type).toBe("markdown");
    });

    it("should create cell with output", () => {
      const cell = CellFactory.codeWithOutput("print('hi')", [
        OutputFactory.stream(["hi\n"]),
      ]);
      expect(cell.outputs).toHaveLength(1);
    });

    it("should create cell with execution count", () => {
      const cell = CellFactory.codeWithExecution("x = 1", 5);
      expect(cell.execution_count).toBe(5);
    });
  });

  // ============================================================================
  // Output Factory
  // ============================================================================

  describe("OutputFactory", () => {
    it("should create stream output", () => {
      const output = OutputFactory.stream(["Hello\n"]);
      expect(output.output_type).toBe("stream");
      expect(output.text).toHaveLength(1);
    });

    it("should create text output", () => {
      const output = OutputFactory.text(["42"]);
      expect(output.output_type).toBe("execute_result");
      expect(output.data!["text/plain"]).toBeDefined();
    });

    it("should create error output", () => {
      const output = OutputFactory.error("Error", "msg", ["trace"]);
      expect(output.output_type).toBe("error");
      expect(output.ename).toBe("Error");
    });

    it("should create image output", () => {
      const output = OutputFactory.imagePng("base64");
      expect(output.data!["image/png"]).toBe("base64");
    });
  });

  // ============================================================================
  // Image Factory
  // ============================================================================

  describe("ImageFactory", () => {
    it("should create minimal PNG", () => {
      const image = ImageFactory.minimalPng();
      expect(image.format).toBe("png");
      expect(image.width).toBe(1);
      expect(image.height).toBe(1);
    });

    it("should create custom image", () => {
      const image = ImageFactory.create({
        format: "jpeg",
        width: 200,
        height: 150,
      });
      expect(image.format).toBe("jpeg");
      expect(image.width).toBe(200);
    });
  });

  // ============================================================================
  // Terminal Factory
  // ============================================================================

  describe("TerminalFactory", () => {
    it("should create kitty terminal", () => {
      const terminal = TerminalFactory.kitty();
      expect(terminal.protocol).toBe("kgp");
      expect(terminal.supported).toContain("kgp");
    });

    it("should create wezterm terminal", () => {
      const terminal = TerminalFactory.wezterm();
      expect(terminal.protocol).toBe("iip");
    });

    it("should create terminal with no support", () => {
      const terminal = TerminalFactory.noSupport();
      expect(terminal.supported).toHaveLength(1);
      expect(terminal.supported[0]).toBe("chafa");
    });
  });

  // ============================================================================
  // Markdown Builder
  // ============================================================================

  describe("MarkdownBuilder", () => {
    it("should build simple document", () => {
      const doc = MarkdownBuilder.create()
        .heading(1, "Title")
        .paragraph("Text")
        .build();
      expect(doc).toContain("# Title");
      expect(doc).toContain("Text");
    });

    it("should build complex document", () => {
      const doc = MarkdownBuilder.simpleDocument();
      expect(doc).toContain("# Title");
      expect(doc).toContain("**bold**");
    });

    it("should build with table", () => {
      const doc = MarkdownBuilder.create()
        .table(["A", "B"], [["1", "2"]])
        .build();
      expect(doc).toContain("| A | B |");
      expect(doc).toContain("| 1 | 2 |");
    });

    it("should build with alert", () => {
      const doc = MarkdownBuilder.create()
        .alert("note", "Important")
        .build();
      expect(doc).toContain("> [!NOTE]");
    });
  });

  // ============================================================================
  // Cell Builder
  // ============================================================================

  describe("CellBuilder", () => {
    it("should build code cell", () => {
      const cell = CellBuilder.create()
        .asCode()
        .source("x = 1")
        .build();
      expect(cell.cell_type).toBe("code");
      expect(cell.source).toContain("x = 1");
    });

    it("should build cell with output", () => {
      const cell = CellBuilder.create()
        .asCode()
        .source("print('hi')")
        .addStreamOutput("hi\n")
        .executed()
        .build();
      expect(cell.outputs).toHaveLength(1);
      expect(cell.execution_count).toBe(1);
    });

    it("should build markdown cell", () => {
      const cell = CellBuilder.markdownCell("# Title");
      expect(cell.cell_type).toBe("markdown");
    });
  });

  // ============================================================================
  // Output Builder
  // ============================================================================

  describe("OutputBuilder", () => {
    it("should build stream output", () => {
      const output = OutputBuilder.create()
        .asStream()
        .withStreamText("Hello\nWorld")
        .build();
      expect(output.output_type).toBe("stream");
      expect(output.text).toHaveLength(2);
    });

    it("should build text output", () => {
      const output = OutputBuilder.create()
        .asExecuteResult()
        .withText("42")
        .build();
      expect(output.output_type).toBe("execute_result");
      expect(output.data!["text/plain"]).toBeDefined();
    });

    it("should build error output", () => {
      const output = OutputBuilder.create()
        .asError()
        .withErrorName("TypeError")
        .withErrorValue("bad type")
        .addTracebackLine("Traceback:")
        .build();
      expect(output.output_type).toBe("error");
      expect(output.ename).toBe("TypeError");
    });
  });

  // ============================================================================
  // Fake Parser
  // ============================================================================

  describe("FakeMarkdownParser", () => {
    let parser: FakeMarkdownParser;

    beforeEach(() => {
      parser = new FakeMarkdownParser();
    });

    it("should track parse calls", () => {
      parser.parse("hello");
      parser.parse("world");
      expect(parser.parseCount).toBe(2);
      expect(parser.lastInput).toBe("world");
    });

    it("should return custom AST", () => {
      const customAst = ASTFactory.document([ASTFactory.heading(1, "Custom")]);
      parser.setReturnAst(customAst);
      const result = parser.parse("input");
      expect(result.children![0].type).toBe("heading");
    });

    it("should throw when configured", () => {
      parser.setError("Test error");
      expect(() => parser.parse("input")).toThrow("Test error");
    });

    it("should reset state", () => {
      parser.parse("hello");
      parser.reset();
      expect(parser.parseCount).toBe(0);
      expect(parser.lastInput).toBeNull();
    });
  });

  // ============================================================================
  // Fake Renderer
  // ============================================================================

  describe("FakeRenderer", () => {
    let renderer: FakeRenderer;

    beforeEach(() => {
      renderer = new FakeRenderer();
    });

    it("should track render calls", () => {
      renderer.render({});
      renderer.render({});
      expect(renderer.renderCount).toBe(2);
    });

    it("should return custom result", () => {
      const customResult = {
        lines: [{ line: 0, text: "Custom", marks: [], images: [] }],
        errors: [],
      };
      renderer.setReturnResult(customResult);
      const result = renderer.render({});
      expect(result.lines[0].text).toBe("Custom");
    });

    it("should throw when configured", () => {
      renderer.setError("Render error");
      expect(() => renderer.render({})).toThrow("Render error");
    });
  });

  // ============================================================================
  // Fake File System
  // ============================================================================

  describe("FakeFileSystem", () => {
    let fs: FakeFileSystem;

    beforeEach(() => {
      fs = new FakeFileSystem();
    });

    it("should store and retrieve files", async () => {
      fs.addFile("/test.txt", "content");
      const content = await fs.readFile("/test.txt");
      expect(content).toBe("content");
      expect(fs.readFileCalled).toBe(1);
    });

    it("should throw on missing file", async () => {
      try {
        await fs.readFile("/missing.txt");
        expect(true).toBe(false); // Should not reach here
      } catch (e) {
        expect((e as Error).message).toContain("File not found");
      }
    });

    it("should check file existence", async () => {
      fs.addFile("/exists.txt", "content");
      expect(await fs.fileExists("/exists.txt")).toBe(true);
      expect(await fs.fileExists("/missing.txt")).toBe(false);
    });

    it("should track write calls", async () => {
      await fs.writeTempFile("test.txt", "content");
      expect(fs.writeFileCalled).toBe(1);
      expect(fs.hasFile("/tmp/test/test.txt")).toBe(true);
    });

    it("should reset state", async () => {
      fs.addFile("/test.txt", "content");
      await fs.readFile("/test.txt");
      fs.reset();
      expect(fs.readFileCalled).toBe(0);
      expect(fs.files.size).toBe(0);
    });
  });

  // ============================================================================
  // Fake Communication
  // ============================================================================

  describe("FakeCommunication", () => {
    let comm: FakeCommunication;

    beforeEach(() => {
      comm = new FakeCommunication();
    });

    it("should track sent messages", () => {
      comm.send({ type: "render", data: { lines: [], errors: [] } });
      comm.send({ type: "error", message: "test" });
      expect(comm.getMessageCount()).toBe(2);
    });

    it("should find messages by type", () => {
      comm.send({ type: "render", data: { lines: [], errors: [] } });
      comm.send({ type: "error", message: "test" });
      expect(comm.findMessage("render")).toBeDefined();
      expect(comm.findMessage("unknown")).toBeUndefined();
    });

    it("should filter messages", () => {
      comm.send({ type: "render", data: { lines: [], errors: [] } });
      comm.send({ type: "render", data: { lines: [], errors: [] } });
      comm.send({ type: "error", message: "test" });
      expect(comm.filterMessages("render")).toHaveLength(2);
    });

    it("should simulate messages", () => {
      let received = false;
      comm.onMessage(() => {
        received = true;
      });
      comm.simulateMessage({ type: "update" });
      expect(received).toBe(true);
    });

    it("should throw when configured", () => {
      comm.setShouldThrow(true, "Send failed");
      expect(() => comm.send({ type: "test" })).toThrow("Send failed");
    });
  });
});
