" slimv.vim:    The Superior Lisp Interaction Mode for VIM
" Version:      0.9.5
" Last Change:  07 Mar 2012
" Maintainer:   Tamas Kovacs <kovisoft at gmail dot com>
" License:      This file is placed in the public domain.
"               No warranty, express or implied.
"               *** ***   Use At-Your-Own-Risk!   *** ***
"
" =====================================================================
"
"  Load Once:
if &cp || exists( 'g:slimv_loaded' )
    finish
endif

let g:slimv_loaded = 1

let g:slimv_windows = 0
let g:slimv_cygwin  = 0
let g:slimv_osx     = 0

if has( 'win32' ) || has( 'win95' ) || has( 'win64' ) || has( 'win16' )
    let g:slimv_windows = 1
elseif has( 'win32unix' )
    let g:slimv_cygwin = 1
elseif has( 'macunix' )
    let g:slimv_osx = 1
endif


" =====================================================================
"  Functions used by global variable definitions
" =====================================================================

" Convert Cygwin path to Windows path, if needed
function! s:Cygpath( path )
    let path = a:path
    if g:slimv_cygwin
        let path = system( 'cygpath -w ' . path )
        let path = substitute( path, "\n", "", "g" )
        let path = substitute( path, "\\", "/", "g" )
    endif
    return path
endfunction

" Find swank.py in the Vim ftplugin directory (if not given in vimrc)
if !exists( 'g:swank_path' )
    let plugins = split( globpath( &runtimepath, 'ftplugin/**/swank.py'), '\n' )
    if len( plugins ) > 0
        let g:swank_path = s:Cygpath( plugins[0] )
    else
        let g:swank_path = 'swank.py'
    endif
endif

" Get the filetype (Lisp dialect) used by Slimv
function! SlimvGetFiletype()
    if &ft != ''
        " Return Vim filetype if defined
        return &ft
    endif

    if match( tolower( g:slimv_lisp ), 'clojure' ) >= 0 || match( tolower( g:slimv_lisp ), 'clj' ) >= 0
        " Must be Clojure
        return 'clojure'
    endif

    " We have no clue, guess its lisp
    return 'lisp'
endfunction

" Try to autodetect SWANK and build the command to start the SWANK server
function! SlimvSwankCommand()
    if exists( 'g:slimv_swank_clojure' ) && SlimvGetFiletype() == 'clojure'
        return g:slimv_swank_clojure
    endif
    if exists( 'g:slimv_swank_scheme' ) && SlimvGetFiletype() == 'scheme'
        return g:slimv_swank_scheme
    endif
    if exists( 'g:slimv_swank_cmd' )
        return g:slimv_swank_cmd
    endif

    if g:slimv_lisp == ''
        let g:slimv_lisp = input( 'Enter Lisp path (or fill g:slimv_lisp in your vimrc): ', '', 'file' )
    endif

    let cmd = b:SlimvSwankLoader()
    if cmd != ''
        if g:slimv_windows || g:slimv_cygwin
            return '!start /MIN ' . cmd
        elseif g:slimv_osx
            return '!osascript -e "tell application \"Terminal\" to do script \"' . cmd . '\""'
        elseif $STY != ''
            " GNU screen under Linux
            return '! screen -X eval "title swank" "screen ' . cmd . '" "select swank"'
        elseif $TMUX != ''
            " tmux under Linux
            return "! tmux new-window -d -n swank '" . cmd . "'"
        elseif $DISPLAY == ''
            " No X, no terminal multiplexer. Cannot run swank server.
            call SlimvErrorWait( 'No X server. Run Vim from screen/tmux or start SWANK server manually.' )
            return ''
        else
            " Must be Linux
            return '! xterm -iconic -e ' . cmd . ' &'
        endif
    endif
    return ''
endfunction

" =====================================================================
"  Global variable definitions
" =====================================================================

" Host name or IP address of the SWANK server
if !exists( 'g:swank_host' )
    let g:swank_host = 'localhost'
endif

" TCP port number to use for the SWANK server
if !exists( 'g:swank_port' )
    let g:swank_port = 4005
endif

" Find Lisp (if not given in vimrc)
if !exists( 'g:slimv_lisp' )
    let lisp = ['', '']
    if exists( 'g:slimv_preferred' )
        let lisp = b:SlimvAutodetect( tolower(g:slimv_preferred) )
    endif
    if lisp[0] == ''
        let lisp = b:SlimvAutodetect( '' )
    endif
    let g:slimv_lisp = lisp[0]
    if !exists( 'g:slimv_impl' )
        let g:slimv_impl = lisp[1]
    endif
endif

" Try to find out the Lisp implementation
" if not autodetected and not given in vimrc
if !exists( 'g:slimv_impl' )
    let g:slimv_impl = b:SlimvImplementation()
endif

" REPL buffer name
if !exists( 'g:slimv_repl_name' )
    let g:slimv_repl_name = 'REPL'
endif

" SLDB buffer name
if !exists( 'g:slimv_sldb_name' )
    let g:slimv_sldb_name = 'SLDB'
endif

" INSPECT buffer name
if !exists( 'g:slimv_inspect_name' )
    let g:slimv_inspect_name = 'INSPECT'
endif

" THREADS buffer name
if !exists( 'g:slimv_threads_name' )
    let g:slimv_threads_name = 'THREADS'
endif

" Shall we open REPL buffer in split window?
if !exists( 'g:slimv_repl_split' )
    let g:slimv_repl_split = 1
endif

" Wrap long lines in REPL buffer
if !exists( 'g:slimv_repl_wrap' )
    let g:slimv_repl_wrap = 1
endif

" Wrap long lines in SLDB buffer
if !exists( 'g:slimv_sldb_wrap' )
    let g:slimv_sldb_wrap = 0
endif

" Maximum number of lines echoed from the evaluated form
if !exists( 'g:slimv_echolines' )
    let g:slimv_echolines = 4
endif

" Syntax highlighting for the REPL buffer
if !exists( 'g:slimv_repl_syntax' )
    let g:slimv_repl_syntax = 0
endif

" Alternative value (in msec) for 'updatetime' while the REPL buffer is changing
if !exists( 'g:slimv_updatetime' )
    let g:slimv_updatetime = 500
endif

" Slimv keybinding set (0 = no keybindings)
if !exists( 'g:slimv_keybindings' )
    let g:slimv_keybindings = 1
endif

" Append Slimv menu to the global menu (0 = no menu)
if !exists( 'g:slimv_menu' )
    let g:slimv_menu = 1
endif

" Build the ctags command capable of generating lisp tags file
" The command can be run with execute 'silent !' . g:slimv_ctags
if !exists( 'g:slimv_ctags' )
    let ctags = split( globpath( '$vim,$vimruntime', 'ctags.exe' ), '\n' )
    if len( ctags ) > 0
        " Remove -a option to regenerate every time
        let g:slimv_ctags = '"' . ctags[0] . '" -a --language-force=lisp *.lisp *.clj'
    endif
endif

" Package/namespace handling
if !exists( 'g:slimv_package' )
    let g:slimv_package = 1
endif

" General timeout for various startup and connection events (seconds)
if !exists( 'g:slimv_timeout' )
    let g:slimv_timeout = 20
endif

" Use balloonexpr to display symbol description
if !exists( 'g:slimv_balloon' )
    let g:slimv_balloon = 1
endif

" Shall we use simple or fuzzy completion?
if !exists( 'g:slimv_simple_compl' )
    let g:slimv_simple_compl = 0
endif

" Custom <Leader> for the Slimv plugin
if !exists( 'g:slimv_leader' )
    if exists( 'mapleader' ) && mapleader != ' '
        let g:slimv_leader = mapleader
    else
        let g:slimv_leader = ','
    endif
endif

" Maximum number of lines searched backwards for indenting special forms
if !exists( 'g:slimv_indent_maxlines' )
    let g:slimv_indent_maxlines = 50
endif

" Special indentation for keyword lists
if !exists( 'g:slimv_indent_keylists' )
    let g:slimv_indent_keylists = 1
endif

" Maximum length of the REPL buffer
if !exists( 'g:slimv_repl_max_len' )
    let g:slimv_repl_max_len = 0
endif

" =====================================================================
"  Template definitions
" =====================================================================

if !exists( 'g:slimv_template_apropos' )
    if SlimvGetFiletype() == 'clojure'
        let g:slimv_template_apropos = '(find-doc "%1")'
    else
        let g:slimv_template_apropos = '(apropos "%1")'
    endif
endif


" =====================================================================
"  Other non-global script variables
" =====================================================================

let s:indent = ''                                         " Most recent indentation info
let s:last_update = 0                                     " The last update time for the REPL buffer
let s:save_updatetime = &updatetime                       " The original value for 'updatetime'
let s:save_showmode = &showmode                           " The original value for 'showmode'
let s:python_initialized = 0                              " Is the embedded Python initialized?
let s:swank_connected = 0                                 " Is the SWANK server connected?
let s:swank_package = ''                                  " Package to use at the next SWANK eval
let s:swank_form = ''                                     " Form to send to SWANK
let s:refresh_disabled = 0                                " Set this variable temporarily to avoid recursive REPL rehresh calls
let s:sldb_level = -1                                     " Are we in the SWANK debugger? -1 == no, else SLDB level
let s:compiled_file = ''                                  " Name of the compiled file
let s:au_curhold_set = 0                                  " Whether the autocommand has been set
let s:current_buf = -1                                    " Swank action was requested from this buffer
let s:current_win = -1                                    " Swank action was requested from this window
let s:skip_sc = 'synIDattr(synID(line("."), col("."), 0), "name") =~ "[Ss]tring\\|[Cc]omment"'
                                                          " Skip matches inside string or comment 
let s:frame_def = '^\s\{0,2}\d\{1,3}:'                    " Regular expression to match SLDB restart or frame identifier
let s:spec_indent = 'flet\|labels\|macrolet\|symbol-macrolet'
                                                          " List of symbols need special indenting
let s:spec_param = 'defmacro'                             " List of symbols with special parameter list
let s:binding_form = 'let\|let\*'                         " List of symbols with binding list

" =====================================================================
"  General utility functions
" =====================================================================

" Display an error message
function! SlimvError( msg )
    echohl ErrorMsg
    echo a:msg
    echohl None
endfunction 

" Display an error message and a question, return user response
function! SlimvErrorAsk( msg, question )
    echohl ErrorMsg
    let answer = input( a:msg . a:question )
    echo ""
    echohl None
    return answer
endfunction 

" Display an error message and wait for ENTER
function! SlimvErrorWait( msg )
    call SlimvErrorAsk( a:msg, " Press ENTER to continue." )
endfunction 

" Shorten long messages to fit status line
function! SlimvShortEcho( msg )
    let saved=&shortmess
    set shortmess+=T
    exe "normal :echomsg a:msg\n"
    let &shortmess=saved
endfunction

" Position the cursor at the end of the REPL buffer
" Optionally mark this position in Vim mark 's'
function! SlimvEndOfReplBuffer()
    if line( '.' ) >= b:repl_prompt_line - 1
        " Go to the end of file only if the user did not move up from here
        normal! G$
    endif
endfunction

" Remember the end of the REPL buffer: user may enter commands here
" Also remember the prompt, because the user may overwrite it
function! SlimvMarkBufferEnd()
    setlocal nomodified
    call SlimvEndOfReplBuffer()
    let b:repl_prompt_line = line( '$' )
    let b:repl_prompt_col = len( getline('$') ) + 1
    let b:repl_prompt = getline( b:repl_prompt_line )
endfunction

" Save caller buffer identification
function! SlimvBeginUpdate()
    let s:current_buf = bufnr( "%" )
    if winnr('$') < 2
        " No windows yet
        let s:current_win = -1
    else
        let s:current_win = winnr()
    endif
endfunction

