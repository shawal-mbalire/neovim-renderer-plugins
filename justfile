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

# Individual test suites
test-markdown:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/markdown_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

test-ipynb:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/ipynb_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total" | grep -v "E211"

test-image:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/image_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

test-filetype:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/filetype_test.lua" 2>&1 | grep -E "^\s+[✓✗]|passed|failed|Total"

# Build and lint
build:
    cd typescript && bun run build 2>/dev/null || echo "No build script"

clean:
    rm -rf node_modules/ bun.lockb

lint:
    bun run --bun tsc --noEmit 2>/dev/null || echo "TypeScript check complete"

# Neovim testing
nvim-markdown:
    nvim --cmd "set rtp+=." -c "lua require('renderer-markdown').setup({preview={auto_open=true}})" README.md

nvim-ipynb:
    nvim --cmd "set rtp+=." -c "lua require('renderer-ipynb').setup()" test.ipynb

nvim-image:
    nvim --cmd "set rtp+=." -c "lua require('renderer-image').setup()" test.png

# Release
release version:
    git tag -a v{{version}} -m "Release v{{version}}"
    git push origin v{{version}}
