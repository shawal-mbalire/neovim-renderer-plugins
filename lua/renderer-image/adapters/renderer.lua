---
--- Image Renderer Adapter
--- Implements ImageRendererPort
--- Handles terminal image display protocols
---

local timing_utils = require("shared.utils.timing")
local image_models = require("renderer-image.domain.models.types")

local image_renderer_adapter = {}

-- ============================================================================
-- State
-- ============================================================================

local image_id_counter = 0
local terminal_info_cache = nil

-- ============================================================================
-- Terminal Detection
-- ============================================================================

---@return TerminalInfo
local function get_terminal_info()
  if not terminal_info_cache then
    terminal_info_cache = image_models.create_terminal_info()
  end
  return terminal_info_cache
end

-- ============================================================================
-- Protocol Encoders
-- ============================================================================

---@param data string
---@param width number
---@param height number
---@return string
local function encode_kitty(data, width, height)
  image_id_counter = image_id_counter + 1
  local image_id = image_id_counter
  local base64 = vim.fn.system("base64", data):gsub("\n", "")

  local ctrl = string.format("a=T,f=100,i=%d,t=d", image_id)
  if width then
    ctrl = ctrl .. ",c=" .. width
  end
  if height then
    ctrl = ctrl .. ",r=" .. height
  end

  local chunk_size = 4096
  local chunks = {}

  for chunk_start = 1, #base64, chunk_size do
    local chunk = base64:sub(chunk_start, chunk_start + chunk_size - 1)
    local is_last = (chunk_start + chunk_size - 1) >= #base64
    local more = is_last and 0 or 1

    if chunk_start == 1 then
      chunks[#chunks + 1] = string.format("\027_%s,m=%d;%s\027\\", ctrl, more, chunk)
    else
      chunks[#chunks + 1] = string.format("\027_Gm=%d;%s\027\\", more, chunk)
    end
  end

  return table.concat(chunks)
end

---@param data string
---@return string
local function encode_iip(data)
  local base64 = vim.fn.system("base64", data):gsub("\n", "")
  return string.format("\027]1337;File=inline=1:%s\027\\", base64)
end

-- ============================================================================
-- Renderer
-- ============================================================================

local last_render_ms = 0

---@param file_path string
---@return number render_time_ms
function image_renderer_adapter.render(file_path)
  local timing_start = timing_utils.start()

  local terminal = get_terminal_info()
  if terminal.protocol == "none" then
    return 0
  end

  local file_handle = io.open(file_path, "rb")
  if not file_handle then
    return 0
  end
  local file_data = file_handle:read("*a")
  file_handle:close()

  -- Get dimensions from PNG header
  local img_width, img_height = 100, 100
  if file_data:sub(1, 4) == "\137PNG" then
    img_width = string.unpack(">I4", file_data:sub(17, 20))
    img_height = string.unpack(">I4", file_data:sub(21, 24))
  end

  -- Scale
  local max_width = 800
  local max_height = 600
  if img_width > max_width then
    img_height = math.floor(img_height * max_width / img_width)
    img_width = max_width
  end
  if img_height > max_height then
    img_width = math.floor(img_width * max_height / img_height)
    img_height = max_height
  end

  local cell_width = math.ceil(img_width / 8)
  local cell_height = math.ceil(img_height / 16)

  local encoded
  if terminal.protocol == "kgp" or terminal.protocol == "kgp_old" then
    encoded = encode_kitty(file_data, cell_width, cell_height)
  elseif terminal.protocol == "iip" then
    encoded = encode_iip(file_data)
  end

  if encoded then
    io.write(encoded)
    io.flush()
  end

  last_render_ms = timing_utils.stop(timing_start)
  return last_render_ms
end

---@return number
function image_renderer_adapter.get_last_render_time()
  return last_render_ms
end

---@return TerminalInfo
function image_renderer_adapter.get_terminal_info()
  return get_terminal_info()
end

return image_renderer_adapter
