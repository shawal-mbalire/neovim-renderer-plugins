---
--- Markdown Domain Ports
--- Interfaces for markdown-specific operations
---

local markdown_ports = {}

-- ============================================================================
-- Parser Port
-- ============================================================================

---@class MarkdownParserPort
---@field parse fun(markdown: string): MarkdownASTNode

-- ============================================================================
-- Renderer Port
-- ============================================================================

---@class MarkdownRendererPort
---@field render fun(ast: MarkdownASTNode, start_line?: number): RenderResult

-- ============================================================================
-- Highlight Port
-- ============================================================================

---@class MarkdownHighlightPort
---@field ensure_highlights fun(): nil
---@field get_heading_hl fun(level: number): string

return markdown_ports
