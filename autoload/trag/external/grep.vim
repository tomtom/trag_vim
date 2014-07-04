" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2014-07-03.
" @Revision:    94


if !exists('g:trag#external#grep#args')
    let g:trag#external#grep#args = '-Hn -E %s --'   "{{{2
endif


if !exists('g:trag#external#grep#supported_kinds')
    let g:trag#external#grep#supported_kinds = ['identity', 'w', 'todo']   "{{{2
endif


function! trag#external#grep#IsSupported(kinds) "{{{3
    return trag#IsSupported(g:trag#external#grep#supported_kinds, a:kinds)
endf


function! trag#external#grep#Run(rx, files, ...) "{{{3
    let grep_params = a:0 >= 1 ? a:1 : {}
    let grep_prg0 = &grepprg
    let grep_format0 = &grepformat
    let grep_prg1 = get(grep_params, 'grepprg', grep_prg0)
    let grep_format1 = get(grep_params, 'grepformat', grep_format0)
    let rx = trag#rx#ConvertRx(a:rx, 'perl', grep_params)
    " TLogVAR a:rx, rx
    let args = get(grep_params, 'args', g:trag#external#grep#args)
    let args = tlib#string#Printf1(args, shellescape(rx, 1))
    if grep_prg0 != grep_prg1
        let &grepprg = grep_prg1
    endif
    if grep_format0 != grep_format1
        let &grepformat = grep_format1
    endif
    " TLogVAR &grepprg, &grepformat, args
    try
        call trag#utils#GrepaddFiles(args, a:files)
        return 1
    finally
        if grep_prg0 != grep_prg1
            let &grepprg = grep_prg0
        endif
        if grep_format0 != grep_format1
            let &grepformat = grep_format0
        endif
    endtry
endf

