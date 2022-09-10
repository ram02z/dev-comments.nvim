-- Copied from telescope.previewers.buffer_previewer
local previewer = function(opts)
  local conf = require("telescope.config").values
  local from_entry = require("telescope.from_entry")
  local previewers = require("telescope.previewers")

  local ns_previewer = vim.api.nvim_create_namespace("dev_comments.previewers")

  opts = opts or {}

  local jump_to_line = function(self, bufnr, lnum, start, finish)
    pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_previewer, 0, -1)
    if lnum and lnum > 0 then
      pcall(vim.api.nvim_buf_add_highlight, bufnr, ns_previewer, "TelescopePreviewLine", lnum - 1, start, finish)
      pcall(vim.api.nvim_win_set_cursor, self.state.winid, { lnum, start + 1 })
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("norm! zz")
      end)
    end
  end

  return previewers.new_buffer_previewer({
    title = "Comment Preview",
    get_buffer_by_name = function(_, entry)
      return from_entry.path(entry, false)
    end,

    define_preview = function(self, entry, _)
      -- builtin.buffers: bypass path validation for terminal buffers that don't have appropriate path
      local has_buftype = entry.bufnr and vim.api.nvim_buf_get_option(entry.bufnr, "buftype") ~= "" or false
      local p
      if not has_buftype then
        p = from_entry.path(entry, true)
        if p == nil or p == "" then return end
      end

      -- Workaround for unnamed buffer when using builtin.buffer
      if entry.bufnr and (p == "[No Name]" or has_buftype) then
        local lines = vim.api.nvim_buf_get_lines(entry.bufnr, 0, -1, false)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        jump_to_line(self, self.state.bufnr, entry.lnum)
      else
        conf.buffer_previewer_maker(p, self.state.bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
          preview = opts.preview,
          callback = function(bufnr)
            jump_to_line(self, bufnr, entry.lnum, entry.col, entry.finish)
          end,
        })
      end
    end,
  })
end

return previewer
