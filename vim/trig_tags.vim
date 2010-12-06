" Trigenix-specific tags stuff
" T5

function! TagsT5_ (branch, action)
    if a:branch == "none"
        return
    elseif a:branch == "6.0.0"
        if has("win32")
            let d = g:sandbox."\\6.0.0\\rel"
        else
            let d = g:sandbox."/6.0.0/rel"
        endif
    elseif a:branch == "5.2.x"
        if has("win32")
            let d = g:sandbox."\\5.2.x\\dev"
        else
            let d = g:sandbox."/5.2.x/dev"
        endif
    elseif a:branch == "5.3.1"
        if has("win32")
            let d = g:sandbox."\\5.3.1\\rel"
        else
            let d = g:sandbox."/5.3.1/rel"
        endif
    elseif a:branch == "HEAD"
        let d=g:t5srchome
    endif
    if d != ""
        if has("win32")
            call TagsAction (a:action, d."\\trigbuilder\\tags")
            call TagsAction (a:action, d."\\parcelforce\\tags")
            call TagsAction (a:action, d."\\trigcompilation\\tags")
            call TagsAction (a:action, d."\\trigenixcpputils\\tags")
            call TagsAction (a:action, d."\\playertest\\tags")
            call TagsAction (a:action, d."\\protestserver\\tags")
            call TagsAction (a:action, d."\\playerframework\\tags")
            call TagsAction (a:action, d."\\playerframework_iface\\tags")
            call TagsAction (a:action, d."\\tags")
        else
            call TagsAction (a:action, d."/trigbuilder/tags")
            call TagsAction (a:action, d."/parcelforce/tags")
            call TagsAction (a:action, d."/trigcompilation/tags")
            call TagsAction (a:action, d."/trigenixcpputils/tags")
            call TagsAction (a:action, d."/playertest/tags")
            call TagsAction (a:action, d."/protestserver/tags")
            call TagsAction (a:action, d."/playerframework/tags")
            call TagsAction (a:action, d."/playerframework_iface/tags")
            call TagsAction (a:action, d."/tags")
        endif
    endif
endfunction

" Exclusive on T5

function! TagsT5(t5)
"   If it's a valid t5, remove all the possible ones
    if a:t5 == "HEAD"   ||
      \a:t5 == "5.2.x"  ||
      \a:t5 == "5.3.1"  ||
      \a:t5 == "6.0.0"    ||
      \a:t5 == "none"
        call TagsT5_("5.2.x", "del")
        call TagsT5_("5.3.1", "del")
        call TagsT5_("HEAD", "del")
        call TagsT5_("6.0.0", "del")
    else
"       Otherwise we'll bail here
        return
    endif
"   Now add back the the requested one
    if a:t5 == "none"
        return
    elseif a:t5 == "HEAD"
        call TagsT5_("HEAD", "add")
        echo "Setting tags for T5 HEAD"
    elseif a:t5 == "5.2.x"
        call TagsT5_("5.2.x", "add")
        echo "Setting tags for T5 5.2.x"
    elseif a:t5 == "5.3.1"
        call TagsT5_("5.3.1", "add")
        echo "Setting tags for T5 5.3.1"
    elseif a:t5 == "6.0.0"
        call TagsT5_("6.0.0", "add")
        echo "Setting tags for T5 6.0.0"
    endif
endfunction

" Rebuild T5

function! RebuildTagsT5(t5)
    if a:t5 == "none"
        return
    elseif a:t5 == "5.2.x"
        call TagsT5_("5.2.x", "rebuild")
        echo "Re-built tags for T5 5.2.x"
    elseif a:t5 == "5.3.1"
        call TagsT5_("5.3.1", "rebuild")
        echo "Re-built tags for T5 5.3.1"
    elseif a:t5 == "HEAD"
        call TagsT5_("HEAD", "rebuild")
        echo "Re-built tags for T5 HEAD"
    elseif a:t5 == "6.0.0"
        call TagsT5_("6.0.0", "rebuild")
        echo "Re-built tags for T5 6.0.0"
    endif
endfunction

" Qualcomm Python Tools

