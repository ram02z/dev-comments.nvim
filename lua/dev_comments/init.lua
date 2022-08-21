--- Table of contents:
---@toc
---@text

--- # Abstract~
---
--- *dev-comments.nvim* is a plugin that uses the tree-sitter-comment parser to
--- list and search for dev comments
---
--- Author: Omar Zeghouani
--- License: MIT
---
---@tag dev-comments
---@toc_entry Abstract
-- Requires ===================================================================
local dev_comments = {}
local Files = require("dev_comments.constants").Files
local FilterCommand = require("dev_comments.constants").FilterCommand

-- Module definition ==========================================================

--- Module setup
---
---@param config table|nil configuration options. See |dev-comments-configuration|
---
---@usage `require("dev_comments").setup({})` (replace `{}` with your `config` table)
---@toc_entry The setup function
dev_comments.setup = function(config)
  config = config or {}
  dev_comments.config = vim.tbl_extend("force", dev_comments.config, config)
  if dev_comments.config.default_mappings then require("dev_comments.presets").set_default_mappings() end
  if dev_comments.config.default_commands then require("dev_comments.presets").set_default_commands() end
  if dev_comments.config.telescope.load then require("telescope").load_extension("dev_comments") end
  if dev_comments.config.cache.enabled then require("dev_comments.cache").register() end
end

--- # Configuration~
---
--- Default values:
---@toc_entry Configure the setup
---@tag dev-comments-configuration
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---
---
--minidoc_replace_start {
dev_comments.config = {
  --minidoc_replace_end
  -- Enables vim.notify messages
  debug = false,
  -- Creates <Plug> mappings
  default_mappings = true,
  -- Create user commands
  default_commands = true,
  -- Each call of dev-comments is cached
  -- Play around with the reset autocommands for more aggressive caching
  cache = {
    enabled = true,
    reset_autocommands = { "BufWritePost", "BufWinEnter" },
  },
  -- Loads and sets default options for telescope plugin
  telescope = {
    load = true,
    -- require("dev_comments.constants").Files
    [Files.CURRENT] = {
      tags = {},
      users = {},
    },
    [Files.OPEN] = {
      tags = {},
      users = {},
    },
    [Files.ALL] = {
      hidden = false,
      depth = 3,
      tags = {},
      users = {},
    },
  },
  -- Cycle through dev-comments in a given buffer
  -- Caching is recommended for this feature
  cycle = {
    wrap = true,
  },
  -- Improves performance when searching in a large directory
  -- Requires ripgrep or grep
  pre_filter = {
    -- require("dev_comments.constants").FilterCommand
    command = FilterCommand.RIPGREP,
    -- If search fails, uses plenary scandir (very slow)
    fallback_to_plenary = true,
  },
  -- Highlight for the tag in picker (not in buffer)
  highlight = {
    tags = {
      ["TODO"] = "TSWarning",
      ["HACK"] = "TSWarning",
      ["WARNING"] = "TSWarning",
      ["FIXME"] = "TSDanger",
      ["XXX"] = "TSDanger",
      ["BUG"] = "TSDanger",
    },
    -- Used if lookup fails for a given tag
    fallback = "TSNote",
  },
}
--minidoc_afterlines_end

return dev_comments
