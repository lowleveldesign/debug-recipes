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

## Analysis

TTD is one of the session object properties which we can query. Axel Souchet in [this post](https://blahcat.github.io/posts/2018/11/02/some-time-travel-musings.html) presents some interesting TTD queries. I list some of them below, but I recommend checking the article to learn more.

```
0:000> dx @$cursession.TTD

0:000> dx @$cursession.TTD.Calls("user32!GetMessage*")
@$cursession.TTD.Calls("user32!GetMessage*").Count() : 0x1e8

// Isolate the address(es) newly allocated as RWX
0:000> dx @$cursession.TTD.Calls("Kernel*!VirtualAlloc*").Where( f => f.Parameters[3] == 0x40 ).Select( f => new {Address : f.ReturnValue } )

// Time-Travel to when the 1st byte is executed
0:000> dx @$cursession.TTD.Memory(0xAddressFromAbove, 0xAddressFromAbove+1, "e")[0].TimeStart.SeekTo()
```

{% endraw %}
