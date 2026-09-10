---
--- ipynb Renderer Plugin (Optimized for <100ms load)
--- Jupyter notebook rendering with kernel selection
--- Lazy-loads kernel definitions for fast startup
---

local ipynb_renderer = {}

-- ============================================================================
-- Configuration (Inline)
-- ============================================================================

ipynb_renderer.config = {
  show_execution_count = true,
  max_output_lines = 100,
  debounce_ms = 100,
  show_render_time = true,
  auto_select_kernel = true,
}

-- ============================================================================
-- State (Lazy-initialized)
-- ============================================================================

local plugin_state = nil
local kernel_definitions = nil

local function get_state()
  if plugin_state then
    return plugin_state
  end
  plugin_state = {
    ns = vim.api.nvim_create_namespace("renderer_ipynb"),
    timers = {},
    selected_kernel = nil,
    last_render_ms = 0,
    highlights_setup = false,
  }
  return plugin_state
end

-- ============================================================================
-- Kernel Definitions (Lazy-loaded)
-- ============================================================================

local function get_kernel_definitions()
  if kernel_definitions then
    return kernel_definitions
  end

  kernel_definitions = {
    { name = "python3", display_name = "Python 3", language = "python", recommended = true },
    { name = "python2", display_name = "Python 2", language = "python", recommended = false },
    { name = "julia", display_name = "Julia", language = "julia", recommended = false },
    { name = "r", display_name = "R", language = "r", recommended = false },
    { name = "bash", display_name = "Bash", language = "bash", recommended = false },
    { name = "javascript", display_name = "JavaScript", language = "javascript", recommended = false },
    { name = "typescript", display_name = "TypeScript", language = "typescript", recommended = false },
  }

  return kernel_definitions
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
    { "RendererCellHeader", "Comment" },
    { "RendererCodeCell", "Special" },
    { "RendererMarkdownCell", "String" },
    { "RendererOutput", "Delimiter" },
    { "RendererOutputText", "Normal" },
    { "RendererError", "ErrorMsg" },
    { "RendererImage", "Underlined" },
    { "RendererRenderTime", "Comment" },
    { "RendererKernelName", "Identifier" },
  }

  for _, mapping in ipairs(highlight_map) do
    vim.api.nvim_set_hl(0, mapping[1], { link = mapping[2], default = true })
  end
end

-- ============================================================================
-- Kernel Selection (Lazy-loaded)
-- ============================================================================

local function find_kernel_by_name(kernel_name)
  local kernels = get_kernel_definitions()
  for _, kernel_def in ipairs(kernels) do
    if kernel_def.name == kernel_name then
      return kernel_def
    end
  end
  return nil
end

local function detect_kernel_from_notebook(notebook_metadata)
  if not notebook_metadata then
    return nil
  end

  if notebook_metadata.kernelspec and notebook_metadata.kernelspec.name then
    return find_kernel_by_name(notebook_metadata.kernelspec.name)
  end

  if notebook_metadata.language_info and notebook_metadata.language_info.name then
    local lang_name = notebook_metadata.language_info.name
    local kernels = get_kernel_definitions()
    for _, kernel_def in ipairs(kernels) do
      if kernel_def.language == lang_name then
        return kernel_def
      end
    end
  end

  return nil
end

local function show_kernel_selection_menu(detected_kernel)
  local menu_items = {}

  if detected_kernel then
    menu_items[1] = {
      text = string.format("%s (detected)", detected_kernel.display_name),
      kernel = detected_kernel,
      is_recommended = true,
    }
  end

  local kernels = get_kernel_definitions()
  for _, kernel_def in ipairs(kernels) do
    if kernel_def.recommended and (not detected_kernel or kernel_def.name ~= detected_kernel.name) then
      menu_items[#menu_items + 1] = {
        text = string.format("%s (recommended)", kernel_def.display_name),
        kernel = kernel_def,
        is_recommended = true,
      }
    end
  end

  for _, kernel_def in ipairs(kernels) do
    if not kernel_def.recommended and (not detected_kernel or kernel_def.name ~= detected_kernel.name) then
      menu_items[#menu_items + 1] = {
        text = kernel_def.display_name,
        kernel = kernel_def,
        is_recommended = false,
      }
    end
  end

  if #menu_items == 0 then
    return
  end

  local display_strings = {}
  for index, item in ipairs(menu_items) do
    local prefix = item.is_recommended and "★ " or "  "
    display_strings[index] = prefix .. item.text
  end

  vim.ui.select(display_strings, {
    prompt = "Select Jupyter Kernel:",
  }, function(selected_index)
    if selected_index and menu_items[selected_index] then
      local current_state = get_state()
      current_state.selected_kernel = menu_items[selected_index].kernel
      vim.notify(
        string.format("[ipynb] Kernel: %s", current_state.selected_kernel.display_name),
        vim.log.levels.INFO
      )
    end
  end)
