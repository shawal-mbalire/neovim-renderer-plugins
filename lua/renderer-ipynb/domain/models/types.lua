---
--- ipynb Domain Models
--- Pure data structures for Jupyter notebooks
---

local ipynb_models = {}

-- ============================================================================
-- Cell Types (StrEnum pattern)
-- ============================================================================

---@alias CellType "code" | "markdown" | "raw"
---@alias OutputType "stream" | "execute_result" | "display_data" | "error"

-- ============================================================================
-- Notebook Types
-- ============================================================================

---@class Notebook
---@field cells Cell[]
---@field metadata table
---@field nbformat number
---@field nbformat_minor number

---@class Cell
---@field cell_type CellType
---@field source string[]
---@field outputs? Output[]
---@field execution_count? number
---@field metadata? table

---@class Output
---@field output_type OutputType
---@field name? string
---@field text? string[]
---@field data? table
---@field ename? string
---@field evalue? string
---@field traceback? string[]

---@class KernelDefinition
---@field name string
---@field display_name string
---@field language string
---@field recommended boolean

-- ============================================================================
-- Factory Functions
-- ============================================================================

---@return KernelDefinition[]
function ipynb_models.get_kernel_definitions()
  return {
    { name = "python3", display_name = "Python 3", language = "python", recommended = true },
    { name = "python2", display_name = "Python 2", language = "python", recommended = false },
    { name = "julia", display_name = "Julia", language = "julia", recommended = false },
    { name = "r", display_name = "R", language = "r", recommended = false },
    { name = "bash", display_name = "Bash", language = "bash", recommended = false },
    { name = "javascript", display_name = "JavaScript", language = "javascript", recommended = false },
    { name = "typescript", display_name = "TypeScript", language = "typescript", recommended = false },
  }
end

---@param name string
---@return KernelDefinition|nil
function ipynb_models.find_kernel_by_name(name)
  for _, kernel in ipairs(ipynb_models.get_kernel_definitions()) do
    if kernel.name == name then
      return kernel
    end
  end
  return nil
end

---@param metadata table
---@return KernelDefinition|nil
function ipynb_models.detect_kernel(metadata)
  if not metadata then
    return nil
  end

  if metadata.kernelspec and metadata.kernelspec.name then
    return ipynb_models.find_kernel_by_name(metadata.kernelspec.name)
  end

  if metadata.language_info and metadata.language_info.name then
    local lang = metadata.language_info.name
    for _, kernel in ipairs(ipynb_models.get_kernel_definitions()) do
      if kernel.language == lang then
        return kernel
      end
    end
  end

  return nil
end

return ipynb_models
