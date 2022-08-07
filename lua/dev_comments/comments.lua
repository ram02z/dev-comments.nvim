local C = {}

local cache = require("dev_comments.cache")
local utils = require("dev_comments.utils")

-- Returns table of nodes parsed by "comment" parser
--
-- @param bufnr: the buffer handle
-- @param results: table of results (used for recursive calls)
-- @param opts: table of options from picker
--
-- @returns results: table of nodes parsed by "comment" parser
local finder = function(bufnr, results, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  results = results or {}
  local status, root_lang_tree = pcall(vim.treesitter.get_parser, bufnr)
  if not status then
    vim.notify(root_lang_tree, vim.log.levels.WARN)
    return results
  end

  local comment_lang_tree
  root_lang_tree:for_each_child(function(child, lang)
    if lang == "comment" then
      comment_lang_tree = child
    end
  end)

  if not comment_lang_tree then
    return results
  end

  comment_lang_tree:for_each_tree(function(tree)
    local root_node = tree:root()
    local child_node = root_node:named_child()
    if child_node and child_node:type() == "tag" then
      local tag = utils.get_node_text(child_node:named_child(0), bufnr)
      local user = utils.get_node_text(child_node:named_child(1), bufnr)
      if
        (#opts.tags == 0 or vim.tbl_contains(opts.tags, tag))
        and (#opts.users == 0 or vim.tbl_contains(opts.users, user))
      then
        table.insert(results, {
          node = root_node,
          tag = tag,
          user = user,
          bufnr = bufnr,
        })
      end
    end
  end)

  return results
end

C.generate = function(opts)
  local has_comments_parser = vim.treesitter.require_language("comment", nil, true)
  if not has_comments_parser then
    error("This plugin requires 'comment' parser to be installed. Try running 'TSInstall comment'")
  end

  cache.register()

  opts = opts or {}
  -- open, current, all
  opts.files = vim.F.if_nil(opts.files, "current") -- TODO: rename this option
  opts.cwd = vim.F.if_nil(opts.cwd, vim.loop.cwd())
  opts.hidden = vim.F.if_nil(opts.hidden, false)
  opts.depth = vim.F.if_nil(opts.depth, 3)
  opts.tags = vim.split(opts.tags or "", ",", { trimempty = true })
  opts.users = vim.split(opts.users or "", ",", { trimempty = true })

  local results = cache.get(opts)
  if results then
    vim.notify("cache hit", vim.log.levels.DEBUG)
    return results
  end

  local buffer_handles = {}
  if opts.files == "current" then
    buffer_handles = { vim.api.nvim_get_current_buf() }
  elseif opts.files == "open" then
    buffer_handles = vim.api.nvim_list_bufs()
  elseif opts.files == "all" then
    utils.load_buffers(opts.cwd, opts.hidden, opts.depth)
    buffer_handles = vim.api.nvim_list_bufs()
  end

  -- Only filter buffers if user specifies cwd
  if opts.cwd then
    buffer_handles = utils.filter_buffers(buffer_handles, opts.cwd)
  end

  results = {}
  for _, bufnr in ipairs(buffer_handles) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local hl = vim.treesitter.highlighter.active[bufnr]
      if not hl then
        vim.notify("Treesitter not active on bufnr: " .. bufnr, vim.log.levels.DEBUG)
      end
      results = finder(bufnr, results, opts)
    end
  end

  if not cache.add(results, opts) then
    vim.notify("couldn't add to cache. Cache is either not registered or files is invalid.")
  end

  return results
end

return C
