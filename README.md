# relative-indent

Hide unnecessary leading indent

![preview](https://i.imgur.com/Iyh8gXm.gif)

# Install

Use of a plugin manager is recommended. [vim-plug](https://github.com/junegunn/vim-plug) is what I use. Note that this plugin requires the `wrap` option to be off to work, but you might not miss it as much with the extra room.

```vim
Plug 'fent/vim-relative-indent'
set nowrap
```

In order to provide for flexibility, relative-indent is not enabled by default. Using an `autocmd` to enable it per buffer is recommended.

```vim
augroup relative_indent
  autocmd!
  " Apply to all filetypes except markdown and quickfix
  autocmd FileType * :RelativeIndentEnable
  autocmd FileType markdown :setlocal wrap
augroup END
```

# Additional Configuration

Using the `list` option with `precedes` provides a helpful marker for when indent has been hidden.

```vim
set listchars+=precedes:<
set list
```

![list_preview](https://i.imgur.com/EZXhsYF.gif)

If you'd like to know how many levels of indent are hidden, use `w:relative_indent_level`. This can be used in your statusline for example.

This is my configuration with lightline
```vim
let g:lightline = {
  \ 'active': {
  \   'left': [
  \     ['relative_indent', 'mode', 'paste'],
  \   ],
  \   'right': [['lineinfo'], ['percent'], ['fileformat', 'filetype']],
  \ 'component_function': {
  \   'relative_indent': 'LightlineRelativeIndent',
  \ },
  \ }

function! LightlineRelativeIndent()
  return repeat('<', get(w:, 'relative_indent_level', 0))
endfunction
```
