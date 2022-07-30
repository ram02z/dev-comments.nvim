local dc_utils = {}

local comment_tag_highlight = {
  ["TODO"] = "TSWarning",
  ["HACK"] = "TSWarning",
  ["WARNING"] = "TSWarning",
  ["FIXME"] = "TSDanger",
  ["XXX"] = "TSDanger",
  ["BUG"] = "TSDanger",
}

dc_utils.get_highlight_by_tag = function(tag)
  local hl_name = comment_tag_highlight[tag]
  if not hl_name then
    hl_name = "TSNote"
  end

  return hl_name
end

dc_utils.get_filename_fn = function()
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

dc_utils.get_node_text = function(node, bufnr)
  if not node then
    return ""
  end

  return vim.treesitter.get_node_text(node, bufnr)
end

dc_utils.load_buffers = function(cwd)
  cwd = cwd or vim.loop.cwd()

  local S = require("plenary.scandir")
  local files = S.scan_dir(cwd, { hidden = true })

  local P = require("plenary.path")
  for _, file_path in ipairs(files) do
    local file = P:new(file_path)
    local bufnr, file_name
    if file:is_file() then
      file_name = file:expand()
      bufnr = vim.fn.bufadd(file_name)
      vim.fn.bufload(bufnr)
      vim.notify("Loaded file: " .. file_name, vim.log.levels.DEBUG)
    end
  end
end

return dc_utils
