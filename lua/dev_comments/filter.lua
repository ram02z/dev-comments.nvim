local F = {}

local utils = require("dev_comments.utils")

-- Greedy pattern capture all uppercase "dev" comments
local default_pattern = [[\b([A-Z_-]+)(\((.*?)\))?: ]]
local tag_pattern = [[\b(%s)(\((.*?)\))?: ]]
local user_pattern = [[\b([A-Z_-]+)(\((%s)\)): ]]
local full_pattern = [[\b(%s)(\((%s)\)): ]]

-- Creates pattern depending on params
---@param tags string[]
---@param users string[]
---@return string default or generated pattern
---@private
local create_pattern = function(tags, users)
  if #tags == 0 and #users == 0 then return default_pattern end

  local tag_group = table.concat(tags, "|")
  local user_group = table.concat(users, "|")
  if #tags > 0 and #users > 0 then
    return string.format(full_pattern, tag_group, user_group)
  elseif #tags > 0 then
    return string.format(tag_pattern, tag_group)
  elseif #users > 0 then
    return string.format(user_pattern, user_group)
  end
end

-- Match dev comments using system search tool
---@param command string # @see constants.FilterCommand
---@param cwd? string # defaults to current working directory
---@param tags? string[] # defaults to empty list
---@param users? string[] # defaults to empty list
---@return string[] list of files with dev comments
F.match = function(command, cwd, tags, users)
  if vim.fn.executable(command) ~= 1 then
    utils.notify(command .. "not found in PATH", vim.log.levels.WARN)
    return
  end

  cwd = vim.F.if_nil(cwd, vim.loop.cwd())
  tags = vim.F.if_nil(tags, {})
  users = vim.F.if_nil(users, {})
  -- TODO: implement hidden flag (rg ignores hidden directories by default but grep doesn't)

  local FilterCommandArgs = require("dev_comments.constants").FilterCommandArgs
  local pattern = create_pattern(tags, users)
  local cmd = vim.tbl_flatten({ command, FilterCommandArgs[command], pattern, cwd })

  local result = vim.fn.systemlist(cmd)
  if vim.v.shell_error == 0 then
    return result
  elseif vim.v.shell_error == 1 then
    utils.notify("No matching comments found from command: " .. table.concat(cmd, " "), vim.log.levels.INFO)
    return {}
  else
    error("Failed with code " .. vim.v.shell_error .. "\nCommand: " .. table.concat(cmd, " "))
  end
end

return F
