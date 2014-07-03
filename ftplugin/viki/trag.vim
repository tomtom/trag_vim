" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    4

if !exists('g:loaded_trag') || exists('g:ftplugin_trag_viki')
    finish
endif
let g:ftplugin_trag_viki = 1

TRagDefFiletype viki txt TXT viki dpl
TRagDefKind i viki /\C^\s*%%%s/
TRagDefKind d viki /\C^\s*#\u\w*\s\+.\{-}\%(id=%s\|%s=\)/
TRagDefKind h viki /\C^\*\+\s\+%s/
TRagDefKind l viki /\C^\s\+%s\s\+::/
TRagDefKind r viki /\C^\s\+\%(.\{-}\s::\|[-+*#]\|[@?].\)\s\+%s/
TRagDefKind todo viki /\C\%(TODO:\?\|FIXME:\?\|+++\|!!!\|###\|???\)\s\+%s/


