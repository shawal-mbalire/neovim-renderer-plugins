---
--- Markdown Renderer Plugin
--- GitHub Flavored Markdown with side-by-side preview
--- Uses built-in Neovim features: extmarks, splits, autocmds
---

local M = {}

-- ============================================================================
-- Configuration
-- ============================================================================

M.config = {
  -- Preview
  preview = {
    enabled = true,
    position = "right",  -- "right" or "bottom"
    width = 50,          -- percentage for right
    height = 15,         -- lines for bottom
    sync_scroll = true,
    auto_open = true,
  },
  debounce_ms = 100,
}

-- ============================================================================
-- State
-- ============================================================================

local state = {
  ns = vim.api.nvim_create_namespace("renderer_markdown"),
  preview_wins = {},
  preview_bufs = {},
  source_to_preview = {},
  timers = {},
}

-- ============================================================================
-- Highlight Groups (using built-in Neovim features)
-- ============================================================================

local function setup_highlights()
  local links = {
    { "RendererHeading1", "Title" },
    { "RendererHeading2", "Title" },
    { "RendererBold", "Bold" },
    { "RendererItalic", "Italic" },
    { "RendererStrike", "Strike" },
    { "RendererCode", "Special" },
    { "RendererCodeBlock", "Special" },
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
  }

  for _, link in ipairs(links) do
    vim.api.nvim_set_hl(0, link[1], { link = link[2], default = true })
  end
end

-- ============================================================================
-- Parser (built-in pattern matching)
-- ============================================================================

local function parse_markdown(lines)
  local marks = {}

  for i, line in ipairs(lines) do
    local line_idx = i - 1

    -- Headings
    local heading_level = line:match("^(#{1,6})%s")
    if heading_level then
      table.insert(marks, {
        line = line_idx,
        col = 0,
        end_col = #line,
        hl = "RendererHeading" .. #heading_level,
      })
    end

    -- Bold
    for s, e in line:gmatch("**([^*]+)**") do
      local col = line:find("%*%*" .. s .. "%*%*")
      if col then
        table.insert(marks, {
          line = line_idx,
          col = col - 1,
          end_col = col + #s + 3,
          hl = "RendererBold",
        })
      end
    end

    -- Italic
    for s, e in line:gmatch("*([^*]+)*") do
      if not line:match("%*%*" .. s .. "%*%*") then
        local col = line:find("%*" .. s .. "%*")
        if col then
          table.insert(marks, {
            line = line_idx,
            col = col - 1,
            end_col = col + #s + 1,
            hl = "RendererItalic",
          })
        end
      end
    end

    -- Inline code
    for code in line:gmatch("`([^`]+)`") do
      local col = line:find("`" .. code .. "`")
      if col then
        table.insert(marks, {
          line = line_idx,
          col = col - 1,
          end_col = col + #code + 1,
          hl = "RendererCode",
        })
      end
    end

    -- Links [text](url)
    for text, url in line:gmatch("%[([^%]]+)%]%(([^)]+)%)") do
      local pattern = "%[" .. text .. "%]%(" .. url .. "%)"
      local col = line:find(pattern)
      if col then
        table.insert(marks, {
          line = line_idx,
          col = col - 1,
          end_col = col + #text + #url + 4,
          hl = "RendererLink",
        })
      end
    end

    -- Images ![alt](src)
    for alt, src in line:gmatch("!?%[([^%]]+)%]%(([^)]+)%)") do
      if line:match("!%[") then
        local pattern = "!%[" .. alt .. "%]%(" .. src .. "%)"
        local col = line:find(pattern)
        if col then
          table.insert(marks, {
            line = line_idx,
            col = col - 1,
            end_col = col + #alt + #src + 4,
            hl = "RendererImage",
          })
        end
      end
    end

    -- Blockquote
    if line:match("^>%s") then
      table.insert(marks, {
        line = line_idx,
        col = 0,
        end_col = 2,
        hl = "RendererBlockquote",
      })
    end

    -- Horizontal rule
    if line:match("^%-%-%-%s*$") or line:match("^%*%*%*%s*$") then
      table.insert(marks, {
        line = line_idx,
        col = 0,
        end_col = #line,
        hl = "RendererHr",
        virt_text = { string.rep("─", vim.o.columns), "RendererHr" },
      })
    end

    -- Task lists
    local task_done = line:match("^%s*[-*+] %[[xX]%]")
    local task_todo = line:match("^%s*[-*+] %[ %]")
    if task_done then
      table.insert(marks, {
        line = line_idx,
        col = 0,
        end_col = #line,
        hl = "RendererTaskDone",
      })
    elseif task_todo then
      table.insert(marks, {
        line = line_idx,
        col = 0,
        end_col = #line,
        hl = "RendererTaskTodo",
      })
    end
  end

  return marks
end

-- ============================================================================
-- Renderer
-- ============================================================================

