" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    6

if !exists('g:loaded_trag') || exists('g:ftplugin_trag_javascript')
    finish
endif
let g:ftplugin_trag_javascript = 1

TRagDefFiletype javascript js
TRagDefKind i javascript /\C^\s*\%(\/\/\|\/\*\).\{-}%s/
TRagDefKind d javascript /\C\%(\<%s\s*[:=]\s*function\>\|\<function\s\+%s\>\)/
TRagDefKind l javascript /\C\<%s\s*=[^=<>]/
TRagDefKind r javascript /\C[^=!<>]=\s*%s/
TRagDefKind f javascript /\C\(\<function\s\+\)\@<!\<%s\s*(/


