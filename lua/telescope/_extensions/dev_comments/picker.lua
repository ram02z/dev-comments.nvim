local dc_picker = {}

local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope._extensions.dev_comments.utils")

local entry_maker = function(opts)
  opts = opts or {}

  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  local display_items = {
    { width = 8 },
    { width = 8 },
    { remaining = true },
  }

  local displayer = entry_display.create({
    separator = " ",
    items = display_items,
  })

  local make_display = function(entry)

    local display_columns = {
      { entry.tag, utils.get_highlight_by_tag(entry.tag), utils.get_highlight_by_tag(entry.tag) },
      { entry.user, "TSConstant" },
      entry.text,
    }

    return displayer(display_columns)
  end

  local get_filename = utils.get_filename_fn()
  return function(entry)
    local start_row, start_col, end_row, _ = entry.node:range()
    local node_text = utils.get_node_text(entry.node, bufnr)
    -- HACK: keeps only the comment text
    node_text = node_text:match("^.*%:(.*)")
    return make_entry.set_default_entry_mt({
      value = entry.node,
      tag = entry.tag,
      user = entry.user,
      ordinal = node_text .. " " .. (entry.tag or "unknown"),
      display = make_display,

      node_text = node_text,

      filename = get_filename(bufnr),
      -- need to add one since the previewer subtracts one
      lnum = start_row + 1,
      col = start_col,
      text = node_text,
      start = start_row,
      finish = end_row,
    }, opts)
  end
end

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
