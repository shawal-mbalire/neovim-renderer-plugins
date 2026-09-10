/**
 * Markdown Parser Unit Tests
 */

import { describe, it, expect, beforeEach } from "bun:test";
import { MarkdownParser } from "../../../plugins/markdown/adapters/parser";
import { MarkdownFactory, ASTFactory } from "../../fixtures";

describe("MarkdownParser", () => {
  let parser: MarkdownParser;

  beforeEach(() => {
    parser = new MarkdownParser();
  });

  // ============================================================================
  // Basic Parsing
  // ============================================================================

  describe("basic parsing", () => {
    it("should parse empty string", () => {
      const result = parser.parse("");
      expect(result.type).toBe("document");
      expect(result.children).toHaveLength(0);
    });

    it("should parse simple text", () => {
      const result = parser.parse("Hello, world!");
      expect(result.type).toBe("document");
      expect(result.children).toHaveLength(1);
      expect(result.children![0].type).toBe("paragraph");
    });

    it("should parse multiple paragraphs", () => {
      const result = parser.parse(MarkdownFactory.multipleParagraphs());
      expect(result.children).toHaveLength(3);
      expect(result.children![0].type).toBe("paragraph");
      expect(result.children![1].type).toBe("paragraph");
      expect(result.children![2].type).toBe("paragraph");
    });
  });

  // ============================================================================
  // Headings
  // ============================================================================

  describe("headings", () => {
    it("should parse heading level 1", () => {
      const result = parser.parse(MarkdownFactory.heading(1));
      expect(result.children).toHaveLength(1);
      expect(result.children![0].type).toBe("heading");
      expect(result.children![0].level).toBe(1);
    });

    it("should parse all heading levels", () => {
      const result = parser.parse(MarkdownFactory.allHeadings());
      expect(result.children).toHaveLength(6);
      expect(result.children![0].level).toBe(1);
      expect(result.children![5].level).toBe(6);
    });
  });

  // ============================================================================
  // Inline Formatting
  // ============================================================================

  describe("inline formatting", () => {
    it("should parse bold text", () => {
      const result = parser.parse(MarkdownFactory.bold());
      const paragraph = result.children![0];
      expect(paragraph.type).toBe("paragraph");
      expect(paragraph.children).toBeDefined();
      expect(paragraph.children!.some((c) => c.type === "bold")).toBe(true);
    });

    it("should parse italic text", () => {
      const result = parser.parse(MarkdownFactory.italic());
      const paragraph = result.children![0];
      expect(paragraph.children!.some((c) => c.type === "italic")).toBe(true);
    });

    it("should parse strikethrough text", () => {
      const result = parser.parse(MarkdownFactory.strikethrough());
      const paragraph = result.children![0];
      expect(paragraph.children!.some((c) => c.type === "strikethrough")).toBe(true);
    });

    it("should parse inline code", () => {
      const result = parser.parse(MarkdownFactory.codeInline());
      const paragraph = result.children![0];
      expect(paragraph.children!.some((c) => c.type === "code_inline")).toBe(true);
    });

    it("should parse mixed inline formatting", () => {
      const result = parser.parse(MarkdownFactory.mixedInline());
      const paragraph = result.children![0];
      expect(paragraph.children!.length).toBeGreaterThan(1);
    });
  });

  // ============================================================================
  // Code Blocks
  // ============================================================================

  describe("code blocks", () => {
    it("should parse fenced code block", () => {
      const result = parser.parse(MarkdownFactory.codeBlock());
      expect(result.children).toHaveLength(1);
      expect(result.children![0].type).toBe("code_block");
      expect(result.children![0].language).toBe("typescript");
    });

    it("should parse code block with language", () => {
      const result = parser.parse(MarkdownFactory.codeBlockWithLanguage("python"));
      expect(result.children![0].language).toBe("python");
    });
  });

  // ============================================================================
  // Lists
  // ============================================================================

  describe("lists", () => {
    it("should parse unordered list", () => {
      const result = parser.parse(MarkdownFactory.unorderedList());
      expect(result.children).toHaveLength(1);
      expect(result.children![0].type).toBe("unordered_list");
      expect(result.children![0].children).toHaveLength(3);
    });

    it("should parse ordered list", () => {
      const result = parser.parse(MarkdownFactory.orderedList());
      expect(result.children).toHaveLength(1);
      expect(result.children![0].type).toBe("ordered_list");
      expect(result.children![0].children).toHaveLength(3);
    });

    it("should parse task list", () => {
      const result = parser.parse(MarkdownFactory.taskList());
      expect(result.children).toHaveLength(1);
      expect(result.children![0].type).toBe("task_list");
      expect(result.children![0].children).toHaveLength(3);
    });
  });

  // ============================================================================
  // Tables
  // ============================================================================

  describe("tables", () => {
    it("should parse simple table", () => {
      const result = parser.parse(MarkdownFactory.simpleTable());
      expect(result.children).toHaveLength(1);
      expect(result.children![0].type).toBe("table");
      expect(result.children![0].children!.length).toBeGreaterThanOrEqual(2);
    });
  });

  // ============================================================================
  // Blockquotes
  // ============================================================================

  describe("blockquotes", () => {
    it("should parse blockquote", () => {
      const result = parser.parse(MarkdownFactory.blockquote());
      expect(result.children).toHaveLength(1);
      expect(result.children![0].type).toBe("blockquote");
    });
  });

  // ============================================================================
  // GitHub Alerts
  // ============================================================================

  describe("alerts", () => {
    it("should parse NOTE alert", () => {
      const result = parser.parse(MarkdownFactory.alertNote());
      expect(result.children).toHaveLength(1);
      expect(result.children![0].type).toBe("alert");
      expect(result.children![0].alertType).toBe("note");
    });

    it("should parse TIP alert", () => {
      const result = parser.parse(MarkdownFactory.alertTip());
      expect(result.children![0].alertType).toBe("tip");
    });

    it("should parse WARNING alert", () => {
      const result = parser.parse(MarkdownFactory.alertWarning());
      expect(result.children![0].alertType).toBe("warning");
    });

    it("should parse CAUTION alert", () => {
      const result = parser.parse(MarkdownFactory.alertCaution());
      expect(result.children![0].alertType).toBe("caution");
    });
  });

  // ============================================================================
  // Math
  // ============================================================================

  describe("math", () => {
    it("should parse inline math", () => {
      const result = parser.parse(MarkdownFactory.mathInline());
      const paragraph = result.children![0];
      expect(paragraph.children!.some((c) => c.type === "math_inline")).toBe(true);
    });

    it("should parse display math", () => {
      const result = parser.parse(MarkdownFactory.mathDisplay());
      expect(result.children).toHaveLength(1);
      expect(result.children![0].type).toBe("math_display");
    });
  });

  // ============================================================================
  // Emoji
  // ============================================================================

  describe("emoji", () => {
    it("should parse emoji shortcode", () => {
      const result = parser.parse(MarkdownFactory.emoji());
      const paragraph = result.children![0];
      expect(paragraph.children!.some((c) => c.type === "emoji")).toBe(true);
    });
  });

  // ============================================================================
  // HTML Extensions
  // ============================================================================

  describe("HTML extensions", () => {
    it("should parse subscript", () => {
      const result = parser.parse(MarkdownFactory.subscript());
      const paragraph = result.children![0];
      expect(paragraph.children!.some((c) => c.type === "subscript")).toBe(true);
    });

    it("should parse superscript", () => {
      const result = parser.parse(MarkdownFactory.superscript());
      const paragraph = result.children![0];
      expect(paragraph.children!.some((c) => c.type === "superscript")).toBe(true);
    });

    it("should parse underline as HTML", () => {
      const result = parser.parse(MarkdownFactory.underline());
      // HTML tags are parsed as raw_html or html_block
      expect(result.children!.length).toBeGreaterThan(0);
    });

    it("should parse highlight as HTML", () => {
      const result = parser.parse(MarkdownFactory.highlight());
      // HTML tags are parsed as raw_html or html_block
      expect(result.children!.length).toBeGreaterThan(0);
    });

    it("should parse keyboard", () => {
      const result = parser.parse(MarkdownFactory.keyboard());
      const paragraph = result.children![0];
      expect(paragraph.children!.some((c) => c.type === "keyboard")).toBe(true);
    });
  });

  // ============================================================================
  // Footnotes
  // ============================================================================

  describe("footnotes", () => {
    it("should parse footnote definition", () => {
      const result = parser.parse(MarkdownFactory.footnote());
      const footnoteDef = result.children!.find((c) => c.type === "footnote_def");
      expect(footnoteDef).toBeDefined();
      expect(footnoteDef!.footnoteId).toBe("1");
    });

    it("should parse footnote reference", () => {
      const result = parser.parse(MarkdownFactory.footnote());
      const paragraph = result.children![0];
      expect(paragraph.children!.some((c) => c.type === "footnote_ref")).toBe(true);
    });
  });

  // ============================================================================
  // Edge Cases
  // ============================================================================

  describe("edge cases", () => {
    it("should handle empty document", () => {
      const result = parser.parse(MarkdownFactory.emptyDocument());
      expect(result.children).toHaveLength(0);
    });

    it("should handle special characters", () => {
      const result = parser.parse(MarkdownFactory.specialCharacters());
      expect(result.children).toHaveLength(1);
    });

    it("should handle unicode", () => {
      const result = parser.parse(MarkdownFactory.unicode());
      expect(result.children).toHaveLength(1);
    });

    it("should handle long lines", () => {
      const result = parser.parse(MarkdownFactory.longLine());
      expect(result.children).toHaveLength(1);
    });
  });
});
