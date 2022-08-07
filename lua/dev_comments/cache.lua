-- TODO: Reset the cache on InsertCharPre?

C = {}

local registered = false
local cache = { ["all"] = {}, ["current"] = {}, ["open"] = {} }

local hash_func = function(opts)
  local cwd = opts.cwd
  local hidden = tostring(opts.hidden)
  local depth = tostring(opts.depth)
  local tags = table.concat(opts.tags)
  local users = table.concat(opts.users)
  return string.format("cwd=%s-hidden=%s-depth=%s-tags=%s-users=%s", cwd, hidden, depth, tags, users)
end

C.add = function(entries, opts)
  if not registered then
    return false
  end
  local hash = hash_func(opts)
  if not opts.files then
    return false
  end

  cache[opts.files][hash] = entries
  return true
end

C.get = function(opts)
  if not registered then
    return nil
  end
  local hash = hash_func(opts)
  if not opts.files then
    return nil
  end
  return cache[opts.files][hash]
end

-- TODO: check if files_opt is actually an option?
C.reset = function(files_opt)
  cache[files_opt] = {}
end

C.register = function()
  if registered then
    return
  end
  local id = vim.api.nvim_create_augroup("DevComments", { clear = true })
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    callback = function()
      C.reset("current")
      C.reset("open")
      C.reset("all")
    end,
    group = id,
  })
  registered = true
end

C.unregister = function()
  if not registered then
    return
  end
  vim.api.nvim_del_augroup_by_name("DevComments")
  registered = false
end

return C