" Everything to do with perforce

if v:version < 700
    " module uses readlfile()!!!!
    finish
endif

let g:PerforceSetUp=1

"source ~/.dotFiles/vim/build.vim
runtime build.vim

function! GetClient(cfg)
    if filereadable(a:cfg)
        for line in readfile(a:cfg)
            if line =~ 'client_spec[=:]'
                return substitute(line, 'client_spec[=:]\s*', '', '')
            endif
        endfor
    "else
        "echo a:cfg." not readable"
    endif
    return ''
endfunction

function! SafePath(path)
  return substitute(a:path, "\\", "/", "g") 
endfunction

function! SetWorkspace(dir, default_client, default_client_root)
    let g:p4ClientRoot = a:dir
    if has("unix")
        let client = GetClient(a:dir."/qpbuild.cfg")
    else
        let client = GetClient(a:dir."\\qpbuild.cfg")
    endif
    if client == ''
        let client = a:default_client
        let client_root = a:default_client_root
    else
        let client_root = SafePath(a:dir)
    endif
    let g:p4Presets = 'qctcbgp4p01.eu.qualcomm.com:1667 '.client.' cemery,cbgperforce01.eu.qualcomm.com:1667 '.client.' cemery'
    let g:p4ClientRoot = client_root
    unlet client
    unlet client_root
endfunction

function! DefaultT5SrcHome()
    if has("unix")
        return expand ("$BASH_T5_SRC_HOME")
    else
        return expand ("$T5_SRC_HOME")
    endif
endfunction

function! NewT5SrcHome(h)
    "if a:h == "."
        "let g:t5srchome = SafePath(getcwd())
    "else
        "let g:t5srchome = a:h
    "endif
    "if g:t5srchome =~ ".*HEAD"
        "let g:sandbox=fnamemodify(g:t5srchome, ":h")
    "elseif g:t5srchome =~ ".*rel"
        "let g:sandbox=fnamemodify(g:t5srchome, ":h:h")
    "elseif g:t5srchome =~ ".*dev"
        "let g:sandbox=fnamemodify(g:t5srchome, ":h:h")
    "else
        "let g:sandbox=fnamemodify(g:t5srchome, ":h:h")
    "endif
    "call SetWorkspace(g:sandbox, "CEMERY", "c:/devel")
   
    if a:h == "."
        let g:t5srchome = SafePath(getcwd())
    else
        let g:t5srchome = a:h
    endif
    let cfg = FindUpTreeFrom("/qpbuild.cfg", g:t5srchome)
    let g:sandbox = fnamemodify (cfg, ":h")
    call SetWorkspace(g:sandbox, "CEMERY", "c:/devel")
    unlet cfg
endfunction

function! InitPerforce()
    call NewT5SrcHome(DefaultT5SrcHome())
    let g:p4EnableMenu = 1
    let g:p4DefaultPreset = 0
    if has("gui")
        so ~/vimfiles/perforce/perforcemenu.vim
    endif
    if has("python")
        python perforce = Perforce()
    endif
endfunction

function! ToggleP4P4IsDisabled()
    return exists("g:DisableP4")
endfunction

function! ToggleP4DisableP4()
    let g:DisableP4=1
endfunction

function! ToggleP4EnableP4()
    unlet g:DisableP4
endfunction

function! ToggleP4()
    if ToggleP4P4IsDisabled()
        call ToggleP4EnableP4()
        echo "Perforce enabled"
    else
        call ToggleP4DisableP4()
        echo "Perforce disabled"
    endif
endfunction
map <Leader>P :call ToggleP4()<CR>

if has("python")

python << EEOOFF
try:
    import P4
except:
    pass

try:
    from traceback import print_exc
except:
    def print_exc():
        pass

import sys
import vim

def add_line(a):
    b = vim.current.buffer
    if isinstance(a, list):
        for l in a:
            add_line(l)
    else:
        b.append(a)

