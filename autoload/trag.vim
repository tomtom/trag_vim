" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-10-25.
" @Revision:    1537

" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile

" A comma-separated list of preferred grep programs:
"
"   - trag
"   - vimgrep
"   - vcs (use the VCS's grep function; see |trag#external#vcs#Run()|, 
"     this option always searches all files in the VCS); for a list of 
"     supported VCSs see |trag#external#vcs#Run()|
"   - external:CMD (CMD defaults to grep; use vimgrep as fallback)
"   - ack (https://github.com/petdance/ack2)
"   - ag (https://github.com/ggreer/the_silver_searcher)
"   - grep (uses 'grepprg')
"
" The first valid option is used. E.g. if the value is "vcs,trag" and if 
" the buffer belongs to a supported VCS (see |trag#external#vcs#Run()|, 
" the VCS's grep function is used. Otherwise trag's own version of grep 
" is used.
"
" trag & vimgrep should work everywhere.
"                                                     *b:trag_grep_type*
" b:trag_grep_type overrides this global variable.
TLet g:trag#grep_type = 'trag'

" Use this type for files that are not supported by |g:trag#grep_type| 
" (e.g. files outside of a VCS if |g:trag#grep_type| includes "vcs").
TLet g:trag#grep_fallback_type = 'trag'

" If no project files are defined, evaluate this expression as 
" fallback-strategy.
TLet g:trag_get_files = 'split(glob("*"), "\n")'
TLet g:trag_get_files_java = 'split(glob("**/*.java"), "\n")'
TLet g:trag_get_files_c = 'split(glob("**/*.[ch]"), "\n")'
TLet g:trag_get_files_cpp = 'split(glob("**/*.[ch]"), "\n")'

" A list of sources.
" Possible values:
"   vcs ....... Use g:trag#check_vcs
"   git ....... Use b:trag_git or g:trag_git
"   tags ...... Use files listed in 'tags'
"   files ..... Use b:trag_files or g:trag_files
"   glob ...... Use b:trag_glob or g:trag_glob
"   project ... Use b:trag_project_{'filetype'} or 
"               g:trag_project_{'filetype'}
"                                                     *b:trag_file_sources*
" b:trag_file_sources overrides this global variable.
TLet g:trag#file_sources = ['vcs', 'project', 'files', 'glob', 'tags']

" If true, use an already loaded buffer instead of the file on disk in 
" certain situations. This implies that if a buffer is dirty, the 
" non-saved version in memory will be preferred over the version on 
" disk.
TLet g:trag#use_buffer = 1

" If true, try to detect whether the current file is under an VCS and 
" use that later on.
TLet g:trag#check_vcs = 1

TLet g:trag#debug = 0

TLet g:trag#world = {
            \ 'key_handlers': [
                \ {'key':  6, 'agent': 'trag#AgentRefactor',     'key_name': '<c-f>', 'help': 'Run a refactor command'},
            \ ],
            \ }

" :nodoc:
function! trag#DefFiletype(args) "{{{3
    let ft = a:args[0]
    for name in a:args[1:-1]
        call trag#SetFiletype(ft, name)
    endfor
endf

" Return true, if a filetype for "name" (an extension or a filename) is 
" defined.
function! trag#HasFiletype(name) "{{{3
    let name = has('fname_case') ? a:name : tolower(a:name)
    return has_key(g:trag_extension_filetype, name)
endf

" Define that filenames ("name" can be either an extension or a 
" filename) are of a certain filetype.
function! trag#SetFiletype(filetype, name) "{{{3
    let name = has('fname_case') ? a:name : tolower(a:name)
    " TLogVAR name, a:filetype
    let g:trag_extension_filetype[name] = a:filetype
endf

" Get the filetype for "name" (either an extension of a filename).
function! trag#GetFiletype(name) "{{{3
    let name = has('fname_case') ? a:name : tolower(a:name)
    " TLogVAR name, get(g:trag_extension_filetype,name,"")
    for [pattern, ft] in items(g:trag_extension_filetype)
        if pattern =~ '^/.\{-}/$' && a:name =~ pattern
            return ft
        elseif a:name == pattern
            return ft
        endif
    endfor
    return ''
endf


