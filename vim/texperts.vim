" Alter the number below for a dynamic #include guard
"let s:texperts_vim_version=1

if exists("g:texperts_vim_version_sourced") && exists("s:texperts_vim_version")
    if s:texperts_vim_version == g:texperts_vim_version_sourced
        finish
    endif
endif

if exists("s:texperts_vim_version")
    let g:texperts_vim_version_sourced=s:texperts_vim_version
endif

function! TPathManip(action, appname)
    if a:action == "add"
        exec ":set path^=$TEXPERT_HOME/".a:appname."/**"
    elseif a:action == "del"
        exec ":set path-=$TEXPERT_HOME/".a:appname."/**"
    endif
endfunction

function! TNoApp()
    if exists("g:texpert_current_app")
        "exec ":set path-=$TEXPERT_HOME/".g:texpert_current_app."/**"
        call TPathManip("del", "shared_plugins")
        call TPathManip("del", g:texpert_current_app)
        unlet g:texpert_current_app
        exec ":set tags-=$TEXPERT_HOME/shared_plugins/tags"
    endif
endfunction

command! TNoApp :call TNoApp()

function! T()
    TNoApp
    cd $TEXPERT_HOME
endfunction

command! T :call T()

function! TApp(appname)
    let ad=expand("$TEXPERT_HOME")."/".a:appname
    if isdirectory(ad)
        call TNoApp()
        let g:texpert_current_app=a:appname
        "exec ":set path+=$TEXPERT_HOME/".g:texpert_current_app."/**"
        if a:appname != "shared_plugins"
            call TPathManip("add", "shared_plugins")
            exec ":set tags+=$TEXPERT_HOME/shared_plugins/tags"
        endif
        call TPathManip("add", g:texpert_current_app)
        exec ":cd $TEXPERT_HOME/".g:texpert_current_app
    else
        echoerr "Directory ".ad." doesn't exist"
    endif
endfunction

function! TAppComp(A,L,P)
    let ret = ["texpert", "gatekeeper", "ui", "rota", "shared_plugins", "texpertise2", "shifty"]
    if len(a:A) > 0
        let ret = filter(ret, 'v:val =~ a:A')
    endif
    return ret
endfunction

command! -nargs=1 -complete=customlist,TAppComp TApp call TApp(<f-args>)

function! GotoRubyFile()
    let cw=expand("<cfile>")
    exec ":find ".cw.".rb"
endfunction

map gr :call GotoRubyFile()<CR>

function! TidyStack()
    exec "g/^\s*$/d"
    normal 1G
	while line("$") > 1
	  normal Jx
	endwhile
    exec "%s@`[^']\\+'@&@g"
    exec "%s@\\(\\.rb:\\d\\+\\)/@\\1/@g"
    let @/=""
    normal 1G
    exec "s@re5ult\\[\\d\\+\\]: @&@g"
endfunction

command! TidyStack call TidyStack()

set path+=/Library/Ruby/Gems/1.8/gems/**
if has("python")
python << EEOOFF
import glob, vim
caps = glob.glob('/Library/Ruby/Gems/1.8/gems/capistrano-*/lib/tags')
if caps:
    caps.sort
    vim.command("set tags+=%s" % (caps[-1], ))
EEOOFF
else
    let cap_tags="/Library/Ruby/Gems/1.8/gems/capistrano-2.5.18/lib/tags"
    if exists(cap_tags)
        exec "set tags+=".cap_tags
    endif
endif

" vim:shiftwidth=4:ts=4