def ascii(s):
    if isinstance(s, unicode):
        s = s.encode('ascii', 'replace').replace('?', '_')
    return s

def plural(n):
    if isinstance(n, float):
        if n == 1.0:
            return ''
    elif isinstance(n, int):
        if n == 1:
            return ''
    elif isinstance(n, long):
        if n == long(1):
            return ''
    return 's'

class Perforce:
    class Presets:
        def __init__(self):
            try:
                 def_preset_idx = long(vim.eval('g:p4DefaultPreset'))
                 presets = []
                 for p in vim.eval('g:p4Presets').split(','):
                     q = p.split(' ')
                     (host, port) = q[0].split(':')
                     r={}
                     r['host'] = host
                     r['port'] = port
                     r['client'] = q[1]
                     r['user'] = q[2]
                     presets.append(r)
                 def_preset = presets[def_preset_idx]
            except:
                 print_exc()
                 def_preset_idx = None
                 presets = []
                 def_preset = None
            self.__presets = presets
            self.__def_preset_idx = def_preset_idx
            self.__def_preset = def_preset

        def presets(self):
            return self.__presets

        def def_preset_idx(self):
            return self.__def_preset_idx

        def def_preset(self):
            return self.__def_preset

        def __repr__(self):
            return 'presets: %s, default preset: %s' % (self.__presets, self.__def_preset_idx)

    def __init__(self):
        self.__p4_dict = {}
        self.__last_p4c = None
        self.__presets = Perforce.Presets()

    def __get_connection(self, host, port, client, parse_forms = False, username = None):
        if host:
            host = host.lower()
        key = (host, port, client)
        p4c = self.__p4_dict.get(key, None)
        if not p4c:
            try:
               p4c = P4.P4()
               if parse_forms:
                   pass
                   #p4c.parse_forms()
               if host and port:
                   p4c.port = ascii('%s:%d' % (host, long(port)))
               if client:
                   p4c.client = client
               p4c.connect()
               self.__p4_dict[key] = p4c
            except:
               print_exc()
        self.__last_p4c = p4c
        return p4c

    def __set_default_connection(self, p4c):
        self.__def_p4c = p4c

    def __make_default_connection(self):
        dp = self.__presets.def_preset()
        if dp:
            p4c = self.__get_connection(dp['host'], dp['port'], dp['client'])
            self.__set_default_connection(p4c)

    def __describe(self, p4c, cl, suppress, opened):
        changed_files = [o['depotFile'] for o in opened if o['change'] == cl]
        add_line('Changes in changelist %s' % cl)
        if changed_files:
            add_line(changed_files)
            if not suppress:
                diff = p4c.run_diff(changed_files)
                for d in diff:
                    if isinstance(d, dict):
                        add_line('==== %(depotFile)s#%(rev)s - %(clientFile)s ====' % d)
                    else:
                        add_line(d)
            else:
                add_line(changed_files)
        else:
                add_line('No changes')
        add_line('')

    def describeOpen(self, changelist, client, shortened):
        c = self.__get_connection(None, None, client, True)
        if c is None:
            print('Not connected')
            return

        if changelist == '':
            changelists = 'default'
        elif changelist == '*':
            changelists = [cl['change'] for cl in c.run_changes('-u', c.user, '-s', 'pending', '-c', c.client)]
            changelists.sort()
            changelists = ['default'] + changelists
        else:
            changelists = [changelist]

        vim.command('new')
        vim.command('se ft=diff')
        vim.command('file Changes for changelist%s %s' % (plural(len(changelists)), ' '.join([str(cl) for cl in changelists])))
        vim.command('se modifiable')
        opened = c.run_opened()
        for cl in changelists:
            self.__describe(c, str(cl), shortened != '', opened)
        vim.command('se nomodifiable')
        vim.command('se nomodified')

    def ensureConnection(self):
        c=self.__last_p4c
        if c is None:
            c=self.__def_p4c
        if c is None:
            self.__make_default_connection()
        if c is None:
            print('Not connected')
            return
        else:
            return c

    def fetch(self, fname):
        c=self.ensureConnection()
        if c is None:
            return
        got=c.run_print('-q', fname)
        if got and len(got) == 2:
            add_line(got[1].split('\n'))

    def __repr__(self):
        return 'Perforce(%s, def conn: %s)' % (repr(self.__presets), self.__def_p4c)
