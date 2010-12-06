if !exists("built_version_control_menu")
    let built_version_control_menu = 1
else
    aunmenu Version\ Control
endif

function! P4Action (action)
    let cwd=getcwd()
    lcd %:p:h
    let f = expand ("%:p:t")
    if a:action == "edit"
        let lines = system ("p4 edit " . f)
        edit!
    elseif a:action == "revert"
        let lines = system ("p4 revert " . f)
        edit!
    elseif a:action == "add"
        let f = expand ("%:p")
        let lines = system ("p4 add " . f)
        edit!
    else
        echo "Bah!"
    endif
    exec "lcd " . cwd
endfunction

amenu 110.10 &Version\ Control.&Edit\ This\ File :call P4Action("edit")<CR>
amenu 110.20 &Version\ Control.&Revert\ This\ File :call P4Action("revert")<CR>
amenu 110.30 &Version\ Control.&Add\ This\ File :call P4Action("add")<CR>

" vim:shiftwidth=4
