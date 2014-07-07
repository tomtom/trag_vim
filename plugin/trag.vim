" trag.vim -- Jump to a file registered in your tags
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-09-29.
" @Last Change: 2014-07-03.
" @Revision:    680
" GetLatestVimScripts: 2033 1 trag.vim

if &cp || exists("loaded_trag")
    finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 112
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 112
        echoerr 'tlib >= 0.112 is required'
        finish
    endif
endif
let loaded_trag = 101

let s:save_cpo = &cpo
set cpo&vim


" :nodoc:
TLet g:trag_kinds = {}
" :nodoc:
TLet g:trag_keyword_chars = {}

" Trag map leader. See also |TragInstallMap()|.
TLet g:trag_map_leader = '<Leader>r'

" A dictionary FILENAME_EXTENSION => FILETYPE
" On systems without has('fname_case') (see |feature-list|), 
" FILENAME_EXTENSION should be a lower-case string.
TLet g:trag_extension_filetype = {}

" A list of kinds for which |TragInstallKindMap()| will install maps 
" that ignore comments.
TLet g:trag_kinds_ignored_comments = ['c', 'd', 'f', 'l', 'r', 'u']


" :display: :TRagDefKind[!] KIND FILETYPE /REGEXP_FORMAT/
" The regexp argument is no real regexp but a format string. % thus have 
" to be escaped with % (see |printf()| for details). The REGEXP_FORMAT 
" should contain at least one %s.
"
" With the [!], reset the regexp definitions.
"
" Examples: >
"   TRagDefKind v * /\C\<%s\>\s*=[^=~<>]/
"   TRagDefKind v ruby /\C\<%s\>\(\s*,\s*[[:alnum:]_@$]\+\s*\)*\s*=[^=~<>]/
command! -bang -nargs=1 TRagDefKind call trag#TRagDefKind(<q-args>, !empty("<bang>"))


" :display: TRagKeyword FILETYPE KEYWORD_CHARS
" Override 'iskeyword' for a certain filetype. See also |trag#CWord()|.
command! -nargs=+ TRagKeyword if len([<f-args>]) == 2
            \ | let g:trag_keyword_chars[[<f-args>][0]] = [<f-args>][1]
            \ | else
                \ | echoerr 'Expected "FILETYPE KEYWORDRX", but got: <q-args>'
                \ | endif


" :display: TRagDefFiletype FILETYPE /REGEXP/ ... EXTENSION ... FILENAME ...
" In order to recognize files based on their extension, you have to 
" declare filetypes first.
" If a file has no extension, the whole filename is used.
" On systems where the case of the filename doesn't matter (check :echo 
" has('fname_case')), EXTENSION should be defined in lower case letters.
" Examples: >
"   TRagDefFiletype html html htm xhtml
command! -nargs=+ TRagDefFiletype call trag#DefFiletype([<f-args>])


" :display: :Trag[!] KIND [REGEXP]
" Run |:Tragsearch| and instantly display the result with |:Tragcw|.
" See |trag#Grep()| for help on the arguments.
" If the kind rx doesn't contain %s (e.g. todo), you can skip the 
" regexp.
"
" Examples: >
"     " Find any matches
"     Trag . foo
" 
"     " Find variable definitions (word on the left-hand): foo = 1
"     Trag l foo
" 
"     " Find variable __or__ function/method definitions
"     Trag d,l foo
" 
"     " Find function calls like: foo(a, b)
"     Trag f foo
"
"     " Find TODO markers
"     Trag todo
command! -nargs=1 -bang -bar Trag Tragsearch<bang> <args> | Tragcw


" :display: :Tragfile
" Edit a file registered in your tag files.
command! Tragfile call trag#Edit()


" :display: :Tragcw
" Display a quick fix list using |tlib#input#ListD()|.
command! -bang -nargs=? Tragcw call trag#QuickListMaybe(!empty("<bang>"))

