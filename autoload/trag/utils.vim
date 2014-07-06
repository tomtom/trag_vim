" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    55


if !exists('g:trag#utils#cmdline_max')
    let g:trag#utils#cmdline_max = g:tlib#sys#windows ? 7000 : 100000   "{{{2
    " let g:trag#utils#cmdline_max = 500   " DBG
endif


function! trag#utils#GrepaddFiles(args, files) "{{{3
    let files = map(copy(a:files), 'shellescape(fnameescape(v:val), 1)')
    " TLogVAR a:args, files
    " TLogVAR len(files)
    let flen = len(files)
    let fidx = 0
    while fidx < flen
        let use_files = []
        let ulen = 0
        while fidx < flen
            let file = files[fidx]
            let ulen1 = ulen + len(file)
            if ulen1 < g:trag#utils#cmdline_max
                call add(use_files, file)
                let fidx += 1
                let ulen = ulen1
            else
                break
            endif
        endwh
        let filess = join(use_files)
        " TLogVAR len(filess)
        " TLogVAR use_files
        try
            " TLogVAR &grepprg, &grepformat
            " echom 'DBG' 'silent grepadd!' a:args
            exec 'silent grepadd!' a:args filess
        catch
            echohl Error
            echom 'Trag: Error when calling grepadd:' len(filess) filess
            echohl NONE
        endtry
    endwh
    " echom '-- PRESS ENTER --' | call getchar() " DBG
endf

