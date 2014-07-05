" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    27


if !exists('g:trag#utils#cmdline_max')
    let g:trag#utils#cmdline_max = g:tlib#sys#windows ? 7000 : 2000000   "{{{2
endif


function! trag#utils#GrepaddFiles(args, files) "{{{3
    let files = map(copy(a:files), 'shellescape(fnameescape(v:val))')
    " TLogVAR files
    " TLogVAR len(files)
    let flen = len(files)
    let fidx = 0
    while fidx < flen
        let use_files = []
        let ulen = 0
        while fidx < flen
            let file = files[fidx]
            if ulen + len(file) < g:trag#utils#cmdline_max
                call add(use_files, file)
                let fidx += 1
                let ulen += len(file)
            else
                break
            endif
        endwh
        let filess = join(use_files)
        " TLogVAR len(filess)
        " TLogVAR use_files
        exec 'silent grepadd!' a:args filess
    endwh
    " echom '-- PRESS ENTER --' | call getchar() " DBG
endf

