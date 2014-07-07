" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    30

if !exists('g:trag#external#ag#opts')
    let g:trag#external#ag#opts = {'grepprg': 'ag', 'args': '-U -f --line-numbers --nogroup --nocolor -- %s'}   "{{{2
endif

" if !exists('g:trag#external#ag#opts_identity')
"     let g:trag#external#ag#opts_identity = {'grepprg': 'ag', 'args': '-Q -U -f --line-numbers --nogroup --nocolor -- %s'}   "{{{2
" endif


if !exists('g:trag#external#ag#supported_kinds')
    let g:trag#external#ag#supported_kinds = ['identity', 'u', 'w', 'todo']   "{{{2
endif


function! trag#external#ag#IsSupported(kinds) "{{{3
    return trag#IsSupported(g:trag#external#ag#supported_kinds, a:kinds)
endf


function! trag#external#ag#Run(kinds, rx, files) "{{{3
    " TLogVAR a:kinds, a:rx, len(a:files)
    let kind = join(tlib#list#Flatten(a:kinds), '_')
    let opts = exists('g:trag#external#ag#opts_'. kind) ? g:trag#external#ag#opts_{kind} : g:trag#external#ag#opts
    return trag#external#grep#Run(a:kinds, a:rx, a:files, opts)
endf

