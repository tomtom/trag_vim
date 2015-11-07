" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-11-07.
" @Revision:    1845


if !exists('g:loaded_tlib') || g:loaded_tlib < 116
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 116
        echoerr 'tlib >= 1.16 is required'
        finish
    endif
endif


" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile

" A dictionary FILENAME_EXTENSION => FILETYPE
" On systems without has('fname_case') (see |feature-list|), 
" FILENAME_EXTENSION should be a lower-case string.
TLet g:trag#extension_filetype = {}

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

TLet g:trag#assume_executable = ['vcs']

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
"   buffer .... Use the current buffer's directory
"   cd ........ Use the current working directory (see |getcwd()|)
"   *FN ....... Call function FN with one arg (a dictionary of options)
"                                                     *b:trag_file_sources*
" b:trag_file_sources overrides this global variable.
TLet g:trag#file_sources = ['vcs', 'project', 'files', 'glob', 'tags', 'filetype', 'buffer']

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

if g:trag#debug
    call tlib#debug#Init()
endif


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
    return has_key(g:trag#extension_filetype, name)
endf

" Define that filenames ("name" can be either an extension or a 
" filename) are of a certain filetype.
function! trag#SetFiletype(filetype, name) "{{{3
    let name = has('fname_case') ? a:name : tolower(a:name)
    " TLogVAR name, a:filetype
    let g:trag#extension_filetype[name] = a:filetype
endf

" Get the filetype for "name" (either an extension of a filename).
function! trag#GetFiletype(name) "{{{3
    let name = has('fname_case') ? a:name : tolower(a:name)
    " TLogVAR name, get(g:trag#extension_filetype,name,"")
    for [pattern, ft] in items(g:trag#extension_filetype)
        if pattern =~ '^/.\{-}/$' && a:name =~ pattern
            return ft
        elseif a:name == pattern
            return ft
        endif
    endfor
    return ''
endf


" :nodoc:
function! trag#TragDefKind(args, ...) "{{{3
    TVarArg ['replace', 0]
    " TLogVAR a:args
    " TLogDBG string(matchlist(a:args, '^\(\S\+\)\s\+\(\S\+\)\s\+/\(.\{-}\)/$'))
    let ml = matchlist(a:args, '^\(\S\+\)\s\+\(\S\+\)\s\+/\(.\{-}\)/$')
    if empty(ml)
        throw 'TragDefKind: Malformed arguments: '. a:args
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


function! s:GetFiles(...) "{{{3
    TVarArg ['opts', {}]
    let fopts = deepcopy(opts)
    for k in ['__rest__', 'kinds', 'include', 'exclude', 'literal', '__exit__', 'text', 'filenames', 'filetype']
        if has_key(fopts, k)
            call remove(fopts, k)
        endif
    endfor
    if get(opts, 'force', 0) || !exists('b:trag_cache_files') || b:trag_cache_files.options != fopts
        Tlibtrace 'trag', fopts
        let b:trag_cache_files = s:SetFiles([], opts)
        let b:trag_cache_files.options = fopts
    endif
    Tlibtrace 'trag', len(b:trag_cache_files.files)
    return b:trag_cache_files.files
endf


function! s:ClearFiles() "{{{3
    Tlibtrace 'trag', exists('b:trag_cache_files')
    let b:trag_cache_files = {}
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


" :def: function! s:SetFiles(?files=[])
function! s:SetFiles(...) "{{{3
    TVarArg ['files', []], ['opts', {}]
    call s:ClearFiles()
    Tlibtrace 'trag', len(files), opts
    let use_source = ''
    if empty(files)
        let source1 = ''
        if has_key(opts, 'file_sources')
            let file_sources = split(opts.file_sources, ',')
        else
            let file_sources = tlib#var#Get('trag#file_sources', 'bg', [])
        endif
        Tlibtrace 'trag', file_sources
        let optglob = get(opts, 'glob', '*')
        for source in file_sources
            Tlibtrace 'trag', source
            let source1 = source
            if source == 'files'
                let files = tlib#var#Get('trag_files', 'bg', [])
            elseif source == 'glob'
                let glob = get(opts, 'glob', tlib#var#Get('trag_glob', 'bg', ''))
                if !empty(glob)
                    Tlibtrace 'trag', glob
                    let files = split(glob(glob), '\n')
                endif
            elseif source == 'project'
                let proj = tlib#var#Get('trag_project_'. &filetype, 'bg', tlib#var#Get('trag_project', 'bg', ''))
                Tlibtrace 'trag', proj
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
            elseif source == 'git' && !has_key(opts, 'glob')
                let git_repos = tlib#var#Get('trag_git', 'bg', '')
                Tlibtrace 'trag', git_repos
                if git_repos == '*'
                    let git_repos = trag#FindGitRepos()
                elseif git_repos == "finddir"
                    let git_repos = finddir('.git')
                endif
                if !empty(git_repos)
                    Tlibtrace 'trag', git_repos
                    let files = trag#GetGitFiles(git_repos)
                endif
            elseif source == 'vcs' && !has_key(opts, 'glob')
                Tlibtrace 'trag', g:trag#check_vcs
                if g:trag#check_vcs
                    let files = tlib#vcs#Ls()
                end
            elseif source == 'buffer'
                let files = split(glob(s:GetGlobPattern(expand('%:p:h') .'/'. optglob, opts)), '\n')
            elseif source == 'filetype'
                let trag_get_files = tlib#var#Get('trag_get_files_'. &filetype, 'bg', '')
                Tlibtrace 'trag', &ft, trag_get_files
                if empty(trag_get_files)
                    let trag_get_files = tlib#var#Get('trag_get_files', 'bg', '')
                    " TLogVAR trag_get_files
                endif
                let files = eval(trag_get_files)
            elseif source == 'cd'
                let files = split(glob(s:GetGlobPattern(getcwd() .'/'. optglob, opts)), '\n')
            elseif source =~ '^\*' && exists(source)
                let fn = substitute(source, '^\*', '', '')
                let files = []
                let globs = call(fn, [opts])
                let idx = 0
                call tlib#progressbar#Init(len(globs), 'Trag: Glob %s', 20)
                try
                    for glob in globs
                        let idx += 1
                        call tlib#progressbar#Display(idx, glob, 1)
                        call extend(files, tlib#file#Glob(glob))
                    endfor
                finally
                    call tlib#progressbar#Restore()
                endtry
            endif
            if !empty(files)
                call filter(files, '!isdirectory(v:val)')
                let use_source = source
                Tlibtrace 'trag', source, len(files)
                break
            endif
        endfor
    endif
    if !empty(files)
        call map(files, 'tlib#file#Canonic(fnamemodify(v:val, ":p"))')
        let files = tlib#list#Uniq(files)
        " TLogVAR files
    endif
    return {'source': use_source, 'files': files}
endf


function! s:GetGlobPattern(root, opts) abort "{{{3
    if has_key(a:opts, 'glob')
        let suffix = ''
    else
        let suffix = expand('%:e')
    endif
    return empty(suffix) ? a:root : a:root . suffix
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
    if b:trag_cache_files.source !~ '\<vcs\>'
        let pattern = matchstr(expand('%:t:r'), '^\w\+')
        " call w.SetInitialFilter(pattern)
        call w.SetInitialFilter([[''], [pattern]])
    endif
    call w.Set_display_format('filename')
    " TLogVAR w.base
    call tlib#input#ListW(w)
endf


" :def: function! trag#Grep(args, ?replace=1, ?files=[], ?filetype='')
" args: A string with the format:
"   KIND REGEXP
"   KIND1,KIND2 REGEXP
"
" DEPRECATED: Old syntax. Please use |trag#GrepWithArgs()| instead.
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
    Tlibtrace 'trag', a:args, replace, files, filetype
    echohl WarningMsg
    echom 'trag#Grep() is deprecated. Please use trag#GrepWithArgs() instead.'
    echohl NONE
    let [kindspos, kindsneg, rx] = s:SplitArgs(a:args)
    return get(s:Grep(kindspos, kindsneg, rx, replace, files, filetype, {}), 'items', [])
endf


let s:trag_args = {
            \ 'help': ':Trag',
            \ 'values': {
            \   'accept': {'type': 1},
            \   'reject': {'type': 1},
            \   'cw': {'type': 1},
            \   'glob': {'type': 1},
            \   'include': {'default': ''},
            \   'exclude': {'default': ''},
            \   'filetype': {'default': ''},
            \   'literal': {'type': -1},
            \   'filenames': {'type': -1},
            \   'text': {'type': -1},
            \   'force': {'type': -1},
            \   'file_sources': {'type': 1, 'complete_customlist': 'g:trag#file_sources'},
            \   'grep_type': {'type': 1, 'complete_customlist': 'map(filter(tlib#cmd#OutputAsList("fun"), ''v:val =~ "GrepWith_\\w\\+(grepdef"''), ''matchstr(v:val, "GrepWith_\\zs\\w\\+")'')'},
            \ },
            \ 'flags': {
            \    'i': '--include', 'x': '--exclude',
            \    'l': '--literal',
            \    'A': '--accept', 'R': '--reject',
            \ },
            \ }


" :def: function! trag#GrepWithArgs(args, ?replace=1, ?extra={})
" args is a list of strings of command-line arguments of |:Trag|.
"
" If the variables [bg]:trag_rxf_{kind}_{&filetype} or 
" [bg]:trag_rxf_{kind} exist, these will be taken as format string (see 
" |printf()|) to format REGEXP.
function! trag#GrepWithArgs(args, ...) abort "{{{3
    TVarArg ['replace', 1], ['extra', {}]
    let opts = tlib#arg#GetOpts(a:args, s:trag_args)
    if !empty(extra)
        let opts = tlib#eval#Extend(opts, extra)
    endif
    Tlibtrace 'trag', a:args, a:000, replace, opts
    if opts.__exit__
        return
    endif
    let rx = get(opts.__rest__, 0, '')
    if get(opts, 'literal', 0)
        let rx = tlib#rx#Escape(rx)
    endif
    let files = opts.__rest__[1 : -1]
    let kindspos = s:SplitArgList(opts.include, [['identity']])
    let kindsneg = s:SplitArgList(opts.exclude, [])
    return s:Grep(kindspos, kindsneg, rx, replace, files, opts.filetype, opts)
endf


function! s:Grep(kindspos, kindsneg, rx, replace, files, filetype, opts) abort
    Tlibtrace 'trag', a:kindspos, a:kindsneg, a:rx, a:replace, a:files, a:filetype, a:opts
    if empty(a:rx)
        let rx = '.\{-}'
        " throw 'Malformed arguments (should be: "KIND REGEXP"): '. string(a:args)
    else
        let rx = a:rx
    endif
    " TAssertType rx, 'string'
    let s:grep_rx = rx
    if empty(a:files)
        let files = s:GetFiles(a:opts)
    else
        let files = split(join(map(a:files, 'glob(v:val)'), "\n"), '\n')
    endif
    let accept = get(a:opts, 'accept', '')
    if !empty(accept)
        call filter(files, 'v:val =~ accept')
    endif
    let reject = get(a:opts, 'reject', '')
    if !empty(reject)
        call filter(files, 'v:val !~ reject')
    endif
    Tlibtrace 'trag', len(files)
    " TLogVAR files
    " TAssertType files, 'list'
    call s:DoAutoCmd('QuickFixCmdPre')
    call tlib#progressbar#Init(len(files), 'Trag: Grep %s', 20)
    if a:replace
        call setqflist([])
    endif
    let scratch = {}
    try
        let qfl_top = len(getqflist())
        Tlibtrace 'trag', qfl_top
        let grepdef = trag#grepdefs#New(files, a:kindspos, a:kindsneg, rx, a:filetype)
        let strip = 0
        let done = 0

        if get(a:opts, 'grep_text', 1)
            let trag_type = get(a:opts, 'grep_type', tlib#var#Get('trag#grep_type', 'bg'))
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
                " TLogVAR grep_type, grep_opts
                " TLogVAR grepdef
                Tlibtrace 'trag', grep_type, grep_opts
                if s:GrepWith_{grep_type}(grepdef, grep_opts)
                    let strip = grep_type == 'vimgrep'
                    let done = 1
                    break
                endif
            endfor
            if !done
                throw 'Trag: Unsupported value for g:trag#grep_type: '. trag_type
            endif
        endif

        Tlibtrace 'trag', len(getqflist())
        if get(a:opts, 'grep_filenames', 0)
            for grep_def in grepdef.Get_grep_defs()
                let grep_def1 = copy(grep_def)
                let grep_def1.rxpos = substitute(grep_def1.rxpos, '\s', '[ _-]', 'g')
                let grep_def1.rxneg = substitute(grep_def1.rxneg, '\s', '[ _-]', 'g')
                " TLogVAR grep_def1
                let qfl = trag#ScanWithGrepDefs(grep_def1, [substitute(grep_def1.ff, '^.\{-}\([^\/]\+\)$', '\1', '')], 1)
                if !empty(qfl)
                    call setqflist(qfl, 'a')
                endif
                " TLogVAR qfl
            endfor
            let done = 1
        endif

        if !done
            throw 'Trag: Neither filenames nor text was scanned!'
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
        let cw = get(a:opts, 'cw', 'Tragcw')
        if !empty(cw) && cw !~ '^n\%[one]$'
            exec cw
        endif
        return {'items': qfl2[qfl_top : -1], 'grepdef': grepdef}
    finally
        if !empty(scratch)
            call tlib#scratch#CloseScratch(scratch)
            let &lazyredraw = lazyredraw
        endif
        call tlib#progressbar#Restore()
    endtry
endf


function! s:GrepWith_trag(grepdef, grep_opts) "{{{3
    let fidx  = 0
    for grep_def in a:grepdef.Get_grep_defs()
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


function! s:GrepWith_vimgrep(grepdef, grep_opts) "{{{3
    let rxnegs = {}
    let fidx  = 0
    for grep_def in a:grepdef.Get_grep_defs()
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


function! s:GrepWith_ack(grepdef, grep_opts) "{{{3
    return s:GrepWith_external(a:grepdef, 'ack '. a:grep_opts)
endf


function! s:GrepWith_ag(grepdef, grep_opts) "{{{3
    return s:GrepWith_external(a:grepdef, 'ag '. a:grep_opts)
endf


function! s:GrepWith_sift(grepdef, grep_opts) "{{{3
    return s:GrepWith_external(a:grepdef, 'sift '. a:grep_opts)
endf


function! s:GrepWith_grep(grepdef, grep_opts) "{{{3
    return s:GrepWith_external(a:grepdef, 'grep '. a:grep_opts)
endf


function! s:GrepWith_vcs(grepdef, grep_opts) "{{{3
    return s:GrepWith_external(a:grepdef, 'vcs '. a:grep_opts)
endf


function! s:GrepWith_external(grepdef, grep_opts) "{{{3
    let opts = tlib#arg#StringAsKeyArgsEqual(a:grep_opts)
    Tlibtrace 'trag', opts
    let grep_cmd = get(opts, 0, 'grep')
    " TLogVAR grep_cmd
    if index(g:trag#assume_executable, grep_cmd) == -1 && !tlib#sys#IsExecutable(grep_cmd)
        Tlibtrace 'trag', grep_cmd, 0
        return 0
    endif
    let group_defs = a:grepdef.Get_group_defs(grep_cmd)
    " TLogVAR group_defs
    let must_filter = a:grepdef.Get_must_filter(grep_cmd)
    " TLogVAR must_filter
    Tlibtrace 'trag', len(group_defs)
    let unprocessed_fnames = {}
    for [ft, group_def] in items(group_defs)
        let rx = get(group_def, 'use_rx', group_def.rxpos)
        let kinds = get(group_def, 'use_kinds', group_def.kindspos)
        " TLogVAR rx, kinds, len(group_def.files)
        Tlibtrace 'trag', rx, kinds
        let [ok, unprocessed_files] = trag#external#{grep_cmd}#Run(kinds, rx, group_def.files)
        Tlibtrace 'trag', ok, len(unprocessed_files)
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
    Tlibtrace 'trag', len(must_filter)
    if !empty(must_filter)
        let qfl = getqflist()
        let qfl = filter(qfl, 'v:val.bufnr > 0')
        Tlibtrace 'trag', 0, len(qfl)
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
        Tlibtrace 'trag', 1, len(qfl)
        call setqflist(qfl)
    endif
    let rxnegs = {}
    for [ft, group_def] in items(group_defs)
        if !empty(group_def.rxneg)
            for ff in group_def.files
                let bufnr = get(bnums, tlib#file#Canonic(ff), 0)
                if bufnr > 0 && !has_key(rxnegs, bufnr)
                    let rxnegs[bufnr] = group_def.rxneg
                endif
            endfor
        endif
    endfor
    Tlibtrace 'trag', len(rxnegs)
    call s:FilterRxNegs(rxnegs)
    Tlibtrace 'trag', len(unprocessed_fnames)
    if !empty(unprocessed_fnames)
        " TLogVAR unprocessed_fnames
        let grepdef1 = trag#grepdefs#New(keys(unprocessed_fnames), a:grepdef.kindspos, a:grepdef.kindsneg, a:grepdef.rx, a:grepdef.filetype)
        call s:GrepWith_{g:trag#grep_fallback_type}(grepdef1, a:grep_opts)
    endif
    Tlibtrace 'trag', 'done'
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
    let world_dict = tlib#eval#Extend(copy(g:trag#world), a:world_dict)
    " TLogVAR world_dict
    call call(function('tlib#qfl#QflList'), [a:list, world_dict] + a:000)
endf


" Display the |location-list| with |tlib#input#ListW()|.
function! trag#LocList(...) "{{{3
    TVarArg ['world', {}], ['suspended', 0]
    " TLogVAR world, suspended
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


function! trag#CComplete(ArgLead, CmdLine, CursorPos) abort "{{{3
    let words = tlib#arg#CComplete(s:trag_args, a:ArgLead)
    if !empty(a:ArgLead)
    endif
    return sort(words)
endf

