local dc_picker = {}

local entry_maker = require("telescope._extensions.dev_comments.entry_maker")
local finder = require("telescope._extensions.dev_comments.finder")
local utils = require("telescope._extensions.dev_comments.utils")

dc_picker.picker = function(opts)
  local has_comments_parser = vim.treesitter.require_language("comment", nil, true)
  if not has_comments_parser then
    error("This plugin requires 'comment' parser to be installed. Try running 'TSInstall comment'")
  end

  -- open, current, all
  opts.files = vim.F.if_nil(opts.files, "current") -- TODO: rename this option
  opts.cwd = vim.F.if_nil(opts.cwd, nil)
  opts.hidden = vim.F.if_nil(opts.hidden, false)
  opts.depth = vim.F.if_nil(opts.depth, 3)
  opts.tags = vim.split(opts.tags or "", ",", { trimempty = true })
  opts.users = vim.split(opts.users or "", ",", { trimempty = true })

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

  local results = {}
  for _, bufnr in ipairs(buffer_handles) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local hl = vim.treesitter.highlighter.active[bufnr]
      if not hl then
        vim.notify("Treesitter not active on bufnr: " .. bufnr, vim.log.levels.DEBUG)
      end
      results = finder(bufnr, results, opts)
    end
  end

  if vim.tbl_isempty(results) then
    vim.notify("No dev comments found", vim.log.levels.INFO)
  end

  local conf = require("telescope.config").values
  local finders = require("telescope.finders")
  local pickers = require("telescope.pickers")
  pickers
    .new(opts, {
      prompt_title = "Dev Comments",
      finder = finders.new_table({
        results = results,
        entry_maker = opts.entry_maker or entry_maker(opts),
      }),
      previewer = conf.grep_previewer(opts),
      sorter = conf.prefilter_sorter({
        tag = "tag",
        sorter = conf.generic_sorter(opts),
      }),
    })
    :find()
end

return dc_picker.picker
