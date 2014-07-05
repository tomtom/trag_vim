" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    13


function! trag#rx#ConvertRx(rx, type, ...) "{{{3
    let opts = a:0 >= 1 ? a:1 : {}
    " TLogVAR a:rx, a:type, opts
    let convert_rx = get(opts, 'convert_rx', 'trag#rx#ConvertRx_'. a:type)
    " TLogVAR convert_rx
    if exists('*'. convert_rx)
        let rx = call(convert_rx, [a:type, a:rx])
    else
        let rx = a:rx
    endif
    " TLogVAR rx
    return rx
endf


function! trag#rx#ConvertRx_git(type, rx) "{{{3
    let rx = substitute(a:rx, '\\C', '', 'g')
    " let rx = substitute(a:rx, '\\{-}', '\\+\\?', 'g')
    return rx
endf


function! trag#rx#ConvertRx_perl(type, rx) "{{{3
    let rx = substitute(a:rx, '\\C', '', 'g')
    let rx = substitute(rx, '\\[<>]', '\\b', 'g')
    let rx = substitute(rx, '\\{-}', '*?', 'g')
    let rxl = []
    " TLogVAR rx
    for part in split(rx, '[()|+?]\zs')
        " TLogVAR 1, part
        if part =~ '\\\@<!\\[()|]$'
            let part = substitute(part, '\\\ze.$', '', '')
        elseif part =~ '[()|]$'
            let part = substitute(part, '.$', '\\\0', '')
        endif
        " TLogVAR 2, part
        call add(rxl, part)
    endfor
    let rx = join(rxl, '')
    return rx
endf


