local utils = require("telescope._extensions.dev_comments.utils")

-- Returns table of nodes parsed by "comment" parser
--
-- @param bufnr: the buffer handle
-- @param results: table of results (used for recursive calls)
-- @param opts: table of options from picker
--
-- @returns results: table of nodes parsed by "comment" parser
local finder = function(bufnr, results, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  results = results or {}
  local status, root_lang_tree = pcall(vim.treesitter.get_parser, bufnr)
  if not status then
    vim.notify(root_lang_tree, vim.log.levels.WARN)
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
      local tag = utils.get_node_text(child_node:named_child(0), bufnr)
      local user = utils.get_node_text(child_node:named_child(1), bufnr)
      if
        (#opts.tags == 0 or vim.tbl_contains(opts.tags, tag))
        and (#opts.users == 0 or vim.tbl_contains(opts.users, user))
      then
        table.insert(results, {
          node = root_node,
          tag = tag,
          user = user,
          bufnr = bufnr,
        })
      end
    end
  end)

  return results
end

return finder
