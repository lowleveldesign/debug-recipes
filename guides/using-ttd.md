---
layout: page
title: Using Time Travel Debugging (TTD)
date: 2024-04-15 08:00:00 +0200
---

{% raw %}

**Table of contents:**

<!-- MarkdownTOC -->

- [Description](#description)
- [Installation](#installation)
- [Collection](#collection)
- [Analysis](#analysis)
    - [Accessing TTD data](#accessing-ttd-data)
    - [Querying debugging events](#querying-debugging-events)
    - [Examining function calls](#examining-function-calls)
    - [Position in TTD trace](#position-in-ttd-trace)
    - [Examining memory access](#examining-memory-access)
- [See also](#see-also)

<!-- /MarkdownTOC -->

## Description

[TTD](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/time-travel-debugging-overview) is a fantastic way to debug application code. After collecting a debug trace, we may query process memory, function calls, going deeper and deeper into the call stacks if necessary, and jump through various process lifetime events.

## Installation

The collector is installed with WinDbgX and we may enable it when starting a WinDbgX debugging session.

Alternatively, we could [install the command-line TTD collector](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-ttd-exe-command-line-util#how-to-download-and-install-the-ttdexe-command-line-utility-preferred-method). The PowerShell script published on the linked site is capable of installing TTD even on systems not supporting the MSIX installations. The command-line tool is probably the best option when collecting TTD traces on server systems. When done, you may uninstall the driver by using the **-cleanup** option.

## Collection

If you have WinDbgX, you may use TTD by checking the "Record with Time Travel Debugging" checkbox when you start a new process or attach to a running one. When you stop the TTD trace in WinDbgX it will terminate the target process (TTD.exe, described later, can detach from a process without killing it).

An alternative to WinDbgX is running the command-line TTD collector. Some usage examples:

```shell
# launch a new winver.exe process and record the trace in C:\logs
ttd.exe -accepteula -out c:\logs winver.exe

# attach and trace the process with ID 1234 and all its newly started children
ttd.exe -accepteula -children -out c:\logs -attach 1234 

# attach and trace the process with ID 1234 to a ring buffer, backed by a trace file of maximum size 1024 MB
ttd.exe -accepteula -ring -maxFile 1024 -out c:\logs -attach 1234

# record a trace of the running and newly started processes, add a timestamp to the trace file names
ttd.exe -accepteula -timestampFilename -out c:\logs -monitor winver.exe
ttd.exe -accepteula -timestampFilename -out c:\logs -monitor app1.exe -monitor app2.exe
```

Analysis
--------

### Accessing TTD data

We can acess TTD objects by querying the TTD property of the session or process objects:

```shell
dx -v @$cursession.TTD
# @$cursession.TTD                
#     HeapLookup       [Returns a vector of heap blocks that contain the provided address: TTD.Utility.HeapLookup(address)]
#     Calls            [Returns call information from the trace for the specified set of methods: TTD.Calls("module!method1", "module!method2", ...) For example: dx @$cursession.TTD.Calls("user32!SendMessageA")]
#     Memory           [Returns memory access information for specified address range: TTD.Memory(startAddress, endAddress [, "rwec"])]
#     MemoryForPositionRange [Returns memory access information for specified address range and position range: TTD.MemoryForPositionRange(startAddress, endAddress [, "rwec"], minPosition, maxPosition)]
#     PinObjectPosition [Pins an object to the given time position: TTD.PinObjectPosition(obj, pos)]
#     AsyncQueryEnabled : false
#     Data             : Normalized data sources based on the contents of the time travel trace
#     Utility          : Methods that can be useful when analyzing time travel traces
#     ToDisplayString  [ToDisplayString([FormatSpecifier]) - Method which converts the object to its display string representation according to an optional format specifier]

dx -v @$curprocess.TTD
# @$curprocess.TTD                
#     Index           
#     Threads         
#     Events          
#     DebugOutput     
#     Lifetime         : [66:0, 118A2:0]
#     DefaultMemoryPolicy : GloballyAggressive
#     SetPosition      [Sets the debugger to point to the given position on this process.]
#     GatherMemoryUse  [0]
#     RecordClients  
```

### Querying debugging events

The **@$curprocess.Events** collection contains [TTD Event objects](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-event-objects). We can use the group query to learn what type of events we have in our trace:

```shell
dx -g @$curprocess.TTD.Events.GroupBy(ev => ev.Type).Select(g => new { Type = g.First().Type, Count = g.Count() })
# ===========================================================
# =                         = (+) Type            = Count   =
# ===========================================================
# = ["ModuleLoaded"]        - ModuleLoaded        - 0x23    =
# = ["ThreadCreated"]       - ThreadCreated       - 0x9     =
# = ["ThreadTerminated"]    - ThreadTerminated    - 0x9     =
# = ["Exception"]           - Exception           - 0x4     =
# = ["ModuleUnloaded"]      - ModuleUnloaded      - 0x23    =
# ===========================================================
```

Next, we may filter the list for events that interest us, for example, to extract the first [TTD Exception object](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-exception-objects), we may run the following query:

```shell
dx @$curprocess.TTD.Events.Where(ev => ev.Type == "Exception").Select(ev => ev.Exception).First()
# @$curprocess.TTD.Events.Where(ev => ev.Type == "Exception").Select(ev => ev.Exception).First()                 : Exception 0xE0434352 of type Software at PC: 0X7FF91E0842D0
#     Position         : 7E7C:0 [Time Travel]
#     Type             : Software
#     ProgramCounter   : 0x7ff91e0842d0
#     Code             : 0xe0434352
#     Flags            : 0x1
#     RecordAddress    : 0x0
# ...
```

### Examining function calls

The **Calls** method of the **TTD** objects allows us to query [function calls](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-calls-objects) made in the trace. We may use either an address or a symbol name (even with wildcards) as a parameter to the Calls method:

```shell
x OLEAUT32!IDispatch_Invoke_Proxy
# 75a13bf0          OLEAUT32!IDispatch_Invoke_Proxy (void)

# we may use the address of a function
dx @$cursession.TTD.Calls(0x75a13bf0).Count()
# @$cursession.TTD.Calls(0x75a13bf0).Count() : 0x6a18

# or its symbolic name
dx @$cursession.TTD.Calls("OLEAUT32!IDispatch_Invoke_Proxy").Count()
# @$cursession.TTD.Calls("OLEAUT32!IDispatch_Invoke_Proxy").Count() : 0x6a18
```

Thanks to **wildcards**, we can easily get statistics on function calls from a given module or modules (this call might take some time for longer traces):

```shell
# Show the number of calls made to functions with names starting from NdrClient in the rpcrt4 module
dx -g @$cursession.TTD.Calls("rpcrt4!NdrClient*").GroupBy(c => c.Function).Select(g => new { Function = g.First().Function, Count = g.Count() })
# ==============================================================================
# =                                   = (+) Function                  = Count  =
# ==============================================================================
# = ["RPCRT4!NdrClientCall2"]         - RPCRT4!NdrClientCall2         - 0x5    =
# = ["RPCRT4!NdrClientInitialize"]    - RPCRT4!NdrClientInitialize    - 0x5    =
# = ["RPCRT4!NdrClientCall3"]         - RPCRT4!NdrClientCall3         - 0x8    =
# = ["RPCRT4!NdrClientZeroOut"]       - RPCRT4!NdrClientZeroOut       - 0x1    =
# ==============================================================================
```

**TimeStart** shows the position of a call in a trace and we may use it to jump between different places in the trace. **SystemTimeStart** shows the clock time of a given call:

```shell
dx -g @$cursession.TTD.Calls("user32!DialogBox*").Select(c => new { Function = c.Function, TimeStart = c.TimeStart, SystemTimeStart = c.SystemTimeStart })
# ==============================================================================================================
# =          = (+) Function                         = (+) TimeStart = (+) SystemTimeStart                      =
# ==============================================================================================================
# = [0x0]    - USER32!DialogBoxIndirectParamW       - 62E569:57     - Friday, February 2, 2024 16:03:39.391    =
# = [0x1]    - USER32!DialogBoxIndirectParamAorW    - 62E569:5C     - Friday, February 2, 2024 16:03:39.391    =
# = [0x2]    - USER32!DialogBox2                    - 631C23:102    - Friday, February 2, 2024 16:03:39.791    =
```

Each function call has a **Parameters** property that gives us access to the function parameters (without private symbols, we can access the first four parameters) of a call:

```shell
# Check which LastErrors were set during the call
dx -h @$cursession.TTD.Calls("ntdll!RtlSetLastWin32Error").Select(c => c.Parameters[0]).Distinct()
# @$cursession.TTD.Calls("ntdll!RtlSetLastWin32Error").Select(c => c.Parameters[0]).Distinct()                
#     [0x0]            : 0xbb
#     [0x1]            : 0x57
#     [0x2]            : 0x0
#     [0x3]            : 0x7e
#     [0x4]            : 0x3f0

# Find LastError calls when LastError is not zero
dx -g @$cursession.TTD.Calls("ntdll!RtlSetLastWin32Error").Where(c => c.Parameters[0] != 0).Select(c => new { TimeStart = c.TimeStart, Error = c.Parameters[0] })
# =========================================
# =           = (+) TimeStart = Error     =
# =========================================
# = [0x0]     - 725:3B        - 0xbb      =
# = [0x1]     - 725:3D6       - 0x57      =
# = [0x2]     - 725:4AA       - 0x57      =
# = [0x3]     - 725:EF0       - 0xbb      =
# ....
```

### Position in TTD trace

The **[TTD Position object](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-position-objects)** describes a moment in time in the trace. Its **SeekTo** method allows us to jump to this moment and analyze the process state:

```shell
dx -r1 @$create("Debugger.Models.TTD.Position", 34395, 1278)
# @$create("Debugger.Models.TTD.Position", 34395, 1278)                 : 865B:4FE [Time Travel]
#     Sequence         : 0x865b
#     Steps            : 0x4fe
#     SeekTo           [Method which seeks to time position]
#     ToSystemTime     [Method which obtains the approximate system time at a given position]

dx -s @$create("Debugger.Models.TTD.Position", 34395, 1278).SeekTo()
# (1d30.1b94): Break instruction exception - code 80000003 (first/second chance not available)
# Time Travel Position: 865B:4FE
```

If we are troubleshooting an issue spanning multiple processes, we may simultaneously record TTD traces for all of them, and later, use the TTD Position objects to set the same moment in time in all the traces. It is a very effective technique when debugging locking issues.

### Examining memory access

The **Memory** and **MemoryForPositionRange** methods of the TTD Session object return [TTD Memory objects](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-memory-objects) describing various operations on the memory. For example, the command below shows all the changes to the global GcInProgress variable in a .NET application:

```shell
dx -g @$cursession.TTD.Memory(&coreclr!g_pGCHeap->GcInProgress, &coreclr!g_pGCHeap->GcInProgress+4, "w")
# ==============================================================================================================================================================================================================================================================================================================
# =          = (+) EventType = (+) ThreadId = (+) UniqueThreadId = (+) TimeStart = (+) TimeEnd = (+) AccessType = (+) IP            = (+) Address       = (+) Size = (+) Value        = (+) OverwrittenValue = (+) SystemTimeStart                            = (+) SystemTimeEnd                              =
# ==============================================================================================================================================================================================================================================================================================================
# = [0x0]    - 0x1           - 0x2c80       - 0x2                - C79:58C       - C79:58C     - Write          - 0x7ff8fdbce0ee    - 0x7ff8fe00caf0    - 0x8      - 0x2b4800c9bc0    - 0x0                  - poniedziałek, 15 kwietnia 2024 10:14:18.475    - poniedziałek, 15 kwietnia 2024 10:14:18.475    =
# = [0x1]    - 0x1           - 0x2c80       - 0x2                - 3AF4:5A       - 3AF4:5A     - Write          - 0x7ff8fdcdacc3    - 0x7ff8fe00cae8    - 0x4      - 0x1              - 0x0                  - poniedziałek, 15 kwietnia 2024 10:14:20.896    - poniedziałek, 15 kwietnia 2024 10:14:20.896    =
# = [0x2]    - 0x1           - 0x2c80       - 0x2                - 3B26:E6C      - 3B26:E6C    - Write          - 0x7ff8fdcdacc3    - 0x7ff8fe00cae8    - 0x4      - 0x0              - 0x1                  - poniedziałek, 15 kwietnia 2024 10:14:20.910    - poniedziałek, 15 kwietnia 2024 10:14:20.910    =
# = [0x3]    - 0x1           - 0x2c80       - 0x2                - 87DF:5A       - 87DF:5A     - Write          - 0x7ff8fdcdacc3    - 0x7ff8fe00cae8    - 0x4      - 0x1              - 0x0                  - poniedziałek, 15 kwietnia 2024 10:14:24.539    - poniedziałek, 15 kwietnia 2024 10:14:24.539    =
# = [0x4]    - 0x1           - 0x2c80       - 0x2                - 880C:50C      - 880C:50C    - Write          - 0x7ff8fdcdacc3    - 0x7ff8fe00cae8    - 0x4      - 0x0              - 0x1                  - poniedziałek, 15 kwietnia 2024 10:14:24.548    - poniedziałek, 15 kwietnia 2024 10:14:24.548    =
# = [0x5]    - 0x1           - 0x2c80       - 0x2                - 889F:5A       - 889F:5A     - Write          - 0x7ff8fdcdacc3    - 0x7ff8fe00cae8    - 0x4      - 0x1              - 0x0                  - poniedziałek, 15 kwietnia 2024 10:14:25.769    - poniedziałek, 15 kwietnia 2024 10:14:25.769    =
# ==============================================================================================================================================================================================================================================================================================================
```

The **MemoryForPositionRange** method allows us to additionally limit memory access queries to a specific time-range. It makes sense to use this method for scope-based addresses, such as function parameters or local variables. Below, you may see an example of a query when we list all the places in the CreateFileW function that read the file name (the first argument to the function):

```shell
dx -s @$call = @$cursession.TTD.Calls("kernelbase!CreateFileW").First()
dx -g @$cursession.TTD.MemoryForPositionRange(@$call.Parameters[0], @$call.Parameters[0] + sizeof(wchar_t), "r", @$call.TimeStart, @$call.TimeEnd)
# ======================================================================================================================================================
# =          = (+) Position = ThreadId  = UniqueThreadId = Address          = IP                = Size   = AccessType = Value               = (+) Data =
# ======================================================================================================================================================
# = [0x0]    - AB:1981      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04a836    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x1]    - AB:1AD4      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04b6e1    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x2]    - AB:1C27      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04b796    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x3]    - AB:1C5E      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04bca9    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x4]    - AB:1CC8      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04caa8    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x5]    - AB:1CCA      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04caae    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x6]    - AB:1CCF      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04cabe    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x7]    - AB:1E23      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04bd5a    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x8]    - AB:1E2A      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04bd7b    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0x9]    - AB:1E5C      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04be56    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# = [0xa]    - AB:1E68      - 0x2018    - 0x2            - 0x236011c33c0    - 0x7ff91e04be7a    - 0x2    - Read       - 0x55005c003a0043    - {...}    =
# ======================================================================================================================================================
```

See also
--------

- [Some Time Travel musings](https://blahcat.github.io/posts/2018/11/02/some-time-travel-musings.html) - a great post by Axel Souchet presenting various techniques for analysing TTD traces

{% endraw %}
