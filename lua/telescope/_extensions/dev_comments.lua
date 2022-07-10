local has_telescope, telescope = pcall(require, 'telescope')
local picker = require('telescope._extensions.dev_comments.picker')

if not has_telescope then
  error('This plugin requires nvim-telescope/telescope.nvim')
end

local has_comments_parser = vim.treesitter.require_language("comment", nil, true)
if not has_comments_parser then
  error("This plugin requires 'comment' parser to be installed. Try running 'TSInstall comment'")
end

return telescope.register_extension{
  exports = { dev_comments = picker }
}
