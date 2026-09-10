" plug.vim integration
" Add this to your .vimrc or init.vim:
"
" call plug#begin()
" Plug 'yourusername/neovim-renderer-plugins'
" call plug#end()
"
" Then add to your init.lua:
" require("renderer").setup()

if exists('g:loaded_renderer_plug')
  finish
endif
let g:loaded_renderer_plug = 1

" Auto-setup when plugin loads
augroup RendererPlug
  autocmd!
  autocmd User plug#end call s:setup()
augroup END

function! s:setup()
  lua require("renderer").setup()
endfunction

" Commands for plug.vim users
command! RendererToggle lua require("renderer").toggle()
command! RendererRefresh lua require("renderer").refresh()
command! RendererStatus lua require("renderer").status()
command! RendererPreviewOpen lua require("renderer").open_preview(vim.api.nvim_get_current_buf())
command! RendererPreviewClose lua require("renderer").close_preview(vim.api.nvim_get_current_buf())
command! RendererPreviewToggle lua require("renderer").toggle_preview(vim.api.nvim_get_current_buf())
