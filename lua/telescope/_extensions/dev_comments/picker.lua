local dc_picker = {}

local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local entry_display = require("telescope.pickers.entry_display")

local comment_type_highlight = {
  ["TODO"] = "TSWarning",
  ["HACK"] = "TSWarning",
  ["WARNING"] = "TSWarning",
  ["FIXME"] = "TSDanger",
  ["XXX"] = "TSDanger",
  ["BUG"] = "TSDanger",
}

local get_filename_fn = function()
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

local entry_maker = function(opts)
  opts = opts or {}

  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  local display_items = {
    { width = 10 },
    { remaining = true },
  }

  if opts.show_line then
    table.insert(display_items, 2, { width = 6 })
  end

  local displayer = entry_display.create({
    separator = " ",
    items = display_items,
  })

  local type_highlight = opts.symbol_highlights or comment_type_highlight

  local make_display = function(entry)
    local msg = vim.api.nvim_buf_get_lines(bufnr, entry.lnum, entry.lnum, false)[1] or ""
    msg = vim.trim(msg)

    -- HACK: keeps only the comment
    local comment = string.match(entry.text, "^.*%:(.*)")

    local display_columns = {
      { entry.kind, type_highlight[entry.kind] or "TSNote", type_highlight[entry.kind] or "TSNote" },
      comment or entry.text,
      msg,
    }

    if entry.user then
      table.insert(display_columns, 2, { entry.user, "TSConstant" })
    end

    return displayer(display_columns)
  end

  local get_filename = get_filename_fn()
  return function(entry)
    local ts_utils = require("nvim-treesitter.ts_utils")
    local start_row, start_col, end_row, _ = ts_utils.get_node_range(entry.node)
    local node_text = vim.treesitter.get_node_text(entry.node, bufnr)
    return make_entry.set_default_entry_mt({
      value = entry.node,
      kind = entry.kind,
      user = entry.user,
      ordinal = node_text .. " " .. (entry.kind or "unknown"),
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

local get_node_text = function(node, bufnr)
  if not node then
    return ""
  end

  return vim.treesitter.get_node_text(node, bufnr)
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
  root_lang_tree = lang_tree or vim.treesitter.get_parser(bufnr)
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
        kind = get_node_text(child_node:named_child(0), bufnr),
        user = get_node_text(child_node:named_child(1), bufnr),
      })
    end
  end)

  return results
end

dc_picker.picker = function(opts)
  opts.show_line = vim.F.if_nil(opts.show_line, true)
  opts.symbol_highlights = comment_type_highlight


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
        tag = "kind",
        sorter = conf.generic_sorter(opts),
      }),
    })
    :find()
end

return dc_picker.picker