" :display: :Traglw
" Display a |location-list| using |tlib#input#ListD()|.
command! -nargs=? Traglw call trag#LocList()


" :display: :Tragsearch[!] KIND REGEXP
" Scan the files registered in your tag files for REGEXP. Generate a 
" quickfix list. With [!], append to the given list. The quickfix list 
" can be viewed with commands like |:cw| or |:Tragcw|.
"
" The REGEXP has to match a single line. This uses |readfile()| and the 
" scans the lines. This is an alternative to |:vimgrep|.
" If you choose your identifiers wisely, this should guide you well 
" through your sources.
" See |trag#Grep()| for help on the arguments.
command! -nargs=1 -bang -bar Tragsearch call trag#Grep(<q-args>, empty("<bang>"))


" :display: :Traggrep REGEXP [GLOBPATTERN]
" A 99%-replacement for grep. The glob pattern is optional.
"
" Example: >
"   :Traggrep foo *.vim
"   :Traggrep bar
command! -nargs=+ -bang -bar -complete=file Traggrep
            \ let g:trag_grepargs = ['.', <f-args>]
            \ | call trag#Grep(g:trag_grepargs[0] .' '. g:trag_grepargs[1], empty("<bang>"), g:trag_grepargs[2:-1])
            \ | unlet g:trag_grepargs
            \ | Tragcw


" :display: :Tragsetfiles [GLOB PATTERN]
" The file list is set only once per buffer. If the list of the project 
" files has changed, you have to run this command on order to reset the 
" per-buffer list.
"
" If no filelist is given, collect the files in your tags files.
"
" Examples: >
"   :Tragsetfiles
"   :Tragsetfiles foo*.txt
command! -nargs=? -bar -complete=file Tragsetfiles call trag#SetFiles(<q-args>)

" :display: :Tragaddfiles FILELIST
" Add more files to the project list.
command! -nargs=1 -bar -complete=file Tragaddfiles call trag#AddFiles(<args>)

" :display: :Tragclearfiles
" Remove any files from the project list.
command! Tragclearfiles call trag#ClearFiles()

" :display: :TragGitFiles GIT_REPOS
command! -nargs=1 -bar -complete=dir TragGitFiles call trag#SetGitFiles(<q-args>)

command! -bar TragRepoFiles call trag#SetRepoFiles()


" Install the following maps:
"
"   <trag_map_leader># ........ Search word under cursor
"   <trag_map_leader>. ........ :Trag * <Input>
"   <trag_map_leader>- ........ :Tragfile
"
" The following maps might be defined only after the first invocation:
"
"   <trag_map_leader><KIND> ... Search word under cursor of KIND
"                               See |g:trag_kinds|
"
" E.g. <trag_map_leader>d searches for the definition of the word under 
" cursor.
function! TragInstallMap(leader) "{{{3
    " TLogVAR a:leader
    exec 'noremap' a:leader .'. :Trag * '
    exec 'noremap' a:leader .'- :Tragfile<cr>'
    exec 'noremap <silent>' a:leader .'# :Trag #w <c-r>=trag#CWord()<cr><cr>'
    for kind in keys(g:trag_kinds)
        call TragInstallKindMap(leader, kind)
    endfor
endf

function! TragInstallKindMap(leader, kind) "{{{3
    " TLogVAR a:leader, a:kind
    if len(a:kind) == 1
        let kind = a:kind
        if index(g:trag_kinds_ignored_comments, kind) != -1
            let kind .= ',-i'
        endif
        exec 'nnoremap' a:leader . a:kind ':Trag #'. kind '<c-r>=trag#CWord()<cr><cr>'
        exec 'vnoremap' a:leader . a:kind 'y<esc>:Trag #'. kind '<c-r>"<cr>'
    endif
endf

if !empty(g:trag_map_leader)
    call TragInstallMap(g:trag_map_leader)
endif


let &cpo = s:save_cpo
unlet s:save_cpo

