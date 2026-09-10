---
--- Image Domain Models
--- Pure data structures for image rendering
---

local image_models = {}

-- ============================================================================
-- Image Types
-- ============================================================================

---@alias ImageFormat "png" | "jpeg" | "gif" | "webp" | "bmp" | "tiff"
---@alias ImageProtocol "kgp" | "kgp_old" | "iip" | "sixel" | "none"

---@class ImageInfo
---@field format ImageFormat
---@field width number
---@field height number
---@field size number
---@field path string

---@class TerminalInfo
---@field protocol ImageProtocol
---@field supported ImageProtocol[]
---@field tmux boolean

-- ============================================================================
-- Constants
-- ============================================================================

local IMAGE_EXTENSIONS = {
  png = true,
  jpeg = true,
  jpg = true,
  gif = true,
  webp = true,
  bmp = true,
  tiff = true,
}

-- ============================================================================
-- Factory Functions
-- ============================================================================

---@return TerminalInfo
function image_models.create_terminal_info()
  local term_value = os.getenv("TERM") or ""
  local term_program = os.getenv("TERM_PROGRAM") or ""
  local is_tmux = os.getenv("TMUX") ~= nil

  local supported = {}

  -- Kitty
  if term_program:lower():find("kitty") or term_value:lower():find("kitty") then
    if not is_tmux then
      supported[#supported + 1] = "kgp"
    end
    supported[#supported + 1] = "kgp_old"
  end

  -- IIP (iTerm2, WezTerm, etc.)
  local iip_terminals = { "iterm2", "wezterm", "warp", "vscode" }
  for _, terminal_name in ipairs(iip_terminals) do
    if term_program:lower():find(terminal_name) then
      supported[#supported + 1] = "iip"
      break
    end
  end

  if os.getenv("VSCODE_INJECTION") == "1" then
    supported[#supported + 1] = "iip"
  end

  -- Sixel
  if term_value:find("sixel") or term_program:lower():find("foot") then
    supported[#supported + 1] = "sixel"
  end

  return {
    protocol = supported[1] or "none",
    supported = supported,
    tmux = is_tmux,
  }
end

---@param file_path string
---@return boolean
function image_models.is_image_file(file_path)
  local ext = file_path:match("%.([^%.]+)$")
  return ext and IMAGE_EXTENSIONS[ext:lower()] or false
end

---@param size_bytes number
---@return string
function image_models.format_file_size(size_bytes)
  if size_bytes < 1024 then
    return string.format("%d B", size_bytes)
  elseif size_bytes < 1024 * 1024 then
    return string.format("%.1f KB", size_bytes / 1024)
  else
    return string.format("%.1f MB", size_bytes / (1024 * 1024))
  end
end

return image_models
