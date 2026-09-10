---
--- ipynb Renderer Plugin
--- Jupyter notebook rendering using built-in Neovim features
--- Renders directly in buffer with extmarks for styling
---

local M = {}

-- ============================================================================
-- Configuration
-- ============================================================================

M.config = {
  show_execution_count = true,
  show_cell_type = true,
  max_output_lines = 100,
  debounce_ms = 100,
}

-- ============================================================================
-- State
-- ============================================================================

local state = {
  ns = vim.api.nvim_create_namespace("renderer_ipynb"),
  timers = {},
}

-- ============================================================================
-- Highlight Groups
-- ============================================================================

local function setup_highlights()
  local hl = {
    { "RendererCellHeader", "Comment" },
    { "RendererCodeCell", "Special" },
    { "RendererMarkdownCell", "String" },
    { "RendererOutput", "Delimiter" },
    { "RendererOutputText", "Normal" },
    { "RendererError", "ErrorMsg" },
    { "RendererStream", "Normal" },
    { "RendererImage", "Underlined" },
  }

  for _, h in ipairs(hl) do
    vim.api.nvim_set_hl(0, h[1], { link = h[2], default = true })
  end
end

-- ============================================================================
-- Notebook Parser (JSON parsing)
-- ============================================================================

local function parse_notebook(json)
  local ok, notebook = pcall(vim.fn.json_decode, json)
  if not ok then
    return nil, "Invalid JSON"
  end

  if not notebook.cells or not notebook.nbformat then
    return nil, "Invalid notebook format"
  end

  return notebook, nil
end

-- ============================================================================
-- Cell Renderer
-- ============================================================================

local function render_cell(cell, index, lines, marks)
  local cell_type = cell.cell_type or "code"
  local source = cell.source or {}
  local outputs = cell.outputs or {}
  local exec_count = cell.execution_count

  -- Cell header
  local header = string.format("─── Cell %d: %s", index + 1, cell_type:upper())
  if exec_count then
    header = header .. string.format(" [%d]", exec_count)
  end
  header = header .. " ───"

  table.insert(lines, header)
  table.insert(marks, {
    line = #lines - 1,
    col = 0,
    end_col = #header,
    hl = "RendererCellHeader",
  })

  -- Source code
  if type(source) == "string" then
    source = vim.split(source, "\n")
  end

  for _, line in ipairs(source) do
    local content = line:gsub("\n$", "")
    table.insert(lines, content)

    if cell_type == "code" then
      table.insert(marks, {
        line = #lines - 1,
        col = 0,
        end_col = #content,
        hl = "RendererCodeCell",
      })
    end
  end

  -- Outputs
  if cell_type == "code" and #outputs > 0 then
    table.insert(lines, "┌─ Output:")
    table.insert(marks, {
      line = #lines - 1,
      col = 0,
      end_col = 10,
      hl = "RendererOutput",
    })

    for _, output in ipairs(outputs) do
      render_output(output, lines, marks)
    end

    table.insert(lines, "└─────────")
    table.insert(marks, {
      line = #lines - 1,
      col = 0,
      end_col = 10,
      hl = "RendererOutput",
    })
  end

  -- Empty line after cell
  table.insert(lines, "")
end

-- ============================================================================
-- Output Renderer
-- ============================================================================

