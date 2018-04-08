" File:        plugin/relative-indent.vim
" Author:      fent (https://github.com/fent)
" Description: Hide indentation levels

if exists('g:loaded_relative_indent')
  finish
endif
let g:loaded_relative_indent = 1
let g:relative_indent_use_conceal = get(g:, 'relative_indent_use_conceal', has('conceal'))

function! s:RelativeIndent()
  let cursor = getcurpos()
  " Don't hide indent past the cursor
  let minindent = cursor[2]
  let topline = line('w0')
  let botline = line('w$')
  let space = &shiftwidth == 0 ? &tabstop : &shiftwidth
  let cursor_at_blank_line = 0
  let virtualedit_set = 0

  " Find the line with the least indent
  for i in range(topline, botline)
    " An indent of 0 is already the minimum
    let line_indent = indent(i)
    if line_indent == 0
      let line_contents = getline(i)
      " Ignore blank lines with zero length
      if strlen(line_contents) == 0
        " If this line is where the cursor is, enable virtualedit mode
        " so that the cursor doesn't jump to column 0
        if cursor[1] == i
          let cursor_at_blank_line = 1
          if &l:virtualedit != 'all'
            let w:relative_indent_last_virtualedit = &l:virtualedit
            let &l:virtualedit = 'all'
            let virtualedit_set = 1
            if exists('w:relative_indent_last_cursor')
              let w:relative_indent_last_cursor[1] = i
              call setpos('.', w:relative_indent_last_cursor)
              unlet w:relative_indent_last_cursor
            endif
          endif
        endif
        continue
      else
        let minindent = 0
        break
      endif
    endif

    " Ignore blank lines of whitespace
    let line_contents = getline(i)
    if empty(matchstr(line_contents, '[^\s]'))
      continue
    endif

    " A one level indent is the lowest it can be above no indent
    if minindent == space
      continue
    endif
    if minindent > line_indent
      let minindent = line_indent
    endif
  endfor

  if g:relative_indent_use_conceal
    " Hide indent with conceal syntax
    execute 'syntax match RelativeIndent'

  elseif cursor_at_blank_line == 0
    " Hide indent by scrolling the window to the right
    if virtualedit_set == 0 && exists('w:relative_indent_last_virtualedit')
      let &l:virtualedit = w:relative_indent_last_virtualedit
      unlet w:relative_indent_last_virtualedit
    endif
    execute 'normal 999zh'
    if minindent > 0
      execute 'normal '.minindent.'zl'
      let w:relative_indent_last_cursor = cursor
      call setpos('.', cursor)
    endif
    let w:relative_indent_last_line = cursor[1]
  endif
endfunction

command! RelativeIndent call <SID>RelativeIndent()

" augroup relative_indent
"   autocmd!
"   autocmd WinEnter,CursorMoved,VimResized * :RelativeIndent
" augroup END
