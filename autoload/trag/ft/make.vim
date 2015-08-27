" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    13

if !exists('g:loaded_trag') || exists('g:ftplugin_trag_make')
    finish
endif
let g:ftplugin_trag_make = 1

TRagDefFiletype make Makefile
TRagDefKind i make /\C^\s*#.\{-}%s/
TRagDefKind d make /\C^%s\s*[:=]/
TRagDefKind l make /\C^\s*\<%s\s*=[^=<>]/
TRagDefKind r make /\C[^=!<>]=.\{-}%s/

