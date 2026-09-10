---
--- Renderer Plugin - Main Lua Module
--- Renders markdown, ipynb, and images in normal Neovim buffers
---

local M = {}

-- ============================================================================
-- Configuration
-- ============================================================================

M.config = {
  -- General
  enabled = true,
  debounce_ms = 100,

  -- Paths
  bun_path = "bun",
  renderer_script = nil,

  -- Preview mode
  preview = {
    enabled = true,
    position = "right",  -- "right" or "bottom"
    width = 50,          -- For right split (percentage)
    height = 15,         -- For bottom split (lines)
    sync_scroll = true,
    auto_open = true,
  },

  -- Features
  kitty = true,
  mermaid = true,

  -- Logging
  log_level = "info",
}

-- ============================================================================
-- State
-- ============================================================================

local state = {
  job_id = nil,
  ns_id = vim.api.nvim_create_namespace("renderer"),
  preview_ns_id = vim.api.nvim_create_namespace("renderer_preview"),
  attached_buffers = {},
  preview_windows = {},
  preview_buffers = {},
  debounce_timers = {},
  source_buf_to_preview = {},
  preview_buf_to_source = {},
}

-- ============================================================================
-- Setup
-- ============================================================================

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  if not M.config.renderer_script then
    local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
    M.config.renderer_script = plugin_dir .. "/../../src/index.ts"
  end

  local augroup = vim.api.nvim_create_augroup("Renderer", { clear = true })

  -- Markdown: auto-open preview
  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    pattern = { "*.md", "*.markdown" },
    callback = function(ev)
      if M.config.preview.enabled and M.config.preview.auto_open then
        M.open_preview(ev.buf)
      end
    end,
  })

  -- Update on changes
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = augroup,
    pattern = { "*.md", "*.markdown", "*.ipynb", "*.html", "*.htm" },
    callback = function(ev)
      M.on_buffer_changed(ev.buf)
    end,
  })

  -- Sync scroll for markdown preview
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = augroup,
    pattern = { "*.md", "*.markdown" },
    callback = function(ev)
      if M.config.preview.sync_scroll then
        M.sync_scroll(ev.buf)
      end
    end,
  })

  -- Cleanup on close
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(ev)
      M.detach_buffer(ev.buf)
      M.close_preview(ev.buf)
    end,
  })

  -- User commands
  vim.api.nvim_create_user_command("RendererToggle", function()
    M.toggle()
  end, {})

  vim.api.nvim_create_user_command("RendererRefresh", function()
    M.refresh()
  end, {})

  vim.api.nvim_create_user_command("RendererStatus", function()
    M.status()
  end, {})

  vim.api.nvim_create_user_command("RendererPreviewOpen", function()
    M.open_preview(vim.api.nvim_get_current_buf())
  end, {})

  vim.api.nvim_create_user_command("RendererPreviewClose", function()
    M.close_preview(vim.api.nvim_get_current_buf())
  end, {})

  vim.api.nvim_create_user_command("RendererPreviewToggle", function()
    M.toggle_preview(vim.api.nvim_get_current_buf())
  end, {})

  M.start_renderer()
end

-- ============================================================================
-- Renderer Process Management
-- ============================================================================

function M.start_renderer()
  if state.job_id then
    return
  end

  local cmd = { M.config.bun_path, "run", M.config.renderer_script }

  state.job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      M.on_renderer_output(data)
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        vim.notify("[Renderer] " .. table.concat(data, "\n"), vim.log.levels.WARN)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("[Renderer] Process exited with code " .. exit_code, vim.log.levels.ERROR)
      end
      state.job_id = nil
    end,
  })

  if state.job_id <= 0 then
    vim.notify("[Renderer] Failed to start renderer process", vim.log.levels.ERROR)
    state.job_id = nil
  end
end

function M.stop_renderer()
  if state.job_id then
    vim.fn.jobstop(state.job_id)
    state.job_id = nil
  end
end

-- ============================================================================
-- Communication
-- ============================================================================

function M.send_to_renderer(msg)
  if not state.job_id then
    M.start_renderer()
  end

  if state.job_id then
    local json = vim.fn.json_encode(msg)
    vim.fn.chansend(state.job_id, json .. "\n")
  end
end

