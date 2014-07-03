" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    3

if !exists('g:loaded_trag') || exists('g:ftplugin_trag_r')
    finish
endif
let g:ftplugin_trag_r = 1

TRagDefFiletype r r
TRagDefKind i r /\C^\s*#%s/
TRagDefKind d r /\C^\s*\%(%s\s*<-\s*function\>\|setMethod\s*("%s"\)/
TRagDefKind c r /\C\%(\<%s\s*<-\s*set\%(Ref\)\?Class\>\|\s*<-\s*set\%(Ref\)\?Class\s*(\s*"%s"\)/
TRagDefKind l r /\C\%(^\s*%s\s*<<\?-\s*\|\<%s\s*=[^=]\)/
TRagDefKind r r /\C\s*<<\?-\s*%s/
TRagDefKind f r /\C\<%s\s*(/