" Stop updating the REPL buffer and switch back to caller
function! SlimvEndUpdateRepl()
    " Keep only the last g:slimv_repl_max_len lines
    let lastline = line('$')
    let prompt_offset = lastline - b:repl_prompt_line
    if g:slimv_repl_max_len > 0 && lastline > g:slimv_repl_max_len
        let start = ''
        let ending = s:CloseForm( getline( 1, lastline - g:slimv_repl_max_len ) )
        if match( ending, ')\|\]\|}\|"' ) >= 0
            " Reverse the ending and replace matched characters with their pairs
            let start = join( reverse( split( ending, '.\zs' ) ), '' )
            let start = substitute( start, ')', '(', 'g' )
            let start = substitute( start, ']', '[', 'g' )
            let start = substitute( start, '}', '{', 'g' )
        endif

        " Delete extra lines
        execute "python vim.current.buffer[0:" . (lastline - g:slimv_repl_max_len) . "] = []"

        " Re-balance the beginning of the buffer
        if start != ''
            call append( 0, start . " .... ; output shortened" )
        endif
        let b:repl_prompt_line = line( '$' ) - prompt_offset
    endif

    " Mark current prompt position
    call SlimvMarkBufferEnd()
    let repl_buf = bufnr( g:slimv_repl_name )
    let repl_win = bufwinnr( repl_buf )
    if repl_buf != s:current_buf && repl_win != -1 && s:sldb_level < 0
        " Switch back to the caller buffer/window
        if g:slimv_repl_split
            if s:current_win == -1
                let s:current_win = winnr('#')
            endif
            if s:current_win > 0 && s:current_win != repl_win
                execute s:current_win . "wincmd w"
            endif
        else
            execute "buf " . s:current_buf
        endif
    endif
endfunction

" Handle response coming from the SWANK listener
function! SlimvSwankResponse()
    let s:refresh_disabled = 1
    silent execute 'python swank_output(1)'
    let s:refresh_disabled = 0
    let msg = ''
    redir => msg
    silent execute 'python swank_response("")'
    redir END

    if msg != ''
        if s:swank_action == ':describe-symbol'
            echo substitute(msg,'^\n*','','')
        endif
    endif
    if s:swank_actions_pending
        let s:last_update = -1
    elseif s:last_update < 0
        " Remember the time when all actions are processed
        let s:last_update = localtime()
    endif
    if s:swank_actions_pending == 0 && s:last_update >= 0 && s:last_update < localtime() - 2
        " All SWANK output handled long ago, restore original update frequency
        let &updatetime = s:save_updatetime
    endif
endfunction

" Execute the given command and write its output at the end of the REPL buffer
function! SlimvCommand( cmd )
    silent execute a:cmd
    if g:slimv_updatetime < &updatetime
        " Update more frequently until all swank responses processed
        let &updatetime = g:slimv_updatetime
        let s:last_update = -1
    endif
endfunction

" Execute the given SWANK command, wait for and return the response
function! SlimvCommandGetResponse( name, cmd, timeout )
    let s:refresh_disabled = 1
    call SlimvCommand( a:cmd )
    let msg = ''
    let s:swank_action = ''
    let starttime = localtime()
    let cmd_timeout = a:timeout
    if cmd_timeout == 0
        let cmd_timeout = 3
    endif
    while s:swank_action == '' && localtime()-starttime < cmd_timeout
        python swank_output( 0 )
        redir => msg
        silent execute 'python swank_response("' . a:name . '")'
        redir END
    endwhile
    let s:refresh_disabled = 0
    return msg
endfunction

" Reload the contents of the REPL buffer from the output file if changed
function! SlimvRefreshReplBuffer()
    if s:refresh_disabled
        " Refresh is unwanted at the moment, probably another refresh is going on
        return
    endif

    let repl_buf = bufnr( g:slimv_repl_name )
    if repl_buf == -1
        " REPL buffer not loaded
        return
    endif
    let repl_win = bufwinnr( repl_buf )
    let this_win = winnr()

    if s:swank_connected
        call SlimvSwankResponse()
    endif
endfunction

" This function re-triggers the CursorHold event
" after refreshing the REPL buffer
function! SlimvTimer()
    call SlimvRefreshReplBuffer()
    if mode() == 'i' || mode() == 'I' || mode() == 'r' || mode() == 'R'
        " Put '<Insert>' twice into the typeahead buffer, which should not do anything
        " just switch to replace/insert mode then back to insert/replace mode
        " But don't do this for readonly buffers
        if bufname('%') != g:slimv_sldb_name && bufname('%') != g:slimv_inspect_name && bufname('%') != g:slimv_threads_name
            call feedkeys("\<insert>\<insert>")
        endif
    else
        " Put an incomplete 'f' command and an Esc into the typeahead buffer
        call feedkeys("f\e")
    endif
endfunction

" Switch refresh mode on:
" refresh REPL buffer on frequent Vim events
function! SlimvRefreshModeOn()
    if ! s:au_curhold_set
        let s:au_curhold_set = 1
        execute "au CursorHold   * :call SlimvTimer()"
        execute "au CursorHoldI  * :call SlimvTimer()"
    endif
endfunction

" Switch refresh mode off
function! SlimvRefreshModeOff()
    execute "au! CursorHold"
    execute "au! CursorHoldI"
    let s:au_curhold_set = 0
endfunction

" Called when entering REPL buffer
function! SlimvReplEnter()
    call SlimvAddReplMenu()
    execute "au FileChangedRO " . g:slimv_repl_name . " :call SlimvRefreshModeOff()"
    call SlimvRefreshModeOn()
endfunction

" Called when leaving REPL buffer
function! SlimvReplLeave()
    try
        " Check if REPL menu exists, then remove it
        aunmenu REPL
        execute ':unmap ' . g:slimv_leader . '\'
    catch /.*/
        " REPL menu not found, we cannot remove it
    endtry
    if g:slimv_repl_split
        call SlimvRefreshModeOn()
    else
        call SlimvRefreshModeOff()
    endif
endfunction

" View the given file in a top/bottom/left/right split window
function! s:SplitView( filename )
    if winnr('$') >= 2
        " We have already at least two windows
        if bufnr("%") == s:current_buf && winnr() == s:current_win
            " Keep the current window on screen, use the other window for the new buffer
            execute "wincmd p"
        endif
        execute "silent view! " . a:filename
    else
        " No windows yet, need to split
        if g:slimv_repl_split == 1
            execute "silent topleft sview! " . a:filename
        elseif g:slimv_repl_split == 2
            execute "silent botright sview! " . a:filename
        elseif g:slimv_repl_split == 3
            execute "silent topleft vertical sview! " . a:filename
        elseif g:slimv_repl_split == 4
            execute "silent botright vertical sview! " . a:filename
        else
            execute "silent view! " . a:filename
        endif
    endif
    stopinsert
endfunction

" Open a buffer with the given name if not yet open, and switch to it
function! SlimvOpenBuffer( name )
    let buf = bufnr( a:name )
    if buf == -1
        " Create a new buffer
        call s:SplitView( a:name )
    else
        if g:slimv_repl_split
            " Buffer is already created. Check if it is open in a window
            let win = bufwinnr( buf )
            if win == -1
                " Create windows
                call s:SplitView( a:name )
            else
                " Switch to the buffer's window
                if winnr() != win
                    execute win . "wincmd w"
                endif
            endif
        else
            execute "buffer " . buf
            stopinsert
        endif
    endif
    setlocal buftype=nofile
    setlocal noswapfile
    setlocal noreadonly
endfunction

" Go to the end of the screen line
function s:EndOfScreenLine()
    if len(getline('.')) < &columns
        " g$ moves the cursor to the rightmost column if virtualedit=all
        normal! $
    else
        normal! g$
    endif
endfunction

" Open a new REPL buffer
function! SlimvOpenReplBuffer()
    call SlimvOpenBuffer( g:slimv_repl_name )
    call b:SlimvInitRepl()
    call PareditInitBuffer()
    if !g:slimv_repl_syntax
        set syntax=
    endif

    " Prompt and its line and column number in the REPL buffer
    if !exists( 'b:repl_prompt' )
        let b:repl_prompt = ''
        let b:repl_prompt_line = 1
        let b:repl_prompt_col = 1
    endif

    " Add keybindings valid only for the REPL buffer
    inoremap <buffer> <silent>        <CR>   <C-R>=pumvisible() ? "\<lt>CR>" : "\<lt>End>\<lt>C-O>:call SlimvSendCommand(0)\<lt>CR>"<CR>
    inoremap <buffer> <silent>        <C-CR> <End><C-O>:call SlimvSendCommand(1)<CR>
    inoremap <buffer> <silent>        <Up>   <C-R>=pumvisible() ? "\<lt>Up>" : "\<lt>C-O>:call SlimvHandleUp()\<lt>CR>"<CR>
    inoremap <buffer> <silent>        <Down> <C-R>=pumvisible() ? "\<lt>Down>" : "\<lt>C-O>:call SlimvHandleDown()\<lt>CR>"<CR>
    inoremap <buffer> <silent>        <C-C>  <C-O>:call SlimvInterrupt()<CR>

    if exists( 'g:paredit_loaded' )
        inoremap <buffer> <silent> <expr> <BS>   PareditBackspace(1)
    else
        inoremap <buffer> <silent> <expr> <BS>   SlimvHandleBS()
    endif

    if g:slimv_keybindings == 1
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'.      :call SlimvSendCommand(0)<CR>'
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'/      :call SlimvSendCommand(1)<CR>'
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'<Up>   :call SlimvPreviousCommand()<CR>'
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'<Down> :call SlimvNextCommand()<CR>'
    elseif g:slimv_keybindings == 2
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'rs     :call SlimvSendCommand(0)<CR>'
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'ro     :call SlimvSendCommand(1)<CR>'
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'rp     :call SlimvPreviousCommand()<CR>'
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'rn     :call SlimvNextCommand()<CR>'
    endif

    if g:slimv_repl_wrap
        inoremap <buffer> <silent>        <Home> <C-O>g<Home>
        inoremap <buffer> <silent>        <End>  <C-O>:call <SID>EndOfScreenLine()<CR>
        noremap  <buffer> <silent>        <Up>   gk
        noremap  <buffer> <silent>        <Down> gj
        noremap  <buffer> <silent>        <Home> g<Home>
        noremap  <buffer> <silent>        <End>  :call <SID>EndOfScreenLine()<CR>
        noremap  <buffer> <silent>        k      gk
        noremap  <buffer> <silent>        j      gj
        noremap  <buffer> <silent>        0      g0
        noremap  <buffer> <silent>        $      :call <SID>EndOfScreenLine()<CR>
        setlocal wrap
    endif

    hi SlimvNormal term=none cterm=none gui=none
    hi SlimvCursor term=reverse cterm=reverse gui=reverse

    " Add autocommands specific to the REPL buffer
    execute "au FileChangedShell " . g:slimv_repl_name . " :call SlimvRefreshReplBuffer()"
    execute "au FocusGained "      . g:slimv_repl_name . " :call SlimvRefreshReplBuffer()"
    execute "au BufEnter "         . g:slimv_repl_name . " :call SlimvReplEnter()"
    execute "au BufLeave "         . g:slimv_repl_name . " :call SlimvReplLeave()"

    call SlimvRefreshReplBuffer()
endfunction

" Open a new Inspect buffer
function SlimvOpenInspectBuffer()
    call SlimvOpenBuffer( g:slimv_inspect_name )
    let b:range_start = 0
    let b:range_end   = 0
    let b:help = SlimvHelpInspect()

    " Add keybindings valid only for the Inspect buffer
    noremap  <buffer> <silent>        <F1>   :call SlimvToggleHelp()<CR>
    noremap  <buffer> <silent>        <CR>   :call SlimvHandleEnterInspect()<CR>
    noremap  <buffer> <silent> <Backspace>   :call SlimvSendSilent(['[-1]'])<CR>
    execute 'noremap <buffer> <silent> ' . g:slimv_leader.'q      :call SlimvQuitInspect()<CR>'

    syn match Type /^\[\d\+\]/
    syn match Type /^\[<<\]/
    syn match Type /^\[--more--\]$/
endfunction