end

local function select_kernel(notebook_metadata)
  if not ipynb_renderer.config.auto_select_kernel then
    return
  end

  local detected = detect_kernel_from_notebook(notebook_metadata)
  local current_state = get_state()

  if detected then
    current_state.selected_kernel = detected
  else
    vim.defer_fn(function()
      show_kernel_selection_menu(nil)
    end, 100)
  end
end

-- ============================================================================
-- Notebook Parser (Optimized)
-- ============================================================================

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
-- Output Renderer (Optimized)
-- ============================================================================

local function render_output(output, output_lines, output_marks)
  local output_type = output.output_type

  if output_type == "stream" then
    local stream_text = output.text or {}
    if type(stream_text) == "string" then
      stream_text = vim.split(stream_text, "\n")
    end
    for _, stream_line in ipairs(stream_text) do
      local content = stream_line:gsub("\n$", "")
      local line_num = #output_lines
      output_lines[line_num + 1] = "│ " .. content
      output_marks[line_num + 1] = {
        line = line_num,
        col = 0,
        end_col = 2,
        hl = "RendererOutput",
      }
    end

  elseif output_type == "error" then
    local traceback_lines = output.traceback or {}
    for _, traceback_line in ipairs(traceback_lines) do
      local content = traceback_line:gsub("\27%[[0-9;]*m", ""):gsub("\n$", "")
      local line_num = #output_lines
      output_lines[line_num + 1] = "│ " .. content
      output_marks[line_num + 1] = {
        line = line_num,
        col = 0,
        end_col = #content + 2,
        hl = "RendererError",
      }
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
        local line_num = #output_lines
        output_lines[line_num + 1] = "│ " .. content
        output_marks[line_num + 1] = {
          line = line_num,
          col = 2,
          end_col = #content + 2,
          hl = "RendererOutputText",
        }
      end
    elseif output_data["image/png"] or output_data["image/jpeg"] then
      local line_num = #output_lines
      output_lines[line_num + 1] = "│ [Image]"
      output_marks[line_num + 1] = {
        line = line_num,
        col = 0,
        end_col = 10,
        hl = "RendererImage",
      }
    end
  end
end

