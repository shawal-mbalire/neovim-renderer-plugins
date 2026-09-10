/**
 * Markdown Domain Models
 * Pure data structures for GFM + GitHub extensions
 */

// ============================================================================
// StrEnum Pattern
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
  | "horizontal_rule"
  | "alert"
  | "math_inline"
  | "math_display"
  | "emoji"
  | "footnote_ref"
  | "footnote_def"
  | "html_block"
  | "raw_html"
  | "mermaid";

export type AlertType = "note" | "tip" | "important" | "warning" | "caution";

// ============================================================================
// Dataclass Pattern
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
  readonly alertType?: AlertType;
  readonly mathContent?: string;
  readonly footnoteId?: string;
  readonly emojiName?: string;
  readonly isHTML?: boolean;
}

// ============================================================================
// Factory Functions
// ============================================================================

export function createMarkdownNode(
  type: MarkdownNodeType,
  options: Partial<Omit<MarkdownASTNode, "type">> = {}
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

export function createCodeBlock(code: string, language?: string): MarkdownASTNode {
  return createMarkdownNode("code_block", { content: code, language });
}

export function createAlert(alertType: AlertType, content: string): MarkdownASTNode {
  return createMarkdownNode("alert", {
    alertType,
    children: [createMarkdownNode("text", { content })],
  });
}