function! TagsQpTools1 (action)
    if has("win32")
        call TagsAction (a:action, $QP_TOOLS_1."\\tags")
    else
        call TagsAction (a:action, $BASH_QP_TOOLS_1."/tags")
    endif
endfunction

" Exclusive on Qualcomm Python Tools

function! TagsQpTools(ver)
"   If it's a valid ver, remove all the possible ones
    if a:ver == "none"  ||
      \a:ver == "1"
        call TagsQpTools1("del")
    else
"       Otherwise we'll bail here
        return
    endif
"   Now add back the the requested one
    if a:ver == "none"
        return
    elseif a:ver == "1"
        call TagsQpTools1("add")
        echo "Setting tags for Qualcomm Python Tools ver 1"
    endif
endfunction

" Rebuild Qualcomm Python Tools

function! RebuildTagsQpTools(ver)
    if a:ver == "none"
        return
    elseif a:ver == "1"
        call TagsQpTools1("rebuild")
        echo "Re-built tags for Qualcomm Python Tools ver 1"
    endif
endfunction

" BREW 2.1.0 tags

function! TagsBrew210 (action)
    if has("win32")
        call TagsAction (a:action, $BREWSDK210EN."\\tags")
    else
        call TagsAction (a:action, $BASH_BREWSDK210EN."/tags")
    endif
endfunction

" BREW 3.1.2 tags

function! TagsBrew312 (action)
    if has("win32")
        call TagsAction (a:action, $BREWSDK312EN."\\inc\\tags")
    else
        call TagsAction (a:action, $BASH_BREWSDK312EN."/inc/tags")
    endif
endfunction

" BREW brewery 3.1.2pk tags

function! TagsBrewery312pk (action)
    if has("win32")
        call TagsAction (a:action, g:tags_sb."brewery\\rel\\3.1.2pk\\tags")
    else
        call TagsAction (a:action, g:tags_sb."brewery/rel/3.1.2pk/tags")
    endif
endfunction

" BREW brewery main tags

function! TagsBreweryMain (action)
    if has("win32")
        call TagsAction (a:action, g:tags_sb."brewery\\main\\tags")
    else
        call TagsAction (a:action, g:tags_sb."brewery/main/tags")
    endif
endfunction

" BREW 3.2.1 generic pk tags

function! TagsBrew312GenericPk (action)
    if has("win32")
        call TagsAction (a:action, $BREWPKGENERIC312."\\tags")
    else
        call TagsAction (a:action, $BASH_BREWPKGENERIC312."/tags")
    endif
endfunction

" BREW 3.x tags

function! TagsBrew3x (action)
    if has("win32")
        call TagsAction (a:action, g:tags_sb."3.x\\tags")
    else
        call TagsAction (a:action, g:tags_sb."3.x/tags")
    endif
endfunction

" BTIL

function! TagsBTILMain (action)
    if has("win32")
        call TagsAction (a:action, $BREWBTILMAIN."\\tags")
    else
        call TagsAction (a:action, $BASH_BREWBTILMAIN."/tags")
    endif
endfunction

function! TagsBTIL3x (action)
    if has("win32")
        call TagsAction (a:action, $BREWBTIL3X."\\tags")
    else
        call TagsAction (a:action, $BASH_BREWBTIL3X."/tags")
    endif
endfunction

function! TagsBTIL102 (action)
    if has("win32")
        call TagsAction (a:action, $BREWBTIL102."\\tags")
    else
        call TagsAction (a:action, $BASH_BREWBTIL102."/tags")
    endif
endfunction

function! TagsBTIL(ver)
"   If it's a valid version, remove all the possible ones
    if a:ver == "3.x"       ||
      \a:ver == "1.0.2"     ||
      \a:ver == "main"    ||
      \a:ver == "none"
        call TagsBTILMain("del")
        call TagsBTIL3x("del")
        call TagsBTIL102("del")
    else
"       Otherwise we'll bail here
        return
    endif
"   Now add back the the requested one
    if a:ver == "none"
        return
    elseif a:ver == "3.x"
        call TagsBTIL3x("add")
        echo "Setting tags for 3.x version of BTIL"
    elseif a:ver == "1.0.2"
        call TagsBTIL102("add")
        echo "Setting tags for 1.0.2 version of BTIL"
    elseif a:ver == "main"
        call TagsBTILMain("add")
        echo "Setting tags for 'main' version of BTIL"
    endif
