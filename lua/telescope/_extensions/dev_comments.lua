local has_telescope, telescope = pcall(require, "telescope")
local picker = require("telescope._extensions.dev_comments.picker")

if not has_telescope then
  error("This plugin requires nvim-telescope/telescope.nvim")
end

return telescope.register_extension({
  exports = { dev_comments = picker },
})
