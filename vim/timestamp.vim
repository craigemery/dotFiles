" This file provides functions that will allow the timestamps (i.e. the last modified
" times) of files to be saved and restored
" This facilitates the saving of a file without changing it's timestamp
" I've most commonly used this for saving a source file after only changing a comment

" The way I'm going to implement this is:

function! SaveTimeStamp(file)
python << EEOOFF
import 
import vim
import string
fname = vim.eval("a:file")
fpath = vim.eval("fnamemodify(\"" + fname + "\", \":p:h\")")
(drive, path) = os.path.splitdrive(fpath)
print "drive: %s" % drive
dbpath = os.path.join(drive, os.path.sep, "timestamps.txt")
mtime = os.path.getmtime(fpath)
print "will write mtime:%d for %s into %s" % (mtime, fpath, dbpath)
EEOOFF
endfunction

function! RestoreTimeStamp()
endfunction

function! SaveFileWithoutChangingTimestamp()
   call SaveTimeStamp()
   write
   call RestoreTimeStamp()
endfunction
