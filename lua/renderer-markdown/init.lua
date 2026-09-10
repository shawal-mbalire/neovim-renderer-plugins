---
--- Markdown Renderer Plugin
--- GitHub Flavored Markdown with side-by-side preview
--- Uses built-in Neovim features: extmarks, splits, autocmds
---

local M = {}

-- ============================================================================
-- Configuration (Dataclass pattern)
-- ============================================================================

---@class MarkdownPreviewConfig
---@field enabled boolean
---@field position string
---@field width number
---@field height number
---@field sync_scroll boolean
---@field auto_open boolean

---@class MarkdownConfig
---@field preview MarkdownPreviewConfig
---@field debounce_ms number
---@field show_render_time boolean

---@type MarkdownConfig
M.config = {
  preview = {
    enabled = true,
    position = "right",
    width = 50,
    height = 15,
    sync_scroll = true,
    auto_open = true,
  },
  debounce_ms = 100,
  show_render_time = true,
}

-- ============================================================================
-- State (Module-level state)
-- ============================================================================

---@class MarkdownState
---@field ns number
---@field preview_wins table<number, number>
---@field preview_bufs table<number, number>
---@field timers table<number, any>
---@field last_render_ms number

---@type MarkdownState
local state = {
  ns = vim.api.nvim_create_namespace("renderer_markdown"),
  preview_wins = {},
  preview_bufs = {},
  timers = {},
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
    { group = "RendererHeading1", link = "Title" },
    { group = "RendererHeading2", link = "Title" },
    { group = "RendererHeading3", link = "Identifier" },
    { group = "RendererHeading4", link = "Identifier" },
    { group = "RendererHeading5", link = "Type" },
    { group = "RendererHeading6", link = "Type" },
    { group = "RendererBold", link = "Bold" },
    { group = "RendererItalic", link = "Italic" },
    { group = "RendererStrike", link = "Strike" },
    { group = "RendererCode", link = "Special" },
    { group = "RendererLink", link = "Underlined" },
    { group = "RendererImage", link = "Underlined" },
    { group = "RendererList", link = "Bullet" },
    { group = "RendererTaskDone", link = "Statement" },
    { group = "RendererTaskTodo", link = "Identifier" },
    { group = "RendererTable", link = "Delimiter" },
    { group = "RendererBlockquote", link = "Comment" },
    { group = "RendererAlert", link = "DiagnosticInfo" },
    { group = "RendererMath", link = "Special" },
    { group = "RendererHr", link = "Comment" },
    { group = "RendererRenderTime", link = "Comment" },
  }

  for _, link_info in ipairs(highlight_links) do
    vim.api.nvim_set_hl(0, link_info.group, { link = link_info.link, default = true })
  end
end

-- ============================================================================
-- Parser (Built-in pattern matching)
-- ============================================================================

---@class RenderMark
---@field line number
---@field col number
---@field end_col number
---@field hl string
---@field virt_text? string

