#!/bin/sh

# Build parser
cd ../tree-sitter-lua
make dist
cd -

# Generate docs
nvim --version
exec nvim --headless --noplugin -u scripts/minimal_init.vim -c "luafile ./scripts/gendocs.lua" -c 'qa'
