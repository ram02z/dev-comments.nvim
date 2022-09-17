local C = {}

local Files = require("dev_comments.constants").Files

local registered = false
local cache = { [Files.ALL] = {}, [Files.CURRENT] = {}, [Files.OPEN] = {} }

-- Hash function using opts table
---@param opts Opts
---@return string
---@private
local hash_func = function(opts)
  local cwd = opts.cwd
  local hidden = tostring(opts.hidden)
  local tags = table.concat(opts.tags)
  local users = table.concat(opts.users)
  return string.format("cwd=%s-hidden=%s-tags=%s-users=%s", cwd, hidden, tags, users)
end

-- Add entry to cache
---@param entry Results
---@param opts Opts
---@return boolean Added to cache
---@private
C.add = function(entry, opts)
  if not registered then return false end
  local hash = hash_func(opts)
  if not opts.files then return false end

  cache[opts.files][hash] = entry
  return true
end

-- Get entry from cache
---@param opts Opts
---@return Results
---@private
C.get = function(opts)
  if not registered then return nil end
  local hash = hash_func(opts)
  if not opts.files then return nil end
  return cache[opts.files][hash]
end

-- Reset cache entry
---@param files_opt string @see constants.Files
---@private
C.reset = function(files_opt)
  if cache[files_opt] ~= nil then cache[files_opt] = {} end
end

-- Register cache and set reset autocommands
---@return boolean Cache is registered
C.register = function()
  if registered then return false end
  local config = require("dev_comments").config
  local id = vim.api.nvim_create_augroup("DevComments", { clear = true })
  vim.api.nvim_create_autocmd(config.cache.reset_autocommands, {
    callback = function()
      C.reset(Files.CURRENT)
      C.reset(Files.OPEN)
      C.reset(Files.ALL)
    end,
    group = id,
  })
  registered = true
  return true
end

-- Unregister cache
---@return boolean Cache is unregistered
C.unregister = function()
  if not registered then return false end
  vim.api.nvim_del_augroup_by_name("DevComments")
  registered = false
  return true
end

return C
