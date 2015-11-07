" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-11-07
" @Revision:    51


let s:prototype = {}


function! s:prototype.Get_files() abort dict "{{{3
    return self.files
endf


function! s:prototype.Get_grep_defs() abort dict "{{{3
    if !has_key(self, 'grep_defs')
        Tlibtrace 'trag', len(self.files)
        let self.grep_defs = map(copy(self.files), 'trag#grepdefs#GetGrepDef(v:val, self.kindspos, self.kindsneg, self.rx, self.filetype)')
        call filter(self.grep_defs, '!empty(v:val)')
        Tlibtrace 'trag', len(self.grep_defs)
    endif
    return self.grep_defs
endf


function! s:prototype.Get_group_defs(grep_cmd) abort dict "{{{3
    Tlibtrace 'trag', a:grep_cmd
    let is_mf = !trag#external#{a:grep_cmd}#IsSupported(self.kindspos)
    let gdid = 'group_defs_'. is_mf
    if !has_key(self, gdid)
        let mfid = 'must_filter_'. is_mf
        Tlibtrace 'trag', is_mf, gdid, mfid
        let group_defs = {}
        let must_filter = {}
        for filename in self.Get_files()
            if !empty(filename)
                let [pt, ft] = s:GuessFiletype(filename)
                if empty(ft)
                    let ft = '*'
                endif
                if !has_key(group_defs, ft)
                    let grep_def = trag#grepdefs#GetGrepDef(filename, self.kindspos, self.kindsneg, self.rx, self.filetype)
                    if empty(grep_def)
                        continue
                    else
                        " TLogVAR grep_def, ft
                        let group_defs[ft] = {'rxpos': grep_def.rxpos,
                                    \ 'rxneg': grep_def.rxneg,
                                    \ 'must_filter': 0,
                                    \ 'kindspos': self.kindspos,
                                    \ 'files': []}
                        if is_mf
                            let must_filter[ft] = grep_def.rxpos
                            let group_defs[ft].use_rx = grep_def.rx
                            let group_defs[ft].use_kinds = [['identity']]
                        endif
                    endif
                endif
                call add(group_defs[ft].files, filename)
            endif
        endfor
        " for grep_def in self.Get_grep_defs()
        "     let ft = grep_def.filetype
        "     " TLogVAR ft, grep_def.ff
        "     if !has_key(group_defs, ft)
        "         " TLogVAR grep_def.kindspos, trag#external#{grep_cmd}#IsSupported(grep_def.kindspos)
        "         let group_defs[ft] = {'rxpos': grep_def.rxpos,
        "                     \ 'must_filter': 0,
        "                     \ 'kindspos': grep_def.kindspos,
        "                     \ 'files': []}
        "         if !trag#external#{grep_cmd}#IsSupported(grep_def.kindspos)
        "             let must_filter[ft] = grep_def.rxpos
        "             let group_defs[ft].use_rx = grep_def.rx
        "             let group_defs[ft].use_kinds = [['identity']]
        "         endif
        "         " TLogVAR group_defs[ft]
        "     endif
        "     call add(group_defs[ft].files, grep_def.ff)
        " endfor
        let self[gdid] = group_defs
        let self[mfid] = must_filter
        Tlibtrace 'trag', len(self[gdid])
    endif
    return self[gdid]
endf


function! s:prototype.Get_must_filter(grep_cmd) abort dict "{{{3
    let is_mf = !trag#external#{a:grep_cmd}#IsSupported(self.kindspos)
    let mfid = 'must_filter_'. is_mf
    Tlibtrace 'trag', a:grep_cmd, is_mf, mfid
    if !has_key(self, mfid)
        call self.Get_group_defs(a:grep_cmd)
    endif
    return self[mfid]
endf


function! trag#grepdefs#New(files, kindspos, kindsneg, rx, filetype) abort "{{{3
    let pt = {'files': a:files, 'kindspos': a:kindspos, 'kindsneg': a:kindsneg, 'rx': a:rx, 'filetype': a:filetype}
    let pt = extend(pt, s:prototype)
    return pt
endf


