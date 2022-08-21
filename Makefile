.PHONY: test
test:
	nvim --headless --noplugin -u minimal.lua -c "lua require(\"plenary.test_harness\").test_directory_command('test {minimal_init = \"/minimal.lua\"}')"
