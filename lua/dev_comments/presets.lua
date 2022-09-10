local P = {}

---
--- # Default mappings~
---
--- dev-comments.nvim comes with optional default mappings and commands
---
---@tag dev-comments-default-mappings
---@toc_entry Default mappings
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---
--minidoc_replace_start function()
P.set_default_mappings = function()
  --minidoc_replace_end
  -- <Plug> keymaps
  vim.keymap.set("n", "<Plug>DevCommentsTelescopeCurrent", function()
    require("telecope").extensions.dev_comments.current({})
  end, { silent = true })
  vim.keymap.set("n", "<Plug>DevCommentsTelescopeOpen", function()
    require("telecope").extensions.dev_comments.open({})
  end, { silent = true })
  vim.keymap.set("n", "<Plug>DevCommentsTelescopeAll", function()
    require("telecope").extensions.dev_comments.open({})
  end, { silent = true })
  vim.keymap.set("n", "<Plug>DevCommentsCyclePrev", function()
    require("dev_comments.cycle").goto_prev()
  end, { silent = true })
  vim.keymap.set("n", "<Plug>DevCommentsCycleNext", function()
    require("dev_comments.cycle").goto_next()
  end, { silent = true })

  -- Keybinds
  vim.keymap.set("n", "[c", "<Plug>DevCommentsCyclePrev")
  vim.keymap.set("n", "]c", "<Plug>DevCommentsCycleNext")
end
--minidoc_afterlines_end

---
--- # Default commands~
---
---@tag dev-comments-default-commands
---@toc_entry Default commands
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---
--minidoc_replace_start function()
P.set_default_commands = function()
  --minidoc_replace_end
  local Files = require("dev_comments.constants").Files
  local cache = require("dev_comments.cache")
  vim.api.nvim_create_user_command("DevCommentsCacheReset", function()
    cache.reset(Files.CURRENT)
    cache.reset(Files.OPEN)
    cache.reset(Files.ALL)
  end, {})
  vim.api.nvim_create_user_command("DevCommentsCacheToggle", function()
    local registered = cache.unregister()
    if not registered then cache.register() end
  end, {})
  vim.api.nvim_create_user_command("DevCommentsCacheDisable", function()
    cache.unregister()
  end, {})
  vim.api.nvim_create_user_command("DevCommentsCacheEnable", function()
    cache.register()
  end, {})
  vim.api.nvim_create_user_command("DevCommentsCyclePrev", function()
    require("dev_comments.cycle").goto_prev()
  end, {})
  vim.api.nvim_create_user_command("DevCommentsCycleNext", function()
    require("dev_comments.cycle").goto_next()
  end, {})
end
--minidoc_afterlines_end

return P