" :nodoc:
function! trag#TRagDefKind(args, ...) "{{{3
    TVarArg ['replace', 0]
    " TLogVAR a:args
    " TLogDBG string(matchlist(a:args, '^\(\S\+\)\s\+\(\S\+\)\s\+/\(.\{-}\)/$'))
    let ml = matchlist(a:args, '^\(\S\+\)\s\+\(\S\+\)\s\+/\(.\{-}\)/$')
    if empty(ml)
        throw 'TRagDefKind: Malformed arguments: '. a:args
    else
        let [match, kind, filetype, regexp; rest] = ml
        " TLogVAR kind, filetype, regexp
        let var = ['g:trag_rxf', kind]
        if filetype != '*' && filetype != '.'
            call add(var, filetype)
        endif
        let varname = join(var, '_')
        if !exists(varname) || replace
            let {varname} = substitute(regexp, '\\/', '/', 'g')
        else
            let {varname} = '\%('. {varname} .'\|'. substitute(regexp, '\\/', '/', 'g') .'\)'
        endif
        if has_key(g:trag_kinds, kind)
            call add(g:trag_kinds[kind], filetype)
        else
            let g:trag_kinds[kind] = [filetype]
            if !empty(g:trag_map_leader)
                call TragInstallKindMap(g:trag_map_leader, kind)
            endif
        endif
    endif
endf



