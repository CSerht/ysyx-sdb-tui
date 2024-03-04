"""
" Copyright © 2024 Haitian Jiang
"
" Permission is hereby granted, free of charge, to any person
" obtaining a copy of this software and associated documentation
" files (the “Software”), to deal in the Software without
" restriction, including without limitation the rights to use,
" copy, modify, merge, publish, distribute, sublicense, and/or
" sell copies of the Software, and to permit persons to whom
" the Software is furnished to do so, subject to the following
" conditions:
"
" The above copyright notice and this permission notice shall
" be included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
" OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
" HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
" WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
" FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
" OTHER DEALINGS IN THE SOFTWARE.
"""


"""
" The method to use this file is as follows:
"
" 1. `source` this file after opening a file in vim.
"    Only need to `source` it once.
" 2. `call HighlightAddress('address')` to highlight
"    the specific line in the file. you can call
"    this function multiple times to highlight different
"    lines.
"
" Note:
" We assume that the line that matches the 
" address is unique in the file because the instruction 
" address is unique in the disassembly file.
"
" If the address is not exist in the file, the function
" will not highlight anything.
"
" The format of the disassembly file is the same as the
" output of `gdb disassemble /m function_name` command.
"""

" Define a new highlight group, using a blue background and white foreground.
" It's named "PosInstHL" (short for "Positional Instruction Highlight").
" See https://www.ditig.com/publications/256-colors-cheat-sheet/ for color codes.
" For more compatibility with all kinds of terminals, we use the system color codes
highlight PosInstHL guibg=blue guifg=white ctermbg=blue ctermfg=white

"""
" This function highlights the line that contains the given address.
" 
" Parameters:
"   address: The address to highlight. e.g. "0x8000100c"
" 
" Example:
" :call HighlightAddress('0x8000100c')
" Then '   0x8000100c <+4> addi sp,sp,-4 # 80022000 <_end>'
" will be highlighted.
"""
function! HighlightAddress(address)
    " Check if the match ID exists, and delete it if it does
    if exists('s:match_id')
        call matchdelete(s:match_id)
    endif

    let l:pattern = '\v^\s*' . a:address . '.*$'

    " Use matchadd() to highlight the pattern, and store the match
    " ID in a script-local variable so we can delete it later.
    let s:match_id = matchadd('PosInstHL', l:pattern)

    " If the above line doesn't work, try the following line instead,
    " or modify the 'PosInstHL' to another highlight group.
    " let s:match_id = matchadd('Search', l:pattern)

    " Search for the address. If not found, search() returns 0.
    if search('^\s*' . a:address) == 0
        echo "Address " . a:address . " not found. Maybe it is optimized out by gdb."
        echo "Try to use disassemble \/s function_name command to get the disassembly file."
        
        " Press Enter to clear the message
        sleep 2
        call feedkeys("\<CR>", 'n')
    endif

endfunction
