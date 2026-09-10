---
--- Markdown Renderer Plugin (Optimized for <100ms load)
--- GitHub Flavored Markdown with side-by-side preview
--- Lazy-loads components for fast startup
---

local markdown_renderer = {}

-- ============================================================================
-- Configuration (Inline to avoid module load)
-- ============================================================================

markdown_renderer.config = {
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
-- State (Lazy-initialized)
-- ============================================================================

local plugin_state = nil

local function get_state()
  if plugin_state then
    return plugin_state
  end
  plugin_state = {
    ns = vim.api.nvim_create_namespace("renderer_markdown"),
    preview_wins = {},
    preview_bufs = {},
    timers = {},
    last_render_ms = 0,
    highlights_setup = false,
  }
  return plugin_state
end

-- ============================================================================
-- Timing (Inline for zero overhead)
-- ============================================================================

local function start_timing()
  return vim.uv.hrtime()
end

local function stop_timing(start_time)
  local elapsed_ns = vim.uv.hrtime() - start_time
  return math.floor((elapsed_ns / 1e6) * 100) / 100
end

-- ============================================================================
-- Highlights (Deferred - only setup when needed)
-- ============================================================================

local function ensure_highlights()
  local current_state = get_state()
  if current_state.highlights_setup then
    return
  end
  current_state.highlights_setup = true

  local highlight_map = {
    { "RendererHeading1", "Title" },
    { "RendererHeading2", "Title" },
    { "RendererHeading3", "Identifier" },
    { "RendererHeading4", "Identifier" },
    { "RendererHeading5", "Type" },
    { "RendererHeading6", "Type" },
    { "RendererBold", "Bold" },
    { "RendererItalic", "Italic" },
    { "RendererStrike", "Strike" },
    { "RendererCode", "Special" },
    { "RendererLink", "Underlined" },
    { "RendererImage", "Underlined" },
    { "RendererList", "Bullet" },
    { "RendererTaskDone", "Statement" },
    { "RendererTaskTodo", "Identifier" },
    { "RendererTable", "Delimiter" },
    { "RendererBlockquote", "Comment" },
    { "RendererAlert", "DiagnosticInfo" },
    { "RendererMath", "Special" },
    { "RendererHr", "Comment" },
    { "RendererRenderTime", "Comment" },
  }

  for _, mapping in ipairs(highlight_map) do
    vim.api.nvim_set_hl(0, mapping[1], { link = mapping[2], default = true })
  end
end

-- ============================================================================
-- Parser (Optimized - single pass)
-- ============================================================================

local function parse_single_line(line_content, line_index)
  local marks_for_line = {}

  -- Headings (check first - most common)
  local heading_prefix = line_content:match("^(#{1,6})%s")
  if heading_prefix then
    marks_for_line[1] = {
      line = line_index,
      col = 0,
      end_col = #line_content,
      hl = "RendererHeading" .. #heading_prefix,
    }
    return marks_for_line
  end

  -- Horizontal rule (check early)
  if line_content:match("^%-%-%-%s*$") or line_content:match("^%*%*%*%s*$") then
    marks_for_line[1] = {
      line = line_index,
      col = 0,
      end_col = #line_content,
      hl = "RendererHr",
      virt_text = string.rep("─", vim.o.columns),
    }
    return marks_for_line
  end

  -- Task lists (check before general list)
  if line_content:match("^%s*[-*+] %[[xX]%]") then
    marks_for_line[1] = {
      line = line_index,
      col = 0,
      end_col = #line_content,
      hl = "RendererTaskDone",
    }
    return marks_for_line
  end
  if line_content:match("^%s*[-*+] %[ %]") then
    marks_for_line[1] = {
      line = line_index,
      col = 0,
      end_col = #line_content,
      hl = "RendererTaskTodo",
    }
    return marks_for_line
  end

  -- Blockquote
  if line_content:match("^>%s") then
    marks_for_line[1] = {
      line = line_index,
      col = 0,
      end_col = 2,
      hl = "RendererBlockquote",
    }
    return marks_for_line
  end

  -- Inline formatting (only if line has special chars)
  if not line_content:find("[*`[!") then
    return marks_for_line
  end

  local mark_index = 1

  -- Bold
  for bold_text in line_content:gmatch("%*%*([^*]+)%*%*") do
    local start_pos = line_content:find("%*%*" .. bold_text .. "%*%*", 1, true)
    if start_pos then
      marks_for_line[mark_index] = {
        line = line_index,
        col = start_pos - 1,
        end_col = start_pos + #bold_text + 3,
        hl = "RendererBold",
      }
      mark_index = mark_index + 1
    end
  end

  -- Inline code
  for code_text in line_content:gmatch("`([^`]+)`") do
    local start_pos = line_content:find("`" .. code_text .. "`", 1, true)
    if start_pos then
      marks_for_line[mark_index] = {
        line = line_index,
        col = start_pos - 1,
        end_col = start_pos + #code_text + 1,
        hl = "RendererCode",
      }
      mark_index = mark_index + 1
    end
  end

  return marks_for_line
end

local function parse_markdown(all_lines)
  local all_marks = {}
  local mark_count = 0

  for line_number, line_content in ipairs(all_lines) do
    local line_index = line_number - 1
    local line_marks = parse_single_line(line_content, line_index)

    for _, mark in ipairs(line_marks) do
      mark_count = mark_count + 1
      all_marks[mark_count] = mark
    end
  end

  return all_marks
end

-- ============================================================================
-- Renderer (Optimized)
-- ============================================================================

local function render_buffer(buffer)
  local timing_start = start_timing()

  if not vim.api.nvim_buf_is_valid(buffer) then
    return 0
  end

  local buffer_lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  local render_marks = parse_markdown(buffer_lines)

  local current_state = get_state()
  vim.api.nvim_buf_clear_namespace(buffer, current_state.ns, 0, -1)

  for _, mark in ipairs(render_marks) do
    if mark.virt_text then
      vim.api.nvim_buf_set_extmark(buffer, current_state.ns, mark.line, mark.col, {
        virt_text = { { mark.virt_text, mark.hl } },
        virt_text_pos = "overlay",
      })
    else
      pcall(vim.api.nvim_buf_set_extmark, buffer, current_state.ns, mark.line, mark.col, {
        end_col = mark.end_col,
        hl_group = mark.hl,
      })
    end
  end

  local render_time = stop_timing(timing_start)
  current_state.last_render_ms = render_time

  if markdown_renderer.config.show_render_time then
    local status_msg = string.format("[markdown] %.2f ms", render_time)
    vim.api.nvim_echo({ { status_msg, "RendererRenderTime" } }, false, {})
  end

  return render_time
end

-- ============================================================================
-- Preview Window (Lazy-loaded)
-- ============================================================================

function markdown_renderer.open_preview(source_buffer)
  if not markdown_renderer.config.preview.enabled then
    return
  end

  local current_state = get_state()

  if current_state.preview_wins[source_buffer] then
    local existing_window = current_state.preview_wins[source_buffer]
    if vim.api.nvim_win_is_valid(existing_window) then
      return
    end
  end

  local preview_buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[preview_buffer].buftype = "nofile"
  vim.bo[preview_buffer].bufhidden = "wipe"
  vim.bo[preview_buffer].filetype = "markdown"

  current_state.preview_bufs[source_buffer] = preview_buffer

  local split_cmd
  if markdown_renderer.config.preview.position == "right" then
    local split_width = math.floor(vim.o.columns * markdown_renderer.config.preview.width / 100)
    split_cmd = string.format("botright vertical %dvnew", split_width)
  else
    split_cmd = string.format("botright %dnew", markdown_renderer.config.preview.height)
  end

  vim.cmd(split_cmd)
  local preview_window = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(preview_window, preview_buffer)

  vim.wo[preview_window].wrap = true
  vim.wo[preview_window].number = false
  vim.wo[preview_window].relativenumber = false
  vim.wo[preview_window].signcolumn = "no"

  current_state.preview_wins[source_buffer] = preview_window

  local source_window = vim.fn.winbufwin(source_buffer)
  if source_window > 0 then
    vim.api.nvim_set_current_win(source_window)
  end

  markdown_renderer.update_preview(source_buffer)
end

function markdown_renderer.close_preview(source_buffer)
  local current_state = get_state()
  local preview_window = current_state.preview_wins[source_buffer]
  if preview_window and vim.api.nvim_win_is_valid(preview_window) then
    vim.api.nvim_win_close(preview_window, true)
  end
  current_state.preview_wins[source_buffer] = nil
  current_state.preview_bufs[source_buffer] = nil
end

function markdown_renderer.toggle_preview(source_buffer)
  local current_state = get_state()
  if current_state.preview_wins[source_buffer] then
    markdown_renderer.close_preview(source_buffer)
  else
    markdown_renderer.open_preview(source_buffer)
  end
end

function markdown_renderer.update_preview(source_buffer)
  local current_state = get_state()
  local preview_buffer = current_state.preview_bufs[source_buffer]
  if not preview_buffer or not vim.api.nvim_buf_is_valid(preview_buffer) then
    return
  end
  local source_lines = vim.api.nvim_buf_get_lines(source_buffer, 0, -1, false)
  vim.api.nvim_buf_set_lines(preview_buffer, 0, -1, false, source_lines)
  render_buffer(preview_buffer)
end

-- ============================================================================
-- Setup (Minimal - defers heavy work)
-- ============================================================================

function markdown_renderer.setup(opts)
  markdown_renderer.config = vim.tbl_deep_extend("force", markdown_renderer.config, opts or {})

  -- Defer highlight setup
  vim.defer_fn(ensure_highlights, 10)

  local augroup = vim.api.nvim_create_augroup("RendererMarkdown", { clear = true })

  -- Only create autocmds for markdown files
  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    pattern = { "*.md", "*.markdown" },
    callback = function(event)
      ensure_highlights()
      if markdown_renderer.config.preview.enabled and markdown_renderer.config.preview.auto_open then
        vim.defer_fn(function()
          markdown_renderer.open_preview(event.buf)
        end, 50)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = augroup,
    pattern = { "*.md", "*.markdown" },
    callback = function(event)
      local current_state = get_state()
      if current_state.timers[event.buf] then
        current_state.timers[event.buf]:stop()
      end
      current_state.timers[event.buf] = vim.defer_fn(function()
        render_buffer(event.buf)
        markdown_renderer.update_preview(event.buf)
      end, markdown_renderer.config.debounce_ms)
    end,
  })

  if markdown_renderer.config.preview.sync_scroll then
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = augroup,
      pattern = { "*.md", "*.markdown" },
      callback = function(event)
        local current_state = get_state()
        local preview_window = current_state.preview_wins[event.buf]
        if not preview_window or not vim.api.nvim_win_is_valid(preview_window) then
          return
        end
        local source_window = vim.fn.winbufwin(event.buf)
        if source_window <= 0 then
          return
        end
        local cursor_pos = vim.api.nvim_win_get_cursor(source_window)
        local preview_buffer = current_state.preview_bufs[event.buf]
        local max_line = vim.api.nvim_buf_line_count(preview_buffer)
        pcall(vim.api.nvim_win_set_cursor, preview_window, { math.min(cursor_pos[1], max_line), 0 })
      end,
    })
  end

  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(event)
      markdown_renderer.close_preview(event.buf)
      local current_state = get_state()
      current_state.timers[event.buf] = nil
    end,
  })

  -- Commands (register immediately - lightweight)
  vim.api.nvim_create_user_command("MarkdownPreview", function()
    markdown_renderer.open_preview(vim.api.nvim_get_current_buf())
  end, {})

  vim.api.nvim_create_user_command("MarkdownPreviewClose", function()
    markdown_renderer.close_preview(vim.api.nvim_get_current_buf())
  end, {})

  vim.api.nvim_create_user_command("MarkdownPreviewToggle", function()
    markdown_renderer.toggle_preview(vim.api.nvim_get_current_buf())
  end, {})
end

return markdown_renderer