function M.on_renderer_output(data)
  if not data then
    return
  end

  for _, line in ipairs(data) do
    if line and line ~= "" then
      local ok, msg = pcall(vim.fn.json_decode, line)
      if ok and msg then
        M.handle_renderer_message(msg)
      end
    end
  end
end

function M.handle_renderer_message(msg)
  if msg.type == "render" and msg.data then
    local source_buf = state.preview_buf_to_source[vim.api.nvim_get_current_buf()]
    if source_buf then
      M.apply_render_to_preview(source_buf, msg.data)
    else
      M.apply_render_to_buffer(vim.api.nvim_get_current_buf(), msg.data)
    end
  elseif msg.type == "error" then
    vim.notify("[Renderer] " .. (msg.message or "Unknown error"), vim.log.levels.ERROR)
  end
end

-- ============================================================================
-- Buffer Rendering (ipynb, images - direct in buffer)
-- ============================================================================

function M.apply_render_to_buffer(buf, result)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, state.ns_id, 0, -1)

  if result.lines then
    for _, line_data in ipairs(result.lines) do
      M.apply_line_render(buf, line_data, state.ns_id)
    end
  end
end

function M.apply_line_render(buf, line_data, ns_id)
  local line = line_data.line or 0
  local line_count = vim.api.nvim_buf_line_count(buf)

  if line >= line_count then
    return
  end

  if line_data.marks then
    for _, mark in ipairs(line_data.marks) do
      local col_start = mark.col_start or 0
      local col_end = mark.col_end or 0
      local hl_group = mark.hl_group or "Normal"

      if col_end > col_start then
        pcall(vim.api.nvim_buf_set_extmark, buf, ns_id, line, col_start, {
          end_col = col_end,
          hl_group = hl_group,
        })
      end
    end
  end

  if line_data.virt_text then
    pcall(vim.api.nvim_buf_set_extmark, buf, ns_id, line, 0, {
      virt_text = { { line_data.virt_text, line_data.virt_hl_group or "Comment" } },
      virt_text_pos = line_data.virt_text_pos or "inline",
    })
  end
end

-- ============================================================================
-- Preview Window (Markdown side-by-side)
-- ============================================================================

function M.open_preview(source_buf)
  if not M.config.preview.enabled then
    return
  end

  -- Check if preview already exists
  if state.preview_windows[source_buf] then
    local win = state.preview_windows[source_buf]
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  -- Create preview buffer
  local preview_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[preview_buf].buftype = "nofile"
  vim.bo[preview_buf].bufhidden = "wipe"
  vim.bo[preview_buf].swapfile = false
  vim.bo[preview_buf].filetype = "markdown_preview"

  -- Track mappings
  state.preview_buffers[source_buf] = preview_buf
  state.preview_buf_to_source[preview_buf] = source_buf
  state.source_buf_to_preview[source_buf] = preview_buf

  -- Open split
  local cmd
  if M.config.preview.position == "right" then
    cmd = "botright vertical"
  else
    cmd = "botright"
  end

  local split_cmd
  if M.config.preview.position == "right" then
    split_cmd = string.format("%s %dvnew", cmd, math.floor(vim.o.columns * M.config.preview.width / 100))
  else
    split_cmd = string.format("%s %dnew", cmd, M.config.preview.height)
  end

  vim.cmd(split_cmd)
  local preview_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(preview_win, preview_buf)

  -- Set preview window options
  vim.wo[preview_win].wrap = true
  vim.wo[preview_win].number = false
  vim.wo[preview_win].relativenumber = false
  vim.wo[preview_win].signcolumn = "no"
  vim.wo[preview_win].foldcolumn = "0"
  vim.wo[preview_win].list = false

  -- Store preview window
  state.preview_windows[source_buf] = preview_win

  -- Go back to source window
  vim.api.nvim_set_current_win(vim.fn.winbufwin(source_buf))

  -- Initial render
  M.send_buffer_content(source_buf)
end

function M.close_preview(source_buf)
  local preview_win = state.preview_windows[source_buf]
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_win_close(preview_win, true)
  end

  local preview_buf = state.preview_buffers[source_buf]
  if preview_buf then
    state.preview_buf_to_source[preview_buf] = nil
  end

  state.preview_windows[source_buf] = nil
  state.preview_buffers[source_buf] = nil
  state.source_buf_to_preview[source_buf] = nil