" Open a new Threads buffer
function SlimvOpenThreadsBuffer()
    call SlimvOpenBuffer( g:slimv_threads_name )
    let b:help = SlimvHelpThreads()

    " Add keybindings valid only for the Threads buffer
    "noremap  <buffer> <silent>        <CR>   :call SlimvHandleEnterThreads()<CR>
    noremap  <buffer> <silent>        <F1>                        :call SlimvToggleHelp()<CR>
    noremap  <buffer> <silent> <Backspace>                        :call SlimvKillThread()<CR>
    execute 'noremap <buffer> <silent> ' . g:slimv_leader.'r      :call SlimvListThreads()<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimv_leader.'d      :call SlimvDebugThread()<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimv_leader.'k      :call SlimvKillThread()<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimv_leader.'q      :call SlimvQuitThreads()<CR>'
endfunction

" Open a new SLDB buffer
function SlimvOpenSldbBuffer()
    call SlimvOpenBuffer( g:slimv_sldb_name )

    " Add keybindings valid only for the SLDB buffer
    noremap  <buffer> <silent>        <CR>   :call SlimvHandleEnterSldb()<CR>
    if g:slimv_keybindings == 1
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'a      :call SlimvDebugCommand("swank_invoke_abort")<CR>'
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'q      :call SlimvDebugCommand("swank_throw_toplevel")<CR>'
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'n      :call SlimvDebugCommand("swank_invoke_continue")<CR>'
    elseif g:slimv_keybindings == 2
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'da     :call SlimvDebugCommand("swank_invoke_abort")<CR>'
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'dq     :call SlimvDebugCommand("swank_throw_toplevel")<CR>'
        execute 'noremap <buffer> <silent> ' . g:slimv_leader.'dn     :call SlimvDebugCommand("swank_invoke_continue")<CR>'
    endif

    " Set folding parameters
    setlocal foldmethod=marker
    setlocal foldmarker={{{,}}}
    setlocal foldtext=substitute(getline(v:foldstart),'{{{','','')
    setlocal iskeyword+=+,-,*,/,%,<,=,>,:,$,?,!,@-@,94,~,#,\|,&,{,},[,]
    if g:slimv_sldb_wrap
        setlocal wrap
    endif

    if version < 703
        " conceal mechanism is defined since Vim 7.3
        syn match Ignore /{{{/
        syn match Ignore /}}}/
    else
        setlocal conceallevel=3 concealcursor=nc
        syn match Comment /{{{/ conceal
        syn match Comment /}}}/ conceal
    endif
    syn match Type /^\s\{0,2}\d\{1,3}:/
    syn match Type /^\s\+in "\(.*\)" \(line\|byte\) \(\d\+\)$/
endfunction

" End updating an otherwise readonly buffer
function SlimvEndUpdate()
    setlocal readonly
    setlocal nomodified
endfunction

" Quit Inspector
function SlimvQuitInspect()
    " Clear the contents of the Inspect buffer
    setlocal noreadonly
    silent! %d
    call SlimvEndUpdate()
    call SlimvCommand( 'python swank_quit_inspector()' )
    b #
endfunction

" Quit Threads
function SlimvQuitThreads()
    " Clear the contents of the Threads buffer
    setlocal noreadonly
    silent! %d
    call SlimvEndUpdate()
    b #
endfunction

" Quit Sldb
function SlimvQuitSldb()
    " Clear the contents of the Sldb buffer
    setlocal noreadonly
    silent! %d
    call SlimvEndUpdate()
    b #
endfunction

" Create help text for Inspect buffer
function SlimvHelpInspect()
    let help = []
    call add( help, '<F1>        : toggle this help' )
    call add( help, '<Enter>     : open object or select action under cursor' )
    call add( help, '<Backspace> : go back to previous object' )
    call add( help, g:slimv_leader . 'q          : quit' )
    return help
endfunction

" Create help text for Threads buffer
function SlimvHelpThreads()
    let help = []
    call add( help, '<F1>        : toggle this help' )
    call add( help, '<Backspace> : kill thread' )
    call add( help, g:slimv_leader . 'k          : kill thread' )
    call add( help, g:slimv_leader . 'd          : debug thread' )
    call add( help, g:slimv_leader . 'r          : refresh' )
    call add( help, g:slimv_leader . 'q          : quit' )
    return help
endfunction

" Write help text to current buffer at given line
function SlimvHelp( line )
    setlocal noreadonly
    if exists( 'b:help_shown' )
        let help = b:help
    else
        let help = ['Press <F1> for Help']
    endif
    let b:help_line = a:line
    call append( b:help_line, help )
    call SlimvEndUpdate()
endfunction

" Toggle help
function SlimvToggleHelp()
    if exists( 'b:help_shown' )
        let lines = len( b:help )
        unlet b:help_shown
    else
        let lines = 1
        let b:help_shown = 1
    endif
    setlocal noreadonly
    execute ":" . (b:help_line+1) . "," . (b:help_line+lines) . "d"
    call SlimvHelp( b:help_line )
endfunction

" Open SLDB buffer and place cursor on the given frame
function SlimvGotoFrame( frame )
    call SlimvOpenSldbBuffer()
    let bcktrpos = search( '^Backtrace:', 'bcnw' )
    let line = getline( '.' )
    let item = matchstr( line, '^\s*' . a:frame .  ':' )
    if item != '' && line('.') > bcktrpos
        " Already standing on the frame
        return
    endif

    " Must locate the frame starting from the 'Backtrace:' string
    call search( '^Backtrace:', 'bcw' )
    call search( '^\s*' . a:frame .  ':', 'w' )
endfunction

" Set 'iskeyword' option depending on file type
function! s:SetKeyword()
    if SlimvGetFiletype() == 'clojure'
        setlocal iskeyword+=+,-,*,/,%,<,=,>,:,$,?,!,@-@,94,~,#,\|,&
    else
        setlocal iskeyword+=+,-,*,/,%,<,=,>,:,$,?,!,@-@,94,~,#,\|,&,{,},[,]
    endif
endfunction

" Select symbol under cursor and return it
function! SlimvSelectSymbol()
    call s:SetKeyword()
    let symbol = expand('<cword>')
    return symbol
endfunction

" Select symbol with possible prefixes under cursor and return it
function! SlimvSelectSymbolExt()
    let save_iskeyword = &iskeyword
    call s:SetKeyword()
    setlocal iskeyword+='
    let symbol = expand('<cword>')
    let &iskeyword = save_iskeyword
    return symbol
endfunction

