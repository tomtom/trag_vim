" trag.vim -- Jump to a file registered in your tags
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-09-29.
" @Last Change: 2015-11-07.
" @Revision:    733
" GetLatestVimScripts: 2033 1 trag.vim

if &cp || exists("g:loaded_trag")
    finish
endif
let g:loaded_trag = 200

let s:save_cpo = &cpo
set cpo&vim


" :nodoc:
TLet g:trag_kinds = {}
" :nodoc:
TLet g:trag_keyword_chars = {}

" Trag map leader. See also |TragInstallMap()|.
TLet g:trag_map_leader = '<Leader>r'

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
command! -bang -nargs=1 TRagDefKind call trag#TragDefKind(<q-args>, !empty("<bang>"))


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


" :display: :Trag[!] [ARGS] [REGEXP] [GLOBPATTERN]
" Scan the files registered in your tag files for REGEXP. Generate a 
" quickfix list. With [!], append to the given list. The quickfix list 
" can be viewed with commands like |:cw| or |:Tragcw|.
"
" The REGEXP has to match a single line. This uses |readfile()| and the 
" scans the lines. This is an alternative to |:vimgrep|.
" If you choose your identifiers wisely, this should guide you well 
" through your sources.
"
" Supported command-line options for ARGS:
"
"   -i=KINDS, --include=KINDS ... Include KINDS (default: .)
"   -x=KINDS, --exclude=KINDS ... Exclude KINDS
"   -A=REGEXP, --accept=REGEXP .. Include files matching REGEXP
"   -R=REGEXP, --reject=REGEXP .. Exclude files matching REGEXP
"   --filetype=FILETYPE ......... Assume 'filetype' is FILETYPE
"   -l, --literal ............... RX is a literal text, not a |regexp|
"   --grep_type=GREP_TYPE ....... See |g:trag#grep_type|
"   --file_sources=SOURCES ...... A comma-separated list of sources (see 
"                                 |g:trag#file_sources|)
"   --filenames ................. Include matching filenames
"   --no-text ................... Don't include matching text lines
"   --glob=PATTERN .............. Pattern for "glob" source
"   --force ..................... Don't use cached information
"   --cw=CMD .................... Command to use for displaying the 
"                                 result (default: :Tragcw; use "none" 
"                                 in order not to display the results 
"                                 list)
"
" Positional arguments:
"   REGEXP ...................... A |regexp| or text (see --literal)
"   GLOB PATTERNS ............... Optional |glob| patterns
" 
" If the kind rx doesn't contain %s (e.g. todo), you can skip the 
" regexp.
"
" Examples: >
"     " Find any matches
"     Trag foo
" 
"     " Find variable definitions (word on the left-hand): foo = 1
"     Trag -i=l foo
" 
"     " Find variable __or__ function/method definitions
"     Trag -i=d,l foo
" 
"     " Find function calls like: foo(a, b)
"     Trag -i=f foo
"
"     " Find TODO markers
"     Trag -i=todo
command! -nargs=+ -bang -bar -complete=customlist,trag#CComplete Trag call trag#GrepWithArgs([<f-args>], empty("<bang>"))


" :display: :Tragcw
" Display a quick fix list using |tlib#input#ListD()|.
command! -bang -nargs=? Tragcw call trag#QuickListMaybe(!empty("<bang>"))

" :display: :Traglw
" Display a |location-list| using |tlib#input#ListD()|.
command! -nargs=? Traglw call trag#LocList()


" :display: :Tragfiles
" Edit a file registered in your tag files.
command! Tragfiles call trag#Edit()


" Install the following maps:
"
"   <trag_map_leader># ........ Search word under cursor
"   <trag_map_leader>. ........ :Trag * <Input>
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
    exec 'noremap' a:leader .'. :Trag '
    exec 'noremap' a:leader .'+ :Tragcw<cr>'
    exec 'noremap' a:leader .'* :Tragfiles<cr>'
    exec 'noremap <silent>' a:leader .'# :Trag -l -i=w <c-r>=trag#CWord()<cr><cr>'
    for kind in keys(g:trag_kinds)
        call TragInstallKindMap(leader, kind)
    endfor
endf


function! TragInstallKindMap(leader, kind) "{{{3
    " TLogVAR a:leader, a:kind
    if len(a:kind) == 1
        let kind = a:kind
        let excl = index(g:trag_kinds_ignored_comments, kind) == -1 ? '' : '-x=i'
        exec 'nnoremap' a:leader . a:kind ':Trag -l -i='. kind excl '<c-r>=trag#CWord()<cr><cr>'
        exec 'vnoremap' a:leader . a:kind 'y<esc>:Trag -l -i='. kind excl '<c-r>"<cr>'
    endif
endf

if !empty(g:trag_map_leader)
    call TragInstallMap(g:trag_map_leader)
endif


let &cpo = s:save_cpo
unlet s:save_cpo
