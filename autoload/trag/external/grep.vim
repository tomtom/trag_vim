" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2014-07-01.
" @Revision:    63


if !exists('g:trag#external#grep#supported_kinds')
    let g:trag#external#grep#supported_kinds = ['identity']   "{{{2
endif


function! trag#external#grep#IsSupported(kinds) "{{{3
    return trag#IsSupported(g:trag#external#grep#supported_kinds, a:kinds)
endf


function! trag#external#grep#Run(rx, files) "{{{3
    let files = copy(a:files)
    let files = map(copy(files), 'fnameescape(v:val)')
    " let files = map(copy(files), 'shellescape(v:val)')
    exec 'grepadd!' join(files)
    return 1
endf

