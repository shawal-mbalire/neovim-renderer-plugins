/**
 * ipynb Parser Unit Tests
 */

import { describe, it, expect, beforeEach } from "bun:test";
import { IpynbParser } from "../../../plugins/ipynb/adapters/parser";
import { NotebookFactory, CellFactory, OutputFactory } from "../../fixtures";

describe("IpynbParser", () => {
  let parser: IpynbParser;

  beforeEach(() => {
    parser = new IpynbParser();
  });

  // ============================================================================
  // Basic Parsing
  // ============================================================================

  describe("basic parsing", () => {
    it("should parse empty notebook", () => {
      const json = JSON.stringify(NotebookFactory.empty());
      const result = parser.parse(json);
      expect(result.cells).toHaveLength(0);
      expect(result.nbformat).toBe(4);
    });

    it("should parse simple notebook", () => {
      const json = JSON.stringify(NotebookFactory.simple());
      const result = parser.parse(json);
      expect(result.cells).toHaveLength(1);
      expect(result.cells[0].cell_type).toBe("code");
    });

    it("should parse mixed cells", () => {
      const json = JSON.stringify(NotebookFactory.mixed());
      const result = parser.parse(json);
      expect(result.cells).toHaveLength(4);
      expect(result.cells[0].cell_type).toBe("markdown");
      expect(result.cells[1].cell_type).toBe("code");
    });
  });

  // ============================================================================
  // Cell Parsing
  // ============================================================================

  describe("cell parsing", () => {
    it("should parse code cell", () => {
      const cell = CellFactory.code('print("Hello")');
      const json = JSON.stringify({
        cells: [cell],
        metadata: NotebookFactory.defaultMetadata(),
        nbformat: 4,
        nbformat_minor: 5,
      });
      const result = parser.parse(json);
      expect(result.cells[0].cell_type).toBe("code");
      expect(result.cells[0].source).toContain('print("Hello")');
    });

    it("should parse markdown cell", () => {
      const cell = CellFactory.markdown("# Title");
      const json = JSON.stringify({
        cells: [cell],
        metadata: NotebookFactory.defaultMetadata(),
        nbformat: 4,
        nbformat_minor: 5,
      });
      const result = parser.parse(json);
      expect(result.cells[0].cell_type).toBe("markdown");
      expect(result.cells[0].source).toContain("# Title");
    });

    it("should parse cell with outputs", () => {
      const cell = CellFactory.codeWithOutput(
        'print("Hello")',
        [OutputFactory.stream(["Hello\n"])]
      );
      const json = JSON.stringify({
        cells: [cell],
        metadata: NotebookFactory.defaultMetadata(),
        nbformat: 4,
        nbformat_minor: 5,
      });
      const result = parser.parse(json);
      expect(result.cells[0].outputs).toHaveLength(1);
      expect(result.cells[0].outputs![0].output_type).toBe("stream");
    });

    it("should parse execution count", () => {
      const cell = CellFactory.codeWithExecution("x = 1", 5);
      const json = JSON.stringify({
        cells: [cell],
        metadata: NotebookFactory.defaultMetadata(),
        nbformat: 4,
        nbformat_minor: 5,
      });
      const result = parser.parse(json);
      expect(result.cells[0].execution_count).toBe(5);
    });
  });

  // ============================================================================
  // Output Parsing
  // ============================================================================

  describe("output parsing", () => {
    it("should parse stream output", () => {
      const output = OutputFactory.stream(["Hello\n", "World\n"]);
      const cell = CellFactory.codeWithOutput("print('Hello')", [output]);
      const json = JSON.stringify({
        cells: [cell],
        metadata: NotebookFactory.defaultMetadata(),
        nbformat: 4,
        nbformat_minor: 5,
      });
      const result = parser.parse(json);
      const parsedOutput = result.cells[0].outputs![0];
      expect(parsedOutput.output_type).toBe("stream");
      expect(parsedOutput.text).toHaveLength(2);
    });

    it("should parse execute_result output", () => {
      const output = OutputFactory.text(["42"]);
      const cell = CellFactory.codeWithOutput("42", [output]);
      const json = JSON.stringify({
        cells: [cell],
        metadata: NotebookFactory.defaultMetadata(),
        nbformat: 4,
        nbformat_minor: 5,
      });
      const result = parser.parse(json);
      const parsedOutput = result.cells[0].outputs![0];
      expect(parsedOutput.output_type).toBe("execute_result");
      expect(parsedOutput.data).toBeDefined();
    });

    it("should parse error output", () => {
      const output = OutputFactory.error(
        "ZeroDivisionError",
        "division by zero",
        ["Traceback: ZeroDivisionError"]
      );
      const cell = CellFactory.codeWithOutput("1/0", [output]);
      const json = JSON.stringify({
        cells: [cell],
        metadata: NotebookFactory.defaultMetadata(),
        nbformat: 4,
        nbformat_minor: 5,
      });
      const result = parser.parse(json);
      const parsedOutput = result.cells[0].outputs![0];
      expect(parsedOutput.output_type).toBe("error");
      expect(parsedOutput.ename).toBe("ZeroDivisionError");
      expect(parsedOutput.evalue).toBe("division by zero");
    });

    it("should parse image output", () => {
      const output = OutputFactory.imagePng("base64data");
      const cell = CellFactory.codeWithOutput("plt.show()", [output]);
      const json = JSON.stringify({
        cells: [cell],
        metadata: NotebookFactory.defaultMetadata(),
        nbformat: 4,
        nbformat_minor: 5,
      });
      const result = parser.parse(json);
      const parsedOutput = result.cells[0].outputs![0];
      expect(parsedOutput.data).toBeDefined();
      expect(parsedOutput.data!["image/png"]).toBe("base64data");
    });
  });

  // ============================================================================
  // Metadata Parsing
  // ============================================================================

  describe("metadata parsing", () => {
    it("should parse kernel metadata", () => {
      const json = JSON.stringify(NotebookFactory.simple());
      const result = parser.parse(json);
      expect(result.metadata.kernelspec).toBeDefined();
      expect(result.metadata.kernelspec!.display_name).toBe("Python 3");
    });

    it("should parse language info", () => {
      const json = JSON.stringify(NotebookFactory.simple());
      const result = parser.parse(json);
      expect(result.metadata.language_info).toBeDefined();
      expect(result.metadata.language_info!.name).toBe("python");
    });
  });

  // ============================================================================
  // Error Handling
  // ============================================================================

  describe("error handling", () => {
    it("should throw on invalid JSON", () => {
      expect(() => parser.parse("not valid json")).toThrow();
    });

    it("should throw on missing nbformat", () => {
      const json = JSON.stringify({ cells: [], metadata: {} });
      expect(() => parser.parse(json)).toThrow();
    });

    it("should throw on unsupported nbformat", () => {
      const json = JSON.stringify({ cells: [], metadata: {}, nbformat: 3 });
      expect(() => parser.parse(json)).toThrow();
    });

    it("should throw on missing cells", () => {
      const json = JSON.stringify({ metadata: {}, nbformat: 4 });
      expect(() => parser.parse(json)).toThrow();
    });
  });

  // ============================================================================
  // Complex Notebooks
  // ============================================================================

  describe("complex notebooks", () => {
    it("should parse notebook with rich outputs", () => {
      const json = JSON.stringify(NotebookFactory.withRichOutputs());
      const result = parser.parse(json);
      expect(result.cells).toHaveLength(2);
      expect(result.cells[0].outputs!.length).toBeGreaterThan(0);
    });

    it("should parse notebook with errors", () => {
      const json = JSON.stringify(NotebookFactory.withErrors());
      const result = parser.parse(json);
      expect(result.cells).toHaveLength(1);
      expect(result.cells[0].outputs![0].output_type).toBe("error");
    });

    it("should parse complex notebook", () => {
      const json = JSON.stringify(NotebookFactory.complex());
      const result = parser.parse(json);
      expect(result.cells).toHaveLength(5);
      expect(result.cells.some((c) => c.cell_type === "markdown")).toBe(true);
      expect(result.cells.some((c) => c.cell_type === "code")).toBe(true);
    });
  });
});
