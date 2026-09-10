---
--- Shared Domain Models
--- Pure data structures used across all plugins
---

local shared_models = {}

-- ============================================================================
-- Render Types
-- ============================================================================

---@class RenderMark
---@field line number
---@field col number
---@field end_col number
---@field hl string
---@field virt_text? string

---@class RenderImage
---@field col number
---@field row number
---@field width number
---@field height number
---@field path? string
---@field placeholder? string

---@class RenderLine
---@field line number
---@field text string
---@field marks RenderMark[]
---@field images RenderImage[]

---@class RenderResult
---@field lines RenderLine[]
---@field errors RenderError[]

---@class RenderError
---@field line number
---@field column number
---@field message string
---@field severity string

-- ============================================================================
-- Factory Functions
-- ============================================================================

---@param line number
---@param text string
---@param marks? RenderMark[]
---@param images? RenderImage[]
---@return RenderLine
function shared_models.create_render_line(line, text, marks, images)
  return {
    line = line,
    text = text,
    marks = marks or {},
    images = images or {},
  }
end

---@param col_start number
---@param col_end number
---@field hl_group string
---@return RenderMark
function shared_models.create_render_mark(col_start, col_end, hl_group)
  return {
    line = 0,
    col = col_start,
    end_col = col_end,
    hl = hl_group,
  }
end

---@return RenderResult
function shared_models.create_render_result()
  return {
    lines = {},
    errors = {},
  }
end

return shared_models