endfunction

function! RebuildTagsBTIL(ver)
    if a:ver == "none"
        return
    elseif a:ver == "3.x"
        call TagsBTIL3x("rebuild")
        echo "Re-built tags for 3.x version of BTIL"
    elseif a:ver == "1.0.2"
        call TagsBTIL102("rebuild")
        echo "Re-built tags for 'main' version of BTIL"
    elseif a:ver == "main"
        call TagsBTILMain("rebuild")
        echo "Re-built tags for 'main' version of BTIL"
    endif
endfunction

" Exclusive on BREW

function! TagsBrew(sdk)
"   If it's a valid sdk, remove all the possible ones
    if a:sdk == "210"           ||
      \a:sdk == "312"           ||
      \a:sdk == "brewery-312pk" ||
      \a:sdk == "brewery-main"  ||
      \a:sdk == "312GenericPk"  ||
      \a:sdk == "3.x"           ||
      \a:sdk == "none"
        call TagsBrew210("del")
        call TagsBrew312("del")
        call TagsBrewery312pk("del")
        call TagsBreweryMain("del")
        call TagsBrew312GenericPk("del")
        call TagsBrew3x("del")
    else
"       Otherwise we'll bail here
        return
    endif
"   Now add back the the requested one
    if a:sdk == "none"
        return
    elseif a:sdk == "210"
        call TagsBrew210("add")
        echo "Setting tags for BREW sdk 2.1.0"
    elseif a:sdk == "312"
        call TagsBrew312("add")
        echo "Setting tags for BREW sdk 3.1.2"
    elseif a:sdk == "brewery-312pk"
        call TagsBrewery312pk("add")
        echo "Setting tags for BREW sdk 3.1.2pk"
    elseif a:sdk == "brewery-main"
        call TagsBreweryMain("add")
        echo "Setting tags for BREW 'brewery main'"
    elseif a:sdk == "312GenericPk"
        call TagsBrew312GenericPk("add")
        echo "Setting tags for BREW Generic 3.1.2pk"
    elseif a:sdk == "3.x"
        call TagsBrew3x("add")
        echo "Setting tags for BREW 3.x"
    endif
endfunction

" Rebuild BREW

function! RebuildTagsBrew(sdk)
    if a:sdk == "none"
        return
    elseif a:sdk == "210"
        call TagsBrew210("rebuild")
        echo "Re-built tags for BREW sdk 2.1.0"
    elseif a:sdk == "312"
        call TagsBrew312("rebuild")
        echo "Re-built tags for BREW sdk 3.1.2"
    elseif a:sdk == "brewery-312pk"
        call TagsBrewery312pk("rebuild")
        echo "Re-built tags for BREW sdk 3.1.2pk"
    elseif a:sdk == "brewery-main"
        call TagsBreweryMain("rebuild")
        echo "Re-built tags for BREW 'brewery main'"
    elseif a:sdk == "312GenericPk"
        call TagsBrew312GenericPk("rebuild")
        echo "Re-built tags for BREW Generic 3.1.2pk"
    elseif a:sdk == "3.x"
        call TagsBrew3x("rebuild")
        echo "Re-built tags for BREW 3.x"
    endif
endfunction

" versioned product in sandbox

function! TagsProduct_ (action, prod, ver)
    let v = a:ver
    let suff = v[-2:]
    let dotX = ".x"
    let ret = ""
    if has("win32")
        if suff =~ "\\.x$"
            let v = v . "\\dev"
        elseif suff =~ "\\.\\d\\+"
            let v = v . "\\rel"
        endif
        let ret = TagsAction (a:action, g:tags_sb.v."\\".a:prod."\\tags")
    else
        if suff =~ "\\.x$"
            let v = v . "/dev"
        elseif suff =~ "\\.\\d\\+"
            let v = v . "\\rel"
        endif
        let ret = TagsAction (a:action, g:tags_sb.v."/".a:prod."/tags")
    endif
    return ret
endfunction

" a branch in qpbuild

