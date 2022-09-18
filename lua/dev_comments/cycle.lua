local C = {}

local generate = require("dev_comments.comments").generate
local utils = require("dev_comments.utils")

-- Finds the position of the next dev comment
---@param wrap boolean Should wrap around
---@param opts Opts
---@param forward boolean Forward search
---@return number[] pos row and column
---@private
local function next_dev_comment(wrap, opts, forward)
  local config = require("dev_comments").config
  wrap = vim.F.if_nil(wrap, config.cycle.wrap)

  -- NOTE: comments are sorted in ascending order
  local comments = generate("current", opts)
  if #comments == 0 then return end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  local start_i, end_i, inc_i
  if forward then
    start_i = 1
    end_i = #comments
    inc_i = 1
  else
    start_i = #comments
    end_i = 1
    inc_i = -1
  end

  local index, comment_range, node_row, node_start_col, node_end_col
  for i = start_i, end_i, inc_i do
    local entry = comments[i]
    node_row, node_start_col, node_end_col = entry.range.start_row, entry.range.start_col, entry.range.end_col
    node_row = node_row + 1
    index = i
    if forward and row <= node_row then
      if row ~= node_row or (col < node_start_col and col < node_end_col) then
        comment_range = { node_row, node_start_col }
        break
      end
    elseif not forward and row >= node_row then
      if row ~= node_row or (col > node_start_col and col > node_end_col) then
        comment_range = { node_row, node_start_col }
        break
      end
    end
  end

  if comment_range == nil and wrap then
    utils.notify("Reached the last node. Wrapping around.", vim.log.levels.INFO)
    if forward then
      index = 1
      node_row, node_start_col = comments[1].range.start_row, comments[1].range.start_col
    else
      index = #comments
      node_row, node_start_col = comments[#comments].range.start_row, comments[#comments].range.start_col
    end
    node_row = node_row + 1

    comment_range = { node_row, node_start_col }
  end

  if comment_range ~= nil then
    vim.api.nvim_echo({ { string.format("Comment %d of %d", index, #comments), "None" } }, false, {})
    return comment_range
  end
end

-- Move cursor to position
---@param pos number[] row and column
---@private
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

-- Move cursor to previous dev comment
---@param wrap boolean Should wrap around
---@param opts Opts
C.goto_prev = function(wrap, opts)
  local pos = next_dev_comment(wrap, opts, false)
  moveto_pos(pos)
end

-- Move cursor to next dev comment
---@param wrap boolean Should wrap around
---@param opts Opts
C.goto_next = function(wrap, opts)
  local pos = next_dev_comment(wrap, opts, true)
  moveto_pos(pos)
end

return C
