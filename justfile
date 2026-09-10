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
    @echo "Running all tests..."
    just test-e2e

# Run unit tests only
test-unit:
    @echo "No unit tests yet"

# Run e2e tests with headless Neovim
test-e2e:
    @echo "=== Running Plugin Tests ==="
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/markdown_test.lua" 2>&1
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/ipynb_test.lua" 2>&1
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/image_test.lua" 2>&1
    @echo ""
    @echo "=== Running Rendering Tests ==="
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/markdown_render_test.lua" 2>&1
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/ipynb_render_test.lua" 2>&1
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/image_render_test.lua" 2>&1
    @echo ""
    @echo "=== Running File Type Detection Tests ==="
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/filetype_test.lua" 2>&1

# Run specific test suites
test-markdown:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/markdown_test.lua" 2>&1
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/markdown_render_test.lua" 2>&1

test-ipynb:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/ipynb_test.lua" 2>&1
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/ipynb_render_test.lua" 2>&1

test-image:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/image_test.lua" 2>&1
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/image_render_test.lua" 2>&1

# Run only rendering tests
test-render:
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/markdown_render_test.lua" 2>&1
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/ipynb_render_test.lua" 2>&1
    nvim --headless -u NONE --cmd "set rtp+={{justfile_directory()}}" -c "luafile tests/e2e/image_render_test.lua" 2>&1

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
