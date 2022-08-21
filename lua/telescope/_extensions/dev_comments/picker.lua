local dc_picker = {}

local Files = require("dev_comments.constants").Files
local entry_maker = require("telescope._extensions.dev_comments.entry_maker")
local comments = require("dev_comments.comments")
local utils = require("dev_comments.utils")

local create = function(results, opts)
  if vim.tbl_isempty(results) then utils.notify("No dev comments found", vim.log.levels.INFO) end

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

local picker = function(files, opts)
  local results = comments.generate(files, opts)
  create(results, opts)
end

dc_picker.current = function(opts)
  picker(Files.CURRENT, opts)
end

dc_picker.open = function(opts)
  picker(Files.OPEN, opts)
end

dc_picker.all = function(opts)
  picker(Files.ALL, opts)
end

return dc_picker
