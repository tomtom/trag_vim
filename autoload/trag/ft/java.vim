" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    4

if !exists('g:loaded_trag') || exists('g:ftplugin_trag_java')
    finish
endif
let g:ftplugin_trag_java = 1

TRagDefFiletype java java
let s:java_mod = '\%(\<\%(final\|public\|protected\|private\|synchronized\|volatile\|abstract\)\s\+\)*'
let s:java_type = '\%(boolean\|byte\|short\|int\|long\|float\|double\|char\|void\|\u[[:alnum:]_.]*\)\s\+'
exec 'TRagDefKind c java /\C^\s*'. s:java_mod .'class\s\+%s/'
exec 'TRagDefKind d java /\C^\s*'. s:java_mod .'\%(\w\+\%(\[\]\)*\)\s\+%s\s*(/'
exec 'TRagDefKind f java /\%(\%(;\|{\|^\)\s*'. s:java_mod . s:java_type .'\)\@<!%s\s*\%([(;]\|$\)/'
TRagDefKind i java /\C^\s*\%(\/\/\|\/\*\).\{-}%s/
TRagDefKind x java /\C\<\%(extends\|implements\)\s\+%s/
unlet s:java_mod s:java_type

