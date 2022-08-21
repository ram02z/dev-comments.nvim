---
--- # Telescope~
---
--- dev-comments.nvim comes with first class telescope integration
---
---@tag dev-comments-telescope
---@toc_entry Telecope integration


local has_telescope, telescope = pcall(require, "telescope")
local picker = require("telescope._extensions.dev_comments.picker")

if not has_telescope then error("This plugin requires nvim-telescope/telescope.nvim") end

return telescope.register_extension({
  exports = {
    current = picker.current,
    open = picker.open,
    all = picker.all,
  },
})
