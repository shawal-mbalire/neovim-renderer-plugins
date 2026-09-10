---
--- Timing Utility
--- High-precision timing for performance measurement
---

local timing_utils = {}

---@return number start_time
function timing_utils.start()
  return vim.uv.hrtime()
end

---@param start_time number
---@return number elapsed_ms
function timing_utils.stop(start_time)
  local elapsed_ns = vim.uv.hrtime() - start_time
  return math.floor((elapsed_ns / 1e6) * 100) / 100
end

---@param label string
---@param start_time number
---@return string
function timing_utils.format(label, start_time)
  local elapsed = timing_utils.stop(start_time)
  return string.format("%s: %.2f ms", label, elapsed)
end

return timing_utils
