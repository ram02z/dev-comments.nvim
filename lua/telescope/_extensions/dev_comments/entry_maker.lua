local utils = require("dev_comments.utils")

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
  local entry_display = require("telescope.pickers.entry_display")
  local displayer = entry_display.create({
    separator = " ",
    items = display_items,
  })

  -- TODO: add the name of the buffer
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
  --- Create entry
  ---@param comment Comment
  ---@return table
  return function(comment)
    if not vim.api.nvim_buf_is_loaded(comment.bufnr) then return end

    local make_entry = require("telescope.make_entry")
    local node_text = utils.get_text_by_range(comment.range, comment.bufnr)
    return make_entry.set_default_entry_mt({
      bufnr = comment.bufnr,
      value = node_text,
      tag = comment.tag,
      user = comment.user,
      ordinal = comment.tag,
      display = make_display,
      filename = get_filename(comment.bufnr),
      -- need to add one since the previewer subtracts one
      lnum = comment.range.start_row + 1,
      col = comment.range.start_col,
      finish = comment.range.end_col,
      text = node_text,
    }, opts)
  end
end

return entry_maker
