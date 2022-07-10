local make_entry = require("telescope.make_entry")
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

return entry_maker
