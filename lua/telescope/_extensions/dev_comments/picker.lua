local dc_picker = {}

local conf = require("telescope.config").values
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local entry_maker = require("telescope._extensions.dev_comments.entry_maker")
local finder = require("telescope._extensions.dev_comments.finder")

dc_picker.picker = function(opts)
  opts.show_line = vim.F.if_nil(opts.show_line, true)

  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  local hl = vim.treesitter.highlighter.active[bufnr]
  if not hl then
    vim.notify("Treesitter not active on bufnr: " .. bufnr, vim.log.levels.WARN)
  end

  local results = finder(bufnr)

  if vim.tbl_isempty(results) then
    vim.notify("No dev comments on bufnr: " .. bufnr, vim.log.levels.WARN)
  end

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