EEOOFF

function! PFDescribeOpen(changelist, client, shortened)
python << EEOOFF
perforce.describeOpen(vim.eval("a:changelist"), vim.eval("a:client"), vim.eval("a:shortened"))
EEOOFF
endfunction

command! -nargs=+ PFDescribeOpen call PFDescribeOpen(<f-args>)

"function! PDiff3()
    "grab the current syntax
    "let syn=b:current_syntax
    "make a new buffer
    "(use bel vert new if you like the original on the right)
    "bel vert new
    "echoerr expand("%:p")
    "return
    "when this buffer is deleted we'll turn off diff mode for our edited file
    "let b:P4DiffWhenClosedDiffOff=1
    "give it the same syntax as the user's file
    "exec "setfiletype ".syn
    "unlet syn
    "insert the original version of the file we've just left
    "exec "python perforce.fetch(r'".expand("#:p")."')"
    "delete the blank line we started off with
    "silent normal 1Gdd
    "this is a temporary file
    "set bt=nofile
    "clear the modified flag
    "set nomodified
    " turn on line numbers
    "setlocal number
    " and wrap lines
    "setlocal wrap
    "enable diff
    "diffthis
    "switch back to the users buffer
    "wincmd p
    " turn on line numbers
    "setlocal number
    " and wrap lines
    "setlocal wrap
    "enable diff for the user's buffer
    "diffthis
    "switch back to the "original"
    "wincmd p
    "enable the navigation keys
    "call EnteredDiff()
"endfunction

"else " !has("python")

function! PDiff3()
    "grab the current syntax
    let syn=b:current_syntax
    "temoprarily revert the buffer to the last version
    silent PW print -q
    "and grab that content
    silent normal 1GyG
    "put what the user had back
    silent undo
    "make a new buffer
    "(use bel vert new if you like the original on the right)
    bel vert new
    "when this buffer is deleted we'll turn off diff mode for our edited file
    let b:P4DiffWhenClosedDiffOff=1
    "this is a temporary file
    set bt=nofile
    "give it the same syntax as the user's file
    exec "setfiletype ".syn
    unlet syn
    "paste in the content we're diffing against
    silent normal pkdd
    "clear the modified flag
    set nomodified
    " turn on line numbers
    setlocal number
    " and wrap lines
    setlocal wrap
    "enable diff
    diffthis
    "switch back to the users buffer
    wincmd p
    " turn on line numbers
    setlocal number
    " and wrap lines
    setlocal wrap
    "enable diff for the user's buffer
    diffthis
    "switch back to the "original"
    "wincmd p
    "enable the navigation keys
    call EnteredDiff()
endfunction

endif " has("python")

command! PDiff3 call PDiff3()

function! P4DiffEnter()
   if &diff
      if exists("g:P4DiffNextEnteredDiffOff")
         diffoff
         setlocal nonumber
         unlet g:P4DiffNextEnteredDiffOff
      endif
   endif
endfunction

function! P4DiffHide()
   if &diff
      if exists("b:P4DiffWhenClosedDiffOff")
         let g:P4DiffNextEnteredDiffOff=1
      endif
   endif
endfunction

augroup P4Diff
autocmd! P4Diff
autocmd! P4Diff BufEnter * call P4DiffEnter()
autocmd! P4Diff BufHidden * call P4DiffHide()
augroup end

" vim:shiftwidth=4