function! TagsBranch_ (action, branch)
    let branch = a:branch
    let suff = branch[-2:]
    let dotX = ".x"
    if has("win32")
        if suff == dotX
            let branch = branch . "\\dev"
        endif
        call TagsAction (a:action, g:tags_sb.a:branch."\\tags")
    else
        if suff == dotX
            let branch = branch . "/dev"
        endif
        call TagsAction (a:action, g:tags_sb.a:branch."/tags")
    endif
endfunction

" Widgets

function! TagsWidgets(ver)
"   If it's a valid version, remove all the possible ones
    if a:ver == "main"      ||
      \a:ver == "official"  ||
      \a:ver == "1.4.1"     ||
      \a:ver == "2.0.1"     ||
      \a:ver == "none"
        call TagsProduct_("del", "widgets", "main")
        call TagsProduct_("del", "widgets", "official")
        call TagsProduct_("del", "widgets", "1.4.1")
        call TagsProduct_("del", "widgets", "2.0.1")
    else
"       Otherwise we'll bail here
        return
    endif
"   Now add back the the requested one
    if a:ver == "none"
        return
    elseif a:ver == "main"
        echo "Setting tags for main version of Widgets".TagsProduct_("add", "widgets", "main")
    elseif a:ver == "official"
        echo "Setting tags for official version of Widgets".TagsProduct_("add", "widgets", "official")
    elseif a:ver == "1.4.1"
        echo "Setting tags for 1.4.1 version of Widgets".TagsProduct_("add", "widgets", "1.4.1")
    elseif a:ver == "2.0.1"
        echo "Setting tags for 2.0.1 version of Widgets".TagsProduct_("add", "widgets", "2.0.1")
    endif
endfunction

function! RebuildTagsWidgets(ver)
    if a:ver == "none"
        return
    elseif a:ver == "main"
        call TagsProduct_("rebuild", "widgets", "main")
        echo "Re-built tags for main version of Widgets"
    elseif a:ver == "official"
        call TagsProduct_("rebuild", "widgets", "official")
        echo "Re-built tags for official version of Widgets"
    elseif a:ver == "1.4.1"
        call TagsProduct_("rebuild", "widgets", "1.4.1")
        echo "Re-built tags for 1.4.1 version of Widgets"
    elseif a:ver == "2.0.1"
        call TagsProduct_("rebuild", "widgets", "2.0.1")
        echo "Re-built tags for 2.0.1 version of Widgets"
    endif
endfunction

" Typeface

function! TagsTypeface(ver)
"   If it's a valid version, remove all the possible ones
    if a:ver == "main"      ||
      \a:ver == "1.0.x"     ||
      \a:ver == "none"
        call TagsProduct_("del", "btfe", "main")
        call TagsProduct_("del", "btfe", "1.0.x")
    else
"       Otherwise we'll bail here
        return
    endif
"   Now add back the the requested one
    if a:ver == "none"
        return
    elseif a:ver == "main"
        call TagsProduct_("add", "btfe", "main")
        echo "Setting tags for main version of Typeface"
    elseif a:ver == "1.0.x"
        call TagsProduct_("add", "btfe", "1.0.x")
        echo "Setting tags for 1.0.x version of Typeface"
    endif
endfunction

function! RebuildTagsTypeface(ver)
    if a:ver == "none"
        return
    elseif a:ver == "main"
        call TagsProduct_("rebuild", "btfe", "main")
        echo "Re-built tags for main version of Typeface"
    elseif a:ver == "1.0.x"
        call TagsProduct_("rebuild", "btfe", "1.0.x")
        echo "Re-built tags for 1.0.x version of Typeface"
    endif
endfunction

" Fonts

function! TagsFonts(ver)
"   If it's a valid version, remove all the possible ones
    if a:ver == "none"      ||
      \a:ver == "main"      ||
      \a:ver == "1.0.0"
        call TagsProduct_("del", "fonts", "main")
        call TagsProduct_("del", "fonts", "1.0.0")
    else
"       Otherwise we'll bail here
        return
    endif
