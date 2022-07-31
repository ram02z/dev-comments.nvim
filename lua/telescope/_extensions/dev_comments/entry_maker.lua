local make_entry = require("telescope.make_entry")
local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope._extensions.dev_comments.utils")

local entry_maker = function(opts)
  opts = opts or {}

  local display_items = {
    { width = 8 },
    { width = 6 },
    { width = 8 },
    -- { width = 10 },
    { remaining = true },
  }

  -- TODO: don't rely on this method, since it uses fixed width columns
  local displayer = entry_display.create({
    separator = " ",
    items = display_items,
  })

  -- TODO: add the name of the buffer and line number
  local make_display = function(entry)
    local display_columns = {
      { entry.tag, utils.get_highlight_by_tag(entry.tag), utils.get_highlight_by_tag(entry.tag) },
      { entry.user, "TSConstant" },
      { entry.lnum .. ":" .. entry.col, "TSConstant" },
      -- { entry.filename, "TSConstant" },
      entry.text,
    }

    return displayer(display_columns)
  end

  local get_filename = utils.get_filename_fn()
  return function(entry)
    if not vim.api.nvim_buf_is_loaded(entry.bufnr) then
      return
    end
    local start_row, start_col, end_row, _ = entry.node:range()
    local node_text = utils.get_node_text(entry.node, entry.bufnr)
    -- HACK: keeps only the comment text
    node_text = utils.split_at_first_occurance(node_text, ":")
    return make_entry.set_default_entry_mt({
      bufnr = entry.bufnr,
      value = entry.node,
      tag = entry.tag,
      user = entry.user,
      ordinal = node_text .. " " .. (entry.tag or "unknown"),
      display = make_display,

      node_text = node_text,

      filename = get_filename(entry.bufnr),
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
