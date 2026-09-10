/**
 * Markdown Domain Models - Full GitHub Flavored Markdown Support
 */

// ============================================================================
// AST Node Types - Complete GFM + GitHub Extensions
// ============================================================================

export type MarkdownNodeType =
  // Document structure
  | "document"
  | "heading"
  | "paragraph"
  | "text"
  
  // Inline formatting (GFM)
  | "bold"
  | "italic"
  | "strikethrough"
  | "code_inline"
  | "link"
  | "image"
  | "autolink"
  
  // Extended inline (GitHub-specific)
  | "subscript"
  | "superscript"
  | "underline"
  | "highlight"
  | "keyboard"
  | "emoji"
  | "color"
  
  // Math
  | "math_inline"
  | "math_display"
  
  // Block elements
  | "code_block"
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
  
  // HTML elements (allowed in GFM)
  | "html_block"
  | "html_inline"
  | "details"
  | "summary"
  | "picture"
  
  // GitHub-specific blocks
  | "alert"
  | "footnote_def"
  | "footnote_ref"
  | "mermaid"
  
  // Raw passthrough
  | "raw_html";

export interface MarkdownASTNode {
  type: MarkdownNodeType;
  content?: string;
  children?: MarkdownASTNode[];
  attributes?: Record<string, string>;
  level?: number;
  language?: string;
  ordered?: boolean;
  checked?: boolean;  // For task items
  isHTML?: boolean;
  
  // Alert-specific
  alertType?: "note" | "tip" | "important" | "warning" | "caution";
  
  // Math
  mathContent?: string;
  
  // Footnote
  footnoteId?: string;
  footnoteLabel?: string;
  
  // Emoji
  emojiName?: string;
  emojiChar?: string;
  
  // Color
  colorValue?: string;
  colorFormat?: "hex" | "rgb" | "hsl";
}

// ============================================================================
// Markdown-specific Configuration
// ============================================================================

export interface MarkdownConfig {
  // GFM features
  enableTables: boolean;
  enableTaskLists: boolean;
  enableStrikethrough: boolean;
  enableAutolinks: boolean;
  enableTagFilter: boolean;
  
  // GitHub extensions
  enableAlerts: boolean;
  enableMath: boolean;
  enableMermaid: boolean;
  enableFootnotes: boolean;
  enableEmoji: boolean;
  enableColorModels: boolean;
  
  // HTML support
  enableHTML: boolean;
  allowedHtmlTags: string[];
  
  // Rendering
  enableImages: boolean;
  enableSubscript: boolean;
  enableSuperscript: boolean;
  enableUnderline: boolean;
  enableHighlight: boolean;
  enableKeyboard: boolean;
}

// ============================================================================
// GitHub Alert Types
// ============================================================================

export type AlertType = "note" | "tip" | "important" | "warning" | "caution";

export interface AlertConfig {
  type: AlertType;
  icon: string;
  color: string;
  title: string;
}

export const ALERT_CONFIGS: Record<AlertType, AlertConfig> = {
  note: { type: "note", icon: "ℹ️", color: "#0969da", title: "Note" },
  tip: { type: "tip", icon: "💡", color: "#1a7f37", title: "Tip" },
  important: { type: "important", icon: "❗", color: "#8250df", title: "Important" },
  warning: { type: "warning", icon: "⚠️", color: "#9a6700", title: "Warning" },
  caution: { type: "caution", icon: "🛑", color: "#bc4c00", title: "Caution" },
};
