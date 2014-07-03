" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    6

if !exists('g:loaded_trag') || exists('g:ftplugin_trag_json')
    finish
endif
let g:ftplugin_trag_json = 1

TRagDefFiletype json json
TRagDefKind d json /\C^\s\+"%s"\s*:/
TRagDefKind l json /\C^\s\+"%s"\s*:/
TRagDefKind r json /\C^\s\+".\{-}"\s*:.\{-}%s/


