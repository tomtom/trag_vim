" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2009-02-27.
" @Revision:    6


function! trag#viki#Rename(world, selected, from, to) "{{{3
    let suffix = tlib#var#Get('vikiNameSuffix', 'bg', '')
    return trag#rename#Rename(a:world, a:selected, a:from, a:to, suffix)
endf

