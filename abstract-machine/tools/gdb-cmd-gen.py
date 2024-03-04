"""
Copyright © 2024 Haitian Jiang

Permission is hereby granted, free of charge, to any person 
obtaining a copy of this software and associated documentation 
files (the “Software”), to deal in the Software without 
restriction, including without limitation the rights to use, 
copy, modify, merge, publish, distribute, sublicense, and/or 
sell copies of the Software, and to permit persons to whom 
the Software is furnished to do so, subject to the following 
conditions:

The above copyright notice and this permission notice shall 
be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
OTHER DEALINGS IN THE SOFTWARE.
"""

from elftools.elf.elffile import ELFFile
import sys


def extract_function_names(elf_file_path):
    function_names = []

    with open(elf_file_path, 'rb') as f:
        elf = ELFFile(f)

        # check if the ELF file symtbl is not empty
        if not elf.get_section_by_name('.symtab'):
            print("Error: .symtab section not found in ELF file")
            return []

        # get the FUNC type symbol names
        for sym in elf.get_section_by_name('.symtab').iter_symbols():
            if sym['st_info']['type'] == 'STT_FUNC':
                function_names.append(sym.name)

    # Fix the special function name
    # Not all ELF files have this function name
    # Just ignore this error in nemu.mk
    function_names.append('__am_asm_trap')

    return function_names


def generate_gdb_command_list(func_names, elf_file_path,):
    gdb_commands = ["file " + elf_file_path,
                    "set disassembler-options no-aliases"  # optional command
                    ]

    # add disassemble commands for each function
    for func_name in func_names:
        if func_name:  # ignore empty function name
            gdb_commands.append(f"disassemble /m {func_name}")
            gdb_commands.append(
                "echo \\n-------------------------------------------------\\n")

    gdb_commands.append("quit")
    return gdb_commands


def gen_gdb_cmds_file(elf_file_path, gdb_cmd_file_path):
    func_names = extract_function_names(elf_file_path)
    # print(func_names)

    gdb_commands = generate_gdb_command_list(func_names, elf_file_path)
    # print(gdb_commands)

    with open(gdb_cmd_file_path, 'w') as f:
        f.write('\n'.join(gdb_commands))


elf_file_path = sys.argv[1]
gdb_gen_file_path = sys.argv[2]

gen_gdb_cmds_file(elf_file_path, gdb_gen_file_path)

# print(f"Done: Generated GDB commands file: {gdb_gen_file_path}")
