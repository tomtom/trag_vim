" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    37

if !exists('g:trag#external#rg#opts')
    let g:trag#external#rg#opts = {'grepprg': 'rg', 'args': '--no-heading --vimgrep -- %s', 'grepformat': '%f:%l:%c:%m'}   "{{{2
endif

" if !exists('g:trag#external#rg#opts_identity')
"     let g:trag#external#rg#opts_identity = {'grepprg': 'ag', 'args': '-Q -U -f --line-numbers --nogroup --nocolor -- %s'}   "{{{2
" endif


if !exists('g:trag#external#rg#supported_kinds')
    let g:trag#external#rg#supported_kinds = ['identity', 'u', 'w', 'todo']   "{{{2
endif


function! trag#external#rg#IsSupported(kinds) abort "{{{3
    return trag#IsSupported(g:trag#external#rg#supported_kinds, a:kinds)
endf


function! trag#external#rg#Run(kinds, rx, files) abort "{{{3
    " TLogVAR a:kinds, a:rx, len(a:files)
    let kind = join(tlib#list#Flatten(a:kinds), '_')
    let opts = exists('g:trag#external#rg#opts_'. kind) ? g:trag#external#rg#opts_{kind} : g:trag#external#rg#opts
    return trag#external#grep#Run(a:kinds, a:rx, a:files, opts)
endf

