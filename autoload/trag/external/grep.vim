" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2014-06-30.
" @Revision:    46


if !exists('g:trag#external#grep#cmd')
    let g:trag#external#grep#cmd = fnamemodify(findfile('autoload/trag/external/grep.sh', &rtp), ':p') "{{{2
endif


if !exists('g:trag#external#grep#args')
    let g:trag#external#grep#args = '%s %s'   "{{{2
endif


if !exists('g:trag#external#grep#efm')
    let g:trag#external#grep#efm = '%f:%l:%m'   "{{{2
endif


function! trag#external#grep#Run(rx, files) "{{{3
    let tmpfile = tempname()
    let files = tlib#sys#FileArgs(g:trag#external#grep#cmd, a:files)
    call writefile(files, tmpfile)
    let efm = &efm
    let makeprg = &makeprg
    try
        let cmd = g:trag#external#grep#cmd
        let cmd = printf('bash -c' .' '. cmd .' '. g:trag#external#grep#args,
                    \ shellescape(escape(a:rx, '\')),
                    \ shellescape(tmpfile))
        TLogVAR cmd
        let &efm = g:trag#external#grep#efm
        let &makeprg = cmd
        make
        return 1
    finally
        let &efm = efm
        let &makeprg = makeprg
        if filereadable(tmpfile)
            call delete(tmpfile)
        endif
    endtry
    return 0
endf

