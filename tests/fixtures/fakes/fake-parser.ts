/**
 * Fake Parser
 * In-memory fake implementation for testing
 */

import type { ParserPort } from "../../../shared/domain/ports";
import type { MarkdownASTNode } from "../../../plugins/markdown/domain/models/types";

export class FakeMarkdownParser implements ParserPort<string, MarkdownASTNode> {
  public parseCount = 0;
  public lastInput: string | null = null;
  public returnAst: MarkdownASTNode | null = null;
  public shouldThrow = false;
  public errorMessage = "Parse error";

  parse(input: string): MarkdownASTNode {
    this.parseCount++;
    this.lastInput = input;

    if (this.shouldThrow) {
      throw new Error(this.errorMessage);
    }

    if (this.returnAst) {
      return this.returnAst;
    }

    // Return a simple AST
    return {
      type: "document",
      children: [
        {
          type: "paragraph",
          children: [{ type: "text", content: input }],
        },
      ],
    };
  }

  setReturnAst(ast: MarkdownASTNode): void {
    this.returnAst = ast;
  }

  setError(message: string): void {
    this.shouldThrow = true;
    this.errorMessage = message;
  }

  reset(): void {
    this.parseCount = 0;
    this.lastInput = null;
    this.returnAst = null;
    this.shouldThrow = false;
    this.errorMessage = "Parse error";
  }
}

export class FakeNotebookParser implements ParserPort<string, unknown> {
  public parseCount = 0;
  public lastInput: string | null = null;
  public returnNotebook: unknown = null;
  public shouldThrow = false;
  public errorMessage = "Parse error";

  parse(input: string): unknown {
    this.parseCount++;
    this.lastInput = input;

    if (this.shouldThrow) {
      throw new Error(this.errorMessage);
    }

    if (this.returnNotebook) {
      return this.returnNotebook;
    }

    // Return a simple notebook
    return {
      cells: [],
      metadata: {
        kernelspec: { display_name: "Python 3", language: "python", name: "python3" },
        language_info: { name: "python", version: "3.9.7" },
      },
      nbformat: 4,
      nbformat_minor: 5,
    };
  }

  setReturnNotebook(notebook: unknown): void {
    this.returnNotebook = notebook;
  }

  setError(message: string): void {
    this.shouldThrow = true;
    this.errorMessage = message;
  }

  reset(): void {
    this.parseCount = 0;
    this.lastInput = null;
    this.returnNotebook = null;
    this.shouldThrow = false;
    this.errorMessage = "Parse error";
  }
}
