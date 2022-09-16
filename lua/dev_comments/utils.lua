local U = {}

local bufload_file = function(file_path)
  local bufnr = vim.fn.bufadd(file_path)
  -- NOTE: silent is required to avoid E325
  vim.cmd("silent! call bufload(" .. bufnr .. ")")

  return bufnr
end

local get_type = function(path)
  local stat = vim.loop.fs_stat(path)
  if stat then return stat.type end
end

-- Get path separator depending on OS
local get_path_separator = function()
  if jit then
    local os = string.lower(jit.os)
    if os == "linux" or os == "osx" or os == "bsd" then
      return [[/]]
    else
      return [[\]]
    end
  else
    return package.config:sub(1, 1)
  end
end

local default_seperator = get_path_separator()

U.notify = function(...)
  local config = require("dev_comments").config
  if config.debug then vim.notify(...) end
end

U.get_highlight_by_tag = function(tag, fallback)
  local config = require("dev_comments").config
  local hl_name = config.highlight.tags[tag]
  if not hl_name then hl_name = vim.F.if_nil(fallback, config.highlight.fallback) end

  return hl_name
end

U.get_filename_fn = function()
  local bufnr_name_cache = {}
  return function(bufnr)
    bufnr = vim.F.if_nil(bufnr, 0)
    local c = bufnr_name_cache[bufnr]
    if c then return c end

    local n = vim.api.nvim_buf_get_name(bufnr)
    bufnr_name_cache[bufnr] = n
    return n
  end
end

U.get_node_text = function(node, bufnr)
  if not node then return "" end

  return vim.treesitter.get_node_text(node, bufnr)
end

U.get_text_by_range = function(range, bufnr)
  local lines
  local eof_row = vim.api.nvim_buf_line_count(bufnr)
  if range.start_row >= eof_row then return "" end

  if range.end_col == 0 then
    lines = vim.api.nvim_buf_get_lines(bufnr, range.start_row, range.end_row, true)
    range.end_col = -1
  else
    lines = vim.api.nvim_buf_get_lines(bufnr, range.start_row, range.end_row + 1, true)
  end

  if #lines > 0 then
    if #lines == 1 then
      lines[1] = string.sub(lines[1], range.start_col + 1, range.end_col)
    else
      lines[1] = string.sub(lines[1], range.start_col + 1)
    end
    return lines[1]
  end

  return ""
end

U.load_buffers_by_cwd = function(cwd, hidden)
  cwd = cwd or vim.loop.cwd()
  -- TODO: hidden is not implemented
  hidden = vim.F.if_nil(hidden, false)

  local buffer_handles = {}
  for name, type in vim.fs.dir(cwd) do
    if type == "file" then
      local file = cwd .. default_seperator .. name
      local bufnr = bufload_file(file)
      table.insert(buffer_handles, bufnr)
    end
  end

  return buffer_handles
end

U.load_buffers_by_fname = function(file_names)
  if not (type(file_names) == "table") then return end

  local buffer_handles = {}
  for _, name in ipairs(file_names) do
    if get_type(name) == "file" then
      local bufnr = bufload_file(name)
      table.insert(buffer_handles, bufnr)
    end
  end

  return buffer_handles
end

U.filter_buffers = function(buffer_handles, cwd)
  cwd = cwd or vim.loop.cwd()

  if not get_type(cwd) == "directory" then
    U.notify("cwd needs to be a valid directory", vim.log.levels.WARN)
    return buffer_handles
  end

  local get_filename_fn = U.get_filename_fn()
  return vim.tbl_filter(function(bufnr)
    local file_name = get_filename_fn(bufnr)
    if get_type(file_name) == "file" then return file_name:sub(1, #cwd) == cwd end
  end, buffer_handles)
end

U.split = function(...)
  local ok, result = pcall(vim.split, ...)
  if not ok then return nil end
  return result
end

return U
