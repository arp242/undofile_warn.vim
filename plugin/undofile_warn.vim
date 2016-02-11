" undofile_warn.vim: Warn when using the undofile.
"
" http://code.arp242.net/undofile.vim
"
" See the bottom of this file for copyright & license information.


"##########################################################
" Initialize some stuff
scriptencoding utf-8
if exists('g:loaded_undofile_warn') | finish | endif
let g:loaded_undofile_warn = 1
let s:save_cpo = &cpo
set cpo&vim


"##########################################################
" The default settings

set undofile

" When loading a file, store the current undo sequence
augroup undofile_warn
	autocmd!
	autocmd BufReadPost,BufCreate,BufNewFile *
		\  let b:undofile_warn_saved = undotree()['seq_cur']
		\| let b:undofile_warn_warned = []
	autocmd! InsertEnter * let b:undofile_warn_warned = []
	"autocmd BufReadPost * call s:check_valid_file()

	" Reset the warning after inserting text. For example you press 'u', then
	" insert text, and press 'u' several times again: you don't get a warning
	" anymore.
	autocmd TextChanged,TextChangedI let b:undofile_warn_warned = []
augroup end

if !exists('g:undofile_warn_prevent')
	let g:undofile_warn_prevent = 1
endif


"##########################################################
" Mappings

nnoremap <silent> <expr> <Plug>(undofile-warn-undo)  undofile_warn#undo()
nnoremap <silent>        <Plug>(undofile-warn-redo)  <C-r>:call undofile_warn#redo()<CR>

" TODO: What about |g-|? |U|? More?
if !exists('g:undofile_warn_no_map') || empty(g:undofile_warn_no_map)
	nmap u     <Plug>(undofile-warn-undo)
	nmap <C-r> <Plug>(undofile-warn-redo)
endif


"##########################################################
" Functions

fun! undofile_warn#undo() abort
	" This happens when :noau is used; doing nothing is probably best
	if !exists('b:undofile_warn_warned') | return 'u' | endif

	" Don't do anything if we can't modify the buffer or there's no filename
	if !&l:modifiable || expand('%') == '' | return 'u' | endif

	let l:cur = undotree()['seq_cur']

	" Warn if the current undo sequence is lower (older) than whatever it was
	" when opening the file
	if empty(b:undofile_warn_warned) && l:cur <= b:undofile_warn_saved
		let b:undofile_warn_warned = add(getpos('.'), l:cur)

		if !g:undofile_warn_prevent
			echohl ErrorMsg | echo 'Using undofile.' | echohl None
			sleep 1
			return 'u"'
		else
			echohl ErrorMsg | echo 'Using undofile; press u again to undo.' | echohl None
			return ''
		endif
	else
		return 'u'
	endif
endfun


fun! undofile_warn#redo() abort
	" This happens when :noau is used; doing nothing is probably best
	if !exists('b:undofile_warn_warned') | return 'u' | endif

	" Don't do anything if we can't modify the buffer or there's no filename
	if !&l:modifiable || expand('%') == '' | return | endif

	" Reset the warning flag
	if !empty(b:undofile_warn_warned) && undotree()['seq_cur'] >= b:undofile_warn_saved
		let b:undofile_warn_warned = []
	endif
endfun
	

" Do something sane when an error occurred.
fun! s:check_valid_file() abort
	" E823: Not an undo file: /home/martin/.vim/tmp/undo/%home%martin%src%qutebrowser%tests%utils%test_urlutils.py 
	" I've sometimes had it happen that after a crash (Vim or system) the undo
	" file is completely empty, in which case it makes no sense keeping it.
	"
	" TODO: How to get the error message?
	"echo errmsg
endfun


let &cpo = s:save_cpo
unlet s:save_cpo


" The MIT License (MIT)
"
" Copyright © 2015-2016 Martin Tournoij
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to
" deal in the Software without restriction, including without limitation the
" rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
" sell copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" The software is provided "as is", without warranty of any kind, express or
" implied, including but not limited to the warranties of merchantability,
" fitness for a particular purpose and noninfringement. In no event shall the
" authors or copyright holders be liable for any claim, damages or other
" liability, whether in an action of contract, tort or otherwise, arising
" from, out of or in connection with the software or the use or other dealings
" in the software.
