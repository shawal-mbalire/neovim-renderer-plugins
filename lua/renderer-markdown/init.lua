---
--- Markdown Renderer Plugin
--- Nested Hexagonal Architecture
--- Entry point - Composition Root
---

local timing_utils = require("shared.utils.timing")
local markdown_parser = require("renderer-markdown.adapters.parser")
local markdown_renderer_adapter = require("renderer-markdown.adapters.renderer")

local markdown_plugin = {}

-- ============================================================================
-- Configuration
-- ============================================================================

markdown_plugin.config = {
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
-- State
-- ============================================================================

local plugin_state = nil

local function get_state()
  if plugin_state then
    return plugin_state
  end
  plugin_state = {
    preview_wins = {},
    preview_bufs = {},
    timers = {},
    last_render_ms = 0,
  }
  return plugin_state
end

-- ============================================================================
-- Render
-- ============================================================================

local function render_buffer(buffer)
  local timing_start = timing_utils.start()

  if not vim.api.nvim_buf_is_valid(buffer) then
    return 0
  end

  local render_time = markdown_renderer_adapter.render(buffer)

  local current_state = get_state()
  current_state.last_render_ms = render_time

  if markdown_plugin.config.show_render_time then
    local status_msg = string.format("[markdown] %.2f ms", render_time)
    vim.api.nvim_echo({ { status_msg, "Comment" } }, false, {})
  end

  return render_time
end

-- ============================================================================
-- Preview Window
-- ============================================================================

function markdown_plugin.open_preview(source_buffer)
  if not markdown_plugin.config.preview.enabled then
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
  if markdown_plugin.config.preview.position == "right" then
    local split_width = math.floor(vim.o.columns * markdown_plugin.config.preview.width / 100)
    split_cmd = string.format("botright vertical %dvnew", split_width)
  else
    split_cmd = string.format("botright %dnew", markdown_plugin.config.preview.height)
  end

  vim.cmd(split_cmd)
  local preview_window = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(preview_window, preview_buffer)

  vim.wo[preview_window].wrap = true
  vim.wo[preview_window].number = false
  vim.wo[preview_window].relativenumber = false
  vim.wo[preview_window].signcolumn = "no"

  current_state.preview_wins[source_buffer] = preview_window

  local success, source_window = pcall(vim.fn.winbufwin, source_buffer)
  if success and source_window > 0 then
    vim.api.nvim_set_current_win(source_window)
  end

  markdown_plugin.update_preview(source_buffer)
end

function markdown_plugin.close_preview(source_buffer)
  local current_state = get_state()
  local preview_window = current_state.preview_wins[source_buffer]
  if preview_window and vim.api.nvim_win_is_valid(preview_window) then
    vim.api.nvim_win_close(preview_window, true)
  end
  current_state.preview_wins[source_buffer] = nil
  current_state.preview_bufs[source_buffer] = nil
end

function markdown_plugin.toggle_preview(source_buffer)
  local current_state = get_state()
  if current_state.preview_wins[source_buffer] then
    markdown_plugin.close_preview(source_buffer)
  else
    markdown_plugin.open_preview(source_buffer)
  end
end

function markdown_plugin.update_preview(source_buffer)
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
-- Setup
-- ============================================================================

function markdown_plugin.setup(opts)
  markdown_plugin.config = vim.tbl_deep_extend("force", markdown_plugin.config, opts or {})

  local augroup = vim.api.nvim_create_augroup("RendererMarkdown", { clear = true })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    pattern = { "*.md", "*.markdown" },
    callback = function(event)
      if markdown_plugin.config.preview.enabled and markdown_plugin.config.preview.auto_open then
        vim.defer_fn(function()
          markdown_plugin.open_preview(event.buf)
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
        markdown_plugin.update_preview(event.buf)
      end, markdown_plugin.config.debounce_ms)
    end,
  })

  if markdown_plugin.config.preview.sync_scroll then
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = augroup,
      pattern = { "*.md", "*.markdown" },
      callback = function(event)
        local current_state = get_state()
        local preview_window = current_state.preview_wins[event.buf]
        if not preview_window or not vim.api.nvim_win_is_valid(preview_window) then
          return
        end
        local success, source_window = pcall(vim.fn.winbufwin, event.buf)
        if not success or source_window <= 0 then
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
      markdown_plugin.close_preview(event.buf)
      local current_state = get_state()
      current_state.timers[event.buf] = nil
    end,
  })

  vim.api.nvim_create_user_command("MarkdownPreview", function()
    markdown_plugin.open_preview(vim.api.nvim_get_current_buf())
  end, {})

  vim.api.nvim_create_user_command("MarkdownPreviewClose", function()
    markdown_plugin.close_preview(vim.api.nvim_get_current_buf())
  end, {})

  vim.api.nvim_create_user_command("MarkdownPreviewToggle", function()
    markdown_plugin.toggle_preview(vim.api.nvim_get_current_buf())
  end, {})
end

return markdown_plugin