local function render_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local marks = parse_markdown(lines)

  -- Clear and apply marks
  vim.api.nvim_buf_clear_namespace(buf, state.ns, 0, -1)

  for _, mark in ipairs(marks) do
    if mark.virt_text then
      vim.api.nvim_buf_set_extmark(buf, state.ns, mark.line, mark.col, {
        virt_text = { mark.virt_text },
        virt_text_pos = "overlay",
      })
    else
      pcall(vim.api.nvim_buf_set_extmark, buf, state.ns, mark.line, mark.col, {
        end_col = mark.end_col,
        hl_group = mark.hl,
      })
    end
  end
end

-- ============================================================================
-- Preview Window
-- ============================================================================

function M.open_preview(source_buf)
  if not M.config.preview.enabled then
    return
  end

  if state.preview_wins[source_buf] then
    local win = state.preview_wins[source_buf]
    if vim.api.nvim_win_is_valid(win) then
      return
    end
  end

  -- Create preview buffer
  local preview_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[preview_buf].buftype = "nofile"
  vim.bo[preview_buf].bufhidden = "wipe"
  vim.bo[preview_buf].filetype = "markdown"

  state.preview_bufs[source_buf] = preview_buf
  state.source_to_preview[source_buf] = preview_buf

  -- Open split
  local cmd
  if M.config.preview.position == "right" then
    local width = math.floor(vim.o.columns * M.config.preview.width / 100)
    cmd = string.format("botright vertical %dvnew", width)
  else
    cmd = string.format("botright %dnew", M.config.preview.height)
  end

  vim.cmd(cmd)
  local preview_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(preview_win, preview_buf)

  -- Configure preview window (using built-in options)
  vim.wo[preview_win].wrap = true
  vim.wo[preview_win].number = false
  vim.wo[preview_win].relativenumber = false
  vim.wo[preview_win].signcolumn = "no"
  vim.wo[preview_win].foldcolumn = "0"
  vim.wo[preview_win].list = false
  vim.wo[preview_win].cursorline = false

  state.preview_wins[source_buf] = preview_win

  -- Go back to source
  local source_win = vim.fn.winbufwin(source_buf)
  if source_win > 0 then
    vim.api.nvim_set_current_win(source_win)
  end

  -- Initial render
  M.update_preview(source_buf)
end

function M.close_preview(source_buf)
  local win = state.preview_wins[source_buf]
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end

  state.preview_wins[source_buf] = nil
  local preview_buf = state.preview_bufs[source_buf]
  if preview_buf then
    state.source_to_preview[preview_buf] = nil
  end
  state.preview_bufs[source_buf] = nil
end

function M.toggle_preview(source_buf)
  if state.preview_wins[source_buf] then
    M.close_preview(source_buf)
  else
    M.open_preview(source_buf)
  end
end

function M.update_preview(source_buf)
  local preview_buf = state.preview_bufs[source_buf]
  if not preview_buf or not vim.api.nvim_buf_is_valid(preview_buf) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
  render_buffer(preview_buf)
end

-- ============================================================================
-- Scroll Sync
-- ============================================================================

local function sync_scroll(source_buf)
  local preview_win = state.preview_wins[source_buf]
  if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
    return
  end

  local source_win = vim.fn.winbufwin(source_buf)
  if source_win <= 0 then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(source_win)
  local preview_buf = state.preview_bufs[source_buf]
  local max_line = vim.api.nvim_buf_line_count(preview_buf)
  local target = math.min(cursor[1], max_line)

  pcall(vim.api.nvim_win_set_cursor, preview_win, { target, 0 })
end

-- ============================================================================
-- Setup
-- ============================================================================

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  setup_highlights()

  local augroup = vim.api.nvim_create_augroup("RendererMarkdown", { clear = true })

  -- Auto-open preview for markdown files
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
    pattern = { "*.md", "*.markdown" },
    callback = function(ev)
      if state.timers[ev.buf] then
        state.timers[ev.buf]:stop()
      end
      state.timers[ev.buf] = vim.defer_fn(function()
        render_buffer(ev.buf)
        M.update_preview(ev.buf)
      end, M.config.debounce_ms)
    end,
  })

  -- Sync scroll
  if M.config.preview.sync_scroll then
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = augroup,
      pattern = { "*.md", "*.markdown" },
      callback = function(ev)
        sync_scroll(ev.buf)
      end,
    })
  end

  -- Cleanup
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(ev)
      M.close_preview(ev.buf)
      state.timers[ev.buf] = nil
    end,
  })

  -- Commands
  vim.api.nvim_create_user_command("MarkdownPreview", function()
    M.open_preview(vim.api.nvim_get_current_buf())
  end, {})
  vim.api.nvim_create_user_command("MarkdownPreviewClose", function()
    M.close_preview(vim.api.nvim_get_current_buf())
  end, {})
  vim.api.nvim_create_user_command("MarkdownPreviewToggle", function()
    M.toggle_preview(vim.api.nvim_get_current_buf())
  end, {})

  -- Initial render for current buffer
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype == "markdown" then
    render_buffer(buf)
  end
end

return M
