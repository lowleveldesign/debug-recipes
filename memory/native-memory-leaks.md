
Diagnosing native memory leaks
==============================

Stressing application (Application Verifier)
--------------------------------------------

Based on <http://randomascii.wordpress.com/2011/12/07/increased-reliability-through-more-crashes/>

FIXME

Memory commands in WinDbg
-------------------------

The **dda, ddp, ddu, dpa, dpp, dpu, dqa, dqp, and dqu** (where dp uses system pointer size) commands display the pointer at the specified location, dereference that pointer, and then display the memory at the resulting location in a variety of formats. As an argument for each of these commands you need to pass a memory range. eg:

    0:001> !teb
    TEB at 7f4fe000
        ...
        StackBase:            00b80000
        StackLimit:           00b7c000
        ...
    0:001> kd
    00b7f8c4  00000000
    00b7f8c8  7737ad34 ntdll!DbgUiRemoteBreakin+0x39
    00b7f8cc  906ef038
    00b7f8d0  00000000
    00b7f8d4  00000000
    00b7f8d8  00000000
    00b7f8dc  00b7f8cc
    00b7f8e0  00000000
    00b7f8e4  00b7f934
    00b7f8e8  77375bc1 ntdll!_except_handler4
    00b7f8ec  e7eea59c
    00b7f8f0  00000000
    00b7f8f4  00b7f900
    00b7f8f8  75df1866 KERNEL32!BaseThreadInitThunk+0xe
    00b7f8fc  00000000
    00b7f900  00b7f944
    00b7f904  772d68f1 ntdll!__RtlUserThreadStart+0x4a
    0:001> dps 00b7f8c4 00b7f904
    00b7f8c4  00000000
    00b7f8c8  7737ad34 ntdll!DbgUiRemoteBreakin+0x39
    00b7f8cc  906ef038
    00b7f8d0  00000000
    00b7f8d4  00000000
    00b7f8d8  00000000
    00b7f8dc  00b7f8cc
    00b7f8e0  00000000
    00b7f8e4  00b7f934
    00b7f8e8  77375bc1 ntdll!_except_handler4
    00b7f8ec  e7eea59c
    00b7f8f0  00000000
    00b7f8f4  00b7f900
    00b7f8f8  75df1866 KERNEL32!BaseThreadInitThunk+0xe
    00b7f8fc  00000000
    00b7f900  00b7f944
    00b7f904  772d68f1 ntdll!__RtlUserThreadStart+0x4a

Another command is **!address** which shows information about the process address space:

    !address Address
    !address -summary
    !address [-f:F1,F2,...] {[-o:{csv | tsv | 1}] | [-c:"Command"]}

The `-summary` option is very interesting as it shows aggregated information about process memory blocks.

To display virtual memory protection information use the **!vprot** command:

    !vprot [Address]

    0:000> !vprot 30c191c
    BaseAddress: 030c1000
    AllocationBase: 030c0000
    AllocationProtect: 00000080 PAGE_EXECUTE_WRITECOPY
    RegionSize: 00011000
    State: 00001000 MEM_COMMIT
    Protect: 00000010 PAGE_EXECUTE
    Type: 01000000 MEM_IMAGE

For memory mapped files in order to find the backing disk file use **!mapped_file** command:

    !mapped_file Address

    0:000> !mapped_file 4121ec
    Mapped file name for 004121ec: '\Device\HarddiskVolume2\CODE\TimeTest\Debug\TimeTest.exe'

### Get memory usage ###

To get information on Windows memory usage use **!memusage** command:

    0: kd> !memusage
    loading PFN database
    loading (100% complete)
    Compiling memory usage data (99% Complete).
    Zeroed:    414 (  1656 kb)
                   Free:      2 (     8 kb)
    Standby: 864091 (3456364 kb)
    Modified:    560 (  2240 kb)
        ModifiedNoWrite:     30 (   120 kb)
    Active/Valid: 182954 (731816 kb)
             Transition:      2 (     8 kb)
                    Bad:      0 (     0 kb)
                Unknown:      0 (     0 kb)
    TOTAL: 1048053 (4192212 kb)

Heap
----

FIXME

Application Verifier (appverif.exe) or user-mode dump heap (umdh.exe) tool.

### Trace leaks using traces windbg extension ###

Based on <http://blogs.microsoft.co.il/blogs/sasha/archive/2013/09/10/announcing-tracer-a-generic-way-to-track-resource-usage-and-leaks.aspx?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+sashag+%28All+Your+Base+Are+Belong+To+Us%29>

!traceopen
!traceclose
!tracedisplay
FIXME

### Collect snapshots and compare them (umdh) ###

The following command creates a first log (assuming that the host.exe application has been started):

    > umdh.exe -pn:host.exe -f:log1.txt

then we need to collect the second log:

    > umdh.exe -pn:host.exe -f:log2.txt

