---
--- Shared Domain Ports
--- Interfaces that adapters must implement
---

local shared_ports = {}

-- ============================================================================
-- Parser Port
-- ============================================================================

---@class ParserPort
---@field parse fun(input: string): table

-- ============================================================================
-- Renderer Port
-- ============================================================================

---@class RendererPort
---@field render fun(input: table, start_line?: number): RenderResult

-- ============================================================================
-- Timing Port
-- ============================================================================

---@class TimingPort
---@field start fun(): number
---@field stop fun(start_time: number): number

-- ============================================================================
-- State Port
-- ============================================================================

---@class StatePort
---@field get fun(): table
---@field set fun(state: table): nil

return shared_ports
