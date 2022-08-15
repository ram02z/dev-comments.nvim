local C = {}

C.Files = { CURRENT = "current", OPEN = "open", ALL = "all" }

C.FilterCommand = { RIPGREP = "rg", GREP = "grep", NONE = "" }

C.FilterCommandArgs = {
  [C.FilterCommand.RIPGREP] = { "--files-with-matches", "--max-count=1" },
  [C.FilterCommand.GREP] = {
    "--recursive",
    "--files-with-matches",
    "--max-count=1",
    "--extended-regexp",
    "--exclude-dir='.[^.]*'",
  },
}

return C
