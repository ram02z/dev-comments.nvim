.PHONY: test
test:
	nvim --headless --noplugin -u test/minimal.vim -c "lua require(\"plenary.test_harness\").test_directory_command('test {minimal_init = \"/test/minimal.vim\"}')"