end

function M.toggle_preview(source_buf)
  if state.preview_windows[source_buf] then
    M.close_preview(source_buf)
  else
    M.open_preview(source_buf)
  end
end

-- ============================================================================
-- Preview Rendering
-- ============================================================================

function M.apply_render_to_preview(source_buf, result)
  local preview_buf = state.preview_buffers[source_buf]
  if not preview_buf or not vim.api.nvim_buf_is_valid(preview_buf) then
    return
  end

  -- Clear preview buffer
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, {})
  vim.api.nvim_buf_clear_namespace(preview_buf, state.preview_ns_id, 0, -1)

  if result.lines then
    local lines = {}
    for _, line_data in ipairs(result.lines) do
      table.insert(lines, line_data.text or "")
    end

    -- Set text content
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)

    -- Apply highlighting
    for _, line_data in ipairs(result.lines) do
      M.apply_line_render(preview_buf, line_data, state.preview_ns_id)
    end
  end
end

-- ============================================================================
-- Scroll Sync
-- ============================================================================

function M.sync_scroll(source_buf)
  local preview_win = state.preview_windows[source_buf]
  if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
    return
  end

  local source_win = vim.fn.winbufwin(source_buf)
  if source_win == -1 then
    return
  end

  -- Get source cursor position
  local cursor = vim.api.nvim_win_get_cursor(source_win)
  local source_line = cursor[1]

  -- Map source line to preview line (1:1 mapping for now)
  local preview_line = math.min(source_line, vim.api.nvim_buf_line_count(state.preview_buffers[source_buf]))

  -- Set preview cursor
  pcall(vim.api.nvim_win_set_cursor, preview_win, { preview_line, 0 })
end

-- ============================================================================
-- Buffer Management
-- ============================================================================

function M.attach_buffer(buf)
  if state.attached_buffers[buf] then
    return
  end

  state.attached_buffers[buf] = true
  M.send_buffer_content(buf)
end

function M.detach_buffer(buf)
  state.attached_buffers[buf] = nil
  state.debounce_timers[buf] = nil
end

function M.send_buffer_content(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  local filetype = vim.bo[buf].filetype

  if filetype == "markdown" or filetype == "md" then
    filetype = "markdown"
  elseif filetype == "ipynb" then
    filetype = "ipynb"
  elseif filetype == "html" or filetype == "htm" then
    filetype = "html"
  else
    filetype = "markdown"
  end

  M.send_to_renderer({
    type = "update",
    content = content,
    filetype = filetype,
  })
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

function M.on_buffer_changed(buf)
  if not M.config.enabled then
    return
  end

  -- For markdown, update preview
  local filetype = vim.bo[buf].filetype
  if filetype == "markdown" or filetype == "md" then
    if state.preview_buffers[buf] then
      -- Debounce preview updates
      if state.debounce_timers[buf] then
        state.debounce_timers[buf]:stop()
      end
      state.debounce_timers[buf] = vim.defer_fn(function()
        M.send_buffer_content(buf)
      end, M.config.debounce_ms)
    end
  else
    -- For ipynb, render directly in buffer
    if not state.attached_buffers[buf] then
      M.attach_buffer(buf)
      return
    end

    if state.debounce_timers[buf] then
      state.debounce_timers[buf]:stop()
    end
    state.debounce_timers[buf] = vim.defer_fn(function()
      M.send_buffer_content(buf)
    end, M.config.debounce_ms)
  end
end

-- ============================================================================
-- User Commands
-- ============================================================================

function M.toggle()
  M.config.enabled = not M.config.enabled
  local status = M.config.enabled and "enabled" or "disabled"
  vim.notify("[Renderer] " .. status, vim.log.levels.INFO)
end

function M.refresh()
  local buf = vim.api.nvim_get_current_buf()
  M.send_buffer_content(buf)
end

function M.status()
  local status = {
    enabled = M.config.enabled,
    process_running = state.job_id ~= nil,
    attached_buffers = vim.tbl_keys(state.attached_buffers),
    preview_windows = vim.tbl_keys(state.preview_windows),
  }
  vim.notify("[Renderer] Status:\n" .. vim.inspect(status), vim.log.levels.INFO)
end

return M
