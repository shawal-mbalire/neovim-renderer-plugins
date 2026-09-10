# Neovim Renderer Plugins - Justfile

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
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/markdown_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

    echo ""
    echo "ipynb:"
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/ipynb_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total" | grep -v "E211"

    echo ""
    echo "image:"
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/image_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

    echo ""
    echo "filetype:"
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/filetype_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

    echo ""
    echo "plugin discovery:"
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/plugin_discovery_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"
    echo ""

# Individual test suites
test-markdown:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/markdown_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

test-ipynb:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/ipynb_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total" | grep -v "E211"

test-image:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/image_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

test-filetype:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/filetype_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

test-discovery:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/plugin_discovery_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

# Format code
format:
    @echo "Formatting Lua..."
    @cd lua && stylua . --column-width 100 --indent-width 2 --quote-style AutoPreferDouble 2>/dev/null || echo "  stylua not found, skipping"
    @echo "Formatting TypeScript..."
    @cd typescript && bunx prettier --write "**/*.ts" 2>/dev/null || echo "  prettier not found, skipping"
    @echo "Done."

# Lint code
lint:
    @echo "Linting TypeScript..."
    @cd typescript && bun install --frozen-lockfile 2>/dev/null && bunx tsc --noEmit 2>/dev/null && echo "  TypeScript: OK" || echo "  TypeScript: errors found"
    @echo "Done."

# Clean build artifacts
clean:
    @cd typescript && rm -rf node_modules/ bun.lockb bun.lock dist/
    @echo "Cleaned."
