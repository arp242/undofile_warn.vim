" undofile_warn.vim: Warn when using the undofile.
" http://code.arp242.net/undofile.vim

scriptencoding utf-8
if exists('g:loaded_undofile_warn') | finish | endif
let g:loaded_undofile_warn = 1
let s:save_cpo = &cpo
set cpo&vim

let s:enabled = 1 " Keep track if this is enabled with :UndofileEnable


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

if !exists('g:undofile_warn_mode')
	let g:undofile_warn_mode = 1
endif


nnoremap <silent> <expr> <Plug>(undofile-warn-undo)  undofile_warn#undo()
nnoremap <silent>        <Plug>(undofile-warn-redo)  <C-r>:call undofile_warn#redo()<CR>

" TODO: What about |g-|? |U|? More?
if !exists('g:undofile_warn_no_map') || empty(g:undofile_warn_no_map)
	nmap u     <Plug>(undofile-warn-undo)
	nmap <C-r> <Plug>(undofile-warn-redo)
endif

command! -nargs=1 UndofileEnable call s:undofile_enable(<q-args>)

fun! s:undofile_enable(st) abort
	if a:st ==? 'yes' || a:st == '1'
		let s:enabled = 1
	elseif a:st ==? 'no' || a:st == '0'
		let s:enabled = 0
	elseif a:st ==? 'toggle'
		let s:enabled = {0: 1, 1: 0}[s:enabled]
	else
		echoerr 'Unknown value: ' . a:st
	endif
endfun

fun! undofile_warn#undo() abort
	" :UndofileEnabled no
	if !s:enabled | return 'u' | endif
	if !exists('b:undofile_warn_saved') | return 'u' | endif

	" This happens when :noau is used; doing nothing is probably best
	if !exists('b:undofile_warn_warned') | return 'u' | endif

	" Don't do anything if we can't modify the buffer or there's no filename
	if !&l:modifiable || expand('%') == '' | return 'u' | endif

	let l:cur = undotree()['seq_cur']

	" Undoing before we've hit the undofile
	if b:undofile_warn_saved < l:cur | return 'u' | endif

	" Always prevent
	if g:undofile_warn_mode == 3
		echohl ErrorMsg | echo 'Using undofile prevented; use ":UndofileEnable no" to continue.' | echohl None
		return ''
	endif

	" We warned already: so let's just undo!
	if !empty(b:undofile_warn_warned) | return 'u' | endif

	" Set warn point
	let b:undofile_warn_warned = add(getpos('.'), l:cur)

	" Warn but continue
	if g:undofile_warn_mode == 0
		echohl ErrorMsg | echo 'Using undofile.' | echohl None
		sleep 1
		return 'u'
	" Double-tap!
	elseif g:undofile_warn_mode == 1
		echohl ErrorMsg | echo 'Using undofile; press u again to undo.' | echohl None
		return ''
	" Ask.
	elseif g:undofile_warn_mode == 2
		if confirm('Use undofile? ', "&Yes\n&No", 2) == 1
			return 'u'
		else
			let b:undofile_warn_warned = []
			return ''
		endif
	else
		echoerr 'Invalid value for g:undofile_warn_mode: ' . g:undofile_warn_mode
	endif
endfun


fun! undofile_warn#redo() abort
	" This happens when :noau is used; doing nothing is probably best
	if !exists('b:undofile_warn_warned') | return | endif

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
