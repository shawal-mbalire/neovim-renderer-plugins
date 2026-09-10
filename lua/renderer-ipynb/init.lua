---
--- ipynb Renderer Plugin
--- Jupyter notebook rendering with kernel selection menu
--- Uses built-in Neovim features: extmarks, vim.ui.select
---

local M = {}

-- ============================================================================
-- Kernel Definitions (Constants)
-- ============================================================================

---@class KernelDefinition
---@field name string
---@field display_name string
---@field language string
---@field mime_type string
---@field file_extension string
---@field recommended boolean

---@type KernelDefinition[]
local KERNEL_DEFINITIONS = {
  {
    name = "python3",
    display_name = "Python 3",
    language = "python",
    mime_type = "text/x-python",
    file_extension = ".py",
    recommended = true,
  },
  {
    name = "python2",
    display_name = "Python 2",
    language = "python",
    mime_type = "text/x-python",
    file_extension = ".py",
    recommended = false,
  },
  {
    name = "julia",
    display_name = "Julia",
    language = "julia",
    mime_type = "text/x-julia",
    file_extension = ".jl",
    recommended = false,
  },
  {
    name = "r",
    display_name = "R",
    language = "r",
    mime_type = "text/x-r",
    file_extension = ".r",
    recommended = false,
  },
  {
    name = "bash",
    display_name = "Bash",
    language = "bash",
    mime_type = "text/x-sh",
    file_extension = ".sh",
    recommended = false,
  },
  {
    name = "javascript",
    display_name = "JavaScript",
    language = "javascript",
    mime_type = "application/javascript",
    file_extension = ".js",
    recommended = false,
  },
  {
    name = "typescript",
    display_name = "TypeScript",
    language = "typescript",
    mime_type = "application/typescript",
    file_extension = ".ts",
    recommended = false,
  },
  {
    name = "markdown",
    display_name = "Markdown",
    language = "markdown",
    mime_type = "text/markdown",
    file_extension = ".md",
    recommended = false,
  },
}

-- ============================================================================
-- Configuration
-- ============================================================================

---@class IpynbConfig
---@field show_execution_count boolean
---@field max_output_lines number
---@field debounce_ms number
---@field show_render_time boolean
---@field auto_select_kernel boolean

---@type IpynbConfig
M.config = {
  show_execution_count = true,
  max_output_lines = 100,
  debounce_ms = 100,
  show_render_time = true,
  auto_select_kernel = true,
}

-- ============================================================================
-- State
-- ============================================================================

---@class IpynbState
---@field ns number
---@field timers table<number, any>
---@field selected_kernel table|nil
---@field last_render_ms number

---@type IpynbState
local state = {
  ns = vim.api.nvim_create_namespace("renderer_ipynb"),
  timers = {},
  selected_kernel = nil,
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
    { group = "RendererCellHeader", link = "Comment" },
    { group = "RendererCodeCell", link = "Special" },
    { group = "RendererMarkdownCell", link = "String" },
    { group = "RendererOutput", link = "Delimiter" },
    { group = "RendererOutputText", link = "Normal" },
    { group = "RendererError", link = "ErrorMsg" },
    { group = "RendererStream", link = "Normal" },
    { group = "RendererImage", link = "Underlined" },
    { group = "RendererRenderTime", link = "Comment" },
    { group = "RendererKernelName", link = "Identifier" },
    { group = "RendererRecommended", link = "Statement" },
  }

  for _, link_info in ipairs(highlight_links) do
    vim.api.nvim_set_hl(0, link_info.group, { link = link_info.link, default = true })
  end
end

-- ============================================================================
-- Kernel Selection
-- ============================================================================

---@param kernel_name string
---@return KernelDefinition|nil
local function find_kernel_by_name(kernel_name)
  for _, kernel_definition in ipairs(KERNEL_DEFINITIONS) do
    if kernel_definition.name == kernel_name then
      return kernel_definition
    end
  end
  return nil
end

