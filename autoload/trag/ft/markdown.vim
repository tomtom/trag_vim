" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    20

if !exists('g:loaded_trag') || exists('g:ftplugin_trag_markdown')
    finish
endif
let g:ftplugin_trag_markdown = 1

TRagDefFiletype markdown md mdown mkd mkdn markdown mdwn
TRagDefKind i markdown /\C^\s*<!---[^>]\{-}%s/
TRagDefKind h markdown /\C^\#\+\s\+%s/
TRagDefKind todo markdown /\C\%%(TODO:\?\|FIXME:\?\|+++\|!!!\|###\|???\|^\s*[-+*]\s\[[ x]\]\)\s\+%s/
TRagDefKind tag markdown /\C\%%(^\s*#%s\|\<id\s*=\s*["']\?%s\)/

