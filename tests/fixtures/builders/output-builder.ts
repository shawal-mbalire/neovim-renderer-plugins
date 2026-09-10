/**
 * Output Builder
 * Fluent builder for constructing notebook outputs
 */

import type { Output, OutputData, OutputType } from "../../../plugins/ipynb/domain/models/types";

export class OutputBuilder {
  private outputType: OutputType = "stream";
  private _streamName: string = "stdout";
  private _streamText: string[] = [];
  private outputData: OutputData = {};
  private _executionCount: number | null = null;
  private _errorName: string = "Error";
  private _errorValue: string = "";
  private _errorTraceback: string[] = [];
  private metadata: Record<string, unknown> = {};

  // ============================================================================
  // Output Type
  // ============================================================================

  asStream(name: string = "stdout"): this {
    this.outputType = "stream";
    this._streamName = name;
    return this;
  }

  asExecuteResult(): this {
    this.outputType = "execute_result";
    return this;
  }

  asDisplayData(): this {
    this.outputType = "display_data";
    return this;
  }

  asError(): this {
    this.outputType = "error";
    return this;
  }

  // ============================================================================
  // Stream Content
  // ============================================================================

  withStreamText(text: string): this {
    this._streamText = text.split("\n");
    return this;
  }

  withStreamLines(lines: string[]): this {
    this._streamText = [...lines];
    return this;
  }

  addStreamLine(line: string): this {
    this._streamText.push(line);
    return this;
  }

  // ============================================================================
  // Rich Output Content
  // ============================================================================

  withText(text: string): this {
    this.outputData["text/plain"] = text.split("\n");
    return this;
  }

  withTextLines(lines: string[]): this {
    this.outputData["text/plain"] = [...lines];
    return this;
  }

  withHtml(html: string): this {
    this.outputData["text/html"] = html.split("\n");
    return this;
  }

  withHtmlLines(lines: string[]): this {
    this.outputData["text/html"] = [...lines];
    return this;
  }

  withMarkdown(md: string): this {
    this.outputData["text/markdown"] = md.split("\n");
    return this;
  }

  withJson(obj: unknown): this {
    this.outputData["application/json"] = JSON.stringify(obj, null, 2);
    return this;
  }

  withJavascript(js: string): this {
    this.outputData["application/javascript"] = js.split("\n");
    return this;
  }

  withImagePng(base64: string): this {
    this.outputData["image/png"] = base64;
    return this;
  }

  withImageJpeg(base64: string): this {
    this.outputData["image/jpeg"] = base64;
    return this;
  }

  withImageGif(base64: string): this {
    this.outputData["image/gif"] = base64;
    return this;
  }

  withImageSvg(svg: string): this {
    this.outputData["image/svg+xml"] = svg;
    return this;
  }

  withLatex(latex: string): this {
    this.outputData["text/latex"] = latex.split("\n");
    return this;
  }

  // ============================================================================
  // Error Content
  // ============================================================================

  withErrorName(name: string): this {
    this._errorName = name;
    return this;
  }

  withErrorValue(value: string): this {
    this._errorValue = value;
    return this;
  }

  withErrorTraceback(traceback: string[]): this {
    this._errorTraceback = [...traceback];
    return this;
  }

  addTracebackLine(line: string): this {
    this._errorTraceback.push(line);
    return this;
  }

  // ============================================================================
  // Execution
  // ============================================================================

  withExecutionCount(count: number): this {
    this._executionCount = count;
    return this;
  }

  // ============================================================================
  // Metadata
  // ============================================================================

  withMetadata(key: string, value: unknown): this {
    this.metadata[key] = value;
    return this;
  }

  // ============================================================================
  // Build
  // ============================================================================

  build(): Output {
    switch (this.outputType) {
      case "stream":
        return {
          output_type: "stream",
          name: this._streamName,
          text: this._streamText,
        };

      case "execute_result":
        return {
          output_type: "execute_result",
          data: Object.keys(this.outputData).length > 0 ? this.outputData : undefined,
          execution_count: this._executionCount,
          metadata: this.metadata,
        };

      case "display_data":
        return {
          output_type: "display_data",
          data: Object.keys(this.outputData).length > 0 ? this.outputData : undefined,
          metadata: this.metadata,
        };

      case "error":
        return {
          output_type: "error",
          ename: this._errorName,
          evalue: this._errorValue,
          traceback: this._errorTraceback,
        };

      default:
        throw new Error(`Unknown output type: ${this.outputType}`);
    }
  }

  // Reset builder
  reset(): this {
    this.outputType = "stream";
    this._streamName = "stdout";
    this._streamText = [];
    this.outputData = {};
    this._executionCount = null;
    this._errorName = "Error";
    this._errorValue = "";
    this._errorTraceback = [];
    this.metadata = {};
    return this;
  }

  // ============================================================================
  // Static Factory Methods
  // ============================================================================

  static create(): OutputBuilder {
    return new OutputBuilder();
  }

  static stream(text: string, name: string = "stdout"): Output {
    return OutputBuilder.create()
      .asStream(name)
      .withStreamText(text)
      .build();
  }

  static text(text: string): Output {
    return OutputBuilder.create()
      .asExecuteResult()
      .withText(text)
      .build();
  }

  static html(html: string): Output {
    return OutputBuilder.create()
      .asExecuteResult()
      .withHtml(html)
      .build();
  }

  static error(ename: string, evalue: string, traceback: string[]): Output {
    return OutputBuilder.create()
      .asError()
      .withErrorName(ename)
      .withErrorValue(evalue)
      .withErrorTraceback(traceback)
      .build();
  }

  static image(base64: string, format: "png" | "jpeg" = "png"): Output {
    const builder = OutputBuilder.create().asDisplayData();
    if (format === "png") {
      builder.withImagePng(base64);
    } else {
      builder.withImageJpeg(base64);
    }
    return builder.build();
  }

  static json(obj: unknown): Output {
    return OutputBuilder.create()
      .asExecuteResult()
      .withJson(obj)
      .build();
  }
}
