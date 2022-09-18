local C = {}

--- # File modes~
---
---@toc_entry File modes
---@tag dev-comments-file-modes
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---
--minidoc_replace_start {
C.Files = {
  --minidoc_replace_end
  --minidoc_replace_start Files.CURRENT,
  CURRENT = "current",
  --minidoc_replace_end
  --minidoc_replace_start Files.OPEN,
  OPEN = "open",
  --minidoc_replace_end
  --minidoc_replace_start Files.ALL
  ALL = "all",
  --minidoc_replace_end
}
--minidoc_afterlines_end

--- # Pre-filter modes~
---
---@toc_entry Pre-filter modes
---@tag dev-comments-filter-modes
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---
--minidoc_replace_start {
C.FilterCommand = {
  --minidoc_replace_end
  --minidoc_replace_start FilterCommand.RIPGREP,
  RIPGREP = "rg",
  --minidoc_replace_end
  --minidoc_replace_start FilterCommand.GREP,
  GREP = "grep",
  --minidoc_replace_end
  --minidoc_replace_start FilterCommand.NONE,
  NONE = "",
  --minidoc_replace_end
}
--minidoc_afterlines_end

C.FilterCommandArgs = {
  [C.FilterCommand.RIPGREP] = { "--files-with-matches", "--max-count=1" },
  -- TODO: doesn't ignore hidden files
  -- exclude-dir flag only matches the directory's base name
  [C.FilterCommand.GREP] = {
    "--recursive",
    "--files-with-matches",
    "--max-count=1",
    "--extended-regexp",
  },
}

return C
