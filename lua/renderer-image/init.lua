---
--- Image Renderer Plugin
--- Terminal image display using Kitty/IIP/Sixel protocols
--- Shows render timing and image info
---

local M = {}

-- ============================================================================
-- Configuration
-- ============================================================================

---@class ImageConfig
---@field max_width number
---@field max_height number
---@field debounce_ms number
---@field show_render_time boolean

---@type ImageConfig
M.config = {
  max_width = 800,
  max_height = 600,
  debounce_ms = 100,
  show_render_time = true,
}

-- ============================================================================
-- State
-- ============================================================================

---@class ImageState
---@field ns number
---@field image_id number
---@field terminal_info? table
---@field last_render_ms number

---@type ImageState
local state = {
  ns = vim.api.nvim_create_namespace("renderer_image"),
  image_id = 0,
  terminal_info = nil,
  last_render_ms = 0,
}

-- ============================================================================
-- Timing Helper
-- ============================================================================

---@return number start_time
local function start_timing()
  return vim.uv.hrtime()
end

---@param start_time number
---@return number elapsed_ms
local function stop_timing(start_time)
  local elapsed_nanoseconds = vim.uv.hrtime() - start_time
  local elapsed_milliseconds = elapsed_nanoseconds / 1e6
  return math.floor(elapsed_milliseconds * 100) / 100
end

-- ============================================================================
-- Highlight Groups
-- ============================================================================

local function setup_highlights()
  local highlight_links = {
    { group = "RendererImageHeader", link = "Title" },
    { group = "RendererImageInfo", link = "Comment" },
    { group = "RendererRenderTime", link = "Comment" },
  }

  for _, link_info in ipairs(highlight_links) do
    vim.api.nvim_set_hl(0, link_info.group, { link = link_info.link, default = true })
  end
end

-- ============================================================================
-- Terminal Detection
-- ============================================================================

---@class TerminalDetectionResult
---@field protocols string[]
---@field primary string
---@field tmux boolean

---@return TerminalDetectionResult
local function detect_terminal()
  local term_value = os.getenv("TERM") or ""
  local term_program = os.getenv("TERM_PROGRAM") or ""
  local is_tmux = os.getenv("TMUX") ~= nil

  local supported_protocols = {}

  -- Kitty Graphics Protocol
  if term_program:lower():find("kitty") or term_value:lower():find("kitty") then
    if not is_tmux then
      table.insert(supported_protocols, "kgp")
    end
    table.insert(supported_protocols, "kgp_old")
  end

  -- Inline Images Protocol (iTerm2, WezTerm, etc.)
  local iip_terminals = { "iterm2", "WezTerm", "Warp", "VSCode" }
  for _, terminal_name in ipairs(iip_terminals) do
    if term_program:lower():find(terminal_name:lower()) then
      table.insert(supported_protocols, "iip")
      break
    end
  end

  if os.getenv("VSCODE_INJECTION") == "1" then
    table.insert(supported_protocols, "iip")
  end

  -- Sixel
  if term_value:find("sixel") or term_program:lower():find("foot") then
    table.insert(supported_protocols, "sixel")
  end

  return {
    protocols = supported_protocols,
    primary = supported_protocols[1] or "none",
    tmux = is_tmux,
  }
end

-- ============================================================================
-- Image Protocol Implementations
-- ============================================================================

