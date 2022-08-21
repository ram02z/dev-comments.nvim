local dev_comments = {}

---@brief [[
--- dev-comments.nvim is a plugin that uses the tree-sitter-comment parser to list and search for dev comments
---
---@brief ]]

---@tag dev_comments.nvim
---@config { ["name"] = "INTRODUCTION" }

--- Setup function is required to setup the configuration, load the telescope extension and register the cache
---
--- Default configuration:
--- <code>
--- local Files = require("dev_comments.constants").Files
--- local FilterCommand = require("dev_comments.constants").FilterCommand
---
--- require("dev_comments").setup({
---   debug = false,
---   default_mappings = true,
---   default_commands = true,
---   cache = {
---     enabled = true,
---     reset_autocommands = { "BufWritePost", "BufWinEnter" },
---   },
---   telescope = {
---     load = true,
---     [Files.CURRENT] = {
---       tags = "",
---       users = "",
---     },
---     [Files.OPEN] = {
---       tags = "",
---       users = "",
---     },
---     [Files.ALL] = {
---       hidden = false,
---       depth = 3,
---       tags = "",
---       users = "",
---     },
---   },
---   cycle = {
---     wrap = true,
---   },
---   pre_filter = {
---     command = FilterCommand.RIPGREP,
---     fallback_to_plenary = true,
---   },
---   highlight = {
---     tags = {
---       ["TODO"] = "TSWarning",
---       ["HACK"] = "TSWarning",
---       ["WARNING"] = "TSWarning",
---       ["FIXME"] = "TSDanger",
---       ["XXX"] = "TSDanger",
---       ["BUG"] = "TSDanger",
---     },
---     fallback = "TSNote",
---   },
--- })
--- </code>

local Files = require("dev_comments.constants").Files
local FilterCommand = require("dev_comments.constants").FilterCommand

-- TODO: update telescope config to take table instead of strings
dev_comments.config = {
  debug = false,
  default_mappings = true,
  default_commands = true,
  cache = {
    enabled = true,
    reset_autocommands = { "BufWritePost", "BufWinEnter" },
  },
  telescope = {
    load = true,
    [Files.CURRENT] = {
      tags = "",
      users = "",
    },
    [Files.OPEN] = {
      tags = "",
      users = "",
    },
    [Files.ALL] = {
      hidden = false,
      depth = 3,
      tags = "",
      users = "",
    },
  },
  cycle = {
    wrap = true,
  },
  pre_filter = {
    command = FilterCommand.RIPGREP,
    fallback_to_plenary = true,
  },
  highlight = {
    tags = {
      ["TODO"] = "TSWarning",
      ["HACK"] = "TSWarning",
      ["WARNING"] = "TSWarning",
      ["FIXME"] = "TSDanger",
      ["XXX"] = "TSDanger",
      ["BUG"] = "TSDanger",
    },
    fallback = "TSNote",
  },
}

---@param config table: Configuration options
dev_comments.setup = function(config)
  config = config or {}
  dev_comments.config = vim.tbl_extend("force", dev_comments.config, config)
  if dev_comments.config.default_mappings then require("dev_comments.presets").set_default_mappings() end
  if dev_comments.config.default_commands then require("dev_comments.presets").set_default_commands() end
  if dev_comments.config.telescope.load then require("telescope").load_extension("dev_comments") end
  if dev_comments.config.cache.enabled then require("dev_comments.cache").register() end
end

return dev_comments
