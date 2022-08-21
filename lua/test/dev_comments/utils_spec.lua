local utils = require("dev_comments.utils")
local mock = require("luassert.mock")

describe("utils", function()

  local notify
  local config = require("dev_comments").config
  before_each(function()
    notify = mock(vim.notify, true)
  end)

  after_each(function()
    mock.revert(notify)
  end)

  it("does not notify if not debug", function()
    config.debug = false
    utils.notify()
    assert.stub(notify).was_not_called()
  end)

  it("gets filename from default buffer", function()
    local get_filename = utils.get_filename_fn()
    local api = mock(vim.api, true)

    get_filename()

    assert.stub(api.nvim_buf_get_name).was_called_with(0)

    mock.revert(api)
  end)

  it("returns empty string with invalid node", function()
    local node = nil
    local text = utils.get_node_text(node)
    assert.equals("", text)
  end)

  it("gets fallback highlight from config if tag and fallback are not found", function ()
    local fallback = config.highlight.fallback
    local hlname = utils.get_highlight_by_tag(nil, nil)
    assert(hlname, fallback)
  end)

  it("gets fallback highlight from param if tag is not found", function ()
    local fallback = "test"
    local hlname = utils.get_highlight_by_tag(nil, fallback)
    assert(hlname, fallback)
  end)
end)