function! trag#grepdefs#GetGrepDef(filename, kindspos, kindsneg, rx, filetype) "{{{3
    " let ff = a:filename
    let ff = fnamemodify(a:filename, ':p')
    " Tlibtrace 'trag', a:filename, ff, filereadable(ff)
    " TLogVAR a:filename, ff, filereadable(ff)
    if filereadable(ff)
        " TLogVAR ff, a:kindspos, a:kindsneg, a:rx
        let [rxpos, filetype0] = s:GetRx(ff, a:kindspos, a:rx, '.', a:filetype)
        " TLogVAR rxpos, filetype0
        if !empty(rxpos)
            if empty(a:kindsneg)
                let rxneg = ''
                let filetype1 = filetype0
            else
                let [rxneg, filetype1] = s:GetRx(ff, a:kindsneg, '', '', filetype0)
            endif
            " TLogVAR rxneg, filetype1
            let ft = empty(filetype0) ? '*' : filetype0
            return {
                        \ 'f': a:filename,
                        \ 'ff': ff,
                        \ 'kindspos': a:kindspos,
                        \ 'rx': a:rx,
                        \ 'rxpos': rxpos,
                        \ 'rxneg': rxneg,
                        \ 'filetype': ft
                        \ }
        endif
    endif
    return {}
endf


function! trag#grepdefs#ClearCachedRx() "{{{3
    let s:rx_cache = {}
endf
call trag#grepdefs#ClearCachedRx()


let s:fnameftypes = {}


function! s:GuessFiletype(filename) abort "{{{3
    if has_key(s:fnameftypes, a:filename)
        let ftdef = s:fnameftypes[a:filename]
        let prototype = ftdef.proto
        let filetype = ftdef.ft
    else
        let prototype = ''
        for mods in [':e', ':t', ':p']
            let needle = fnamemodify(a:filename, mods)
            if !empty(needle)
                let filetype = trag#GetFiletype(needle)
                " TLogVAR needle, filetype
                if !empty(filetype)
                    let prototype = needle
                    break
                endif
            endif
        endfor
        let s:fnameftypes[a:filename] = {'ft': filetype, 'proto': prototype}
    endif
    return [prototype, filetype]
endf


function! s:GetRx(filename, kinds, rx, default, filetype) "{{{3
    " TLogVAR a:filename, a:kinds, a:rx, a:default
    if empty(a:filetype)
        let [prototype, filetype] = s:GuessFiletype(a:filename)
    else
        let prototype = a:filename
        let filetype = a:filetype
    endif
    if empty(a:kinds)
        let rv = a:default
    else
        let rxacc = []
        let id = filetype .'*'.string(a:kinds).'*'.a:rx
        " TLogVAR prototype, filetype, id
        if has_key(s:rx_cache, id)
            let rv = s:rx_cache[id]
        else
            for kindand in a:kinds
                let rx = a:rx
                for kind in kindand
                    let rxf = tlib#var#Get('trag_rxf_'. kind, 'bg')
                    " TLogVAR rxf
                    if !empty(filetype)
                        let rxf = tlib#var#Get('trag_rxf_'. kind .'_'. filetype, 'bg', rxf)
                    endif
                    " TLogVAR rxf
                    if empty(rxf)
                        if &verbose > 1
                            if empty(filetype)
                                echom 'Unknown kind '. kind .' for unregistered filetype; skip files like '. prototype
                            else
                                echom 'Unknown kind '. kind .' for ft='. filetype .'; skip files like '. prototype
                            endif
                        endif
                        return ['', filetype]
                    else
                        " TLogVAR rxf
                        " If the expression is no word, ignore word boundaries.
                        if rx =~ '\W$' && rxf =~ '%\@<!%s\\>'
                            let rxf = substitute(rxf, '%\@<!%s\\>', '%s', 'g')
                        endif
                        if rx =~ '^\W' && rxf =~ '\\<%s'
                            let rxf = substitute(rxf, '\\<%s', '%s', 'g')
                        endif
                        " TLogVAR rxf, rx
                        let rx = tlib#string#Printf1(rxf, rx)
                    endif
                endfor
                call add(rxacc, rx)
            endfor
            let rv = s:Rx(rxacc, a:default)
            let s:rx_cache[id] = rv
        endif
    endif
    " TLogVAR rv
    return [rv, filetype]
endf


function! s:Rx(rxacc, default) "{{{3
    if empty(a:rxacc)
        let rx = a:default
    elseif len(a:rxacc) == 1
        let rx = a:rxacc[0]
    else
        let rx = '\('. join(a:rxacc, '\|') .'\)'
    endif
    return rx
endf


