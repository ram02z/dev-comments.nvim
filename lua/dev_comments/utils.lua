local U = {}

local comment_tag_highlight = {
  ["TODO"] = "TSWarning",
  ["HACK"] = "TSWarning",
  ["WARNING"] = "TSWarning",
  ["FIXME"] = "TSDanger",
  ["XXX"] = "TSDanger",
  ["BUG"] = "TSDanger",
}

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

U.load_buffers = function(cwd, hidden, depth)
  cwd = cwd or vim.loop.cwd()
  hidden = hidden or false
  depth = depth or 3

  local S = require("plenary.scandir")
  local files = S.scan_dir(cwd, { hidden = hidden, depth = depth })

  local P = require("plenary.path")
  for _, file_path in ipairs(files) do
    local file = P:new(file_path)
    local bufnr, file_name
    if file:is_file() then
      file_name = file:expand()
      bufnr = vim.fn.bufadd(file_name)
      -- NOTE: silent is required to avoid E325
      vim.cmd("silent! call bufload(" .. bufnr .. ")")
      -- vim.fn.bufload(bufnr)
      -- vim.notify("Loaded file: " .. file_name, vim.log.levels.DEBUG)
    end
  end
end

U.filter_buffers = function(buffer_handles, cwd)
  cwd = cwd or vim.loop.cwd()

  local P = require("plenary.path")
  local status, dir = pcall(P.new, cwd)
  if not status then
    vim.notify("cwd is invalid")
    return buffer_handles
  end

  -- TODO: should this be an error?
  if not dir:is_dir() then
    vim.notify("cwd needs to be a valid directory", vim.log.levels.WARN)
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
