set hidden
set noswapfile

set rtp+=../plenary.nvim
set rtp+=../dev-comments.nvim
set rtp+=../mini.nvim

runtime! plugin/plenary.vim

lua << EOF
require("mini.doc").setup({})
EOF
