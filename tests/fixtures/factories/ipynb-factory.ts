/**
 * ipynb Test Factory
 * Creates test notebook JSON and cell objects
 */

import type { Notebook, Cell, Output, OutputData } from "../../../plugins/ipynb/domain/models/types";

// ============================================================================
// Notebook Factory
// ============================================================================

export const NotebookFactory = {
  // Empty notebook
  empty: (): Notebook => ({
    cells: [],
    metadata: NotebookFactory.defaultMetadata(),
    nbformat: 4,
    nbformat_minor: 5,
  }),

  // Simple notebook with one code cell
  simple: (): Notebook => ({
    cells: [
      CellFactory.code('print("Hello, World!")'),
    ],
    metadata: NotebookFactory.defaultMetadata(),
    nbformat: 4,
    nbformat_minor: 5,
  }),

  // Notebook with mixed cells
  mixed: (): Notebook => ({
    cells: [
      CellFactory.markdown("# Title\n\nThis is a markdown cell."),
      CellFactory.code('x = 1\nprint(x)'),
      CellFactory.code('y = x + 1\nprint(y)'),
      CellFactory.markdown("## Conclusion\n\nDone."),
    ],
    metadata: NotebookFactory.defaultMetadata(),
    nbformat: 4,
    nbformat_minor: 5,
  }),

  // Notebook with outputs
  withOutputs: (): Notebook => ({
    cells: [
      CellFactory.codeWithOutput(
        'print("Hello")',
        [OutputFactory.stream(["Hello\n"])]
      ),
      CellFactory.codeWithOutput(
        'x = [1, 2, 3]\nprint(x)',
        [OutputFactory.stream(["[1, 2, 3]\n"])]
      ),
    ],
    metadata: NotebookFactory.defaultMetadata(),
    nbformat: 4,
    nbformat_minor: 5,
  }),

  // Notebook with rich outputs
  withRichOutputs: (): Notebook => ({
    cells: [
      CellFactory.codeWithOutput(
        'import matplotlib.pyplot as plt\nplt.plot([1, 2, 3])',
        [
          OutputFactory.imagePng("base64encodedpng"),
          OutputFactory.html(["<div>Plot</div>"]),
        ]
      ),
      CellFactory.codeWithOutput(
        '{"key": "value"}',
        [OutputFactory.json({"key": "value"})]
      ),
    ],
    metadata: NotebookFactory.defaultMetadata(),
    nbformat: 4,
    nbformat_minor: 5,
  }),

  // Notebook with errors
  withErrors: (): Notebook => ({
    cells: [
      CellFactory.codeWithOutput(
        '1/0',
        [OutputFactory.error("ZeroDivisionError", "division by zero", ["Traceback: ZeroDivisionError"])]
      ),
    ],
    metadata: NotebookFactory.defaultMetadata(),
    nbformat: 4,
    nbformat_minor: 5,
  }),

  // Complex notebook
  complex: (): Notebook => ({
    cells: [
      CellFactory.markdown("# Data Analysis\n\nAnalyze the data."),
      CellFactory.codeWithOutput(
        'import pandas as pd\ndf = pd.DataFrame({"a": [1, 2], "b": [3, 4]})\ndf.head()',
        [OutputFactory.html(["<table><tr><td>Data</td></tr></table>"])]
      ),
      CellFactory.codeWithOutput(
        'df.describe()',
        [OutputFactory.text(["count    2.0\nmean     2.5"])]
      ),
      CellFactory.markdown("## Results\n\nThe data shows..."),
      CellFactory.codeWithOutput(
        'plt.figure()\nplt.plot(df["a"], df["b"])\nplt.show()',
        [OutputFactory.imagePng("plotbase64")]
      ),
    ],
    metadata: NotebookFactory.defaultMetadata(),
    nbformat: 4,
    nbformat_minor: 5,
  }),

  // From JSON string
  fromJson: (json: string): Notebook => {
    return JSON.parse(json);
  },

  // Default metadata
  defaultMetadata: () => ({
    kernelspec: {
      display_name: "Python 3",
      language: "python",
      name: "python3",
    },
    language_info: {
      name: "python",
      version: "3.9.7",
      mimetype: "text/x-python",
      file_extension: ".py",
    },
  }),
};

