" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2014-07-03.
" @Revision:    225


if !exists('g:trag#external#vcs#options_git')
    let g:trag#external#vcs#options_git = {'args': 'grep -Hn -G %s --'}  "{{{2
endif


" if !exists('g:trag#external#vcs#options_hg')
"     let g:trag#external#vcs#options_hg = {'args': 'grep -n %s --',
"                 \ 'convert_rx': 'trag#rx#ConvertRx_perl',
"                 \ 'gfm': '%f:%*[^:]:%l:%m'}  "{{{2
" endif


if !exists('g:trag#external#vcs#supported_kinds')
    let g:trag#external#vcs#supported_kinds = ['identity', 'w', 'todo']   "{{{2
endif


function! trag#external#vcs#IsSupported(kinds) "{{{3
    return trag#IsSupported(g:trag#external#vcs#supported_kinds, a:kinds)
endf


" Currently only git is supported.
" For other VCSs, I'd recommend to use "ag".
function! trag#external#vcs#Run(kinds, rx, files) "{{{3
    " TLogVAR a:rx, a:files
    if exists('b:trag_support_vcs')
        if empty(b:trag_support_vcs)
            return [0, a:files]
        else
            let [type, dir, bin] = b:trag_support_vcs
        endif
    else
        let b:trag_support_vcs = []
        let [type, dir] = tlib#vcs#FindVCS(expand('%:p'))
        if empty(type)
            return [0, a:files]
        endif
        if !exists('g:trag#external#vcs#options_'. type)
            " echom 'Trag: Unsupported VCS type:' type
            return [0, a:files]
        endif
        let bin = tlib#vcs#Executable(type)
        " TLogVAR bin
        if empty(bin)
            " echom 'Trag: Unsupported VCS type:' type
            return [0, a:files]
        endif
        let b:trag_support_vcs = [type, dir, bin]
        " TLogVAR b:trag_support_vcs
    endif
    " TLogVAR type, dir, bin
    let ddir = fnamemodify(dir, ':p:h:h')
    let cd = getcwd()
    " TLogVAR type, dir, ddir, cd
    let gfm = &gfm
    let grepprg = &grepprg
    try
        let vcs_fnames = tlib#vcs#Ls('', [type, dir])
        " TLogVAR vcs_fnames
        let vcs_files = tlib#list#ToDictionary(vcs_fnames, 1)
        " TLogVAR vcs_files
        let unprocessed_fnames = filter(copy(a:files), '!has_key(vcs_files, v:val)')
        " TLogVAR unprocessed_fnames
        let files = filter(copy(a:files), 'has_key(vcs_files, v:val)')
        " TLogVAR files
        let opts = g:trag#external#vcs#options_{type}
        " TLogVAR opts
        let rx = trag#rx#ConvertRx(a:rx, type, opts)
        " TLogVAR a:rx, rx
        let cmd = bin .' '. printf(get(opts, 'args', '%s'),
                    \ shellescape(rx, 1))
        let &grepprg = cmd
        " let &gfm = get(opts, 'gfm', '%m')
        let &gfm = get(opts, 'gfm', '%f:%l:%m')
        " TLogVAR &grepprg, &gfm
        let convert_filename = get(opts, 'convert_filename', 'trag#external#vcs#ConvertFilename_'. type)
        if exists('*'. convert_filename)
            let files = map(files, 'call(convert_filename, [type, v:val])')
        endif
        exec 'cd!' fnameescape(ddir)
        " TLogVAR getcwd()
        call trag#utils#GrepaddFiles('', files)
        return [1, unprocessed_fnames]
    finally
        if getcwd() != cd
            exec 'cd!' fnameescape(cd)
        endif
        let &gfm = gfm
        let &grepprg = grepprg
    endtry
    return [0, a:files]
endf


function! trag#external#vcs#ConvertFilename_git(type, filename) "{{{3
    return substitute(a:filename, '\\', '/', 'g')
endf


