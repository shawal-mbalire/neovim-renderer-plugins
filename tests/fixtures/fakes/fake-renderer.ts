/**
 * Fake Renderer
 * In-memory fake implementation for testing
 */

import type { RendererPort } from "../../../shared/domain/ports";
import type { RenderResult, RenderLine } from "../../../shared/domain/models/types";

export class FakeRenderer implements RendererPort {
  public renderCount = 0;
  public lastInput: unknown = null;
  public returnResult: RenderResult | null = null;
  public shouldThrow = false;
  public errorMessage = "Render error";

  render(input: unknown, startLine?: number): RenderResult {
    this.renderCount++;
    this.lastInput = input;

    if (this.shouldThrow) {
      throw new Error(this.errorMessage);
    }

    if (this.returnResult) {
      return this.returnResult;
    }

    // Return a simple result
    return {
      lines: [
        {
          line: startLine || 0,
          text: "Rendered content",
          marks: [],
          images: [],
        },
      ],
      errors: [],
    };
  }

  setReturnResult(result: RenderResult): void {
    this.returnResult = result;
  }

  setError(message: string): void {
    this.shouldThrow = true;
    this.errorMessage = message;
  }

  reset(): void {
    this.renderCount = 0;
    this.lastInput = null;
    this.returnResult = null;
    this.shouldThrow = false;
    this.errorMessage = "Render error";
  }
}

export class FakeMarkdownRenderer implements RendererPort {
  public renderCount = 0;
  public lastInput: unknown = null;
  public returnResult: RenderResult | null = null;
  public shouldThrow = false;
  public errorMessage = "Render error";

  render(input: unknown, startLine?: number): RenderResult {
    this.renderCount++;
    this.lastInput = input;

    if (this.shouldThrow) {
      throw new Error(this.errorMessage);
    }

    if (this.returnResult) {
      return this.returnResult;
    }

    // Return a simple markdown result
    return {
      lines: [
        {
          line: startLine || 0,
          text: "# Rendered Markdown",
          marks: [
            {
              col_start: 0,
              col_end: 17,
              hl_group: "Title",
            },
          ],
          images: [],
        },
      ],
      errors: [],
    };
  }

  setReturnResult(result: RenderResult): void {
    this.returnResult = result;
  }

  setError(message: string): void {
    this.shouldThrow = true;
    this.errorMessage = message;
  }

  reset(): void {
    this.renderCount = 0;
    this.lastInput = null;
    this.returnResult = null;
    this.shouldThrow = false;
    this.errorMessage = "Render error";
  }
}

export class FakeNotebookRenderer implements RendererPort {
  public renderCount = 0;
  public lastInput: unknown = null;
  public returnResult: RenderResult | null = null;
  public shouldThrow = false;
  public errorMessage = "Render error";

  render(input: unknown, startLine?: number): RenderResult {
    this.renderCount++;
    this.lastInput = input;

    if (this.shouldThrow) {
      throw new Error(this.errorMessage);
    }

    if (this.returnResult) {
      return this.returnResult;
    }

    // Return a simple notebook result
    return {
      lines: [
        {
          line: startLine || 0,
          text: "=== Python 3 ===",
          marks: [
            {
              col_start: 0,
              col_end: 16,
              hl_group: "Comment",
            },
          ],
          images: [],
        },
      ],
      errors: [],
    };
  }

  setReturnResult(result: RenderResult): void {
    this.returnResult = result;
  }

  setError(message: string): void {
    this.shouldThrow = true;
    this.errorMessage = message;
  }

  reset(): void {
    this.renderCount = 0;
    this.lastInput = null;
    this.returnResult = null;
    this.shouldThrow = false;
    this.errorMessage = "Render error";
  }
}
