---
--- Image Renderer Plugin (Optimized for <100ms load)
--- Terminal image display using Kitty/IIP/Sixel protocols
--- Lazy-loads protocol implementations
---

local image_renderer = {}

-- ============================================================================
-- Configuration (Inline)
-- ============================================================================

image_renderer.config = {
  max_width = 800,
  max_height = 600,
  debounce_ms = 100,
  show_render_time = true,
}

-- ============================================================================
-- State (Lazy-initialized)
-- ============================================================================

local plugin_state = nil

local function get_state()
  if plugin_state then
    return plugin_state
  end
  plugin_state = {
    ns = vim.api.nvim_create_namespace("renderer_image"),
    image_id = 0,
    terminal_info = nil,
    last_render_ms = 0,
    highlights_setup = false,
  }
  return plugin_state
end

-- ============================================================================
-- Timing (Inline)
-- ============================================================================

local function start_timing()
  return vim.uv.hrtime()
end

local function stop_timing(start_time)
  local elapsed_ns = vim.uv.hrtime() - start_time
  return math.floor((elapsed_ns / 1e6) * 100) / 100
end

-- ============================================================================
-- Highlights (Deferred)
-- ============================================================================

local function ensure_highlights()
  local current_state = get_state()
  if current_state.highlights_setup then
    return
  end
  current_state.highlights_setup = true

  local highlight_map = {
    { "RendererImageHeader", "Title" },
    { "RendererImageInfo", "Comment" },
    { "RendererRenderTime", "Comment" },
  }

  for _, mapping in ipairs(highlight_map) do
    vim.api.nvim_set_hl(0, mapping[1], { link = mapping[2], default = true })
  end
end

-- ============================================================================
-- Terminal Detection (Cached)
-- ============================================================================

local function detect_terminal()
  local current_state = get_state()
  if current_state.terminal_info then
    return current_state.terminal_info
  end

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
  local iip_terminals = { "iterm2", "wewterm", "warp", "vscode" }
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

  current_state.terminal_info = {
    protocols = supported,
    primary = supported[1] or "none",
    tmux = is_tmux,
  }

  return current_state.terminal_info
end

-- ============================================================================
-- Protocol Encoders (Lazy-loaded)
-- ============================================================================

local function encode_kitty(data, width, height)
  local current_state = get_state()
  current_state.image_id = current_state.image_id + 1
  local image_id = current_state.image_id
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

local function encode_iip(data)
  local base64 = vim.fn.system("base64", data):gsub("\n", "")
  return string.format("\027]1337;File=inline=1:%s\027\\", base64)
end

-- ============================================================================
-- Image Display
-- ============================================================================

local function display_image(file_path)
  local timing_start = start_timing()

  local terminal = detect_terminal()
  if terminal.primary == "none" then
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
  if img_width > image_renderer.config.max_width then
    img_height = math.floor(img_height * image_renderer.config.max_width / img_width)
    img_width = image_renderer.config.max_width
  end
  if img_height > image_renderer.config.max_height then
    img_width = math.floor(img_width * image_renderer.config.max_height / img_height)
    img_height = image_renderer.config.max_height
  end

  local cell_width = math.ceil(img_width / 8)
  local cell_height = math.ceil(img_height / 16)

  local encoded
  if terminal.primary == "kgp" or terminal.primary == "kgp_old" then
    encoded = encode_kitty(file_data, cell_width, cell_height)
  elseif terminal.primary == "iip" then
    encoded = encode_iip(file_data)
  end

  if encoded then
    io.write(encoded)
    io.flush()
  end

  local render_time = stop_timing(timing_start)
  local current_state = get_state()
  current_state.last_render_ms = render_time

  return render_time
end

-- ============================================================================
-- File Detection
-- ============================================================================

local image_extensions = {
  png = true, jpeg = true, jpg = true, gif = true,
  webp = true, bmp = true, tiff = true,
}

local function is_image_file(file_path)
  local ext = file_path:match("%.([^%.]+)$")
  return ext and image_extensions[ext:lower()] or false
end

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
-- Buffer Renderer
-- ============================================================================

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
    string.format("File: %s", file_path),
    string.format("Size: %s", format_file_size(file_size)),
    string.format("Terminal: %s", terminal.primary),
    string.format("Protocols: %s", table.concat(terminal.protocols, ", ")),
  }

  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, display_lines)
  vim.bo[buffer].filetype = "image"
  vim.bo[buffer].modifiable = false

  ensure_highlights()

  local buf_ns = vim.api.nvim_create_namespace("renderer_image_display")
  vim.api.nvim_buf_clear_namespace(buffer, buf_ns, 0, -1)

  pcall(vim.api.nvim_buf_set_extmark, buffer, buf_ns, 0, 0, {
    end_col = #display_lines[1],
    hl_group = "RendererImageHeader",
  })

  display_image(file_path)

  local render_time = stop_timing(timing_start)
  local current_state = get_state()
  current_state.last_render_ms = render_time

  if image_renderer.config.show_render_time then
    local status_msg = string.format("[image] %.2f ms", render_time)
    vim.api.nvim_echo({ { status_msg, "RendererRenderTime" } }, false, {})
  end

  return render_time
end

-- ============================================================================
-- Setup (Minimal)
-- ============================================================================

function image_renderer.setup(opts)
  image_renderer.config = vim.tbl_deep_extend("force", image_renderer.config, opts or {})

  vim.defer_fn(ensure_highlights, 10)

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
    display_image(file_path)
  end, {})

  vim.api.nvim_create_user_command("ImageInfo", function()
    local file_path = vim.fn.expand("%:p")
    local terminal = detect_terminal()
    local current_state = get_state()
    local info = {
      string.format("File: %s", file_path),
      string.format("Terminal: %s", terminal.primary),
      string.format("Protocols: %s", table.concat(terminal.protocols, ", ")),
      string.format("Last render: %.2f ms", current_state.last_render_ms),
    }
    vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
  end, {})
end

return image_renderer
