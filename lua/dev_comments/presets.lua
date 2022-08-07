local P = {}

local setup = function()
  vim.keymap.set(
    "n",
    "<Plug>DevCommentsTelescopeCurrent",
    "<cmd>lua require('telescope').extensions.dev_comments.current{}<cr>",
    { silent = true }
  )
  vim.keymap.set(
    "n",
    "<Plug>DevCommentsTelescopeOpen",
    "<cmd>lua require('telescope').extensions.dev_comments.open{}<cr>",
    { silent = true }
  )
  vim.keymap.set(
    "n",
    "<Plug>DevCommentsTelescopeAll",
    "<cmd>lua require('telescope').extensions.dev_comments.all{}<cr>",
    { silent = true }
  )
  vim.keymap.set(
    "n",
    "<Plug>DevCommentsCyclePrev",
    "<cmd>lua require('dev_comments.cycle').goto_prev()<cr>",
    { silent = true }
  )
  vim.keymap.set(
    "n",
    "<Plug>DevCommentsCycleNext",
    "<cmd>lua require('dev_comments.cycle').goto_next()<cr>",
    { silent = true }
  )
end

P.set_default_mappings = function()
  setup()
  vim.keymap.set("n", "[c", "<Plug>DevCommentsCyclePrev")
  vim.keymap.set("n", "]c", "<Plug>DevCommentsCycleNext")
end

return P
