local C = {}

local comments = require("dev_comments.comments")
local utils = require("dev_comments.utils")

local function next_dev_comment(wrap, opts, forward)
  local config = require("dev_comments").config
  wrap = vim.F.if_nil(wrap, config.cycle.wrap)

  -- NOTE: results are sorted in ascending order
  local results = comments.generate("current", opts)
  if #results == 0 then return end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

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

  local index, result_range, node_row, node_start_col, node_end_col
  for i = start_i, end_i, inc_i do
    local entry = results[i]
    node_row, node_start_col, node_end_col = entry.range.start_row, entry.range.start_col, entry.range.end_col
    node_row = node_row + 1
    index = i
    if forward and row <= node_row then
      if row ~= node_row or (col < node_start_col and col < node_end_col) then
        result_range = { node_row, node_start_col }
        break
      end
    elseif not forward and row >= node_row then
      if row ~= node_row or (col > node_start_col and col > node_end_col) then
        result_range = { node_row, node_start_col }
        break
      end
    end
  end

  if result_range == nil and wrap then
    utils.notify("Reached the last node. Wrapping around.", vim.log.levels.INFO)
    if forward then
      index = 1
      node_row, node_start_col = results[1].range.start_row, results[1].range.start_col
    else
      index = #results
      node_row, node_start_col = results[#results].range.start_row, results[#results].range.start_col
    end
    node_row = node_row + 1

    result_range = { node_row, node_start_col }
  end

  if result_range ~= nil then
    vim.api.nvim_echo({ { string.format("Comment %d of %d", index, #results), "None" } }, false, {})
    return result_range
  end
end

local function moveto_pos(pos)
  local win_id = vim.api.nvim_get_current_win()

  if not pos then
    vim.notify_once("No dev comments to move to", vim.log.levels.WARN)
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
