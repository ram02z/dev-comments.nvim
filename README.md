# dev-comments.nvim

> List and search for dev comments using [tree-sitter-comment](https://github.com/stsewd/tree-sitter-comment) parser

## Features

- Performant searching
- Highly configurable
- Sensible defaults (can be disabled)
- [Telescope](https://github.com/nvim-telescope/telescope.nvim) integration
- Filter dev comments by tags i.e. `<TAG>:` and/or users i.e. `<TAG>(<user>):`
- Cycle through dev comments in a buffer
- All core functionality has unit tests

## Requirements

### Core

- Neovim >= 0.7.0

### Optional

  - [ripgrep](https://github.com/BurntSushi/ripgrep) 

  *OR*

  - [grep](https://www.gnu.org/software/grep/manual/grep.html)

  > Highly recommended if you use the `all` file mode

## Installation

Install the plugin with your preferred plugin manager

### [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'ram02z/dev-comments.nvim'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'nvim-telescope/telescope.nvim' " optional for picker

lua << EOF
require("dev_comments").setup({
  -- configuration
  -- leave empty for defaults
})
EOF
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use({
  "ram02z/dev-comments.nvim",
  requires = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/nvim-telescope", -- optional
  },
  config = function()
      require("dev_comments").setup({
      -- configuration
      -- leave empty for defaults
    })
  end
})
```

Ensure you have the `tree-sitter-comment` parser installed in Neovim

Run `:TSInstall comment<CR>`

## Configuration

All features are enabled by default.

See the [help](./doc/dev-comments.txt) doc or run `:help dev-comments-configuration<CR>` in Neovim

## Usage

The file modes:
- `all`: searches in all files based on value of `cwd`
- `open`: searches only open files
  - Only filters based on `cwd` if provided
- `buffer`: searches only the open buffer
  - Ignores the value of `cwd`

The main options are:
- `cwd`: filters the search by working directory
  - Default: value of `vim.loop.cwd()`
  - Uses `vim.fn.expand()` to expand variables i.e. `~` -> `/root/home/`
- `tags`: filters the search by tags i.e. `<TAG>: `
  - Default: all tags
  - Use `table<string>` if using the API directly
  - Use comma separated strings if you using the commands, i.e. `tags=TODO`
- `users` : filters the search by user i.e. `<TAG>(<USER>):`
  - Default: all users 
  - Use `table<string>` if using the API directly
  - Use comma separated strings if you using the commands, i.e. `users=ram02z,foo`

### Telescope

Either set the `telescope.load` to `true` in the configuration or load the extension manually

```lua
require("telescope").load_extension("dev_comments")
```

The three file modes `all`, `current` and `open` are available by running 
`:Telescope dev_comments <file-mode><CR>`

For more information, run `:help dev-comments-telescope<CR>`

### Cycle

The cycle feature only works in the current open buffer

### Commands

Run `:help dev-comments-default-commands<CR>` in Neovim

### Keymaps

Run `:help dev-comments-default-keymaps<CR>` in Neovim

## License

MIT
