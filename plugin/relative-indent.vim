" File:        plugin/relative-indent.vim
" Author:      fent (https://github.com/fent)
" Description: Hide indentation levels

if exists('g:loaded_relative_indent')
  finish
endif
let g:loaded_relative_indent = 1

function! s:RelativeIndent()
  let l:cursor = getcurpos()
  " Don't hide indent past the cursor
  if &l:virtualedit !=# 'all' || exists('w:relative_indent_last_virtualedit')
    let l:curr_line_contents = getline(l:cursor[1])
    let l:cursor_at_blank_line = empty(matchstr(l:curr_line_contents, '[^\s]'))
    let l:moved_from_blank_line = !l:cursor_at_blank_line && exists('w:relative_indent_last_virtualedit')
    if l:cursor_at_blank_line
      if exists('w:relative_indent_last_cursor')
        let l:minindent = w:relative_indent_last_cursor[2] - 1
      else
        let l:minindent = 2147483647
      endif
    elseif l:moved_from_blank_line && exists('w:relative_indent_last_cursor')
      let l:minindent = w:relative_indent_last_cursor[2] - 1
    endif
  else
    let l:cursor_at_blank_line = 0
    let l:moved_from_blank_line = 0
  endif
  let l:minindent = get(l:, 'minindent', l:cursor[2] - 1)
  let l:topline = line('w0')
  let l:botline = line('w$')

  " Find the line with the least indent
  if l:minindent > 0
    for l:i in range(l:topline, l:botline)
      " An indent of 0 is already the minimum
      let l:line_indent = indent(l:i)
      if l:line_indent == 0
        let l:line_contents = getline(l:i)
        " Ignore blank lines with zero length
        if strlen(l:line_contents) == 0
          continue
        else
          let l:minindent = 0
          break
        endif
      endif

      " Ignore blank lines of whitespace
      let l:line_contents = getline(l:i)
      if empty(matchstr(l:line_contents, '[^\s]'))
        continue
      endif

      if l:minindent > l:line_indent
        let l:minindent = l:line_indent
      endif
    endfor
  endif

  " If this line is where the cursor is, enable virtualedit mode
  " so that the cursor doesn't jump to column 0
  if l:cursor_at_blank_line && &l:virtualedit !=# 'all'
    let w:relative_indent_last_virtualedit = &l:virtualedit
    let &l:virtualedit = 'all'
  endif

  " When moving from a blank line to a non blank line,
  " restore the cursor column to the last column it was at
  " on a non blank line
  if l:moved_from_blank_line
    let &l:virtualedit = w:relative_indent_last_virtualedit
    unlet w:relative_indent_last_virtualedit
    if exists('w:relative_indent_last_cursor')
      let w:relative_indent_last_cursor[1] = l:cursor[1]
      let l:cursor = w:relative_indent_last_cursor
    endif
  elseif !l:cursor_at_blank_line || !exists('w:relative_indent_last_cursor')
    let w:relative_indent_last_cursor = l:cursor
  endif

  let l:precedes_shown = l:minindent > 0 && &l:list && !empty(matchstr(&l:listchars, 'precedes:\S'))
  if l:precedes_shown
      let l:minindent -= 1
  endif

  " Reset horizontal scroll
  execute 'normal 999zh'
  if l:minindent > 0
    " Hide indent by scrolling the window to the right
    execute 'normal '.l:minindent.'zl'
  endif

  if l:cursor_at_blank_line
    " Emulate how vim would place the cursor at a blank line
    " by placing it at the left of the window
    let l:cursor[2] = l:minindent + (l:precedes_shown ? 1 : 0)
    let l:cursor[3] = l:precedes_shown ? 1 : 0
  elseif l:moved_from_blank_line
    " Vim won't set curswant with `setpos()`,
    " it only does so when moving the cursor vertically,
    " so set it manually
    if l:cursor[4] > l:cursor[2]
      let l:curr_line_contents = get(l:, 'curr_line_contents', getline(l:cursor[1]))
      let l:cursor[2] = min([strlen(l:curr_line_contents), l:cursor[4]])
    endif
  endif
  call setpos('.', l:cursor)
endfunction

function! s:RelativeIndentEnable()
  augroup relative_indent_enabling_group
    autocmd!
    autocmd WinEnter,WinLeave,CursorMoved,VimResized,TextChanged * :RelativeIndent
  augroup END
  nnoremap <c-e> <buffer> <c-e>:calls<SID>RelativeIndent()<cr>
  nnoremap <c-y> <buffer> <c-y>:calls<SID>RelativeIndent()<cr>
  inoremap <c-x><c-e> <buffer> <c-x><c-e>:calls<SID>RelativeIndent()<cr>
  inoremap <c-x><c-y> <buffer> <c-x><c-y>:calls<SID>RelativeIndent()<cr>
endfunction

function! s:RelativeIndentDisable()
  augroup relative_indent_enabling_group
    autocmd!
  augroup END
  nunmap <c-e> <buffer>
  nunmap <e-y> <buffer>
  iunmap <c-x><c-e> <buffer>
  iunmap <c-x><c-y> <buffer>
endfunction

command! RelativeIndent call <SID>RelativeIndent()
command! RelativeIndentEnable call <SID>RelativeIndentEnable()
command! RelativeIndentDisable call <SID>RelativeIndentDisable()
