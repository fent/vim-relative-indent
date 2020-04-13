" File:        plugin/relative-indent.vim
" Author:      fent (https://github.com/fent)
" Description: Hide indentation levels

if exists('g:loaded_relative_indent')
  finish
endif
let g:loaded_relative_indent = 1

function! s:CheckListchars()
  let b:relative_indent_precedes_shown =
    \ &l:list &&
    \ !empty(matchstr(&l:listchars, 'precedes:\S'))
  let b:relative_indent_default_tab =
    \ &l:list && empty(matchstr(&l:listchars, 'tab:'))
endfunction

function! s:CheckVirtualEdit()
  let s:real_virtualedit = &virtualedit
endfunction

autocmd OptionSet virtualedit :call <SID>CheckVirtualEdit()
call s:CheckVirtualEdit()

function! s:RelativeIndent()
  if &l:wrap || mode() !~? '^[nv]'
    return
  endif

  let l:cursor = getcurpos()
  " Don't hide indent past the cursor
  if &virtualedit !=# 'all' || s:real_virtualedit !=# &virtualedit
    let l:cursor_at_blank_line = strlen(getline(l:cursor[1])) == 0
    let l:moved_from_blank_line =
      \ !l:cursor_at_blank_line &&
      \ s:real_virtualedit !=# &virtualedit
    if l:cursor_at_blank_line
      let l:minindent = exists('w:relative_indent_last_cursor') ?
        \  w:relative_indent_last_cursor[4] - 1 : 2147483647
    endif
  else
    let l:cursor_at_blank_line = 0
    let l:moved_from_blank_line = 0
  endif
  let l:minindent = get(l:, 'minindent', l:cursor[4] - 1)
  let l:topline = line('w0')
  let l:botline = line('w$')

  " Find the line with the least indent
  if l:minindent > 0
    let l:nonblank_found = 0
    for l:line_num in range(l:topline, l:botline)
      " An indent of 0 is already the minimum
      let l:line_indent = indent(l:line_num)
      if l:line_indent == 0
        let l:line_contents = getline(l:line_num)
        " Ignore blank lines with zero length
        if strlen(l:line_contents) == 0
          continue
        else
          let l:minindent = 0
          break
        endif
      endif

      " Ignore blank lines of whitespace
      let l:line_contents = getline(l:line_num)
      if empty(matchstr(l:line_contents, '\S'))
        continue
      endif

      " Default tab is printed at 2 characters no matter the `tabstop`
      " but `indent()` will still return the total indent in spaces
      if b:relative_indent_default_tab && !empty(matchstr(l:line_contents, '^\t\+'))
        let l:line_indent = l:line_indent / &l:tabstop * 2
      endif

      let l:nonblank_found = 1
      if l:minindent > l:line_indent
        let l:minindent = l:line_indent
      endif

    endfor

    " In case the window only shows blank lines, or no lines
    if l:minindent > 0 && !l:nonblank_found
      let l:minindent = 0
    endif
  endif

  " If the cursor is at a blank line, enable virtualedit mode
  " so that the cursor doesn't jump to column 0
  if l:cursor_at_blank_line && &virtualedit !=# 'all'
    noautocmd let &virtualedit = 'all'
  endif

  " When moving from a blank line to a non blank line,
  " restore the cursor column to the last column it was at
  " on a non blank line
  if l:moved_from_blank_line
    noautocmd let &virtualedit = s:real_virtualedit
    if exists('w:relative_indent_last_cursor')
      let w:relative_indent_last_cursor[1] = l:cursor[1]
      if l:cursor[2] > l:minindent + 1
        let w:relative_indent_last_cursor[2] = l:cursor[2]
        let w:relative_indent_last_cursor[4] = l:cursor[4]
      endif
      let l:cursor = w:relative_indent_last_cursor
    endif
  elseif !l:cursor_at_blank_line || !exists('w:relative_indent_last_cursor')
    let w:relative_indent_last_cursor = l:cursor
  endif

  let l:precedes_shown =
    \ l:minindent > 0 &&
    \ b:relative_indent_precedes_shown

  " Export a variable that can be used in statusline
  let w:relative_indent_level = !l:precedes_shown || l:minindent > 1 ? l:minindent / shiftwidth() : 0

  if l:precedes_shown && l:minindent > 0
    " Move the window one unit left if precedes is shown
    " so that the precedes char doesn't block text
    let l:minindent -= 1
  endif

  " Reset horizontal scroll
  execute 'normal! 999zh'
  if l:minindent > 0
    " Hide indent by scrolling the window to the right
    execute 'normal! '.l:minindent.'zl'
  endif

  if l:cursor_at_blank_line
    let l:cursor[3] = l:minindent + (l:precedes_shown ? 1 : 0)
    " Place cursor one unit to the right of the precedes column
    let l:cursor[2] = 0
    if exists('w:relative_indent_last_cursor')
      let l:cursor[4] = w:relative_indent_last_cursor[4]
    endif
  elseif l:moved_from_blank_line
    " Vim won't set curswant with `setpos()`,
    " so we have to set the column to curswant and see if we can move there.
    let l:cursor[2] = l:cursor[4]
  endif
  call setpos('.', l:cursor)
endfunction

function! s:CheckWrap()
  if &l:wrap
    if s:real_virtualedit !=# &virtualedit
      noautocmd let &virtualedit = s:real_virtualedit
    endif
  else
    call s:RelativeIndent()
  endif
endfunction

function! s:RelativeIndentEnable()
  augroup relative_indent_enabling_group
    autocmd! * <buffer>
    autocmd CursorMoved,VimResized,TextChanged <buffer> :call <SID>RelativeIndent()
    autocmd WinEnter <buffer> :call <SID>CheckListchars() | :call <SID>RelativeIndent()
    autocmd OptionSet list,listchars :call <SID>CheckListchars() | :call <SID>RelativeIndent()
    autocmd OptionSet wrap :call <SID>CheckWrap()
    autocmd OptionSet sidescrolloff :call <SID>RelativeIndent()
  augroup END
  nnoremap <buffer><silent> <c-e> <c-e>:call <SID>RelativeIndent()<cr>
  nnoremap <buffer><silent> <c-y> <c-y>:call <SID>RelativeIndent()<cr>
  inoremap <buffer><silent> <c-x><c-e> <c-x><c-e><esc>:call <SID>RelativeIndent()<cr>a
  inoremap <buffer><silent> <c-x><c-y> <c-x><c-y><esc>:call <SID>RelativeIndent()<cr>a
  call s:CheckListchars()
  if empty(expand('<amatch>'))
    call s:RelativeIndent()
  endif
endfunction

function! s:RelativeIndentDisable()
  augroup relative_indent_enabling_group
    autocmd!
  augroup END
  nunmap <buffer> <c-e>
  nunmap <buffer> <c-y>
  iunmap <buffer> <c-x><c-e>
  iunmap <buffer> <c-x><c-y>
  if s:real_virtualedit !=# &virtualedit
    noautocmd let &virtualedit = s:real_virtualedit
  endif
  unlet! w:relative_indent_last_cursor
  unlet! w:relative_indent_level
  unlet! b:relative_indent_precedes_shown
  execute 'normal! 999zh'
endfunction

command! RelativeIndent call <SID>CheckListchars()<Bar>call <SID>RelativeIndent()
command! RelativeIndentEnable call <SID>RelativeIndentEnable()
command! RelativeIndentDisable call <SID>RelativeIndentDisable()