---@param notebook_metadata table
---@return KernelDefinition|nil
local function detect_kernel_from_notebook(notebook_metadata)
  if not notebook_metadata then
    return nil
  end

  -- Try kernelspec first
  if notebook_metadata.kernelspec then
    local kernel_name = notebook_metadata.kernelspec.name
    if kernel_name then
      return find_kernel_by_name(kernel_name)
    end
  end

  -- Try language_info
  if notebook_metadata.language_info then
    local language_name = notebook_metadata.language_info.name
    if language_name then
      for _, kernel_definition in ipairs(KERNEL_DEFINITIONS) do
        if kernel_definition.language == language_name then
          return kernel_definition
        end
      end
    end
  end

  return nil
end

---@param detected_kernel KernelDefinition|nil
local function show_kernel_selection_menu(detected_kernel)
  local menu_items = {}

  -- Add detected kernel first with marker
  if detected_kernel then
    table.insert(menu_items, {
      text = string.format("%s (detected)", detected_kernel.display_name),
      kernel = detected_kernel,
      is_recommended = true,
    })
  end

  -- Add recommended kernels
  for _, kernel_definition in ipairs(KERNEL_DEFINITIONS) do
    if kernel_definition.recommended and (not detected_kernel or kernel_definition.name ~= detected_kernel.name) then
      table.insert(menu_items, {
        text = string.format("%s (recommended)", kernel_definition.display_name),
        kernel = kernel_definition,
        is_recommended = true,
      })
    end
  end

  -- Add other kernels
  for _, kernel_definition in ipairs(KERNEL_DEFINITIONS) do
    if not kernel_definition.recommended and (not detected_kernel or kernel_definition.name ~= detected_kernel.name) then
      table.insert(menu_items, {
        text = kernel_definition.display_name,
        kernel = kernel_definition,
        is_recommended = false,
      })
    end
  end

  if #menu_items == 0 then
    vim.notify("[ipynb] No kernels available", vim.log.levels.WARN)
    return
  end

  -- Format display strings for vim.ui.select
  local display_strings = {}
  for index, menu_item in ipairs(menu_items) do
    local prefix = ""
    if menu_item.is_recommended then
      prefix = "★ "
    end
    display_strings[index] = prefix .. menu_item.text
  end

  vim.ui.select(display_strings, {
    prompt = "Select Jupyter Kernel:",
    format_item = function(item)
      return item
    end,
  }, function(selected_index)
    if selected_index and menu_items[selected_index] then
      state.selected_kernel = menu_items[selected_index].kernel
      vim.notify(
        string.format("[ipynb] Selected kernel: %s", state.selected_kernel.display_name),
        vim.log.levels.INFO
      )
    end
  end)
end

---@param notebook_metadata table
local function select_kernel(notebook_metadata)
  if not M.config.auto_select_kernel then
    return
  end

  local detected_kernel = detect_kernel_from_notebook(notebook_metadata)

  if detected_kernel then
    state.selected_kernel = detected_kernel
    vim.notify(
      string.format("[ipynb] Auto-detected kernel: %s", detected_kernel.display_name),
      vim.log.levels.INFO
    )
  else
    show_kernel_selection_menu(nil)
  end
end

-- ============================================================================
-- Notebook Parser
-- ============================================================================

---@param json_content string
---@return table|nil notebook
---@return string|nil error
local function parse_notebook(json_content)
  local success, notebook = pcall(vim.fn.json_decode, json_content)
  if not success then
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

---@class RenderedOutput
---@field lines string[]
---@field marks table[]

