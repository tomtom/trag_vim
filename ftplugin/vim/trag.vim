" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    6

if !exists('g:loaded_trag') || exists('g:ftplugin_trag_vim')
    finish
endif
let g:ftplugin_trag_vim = 1

TRagDefFiletype vim vim .vimrc _vimrc
TRagKeyword vim [:alnum:]_:#
TRagDefKind W vim /\C[^|]\{-}%s[^|]\{-}/
TRagDefKind d vim /\C\<\%(fu\%%[nction]!\?\s\+\|com\%%[mand]!\?\s\+\%(-\S\+\s\+\)*\)%s/
TRagDefKind f vim /\C\%(\<fu\%%[nction]!\?\s\+\)\@<!%s\s*(/
TRagDefKind i vim /\C^\s*"%s/
TRagDefKind r vim /\C^\s*let\s\+\S\+\s*=[^|]\{-}%s/
TRagDefKind l vim /\C^\s*let\s\+%s/


