# Neovim Renderer Plugins - Justfile

# Paths
selene := `which selene`
stylua := `which stylua`
root_dir := justfile_directory()

default:
    @just --list

# Run all tests
test:
	#!/usr/bin/env bash
	set -e
	echo ""
	echo "Running tests..."
	echo ""

	echo "markdown:"
	nvim --headless --cmd "set rtp+={{root_dir}}" -c "luafile lua/tests/e2e/markdown_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

	echo ""
	echo "ipynb:"
	nvim --headless --cmd "set rtp+={{root_dir}}" -c "luafile lua/tests/e2e/ipynb_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total" | grep -v "E211"

	echo ""
	echo "image:"
	nvim --headless --cmd "set rtp+={{root_dir}}" -c "luafile lua/tests/e2e/image_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

	echo ""
	echo "filetype:"
	nvim --headless --cmd "set rtp+={{root_dir}}" -c "luafile lua/tests/e2e/filetype_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

	echo ""
	echo "plugin discovery:"
	nvim --headless --cmd "set rtp+={{root_dir}}" -c "luafile lua/tests/e2e/plugin_discovery_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"
	echo ""

# Individual test suites
test-markdown:
	nvim --headless --cmd "set rtp+={{root_dir}}" -c "luafile lua/tests/e2e/markdown_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

test-ipynb:
	nvim --headless --cmd "set rtp+={{root_dir}}" -c "luafile lua/tests/e2e/ipynb_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total" | grep -v "E211"

test-image:
	nvim --headless --cmd "set rtp+={{root_dir}}" -c "luafile lua/tests/e2e/image_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

test-filetype:
	nvim --headless --cmd "set rtp+={{root_dir}}" -c "luafile lua/tests/e2e/filetype_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

test-discovery:
	nvim --headless --cmd "set rtp+={{root_dir}}" -c "luafile lua/tests/e2e/plugin_discovery_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

test-lazyvim:
    #!/usr/bin/env bash
    set -e
    echo "Testing lazy.nvim plugin discovery..."
    echo ""
    nvim --headless -u NONE --cmd "set rtp+={{root_dir}}" -c "lua << EOF
    local passed = 0
    local failed = 0
    local plugins = {'renderer-markdown', 'renderer-ipynb', 'renderer-image'}
    for _, name in ipairs(plugins) do
      local ok, plugin = pcall(require, name)
      if ok and plugin.setup then
        pcall(plugin.setup, { preview = { auto_open = false } })
        print('  ✓ ' .. name .. ' loaded')
        passed = passed + 1
      else
        print('  ✗ ' .. name .. ' failed')
        failed = failed + 1
      end
    end
    local cmds = {'MarkdownPreview','IpynbRender','ImageShow'}
    for _, cmd in ipairs(cmds) do
      if vim.api.nvim_get_commands({})[cmd] then
        print('  ✓ Command ' .. cmd)
        passed = passed + 1
      else
        print('  ✗ Command ' .. cmd)
        failed = failed + 1
      end
    end
    print(passed .. ' passed, ' .. failed .. ' failed')
    vim.cmd(failed > 0 and 'cquit 1' or 'qa!')
    EOF" 2>&1 | grep -v "^$"

# Format code
format:
    @echo "Formatting Lua..."
    @cd lua && {{stylua}} . --column-width 100 --indent-width 2 --quote-style AutoPreferDouble 2>/dev/null || echo "  stylua not found, skipping"
    @echo "Formatting TypeScript..."
    @cd typescript && bunx prettier --write "**/*.ts" 2>/dev/null || echo "  prettier not found, skipping"
    @echo "Done."

# Lint code
lint:
    @echo "Linting Lua..."
    @cd lua && {{selene}} . 2>&1 | grep -E "^[a-z]|Results:" || echo "  Lua: OK"
    @echo ""
    @echo "Linting TypeScript..."
    @cd typescript && bun install --frozen-lockfile 2>/dev/null && bunx tsc --noEmit 2>&1 | grep -E "error TS|Done" || echo "  TypeScript: OK"
    @echo "Done."

# Clean build artifacts
clean:
    @cd typescript && rm -rf node_modules/ bun.lockb bun.lock dist/
    @echo "Cleaned."

# ============================================================================
# Neovim Testing
# ============================================================================

nvim-markdown:
    nvim --cmd "set rtp+=." -c "lua require('renderer-markdown').setup({preview={auto_open=true}})" README.md

nvim-ipynb:
    nvim --cmd "set rtp+=." -c "lua require('renderer-ipynb').setup()" test.ipynb

nvim-image:
    nvim --cmd "set rtp+=." -c "lua require('renderer-image').setup()" test.png

# ============================================================================
# Release
# ============================================================================

release version:
    git tag -a v{{version}} -m "Release v{{version}}"
    git push origin v{{version}}
