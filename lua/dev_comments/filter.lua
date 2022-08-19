local F = {}

local utils = require("dev_comments.utils")

-- Greedy pattern capture all uppercase "dev" comments
-- TODO: comment parser doesn't care about trailing space
local default_pattern = [[\b([A-Z]+)(\((.*?)\))?: ]]
local tag_pattern = [[\b(%s)(\((.*?)\))?: ]]
local user_pattern = [[\b([A-Z]+)(\((%s)\)): ]]
local full_pattern = [[\b(%s)(\((%s)\)): ]]

local create_pattern = function(tags, users)
  if #tags == 0 and #users == 0 then
    return default_pattern
  end


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

-- TODO: implement depth search
-- TODO: implement hidden flag (ignores hidden directories by default)
F.match = function(command, cwd, tags, users)
  if vim.fn.executable(command) ~= 1 then
    utils.notify(command .. "not found in PATH", vim.log.levels.WARN)
    return
  end

  cwd = vim.F.if_nil(cwd, vim.loop.cwd())
  tags = vim.F.if_nil(tags, {})
  users = vim.F.if_nil(users, {})

  local Job = require("plenary.job")
  local FilterCommandArgs = require("dev_comments.constants").FilterCommandArgs
  local pattern = create_pattern(tags, users)
  local args = vim.tbl_flatten({ FilterCommandArgs[command], pattern, cwd })
  local job = Job:new({
    command = command,
    args = args,
  })

  local _, ret = job:sync()

  if ret == 0 then
    return job:result()
  elseif ret == 1 then
    utils.notify("No matching comments found from command: " .. command, vim.log.levels.INFO)
    return {}
  elseif ret == 2 then
    local error = table.concat(job:stderr_result(), "\n")
    utils.notify("Failed with code " .. code .. ":" .. error, vim.log.levels.ERROR)
  end
end

return F