local function render_output(output, lines, marks)
  local output_type = output.output_type

  if output_type == "stream" then
    local text = output.text or {}
    if type(text) == "string" then
      text = vim.split(text, "\n")
    end
    for _, line in ipairs(text) do
      local content = line:gsub("\n$", "")
      table.insert(lines, "│ " .. content)
      table.insert(marks, {
        line = #lines - 1,
        col = 0,
        end_col = 2,
        hl = "RendererOutput",
      })
    end

  elseif output_type == "error" then
    local traceback = output.traceback or {}
    for _, line in ipairs(traceback) do
      -- Strip ANSI codes
      local content = line:gsub("\27%[[0-9;]*m", ""):gsub("\n$", "")
      table.insert(lines, "│ " .. content)
      table.insert(marks, {
        line = #lines - 1,
        col = 0,
        end_col = #content + 2,
        hl = "RendererError",
      })
    end

  elseif output_type == "execute_result" or output_type == "display_data" then
    local data = output.data or {}
    -- Try text/plain first
    if data["text/plain"] then
      local text = data["text/plain"]
      if type(text) == "string" then
        text = vim.split(text, "\n")
      end
      for _, line in ipairs(text) do
        local content = line:gsub("\n$", "")
        table.insert(lines, "│ " .. content)
        table.insert(marks, {
          line = #lines - 1,
          col = 2,
          end_col = #content + 2,
          hl = "RendererOutputText",
        })
      end
    elseif data["image/png"] or data["image/jpeg"] then
      table.insert(lines, "│ [Image]")
      table.insert(marks, {
        line = #lines - 1,
        col = 0,
        end_col = 10,
        hl = "RendererImage",
      })
    elseif data["text/html"] then
      table.insert(lines, "│ [HTML output]")
      table.insert(marks, {
        line = #lines - 1,
        col = 0,
        end_col = 14,
        hl = "RendererOutput",
      })
    end
  end
end

-- ============================================================================
-- Buffer Renderer
-- ============================================================================

local function render_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  local notebook, err = parse_notebook(content)

  if not notebook then
    vim.notify("[ipynb] " .. (err or "Parse error"), vim.log.levels.ERROR)
    return
  end

  local lines = {}
  local marks = {}

  -- Notebook header
  local kernel = notebook.metadata and notebook.metadata.kernelspec
  local header = "=== Jupyter Notebook"
  if kernel and kernel.display_name then
    header = header .. " (" .. kernel.display_name .. ")"
  end
  header = header .. " ==="

  table.insert(lines, header)
  table.insert(marks, {
    line = 0,
    col = 0,
    end_col = #header,
    hl = "RendererCellHeader",
  })
  table.insert(lines, "")

  -- Render cells
  for i, cell in ipairs(notebook.cells) do
    render_cell(cell, i, lines, marks)
  end

  -- Replace buffer content
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.bo[buf].filetype = "ipynb"

  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(buf, state.ns, 0, -1)
  for _, mark in ipairs(marks) do
    pcall(vim.api.nvim_buf_set_extmark, buf, state.ns, mark.line, mark.col, {
      end_col = mark.end_col,
      hl_group = mark.hl,
    })
  end
end

-- ============================================================================
-- Setup
-- ============================================================================

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  setup_highlights()

  local augroup = vim.api.nvim_create_augroup("RendererIpynb", { clear = true })

  -- Render on open
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    pattern = "*.ipynb",
    callback = function(ev)
      render_buffer(ev.buf)
    end,
  })

  -- Update on changes
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = augroup,
    pattern = "*.ipynb",
    callback = function(ev)
      if state.timers[ev.buf] then
        state.timers[ev.buf]:stop()
      end
      state.timers[ev.buf] = vim.defer_fn(function()
        render_buffer(ev.buf)
      end, M.config.debounce_ms)
    end,
  })

  -- Cleanup
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(ev)
      state.timers[ev.buf] = nil
    end,
  })

  -- Commands
  vim.api.nvim_create_user_command("IpynbRender", function()
    render_buffer(vim.api.nvim_get_current_buf())
  end, {})
  vim.api.nvim_create_user_command("IpynbEdit", function()
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].modifiable = true
    vim.bo[buf].filetype = "json"
    vim.notify("[ipynb] Edit mode enabled", vim.log.levels.INFO)
  end, {})

  -- Initial render
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype == "ipynb" or vim.api.nvim_buf_get_name(buf):match("%.ipynb$") then
    render_buffer(buf)
  end
end

return M
