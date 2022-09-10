local comments = require("dev_comments.comments")
local mock = require("luassert.mock")

describe("comments", function()
  local treesitter

  before_each(function()
    treesitter = mock(vim.treesitter, true)
  end)

  after_each(function()
    mock.revert(treesitter)
  end)

  it("throws if comment parser is not available", function()
    assert.has_error(function()
      comments.generate()
      assert.stub(treesitter.require_language).was_called_with("comment", nil, true)
    end, "This plugin requires 'comment' parser to be installed. Try running 'TSInstall comment'")
  end)

  it("checks cache first when generating", function() end)

  it("generates sorted results for Files.CURRENT", function() end)

  it("generates sorted results for Files.OPEN", function() end)

  it("generates sorted results for Files.ALL", function() end)
end)