---@param cell table
---@param cell_index number
---@param output_lines string[]
---@param output_marks table[]
local function render_cell(cell, cell_index, output_lines, output_marks)
  local cell_type = cell.cell_type or "code"
  local source_lines = cell.source or {}
  local cell_outputs = cell.outputs or {}
  local execution_count = cell.execution_count

  -- Cell header
  local header_text = string.format("─── Cell %d: %s", cell_index + 1, cell_type:upper())
  if execution_count then
    header_text = header_text .. string.format(" [%d]", execution_count)
  end
  header_text = header_text .. " ───"

  table.insert(output_lines, header_text)
  table.insert(output_marks, {
    line = #output_lines - 1,
    col = 0,
    end_col = #header_text,
    hl = "RendererCellHeader",
  })

  -- Source code
  if type(source_lines) == "string" then
    source_lines = vim.split(source_lines, "\n")
  end

  for _, source_line in ipairs(source_lines) do
    local content = source_line:gsub("\n$", "")
    table.insert(output_lines, content)

    if cell_type == "code" then
      table.insert(output_marks, {
        line = #output_lines - 1,
        col = 0,
        end_col = #content,
        hl = "RendererCodeCell",
      })
    end
  end

  -- Outputs
  if cell_type == "code" and #cell_outputs > 0 then
    table.insert(output_lines, "┌─ Output:")
    table.insert(output_marks, {
      line = #output_lines - 1,
      col = 0,
      end_col = 10,
      hl = "RendererOutput",
    })

    for _, output in ipairs(cell_outputs) do
      render_output(output, output_lines, output_marks)
    end

    table.insert(output_lines, "└─────────")
    table.insert(output_marks, {
      line = #output_lines - 1,
      col = 0,
      end_col = 10,
      hl = "RendererOutput",
    })
  end

  table.insert(output_lines, "")
end

-- ============================================================================
-- Output Renderer
-- ============================================================================

