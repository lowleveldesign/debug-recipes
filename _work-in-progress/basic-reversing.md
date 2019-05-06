
# Basic reversing

## Collect basic information about the executable (Windows)

**Dumpbin** (part of the Windows SDK) is a command line tool which dumps various information about the executable:

- **dumpbin /all /disasm:nobytes /out:file.asm file.dll** - dump all PE headers and disassemble the .text sections
- **dumpbin /exports file.dll** - dump information about the exported methods in the PE file

## Debugging an application

### Dump assembly

### Calling conventions

## Reversing tools

### Ghidra

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
