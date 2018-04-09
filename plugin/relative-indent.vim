" File:        plugin/relative-indent.vim
" Author:      fent (https://github.com/fent)
" Description: Hide indentation levels

if exists('g:loaded_relative_indent')
  finish
endif
let g:loaded_relative_indent = 1

function! s:RelativeIndent()
  let cursor = getcurpos()
  " Don't hide indent past the cursor
  if &l:virtualedit != 'all' || exists('w:relative_indent_last_virtualedit')
    let curr_line_contents = getline(cursor[1])
    let cursor_at_blank_line = empty(matchstr(curr_line_contents, '[^\s]'))
    if cursor_at_blank_line
      let minindent = exists('w:relative_indent_last_cursor') ?
        \ w:relative_indent_last_cursor[2] :
        \ 2147483647
    endif
  else
    let cursor_at_blank_line = 0
  endif
  let minindent = get(l:, 'minindent', cursor[2])
  let topline = line('w0')
  let botline = line('w$')
  let virtualedit_set = 0

  " Find the line with the least indent
  if minindent > 0
    for i in range(topline, botline)
      " An indent of 0 is already the minimum
      let line_indent = indent(i)
      if line_indent == 0
        let line_contents = getline(i)
        " Ignore blank lines with zero length
        if strlen(line_contents) == 0
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

      if minindent > line_indent
        let minindent = line_indent
      endif
    endfor
  endif

  " If this line is where the cursor is, enable virtualedit mode
  " so that the cursor doesn't jump to column 0
  if cursor_at_blank_line && &l:virtualedit != 'all'
    let w:relative_indent_last_virtualedit = &l:virtualedit
    let &l:virtualedit = 'all'
    let virtualedit_set = 1
  endif

  " When moving from a blank line to a non blank line,
  " restore the cursor column to the last column it was at
  " on a non blank line
  let moved_from_blank_line = !cursor_at_blank_line && !virtualedit_set && exists('w:relative_indent_last_virtualedit')
  if moved_from_blank_line
    let &l:virtualedit = w:relative_indent_last_virtualedit
    unlet w:relative_indent_last_virtualedit
    if exists('w:relative_indent_last_cursor')
      let w:relative_indent_last_cursor[1] = cursor[1]
      let cursor = w:relative_indent_last_cursor
    endif
  elseif !cursor_at_blank_line
    let w:relative_indent_last_cursor = cursor
  endif

  let precedes_shown = &l:list && !empty(matchstr(&l:listchars, 'precedes:\S'))
  if minindent > 0 && precedes_shown
      let minindent -= 1
  endif

  " Reset horizontal scroll
  execute 'normal 999zh'
  if minindent > 0
    " Hide indent by scrolling the window to the RIGHT
    execute 'normal '.minindent.'zl'
  endif

  if cursor_at_blank_line
    " Emulate how vim would place the cursor at a blank line
    " by placing it at the left of the window
    let cursor[2] = minindent + (precedes_shown ? 1 : 0)
    let cursor[3] = 1
  elseif moved_from_blank_line
    " Vim won't set curswant with `setpos()`,
    " it only does so when moving the cursor vertically,
    " so set it manually
    if cursor[4] > cursor[2]
      let curr_line_contents = get(l:, 'curr_line_contents', getline(cursor[1]))
      let cursor[2] = min([strlen(curr_line_contents), cursor[4]])
    endif
  endif
  call setpos('.', cursor)

  let w:relative_indent_last_indent = minindent
endfunction

command! RelativeIndent call <SID>RelativeIndent()

" augroup relative_indent
"   autocmd!
"   autocmd WinEnter,CursorMoved,VimResized * :RelativeIndent
" augroup END
