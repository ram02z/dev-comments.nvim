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

return dc_utils