// ============================================================================
// Cell Factory
// ============================================================================

export const CellFactory = {
  // Code cell
  code: (source: string): Cell => ({
    cell_type: "code",
    source: source.split("\n"),
    outputs: [],
    execution_count: null,
    metadata: {},
  }),

  // Code cell with output
  codeWithOutput: (source: string, outputs: Output[]): Cell => ({
    cell_type: "code",
    source: source.split("\n"),
    outputs,
    execution_count: 1,
    metadata: {},
  }),

  // Code cell with execution count
  codeWithExecution: (source: string, executionCount: number): Cell => ({
    cell_type: "code",
    source: source.split("\n"),
    outputs: [],
    execution_count: executionCount,
    metadata: {},
  }),

  // Markdown cell
  markdown: (source: string): Cell => ({
    cell_type: "markdown",
    source: source.split("\n"),
    metadata: {},
  }),

  // Raw cell
  raw: (source: string): Cell => ({
    cell_type: "raw",
    source: source.split("\n"),
    metadata: {},
  }),

  // From array of lines
  fromLines: (type: "code" | "markdown" | "raw", lines: string[]): Cell => ({
    cell_type: type,
    source: lines,
    metadata: {},
  }),
};

// ============================================================================
// Output Factory
// ============================================================================

export const OutputFactory = {
  // Stream output
  stream: (text: string[], name: string = "stdout"): Output => ({
    output_type: "stream",
    name,
    text,
  }),

  // Execute result
  executeResult: (data: OutputData, executionCount: number = 1): Output => ({
    output_type: "execute_result",
    data,
    execution_count: executionCount,
  }),

  // Display data
  displayData: (data: OutputData): Output => ({
    output_type: "display_data",
    data,
  }),

  // Error output
  error: (ename: string, evalue: string, traceback: string[]): Output => ({
    output_type: "error",
    ename,
    evalue,
    traceback,
  }),

  // Text output
  text: (text: string[]): Output => ({
    output_type: "execute_result",
    data: { "text/plain": text },
  }),

  // HTML output
  html: (html: string[]): Output => ({
    output_type: "execute_result",
    data: { "text/html": html },
  }),

  // JSON output
  json: (obj: unknown): Output => ({
    output_type: "execute_result",
    data: { "application/json": JSON.stringify(obj, null, 2) },
  }),

  // Image output
  imagePng: (base64: string): Output => ({
    output_type: "display_data",
    data: { "image/png": base64 },
  }),

  imageJpeg: (base64: string): Output => ({
    output_type: "display_data",
    data: { "image/jpeg": base64 },
  }),

  // SVG output
  svg: (svg: string): Output => ({
    output_type: "display_data",
    data: { "image/svg+xml": svg },
  }),

  // LaTeX output
  latex: (latex: string[]): Output => ({
    output_type: "execute_result",
    data: { "text/latex": latex },
  }),

  // Markdown output
  markdown: (md: string[]): Output => ({
    output_type: "execute_result",
    data: { "text/markdown": md },
  }),
};

// ============================================================================
// Notebook JSON Factory
// ============================================================================

export const NotebookJsonFactory = {
  minimal: (): string => JSON.stringify({
    cells: [],
    metadata: {
      kernelspec: { display_name: "Python 3", language: "python", name: "python3" },
      language_info: { name: "python", version: "3.9.7" },
    },
    nbformat: 4,
    nbformat_minor: 5,
  }),

  withCodeCell: (code: string): string => JSON.stringify({
    cells: [
      {
        cell_type: "code",
        source: code.split("\n"),
        outputs: [],
        execution_count: null,
        metadata: {},
      },
    ],
    metadata: NotebookFactory.defaultMetadata(),
    nbformat: 4,
    nbformat_minor: 5,
  }),

  invalid: (): string => "not valid json",
  
  wrongNbformat: (): string => JSON.stringify({
    cells: [],
    metadata: {},
    nbformat: 3,
    nbformat_minor: 0,
  }),
};
