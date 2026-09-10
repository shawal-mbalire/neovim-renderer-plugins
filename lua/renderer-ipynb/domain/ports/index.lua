---
--- ipynb Domain Ports
---

local ipynb_ports = {}

---@class NotebookParserPort
---@field parse fun(json: string): Notebook

---@class NotebookRendererPort
---@field render fun(notebook: Notebook, start_line?: number): RenderResult

---@class KernelSelectorPort
---@field detect_kernel fun(metadata: table): KernelDefinition|nil
---@field show_selection_menu fun(callback: fun(kernel: KernelDefinition)): nil

return ipynb_ports
