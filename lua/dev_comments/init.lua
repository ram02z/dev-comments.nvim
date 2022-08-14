-- TODO: use grep to list files when using Files.ALL
local dev_comments = {}

local Files = require("dev_comments.constants").Files

dev_comments.config = {
  debug = false,
  default_mappings = true,
  default_commands = true,
  cache = true,
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
}

dev_comments.setup = function(config)
  config = config or {}
  dev_comments.config = vim.tbl_extend("force", dev_comments.config, config)
  if dev_comments.config.default_mappings then
    require("dev_comments.presets").set_default_mappings()
  end
  if dev_comments.config.default_commands then
    require("dev_comments.presets").set_default_commands()
  end
  if dev_comments.config.telescope.load then
    require("telescope").load_extension("dev_comments")
  end
  if dev_comments.config.cache then
    require("dev_comments.cache").register()
  end
end

return dev_comments
