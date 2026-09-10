# Neovim Renderer Plugins - Justfile
# Modern command runner (https://just.systems/)

# ============================================================================
# Development
# ============================================================================

# List all available commands
default:
    @just --list

# Run all tests
test:
    @echo "Running e2e tests..."
    just test-e2e

# Run unit tests only
test-unit:
    @echo "No unit tests yet"

# Run e2e tests with headless Neovim
test-e2e:
    @echo "Running markdown e2e tests..."
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/markdown_test.lua" 2>&1
    @echo "Running ipynb e2e tests..."
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/ipynb_test.lua" 2>&1
    @echo "Running image e2e tests..."
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/image_test.lua" 2>&1

# Run full e2e test suite
test-e2e-full:
    bun test tests/e2e/

# Watch tests
test-watch:
    bun test --watch

# Run specific e2e test
test-e2e-markdown:
    nvim --headless --cmd "set rtp+=." -c "luafile tests/e2e/markdown_test.lua"

test-e2e-ipynb:
    nvim --headless --cmd "set rtp+=." -c "luafile tests/e2e/ipynb_test.lua"

test-e2e-image:
    nvim --headless --cmd "set rtp+=." -c "luafile tests/e2e/image_test.lua"

# ============================================================================
# Build
# ============================================================================

# Build TypeScript
build:
    @echo "Building markdown renderer..."
    cd typescript/deployment/markdown && bun run build
    @echo "Building ipynb renderer..."
    cd typescript/deployment/ipynb && bun run build
    @echo "Building image renderer..."
    cd typescript/deployment/image && bun run build

# Clean build artifacts
clean:
    rm -rf typescript/deployment/*/renderer
    rm -rf node_modules/
    rm -rf bun.lockb

# ============================================================================
# Lint & Format
# ============================================================================

# Run linter
lint:
    bun run --bun tsc --noEmit

# Format code
format:
    @echo "Formatting..."
    # Add formatter when available

# ============================================================================
# Neovim Testing
# ============================================================================

# Test plugin in Neovim (interactive)
nvim-test:
    nvim --cmd "set rtp+=." -c "lua require('renderer-markdown').setup()" README.md

# Test markdown preview
nvim-markdown:
    nvim --cmd "set rtp+=." -c "lua require('renderer-markdown').setup({preview={auto_open=true}})" README.md

# Test ipynb rendering
nvim-ipynb:
    nvim --cmd "set rtp+=." -c "lua require('renderer-ipynb').setup()" test.ipynb

# Test image rendering
nvim-image:
    nvim --cmd "set rtp+=." -c "lua require('renderer-image').setup()" test.png

# Headless Neovim test (for CI)
nvim-headless:
    nvim --headless --cmd "set rtp+=." -c "lua require('renderer-markdown').setup()" -c "lua print('OK')" -c "qa!"

# ============================================================================
# Development Helpers
# ============================================================================

# Install dependencies
install:
    bun install

# Update dependencies
update:
    bun update

# Run TypeScript type check
typecheck:
    bun run --bun tsc --noEmit

# Show project structure
tree:
    @find . -type f -name "*.ts" -o -name "*.lua" -o -name "*.json" | grep -v node_modules | sort

# ============================================================================
# Release
# ============================================================================

# Tag a release
release version:
    git tag -a v{{version}} -m "Release v{{version}}"
    git push origin v{{version}}

# Create changelog
changelog:
    git log --oneline --no-merges v$(git describe --tags --abbrev=0 2>/dev/null || echo "HEAD")..HEAD
