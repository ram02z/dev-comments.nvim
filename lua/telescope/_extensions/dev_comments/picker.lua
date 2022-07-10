local dc_picker = {}

local conf = require("telescope.config").values
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local entry_maker = require("telescope._extensions.dev_comments.entry_maker")
local utils = require("telescope._extensions.dev_comments.utils")

-- Returns table of nodes parsed by "comment" parser
--
-- @param bufnr: the buffer handle
-- @param lang_tree: the buffer's language tree
-- @param results: table of results (used for recursive calls)
--
-- @returns results: table of nodes parsed by "comment" parser
local dev_comments = function(bufnr, lang_tree, results)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local root_lang_tree = lang_tree or vim.treesitter.get_parser(bufnr)
  results = results or {}

  if not root_lang_tree then
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
      })
    end
  end)

  return results
end

dc_picker.picker = function(opts)
  opts.show_line = vim.F.if_nil(opts.show_line, true)

  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  local hl = vim.treesitter.highlighter.active[bufnr]
  if not hl then
    error("Treesitter not active on bufnr: " .. bufnr)
  end

  local results = dev_comments(bufnr)

  if vim.tbl_isempty(results) then
    error("No dev comments on bufnr: " .. bufnr)
  end

  pickers
    .new(opts, {
      prompt_title = "Dev Comments",
      finder = finders.new_table({
        results = results,
        entry_maker = opts.entry_maker or entry_maker(opts),
      }),
      previewer = conf.grep_previewer(opts),
      sorter = conf.prefilter_sorter({
        tag = "tag",
        sorter = conf.generic_sorter(opts),
      }),
    })
    :find()
end

return dc_picker.picker
