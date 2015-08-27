" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    3

if !exists('g:loaded_trag') || exists('g:ftplugin_trag_ruby')
    finish
endif
let g:ftplugin_trag_ruby = 1

TRagDefFiletype ruby rb
TRagDefKind w ruby /\C[:@]\?\<%s\>/
TRagDefKind W ruby /\C[^;()]\{-}%s[^;()]\{-}/
TRagDefKind c ruby /\C\<class\s\+\%(\u\w*::\)*%s\>/
TRagDefKind d ruby /\C\<\%(def\s\+\%(\u\w*\.\)*\|attr\%(_\w\+\)\?\s\+\%(:\w\+,\s\+\)*:\)%s/
TRagDefKind f ruby /\<%s\>/
TRagDefKind i ruby /\C^\s*#%s/
TRagDefKind m ruby /\C\<module\s\+\%(\u\w*::\)*%s/
TRagDefKind l ruby /\C%s\%(\s*,\s*[[:alnum:]_@$]\+\s*\)*\s*=[^=~<>]/
TRagDefKind x ruby /\C\s\*class\>.\{-}<\s*%s/


