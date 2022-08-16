local F = {}

local utils = require("dev_comments.utils")

-- Greedy pattern capture all uppercase "dev" comments
local default_pattern = [[\b([A-Z]+)(\((.*?)\))?:]]
local fpattern = [[\b(%s)(\((.*?)\))?:]]

local create_pattern = function(tags)
  if #tags == 0 then
    return default_pattern
  end

  local group = table.concat(tags, "|")
  return string.format(fpattern, group)
end

-- TODO: implement depth search
-- TODO: implement hidden flag (ignores hidden directories by default)
F.match = function(command, cwd, tags)
  if vim.fn.executable(command) ~= 1 then
    utils.notify(command .. "not found in PATH", vim.log.levels.WARN)
    return
  end

  cwd = vim.F.if_nil(cwd, vim.loop.cwd())

  local Job = require("plenary.job")
  local FilterCommandArgs = require("dev_comments.constants").FilterCommandArgs
  local pattern = create_pattern(tags)
  local args = vim.tbl_flatten({ FilterCommandArgs[command], pattern, cwd })
  local job = Job:new({
    command = command,
    args = args,
  })

  local _, ret = job:sync()

  if ret == 0 then
    return job:result()
  end
end

return F
