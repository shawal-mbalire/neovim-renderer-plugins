/**
 * Markdown Domain Models
 * Pure data structures for GFM + GitHub extensions
 */

// ============================================================================
// Node Types (StrEnum pattern)
// ============================================================================

export type MarkdownNodeType =
  | "document"
  | "heading"
  | "paragraph"
  | "text"
  | "bold"
  | "italic"
  | "strikethrough"
  | "code_inline"
  | "code_block"
  | "link"
  | "image"
  | "blockquote"
  | "list_item"
  | "ordered_list"
  | "unordered_list"
  | "task_list"
  | "task_item"
  | "table"
  | "table_row"
  | "table_cell"
  | "horizontal_rule";

// ============================================================================
// AST Node
// ============================================================================

export interface MarkdownASTNode {
  readonly type: MarkdownNodeType;
  readonly content?: string;
  readonly children?: ReadonlyArray<MarkdownASTNode>;
  readonly attributes?: Readonly<Record<string, string>>;
  readonly level?: number;
  readonly language?: string;
  readonly ordered?: boolean;
  readonly checked?: boolean;
}

// ============================================================================
// Factory Functions
// ============================================================================

export function createMarkdownNode(
  type: MarkdownNodeType,
  options: Partial<Omit<MarkdownASTNode, "type">> = {},
): MarkdownASTNode {
  return { type, ...options };
}

export function createHeading(level: number, content: string): MarkdownASTNode {
  return createMarkdownNode("heading", {
    level,
    children: [createMarkdownNode("text", { content })],
  });
}

export function createParagraph(content: string): MarkdownASTNode {
  return createMarkdownNode("paragraph", {
    children: [createMarkdownNode("text", { content })],
  });
}

export function createCodeBlock(
  code: string,
  language?: string,
): MarkdownASTNode {
  return createMarkdownNode("code_block", { content: code, language });
}
