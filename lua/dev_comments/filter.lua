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
F.match = function(cb, command, cwd, tags)
  if vim.fn.executable(command) ~= 1 then
    utils.notify(command .. "not found in PATH", vim.log.levels.WARN)
    return
  end

  local J = require("plenary.job")
  local FilterCommandArgs = require("dev_comments.constants").FilterCommandArgs
  local pattern = create_pattern(tags)
  local args = vim.tbl_flatten({ FilterCommandArgs[command], pattern, cwd })
  J:new({
    command = command,
    args = args,
    on_exit = vim.schedule_wrap(function(j, code)
      if code == 2 then
        local error = table.concat(j:stderr_result(), "\n")
        utils.notify("Failed with code " .. code .. ":" .. error, vim.log.levels.ERROR)
      elseif code == 1 then
        utils.notify("No matching comments found", vim.log.levels.INFO)
      else
        cb(j:result(), cwd)
      end
    end),
  }):start()
end

return F
