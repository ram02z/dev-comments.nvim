local C = {}

local comments = require("dev_comments.comments")
local utils = require("dev_comments.utils")

local function next_dev_comment(wrap, opts, forward)
  local config = require("dev_comments").config
  wrap = vim.F.if_nil(wrap, config.cycle.wrap)

  -- assumes results are in ascending line order
  local results = comments.generate("current", opts)
  if #results == 0 then return end

  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))

  local start_i, end_i, inc_i
  if forward then
    start_i = 1
    end_i = #results
    inc_i = 1
  else
    start_i = #results
    end_i = 1
    inc_i = -1
  end

  local node_row, node_col
  for i = start_i, end_i, inc_i do
    local entry = results[i]
    node_row, node_col = entry.range.start_row, entry.range.start_col
    node_row = node_row + 1
    if forward and row < node_row then
      return { node_row, node_col }
    elseif not forward and row > node_row then
      return { node_row, node_col }
    end
  end

  if wrap then
    utils.notify("Reached the last node. Wrapping around.", vim.log.levels.INFO)
    if forward then
      node_row, node_col = results[1].range.start_row, results[1].range.start_col
    else
      node_row, node_col = results[#results].range.start_row, results[#results].range.start_col
    end
    node_row = node_row + 1

    return { node_row, node_col }
  end
end

local function moveto_pos(pos)
  local win_id = vim.api.nvim_get_current_win()

  if not pos then
    utils.notify("No dev comments to move to", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_win_call(win_id, function()
    -- Save position in the window's jumplist
    vim.cmd("normal! m'")
    vim.api.nvim_win_set_cursor(win_id, { pos[1], pos[2] })
    -- Open folds under the cursor
    vim.cmd("normal! zv")
  end)
end

C.goto_prev = function(wrap, opts)
  local pos = next_dev_comment(wrap, opts, false)
  moveto_pos(pos)
end

C.goto_next = function(wrap, opts)
  local pos = next_dev_comment(wrap, opts, true)
  moveto_pos(pos)
end

return C
