local C = {}

local Files = require("dev_comments.constants").Files
local cache = require("dev_comments.cache")
local utils = require("dev_comments.utils")
local filter = require("dev_comments.filter")

local get_named_child_node_text = function(node, name, bufnr)
  bufnr = bufnr or 0
  local node_text = ""
  for child_node in node:iter_children() do
    if child_node:named() and child_node:type() == name then
      node_text = utils.get_node_text(child_node, bufnr)
      break
    end
  end

  return node_text
end

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
    utils.notify(root_lang_tree, vim.log.levels.WARN)
    return results
  end

  local comment_lang_tree
  root_lang_tree:for_each_child(function(child, lang)
    if lang == "comment" then comment_lang_tree = child end
  end)

  if not comment_lang_tree then return results end

  comment_lang_tree:for_each_tree(function(tree)
    local root_node = tree:root()
    for child_node in root_node:iter_children() do
      if child_node:named() and child_node:type() == "tag" then
        local tag = get_named_child_node_text(child_node, "name", bufnr)
        local user = get_named_child_node_text(child_node, "user", bufnr)
        if
          (#opts.tags == 0 or vim.tbl_contains(opts.tags, tag))
          and (#opts.users == 0 or vim.tbl_contains(opts.users, user))
        then
          -- FIXME(ozeghouani): if a comment node contains two tag nodes, it will get the text of the comment node
          table.insert(results, {
            node = root_node,
            tag = tag,
            user = user,
            bufnr = bufnr,
          })
        end
      end
    end
  end)

  return results
end

local set_opts = function(files, opts)
  local config = require("dev_comments").config
  if opts.cwd ~= nil then opts.cwd = vim.fn.expand(opts.cwd) end
  opts.hidden = vim.F.if_nil(opts.hidden, config.telescope[files].hidden)
  opts.depth = vim.F.if_nil(opts.depth, config.telescope[files].depth)
  opts.tags = vim.split(opts.tags or config.telescope[files].tags, ",", { trimempty = true })
  opts.users = vim.split(opts.users or config.telescope[files].users, ",", { trimempty = true })
end

C.generate = function(files, opts)
  local has_comments_parser = vim.treesitter.require_language("comment", nil, true)
  if not has_comments_parser then
    error("This plugin requires 'comment' parser to be installed. Try running 'TSInstall comment'")
  end

  opts = opts or {}
  opts.files = files
  set_opts(files, opts)

  local results = cache.get(opts)
  if results then
    utils.notify("cache hit", vim.log.levels.DEBUG)
    return results
  end

  local buffer_handles = {}
  local config = require("dev_comments").config
  if opts.files == Files.CURRENT then
    buffer_handles = { vim.api.nvim_get_current_buf() }
  elseif opts.files == Files.OPEN then
    buffer_handles = vim.api.nvim_list_bufs()
    if opts.cwd then buffer_handles = utils.filter_buffers(buffer_handles, opts.cwd) end
  elseif opts.files == Files.ALL then
    file_names = filter.match(config.pre_filter.command, opts.cwd, opts.tags, opts.users)
    -- FIXME: which cases are handled for the fallback?
    if not file_names and config.pre_filter.fallback_to_plenary then
      buffer_handles = utils.load_buffers_by_cwd(opts.cwd, opts.hidden, opts.depth)
    else
      buffer_handles = utils.load_buffers_by_fname(file_names)
    end
  end

  results = {}
  for _, bufnr in ipairs(buffer_handles) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local hl = vim.treesitter.highlighter.active[bufnr]
      if not hl then utils.notify("Treesitter not active on bufnr: " .. bufnr, vim.log.levels.DEBUG) end
      results = finder(bufnr, results, opts)
    end
  end

  if not cache.add(results, opts) then
    utils.notify("couldn't add to cache. Cache is either not registered or files is invalid.")
  end

  return results
end

return C
