local C = {}

local Files = require("dev_comments.constants").Files
local cache = require("dev_comments.cache")
local utils = require("dev_comments.utils")
local filter = require("dev_comments.filter")

---@class Opts table of options used by comments.generate
---@field files string
---@field cwd string
---@field hidden boolean
---@field tags string[]
---@field users string[]

---@class Results table of results returned by comments.generate
---@field tag string
---@field user string
---@field range Range
---@field bufnr number Buffer number

---@class Range
---@field start_row number The start row of text
---@field end_row number The end row of text
---@field start_col number The start column of text
---@field end_col number The end column of text

-- Get named child node text
---@param node any # tsnode
---@param name string child node type
---@param bufnr? number defaults to 0
---@return string child node text
---@private
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

-- Sort results in ascending order of position
---@param results Results
---@return Results
---@private
local sort_results = function(results)
  local t = {}
  for _, v in pairs(results) do
    table.insert(t, v)
  end

  table.sort(t, function(a, b)
    if a.range.start_row ~= b.range.start_row then return a.range.start_row < a.range.start_row end

    return a.range.start_col < a.range.start_col
  end)

  return t
end

-- Returns table of nodes parsed by "comment" parser
---@param bufnr number buffer number
---@param results Results # used for recursive calls
---@param opts table of options from picker
---@returns results Results
---@private
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
    local end_row, end_col = root_node:end_()
    for i = root_node:named_child_count() - 1, 0, -1 do
      local child_node = root_node:named_child(i)
      local child_end_row, child_end_col = child_node:end_()
      -- NOTE: Assumes that this node spans till the end of the line
      if child_end_col > end_col then
        local line = vim.api.nvim_buf_get_lines(bufnr, child_end_row, child_end_row + 1, false)
        if line[1] then end_col = #line[1] end
      end
      local range = { start_row = child_end_row, start_col = child_end_col, end_row = end_row, end_col = end_col }
      end_row, end_col = child_node:start()
      if child_node:named() and child_node:type() == "tag" then
        local tag = get_named_child_node_text(child_node, "name", bufnr)
        local user = get_named_child_node_text(child_node, "user", bufnr)
        if
          (#opts.tags == 0 or vim.tbl_contains(opts.tags, tag))
          and (#opts.users == 0 or vim.tbl_contains(opts.users, user))
        then
          table.insert(results, {
            tag = tag,
            user = user,
            range = range,
            bufnr = bufnr,
          })
        end
      end
    end
  end)

  return sort_results(results)
end

-- Updates options table
---@param files string # @see constants.Files
---@param opts Opts
---@private
local set_opts = function(files, opts)
  local config = require("dev_comments").config
  if opts.cwd ~= nil then opts.cwd = vim.fn.expand(opts.cwd) end
  opts.hidden = vim.F.if_nil(opts.hidden, config.telescope[files].hidden)
  opts.tags = utils.split(opts.tags, ",", { trimempty = true }) or config.telescope[files].tags
  opts.users = utils.split(opts.users, ",", { trimempty = true }) or config.telescope[files].users
end

-- Generate results table based on options
---@param files string # @see constants.Files
---@param opts Opts
---@return table
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
    local file_names = filter.match(config.pre_filter.command, opts.cwd, opts.tags, opts.users)
    -- FIXME: which cases are handled for the fallback?
    if not file_names and config.pre_filter.fallback_to_scan_dir then
      buffer_handles = utils.load_buffers_by_cwd(opts.cwd, opts.hidden)
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
