" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    19

if !exists('g:trag#external#ag#opts')
    let g:trag#external#ag#opts = {'grepprg': 'ag', 'args': '-U -f --line-numbers --nogroup --nocolor -- %s'}   "{{{2
endif


if !exists('g:trag#external#ag#supported_kinds')
    let g:trag#external#ag#supported_kinds = ['identity', 'w', 'todo']   "{{{2
endif


function! trag#external#ag#IsSupported(kinds) "{{{3
    return trag#IsSupported(g:trag#external#ag#supported_kinds, a:kinds)
endf


function! trag#external#ag#Run(rx, files) "{{{3
    return trag#external#grep#Run(a:rx, a:files, g:trag#external#ag#opts)
endf

