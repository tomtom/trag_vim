" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2009-02-27.
" @Revision:    25

function! trag#java#Rename(world, selected, from, to) "{{{3
    return trag#rename#Rename(a:world, a:selected, a:from, a:to, suffix)
endf

