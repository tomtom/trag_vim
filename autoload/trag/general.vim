" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-12-01.
" @Revision:    8


function! trag#general#Rename(world, selected, rx, subst) "{{{3
    let cmd = 's/\C\<'. escape(tlib#rx#Escape(a:rx), '/') .'\>/'. escape(tlib#rx#EscapeReplace(a:subst), '/') .'/ge'
    " let cmd = 's/\C'. escape(a:rx, '/') .'/'. escape(tlib#rx#EscapeReplace(a:subst), '/') .'/ge'
    return tlib#qfl#RunCmdOnSelected(a:world, a:selected, cmd)
endf