---@param data string
---@param width number
---@param height number
---@return string
local function encode_kitty_graphics_protocol(data, width, height)
  state.image_id = state.image_id + 1
  local image_identifier = state.image_id
  local base64_data = vim.fn.system("base64", data):gsub("\n", "")

  local control_data = string.format("a=T,f=100,i=%d,t=d", image_identifier)
  if width then
    control_data = control_data .. ",c=" .. width
  end
  if height then
    control_data = control_data .. ",r=" .. height
  end

  local chunk_size = 4096
  local encoded_chunks = {}

  for chunk_start = 1, #base64_data, chunk_size do
    local chunk_end = math.min(chunk_start + chunk_size - 1, #base64_data)
    local chunk = base64_data:sub(chunk_start, chunk_end)
    local is_last_chunk = chunk_end >= #base64_data
    local more_data_flag = is_last_chunk and 0 or 1

    if chunk_start == 1 then
      table.insert(encoded_chunks, string.format(
        "\027_%s,m=%d;%s\027\\",
        control_data, more_data_flag, chunk
      ))
    else
      table.insert(encoded_chunks, string.format(
        "\027_Gm=%d;%s\027\\",
        more_data_flag, chunk
      ))
    end
  end

  return table.concat(encoded_chunks)
end

---@param data string
---@return string
local function encode_inline_images_protocol(data)
  local base64_data = vim.fn.system("base64", data):gsub("\n", "")
  return string.format("\027]1337;File=inline=1:%s\027\\", base64_data)
end

-- ============================================================================
-- Image Display
-- ============================================================================

---@param buffer number
---@param file_path string
---@return number render_time_ms
local function display_image(buffer, file_path)
  local timing_start = start_timing()

  local terminal = detect_terminal()
  if terminal.primary == "none" then
    vim.notify("[image] Terminal does not support image display", vim.log.levels.WARN)
    return 0
  end

  local file_handle = io.open(file_path, "rb")
  if not file_handle then
    vim.notify("[image] Cannot read file: " .. file_path, vim.log.levels.ERROR)
    return 0
  end
  local file_data = file_handle:read("*a")
  file_handle:close()

  -- Get image dimensions from PNG header
  local image_width, image_height = 100, 100
  if file_data:sub(1, 4) == "\137PNG" then
    image_width = string.unpack(">I4", file_data:sub(17, 20))
    image_height = string.unpack(">I4", file_data:sub(21, 24))
  end

  -- Scale if needed
  if image_width > M.config.max_width then
    image_height = math.floor(image_height * M.config.max_width / image_width)
    image_width = M.config.max_width
  end
  if image_height > M.config.max_height then
    image_width = math.floor(image_width * M.config.max_height / image_height)
    image_height = M.config.max_height
  end

  -- Convert to cell dimensions (approximate)
  local cell_width = math.ceil(image_width / 8)
  local cell_height = math.ceil(image_height / 16)

  -- Display using appropriate protocol
  local encoded_data
  if terminal.primary == "kgp" or terminal.primary == "kgp_old" then
    encoded_data = encode_kitty_graphics_protocol(file_data, cell_width, cell_height)
  elseif terminal.primary == "iip" then
    encoded_data = encode_inline_images_protocol(file_data)
  end

  if encoded_data then
    io.write(encoded_data)
    io.flush()
  end

  local render_time = stop_timing(timing_start)
  state.last_render_ms = render_time

  return render_time
end

-- ============================================================================
-- File Type Detection
-- ============================================================================

local image_extensions = {
  png = true,
  jpeg = true,
  jpg = true,
  gif = true,
  webp = true,
  bmp = true,
  tiff = true,
}

---@param file_path string
---@return boolean
local function is_image_file(file_path)
  local extension = file_path:match("%.([^%.]+)$")
  return extension and image_extensions[extension:lower()] or false
end

-- ============================================================================
-- Buffer Renderer
-- ============================================================================

---@param buffer number
---@return number render_time_ms
local function render_image_buffer(buffer)
  local timing_start = start_timing()

  if not vim.api.nvim_buf_is_valid(buffer) then
    return 0
  end

  local file_path = vim.api.nvim_buf_get_name(buffer)
  if not file_path or not is_image_file(file_path) then
    return 0
  end

  local file_size = vim.fn.getfsize(file_path)
  local file_name = vim.fn.fnamemodify(file_path, ":t")
  local terminal = detect_terminal()

  local display_lines = {
    string.format("=== Image: %s ===", file_name),
    "",
    "Terminal image display available with:",
    "  - Kitty Graphics Protocol",
    "  - iTerm2 Inline Images",
    "  - Sixel",
    "",
    string.format("File: %s", file_path),
    string.format("Size: %s", format_file_size(file_size)),
    string.format("Terminal: %s (%s)", terminal.primary, table.concat(terminal.protocols, ", ")),
  }

  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, display_lines)
  vim.bo[buffer].filetype = "image"
  vim.bo[buffer].modifiable = false

  -- Apply highlights
  local buffer_namespace = vim.api.nvim_create_namespace("renderer_image_display")
  vim.api.nvim_buf_clear_namespace(buffer, buffer_namespace, 0, -1)

  pcall(vim.api.nvim_buf_set_extmark, buffer, buffer_namespace, 0, 0, {
    end_col = #display_lines[1],
    hl_group = "RendererImageHeader",
  })

  local render_time = display_image(buffer, file_path)
  state.last_render_ms = render_time

  if M.config.show_render_time then
    local status_message = string.format("[image] Rendered in %.2f ms", render_time)
    vim.api.nvim_echo({ { status_message, "RendererRenderTime" } }, false, {})
  end

  return render_time
end

---@param size_bytes number
---@return string formatted_size
local function format_file_size(size_bytes)
  if size_bytes < 1024 then
    return string.format("%d B", size_bytes)
  elseif size_bytes < 1024 * 1024 then
    return string.format("%.1f KB", size_bytes / 1024)
  else
    return string.format("%.1f MB", size_bytes / (1024 * 1024))
  end
end

-- ============================================================================
-- Setup
-- ============================================================================

---@param opts? ImageConfig
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  setup_highlights()

  local augroup = vim.api.nvim_create_augroup("RendererImage", { clear = true })

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.bmp", "*.tiff" },
    callback = function(event)
      render_image_buffer(event.buf)
    end,
  })

  vim.api.nvim_create_user_command("ImageShow", function()
    local file_path = vim.fn.expand("%:p")
    display_image(vim.api.nvim_get_current_buf(), file_path)
  end, {})

  vim.api.nvim_create_user_command("ImageInfo", function()
    local file_path = vim.fn.expand("%:p")
    local terminal = detect_terminal()
    local info_lines = {
      string.format("File: %s", file_path),
      string.format("Terminal: %s", terminal.primary),
      string.format("Protocols: %s", table.concat(terminal.protocols, ", ")),
      string.format("TMUX: %s", tostring(terminal.tmux)),
      string.format("Last render: %.2f ms", state.last_render_ms),
    }
    vim.notify(table.concat(info_lines, "\n"), vim.log.levels.INFO)
  end, {})

  local current_buffer = vim.api.nvim_get_current_buf()
  local buffer_name = vim.api.nvim_buf_get_name(current_buffer)
  if buffer_name and is_image_file(buffer_name) then
    render_image_buffer(current_buffer)
  end
end

return M
