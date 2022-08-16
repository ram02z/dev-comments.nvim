local U = {}

local comment_tag_highlight = {
  ["TODO"] = "TSWarning",
  ["HACK"] = "TSWarning",
  ["WARNING"] = "TSWarning",
  ["FIXME"] = "TSDanger",
  ["XXX"] = "TSDanger",
  ["BUG"] = "TSDanger",
}

U.notify = function(msg, level, opts)
  local config = require("dev_comments").config
  if config.debug then
    vim.notify(msg, level, opts)
  end
end

U.get_highlight_by_tag = function(tag)
  local hl_name = comment_tag_highlight[tag]
  if not hl_name then
    hl_name = "TSNote"
  end

  return hl_name
end

U.get_filename_fn = function()
  local bufnr_name_cache = {}
  return function(bufnr)
    bufnr = vim.F.if_nil(bufnr, 0)
    local c = bufnr_name_cache[bufnr]
    if c then
      return c
    end

    local n = vim.api.nvim_buf_get_name(bufnr)
    bufnr_name_cache[bufnr] = n
    return n
  end
end

U.get_node_text = function(node, bufnr)
  if not node then
    return ""
  end

  return vim.treesitter.get_node_text(node, bufnr)
end

U.load_buffers_by_cwd = function(cwd, hidden, depth)
  cwd = cwd or vim.loop.cwd()
  hidden = vim.F.if_nil(hidden, false)
  depth = vim.F.if_nil(depth, 3)

  local S = require("plenary.scandir")
  local files = S.scan_dir(cwd, { hidden = hidden, depth = depth })

  local buffer_handles = {}
  local P = require("plenary.path")
  for _, file_path in ipairs(files) do
    local file = P:new(file_path)
    local bufnr
    if file:is_file() then
      bufnr = vim.fn.bufadd(file:expand())
      -- NOTE: silent is required to avoid E325
      vim.cmd("silent! call bufload(" .. bufnr .. ")")
      table.insert(buffer_handles, bufnr)
      -- vim.fn.bufload(bufnr)
      -- vim.notify("Loaded file: " .. file_name, vim.log.levels.DEBUG)
    end
  end

  return buffer_handles
end

U.load_buffers_by_fname = function(file_names)
  if not (type(file_names) == "table") then
    return
  end

  local buffer_handles = {}
  local P = require("plenary.path")
  for _, file_name in ipairs(file_names) do
    local file = P:new(file_name)
    local bufnr
    if file:is_file() then
      bufnr = vim.fn.bufadd(file:expand())
      -- NOTE: silent is required to avoid E325
      vim.cmd("silent! call bufload(" .. bufnr .. ")")
      table.insert(buffer_handles, bufnr)
    end
  end

  return buffer_handles
end

U.filter_buffers = function(buffer_handles, cwd)
  cwd = cwd or vim.loop.cwd()

  local P = require("plenary.path")
  local status, dir = pcall(P.new, cwd)
  if not status then
    U.notify("cwd is invalid", vim.log.levels.WARN)
    return buffer_handles
  end

  -- TODO: should this be an error?
  if not dir:is_dir() then
    U.notify("cwd needs to be a valid directory", vim.log.levels.WARN)
    return buffer_handles
  end

  local dir_path = dir:expand()
  local get_filename_fn = U.get_filename_fn()
  return vim.tbl_filter(function(bufnr)
    local file_name = get_filename_fn(bufnr)
    local file = P:new(file_name)
    if file:is_file() then
      -- if file is not relative to the directory, it is not contained in it
      return file:make_relative(dir_path) ~= file_name
    end
  end, buffer_handles)
end

U.split_at_first_occurance = function(s, sep)
  local t = vim.split(s, sep, { trimempty = true })
  if #t == 0 then
    return s
  end

  s = table.concat(t, "", 2, #t)
  return vim.split(s, "\n")[1]
end

return U
