" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    15

if !exists('g:trag#external#ack#opts')
    let g:trag#external#ack#opts = {'grepprg': 'ack', 'args': '-Hns --nocolor --nogroup %s --'}   "{{{2
endif


if !exists('g:trag#external#ack#supported_kinds')
    let g:trag#external#ack#supported_kinds = ['identity', 'u', 'w', 'todo']   "{{{2
endif


function! trag#external#ack#IsSupported(kinds) "{{{3
    return trag#IsSupported(g:trag#external#ack#supported_kinds, a:kinds)
endf


function! trag#external#ack#Run(kinds, rx, files) "{{{3
    return trag#external#grep#Run(a:kinds, a:rx, a:files, g:trag#external#ack#opts)
endf

