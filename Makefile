NVIM_EXEC ?= nvim

.PHONY: test
test:
	$(NVIM_EXEC) --headless --noplugin -u scripts/minimal_init.vim -c "lua require(\"plenary.test_harness\").test_directory_command('test {minimal_init = \"scripts/minimal_init.vim\"}')"

.PHONY: docgen
docgen:
	$(NVIM_EXEC) --headless --noplugin -u scripts/minimal_init.vim -c "lua MiniDoc.generate()" -c "qa!"
