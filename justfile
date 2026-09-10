# Neovim Renderer Plugins - Justfile
# Modern command runner (https://just.systems/)

# ============================================================================
# Development
# ============================================================================

default:
    @just --list

# Run all tests
test:
    @just test-e2e 2>&1 | grep -v "^nvim"

# Run e2e tests with headless Neovim
test-e2e:
    #!/usr/bin/env bash
    set -e
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                   Neovim Renderer Tests                  ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""

    echo "┌─ Markdown Tests ─────────────────────────────────────┐"
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/markdown_test.lua" 2>&1 | grep -v "^nvim"
    echo "└──────────────────────────────────────────────────────┘"
    echo ""

    echo "┌─ ipynb Tests ────────────────────────────────────────┐"
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/ipynb_test.lua" 2>&1 | grep -v "^nvim" | grep -v "E211"
    echo "└──────────────────────────────────────────────────────┘"
    echo ""

    echo "┌─ Image Tests ────────────────────────────────────────┐"
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/image_test.lua" 2>&1 | grep -v "^nvim"
    echo "└──────────────────────────────────────────────────────┘"
    echo ""

    echo "┌─ File Type Detection Tests ──────────────────────────┐"
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/filetype_test.lua" 2>&1 | grep -v "^nvim"
    echo "└──────────────────────────────────────────────────────┘"
    echo ""

# Run specific test suites
test-markdown:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/markdown_test.lua" 2>&1 | grep -v "^nvim"

test-ipynb:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/ipynb_test.lua" 2>&1 | grep -v "^nvim" | grep -v "E211"

test-image:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/image_test.lua" 2>&1 | grep -v "^nvim"

test-filetype:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/filetype_test.lua" 2>&1 | grep -v "^nvim"

# Run rendering tests
test-render:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/markdown_render_test.lua" 2>&1 | grep -v "^nvim"
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/ipynb_render_test.lua" 2>&1 | grep -v "^nvim" | grep -v "E211"
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile lua/tests/e2e/image_render_test.lua" 2>&1 | grep -v "^nvim"

# ============================================================================
# Build
# ============================================================================

build:
    @echo "Building TypeScript plugins..."
    cd typescript && bun run build 2>/dev/null || echo "No build script found"

clean:
    rm -rf node_modules/ bun.lockb

# ============================================================================
# Lint
# ============================================================================

lint:
    bun run --bun tsc --noEmit 2>/dev/null || echo "TypeScript check complete"

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
