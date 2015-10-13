" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    47


if !exists('g:trag#external#sift#ignore_dirs')
    let g:trag#external#sift#ignore_dirs = ['.git', '.hg']   "{{{2
endif


if !exists('g:trag#external#sift#opts')
    " "--exclude-dirs DIRS" will be replaced with the entries from 
    " |g:trag#external#sift#ignore_dirs|.
    let g:trag#external#sift#opts = {'grepprg': 'sift', 'args': '--exclude-dirs DIRS --no-color -n -- %s'}   "{{{2
endif

" if !exists('g:trag#external#sift#opts_identity')
"     let g:trag#external#sift#opts_identity = {'grepprg': 'ag', 'args': '-Q -U -f --line-numbers --nogroup --nocolor -- %s'}   "{{{2
" endif


if !exists('g:trag#external#sift#supported_kinds')
    let g:trag#external#sift#supported_kinds = ['identity', 'u', 'w', 'todo']   "{{{2
endif


function! trag#external#sift#IsSupported(kinds) "{{{3
    return trag#IsSupported(g:trag#external#sift#supported_kinds, a:kinds)
endf


function! trag#external#sift#Run(kinds, rx, files) "{{{3
    " TLogVAR a:kinds, a:rx, len(a:files)
    let kind = join(tlib#list#Flatten(a:kinds), '_')
    let opts = copy(exists('g:trag#external#sift#opts_'. kind) ? g:trag#external#sift#opts_{kind} : g:trag#external#sift#opts)
    let idirs = join(map(copy(g:trag#external#sift#ignore_dirs), '"--exclude-dirs ''". v:val ."''"'))
    let opts.args = substitute(get(opts, 'args', ''), '--exclude-dirs DIRS', tlib#rx#EscapeReplace(idirs), '')
    " TLogVAR opts
    return trag#external#grep#Run(a:kinds, a:rx, a:files, opts)
endf