-- ============================================================================
-- Cell Renderer (Optimized)
-- ============================================================================

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

  local header_line_num = #output_lines
  output_lines[header_line_num + 1] = header_text
  output_marks[header_line_num + 1] = {
    line = header_line_num,
    col = 0,
    end_col = #header_text,
    hl = "RendererCellHeader",
  }

  -- Source code
  if type(source_lines) == "string" then
    source_lines = vim.split(source_lines, "\n")
  end

  local hl_group = cell_type == "code" and "RendererCodeCell" or nil
  for _, source_line in ipairs(source_lines) do
    local content = source_line:gsub("\n$", "")
    local line_num = #output_lines
    output_lines[line_num + 1] = content
    if hl_group then
      output_marks[line_num + 1] = {
        line = line_num,
        col = 0,
        end_col = #content,
        hl = hl_group,
      }
    end
  end

  -- Outputs
  if cell_type == "code" and #cell_outputs > 0 then
    local output_header_num = #output_lines
    output_lines[output_header_num + 1] = "┌─ Output:"
    output_marks[output_header_num + 1] = {
      line = output_header_num,
      col = 0,
      end_col = 10,
      hl = "RendererOutput",
    }

    for _, output in ipairs(cell_outputs) do
      render_output(output, output_lines, output_marks)
    end

    local output_footer_num = #output_lines
    output_lines[output_footer_num + 1] = "└─────────"
    output_marks[output_footer_num + 1] = {
      line = output_footer_num,
      col = 0,
      end_col = 10,
      hl = "RendererOutput",
    }
  end

  output_lines[#output_lines + 1] = ""
end

-- ============================================================================
-- Buffer Renderer (Optimized)
-- ============================================================================

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

  local current_state = get_state()
  if not current_state.selected_kernel then
    select_kernel(notebook.metadata)
  end

  local rendered_lines = {}
  local rendered_marks = {}

  -- Notebook header
  local kernel = notebook.metadata and notebook.metadata.kernelspec
  local header = "=== Jupyter Notebook"
  if kernel and kernel.display_name then
    header = header .. " (" .. kernel.display_name .. ")"
  elseif current_state.selected_kernel then
    header = header .. " (" .. current_state.selected_kernel.display_name .. ")"
  end
  header = header .. " ==="

  rendered_lines[1] = header
  rendered_marks[1] = {
    line = 0,
    col = 0,
    end_col = #header,
    hl = "RendererCellHeader",
  }

  if current_state.selected_kernel then
    local kernel_info = string.format("Kernel: %s", current_state.selected_kernel.display_name)
    rendered_lines[2] = kernel_info
    rendered_marks[2] = {
      line = 1,
      col = 0,
      end_col = #kernel_info,
      hl = "RendererKernelName",
    }
    rendered_lines[3] = ""
  else
    rendered_lines[2] = ""
  end

  -- Render cells
  for cell_index, cell in ipairs(notebook.cells) do
    render_cell(cell, cell_index, rendered_lines, rendered_marks)
  end

  -- Replace buffer content
  vim.api.nvim_buf_set_option(buffer, "modifiable", true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, rendered_lines)
  vim.api.nvim_buf_set_option(buffer, "modifiable", false)
  vim.bo[buffer].filetype = "ipynb"

  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(buffer, current_state.ns, 0, -1)
  for _, mark in ipairs(rendered_marks) do
    pcall(vim.api.nvim_buf_set_extmark, buffer, current_state.ns, mark.line, mark.col, {
      end_col = mark.end_col,
      hl_group = mark.hl,
    })
  end

  local render_time = stop_timing(timing_start)
  current_state.last_render_ms = render_time

  if ipynb_renderer.config.show_render_time then
    local status_msg = string.format("[ipynb] %.2f ms", render_time)
    vim.api.nvim_echo({ { status_msg, "RendererRenderTime" } }, false, {})
  end

  return render_time
end

-- ============================================================================
-- Setup (Minimal)
-- ============================================================================

function ipynb_renderer.setup(opts)
  ipynb_renderer.config = vim.tbl_deep_extend("force", ipynb_renderer.config, opts or {})

  vim.defer_fn(ensure_highlights, 10)

  local augroup = vim.api.nvim_create_augroup("RendererIpynb", { clear = true })

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    pattern = "*.ipynb",
    callback = function(event)
      ensure_highlights()
      render_buffer(event.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = augroup,
    pattern = "*.ipynb",
    callback = function(event)
      local current_state = get_state()
      if current_state.timers[event.buf] then
        current_state.timers[event.buf]:stop()
      end
      current_state.timers[event.buf] = vim.defer_fn(function()
        render_buffer(event.buf)
      end, ipynb_renderer.config.debounce_ms)
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(event)
      local current_state = get_state()
      current_state.timers[event.buf] = nil
    end,
  })

  vim.api.nvim_create_user_command("IpynbRender", function()
    render_buffer(vim.api.nvim_get_current_buf())
  end, {})

  vim.api.nvim_create_user_command("IpynbEdit", function()
    local buffer = vim.api.nvim_get_current_buf()
    vim.bo[buffer].modifiable = true
    vim.bo[buffer].filetype = "json"
    vim.notify("[ipynb] Edit mode", vim.log.levels.INFO)
  end, {})

  vim.api.nvim_create_user_command("IpynbSelectKernel", function()
    local current_buffer = vim.api.nvim_get_current_buf()
    local content = table.concat(vim.api.nvim_buf_get_lines(current_buffer, 0, -1, false), "\n")
    local notebook = parse_notebook(content)
    if notebook then
      show_kernel_selection_menu(detect_kernel_from_notebook(notebook.metadata))
    else
      show_kernel_selection_menu(nil)
    end
  end, {})

  vim.api.nvim_create_user_command("IpynbShowKernels", function()
    local kernels = get_kernel_definitions()
    local kernel_list = {}
    for _, kernel_def in ipairs(kernels) do
      local marker = kernel_def.recommended and "★" or " "
      kernel_list[#kernel_list + 1] = string.format("%s %s", marker, kernel_def.display_name)
    end
    vim.notify("Kernels:\n" .. table.concat(kernel_list, "\n"), vim.log.levels.INFO)
  end, {})
end

return ipynb_renderer
