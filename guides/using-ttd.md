---
layout: page
title: Using Time Travel Debugging (TTD)
date: 2024-01-01 08:00:00 +0200
---

{% raw %}

*-- WORK IN PROGRESS --*

**Table of contents:**

<!-- MarkdownTOC -->

- [Description](#description)
- [Installation](#installation)
- [Collection](#collection)
- [Analysis](#analysis)
    - [Analysing function calls](#analysing-function-calls)
    - [Analysing memory access](#analysing-memory-access)

<!-- /MarkdownTOC -->

## Description

[TTD](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/time-travel-debugging-overview), added in WinDbg Preview, is a fantastic way to debug application code. After collecting a debug trace, we may examine it as much as we need to, going deeper and deeper into the call stacks.

## Installation

The collector is installed with WinDbgX and we may enable it when starting a WinDbgX debugging session.

Alternatively, we could [install the command-line TTD collector](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-ttd-exe-command-line-util#how-to-download-and-install-the-ttdexe-command-line-utility-preferred-method). The PowerShell script published on the linked site is capable of installing TTD even on systems not supporting the MSIX installations. The command-line tool is probably the best option when collecting TTD traces on server systems. When done, you may uninstall the driver by using the **-cleanup** option.

## Collection

If you have WinDbgX, you may use TTD by checking the "Record with Time Travel Debugging" checkbox when you start a new process or attach to a running one. When you stop the TTD trace in WinDbgX it will terminate the target process (TTD.exe, described later, can detach from a process without killing it).

An alternative to WinDbgX is running the command-line TTD collector. Some usage examples:

```shell
# launch a new winver.exe process and record the trace in C:\logs
ttd.exe -accepteula winver.exe -out c:\logs

# attach and trace the process with ID 1234 and all its newly started children
ttd.exe -accepteula -attach 1234 -children -out c:\logs

# attach and trace the process with ID 1234 to a ring buffer, backed by a trace file of maximum size 1024 MB
ttd.exe -accepteula -attach 1234 -ring -maxFile 1024 -out c:\logs

# record a trace of the running and newly started processes, add a timestamp to the trace file names
ttd.exe -accepteula -monitor winver.exe -timestampFilename -out c:\logs
ttd.exe -accepteula -monitor app1.exe -monitor app2.exe -timestampFilename -out c:\logs
```

Analysis
--------

TTD is one of the session object properties which we can query. Axel Souchet in [this post](https://blahcat.github.io/posts/2018/11/02/some-time-travel-musings.html) presents some interesting TTD queries. 

```shell
dx @$cursession.TTD
```

### Analysing function calls

The **Calls** method of the **TTD** objects allows us to query function calls made in the trace. We may use either an address or a symbol name (even with wildcards) as a parameter to the Calls method. Some example TTD.Calls queries:

```shell
# Check the number of calls to the OLEAUT32!IDispatch_Invoke_Proxy function
x OLEAUT32!IDispatch_Invoke_Proxy
# 75a13bf0          OLEAUT32!IDispatch_Invoke_Proxy (void)
dx @$cursession.TTD.Calls(0x75a13bf0).Count()
# @$cursession.TTD.Calls(0x75a13bf0).Count() : 0x6a18
dx @$cursession.TTD.Calls("OLEAUT32!IDispatch_Invoke_Proxy").Count()
# @$cursession.TTD.Calls("OLEAUT32!IDispatch_Invoke_Proxy").Count() : 0x6a18

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

# Isolate the address(es) newly allocated as RWX
dx @$cursession.TTD.Calls("Kernel*!VirtualAlloc*").Where( f => f.Parameters[3] == 0x40 ).Select( f => new {Address : f.ReturnValue } )

# Check what LastErrors were set during the call
dx -h @$cursession.TTD.Calls("ntdll!RtlSetLastWin32Error").Select(c => c.Parameters[0]).Distinct()
# @$cursession.TTD.Calls("ntdll!RtlSetLastWin32Error").Select(c => c.Parameters[0]).Distinct()                
#     [0x0]            : 0xbb
#     [0x1]            : 0x57
#     [0x2]            : 0x0
#     [0x3]            : 0x7e
#     [0x4]            : 0x3f0

# Find LastError calls with the passed error code
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

### Analysing memory access

```shell
# Time-Travel to when the 1st byte is executed
dx @$cursession.TTD.Memory(0xAddressFromAbove, 0xAddressFromAbove+1, "e")[0].TimeStart.SeekTo()
```

{% endraw %}