"   Now add back the the requested one
    if a:ver == "none"
        return
    elseif a:ver == "main"
        call TagsProduct_("add", "fonts", "main")
        echo "Setting tags for main version of Fonts"
    elseif a:ver == "1.0.0"
        call TagsProduct_("add", "fonts", "1.0.0")
        echo "Setting tags for 1.0.0 version of Fonts"
    endif
endfunction

function! RebuildTagsFonts(ver)
    if a:ver == "none"
        return
    elseif a:ver == "main"
        call TagsProduct_("rebuild", "fonts", "main")
        echo "Re-built tags for main version of Fonts"
    elseif a:ver == "1.0.0"
        call TagsProduct_("rebuild", "fonts", "1.0.0")
        echo "Re-built tags for 1.0.0 version of Fonts"
    endif
endfunction

" MIUI

function! TagsMIUI(ver)
"   If it's a valid version, remove all the possible ones
    if a:ver == "none"      ||
      \a:ver == "main"
        call TagsBranch_("del", "MIUI")
    else
"       Otherwise we'll bail here
        return
    endif
"   Now add back the the requested one
    if a:ver == "none"
        return
    elseif a:ver == "main"
        call TagsBranch_("add", "MIUI")
        echo "Setting tags for MIUI"
    endif
endfunction

function! RebuildTagsMIUI(ver)
    if a:ver == "none"
        return
    elseif a:ver == "main"
        call TagsBranch_("rebuild", "MIUI")
        echo "Re-built tags for MIUI"
    endif
endfunction

function! RebuildAllBrewTags()
    call RebuildTagsBrew("210")
    call RebuildTagsBrew("312")
    call RebuildTagsBrew("brewery-312pk")
    call RebuildTagsBrew("brewery-main")
    call RebuildTagsBrew("312GenericPk")
    call RebuildTagsBTIL("3.x")
    call RebuildTagsBTIL("main")
    call RebuildTagsWidgets("main")
    call RebuildTagsWidgets("official")
    call RebuildTagsWidgets("1.2.0")
    call RebuildTagsWidgets("1.2")
endfunction

nmap <silent> gF :lcd .<CR>:echo "Trying to find file ".'"'.expand("<cfile>").'" in tags'<CR>:sleep<CR>:exec "tselect ".expand("<cfile>")<CR>

amenu 40.320.10.10       &Tools.T&ags.Build\ &Tags\ File.&Current\ Directory :cal BuildTagsFile()<CR>

amenu 40.320.10.20.10    &Tools.T&ags.Build\ &Tags\ File.&BREW.&Rebuild\ All :call RebuildAllBrewTags()<CR>
amenu 40.320.10.20.10.10 &Tools.T&ags.Build\ &Tags\ File.&BREW.&SDK.Rebuild\ &2\.1\.0 :call RebuildTagsBrew("210")<CR>
amenu 40.320.10.20.10.20 &Tools.T&ags.Build\ &Tags\ File.&BREW.&SDK.Rebuild\ &3\.1\.2 :call RebuildTagsBrew("312")<CR>
amenu 40.320.10.20.10.30 &Tools.T&ags.Build\ &Tags\ File.&BREW.&SDK.Rebuild\ brewery\ 3\.1\.2&pk :call RebuildTagsBrew("brewery-312pk")<CR>
amenu 40.320.10.20.10.40 &Tools.T&ags.Build\ &Tags\ File.&BREW.&SDK.Rebuild\ brewery\ &main :call RebuildTagsBrew("brewery-main")<CR>
amenu 40.320.10.20.10.50 &Tools.T&ags.Build\ &Tags\ File.&BREW.&SDK.Rebuild\ &3\.1\.2\ Generic\ pk :call RebuildTagsBrew("312GenericPk")<CR>
amenu 40.320.10.20.10.60 &Tools.T&ags.Build\ &Tags\ File.&BREW.&SDK.Rebuild\ 3\.&x :call RebuildTagsBrew("3.x")<CR>

amenu 40.320.10.20.20.10 &Tools.T&ags.Build\ &Tags\ File.&BREW.&BTIL.Rebuild\ &3\.x :call RebuildTagsBTIL("3.x")<CR>
amenu 40.320.10.20.20.20 &Tools.T&ags.Build\ &Tags\ File.&BREW.&BTIL.Rebuild\ &main :call RebuildTagsBTIL("main")<CR>
amenu 40.320.10.20.20.30 &Tools.T&ags.Build\ &Tags\ File.&BREW.&BTIL.Rebuild\ &1\.0\.2 :call RebuildTagsBTIL("1.0.2")<CR>

