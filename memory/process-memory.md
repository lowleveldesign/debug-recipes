
Working with process memory
===========================

Analysing memory addresses
--------------------------

### Find information about a given address ###

The **!address** command in windbg is great when it comes to displaying information about a memory.

Show process or target memory summary: `!address -summary`

Show only memory occupied by stacks and images: `!address -f:Stack,Image`

Show information about a specific address, eg.:

```
0:004> !address 000000ec`3cabf66c

Usage: Stack
Base Address: 000000ec3caaf000 End Address: 000000ec3cac0000
Region Size: 0000000000011000 ( 68.000 kB) State: 00001000 MEM_COMMIT Protect: 00000004 PAGE_READWRITE Type: 00020000 MEM_PRIVATE Allocation Base: 000000ec3ca40000
Allocation Protect: 00000004 PAGE_READWRITE
More info: ~3k

Content source: 1 (target), length: 994
```

Analysing memory content
------------------------

### Search in memory ###

The **s** command is used to search through memory content. The syntax is `s [-Type] Range Pattern`, where type might be: b (byte), w (word), d (dword), q (qword), a (ASCII), u (Unicode).

Additionally you may search for all memory containing prinatable ASCII (`s-sa [Range]`) or Unicode (`s-su [Range]`) strings, eg. `s-sa 7ffb``2ec10000 7ffb``2ed5e000`.