" Select bottom level form the cursor is inside and copy it to register 's'
function! SlimvSelectForm()
    " Search the opening '(' if we are standing on a special form prefix character
    let c = col( '.' ) - 1
    let firstchar = getline( '.' )[c]
    while c < len( getline( '.' ) ) && match( "'`#", getline( '.' )[c] ) >= 0
        normal! l
        let c = c + 1
    endwhile
    let p1 = getpos('.')
    normal! va(o
    let p2 = getpos('.')
    if firstchar != '(' && p1[1] == p2[1] && (p1[2] == p2[2] || p1[2] == p2[2]+1)
        " Empty selection and no paren found, select current word instead
        normal! aw
    else
        " Handle '() or #'() etc. type special syntax forms (but stop at prompt)
        let c = col( '.' ) - 2
        while c >= 0 && match( ' \t()>', getline( '.' )[c] ) < 0
            normal! h
            let c = c - 1
        endwhile
    endif
    silent normal! "sy
    let sel = SlimvGetSelection()
    if sel == ''
        call SlimvError( "Form is empty." )
        return 0
    elseif sel == '(' || sel == '[' || sel == '{'
        call SlimvError( "Form is unbalanced." )
        return 0
    else
        return 1
    endif
endfunction

" Find starting '(' of a top level form
function! SlimvFindDefunStart()
    let l = line( '.' )
    let matchb = max( [l-100, 1] )
    while searchpair( '(', '', ')', 'bW', s:skip_sc, matchb )
    endwhile
endfunction

" Select top level form the cursor is inside and copy it to register 's'
function! SlimvSelectDefun()
    call SlimvFindDefunStart()
    return SlimvSelectForm()
endfunction

" Return the contents of register 's'
function! SlimvGetSelection()
    return getreg( 's' )
endfunction

" Find language specific package/namespace definition backwards
" Set it as the current package for the next swank action
function! SlimvFindPackage()
    if !g:slimv_package || SlimvGetFiletype() == 'scheme'
        return
    endif
    let oldpos = winsaveview()
    if SlimvGetFiletype() == 'clojure'
        let string = '\(in-ns\|ns\)'
    else
        let string = '\(cl:\|common-lisp:\|\)in-package'
    endif
    let found = 0
    let searching = search( '(\s*' . string . '\s', 'bcW' )
    while searching
        " Search for the previos occurrence
        if synIDattr( synID( line('.'), col('.'), 0), 'name' ) !~ '[Ss]tring\|[Cc]omment'
            " It is not inside a comment or string
            let found = 1
            break
        endif
        let searching = search( '(\s*' . string . '\s', 'bW' )
    endwhile
    if found
        silent normal! ww
        let l:packagename_tokens = split(expand('<cWORD>'),')\|\s')
        if l:packagename_tokens != []
            " Remove quote character from package name
            let s:swank_package = substitute( l:packagename_tokens[0], "'", '', '' )
        else
            let s:swank_package = ''
        endif
    endif
    call winrestview( oldpos )
endfunction

" Execute the given SWANK command with current package defined
function! SlimvCommandUsePackage( cmd )
    call SlimvFindPackage()
    let s:refresh_disabled = 1
    call SlimvCommand( a:cmd )
    let s:swank_package = ''
    let s:refresh_disabled = 0
    call SlimvRefreshReplBuffer()
endfunction

" Initialize embedded Python and connect to SWANK server
function! SlimvConnectSwank()
    if !s:python_initialized
        if ! has('python')
            call SlimvErrorWait( 'Vim is compiled without the Python feature. Unable to run SWANK client.' )
            return 0
        endif
        if g:slimv_windows || g:slimv_cygwin
            " Verify that Vim is compiled with Python and Python is properly installed
            let v = ''
            redir => v
            silent ver
            redir END
            let pydll = matchstr( v, '\cpython..\.dll' )
            if ! executable( pydll )
                call SlimvErrorWait( pydll . ' not found. Unable to run SWANK client.' )
                return 0
            endif
        endif
        python import vim
        execute 'pyfile ' . g:swank_path
        let s:python_initialized = 1
    endif

    if !s:swank_connected
        let s:swank_version = ''
        let s:lisp_version = ''
        if g:swank_host == ''
            let g:swank_host = input( 'Swank server host name: ', 'localhost' )
        endif
        execute 'python swank_connect("' . g:swank_host . '", ' . g:swank_port . ', "result" )'
        if result != '' && ( g:swank_host == 'localhost' || g:swank_host == '127.0.0.1' )
            " SWANK server is not running, start server if possible
            let swank = SlimvSwankCommand()
            if swank != ''
                redraw
                echon "\rStarting SWANK server..."
                silent execute swank
                let starttime = localtime()
                while result != '' && localtime()-starttime < g:slimv_timeout
                    sleep 500m
                    execute 'python swank_connect("' . g:swank_host . '", ' . g:swank_port . ', "result" )'
                endwhile
                redraw!
            endif
        endif
        if result != ''
            " Display connection error message
            call SlimvErrorWait( result )
            return 0
        endif

        " Connected to SWANK server
        redraw
        echon "\rGetting SWANK connection info..."
        let starttime = localtime()
        while s:swank_version == '' && localtime()-starttime < g:slimv_timeout
            call SlimvSwankResponse()
        endwhile
        if s:swank_version >= '2008-12-23'
            call SlimvCommandGetResponse( ':create-repl', 'python swank_create_repl()', g:slimv_timeout )
        endif
        let s:swank_connected = 1
        if g:slimv_simple_compl == 0
            python swank_require('swank-fuzzy')
            call SlimvSwankResponse()
        endif
        redraw
        echon "\rConnected to SWANK server on port " . g:swank_port . "."
        if exists( "g:swank_block_size" ) && SlimvGetFiletype() == 'lisp'
            " Override SWANK connection output buffer size
            let cmd = "(progn (setf (slot-value (swank::connection.user-output swank::*emacs-connection*) 'swank-backend::buffer)"
            let cmd = cmd . " (make-string " . g:swank_block_size . ")) nil)"
            call SlimvSend( [cmd], 0, 1 )
        endif
        if exists( "*b:SlimvReplInit" )
            " Perform implementation specific REPL initialization if supplied
            call b:SlimvReplInit( s:lisp_version )
        endif
    endif
    return s:swank_connected
endfunction

" Send argument to Lisp server for evaluation
function! SlimvSend( args, echoing, output )
    call SlimvBeginUpdate()

    if ! SlimvConnectSwank()
        return
    endif

    " Send the lines to the client for evaluation
    let text = join( a:args, "\n" ) . "\n"

    let s:refresh_disabled = 1
    let s:swank_form = text
    if a:output
        call SlimvOpenReplBuffer()
    endif
    if a:echoing && g:slimv_echolines != 0
        if g:slimv_echolines > 0
            let nlpos = match( s:swank_form, "\n", 0, g:slimv_echolines )
            if nlpos > 0
                " Echo only the first g:slimv_echolines number of lines
                let trimmed = strpart( s:swank_form, nlpos )
                let s:swank_form = strpart( s:swank_form, 0, nlpos )
                let ending = s:CloseForm( [s:swank_form] )
                if ending != 'ERROR'
                    if substitute( trimmed, '\s\|\n', '', 'g' ) == ''
                        " Only whitespaces are trimmed
                        let s:swank_form = s:swank_form . ending . "\n"
                    else
                        " Valuable characters trimmed, indicate it by printing "..."
                        let s:swank_form = s:swank_form . " ..." . ending . "\n"
                    endif
                endif
            endif
        endif
        let lines = split( s:swank_form, '\n', 1 )
        call append( '$', lines )
        let s:swank_form = text
    elseif a:output
        " Open a new line for the output
        call append( '$', '' )
    endif
    if a:output
        call SlimvMarkBufferEnd()
    endif
    call SlimvCommand( 'python swank_input("s:swank_form")' )
    let s:swank_package = ''
    let s:refresh_disabled = 0
    call SlimvRefreshModeOn()
    call SlimvRefreshReplBuffer()
endfunction

" Eval arguments in Lisp REPL
function! SlimvEval( args )
    call SlimvSend( a:args, 1, 1 )
endfunction

" Send argument silently to SWANK
function! SlimvSendSilent( args )
    call SlimvSend( a:args, 0, 0 )
endfunction

" Set command line after the prompt
function! SlimvSetCommandLine( cmd )
    let line = getline( "." )
    if line( "." ) == b:repl_prompt_line
        " The prompt is in the line marked by b:repl_prompt_line
        let promptlen = len( b:repl_prompt )
    else
        let promptlen = 0
    endif
    if len( line ) > promptlen
        let line = strpart( line, 0, promptlen )
    endif
    let line = line . a:cmd
    call setline( ".", line )
    call SlimvEndOfReplBuffer()
    set nomodified
endfunction

" Add command list to the command history
function! SlimvAddHistory( cmd )
    if !exists( 'g:slimv_cmdhistory' )
        let g:slimv_cmdhistory = []
    endif
    let i = 0
    while i < len( a:cmd )
        " Trim trailing whitespaces from the command
        let command = substitute( a:cmd[i], "\\(.*[^ ]\\)\\s*", "\\1", "g" )
        if len( a:cmd ) > 1 || len( g:slimv_cmdhistory ) == 0 || command != g:slimv_cmdhistory[-1]
            " Add command only if differs from the last one
            call add( g:slimv_cmdhistory, command )
        endif
        let i = i + 1
    endwhile
    let g:slimv_cmdhistorypos = len( g:slimv_cmdhistory )
endfunction

" Recall command from the command history at the marked position
function! SlimvRecallHistory()
    if g:slimv_cmdhistorypos >= 0 && g:slimv_cmdhistorypos < len( g:slimv_cmdhistory )
        call SlimvSetCommandLine( g:slimv_cmdhistory[g:slimv_cmdhistorypos] )
    else
        call SlimvSetCommandLine( "" )
    endif
endfunction

" Return missing parens, double quotes, etc to properly close form
function! s:CloseForm( lines )
    let form = join( a:lines, "\n" )
    let end = ''
    let i = 0
    while i < len( form )
        if form[i] == '"'
            " Inside a string
            let end = '"' . end
            let i += 1
            while i < len( form )
                if form[i] == '\'
                    " Ignore next character
                    let i += 2
                elseif form[i] == '"'
                    let end = end[1:]
                    break
                else
                    let i += 1
                endif
            endwhile
        elseif form[i] == ';'
            " Inside a comment
            let end = "\n" . end
            let cend = match(form, "\n", i)
            if cend == -1
                break
            endif
            let i = cend
            let end = end[1:]
        else
            " We are outside of strings and comments, now we shall count parens
            if form[i] == '('
                let end = ')' . end
            elseif form[i] == '[' && SlimvGetFiletype() == 'clojure'
                let end = ']' . end
            elseif form[i] == '{' && SlimvGetFiletype() == 'clojure'
                let end = '}' . end
            elseif form[i] == ')' || ((form[i] == ']' || form[i] == '}') && SlimvGetFiletype() == 'clojure')
                if len( end ) == 0 || end[0] != form[i]
                    " Oops, too many closing parens or invalid closing paren
                    return 'ERROR'
                endif
                let end = end[1:]
            endif
        endif
        let i += 1
    endwhile
    return end
endfunction

" Return Lisp source code indentation at the given line
function! SlimvIndent( lnum )
    if a:lnum <= 1
        " Start of the file
        return 0
    endif
    let pnum = prevnonblank(a:lnum - 1)
    if pnum == 0
        " Hit the start of the file, use zero indent.
        return 0
    endif

    " Handle special indentation style for flet, labels, etc.
    " When searching for containing forms, don't go back
    " more than g:slimv_indent_maxlines lines.
    let backline = max([pnum-g:slimv_indent_maxlines, 1])
    let oldpos = winsaveview()
    let indent_keylists = g:slimv_indent_keylists
    " Find beginning of the innermost containing form
    normal! 0
    let [l, c] = searchpairpos( '(', '', ')', 'bW', s:skip_sc, backline )
    if l > 0
        if SlimvGetFiletype() == 'clojure'
            " Is this a clojure form with [] binding list?
            call winrestview( oldpos )
            let [lb, cb] = searchpairpos( '\[', '', '\]', 'bW', s:skip_sc, backline )
            if lb >= l && (lb > l || cb > c)
                call winrestview( oldpos )
                return cb
            endif
        endif
        " Is this a form with special indentation?
        let line = strpart( getline(l), c-1 )
        if match( line, '\c^(\s*\('.s:spec_indent.'\)\>' ) >= 0
            " Search for the binding list and jump to its end
            if search( '(' ) > 0
                exe 'normal! %'
                if line('.') == pnum
                    " We are indenting the first line after the end of the binding list
                    call winrestview( oldpos )
                    return c + 1
                endif
            endif
        elseif l == pnum
            " If the containing form starts above this line then find the
            " second outer containing form (possible start of the binding list)
            let [l2, c2] = searchpairpos( '(', '', ')', 'bW', s:skip_sc, backline )
            if l2 > 0
                let line2 = strpart( getline(l2), c2-1 )
                if match( line2, '\c^(\s*\('.s:spec_param.'\)\>' ) >= 0
                    if search( '(' ) > 0
                        if line('.') == l && col('.') == c
                            " This is the parameter list of a special form
                            call winrestview( oldpos )
                            return c
                        endif
                    endif
                endif
                if SlimvGetFiletype() != 'clojure'
                    if l2 == l && match( line2, '\c^(\s*\('.s:binding_form.'\)\>' ) >= 0
                        " Is this a lisp form with binding list?
                        call winrestview( oldpos )
                        return c
                    endif
                    if match( line2, '\c^(\s*cond\>' ) >= 0 && match( line, '\c^(\s*t\>' ) >= 0
                        " Is this the 't' case for a 'cond' form?
                        call winrestview( oldpos )
                        return c
                    endif
                    if match( line2, '\c^(\s*defpackage\>' ) >= 0
                        let indent_keylists = 0
                    endif
                endif
                " Go one level higher and check if we reached a special form
                let [l3, c3] = searchpairpos( '(', '', ')', 'bW', s:skip_sc, backline )
                if l3 > 0
                    " Is this a form with special indentation?
                    let line3 = strpart( getline(l3), c3-1 )
                    if match( line3, '\c^(\s*\('.s:spec_indent.'\)\>' ) >= 0
                        " This is the first body-line of a binding
                        call winrestview( oldpos )
                        return c + 1
                    endif
                    if match( line3, '\c^(\s*defsystem\>' ) >= 0
                        let indent_keylists = 0
                    endif
                    " Finally go to the topmost level to check for some forms with special keyword indenting
                    let [l4, c4] = searchpairpos( '(', '', ')', 'brW', s:skip_sc, backline )
                    if l4 > 0
                        let line4 = strpart( getline(l4), c4-1 )
                        if match( line4, '\c^(\s*defsystem\>' ) >= 0
                            let indent_keylists = 0
                        endif
                    endif
                endif
            endif
        endif
        " Restore all cursor movements
        call winrestview( oldpos )
    endif

    " Check if the current form started in the previous nonblank line
    if l == pnum
        " Found opening paren in the previous line
        let line = getline(l)
        let form = strpart( line, c )
        " Contract strings, remove comments
        let form = substitute( form, '".\{-}[^\\]"', '""', 'g' )
        let form = substitute( form, ';.*$', '', 'g' )
        " Contract subforms by replacing them with a single character
        let f = ''
        while form != f
            let f = form
            let form = substitute( form, '([^()]*)',     '0', 'g' )
            let form = substitute( form, '\[[^\[\]]*\]', '0', 'g' )
            let form = substitute( form, '{[^{}]*}',     '0', 'g' )
        endwhile
        " Find out the function name
        let func = matchstr( form, '\<\k*\>' )
        " If it's a keyword, keep the indentation straight
        if indent_keylists && strpart(func, 0, 1) == ':'
            if form =~ '^:\S*\s\+\S'
                " This keyword has an associated value in the same line
                return c
            else
                " The keyword stands alone in its line with no associated value
                return c + 1
            endif
        endif
        if SlimvGetFiletype() == 'clojure'
            " Fix clojure specific indentation issues not handled by the default lisp.vim
            if match( func, 'defn-\?$' ) >= 0 || match( func, 'fn$' ) >= 0
                return c + 1
            endif
        else
            if match( func, 'defgeneric$' ) >= 0 || match( func, 'defsystem$' ) >= 0 || match( func, 'aif$' ) >= 0
                return c + 1
            endif
        endif
        " Remove package specification
        let func = substitute(func, '^.*:', '', '')
        if func != '' && s:swank_connected
            " Look how many arguments are on the same line
            let form = substitute( form, "[()\\[\\]{}#'`,]", '', 'g' )
            let args_here = len( split( form ) ) - 1
            " Get swank indent info
            let s:indent = ''
            silent execute 'python get_indent_info("' . func . '")'
            if s:indent != '' && s:indent == args_here
                " The next one is an &body argument, so indent by 2 spaces from the opening '('
                return c + 1
            endif
        endif
    endif

    " Use default Lisp indening
    set lisp
    let li = lispindent(a:lnum)
    set nolisp
    let line = strpart( getline(a:lnum-1), li-1 )
    let gap = matchend( line, '^(\s\+\S' )
    if gap >= 0
        " Align to the gap between the opening paren and the first atom
        return li + gap - 2
    endif
    return li
endfunction 

" Send command line to REPL buffer
" Arguments: close = add missing closing parens
function! SlimvSendCommand( close )
    call SlimvRefreshModeOn()
    let lastline = b:repl_prompt_line
    let lastcol  = b:repl_prompt_col
    if lastline > 0
        if line( "." ) >= lastline
            " Trim the prompt from the beginning of the command line
            " The user might have overwritten some parts of the prompt
            let cmdline = getline( lastline )
            let c = 0
            while c < lastcol - 1 && cmdline[c] == b:repl_prompt[c]
                let c = c + 1
            endwhile
            let cmd = [ strpart( getline( lastline ), c ) ]

            " Build a possible multi-line command
            let l = lastline + 1
            while l <= line("$")
                call add( cmd, strpart( getline( l ), 0) )
                let l = l + 1
            endwhile

            " Count the number of opening and closing braces
            let end = s:CloseForm( cmd )
            if end == 'ERROR'
                " Too many closing parens
                call SlimvErrorWait( "Too many or invalid closing parens found." )
                return
            endif
            let echoing = 0
            if a:close && end != ''
                " Close form if necessary and evaluate it
                let cmd[len(cmd)-1] = cmd[len(cmd)-1] . end
                let end = ''
                let echoing = 1
            endif
            if end == ''
                " Expression finished, let's evaluate it
                " but first add it to the history
                call SlimvAddHistory( cmd )
                " Evaluate, but echo only when form is actually closed here
                call SlimvSend( cmd, echoing, 1 )
            else
                " Expression is not finished yet, indent properly and wait for completion
                " Indentation works only if lisp indentation is switched on
                let l = line('.') + 1
                call append( '.', '' )
                call setline( l, repeat( ' ', SlimvIndent(l) ) )
                normal! j$
            endif
        endif
    else
        call append( '$', "Slimv error: previous EOF mark not found, re-enter last form:" )
        call append( '$', "" )
        call SlimvMarkBufferEnd()
    endif
endfunction

" Close current top level form by adding the missing parens
function! SlimvCloseForm()
    let l2 = line( '.' )
    call SlimvFindDefunStart()
    let l1 = line( '.' )
    let form = []
    let l = l1
    while l <= l2
        call add( form, getline( l ) )
        let l = l + 1
    endwhile
    let end = s:CloseForm( form )
    if end == 'ERROR'
        " Too many closing parens
        call SlimvErrorWait( "Too many or invalid closing parens found." )
    elseif end != ''
        " Add missing parens
        if end[0] == "\n"
            call append( l2, end[1:] )
        else
            call setline( l2, getline( l2 ) . end )
        endif
    endif
    normal! %
endfunction

" Handle insert mode 'Backspace' keypress in the REPL buffer
function! SlimvHandleBS()
    if line( "." ) == b:repl_prompt_line && col( "." ) <= b:repl_prompt_col
        " No BS allowed before the previous EOF mark
        return ""
    else
        return "\<BS>"
    endif
endfunction

" Recall previous command from command history
function! s:PreviousCommand()
    if exists( 'g:slimv_cmdhistory' ) && g:slimv_cmdhistorypos > 0
        let g:slimv_cmdhistorypos = g:slimv_cmdhistorypos - 1
        call SlimvRecallHistory()
    endif
endfunction

" Recall next command from command history
function! s:NextCommand()
    if exists( 'g:slimv_cmdhistory' ) && g:slimv_cmdhistorypos < len( g:slimv_cmdhistory )
        let g:slimv_cmdhistorypos = g:slimv_cmdhistorypos + 1
        call SlimvRecallHistory()
    else
        call SlimvSetCommandLine( "" )
    endif
endfunction

" Handle insert mode 'Up' keypress in the REPL buffer
function! SlimvHandleUp()
    if line( "." ) >= b:repl_prompt_line
        if exists( 'g:slimv_cmdhistory' ) && g:slimv_cmdhistorypos == len( g:slimv_cmdhistory )
            call SlimvMarkBufferEnd()
            startinsert!
        endif
        call s:PreviousCommand()
    else
        normal! gk
    endif
endfunction

" Handle insert mode 'Down' keypress in the REPL buffer
function! SlimvHandleDown()
    if line( "." ) >= b:repl_prompt_line
        call s:NextCommand()
    else
        normal! gj
    endif
endfunction

" Make a fold at the cursor point in the current buffer
function SlimvMakeFold()
    setlocal noreadonly
    normal! o    }}}kA {{{0
    setlocal readonly
endfunction

" Handle normal mode 'Enter' keypress in the SLDB buffer
function! SlimvHandleEnterSldb()
    let line = getline('.')
    if s:sldb_level >= 0
        " Check if Enter was pressed in a section printed by the SWANK debugger
        " The source specification is within a fold, so it has to be tested first
        let mlist = matchlist( line, '^\s\+in "\(.*\)" \(line\|byte\) \(\d\+\)$' )
        if len(mlist)
            if g:slimv_repl_split
                " Switch back to other window
                execute "wincmd p"
            endif
            " Jump to the file at the specified position
            if mlist[2] == 'line'
                exec ":edit +" . mlist[3] . " " . mlist[1]
            else
                exec ":edit +" . mlist[3] . "go " . mlist[1]
            endif
            return
        endif
        if foldlevel('.')
            " With a fold just toggle visibility
            normal za
            return
        endif
        let item = matchstr( line, s:frame_def )
        if item != ''
            let item = substitute( item, '\s\|:', '', 'g' )
            if search( '^Backtrace:', 'bnW' ) > 0
                " Display item-th frame
                call SlimvMakeFold()
                silent execute 'python swank_frame_locals("' . item . '")'
                if g:slimv_impl != 'clisp'
                    " These are not implemented for CLISP
                    silent execute 'python swank_frame_source_loc("' . item . '")'
                    silent execute 'python swank_frame_call("' . item . '")'
                endif
                return
            endif
            if search( '^Restarts:', 'bnW' ) > 0
                " Apply item-th restart
                call SlimvQuitSldb()
                silent execute 'python swank_invoke_restart("' . s:sldb_level . '", "' . item . '")'
                return
            endif
        endif
    endif

    " No special treatment, perform the original function
    execute "normal! \<CR>"
endfunction

" Handle normal mode 'Enter' keypress in the Inspector buffer
function! SlimvHandleEnterInspect()
    let line = getline('.')
    if line[0:9] == 'Inspecting'
        " Reload inspected item
        call SlimvSendSilent( ['[0]'] )
        return
    endif

    if line[0] == '['
        if line =~ '^[--more--\]$'
            " More data follows, fetch next part
            call SlimvCommand( 'python swank_inspector_range()' )
            call SlimvRefreshReplBuffer()
            return
        elseif line[0:3] == '[<<]'
            " Pop back up in the inspector
            let item = '-1'
        else
            " Inspect n-th part
            let item = matchstr( line, '\d\+' )
        endif
        if item != ''
            call SlimvSendSilent( ['[' . item . ']'] )
            return
        endif
    endif

    if line[0] == '<'
        " Inspector n-th action
        let item = matchstr( line, '\d\+' )
        if item != ''
            call SlimvSendSilent( ['<' . item . '>'] )
            return
        endif
    endif

    " No special treatment, perform the original function
    execute "normal! \<CR>"
endfunction

" Go to command line and recall previous command from command history
function! SlimvPreviousCommand()
    call SlimvEndOfReplBuffer()
    if line( "." ) >= b:repl_prompt_line
        call s:PreviousCommand()
    endif
endfunction

" Go to command line and recall next command from command history
function! SlimvNextCommand()
    call SlimvEndOfReplBuffer()
    if line( "." ) >= b:repl_prompt_line
        call s:NextCommand()
    endif
endfunction

" Handle interrupt (Ctrl-C) keypress in the REPL buffer
function! SlimvInterrupt()
    call SlimvCommand( 'python swank_interrupt()' )
    call SlimvRefreshReplBuffer()
endfunction

" Select a specific restart in debugger
function! SlimvDebugCommand( cmd )
    if SlimvConnectSwank()
        if s:sldb_level >= 0
            if bufname('%') != g:slimv_sldb_name
                call SlimvOpenSldbBuffer()
            endif
            call SlimvQuitSldb()
            call SlimvCommand( 'python ' . a:cmd . '()' )
            call SlimvRefreshReplBuffer()
        else
            call SlimvError( "Debugger is not activated." )
        endif
    endif
endfunction

" List current Lisp threads
function! SlimvListThreads()
    if SlimvConnectSwank()
        call SlimvCommand( 'python swank_list_threads()' )
        call SlimvRefreshReplBuffer()
    endif
endfunction

" Kill thread(s) selected from the Thread List
function! SlimvKillThread() range
    if SlimvConnectSwank()
        if a:firstline == a:lastline
            let line = getline('.')
            let item = matchstr( line, '\d\+' )
            if bufname('%') != g:slimv_threads_name
                " We are not in the Threads buffer, not sure which thread to kill
                let item = input( 'Thread to kill: ', item )
            endif
            if item != ''
                call SlimvCommand( 'python swank_kill_thread(' . item . ')' )
                call SlimvRefreshReplBuffer()
            endif
            echomsg 'Thread ' . item . ' is killed.'
        else
            for line in getline(a:firstline, a:lastline)
                let item = matchstr( line, '\d\+' )
                if item != ''
                    call SlimvCommand( 'python swank_kill_thread(' . item . ')' )
                endif
            endfor
            call SlimvRefreshReplBuffer()
        endif
        call SlimvListThreads()
    endif
endfunction

" Debug thread selected from the Thread List
function! SlimvDebugThread()
    if SlimvConnectSwank()
        let line = getline('.')
        let item = matchstr( line, '\d\+' )
        let item = input( 'Thread to debug: ', item )
        if item != ''
            call SlimvCommand( 'python swank_debug_thread(' . item . ')' )
            call SlimvRefreshReplBuffer()
        endif
    endif
endfunction

" Display function argument list
function! SlimvArglist()
    let l = line('.')
    let c = col('.') - 1
    let line = getline('.')
    call s:SetKeyword()
    if s:swank_connected && c > 1 && line[c-2] =~ '\k'
        let save_ve = &virtualedit
        set virtualedit=onemore
        " Display only if entering the first space after a keyword
        let matchb = max( [l-100, 1] )
        let [l0, c0] = searchpairpos( '(', '', ')', 'nbW', s:skip_sc, matchb )
        if l0 > 0
            " Found opening paren, let's find out the function name
            let arg = matchstr( line, '\<\k*\>', c0 )
            if arg != ''
                " Ask function argument list from SWANK
                call SlimvFindPackage()
                let msg = SlimvCommandGetResponse( ':operator-arglist', 'python swank_op_arglist("' . arg . '")', 0 )
                if msg != ''
                    " Print argument list in status line with newlines removed.
                    " Disable showmode until the next ESC to prevent
                    " immeditate overwriting by the "-- INSERT --" text.
                    let s:save_showmode = &showmode
                    set noshowmode
                    let msg = substitute( msg, "\n", "", "g" )
                    redraw
                    if match( msg, arg ) != 1
                        " Function name is not received from REPL
                        call SlimvShortEcho( "(" . arg . ' ' . msg[1:] )
                    else
                        call SlimvShortEcho( msg )
                    endif
                endif
            endif
        endif
        let &virtualedit=save_ve
    endif

    " Return empty string because this function is called from an insert mode mapping
    return ''
endfunction

" Start and connect swank server
function! SlimvConnectServer()
    if s:swank_connected
        python swank_disconnect()
        let s:swank_connected = 0
    endif 
    call SlimvBeginUpdate()
    if SlimvConnectSwank()
        let repl_buf = bufnr( g:slimv_repl_name )
        let repl_win = bufwinnr( repl_buf )
        if repl_buf == -1 || ( g:slimv_repl_split && repl_win == -1 )
            call SlimvOpenReplBuffer()
        endif
    endif
endfunction

" Get the last region (visual block)
function! SlimvGetRegion(first, last)
    let oldpos = winsaveview()
    if a:first < a:last || ( a:first == line( "'<" ) && a:last == line( "'>" ) )
        let lines = getline( a:first, a:last )
    else
        " No range was selected, select current paragraph
        normal! vap
        execute "normal! \<Esc>"
        call winrestview( oldpos ) 
        let lines = getline( "'<", "'>" )
        if lines == [] || lines == ['']
            call SlimvError( "No range selected." )
            return []
        endif
    endif
    let firstcol = col( "'<" ) - 1
    let lastcol  = col( "'>" ) - 2
    if lastcol >= 0
        let lines[len(lines)-1] = lines[len(lines)-1][ : lastcol]
    else
        let lines[len(lines)-1] = ''
    endif
    let lines[0] = lines[0][firstcol : ]

    " Find and set package/namespace definition preceding the region
    call SlimvFindPackage()
    call winrestview( oldpos ) 
    return lines
endfunction

" Eval buffer lines in the given range
function! SlimvEvalRegion() range
    if v:register == '"'
        let lines = SlimvGetRegion(a:firstline, a:lastline)
    else
        " Register was passed, so eval register contents instead
        let reg = getreg( v:register )
        let ending = s:CloseForm( [reg] )
        if ending == 'ERROR'
            call SlimvError( 'Too many or invalid closing parens in register "' . v:register )
            return
        endif
        let lines = [reg . ending]
    endif
    if lines != []
        call SlimvEval( lines )
    endif
endfunction

" Eval contents of the 's' register, optionally store it in another register
" Also optionally add a test form for quick testing (not stored in 'outreg')
function! SlimvEvalSelection( outreg, testform )
    let sel = SlimvGetSelection()
    if a:outreg != '"'
        " Register was passed, so store current selection in register
        call setreg( a:outreg, sel )
    endif
    let lines = [sel]
    if a:testform != ''
        " Append optional test form at the tail
        let lines = lines + [a:testform]
    endif
    if bufnr( "%" ) == bufnr( g:slimv_repl_name )
        " If this is the REPL buffer then go to EOF
        normal! G$
    endif
    call SlimvEval( lines )
endfunction

" Eval Lisp form.
" Form given in the template is passed to Lisp without modification.
function! SlimvEvalForm( template )
    let lines = [a:template]
    call SlimvEval( lines )
endfunction

" Eval Lisp form, with the given parameter substituted in the template.
" %1 string is substituted with par1
function! SlimvEvalForm1( template, par1 )
    let p1 = escape( a:par1, '&' )
    let temp1 = substitute( a:template, '%1', p1, 'g' )
    let lines = [temp1]
    call SlimvEval( lines )
endfunction

" Eval Lisp form, with the given parameters substituted in the template.
" %1 string is substituted with par1
" %2 string is substituted with par2
function! SlimvEvalForm2( template, par1, par2 )
    let p1 = escape( a:par1, '&' )
    let p2 = escape( a:par2, '&' )
    let temp1 = substitute( a:template, '%1', p1, 'g' )
    let temp2 = substitute( temp1,      '%2', p2, 'g' )
    let lines = [temp2]
    call SlimvEval( lines )
endfunction


" =====================================================================
"  Special functions
" =====================================================================

" Evaluate and test top level form at the cursor pos
function! SlimvEvalTestDefun( testform )
    let outreg = v:register
    let oldpos = winsaveview()
    if !SlimvSelectDefun()
        return
    endif
    call SlimvFindPackage()
    call winrestview( oldpos ) 
    call SlimvEvalSelection( outreg, a:testform )
endfunction

" Evaluate top level form at the cursor pos
function! SlimvEvalDefun()
    call SlimvEvalTestDefun( '' )
endfunction

" Evaluate the whole buffer
function! SlimvEvalBuffer()
    let lines = getline( 1, '$' )
    call SlimvEval( lines )
endfunction

" Return frame number if we are in the Backtrace section of the debugger
function! s:DebugFrame()
    if s:swank_connected && s:sldb_level >= 0
        " Check if we are in SLDB
        let repl_buf = bufnr( g:slimv_sldb_name )
        if repl_buf != -1 && repl_buf == bufnr( "%" )
            let bcktrpos = search( '^Backtrace:', 'bcnw' )
            let framepos = line( '.' )
            if matchstr( getline('.'), s:frame_def ) == ''
                let framepos = search( s:frame_def, 'bcnw' )
            endif
            if framepos > 0 && bcktrpos > 0 && framepos > bcktrpos
                let line = getline( framepos )
                let item = matchstr( line, s:frame_def )
                if item != ''
                    return substitute( item, '\s\|:', '', 'g' )
                endif
            endif
        endif
    endif
    return ''
endfunction

" Evaluate and test current s-expression at the cursor pos
function! SlimvEvalTestExp( testform )
    let outreg = v:register
    let oldpos = winsaveview()
    if !SlimvSelectForm()
        return
    endif
    call SlimvFindPackage()
    call winrestview( oldpos ) 
    call SlimvEvalSelection( outreg, a:testform )
endfunction

" Evaluate current s-expression at the cursor pos
function! SlimvEvalExp()
    call SlimvEvalTestExp( '' )
endfunction

" Evaluate expression entered interactively
function! SlimvInteractiveEval()
    let frame = s:DebugFrame()
    if frame != ''
        " We are in the debugger, eval expression in the frame the cursor stands on
        let e = input( 'Eval in frame ' . frame . ': ' )
        if e != ''
            let result = SlimvCommandGetResponse( ':eval-string-in-frame', 'python swank_eval_in_frame("' . e . '", ' . frame . ')', 0 )
            if result != ''
                redraw
                echo result
            endif
        endif
    else
        let e = input( 'Eval: ' )
        if e != ''
            call SlimvEval([e])
        endif
    endif
endfunction

" Undefine function
function! SlimvUndefineFunction()
    if s:swank_connected
        call SlimvCommand( 'python swank_undefine_function("' . SlimvSelectSymbol() . '")' )
        call SlimvRefreshReplBuffer()
    endif
endfunction

" ---------------------------------------------------------------------

" Macroexpand-1 the current top level form
function! SlimvMacroexpand()
    call SlimvBeginUpdate()
    if SlimvConnectSwank()
        if !SlimvSelectForm()
            return
        endif
        let s:swank_form = SlimvGetSelection()
        if bufnr( "%" ) == bufnr( g:slimv_repl_name )
            " If this is the REPL buffer then go to EOF
            normal! G$
        endif
        call SlimvCommandUsePackage( 'python swank_macroexpand("s:swank_form")' )
    endif
endfunction

" Macroexpand the current top level form
function! SlimvMacroexpandAll()
    call SlimvBeginUpdate()
    if SlimvConnectSwank()
        if !SlimvSelectForm()
            return
        endif
        let s:swank_form = SlimvGetSelection()
        if bufnr( "%" ) == bufnr( g:slimv_repl_name )
            " If this is the REPL buffer then go to EOF
            normal! G$
        endif
        call SlimvCommandUsePackage( 'python swank_macroexpand_all("s:swank_form")' )
    endif
endfunction

" Set a breakpoint on the beginning of a function
function! SlimvBreak()
    if SlimvConnectSwank()
        let s = input( 'Set breakpoint: ', SlimvSelectSymbol() )
        if s != ''
            call SlimvCommandUsePackage( 'python swank_set_break("' . s . '")' )
            redraw!
        endif
    endif
endfunction

" Switch trace on for the selected function (toggle for swank)
function! SlimvTrace()
    if SlimvGetFiletype() == 'scheme'
        call SlimvError( "Tracing is not supported by swank-scheme." )
        return
    endif
    if SlimvConnectSwank()
        let s = input( '(Un)trace: ', SlimvSelectSymbol() )
        if s != ''
            call SlimvCommandUsePackage( 'python swank_toggle_trace("' . s . '")' )
            redraw!
        endif
    endif
endfunction

" Switch trace off for the selected function (or all functions for swank)
function! SlimvUntrace()
    if SlimvGetFiletype() == 'scheme'
        call SlimvError( "Tracing is not supported by swank-scheme." )
        return
    endif
    if SlimvConnectSwank()
        let s:refresh_disabled = 1
        call SlimvCommand( 'python swank_untrace_all()' )
        let s:refresh_disabled = 0
        call SlimvRefreshReplBuffer()
    endif
endfunction

" Disassemble the selected function
function! SlimvDisassemble()
    if SlimvConnectSwank()
        let s = input( 'Disassemble: ', SlimvSelectSymbol() )
        if s != ''
            call SlimvCommandUsePackage( 'python swank_disassemble("' . s . '")' )
        endif
    endif
endfunction

" Inspect symbol under cursor
function! SlimvInspect()
    if !SlimvConnectSwank()
        return
    endif
    let frame = s:DebugFrame()
    if frame != ''
        " Inspect selected for a frame in the debugger's Backtrace section
        let line = getline( '.' )
        if matchstr( line, s:frame_def ) != ''
            " This is the base frame line in form '  1: xxxxx'
            let sym = ''
        elseif matchstr( line, '^\s\+in "\(.*\)" \(line\|byte\)' ) != ''
            " This is the source location line
            let sym = ''
        elseif matchstr( line, '^\s\+No source line information' ) != ''
            " This is the no source location line
            let sym = ''
        elseif matchstr( line, '^\s\+Locals:' ) != ''
            " This is the 'Locals' line
            let sym = ''
        else
            let sym = SlimvSelectSymbolExt()
        endif
        let s = input( 'Inspect in frame ' . frame . ' (evaluated): ', sym )
        if s != ''
            call SlimvBeginUpdate()
            call SlimvCommand( 'python swank_inspect_in_frame("' . s . '", ' . frame . ')' )
            call SlimvRefreshReplBuffer()
        endif
    else
        let s = input( 'Inspect: ', SlimvSelectSymbolExt() )
        if s != ''
            call SlimvBeginUpdate()
            call SlimvCommandUsePackage( 'python swank_inspect("' . s . '")' )
        endif
    endif
endfunction

" Cross reference: who calls
function! SlimvXrefBase( text, cmd )
    if SlimvConnectSwank()
        let s = input( a:text, SlimvSelectSymbol() )
        if s != ''
            call SlimvCommandUsePackage( 'python swank_xref("' . s . '", "' . a:cmd . '")' )
        endif
    endif
endfunction

" Cross reference: who calls
function! SlimvXrefCalls()
    call SlimvXrefBase( 'Who calls: ', ':calls' )
endfunction

" Cross reference: who references
function! SlimvXrefReferences()
    call SlimvXrefBase( 'Who references: ', ':references' )
endfunction

" Cross reference: who sets
function! SlimvXrefSets()
    call SlimvXrefBase( 'Who sets: ', ':sets' )
endfunction

" Cross reference: who binds
function! SlimvXrefBinds()
    call SlimvXrefBase( 'Who binds: ', ':binds' )
endfunction

" Cross reference: who macroexpands
function! SlimvXrefMacroexpands()
    call SlimvXrefBase( 'Who macroexpands: ', ':macroexpands' )
endfunction

" Cross reference: who specializes
function! SlimvXrefSpecializes()
    call SlimvXrefBase( 'Who specializes: ', ':specializes' )
endfunction

" Cross reference: list callers
function! SlimvXrefCallers()
    call SlimvXrefBase( 'List callers: ', ':callers' )
endfunction

" Cross reference: list callees
function! SlimvXrefCallees()
    call SlimvXrefBase( 'List callees: ', ':callees' )
endfunction

" ---------------------------------------------------------------------

" Switch or toggle profiling on for the selected function
function! SlimvProfile()
    if SlimvConnectSwank()
        let s = input( '(Un)profile: ', SlimvSelectSymbol() )
        if s != ''
            call SlimvCommandUsePackage( 'python swank_toggle_profile("' . s . '")' )
            redraw!
        endif
    endif
endfunction

" Switch profiling on based on substring
function! SlimvProfileSubstring()
    if SlimvConnectSwank()
        let s = input( 'Profile by matching substring: ', SlimvSelectSymbol() )
        if s != ''
            let p = input( 'Package (RET for all packages): ' )
            call SlimvCommandUsePackage( 'python swank_profile_substring("' . s . '","' . p . '")' )
            redraw!
        endif
    endif
endfunction

" Switch profiling completely off
function! SlimvUnprofileAll()
    if SlimvConnectSwank()
        call SlimvCommandUsePackage( 'python swank_unprofile_all()' )
    endif
endfunction

" Display list of profiled functions
function! SlimvShowProfiled()
    if SlimvConnectSwank()
        call SlimvCommandUsePackage( 'python swank_profiled_functions()' )
    endif
endfunction

" Report profiling results
function! SlimvProfileReport()
    if SlimvConnectSwank()
        call SlimvCommandUsePackage( 'python swank_profile_report()' )
    endif
endfunction

" Reset profiling counters
function! SlimvProfileReset()
    if SlimvConnectSwank()
        call SlimvCommandUsePackage( 'python swank_profile_reset()' )
    endif
endfunction

" ---------------------------------------------------------------------

" Compile the current top-level form
function! SlimvCompileDefun()
    let oldpos = winsaveview()
    if !SlimvSelectDefun()
        call winrestview( oldpos ) 
        return
    endif
    if SlimvConnectSwank()
        let s:swank_form = SlimvGetSelection()
        call SlimvCommandUsePackage( 'python swank_compile_string("s:swank_form")' )
    endif
endfunction

" Compile and load whole file
function! SlimvCompileLoadFile()
    let filename = fnamemodify( bufname(''), ':p' )
    let filename = substitute( filename, '\\', '/', 'g' )
    if &modified
        let answer = SlimvErrorAsk( '', "Save file before compiling [Y/n]?" )
        if answer[0] != 'n' && answer[0] != 'N'
            write
        endif
    endif
    if SlimvConnectSwank()
        let s:compiled_file = ''
        call SlimvCommandUsePackage( 'python swank_compile_file("' . filename . '")' )
        let starttime = localtime()
        while s:compiled_file == '' && localtime()-starttime < g:slimv_timeout
            call SlimvSwankResponse()
        endwhile
        if s:compiled_file != ''
            call SlimvCommandUsePackage( 'python swank_load_file("' . s:compiled_file . '")' )
            let s:compiled_file = ''
        endif
    endif
endfunction

" Compile whole file
function! SlimvCompileFile()
    let filename = fnamemodify( bufname(''), ':p' )
    let filename = substitute( filename, '\\', '/', 'g' )
    if &modified
        let answer = SlimvErrorAsk( '', "Save file before compiling [Y/n]?" )
        if answer[0] != 'n' && answer[0] != 'N'
            write
        endif
    endif
    if SlimvConnectSwank()
        call SlimvCommandUsePackage( 'python swank_compile_file("' . filename . '")' )
    endif
endfunction

" Compile buffer lines in the given range
function! SlimvCompileRegion() range
    if v:register == '"'
        let lines = SlimvGetRegion(a:firstline, a:lastline)
    else
        " Register was passed, so compile register contents instead
        let reg = getreg( v:register )
        let ending = s:CloseForm( [reg] )
        if ending == 'ERROR'
            call SlimvError( 'Too many or invalid closing parens in register "' . v:register )
            return
        endif
        let lines = [reg . ending]
    endif
    if lines == []
        return
    endif
    let region = join( lines, "\n" )
    if SlimvConnectSwank()
        let s:swank_form = region
        call SlimvCommandUsePackage( 'python swank_compile_string("s:swank_form")' )
    endif
endfunction

" ---------------------------------------------------------------------

" Describe the selected symbol
function! SlimvDescribeSymbol()
    if SlimvConnectSwank()
        call SlimvCommandUsePackage( 'python swank_describe_symbol("' . SlimvSelectSymbol() . '")' )
    endif
endfunction

" Display symbol description in balloonexpr
function! SlimvDescribe(arg)
    let arg=a:arg
    if a:arg == ''
        let arg = expand('<cword>')
    endif
    " We don't want to try connecting here ... the error message would just 
    " confuse the balloon logic
    if !s:swank_connected
        return ''
    endif
    call SlimvFindPackage()
    let arglist = SlimvCommandGetResponse( ':operator-arglist', 'python swank_op_arglist("' . arg . '")', 0 )
    if arglist == ''
        " Not able to fetch arglist, assuming function is not defined
        " Skip calling describe, otherwise SWANK goes into the debugger
        return ''
    endif
    let msg = SlimvCommandGetResponse( ':describe-function', 'python swank_describe_function("' . arg . '")', 0 )
    if msg == ''
        " No describe info, display arglist
        if match( arglist, arg ) != 1
            " Function name is not received from REPL
            return "(" . arg . ' ' . arglist[1:]
        else
            return arglist
        endif
    else
        return substitute(msg,'^\n*','','')
    endif
endfunction

" Apropos of the selected symbol
function! SlimvApropos()
    call SlimvEvalForm1( g:slimv_template_apropos, SlimvSelectSymbol() )
endfunction

" Generate tags file using ctags
function! SlimvGenerateTags()
    if exists( 'g:slimv_ctags' ) && g:slimv_ctags != ''
        execute 'silent !' . g:slimv_ctags
    else
        call SlimvError( "Copy ctags to the Vim path or define g:slimv_ctags." )
    endif
endfunction

" ---------------------------------------------------------------------

" Find word in the CLHS symbol database, with exact or partial match.
" Return either the first symbol found with the associated URL,
" or the list of all symbols found without the associated URL.
function! SlimvFindSymbol( word, exact, all, db, root, init )
    if a:word == ''
        return []
    endif
    if !a:all && a:init != []
        " Found something already at a previous db lookup, no need to search this db
        return a:init
    endif
    let lst = a:init
    let i = 0
    let w = tolower( a:word )
    if a:exact
        while i < len( a:db )
            " Try to find an exact match
            if a:db[i][0] == w
                " No reason to check a:all here
                return [a:db[i][0], a:root . a:db[i][1]]
            endif
            let i = i + 1
        endwhile
    else
        while i < len( a:db )
            " Try to find the symbol starting with the given word
            let w2 = escape( w, '~' )
            if match( a:db[i][0], w2 ) == 0
                if a:all
                    call add( lst, a:db[i][0] )
                else
                    return [a:db[i][0], a:root . a:db[i][1]]
                endif
            endif
            let i = i + 1
        endwhile
    endif

    " Return whatever found so far
    return lst
endfunction

" Lookup word in Common Lisp Hyperspec
function! SlimvLookup( word )
    " First try an exact match
    let w = a:word
    let symbol = []
    while symbol == []
        let symbol = b:SlimvHyperspecLookup( w, 1, 0 )
        if symbol == []
            " Symbol not found, try a match on beginning of symbol name
            let symbol = b:SlimvHyperspecLookup( w, 0, 0 )
            if symbol == []
                " We are out of luck, can't find anything
                let msg = 'Symbol ' . w . ' not found. Hyperspec lookup word: '
                let val = ''
            else
                let msg = 'Hyperspec lookup word: '
                let val = symbol[0]
            endif
            " Ask user if this is that he/she meant
            let w = input( msg, val )
            if w == ''
                " OK, user does not want to continue
                return
            endif
            let symbol = []
        endif
    endwhile
    if symbol != []
        " Symbol found, open HS page in browser
        if match( symbol[1], ':' ) < 0 && exists( g:slimv_hs_root )
            let page = g:slimv_hs_root . symbol[1]
        else
            " URL is already a fully qualified address
            let page = symbol[1]
        endif
        if exists( "g:slimv_browser_cmd" )
            " We have an given command to start the browser
            if !exists( "g:slimv_browser_cmd_suffix" )
                " Fork the browser by default
                let g:slimv_browser_cmd_suffix = '&'
            endif
            silent execute '! ' . g:slimv_browser_cmd . ' ' . page . ' ' . g:slimv_browser_cmd_suffix
        else
            if g:slimv_windows
                " Run the program associated with the .html extension
                silent execute '! start ' . page
            else
                " On Linux it's not easy to determine the default browser
                if executable( 'xdg-open' )
                    silent execute '! xdg-open ' . page . ' &'
                else
                    " xdg-open not installed, ask help from Python webbrowser package
                    let pycmd = "import webbrowser; webbrowser.open('" . page . "')"
                    silent execute '! python -c "' . pycmd . '"'
                endif
            endif
        endif
        " This is needed especially when using text browsers
        redraw!
    endif
endfunction

" Lookup current symbol in the Common Lisp Hyperspec
function! SlimvHyperspec()
    call SlimvLookup( SlimvSelectSymbol() )
endfunction

" Complete symbol name starting with 'base'
function! SlimvComplete( base )
    " Find all symbols starting with "a:base"
    if a:base == ''
        return []
    endif
    if s:swank_connected
        call SlimvFindPackage()
        if g:slimv_simple_compl
            let msg = SlimvCommandGetResponse( ':simple-completions', 'python swank_completions("' . a:base . '")', 0 )
        else
            let msg = SlimvCommandGetResponse( ':fuzzy-completions', 'python swank_fuzzy_completions("' . a:base . '")', 0 )
        endif
        if msg != ''
            " We have a completion list from SWANK
            let res = split( msg, '\n' )
            return res
        endif
    endif

    " No completion yet, try to fetch it from the Hyperspec database
    let res = []
    let symbol = b:SlimvHyperspecLookup( a:base, 0, 1 )
    if symbol == []
        return []
    endif
    call sort( symbol )
    for m in symbol
        if m =~ '^' . a:base
            call add( res, m )
        endif
    endfor
    return res
endfunction

" Complete function that uses the Hyperspec database
function! SlimvOmniComplete( findstart, base )
    if a:findstart
        " Locate the start of the symbol name
        call s:SetKeyword()
        let upto = strpart( getline( '.' ), 0, col( '.' ) - 1)
        let p = match(upto, '\(\k\|\.\)\+$')
        return p 
    else
        return SlimvComplete( a:base )
    endif
endfunction

" Define complete function only if none is defined yet
if &omnifunc == ''
    set omnifunc=SlimvOmniComplete
endif

" Complete function for user-defined commands
function! SlimvCommandComplete( arglead, cmdline, cursorpos )
    " Locate the start of the symbol name
    call s:SetKeyword()
    let upto = strpart( a:cmdline, 0, a:cursorpos )
    let base = matchstr(upto, '\k\+$')
    let ext  = matchstr(upto, '\S*\k\+$')
    let compl = SlimvComplete( base )
    if len(compl) > 0 && base != ext
        " Command completion replaces whole word between spaces, so we
        " need to add any prefix present in front of the keyword, like '('
        let prefix = strpart( ext, 0, len(ext) - len(base) )
        let i = 0
        while i < len(compl)
            let compl[i] = prefix . compl[i]
            let i = i + 1
        endwhile
    endif
    return compl
endfunction

" Set current package
function! SlimvSetPackage()
    if SlimvConnectSwank()
        call SlimvFindPackage()
        let pkg = input( 'Package: ', s:swank_package )
        if pkg != ''
            let s:refresh_disabled = 1
            call SlimvCommand( 'python swank_set_package("' . pkg . '")' )
            let s:refresh_disabled = 0
            call SlimvRefreshReplBuffer()
        endif
    endif
endfunction

" =====================================================================
"  Slimv keybindings
" =====================================================================

" <Leader> timeouts in 1000 msec by default, if this is too short,
" then increase 'timeoutlen'

" Map keyboard keyset dependant shortcut to command and also add it to menu
function! s:MenuMap( name, shortcut1, shortcut2, command )
    if g:slimv_keybindings == 1
        " Short (one-key) keybinding set
        let shortcut = a:shortcut1
    elseif g:slimv_keybindings == 2
        " Easy to remember (two-key) keybinding set
        let shortcut = a:shortcut2
    endif

    if shortcut != ''
        execute "noremap <silent> " . shortcut . " " . a:command
        if a:name != '' && g:slimv_menu == 1
            silent execute "amenu " . a:name . "<Tab>" . shortcut . " " . a:command
        endif
    elseif a:name != '' && g:slimv_menu == 1
        silent execute "amenu " . a:name . " " . a:command
    endif
endfunction

" Initialize buffer by adding buffer specific mappings
function! SlimvInitBuffer()
    " Map space to display function argument list in status line
    inoremap <silent> <buffer> <Space>    <Space><C-R>=SlimvArglist()<CR>
    "noremap  <silent> <buffer> <C-C>      :call SlimvInterrupt()<CR>
    au InsertLeave * :let &showmode=s:save_showmode
    inoremap <silent> <buffer> <C-X>0     <C-O>:call SlimvCloseForm()<CR>
    inoremap <silent> <buffer> <Tab>      <C-R>=pumvisible() ? "\<lt>C-N>" : "\<lt>C-X>\<lt>C-O>"<CR>

    " Setup balloonexp to display symbol description
    if g:slimv_balloon && has( 'balloon_eval' )
        "setlocal balloondelay=100
        setlocal ballooneval
        setlocal balloonexpr=SlimvDescribe(v:beval_text)
    endif
    " This is needed for safe switching of modified buffers
    set hidden
endfunction

" Edit commands
call s:MenuMap( 'Slim&v.Edi&t.Close-&Form',                     g:slimv_leader.')',  g:slimv_leader.'tc',  ':<C-U>call SlimvCloseForm()<CR>' )
call s:MenuMap( 'Slim&v.Edi&t.&Complete-Symbol<Tab>Tab',        '',                  '',                   '<Ins><C-X><C-O>' )
call s:MenuMap( 'Slim&v.Edi&t.&Paredit-Toggle',                 g:slimv_leader.'(',  g:slimv_leader.'(t',  ':<C-U>call PareditToggle()<CR>' )

" Evaluation commands
call s:MenuMap( 'Slim&v.&Evaluation.Eval-&Defun',               g:slimv_leader.'d',  g:slimv_leader.'ed',  ':<C-U>call SlimvEvalDefun()<CR>' )
call s:MenuMap( 'Slim&v.&Evaluation.Eval-Current-&Exp',         g:slimv_leader.'e',  g:slimv_leader.'ee',  ':<C-U>call SlimvEvalExp()<CR>' )
call s:MenuMap( 'Slim&v.&Evaluation.Eval-&Region',              g:slimv_leader.'r',  g:slimv_leader.'er',  ':call SlimvEvalRegion()<CR>' )
call s:MenuMap( 'Slim&v.&Evaluation.Eval-&Buffer',              g:slimv_leader.'b',  g:slimv_leader.'eb',  ':<C-U>call SlimvEvalBuffer()<CR>' )
call s:MenuMap( 'Slim&v.&Evaluation.Interacti&ve-Eval\.\.\.',   g:slimv_leader.'v',  g:slimv_leader.'ei',  ':call SlimvInteractiveEval()<CR>' )
call s:MenuMap( 'Slim&v.&Evaluation.&Undefine-Function',        g:slimv_leader.'u',  g:slimv_leader.'eu',  ':call SlimvUndefineFunction()<CR>' )

" Debug commands
call s:MenuMap( 'Slim&v.De&bugging.Macroexpand-&1',             g:slimv_leader.'1',  g:slimv_leader.'m1',  ':<C-U>call SlimvMacroexpand()<CR>' )
call s:MenuMap( 'Slim&v.De&bugging.&Macroexpand-All',           g:slimv_leader.'m',  g:slimv_leader.'ma',  ':<C-U>call SlimvMacroexpandAll()<CR>' )
call s:MenuMap( 'Slim&v.De&bugging.Toggle-&Trace\.\.\.',        g:slimv_leader.'t',  g:slimv_leader.'dt',  ':call SlimvTrace()<CR>' )
call s:MenuMap( 'Slim&v.De&bugging.U&ntrace-All',               g:slimv_leader.'T',  g:slimv_leader.'du',  ':call SlimvUntrace()<CR>' )
call s:MenuMap( 'Slim&v.De&bugging.Set-&Breakpoint',            g:slimv_leader.'B',  g:slimv_leader.'db',  ':call SlimvBreak()<CR>' )
call s:MenuMap( 'Slim&v.De&bugging.Disassemb&le\.\.\.',         g:slimv_leader.'l',  g:slimv_leader.'dd',  ':call SlimvDisassemble()<CR>' )
call s:MenuMap( 'Slim&v.De&bugging.&Inspect\.\.\.',             g:slimv_leader.'i',  g:slimv_leader.'di',  ':call SlimvInspect()<CR>' )
call s:MenuMap( 'Slim&v.De&bugging.-SldbSep-',                  '',                  '',                   ':' )
call s:MenuMap( 'Slim&v.De&bugging.&Abort',                     g:slimv_leader.'a',  g:slimv_leader.'da',  ':call SlimvDebugCommand("swank_invoke_abort")<CR>' )
call s:MenuMap( 'Slim&v.De&bugging.&Quit-to-Toplevel',          g:slimv_leader.'q',  g:slimv_leader.'dq',  ':call SlimvDebugCommand("swank_throw_toplevel")<CR>' )
call s:MenuMap( 'Slim&v.De&bugging.&Continue',                  g:slimv_leader.'n',  g:slimv_leader.'dc',  ':call SlimvDebugCommand("swank_invoke_continue")<CR>' )
call s:MenuMap( 'Slim&v.De&bugging.-ThreadSep-',                '',                  '',                   ':' )
call s:MenuMap( 'Slim&v.De&bugging.List-T&hreads',              g:slimv_leader.'H',  g:slimv_leader.'dl',  ':call SlimvListThreads()<CR>' )
call s:MenuMap( 'Slim&v.De&bugging.&Kill-Thread\.\.\.',         g:slimv_leader.'K',  g:slimv_leader.'dk',  ':call SlimvKillThread()<CR>' )
call s:MenuMap( 'Slim&v.De&bugging.&Debug-Thread\.\.\.',        g:slimv_leader.'G',  g:slimv_leader.'dT',  ':call SlimvDebugThread()<CR>' )


" Compile commands
call s:MenuMap( 'Slim&v.&Compilation.Compile-&Defun',           g:slimv_leader.'D',  g:slimv_leader.'cd',  ':<C-U>call SlimvCompileDefun()<CR>' )
call s:MenuMap( 'Slim&v.&Compilation.Compile-&Load-File',       g:slimv_leader.'L',  g:slimv_leader.'cl',  ':<C-U>call SlimvCompileLoadFile()<CR>' )
call s:MenuMap( 'Slim&v.&Compilation.Compile-&File',            g:slimv_leader.'F',  g:slimv_leader.'cf',  ':<C-U>call SlimvCompileFile()<CR>' )
call s:MenuMap( 'Slim&v.&Compilation.Compile-&Region',          g:slimv_leader.'R',  g:slimv_leader.'cr',  ':call SlimvCompileRegion()<CR>' )

" Xref commands
call s:MenuMap( 'Slim&v.&Xref.Who-&Calls',                      g:slimv_leader.'xc', g:slimv_leader.'xc',  ':call SlimvXrefCalls()<CR>' )
call s:MenuMap( 'Slim&v.&Xref.Who-&References',                 g:slimv_leader.'xr', g:slimv_leader.'xr',  ':call SlimvXrefReferences()<CR>' )
call s:MenuMap( 'Slim&v.&Xref.Who-&Sets',                       g:slimv_leader.'xs', g:slimv_leader.'xs',  ':call SlimvXrefSets()<CR>' )
call s:MenuMap( 'Slim&v.&Xref.Who-&Binds',                      g:slimv_leader.'xb', g:slimv_leader.'xb',  ':call SlimvXrefBinds()<CR>' )
call s:MenuMap( 'Slim&v.&Xref.Who-&Macroexpands',               g:slimv_leader.'xm', g:slimv_leader.'xm',  ':call SlimvXrefMacroexpands()<CR>' )
call s:MenuMap( 'Slim&v.&Xref.Who-S&pecializes',                g:slimv_leader.'xp', g:slimv_leader.'xp',  ':call SlimvXrefSpecializes()<CR>' )
call s:MenuMap( 'Slim&v.&Xref.&List-Callers',                   g:slimv_leader.'xl', g:slimv_leader.'xl',  ':call SlimvXrefCallers()<CR>' )
call s:MenuMap( 'Slim&v.&Xref.List-Call&ees',                   g:slimv_leader.'xe', g:slimv_leader.'xe',  ':call SlimvXrefCallees()<CR>' )

" Profile commands
call s:MenuMap( 'Slim&v.&Profiling.Toggle-&Profile\.\.\.',      g:slimv_leader.'p',  g:slimv_leader.'pp',  ':<C-U>call SlimvProfile()<CR>' )
call s:MenuMap( 'Slim&v.&Profiling.Profile-&By-Substring\.\.\.',g:slimv_leader.'P',  g:slimv_leader.'pb',  ':<C-U>call SlimvProfileSubstring()<CR>' )
call s:MenuMap( 'Slim&v.&Profiling.Unprofile-&All',             g:slimv_leader.'U',  g:slimv_leader.'pa',  ':<C-U>call SlimvUnprofileAll()<CR>' )
call s:MenuMap( 'Slim&v.&Profiling.&Show-Profiled',             g:slimv_leader.'?',  g:slimv_leader.'ps',  ':<C-U>call SlimvShowProfiled()<CR>' )
call s:MenuMap( 'Slim&v.&Profiling.-ProfilingSep-',             '',                  '',                   ':' )
call s:MenuMap( 'Slim&v.&Profiling.Profile-Rep&ort',            g:slimv_leader.'o',  g:slimv_leader.'pr',  ':<C-U>call SlimvProfileReport()<CR>' )
call s:MenuMap( 'Slim&v.&Profiling.Profile-&Reset',             g:slimv_leader.'X',  g:slimv_leader.'px',  ':<C-U>call SlimvProfileReset()<CR>' )

" Documentation commands
call s:MenuMap( 'Slim&v.&Documentation.Describe-&Symbol',       g:slimv_leader.'s',  g:slimv_leader.'ds',  ':call SlimvDescribeSymbol()<CR>' )
call s:MenuMap( 'Slim&v.&Documentation.&Apropos',               g:slimv_leader.'A',  g:slimv_leader.'dp',  ':call SlimvApropos()<CR>' )
call s:MenuMap( 'Slim&v.&Documentation.&Hyperspec',             g:slimv_leader.'h',  g:slimv_leader.'dh',  ':call SlimvHyperspec()<CR>' )
call s:MenuMap( 'Slim&v.&Documentation.Generate-&Tags',         g:slimv_leader.']',  g:slimv_leader.'dg',  ':call SlimvGenerateTags()<CR>' )

" REPL commands
call s:MenuMap( 'Slim&v.&Repl.&Connect-Server',                 g:slimv_leader.'c',  g:slimv_leader.'rc',  ':call SlimvConnectServer()<CR>' )
call s:MenuMap( '',                                             g:slimv_leader.'g',  g:slimv_leader.'rp',  ':call SlimvSetPackage()<CR>' )
call s:MenuMap( 'Slim&v.&Repl.Interrup&t-Lisp-Process',         g:slimv_leader.'y',  g:slimv_leader.'ri',  ':call SlimvInterrupt()<CR>' )


" =====================================================================
"  Slimv menu
" =====================================================================

if g:slimv_menu == 1
    " Works only if 'wildcharm' is <Tab>
    if &wildcharm == 0
        set wildcharm=<Tab>
    endif
    if &wildcharm != 0
        execute ':map ' . g:slimv_leader.', :emenu Slimv.' . nr2char( &wildcharm )
    endif
endif

" Add REPL menu. This menu exist only for the REPL buffer.
function! SlimvAddReplMenu()
    if &wildcharm != 0
        execute ':map ' . g:slimv_leader.'\ :emenu REPL.' . nr2char( &wildcharm )
    endif

    amenu &REPL.Send-&Input                            :call SlimvSendCommand(0)<CR>
    amenu &REPL.Cl&ose-Send-Input                      :call SlimvSendCommand(1)<CR>
    amenu &REPL.Set-Packa&ge                           :call SlimvSetPackage()<CR>
    amenu &REPL.Interrup&t-Lisp-Process                <Esc>:<C-U>call SlimvInterrupt()<CR>
    amenu &REPL.-REPLSep-                              :
    amenu &REPL.&Previous-Input                        :call SlimvPreviousCommand()<CR>
    amenu &REPL.&Next-Input                            :call SlimvNextCommand()<CR>
endfunction

" =====================================================================
"  Slimv commands
" =====================================================================

command! -complete=customlist,SlimvCommandComplete -nargs=* Lisp call SlimvEval([<q-args>])
command! -complete=customlist,SlimvCommandComplete -nargs=* Eval call SlimvEval([<q-args>])

" Switch on syntax highlighting
if !exists("g:syntax_on")
    syntax on
endif