amenu 40.320.10.20.30.10 &Tools.T&ags.Build\ &Tags\ File.&BREW.&Widgets.Rebuild\ &main :call RebuildTagsWidgets("main")<CR>
amenu 40.320.10.20.30.20 &Tools.T&ags.Build\ &Tags\ File.&BREW.&Widgets.Rebuild\ &official :call RebuildTagsWidgets("official")<CR>
amenu 40.320.10.20.30.30 &Tools.T&ags.Build\ &Tags\ File.&BREW.&Widgets.Rebuild\ &1\.4\.1 :call RebuildTagsWidgets("1.4.1")<CR>
amenu 40.320.10.20.30.40 &Tools.T&ags.Build\ &Tags\ File.&BREW.&Widgets.Rebuild\ &2\.0\.1 :call RebuildTagsWidgets("2.0.1")<CR>

amenu 40.320.10.20.40.10 &Tools.T&ags.Build\ &Tags\ File.&BREW.&Typeface.Rebuild\ &main :call RebuildTagsTypeface("main")<CR>
amenu 40.320.10.20.40.20 &Tools.T&ags.Build\ &Tags\ File.&BREW.&Typeface.Rebuild\ 1\.&0\.x :call RebuildTagsTypeface("1.0.x")<CR>

amenu 40.320.10.30 &Tools.T&ags.Build\ &Tags\ File.&MIUI :call RebuildTagsMIUI("main")<CR>

amenu 40.320.10.30 &Tools.T&ags.Build\ &Tags\ File.T&5.&HEAD :call RebuildTagsT5("HEAD")<CR>
amenu 40.320.10.30 &Tools.T&ags.Build\ &Tags\ File.T&5.5\.&2\.x :call RebuildTagsT5("5.2.x")<CR>
amenu 40.320.10.40 &Tools.T&ags.Build\ &Tags\ File.T&5.5\.&3\.1 :call RebuildTagsT5("5.3.1")<CR>
amenu 40.320.10.50 &Tools.T&ags.Build\ &Tags\ File.&QP\ Tools :call RebuildTagsQpTools("1")<CR>

amenu 40.320.10.20.40.10 &Tools.T&ags.Build\ &Tags\ File.&BREW.&Fonts.Rebuild\ &main :call RebuildTagsFonts("main")<CR>
amenu 40.320.10.20.40.20 &Tools.T&ags.Build\ &Tags\ File.&BREW.&Fonts.Rebuild\ &1\.0\.0 :call RebuildTagsFonts("1.0.0")<CR>

amenu 40.320.20.10.1  &Tools.T&ags.&BREW.&SDK.&Remove :call TagsBrew("none")<CR>
amenu 40.320.20.10.10 &Tools.T&ags.&BREW.&SDK.Set\ to\ &2\.1\.0 :call TagsBrew("210")<CR>
amenu 40.320.20.10.20 &Tools.T&ags.&BREW.&SDK.Set\ to\ &3\.1\.2 :call TagsBrew("312")<CR>
amenu 40.320.20.10.30 &Tools.T&ags.&BREW.&SDK.Set\ to\ brewery\ 3\.1\.2&pk :call TagsBrew("brewery-312pk")<CR>
amenu 40.320.20.10.40 &Tools.T&ags.&BREW.&SDK.Set\ to\ brewery\ &main :call TagsBrew("brewery-main")<CR>
amenu 40.320.20.10.50 &Tools.T&ags.&BREW.&SDK.Set\ to\ &3\.1\.2\ Generic\ pk :call TagsBrew("312GenericPk")<CR>
amenu 40.320.20.10.60 &Tools.T&ags.&BREW.&SDK.Set\ to\ 3\.&x :call TagsBrew("3.x")<CR>

