
Basic reversing
===============

In this recipe:

- [Collect basic information about the executable (Windows)](#collect-basic-information-about-the-executable-windows)
- [Collect basic information about the executable (Linux)](#collect-basic-information-about-the-executable-linux)
- [Understand calling conventions](#understand-calling-conventions)
  - [AMD64](#amd64)
  - [x86 (stdcall and pascall)](#x86-stdcall-and-pascall)
  - [x86 (cdecl)](#x86-cdecl)
  - [x86 (fastcall)](#x86-fastcall)
  - [x86 (clrcall)](#x86-clrcall)
  - [x86 (thiscall)](#x86-thiscall)
- [Use reversing tools](#use-reversing-tools)
  - [Ghidra](#ghidra)
  - [IDA Freeware](#ida-freeware)

## Collect basic information about the executable (Windows)

**Dumpbin** (part of the Windows SDK) is a command line tool which dumps various information about the executable:

- dump all PE headers and disassemble the .text sections: `dumpbin /all /disasm:nobytes /out:file.asm file.dll`
- dump information about the exported methods in the PE file: `dumpbin /exports file.dll`
- dump PE file headers: `dumpbin /headers file.dll`

A great tool to track dependencies between PE files is [**Dependencies**](https://github.com/lucasg/Dependencies), a rewrite of the [Dependency Walker](http://www.dependencywalker.com/).

## Collect basic information about the executable (Linux)

To dump **symbol tables**, we can use the `readelf -s {path}` command. The **.dynsym** table lists the dynamic symbols (required by the dynamic linker), while the **.symtab** lists all the  symbols, local and dynamic. Alternatively, we could use `objdump -t` (static symbols) or `objdump -T` (dynamic symbols).

## Understand calling conventions

### AMD64

Parameters less than 64 bits long are not zero extended; the high bits contain garbage. It is the caller's responsibility to allocate 32 bytes of "shadow space" (for storing RCX, RDX, R8, and R9 if needed) before calling the function:

![x64-calling-convention](x64.jpg)

Condition   | Argument 0 | Argument 1 | Argument 2 | Argument 3
------------|------------|------------|------------|------------
If integer  | RCX        | RDX        | R8         | R9
If float    | XMM0       | XMM1       | XMM2       | XMM3


Address    | The value is
-----------|---------------------------
 ...       | ...
RSP - 0x08 | Local variable 0
RSP        | Return address
RSP + 0x08 | Placeholder 0
RSP + 0x10 | Placeholder 1
RSP + 0x18 | Placeholder 2
RSP + 0x20 | Placeholder 3
RSP + 0x28 | Argument 4
RSP + 0x30 | Argument 5
RSP + 0x38 | Argument 6
 ...       | ...

It is also the caller's responsibility to clean the stack after the call. Integer return values (similar to x86) are returned in RAX if 64 bits or less. Floating point return values are returned in XMM0.

As there is no base pointer in x64 the debugger uses something called unwind info, which is embedded into the binary. You may dump the unwind info with dumpbin /unwindinfo. Within the debugger we may use the .fnent command. Excellent article about it can be found [here](https://blogs.msdn.microsoft.com/ntdebugging/2010/5/12/x64-manual-stack-reconstruction-and-stack-walking/).

### x86 (stdcall and pascall)

Arguments: right to left

Stack-maintenance: called function pops its arguments from the stack

![x86-calling-convention](x86.jpg)

Address    | The value is
-----------|---------------------------
 ...       | ...
EBP + 0x00 | Previous EBP
EBP + 0x04 | Return address
EBP + 0x08 | Argument 0
EBP + 0x0C | Argument 1
EBP + 0x10 | Argument 2
 ...       | ...

Name decoration: 

- prefix: `_` 
- suffix: `@<num_of_bytes_in_decimal_in_argument_list>`

Example: `int func(int a, double b)` will be emitted as `_func@12`

### x86 (cdecl)

Arguments: from right to left

Stack-maintenance: calling function pops arguments from the stack

Name decoration:

- prefix: `_`, except functions exported using C linkage

### x86 (fastcall)

Arguments: first 2 DWORD or smaller arguments are passed in ECX and EDX registers; all other arguments are passed right to left

Stack-maintenance: called function pops arguments from the stack

Name decoration: 

- prefix: `_` 
- suffix: `@<num_of_bytes_in_decimal_in_argument_list>`

### x86 (clrcall)

Similar to fastcall. Two registers are used by the x86 jitter (ecx, edx). Large value types like Decimal and large structs are passed by reserving space on the caller's stack, copying the value into it and passing a pointer to this copy. The callee copies it again to its own stack frame.

### x86 (thiscall)

Arguments: right to left, with this being passed via ECX register (for vararg functions cdecl is being used, with `this` pushed on the stack as the last)

Stack-maintenance: called function pops arguments from the stack

## Reversing in WinDbg

### Collect information about an PE image

`lmvm {module_name}` shows some information about a module, notably the base address:

```
0:009> lmvm notepad
Browse full module list
start             end                 module name
00007ff6`27650000 00007ff6`276c6000   Notepad  C (no symbols)           
    Loaded symbol image file: C:\Program Files\WindowsApps\Microsoft.WindowsNotepad_11.2112.32.0_x64__8wekyb3d8bbwe\Notepad\Notepad.exe
    Image path: C:\Program Files\WindowsApps\Microsoft.WindowsNotepad_11.2112.32.0_x64__8wekyb3d8bbwe\Notepad\Notepad.exe
    Image name: Notepad.exe
    Browse all global symbols  functions  data
    Timestamp:        Fri Feb  4 19:47:08 2022 (61FD74AC)
    CheckSum:         00000000
    ImageSize:        00076000
    File version:     11.2112.32.0
    Product version:  11.2112.32.0
    File flags:       0 (Mask 3F)
    File OS:          4 Unknown Win32
    File type:        1.0 App
    File date:        00000000.00000000
    Translations:     0000.04b0
    Information from resource tables:
```

`!lmi {module_name | base_address}` displays low-level information about a module in a readable format:

```
0:009> !lmi 00007ff6`27650000
Loaded Module Info: [00007ff6`27650000] 
         Module: Notepad
   Base Address: 00007ff627650000
     Image Name: C:\Program Files\WindowsApps\Microsoft.WindowsNotepad_11.2112.32.0_x64__8wekyb3d8bbwe\Notepad\Notepad.exe
   Machine Type: 34404 (X64)
     Time Stamp: 61fd74ac Fri Feb  4 19:47:08 2022
           Size: 76000
       CheckSum: 0
Characteristics: 22  
Debug Data Dirs: Type  Size     VA  Pointer
             CODEVIEW    41, 4f254,   4e654 RSDS - GUID: {A41B5EAD-0A45-4E4F-A353-E105818B8A1A}
               Age: 1, Pdb: D:\a\1\b\Release\x64\Notepad\Notepad.pdb
           VC_FEATURE    14, 4f298,   4e698 [Data not mapped]
                 POGO   400, 4f2ac,   4e6ac [Data not mapped]
                ILTCG     0,     0,       0  [Debug data not mapped]
     Image Type: FILE     - Image read successfully from debugger.
                 C:\Program Files\WindowsApps\Microsoft.WindowsNotepad_11.2112.32.0_x64__8wekyb3d8bbwe\Notepad\Notepad.exe
    Symbol Type: NONE     - PDB not found from symbol search path.
    Load Report: no symbols loaded
```

`!dh {module_name | base_address}` shows information from the PE header

## Use reversing tools

### Ghidra

**Ghidra does not understand full `_NT_SYMBOL_PATH` syntax** and it will parse only the first location from this variable.

When you need to understand the logic in an application, a simple assembly listing might not be enough. There are various tools available in the market that can disassemble and nicely output the assembly code, but my favourite one is [**Ghidra**](https://ghidra-sre.org/), an open-source reverse engineering software released by NSA. It even has a decompiler and supports lots of platforms. The section below contains a set of basic shortcuts to help you find your way around in this tool. 

| Shortcut      | Description       |
| ------------- | ----------------- |
| G             | Go to address |
| L             | Change label |
| Alt+larrow    | Go back |
| ;             | Set comment |
| Ctrl+uarrow   | Previous function |
| Ctrl+darrow   | Next function |
| Middle mouse  | Select a symbol |

Marks:

| Shortcut      | Description       |
| ------------- | ----------------- |
| Ctrl+D        | Set bookmark |
| Ctrl+Alt+B    | Next bookmark |

Other popular shortcuts are listed in [the official Ghidra CheatSheet](https://ghidra-sre.org/CheatSheet.html).

To rebase an image, open the memory window, click on the button with a house icon and type the new base address.

### IDA Freeware

Before Ghidra, another tool I used was the free version of [**IDA**](https://www.hex-rays.com/products/ida/support/download_freeware.shtml). The table below contains some of its shortcuts.

| Shortcut      | Description       |
| ------------- | ----------------- |
| Space         | Switch to graph/assembly |
| Esc           | Go back |
| Ctrl+Enter    | Go forward |
| N             | Rename variable |
| Tab           | Switch to pseudo-code |

Jumps:

| Shortcut      | Description       |
| ------------- | ----------------- |
| Ctrl+P        | Function |
| Ctrl+L        | Symbol |
| Ctrl+S        | Segment |
| Ctrl+E        | Entry point |
| Ctrl+X        | Shows refs to the selected address |
| Ctrl+J        | Shows refs from the selected address |

Marks:

| Shortcut      | Description       |
| ------------- | ----------------- |
| Alt+M         | Create a mark |
| Ctrl+M        | Jump to a mark |

Search:

| Shortcut      | Description       |
| ------------- | ----------------- |
| Alt+T         | Text search |
| Ctrl+T        | Next text search |
| Alt+B         | Binary search |
| Ctrl+B        | Next binary search |