and finally we can find allocations that occured in the meantime using the same umdh.exe tool:

    > umdh.exe log1.txt log2.txt
    Warning: _NT_SYMBOL_PATH variable is not defined. Will be set to %windir%\symbols.
    DBGHELP: host - private symbols & lines
             c:\book\code\chapter_08\HeapLeak\ExeHeapLeak\objfre_win7_x86\i386\host.pdb
    DBGHELP: ntdll - export symbols
    ...
    +   27000 ( 27000 -     0)     9c allocs        BackTrace1
    +      9c (    9c -     0)      BackTrace1      allocations
            ntdll!RtlLogStackBackTrace+00000007
            ntdll!wcsnicmp+000001E4
            host!MemoryAlloc+00000017
            host!CMainApp::MainHR+00000018
            kernel32!BaseThreadInitThunk+00000012
            ntdll!RtlInitializeExceptionChain+000000EF
            ntdll!RtlInitializeExceptionChain+000000C2
    Total increase ==  27000 requested +    9c0 overhead =  279c0

Umdh uses symbols that are defined in the `_NT_SYMBOL_PATH` so remember to set it first.

### List all heaps in a process (windbg) ###

    0:000> !heap 0
    Index   Address  Name      Debugging options enabled
      1:   bd4aef0000
        Segment at 000000bd4aef0000 to 000000bd4afef000 (0000b000 bytes committed)
      2:   bd4ac70000
        Segment at 000000bd4ac70000 to 000000bd4ac80000 (00001000 bytes committed)

### Check heap statistics (windbg) ###

To display summary information about each heap we can use `-s` switch:

    0:000> !heap -s
    NtGlobalFlag enables following debugging aids for new heaps:
        tail checking
        free checking
        validate parameters
    LFH Key                   : 0x000000454b25cb0c
    Termination on corruption : ENABLED
              Heap     Flags   Reserv  Commit  Virt   Free  List   UCR  Virt  Lock  Fast
                                (k)     (k)    (k)     (k) length      blocks cont. heap
    -------------------------------------------------------------------------------------
    000000bd4aef0000 40000062    1020     44   1020      1    12     1    0      0
    000000bd4ac70000 40008060      64      4     64      2     1     1    0      0
    -------------------------------------------------------------------------------------

To display usage statistics you may use `-stat` switch:

    0:000> !heap -stat -h 000000bd4aef0000
     heap @ 000000bd4aef0000
    group-by: TOTSIZE max-display: 20
        size     #blocks     total     ( %) (percent of total busy bytes)
        28ca 1 - 28ca  (30.72)
        110 13 - 1430  (15.21)
        1008 1 - 1008  (12.08)
        400 2 - 800  (6.03)
        50 16 - 6e0  (5.18)
        6ca 1 - 6ca  (5.11)
        40 16 - 580  (4.14)
        20 2a - 540  (3.95)
        238 1 - 238  (1.67)
        200 1 - 200  (1.51)
        42 6 - 18c  (1.17)
        150 1 - 150  (0.99)
        a8 2 - 150  (0.99)
        130 1 - 130  (0.89)
        120 1 - 120  (0.85)
        108 1 - 108  (0.78)
        102 1 - 102  (0.76)
        100 1 - 100  (0.75)
        fa 1 - fa  (0.74)
        f8 1 - f8  (0.73)

### Filter heap content (windbg) ###

Using `!heap -flt` command we can filter the heap content either by size or size range. The following command will display allocations of size 28ca:

    0:000> !heap -flt s 0x28ca
        _HEAP @ bd4aef0000
                  HEAP_ENTRY Size Prev Flags            UserPtr UserSize - state
            000000bd4aef08a0 0290 0000  [00]   000000bd4aef08b0    028ca - (busy)
        _HEAP @ bd4ac70000


### Display C++ heap objects in WinDbg ###

Based on <http://blogs.microsoft.co.il/blogs/sasha/archive/2013/08/05/searching-and-displaying-c-heap-objects-in-windbg.aspx>

Using pykd windbg extension... FIXME

Debugging Windows memory problems
------------------------------

### Leaking handles ###

If you observe a growing number of handles in a process and growing kernel memory in Paged Pool and NP Pool then you may witness a handles leak. To diagnose this kind of problems you may use `!htrace` command:

    !htrace -enable
    !htrace -disable
    !htrace -snapshot
    !htrace -diff

This command informs kernel to track more information about handles used by a given process (including the creation call stack).

To read a given handle you may use the `!handle <handle-addr>` command.

Links
-----

- [Desktop Heap Exhaustion / Hard Bugs](http://geekswithblogs.net/akraus1/archive/2014/02/04/155370.aspx)
- [Analyzing heap objects with mona.py](https://www.corelan.be/index.php/2014/08/16/analyzing-heap-objects-with-mona-py/)
- [Advanced Memory Dump Debugging - and looking for handle references](http://geekswithblogs.net/akraus1/archive/2014/09/29/159441.aspx)
- [ETW Heap Tracing–Every Allocation Recorded](https://randomascii.wordpress.com/2015/04/27/etw-heap-tracingevery-allocation-recorded/)

Tools
-----

- [Visual Leak Detector for Visual C++ 2008-2015](http://vld.codeplex.com/)
- [UMDH.exe](https://msdn.microsoft.com/en-us/library/windows/hardware/ff558947%28v=vs.85%29.aspx)