---@param line_content string
---@param line_index number
---@return RenderMark[]
local function parse_single_line(line_content, line_index)
  local marks_for_line = {}

  -- Headings
  local heading_prefix = line_content:match("^(#{1,6})%s")
  if heading_prefix then
    local heading_level = #heading_prefix
    table.insert(marks_for_line, {
      line = line_index,
      col = 0,
      end_col = #line_content,
      hl = "RendererHeading" .. heading_level,
    })
  end

  -- Bold
  for bold_text in line_content:gmatch("%*%*([^*]+)%*%*") do
    local start_position = line_content:find("%*%*" .. bold_text .. "%*%*")
    if start_position then
      table.insert(marks_for_line, {
        line = line_index,
        col = start_position - 1,
        end_col = start_position + #bold_text + 3,
        hl = "RendererBold",
      })
    end
  end

  -- Italic (not inside bold)
  for italic_text in line_content:gmatch("[^%*]%*([^*]+)%*[^%*]") do
    local start_position = line_content:find("[^%*]%*" .. italic_text .. "%*[^%*]")
    if start_position then
      table.insert(marks_for_line, {
        line = line_index,
        col = start_position,
        end_col = start_position + #italic_text + 1,
        hl = "RendererItalic",
      })
    end
  end

  -- Inline code
  for code_text in line_content:gmatch("`([^`]+)`") do
    local start_position = line_content:find("`" .. code_text .. "`")
    if start_position then
      table.insert(marks_for_line, {
        line = line_index,
        col = start_position - 1,
        end_col = start_position + #code_text + 1,
        hl = "RendererCode",
      })
    end
  end

  -- Links [text](url)
  for link_text, link_url in line_content:gmatch("%[([^%]]+)%]%(([^)]+)%)") do
    local pattern = "%[" .. link_text .. "%]%(" .. link_url .. "%)"
    local start_position = line_content:find(pattern)
    if start_position then
      table.insert(marks_for_line, {
        line = line_index,
        col = start_position - 1,
        end_col = start_position + #link_text + #link_url + 3,
        hl = "RendererLink",
      })
    end
  end

  -- Images ![alt](src)
  if line_content:match("!%[") then
    for alt_text, img_src in line_content:gmatch("!%[([^%]]+)%]%(([^)]+)%)") do
      local pattern = "!%[" .. alt_text .. "%]%(" .. img_src .. "%)"
      local start_position = line_content:find(pattern)
      if start_position then
        table.insert(marks_for_line, {
          line = line_index,
          col = start_position - 1,
          end_col = start_position + #alt_text + #img_src + 3,
          hl = "RendererImage",
        })
      end
    end
  end

  -- Blockquote
  if line_content:match("^>%s") then
    table.insert(marks_for_line, {
      line = line_index,
      col = 0,
      end_col = 2,
      hl = "RendererBlockquote",
    })
  end

  -- Horizontal rule
  if line_content:match("^%-%-%-%s*$") or line_content:match("^%*%*%*%s*$") then
    local rule_width = vim.o.columns
    table.insert(marks_for_line, {
      line = line_index,
      col = 0,
      end_col = #line_content,
      hl = "RendererHr",
      virt_text = string.rep("─", rule_width),
    })
  end

  -- Task lists
  local task_done_pattern = line_content:match("^%s*[-*+] %[[xX]%]")
  local task_todo_pattern = line_content:match("^%s*[-*+] %[ %]")
  if task_done_pattern then
    table.insert(marks_for_line, {
      line = line_index,
      col = 0,
      end_col = #line_content,
      hl = "RendererTaskDone",
    })
  elseif task_todo_pattern then
    table.insert(marks_for_line, {
      line = line_index,
      col = 0,
      end_col = #line_content,
      hl = "RendererTaskTodo",
    })
  end

  return marks_for_line
end

---@param all_lines string[]
---@return RenderMark[]
local function parse_markdown(all_lines)
  local all_marks = {}

  for line_number, line_content in ipairs(all_lines) do
    local line_index = line_number - 1
    local line_marks = parse_single_line(line_content, line_index)

    for _, mark in ipairs(line_marks) do
      table.insert(all_marks, mark)
    end
  end

  return all_marks
end

-- ============================================================================
-- Renderer
-- ============================================================================

---@param buffer number
---@return number render_time_ms
local function render_buffer(buffer)
  local timing_start = start_timing()

  if not vim.api.nvim_buf_is_valid(buffer) then
    return 0
  end

  local buffer_lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  local render_marks = parse_markdown(buffer_lines)

  vim.api.nvim_buf_clear_namespace(buffer, state.ns, 0, -1)

  for _, mark in ipairs(render_marks) do
    if mark.virt_text then
      vim.api.nvim_buf_set_extmark(buffer, state.ns, mark.line, mark.col, {
        virt_text = { { mark.virt_text, mark.hl } },
        virt_text_pos = "overlay",
      })
    else
      pcall(vim.api.nvim_buf_set_extmark, buffer, state.ns, mark.line, mark.col, {
        end_col = mark.end_col,
        hl_group = mark.hl,
      })
    end
  end

  local render_time = stop_timing(timing_start)
  state.last_render_ms = render_time

  if M.config.show_render_time then
    local status_message = string.format("[markdown] Rendered in %.2f ms", render_time)
    vim.api.nvim_echo({ { status_message, "RendererRenderTime" } }, false, {})
  end

  return render_time
end

-- ============================================================================
-- Preview Window
-- ============================================================================

