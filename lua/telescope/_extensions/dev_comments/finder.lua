local utils = require("telescope._extensions.dev_comments.utils")

-- Returns table of nodes parsed by "comment" parser
--
-- @param bufnr: the buffer handle
-- @param results: table of results (used for recursive calls)
-- @param lang_tree: the buffer's language tree
--
-- @returns results: table of nodes parsed by "comment" parser
local finder = function(bufnr, results, lang_tree)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  results = results or {}
  local status, result = pcall(vim.treesitter.get_parser, bufnr)
  if not status then
    vim.notify(result, vim.log.levels.WARN)
    return results
  end

  local root_lang_tree = result or lang_tree
  if not root_lang_tree then
    vim.notify("LanguageTree is nil for bufnr: " .. bufnr, vim.log.levels.WARN)
    return results
  end

  local comment_lang_tree
  root_lang_tree:for_each_child(function(child, lang)
    if lang == "comment" then
      comment_lang_tree = child
    end
  end)

  if not comment_lang_tree then
    return results
  end

  comment_lang_tree:for_each_tree(function(tree)
    local root_node = tree:root()
    local child_node = root_node:named_child()
    if child_node and child_node:type() == "tag" then
      table.insert(results, {
        node = root_node,
        tag = utils.get_node_text(child_node:named_child(0), bufnr),
        user = utils.get_node_text(child_node:named_child(1), bufnr),
        bufnr = bufnr,
      })
    end
  end)

  return results
end

return finder