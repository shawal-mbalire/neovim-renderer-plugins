/**
 * Markdown Domain Models
 */

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

export interface MarkdownASTNode {
  type: MarkdownNodeType;
  content?: string;
  children?: MarkdownASTNode[];
  attributes?: Record<string, string>;
  level?: number;
  language?: string;
  ordered?: boolean;
  checked?: boolean;
  alertType?: "note" | "tip" | "important" | "warning" | "caution";
  mathContent?: string;
  footnoteId?: string;
  emojiName?: string;
  isHTML?: boolean;
}