amenu 40.320.20.20.1  &Tools.T&ags.&BREW.&BTIL.&Remove :call TagsBTIL("none")<CR>
amenu 40.320.20.20.10 &Tools.T&ags.&BREW.&BTIL.Set\ to\ &3\.x :call TagsBTIL("3.x")<CR>
amenu 40.320.20.20.20 &Tools.T&ags.&BREW.&BTIL.Set\ to\ &main :call TagsBTIL("main")<CR>
amenu 40.320.20.20.30 &Tools.T&ags.&BREW.&BTIL.Set\ to\ &1\.0\.2 :call TagsBTIL("1.0.2")<CR>

amenu 40.320.20.30.1  &Tools.T&ags.&BREW.&Widgets.&Remove :call TagsWidgets("none")<CR>
amenu 40.320.20.30.10 &Tools.T&ags.&BREW.&Widgets.Set\ to\ &main :call TagsWidgets("main")<CR>
amenu 40.320.20.30.20 &Tools.T&ags.&BREW.&Widgets.Set\ to\ &official :call TagsWidgets("official")<CR>
amenu 40.320.20.30.30 &Tools.T&ags.&BREW.&Widgets.Set\ to\ &1\.4\.1 :call TagsWidgets("1.4.1")<CR>
amenu 40.320.20.30.40 &Tools.T&ags.&BREW.&Widgets.Set\ to\ &2\.0\.1 :call TagsWidgets("2.0.1")<CR>

amenu 40.320.20.40.1  &Tools.T&ags.&BREW.&Typeface.&Remove :call TagsTypeface("none")<CR>
amenu 40.320.20.40.10 &Tools.T&ags.&BREW.&Typeface.&main :call TagsTypeface("main")<CR>
amenu 40.320.20.40.20 &Tools.T&ags.&BREW.&Typeface.1\.&0\.x :call TagsTypeface("1.0.x")<CR>

amenu 40.320.20.40.1  &Tools.T&ags.&BREW.&Fonts.&Remove :call TagsFonts("none")<CR>
amenu 40.320.20.40.10 &Tools.T&ags.&BREW.&Fonts.Set\ to\ &main :call TagsFonts("main")<CR>
amenu 40.320.20.40.20 &Tools.T&ags.&BREW.&Fonts.Set\ to\ &1\.0\.0 :call TagsFonts("1.0.0")<CR>

amenu 40.320.30 &Tools.T&ags.T&5.&HEAD :call TagsT5("HEAD")<CR>
amenu 40.320.30 &Tools.T&ags.T&5.5\.&2\.x :call TagsT5("5.2.x")<CR>
amenu 40.320.40 &Tools.T&ags.T&5.5\.&3\.1 :call TagsT5("5.3.1")<CR>
amenu 40.320.50 &Tools.T&ags.T&5.&6\.0\.0 :call TagsT5("6.0.0")<CR>
amenu 40.320.60 &Tools.T&ags.T&5.&None :call TagsT5("none")<CR>
amenu 40.320.70 &Tools.T&ags.&QP\ Tools :call TagsQpTools("1")<CR>

amenu 40.320.50.1  &Tools.T&ags.&MIUI.&Remove :call TagsMIUI("none")<CR>
amenu 40.320.50.10 &Tools.T&ags.&MIUI.&Set :call TagsMIUI("main")<CR>

if !exists("tags_grown")
    let tags_grown = 1

"   Tags on all platforms
"   set tags+=../tags
"   call AddTagFileIfReadable(expand("~/dist/tag/dist"))
"   call AddTagFileIfReadable(expand("~/dist/tag/shell"))
"   call TagsOnlyWCE300()
    set tags-=TAGS
    set tags-=./TAGS

"   tags *just* on Win32
    if has("win32")
"       set tags+=../TAGS
    endif

"   tags *just* on Linux
    if has("unix")
"       call AddTagFileIfReadable(expand("~/dist/tag/system"))
"       set tags+=~/dist/tag/ose
"       set tags+=~/dist/tag/arm
    endif

"   trigenix specific tag files
"   exec "set tags+=".$T4_HOME."/code/tags"
"   exec "set tags+=".$PMAKE_2."/tags"

    call TagsBrew210("add")
    call TagsQpTools1("add")

    if has("gui")
        aunmenu Tools.Build\ Tags\ File
    endif
endif

