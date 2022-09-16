local U = {}

-- Load buffer by path
---@param path string File path
---@return number bufnr Buffer number
local bufload_file = function(path)
  local bufnr = vim.fn.bufadd(path)
  -- NOTE: silent is required to avoid E325
  vim.cmd("silent! call bufload(" .. bufnr .. ")")

  return bufnr
end

-- Get file type
---@param path string File path
---@return string # directory or file
local get_type = function(path)
  local stat = vim.loop.fs_stat(path)
  if stat then return stat.type end
end

-- Get path separator depending on OS
---@return string
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

-- Wrapper around vim.notify
-- Only notifies when config.debug is true
---@param ... any # vim.notify() args
U.notify = function(...)
  local config = require("dev_comments").config
  if config.debug then vim.notify(...) end
end

-- Get highlight by tag using tag-highlight map in config
---@param tag string Comment tag
---@param fallback string Fallback highlight name
---@return string hl_name Highlight name
U.get_highlight_by_tag = function(tag, fallback)
  local config = require("dev_comments").config
  local hl_name = config.highlight.tags[tag]
  if not hl_name then hl_name = vim.F.if_nil(fallback, config.highlight.fallback) end

  return hl_name
end

-- Get name of file by buffer
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

-- Wrapper around vim.treesitter.get_node_text
---@param node any # tsnode
---@param bufnr number Buffer number
---@return string node_text Returns empty string if node is nil
U.get_node_text = function(node, bufnr)
  if not node then return "" end

  return vim.treesitter.get_node_text(node, bufnr)
end

---@class Range
---@field start_row number The start row of text
---@field end_row number The end row of text
---@field start_col number The start column of text
---@field end_col number The end column of text

---@param range Range The range of the text
---@param bufnr number The buffer number to get text from
---@return string text
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

-- Loads all files in directory as vim buffers
---@param cwd? string Directory to search in
---@param hidden? boolean Include hidden files (false default)
---@return table bufnrs Buffer numbers
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

-- Loads all file names as vim buffers
---@param file_names table File names
---@return table bufnrs Buffer numbers
U.load_buffers_by_fname = function(file_names)
  vim.validate({ file_names = { file_names, "table" } })

  local buffer_handles = {}
  for _, name in ipairs(file_names) do
    if get_type(name) == "file" then
      local bufnr = bufload_file(name)
      table.insert(buffer_handles, bufnr)
    end
  end

  return buffer_handles
end

-- Filter buffers only in directory
---@param buffer_handles table Buffer numbers
---@param cwd string Directory to filter
---@return table bufnrs Buffer numbers
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

-- Wrapper around vim.split
---comment
---@param ... any
---@return table List of split components
---@return nil nil vim.split call failed
U.split = function(...)
  local ok, result = pcall(vim.split, ...)
  if not ok then return nil end
  return result
end

return U
