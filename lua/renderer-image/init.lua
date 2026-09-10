---
--- Image Renderer Plugin
--- Terminal image display using Kitty/IIP/Sixel protocols
--- Auto-detects terminal and uses best available protocol
---

local M = {}

-- ============================================================================
-- Configuration
-- ============================================================================

M.config = {
  max_width = 800,
  max_height = 600,
  debounce_ms = 100,
}

-- ============================================================================
-- State
-- ============================================================================

local state = {
  ns = vim.api.nvim_create_namespace("renderer_image"),
  image_id = 0,
  supported = nil,
}

-- ============================================================================
-- Terminal Detection
-- ============================================================================

local function detect_terminal()
  local term = os.getenv("TERM") or ""
  local term_program = os.getenv("TERM_PROGRAM") or ""
  local tmux = os.getenv("TMUX") ~= nil

  local protocols = {}

  -- Kitty
  if term_program:lower():find("kitty") or term:lower():find("kitty") then
    if not tmux then
      table.insert(protocols, "kgp")
    end
    table.insert(protocols, "kgp_old")
  end

  -- IIP (iTerm2, WezTerm, etc.)
  if term_program:lower():find("iterm2")
    or os.getenv("TERM_PROGRAM") == "WezTerm"
    or os.getenv("TERM_PROGRAM") == "Warp"
    or os.getenv("VSCODE_INJECTION") == "1" then
    table.insert(protocols, "iip")
  end

  -- Sixel
  if term:find("sixel") or term_program:lower():find("foot") then
    table.insert(protocols, "sixel")
  end

  return {
    protocols = protocols,
    primary = protocols[1] or "none",
    tmux = tmux,
  }
end

-- ============================================================================
-- Image Protocol Implementations
-- ============================================================================

local protocols = {}

-- Kitty Graphics Protocol
function protocols.kgp(data, width, height, col, row)
  state.image_id = state.image_id + 1
  local id = state.image_id
  local base64 = vim.fn.system("base64", data):gsub("\n", "")

  local control = string.format("a=T,f=100,i=%d,t=d", id)
  if width then
    control = control .. ",c=" .. width
  end
  if height then
    control = control .. ",r=" .. height
  end

  -- Chunk if needed
  local chunks = {}
  local chunk_size = 4096
  for i = 1, #base64, chunk_size do
    local chunk = base64:sub(i, i + chunk_size - 1)
    local is_last = (i + chunk_size - 1) >= #base64
    if i == 1 then
      local m = is_last and 0 or 1
      table.insert(chunks, string.format("\027_%s,m=%d;%s\027\\", control, m, chunk))
    else
      local m = is_last and 0 or 1
      table.insert(chunks, string.format("\027_Gm=%d;%s\027\\", m, chunk))
    end
  end

  return table.concat(chunks)
end

-- iTerm2 Inline Images Protocol
function protocols.iip(data, width, height, col, row)
  local base64 = vim.fn.system("base64", data):gsub("\n", "")
  local cmd = string.format("\027]1337;File=inline=1:%s\027\\", base64)
  return cmd
end

-- ============================================================================
-- Image Display
-- ============================================================================

local function display_image(buf, path, line)
  local term = detect_terminal()
  if term.primary == "none" then
    vim.notify("[image] Terminal does not support image display", vim.log.levels.WARN)
    return
  end

  -- Read image file
  local f = io.open(path, "rb")
  if not f then
    vim.notify("[image] Cannot read file: " .. path, vim.log.levels.ERROR)
    return
  end
  local data = f:read("*a")
  f:close()

  -- Get image dimensions (simple header parsing)
  local width, height = 100, 100
  if data:sub(1, 4) == "\137PNG" then
    -- PNG header
    width = string.unpack(">I4", data:sub(17, 20))
    height = string.unpack(">I4", data:sub(21, 24))
  end

  -- Scale if needed
  if width > M.config.max_width then
    height = math.floor(height * M.config.max_width / width)
    width = M.config.max_width
  end
  if height > M.config.max_height then
    width = math.floor(width * M.config.max_height / height)
    height = M.config.max_height
  end

  -- Convert to cells (approximate)
  local cell_width = math.ceil(width / 8)
  local cell_height = math.ceil(height / 16)

  -- Display using protocol
  local renderer = protocols[term.primary]
  if renderer then
    local cmd = renderer(data, cell_width, cell_height, 0, line)
    -- Write directly to stdout
    io.write(cmd)
    io.flush()
  end
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

local function is_image_file(path)
  local ext = path:match("%.([^%.]+)$")
  return ext and image_extensions[ext:lower()]
end

-- ============================================================================
-- Buffer Renderer
-- ============================================================================

local function render_image_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local path = vim.api.nvim_buf_get_name(buf)
  if not path or not is_image_file(path) then
    return
  end

  -- Show placeholder text
  local lines = {
    string.format("=== Image: %s ===", vim.fn.fnamemodify(path, ":t")),
    "",
    "Terminal image display available with:",
    "  - Kitty Graphics Protocol",
    "  - iTerm2 Inline Images",
    "  - Sixel",
    "",
    string.format("File: %s", path),
    string.format("Size: %d bytes", vim.fn.getfsize(path)),
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "image"
  vim.bo[buf].modifiable = false

  -- Try to display actual image
  display_image(buf, path, 0)
end

-- ============================================================================
-- Setup
-- ============================================================================

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local augroup = vim.api.nvim_create_augroup("RendererImage", { clear = true })

  -- Render on open
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.bmp", "*.tiff" },
    callback = function(ev)
      render_image_buffer(ev.buf)
    end,
  })

  -- Commands
  vim.api.nvim_create_user_command("ImageShow", function()
    local path = vim.fn.expand("%:p")
    display_image(vim.api.nvim_get_current_buf(), path, 0)
  end, {})
  vim.api.nvim_create_user_command("ImageInfo", function()
    local path = vim.fn.expand("%:p")
    local term = detect_terminal()
    local info = {
      string.format("File: %s", path),
      string.format("Terminal: %s", term.primary),
      string.format("Protocols: %s", table.concat(term.protocols, ", ")),
      string.format("TMUX: %s", tostring(term.tmux)),
    }
    vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
  end, {})

  -- Initial render
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  if path and is_image_file(path) then
    render_image_buffer(buf)
  end
end

return M