""" Known Types {{{1

TRagDefKind identity * /\C%s/

" Left hand side value in an assignment.
" Examples:
" l foo =~ foo = 1
TRagDefKind l * /\C%s\s*[^=]*=[^=~<>]/

" Right hand side value in an assignment.
" Examples:
" r foo =~ bar = foo
TRagDefKind r * /\C[^!=~<>]=.\{-}%s/

" Markers: TODO, TBD, FIXME, OPTIMIZE
TRagDefKind todo * /\C\%(TBD\|TODO\|FIXME\|OPTIMIZE\)/

" A mostly general rx format string for function calls.
TRagDefKind f * /\C%s\s*(/

" The same as w, but is listed in |g:trag_kinds_ignored_comments|.
TRagDefKind u * /\C\<%s\>/

" A mostly general rx format string for words.
TRagDefKind w * /\C\<%s\>/
TRagDefKind W * /\C.\{-}%s.\{-}/

TRagDefKind fuzzy * /\c%{fuzzyrx}/

runtime! autoload/trag/ft/*.vim



""" File sets {{{1

" :doc:
" The following variables provide alternatives to collecting 
" your project's file list on the basis of you tags files.
"
" These variables are tested in the order as listed here. If the value 
" of a variable is non-empty, this one will be used instead of the other 
" methods.
"
" The tags file is used as a last ressort.

" 1. A list of files. Can be buffer local.
TLet g:trag_files = []

" 2. A glob pattern -- this should be an absolute path and may contain ** 
" (see |glob()| and |wildcards|). Can be buffer local.
TLet g:trag_glob = ''

" 3. Filetype-specific project files.
TLet g:trag_project_ruby = 'Manifest.txt'

" 4. The name of a file containing the projects file list. This file could be 
" generated via make. Can be buffer local.
TLet g:trag_project = ''

" 5. The name of a git repository that includes all files of interest. 
" If the value is "*", trag will search from the current directory 
" (|getcwd()|) upwards for a .git directory.
" If the value is "finddir", use |finddir()| to find a .git directory.
" Can be buffer local.
TLet g:trag_git = ''


""" input#List {{{1

" :nodoc:
TLet g:trag_edit_world = {
            \ 'type': 's',
            \ 'query': 'Select file',
            \ 'pick_last_item': 1,
            \ 'scratch': '__TRagEdit__',
            \ 'return_agent': 'tlib#agent#ViewFile',
            \ }


""" Functions {{{1
    
let s:grep_rx = ''


function! s:GetFiles() "{{{3
    if !exists('b:trag_files_')
        call trag#SetFiles()
    endif
    if empty(b:trag_files_)
        let trag_get_files = tlib#var#Get('trag_get_files_'. &filetype, 'bg', '')
        " TLogVAR trag_get_files
        if empty(trag_get_files)
            let trag_get_files = tlib#var#Get('trag_get_files', 'bg', '')
            " TLogVAR trag_get_files
        endif
        if g:trag#debug
            " echohl Error
            echom 'TRag: No project files ... use: '. trag_get_files
            " echohl NONE
        endif
        let b:trag_files_ = eval(trag_get_files)
    endif
    " TLogVAR b:trag_files_
    return b:trag_files_
endf


function! trag#ClearFiles() "{{{3
    let b:trag_files_ = []
endf


function! trag#AddFiles(files) "{{{3
    if tlib#type#IsString(a:files)
        let files_ = eval(a:files)
    else
        let files_ = a:files
    endif
    if !tlib#type#IsList(files_)
        echoerr 'trag_files must result in a list: '. string(a:files)
    elseif exists('b:trag_files_')
        let b:trag_files_ += files_
    else
        let b:trag_files_ = files_
    endif
    unlet files_
endf


function! trag#GetProjectFiles(manifest) "{{{3
    if filereadable(a:manifest)
        " TLogVAR a:manifest
        let files = readfile(a:manifest)
        let cwd   = getcwd()
        try
            call tlib#dir#CD(fnamemodify(a:manifest, ':h'), 1)
            call map(files, 'fnamemodify(v:val, ":p")')
            return files
        finally
            call tlib#dir#CD(cwd, 1)
        endtry
    endif
    return []
endf


function! trag#GetGitFiles(repos) "{{{3
    let repos   = tlib#dir#PlainName(a:repos)
    let basedir = substitute(repos, '[\/]\.git\%([\/]\)\?$', '', '')
    " TLogVAR repos, basedir
    " TLogVAR getcwd()
    call tlib#dir#Push(basedir)
    " TLogVAR getcwd()
    try
        let files = split(system('git ls-files'), '\n')
        " TLogVAR files
        call map(files, 'basedir . g:tlib#dir#sep . v:val')
        return files
    finally
        call tlib#dir#Pop()
    endtry
    return []
endf


" Set the files list to the files in the current VCS repository.
function! trag#SetRepoFiles() "{{{3
    let [type, dir] = tlib#vcs#FindVCS(expand('%'))
    if empty(type)
        echom 'No supported VCS repository found.'
    else
        let files = tlib#vcs#Ls('', [type, dir])
        let b:trag_files_ = files
        echom len(files) 'files from the' type 'repository.'
    endif
endf


" Set the files list from the files included in a given git repository.
function! trag#SetGitFiles(repos) "{{{3
    let files = trag#GetGitFiles(a:repos)
    if !empty(files)
        call trag#ClearFiles()
        let b:trag_files_ = files
        echom len(files) ." files from the git repository."
    endif
endf


" :def: function! trag#SetFiles(?files=[])
function! trag#SetFiles(...) "{{{3
    TVarArg ['files', []]
    call trag#ClearFiles()
    if empty(files)
        let source1 = ''
        for source in tlib#var#Get('trag#file_sources', 'bg', [])
            let source1 = source
            if source == 'files'
                let files = tlib#var#Get('trag_files', 'bg', [])
            elseif source == 'glob'
                let glob = tlib#var#Get('trag_glob', 'bg', '')
                if !empty(glob)
                    " TLogVAR glob
                    let files = split(glob(glob), '\n')
                endif
            elseif source == 'project'
                let proj = tlib#var#Get('trag_project_'. &filetype, 'bg', tlib#var#Get('trag_project', 'bg', ''))
                " TLogVAR proj
                if !empty(proj)
                    " let proj = fnamemodify(proj, ':p')
                    let proj = findfile(proj, '.;')
                    let files = trag#GetProjectFiles(proj)
                endif
            elseif source == 'tags'
                let filenames = {}
                for tag in taglist('.')
                    let filenames[tag.filename] = 1
                endfor
                let files = keys(filenames)
            elseif source == 'git'
                let git_repos = tlib#var#Get('trag_git', 'bg', '')
                if git_repos == '*'
                    let git_repos = trag#FindGitRepos()
                elseif git_repos == "finddir"
                    let git_repos = finddir('.git')
                endif
                if !empty(git_repos)
                    let files = trag#GetGitFiles(git_repos)
                endif
            elseif source == 'vcs'
                if g:trag#check_vcs
                    let files = tlib#vcs#Ls()
                end
            endif
            if !empty(files)
                break
            endif
        endfor
    endif
    " TLogVAR files
    if !empty(files)
        call map(files, 'fnamemodify(v:val, ":p")')
        " TLogVAR files
        call trag#AddFiles(files)
        let b:trag_source = source1
    else
        let b:trag_source = ''
    endif
    " TLogVAR b:trag_files_
    if empty(b:trag_files_)
        let files0 = taglist('.')
        " Filter bogus entry?
        call filter(files0, '!empty(v:val.kind)')
        call map(files0, 'v:val.filename')
        call sort(files0)
        let last = ''
        try
            call tlib#progressbar#Init(len(files0), 'TRag: Collect files %s', 20)
            let fidx = 0
            for f in files0
                call tlib#progressbar#Display(fidx)
                let fidx += 1
                " if f != last && filereadable(f)
                if f != last
                    call add(b:trag_files_, f)
                    let last = f
                endif
            endfor
        finally
            call tlib#progressbar#Restore()
        endtry
    endif
endf


function! trag#FindGitRepos() "{{{3
    let dir = fnamemodify(getcwd(), ':p')
    let git = tlib#file#Join([dir, '.git'])
    while !isdirectory(git)
        let dir1 = fnamemodify(dir, ':h')
        if dir == dir1
            break
        else
            let dir = dir1
        endif
        let git = tlib#file#Join([dir, '.git'])
    endwh
    if isdirectory(git)
        return git
    else
        return ''
    endif
endf


" Edit a file from the project catalog. See |g:trag_project| and 
" |:TRagfile|.
function! trag#Edit() "{{{3
    let w = tlib#World#New(copy(g:trag_edit_world))
    let w.base = s:GetFiles()
    let w.show_empty = 1
    let w.pick_last_item = 0
    if b:trag_source !~ '\<vcs\>'
        let pattern = matchstr(expand('%:t:r'), '^\w\+')
        " call w.SetInitialFilter(pattern)
        call w.SetInitialFilter([[''], [pattern]])
    endif
    call w.Set_display_format('filename')
    " TLogVAR w.base
    call tlib#input#ListW(w)
endf


" Test j trag
" Test n tragfoo
" Test j trag(foo)
" Test n tragfoo(foo)
" Test j trag
" Test n tragfoo

" :def: function! trag#Grep(args, ?replace=1, ?files=[], ?filetype='')
" args: A string with the format:
"   KIND REGEXP
"   KIND1,KIND2 REGEXP
"
" If the variables [bg]:trag_rxf_{kind}_{&filetype} or 
" [bg]:trag_rxf_{kind} exist, these will be taken as format string (see 
" |printf()|) to format REGEXP.
"
" EXAMPLE:
" trag#Grep('v foo') will find by default take g:trag_rxf_v and find 
" lines that looks like "\<foo\>\s*=[^=~]", which most likely is a 
" variable definition in many programming languages. I.e. it will find 
" lines like: >
"   foo = 1
" < but not: >
"   def foo(bar)
"   call foo(bar)
"   if foo == 1
function! trag#Grep(args, ...) "{{{3
    TVarArg ['replace', 1], ['files', []], ['filetype', '']
    " TLogVAR a:args, replace, files, filetype
    let [kindspos, kindsneg, rx] = s:SplitArgs(a:args)
    " TLogVAR kindspos, kindsneg, rx, a:args
    if empty(rx)
        let rx = '.\{-}'
        " throw 'Malformed arguments (should be: "KIND REGEXP"): '. string(a:args)
    endif
    " TAssertType rx, 'string'
    let s:grep_rx = rx
    if empty(files)
        let files = s:GetFiles()
    else
        let files = split(join(map(files, 'glob(v:val)'), "\n"), '\n')
    endif
    " TLogVAR files
    " TAssertType files, 'list'
    call s:DoAutoCmd('QuickFixCmdPre')
    call tlib#progressbar#Init(len(files), 'TRag: Grep %s', 20)
    if replace
        call setqflist([])
    endif
    let scratch = {}
    try
        let qfl_top = len(getqflist())
        let grep_defs = map(copy(files), 's:GetGrepDef(v:val, kindspos, kindsneg, rx, filetype)')
        let grep_defs = filter(grep_defs, '!empty(v:val)')
        let done = 0
        let trag_type = tlib#var#Get('trag#grep_type', 'bg')
        let s:last_run_files = files
        let s:last_run_grep_defs = grep_defs
        for grep_name in split(trag_type, ',\s*')
            " TLogVAR grep_name
            let ml = matchlist(grep_name, '^\(\w\+\):\s*\(.\{-}\)\s*$')
            if empty(ml)
                let grep_type = grep_name
                let grep_opts = ''
            else
                let grep_type = ml[1]
                let grep_opts = ml[2]
            endif
            let strip = grep_type == 'vimgrep'
            " TLogVAR grep_type, grep_opts
            " TLogVAR grep_defs
            if s:GrepWith_{grep_type}(grep_defs, grep_opts)
                let done = 1
                break
            endif
        endfor
        " TLogVAR len(getqflist())
        if !done
            throw 'TRag: Unsupported value for g:trag#grep_type: '. trag_type
        endif

        if strip
            let qfl1 = getqflist()
            if !empty(qfl1)
                " TLogVAR qfl_top, qfl1
                let qfl1[qfl_top : -1] = map(qfl1[qfl_top : -1], 's:StripText(v:val)')
                call setqflist(qfl1, 'r')
            endif
        endif
        call s:DoAutoCmd('QuickFixCmdPost')

        " TLogDBG 'qfl:'. string(getqflist())
        let qfl2 = getqflist()
        return qfl2[qfl_top : -1]
    finally
        if !empty(scratch)
            call tlib#scratch#CloseScratch(scratch)
            let &lazyredraw = lazyredraw
        endif
        call tlib#progressbar#Restore()
    endtry
endf


function! trag#LastRun(what) abort "{{{3
    if a:what =~# '^\%(f\%[iles]\|grep_defs\)$'
        return s:last_run_{a:what}
    else
        echoerr 'trag#LastRun: Unsupported type:' a:what
    endif
endf


function! s:GetGrepDef(filename, kindspos, kindsneg, rx, filetype) "{{{3
    let ff = fnamemodify(a:filename, ':p')
    if filereadable(ff)
        " TLogVAR f, kindspos, kindsneg
        let [rxpos, filetype0] = s:GetRx(ff, a:kindspos, a:rx, '.', a:filetype)
        " TLogVAR a:rx, rxpos
        if !empty(rxpos)
            let [rxneg, filetype1] = s:GetRx(ff, a:kindsneg, '', '', filetype0)
            " TLogVAR rxneg
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


function! s:GrepWith_trag(grep_defs, grep_opts) "{{{3
    let fidx  = 0
    for grep_def in a:grep_defs
        let fidx += 1
        call tlib#progressbar#Display(fidx, ' '. pathshorten(grep_def.f))
        let bnum = bufnr(grep_def.ff)
        if g:trag#use_buffer && bnum != -1 && bufloaded(bnum)
            " TLogVAR bnum, a:filename, bufname(bnum)
            let lines = getbufline(bnum, 1, '$')
        else
            let lines = readfile(grep_def.ff)
        endif
        " TLogVAR grep_def.rxpos, grep_def.rxneg
        call trag#ScanWithGrepDefs(grep_def, lines, 1)
    endfor
    return 1
endf


function! trag#ScanWithGrepDefs(grep_def, lines, setqflist) "{{{3
    let qfl = {}
    let lnum = 1
    for line in a:lines
        if line =~ a:grep_def.rxpos && (empty(a:grep_def.rxneg) || line !~ a:grep_def.rxneg)
            let qfl[lnum] = {"filename": a:grep_def.ff, "lnum": lnum, "text": tlib#string#Strip(line)}
        endif
        let lnum += 1
    endfor
    " TLogVAR qfl
    if a:setqflist && !empty(qfl)
        call setqflist(values(qfl), 'a')
    endif
    return values(qfl)
endf


function! s:GrepWith_vimgrep(grep_defs, grep_opts) "{{{3
    let rxnegs = {}
    let fidx  = 0
    for grep_def in a:grep_defs
        let fidx += 1
        call tlib#progressbar#Display(fidx, ' '. pathshorten(grep_def.f))
        let qfll = len(getqflist())
        silent! exec 'noautocmd vimgrepadd' '/'. escape(grep_def.rxpos, '/') .'/j' tlib#arg#Ex(grep_def.ff)
        " TLogVAR qfll, len(getqflist())
        if qfll != len(getqflist())
            let bufnr = bufnr(grep_def.ff)
            " TLogVAR bufnr, grep_def.rxneg
            if !empty(grep_def.rxneg) && !has_key(rxnegs, bufnr)
                let rxnegs[bufnr] = grep_def.rxneg
            endif
        endif
    endfor
    call s:FilterRxNegs(rxnegs)
    return 1
endf


function! s:GrepWith_ack(grep_defs, grep_opts) "{{{3
    return s:GrepWith_external(a:grep_defs, 'ack '. a:grep_opts)
endf


function! s:GrepWith_ag(grep_defs, grep_opts) "{{{3
    return s:GrepWith_external(a:grep_defs, 'ag '. a:grep_opts)
endf


function! s:GrepWith_sift(grep_defs, grep_opts) "{{{3
    return s:GrepWith_external(a:grep_defs, 'sift '. a:grep_opts)
endf


function! s:GrepWith_grep(grep_defs, grep_opts) "{{{3
    return s:GrepWith_external(a:grep_defs, 'grep '. a:grep_opts)
endf


function! s:GrepWith_vcs(grep_defs, grep_opts) "{{{3
    return s:GrepWith_external(a:grep_defs, 'vcs '. a:grep_opts)
endf


function! s:GrepWith_external(grep_defs, grep_opts) "{{{3
    let opts = tlib#arg#StringAsKeyArgsEqual(a:grep_opts)
    let grep_cmd = get(opts, 0, 'grep')
    if !tlib#sys#IsExecutable(grep_cmd)
        return 0
    endif
    " TLogVAR grep_cmd
    let group_defs = {}
    let must_filter = {}
    for grep_def in deepcopy(a:grep_defs)
        let ft = grep_def.filetype
        " TLogVAR ft, grep_def.ff
        if !has_key(group_defs, ft)
            " TLogVAR grep_def.kindspos, trag#external#{grep_cmd}#IsSupported(grep_def.kindspos)
            let group_defs[ft] = {'rxpos': grep_def.rxpos,
                        \ 'must_filter': 0,
                        \ 'kindspos': grep_def.kindspos,
                        \ 'files': []}
            if !trag#external#{grep_cmd}#IsSupported(grep_def.kindspos)
                let must_filter[ft] = grep_def.rxpos
                let group_defs[ft].use_rx = grep_def.rx
                let group_defs[ft].use_kinds = [['identity']]
            endif
            " TLogVAR group_defs[ft]
        endif
        call add(group_defs[ft].files, grep_def.ff)
    endfor
    let unprocessed_fnames = {}
    for [ft, group_def] in items(group_defs)
        let rx = get(group_def, 'use_rx', group_def.rxpos)
        let kinds = get(group_def, 'use_kinds', group_def.kindspos)
        " TLogVAR rx, kinds
        let [ok, unprocessed_files] = trag#external#{grep_cmd}#Run(kinds, rx, group_def.files)
        " TLogVAR ft, len(getqflist())
        if ok
            for unprocessed_file in unprocessed_files
                let unprocessed_fnames[unprocessed_file] = 1
            endfor
        else
            if g:trag#debug
                echohl WarningMsg
                echom 'Trag: Error when using external grep:' grep_cmd
                echom v:exception
                echohl NONE
            endif
            return 0
        endif
    endfor
    " bufnr() can be slow
    let bnums = {}
    for bnum in range(1, bufnr('$'))
        if bufexists(bnum)
            let fname = tlib#file#Canonic(fnamemodify(bufname(bnum), ':p'))
            let bnums[fname] = bnum
        endif
    endfor
    " TLogVAR bnums
    if !empty(must_filter)
        let qfl = getqflist()
        let qfl = filter(qfl, 'v:val.bufnr > 0')
        " TLogVAR qfl
        " TLogVAR 1, len(qfl)
        let collected_bufnrs = {}
        for [ft, rxpos] in items(must_filter)
            " TLogVAR ft, rxpos
            " TLogVAR group_defs[ft].files
            let bufnrs = tlib#list#ToDictionary(filter(map(copy(group_defs[ft].files), 'get(bnums, tlib#file#Canonic(v:val), 0)'), 'v:val > 0'), 1)
            " TLogVAR bufnrs
            let collected_bufnrs = extend(collected_bufnrs, bufnrs)
            let qfl = filter(qfl, '!has_key(bufnrs, v:val.bufnr) || v:val.text =~ rxpos')
            let qfl = map(qfl, 's:StripText(v:val)')
        endfor
        " TLogVAR 2, len(qfl)
        " let qfl = filter(qfl, 'has_key(collected_bufnrs, v:val.bufnr)')
        " TLogVAR 3, len(qfl)
        call setqflist(qfl)
    endif
    let rxnegs = {}
    for grep_def in deepcopy(a:grep_defs)
        if !empty(grep_def.rxneg)
            let bufnr = get(bnums, tlib#file#Canonic(grep_def.ff), 0)
            if bufnr > 0 && !has_key(rxnegs, bufnr)
                let rxnegs[bufnr] = grep_def.rxneg
            endif
        endif
    endfor
    call s:FilterRxNegs(rxnegs)
    if !empty(unprocessed_fnames)
        " TLogVAR unprocessed_fnames
        let grep_defs1 = filter(deepcopy(a:grep_defs), 'has_key(unprocessed_fnames, v:val.ff)')
        call s:GrepWith_{g:trag#grep_fallback_type}(grep_defs1, a:grep_opts)
    endif
    return 1
endf


function! s:FilterRxNegs(rxnegs) "{{{3
    " TLogVAR a:rxnegs
    if !empty(a:rxnegs)
        let qfl = getqflist()
        " TLogVAR 1, len(qfl)
        let qfl = filter(qfl, '!has_key(a:rxnegs, v:val.bufnr) || v:val.text !~ a:rxnegs[v:val.bufnr]')
        " TLogVAR 2, len(qfl)
        call setqflist(qfl)
    endif
endf


function! s:DoAutoCmd(event) "{{{3
    redir => aus
    exec 'silent! autocmd' a:event 'trag'
    redir END
    let au = split(aus, '\n')
    if len(au) > 1
        exec 'doautocmd' a:event 'trag'
    endif
endf


function! s:AddCurrentLine(file, qfl, rxneg) "{{{3
    " TLogVAR a:file, a:rxneg
    let lnum = line('.')
    let text = getline(lnum)
    " TLogVAR lnum, text
    if empty(a:rxneg) || text !~ a:rxneg
        let a:qfl[lnum] = {"filename": a:file, "lnum": lnum, "text": tlib#string#Strip(text)}
    endif
endf


function! s:StripText(rec) "{{{3
    let a:rec['text'] = tlib#string#Strip(a:rec['text'])
    return a:rec
endf


function! s:SplitArgs(args) "{{{3
    " TLogVAR a:args
    if a:args =~ '\s'
        let kind = matchstr(a:args, '^\S\+')
        if kind == '.' || kind == '*'
            let kind = ''
        endif
        let rx = matchstr(a:args, '\s\zs.*')
    else
        let kind = a:args
        let rx = ''
    endif
    " TLogVAR kind
    if stridx(kind, '#') != -1
        let kind = substitute(kind, '#', '', 'g')
        let rx = tlib#rx#Escape(rx)
    endif
    let kinds = split(kind, '[!-]', 1)
    let kindspos = s:SplitArgList(get(kinds, 0, ''), [['identity']])
    let kindsneg = s:SplitArgList(get(kinds, 1, ''), [])
    " TLogVAR a:args, kinds, kind, rx, kindspos, kindsneg
    return [kindspos, kindsneg, rx]
endf


function! s:SplitArgList(string, default) "{{{3
    let rv = map(split(a:string, ','), 'reverse(split(v:val, ''\.'', 1))')
    if empty(rv)
        return a:default
    else
        return rv
    endif
endf


function! trag#ClearCachedRx() "{{{3
    let s:rx_cache = {}
endf
call trag#ClearCachedRx()


let s:fnameftypes = {}

function! s:GetRx(filename, kinds, rx, default, filetype) "{{{3
    " TLogVAR a:filename, a:kinds, a:rx, a:default
    if empty(a:filetype)
        if has_key(s:fnameftypes, a:filename)
            let ftdef = s:fnameftypes[a:filename]
            let prototype = ftdef.proto
            let filetype = ftdef.ft
        else
            let prototype = ''
            for needle in [
                        \ fnamemodify(a:filename, ':p'),
                        \ fnamemodify(a:filename, ':t'),
                        \ fnamemodify(a:filename, ':e')
                        \ ]
                let filetype = trag#GetFiletype(needle)
                " TLogVAR needle, filetype
                if !empty(filetype)
                    let prototype = needle
                    break
                endif
            endfor
            let s:fnameftypes[a:filename] = {'ft': filetype, 'proto': prototype}
        endif
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


" :display: trag#QuickList(?world={}, ?suspended=0)
" Display the |quickfix| list with |tlib#input#ListW()|.
function! trag#QuickList(...) "{{{3
    TVarArg ['world', {}], ['suspended', 0]
    call trag#BrowseList(world, getqflist(), 0, suspended)
endf


function! trag#QuickListMaybe(anyway) "{{{3
    call trag#BrowseList({}, getqflist(), a:anyway)
endf


function! trag#BrowseList(world_dict, list, ...) "{{{3
    let world_dict = tlib#eval#Extend(deepcopy(g:trag#world), a:world_dict)
    " TLogVAR world_dict
    call call(function('tlib#qfl#QflList'), [a:list, world_dict] + a:000)
endf


" Display the |location-list| with |tlib#input#ListW()|.
function! trag#LocList(...) "{{{3
    TVarArg ['world', {}], ['suspended', 0]
    " TLogVAR world, suspended
    " TVarArg ['sign', 'TRag']
    " if !empty(sign) && !empty(g:trag_sign)
    "     " call tlib#signs#ClearAll(sign)
    "     " call tlib#signs#Mark(sign, getqflist())
    " endif
    call trag#BrowseList(world, getloclist(0), 0, suspended)
endf


" Invoke an refactor command.
" Currently only one command is supported: rename
function! trag#AgentRefactor(world, selected) "{{{3
    call a:world.CloseScratch()
    let cmds = ['Rename']
    let cmd = tlib#input#List('s', 'Select command', cmds)
    if !empty(cmd)
        return trag#Refactor{cmd}(a:world, a:selected)
    endif
    let a:world.state = 'reset'
    return a:world
endf


function! trag#CWord() "{{{3
    if has_key(g:trag_keyword_chars, &filetype)
        let rx = '['. g:trag_keyword_chars[&filetype] .']\+'
        let line = getline('.')
        let col  = col('.')
        if col == 1
            let pre = ''
        else
            let pre = matchstr(line[0 : col - 2],  rx.'$')
        endif
        let post = matchstr(line[col - 1 : -1], '^'.rx)
        let word = pre . post
        " TLogVAR word, pre, post, line, col
    else
        let word = expand('<cword>')
        " TLogVAR word
    endif
    return word
endf


function! trag#RefactorRename(world, selected) "{{{3
    " TLogVAR a:selected
    let from = input('Rename ', s:grep_rx)
    if !empty(from)
        let to = input('Rename '. from .' to: ', from)
        if !empty(to)
            let ft = a:world.filetype
            let fn = 'trag#'. ft .'#Rename'
            " TLogVAR ft, exists('*'. fn)
            try
                return call(fn, [a:world, a:selected, from, to])
            catch /^Vim\%((\a\+)\)\=:E117/
                " TLogDBG "General"
                return trag#general#Rename(a:world, a:selected, from, to)
            endtry
        endif
    endif
    let a:world.state = 'reset'
    return a:world
endf


function! trag#IsSupported(supported_kinds, kinds) "{{{3
    let kinds = tlib#list#Flatten(a:kinds)
    let not_supported = filter(kinds, 'index(a:supported_kinds, v:val) == -1')
    " TLogVAR a:supported_kinds, a:kinds, not_supported
    return empty(not_supported)
endf