---@param output table
---@param output_lines string[]
---@param output_marks table[]
local function render_output(output, output_lines, output_marks)
  local output_type = output.output_type

  if output_type == "stream" then
    local stream_text = output.text or {}
    if type(stream_text) == "string" then
      stream_text = vim.split(stream_text, "\n")
    end
    for _, stream_line in ipairs(stream_text) do
      local content = stream_line:gsub("\n$", "")
      table.insert(output_lines, "│ " .. content)
      table.insert(output_marks, {
        line = #output_lines - 1,
        col = 0,
        end_col = 2,
        hl = "RendererOutput",
      })
    end

  elseif output_type == "error" then
    local traceback_lines = output.traceback or {}
    for _, traceback_line in ipairs(traceback_lines) do
      local content = traceback_line:gsub("\27%[[0-9;]*m", ""):gsub("\n$", "")
      table.insert(output_lines, "│ " .. content)
      table.insert(output_marks, {
        line = #output_lines - 1,
        col = 0,
        end_col = #content + 2,
        hl = "RendererError",
      })
    end

  elseif output_type == "execute_result" or output_type == "display_data" then
    local output_data = output.data or {}
    if output_data["text/plain"] then
      local text_content = output_data["text/plain"]
      if type(text_content) == "string" then
        text_content = vim.split(text_content, "\n")
      end
      for _, text_line in ipairs(text_content) do
        local content = text_line:gsub("\n$", "")
        table.insert(output_lines, "│ " .. content)
        table.insert(output_marks, {
          line = #output_lines - 1,
          col = 2,
          end_col = #content + 2,
          hl = "RendererOutputText",
        })
      end
    elseif output_data["image/png"] or output_data["image/jpeg"] then
      table.insert(output_lines, "│ [Image]")
      table.insert(output_marks, {
        line = #output_lines - 1,
        col = 0,
        end_col = 10,
        hl = "RendererImage",
      })
    elseif output_data["text/html"] then
      table.insert(output_lines, "│ [HTML output]")
      table.insert(output_marks, {
        line = #output_lines - 1,
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

---@param buffer number
---@return number render_time_ms
local function render_buffer(buffer)
  local timing_start = start_timing()

  if not vim.api.nvim_buf_is_valid(buffer) then
    return 0
  end

  local content = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
  local notebook, parse_error = parse_notebook(content)

  if not notebook then
    vim.notify("[ipynb] " .. (parse_error or "Parse error"), vim.log.levels.ERROR)
    return 0
  end

  -- Select kernel if not already selected
  if not state.selected_kernel then
    select_kernel(notebook.metadata)
  end

  local rendered_lines = {}
  local rendered_marks = {}

  -- Notebook header with kernel info
  local kernel = notebook.metadata and notebook.metadata.kernelspec
  local header = "=== Jupyter Notebook"
  if kernel and kernel.display_name then
    header = header .. " (" .. kernel.display_name .. ")"
  elseif state.selected_kernel then
    header = header .. " (" .. state.selected_kernel.display_name .. ")"
  end
  header = header .. " ==="

  table.insert(rendered_lines, header)
  table.insert(rendered_marks, {
    line = 0,
    col = 0,
    end_col = #header,
    hl = "RendererCellHeader",
  })

  -- Kernel info line
  if state.selected_kernel then
    local kernel_info = string.format("Kernel: %s", state.selected_kernel.display_name)
    table.insert(rendered_lines, kernel_info)
    table.insert(rendered_marks, {
      line = 1,
      col = 0,
      end_col = #kernel_info,
      hl = "RendererKernelName",
    })
  end

  table.insert(rendered_lines, "")

  -- Render cells
  local start_line_offset = state.selected_kernel and 3 or 1
  for cell_index, cell in ipairs(notebook.cells) do
    render_cell(cell, cell_index, rendered_lines, rendered_marks)
  end

  -- Replace buffer content
  vim.api.nvim_buf_set_option(buffer, "modifiable", true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, rendered_lines)
  vim.api.nvim_buf_set_option(buffer, "modifiable", false)
  vim.bo[buffer].filetype = "ipynb"

  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(buffer, state.ns, 0, -1)
  for _, mark in ipairs(rendered_marks) do
    pcall(vim.api.nvim_buf_set_extmark, buffer, state.ns, mark.line, mark.col, {
      end_col = mark.end_col,
      hl_group = mark.hl,
    })
  end

  local render_time = stop_timing(timing_start)
  state.last_render_ms = render_time

  if M.config.show_render_time then
    local status_message = string.format("[ipynb] Rendered in %.2f ms", render_time)
    vim.api.nvim_echo({ { status_message, "RendererRenderTime" } }, false, {})
  end

  return render_time
end

-- ============================================================================
-- Setup
-- ============================================================================

---@param opts? IpynbConfig
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  setup_highlights()

  local augroup = vim.api.nvim_create_augroup("RendererIpynb", { clear = true })

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    pattern = "*.ipynb",
    callback = function(event)
      render_buffer(event.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = augroup,
    pattern = "*.ipynb",
    callback = function(event)
      if state.timers[event.buf] then
        state.timers[event.buf]:stop()
      end
      state.timers[event.buf] = vim.defer_fn(function()
        render_buffer(event.buf)
      end, M.config.debounce_ms)
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(event)
      state.timers[event.buf] = nil
    end,
  })

  vim.api.nvim_create_user_command("IpynbRender", function()
    render_buffer(vim.api.nvim_get_current_buf())
  end, {})

  vim.api.nvim_create_user_command("IpynbEdit", function()
    local buffer = vim.api.nvim_get_current_buf()
    vim.bo[buffer].modifiable = true
    vim.bo[buffer].filetype = "json"
    vim.notify("[ipynb] Edit mode enabled", vim.log.levels.INFO)
  end, {})

  vim.api.nvim_create_user_command("IpynbSelectKernel", function()
    local current_buffer = vim.api.nvim_get_current_buf()
    local buffer_content = table.concat(vim.api.nvim_buf_get_lines(current_buffer, 0, -1, false), "\n")
    local notebook = parse_notebook(buffer_content)
    if notebook then
      show_kernel_selection_menu(detect_kernel_from_notebook(notebook.metadata))
    else
      show_kernel_selection_menu(nil)
    end
  end, {})

  vim.api.nvim_create_user_command("IpynbShowKernels", function()
    local kernel_list = {}
    for _, kernel_definition in ipairs(KERNEL_DEFINITIONS) do
      local marker = kernel_definition.recommended and "★" or " "
      table.insert(kernel_list, string.format("%s %s (%s)", marker, kernel_definition.display_name, kernel_definition.name))
    end
    vim.notify("Available kernels:\n" .. table.concat(kernel_list, "\n"), vim.log.levels.INFO)
  end, {})

  local current_buffer = vim.api.nvim_get_current_buf()
  local buffer_name = vim.api.nvim_buf_get_name(current_buffer)
  if vim.bo[current_buffer].filetype == "ipynb" or buffer_name:match("%.ipynb$") then
    render_buffer(current_buffer)
  end
end

return M