---@param source_buffer number
function M.open_preview(source_buffer)
  if not M.config.preview.enabled then
    return
  end

  if state.preview_wins[source_buffer] then
    local existing_window = state.preview_wins[source_buffer]
    if vim.api.nvim_win_is_valid(existing_window) then
      return
    end
  end

  local preview_buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[preview_buffer].buftype = "nofile"
  vim.bo[preview_buffer].bufhidden = "wipe"
  vim.bo[preview_buffer].filetype = "markdown"

  state.preview_bufs[source_buffer] = preview_buffer

  local split_command
  if M.config.preview.position == "right" then
    local split_width = math.floor(vim.o.columns * M.config.preview.width / 100)
    split_command = string.format("botright vertical %dvnew", split_width)
  else
    split_command = string.format("botright %dnew", M.config.preview.height)
  end

  vim.cmd(split_command)
  local preview_window = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(preview_window, preview_buffer)

  vim.wo[preview_window].wrap = true
  vim.wo[preview_window].number = false
  vim.wo[preview_window].relativenumber = false
  vim.wo[preview_window].signcolumn = "no"
  vim.wo[preview_window].foldcolumn = "0"
  vim.wo[preview_window].list = false
  vim.wo[preview_window].cursorline = false

  state.preview_wins[source_buffer] = preview_window

  local source_window = vim.fn.winbufwin(source_buffer)
  if source_window > 0 then
    vim.api.nvim_set_current_win(source_window)
  end

  M.update_preview(source_buffer)
end

---@param source_buffer number
function M.close_preview(source_buffer)
  local preview_window = state.preview_wins[source_buffer]
  if preview_window and vim.api.nvim_win_is_valid(preview_window) then
    vim.api.nvim_win_close(preview_window, true)
  end

  state.preview_wins[source_buffer] = nil
  local preview_buffer = state.preview_bufs[source_buffer]
  if preview_buffer then
    state.preview_bufs[source_buffer] = nil
  end
end

---@param source_buffer number
function M.toggle_preview(source_buffer)
  if state.preview_wins[source_buffer] then
    M.close_preview(source_buffer)
  else
    M.open_preview(source_buffer)
  end
end

---@param source_buffer number
function M.update_preview(source_buffer)
  local preview_buffer = state.preview_bufs[source_buffer]
  if not preview_buffer or not vim.api.nvim_buf_is_valid(preview_buffer) then
    return
  end

  local source_lines = vim.api.nvim_buf_get_lines(source_buffer, 0, -1, false)
  vim.api.nvim_buf_set_lines(preview_buffer, 0, -1, false, source_lines)
  render_buffer(preview_buffer)
end

-- ============================================================================
-- Scroll Sync
-- ============================================================================

---@param source_buffer number
local function sync_scroll(source_buffer)
  local preview_window = state.preview_wins[source_buffer]
  if not preview_window or not vim.api.nvim_win_is_valid(preview_window) then
    return
  end

  local source_window = vim.fn.winbufwin(source_buffer)
  if source_window <= 0 then
    return
  end

  local cursor_position = vim.api.nvim_win_get_cursor(source_window)
  local source_line = cursor_position[1]

  local preview_buffer = state.preview_bufs[source_buffer]
  local max_preview_line = vim.api.nvim_buf_line_count(preview_buffer)
  local target_line = math.min(source_line, max_preview_line)

  pcall(vim.api.nvim_win_set_cursor, preview_window, { target_line, 0 })
end

-- ============================================================================
-- Setup
-- ============================================================================

---@param opts? MarkdownConfig
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  setup_highlights()

  local augroup = vim.api.nvim_create_augroup("RendererMarkdown", { clear = true })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    pattern = { "*.md", "*.markdown" },
    callback = function(event)
      if M.config.preview.enabled and M.config.preview.auto_open then
        M.open_preview(event.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = augroup,
    pattern = { "*.md", "*.markdown" },
    callback = function(event)
      if state.timers[event.buf] then
        state.timers[event.buf]:stop()
      end
      state.timers[event.buf] = vim.defer_fn(function()
        render_buffer(event.buf)
        M.update_preview(event.buf)
      end, M.config.debounce_ms)
    end,
  })

  if M.config.preview.sync_scroll then
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = augroup,
      pattern = { "*.md", "*.markdown" },
      callback = function(event)
        sync_scroll(event.buf)
      end,
    })
  end

  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(event)
      M.close_preview(event.buf)
      state.timers[event.buf] = nil
    end,
  })

  vim.api.nvim_create_user_command("MarkdownPreview", function()
    M.open_preview(vim.api.nvim_get_current_buf())
  end, {})

  vim.api.nvim_create_user_command("MarkdownPreviewClose", function()
    M.close_preview(vim.api.nvim_get_current_buf())
  end, {})

  vim.api.nvim_create_user_command("MarkdownPreviewToggle", function()
    M.toggle_preview(vim.api.nvim_get_current_buf())
  end, {})

  local current_buffer = vim.api.nvim_get_current_buf()
  if vim.bo[current_buffer].filetype == "markdown" then
    render_buffer(current_buffer)
  end
end

return M
