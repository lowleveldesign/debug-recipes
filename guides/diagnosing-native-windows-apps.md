---
layout: page
title: Diagnosing native Windows applications
date: 2025-05-25 08:00:00 +0200
---

{% raw %}

**Table of contents:**

<!-- MarkdownTOC -->

- [Debugging process execution](#debugging-process-execution)
- [Collecting memory dumps on errors](#collecting-memory-dumps-on-errors)
    - [Using procdump](#using-procdump)
    - [Using Windows Error Reporting \(WER\)](#using-windows-error-reporting-wer)
    - [Automatic dump collection using AeDebug registry key](#automatic-dump-collection-using-aedebug-registry-key)
- [Diagnosing waits or high CPU usage](#diagnosing-waits-or-high-cpu-usage)
    - [Collecting ETW trace](#collecting-etw-trace)
    - [Anaysing the collected traces](#anaysing-the-collected-traces)
- [Diagnosing issues with DLL loading](#diagnosing-issues-with-dll-loading)
- [Diagnosing window functions \(user32\)](#diagnosing-window-functions-user32)

<!-- /MarkdownTOC -->

Debugging process execution
---------------------------

Please check [the WinDbg guide](/guides/windbg) where I describe various troubleshooting commands in WinDbg, along with Time Travel Debugging.

Collecting memory dumps on errors
---------------------------------

### Using procdump

My preferred tool to collect memory dumps is **[procdump](https://learn.microsoft.com/en-us/sysinternals/downloads/procdump)**.

It is often a good way to start diagnosing errors by observing 1st chance exceptions occurring in a process. At this point we don't want to collect any dumps, only logs. We may achieve this by specyfing a non-existing exception name in the filter command, for example:

```
C:\Utils> procdump -e 1 -f "DoesNotExist" 8012
...

CLR Version: v4.0.30319

[09:03:27] Exception: E0434F4D.System.NullReferenceException ("Object reference not set to an instance of an object.")
[09:03:28] Exception: E0434F4D.System.NullReferenceException ("Object reference not set to an instance of an object.")
```

We may also observe the logs in procmon. In order to see the procdump log events in **procmon** remember to add procdump.exe and procdump64.exe to the accepted process names in procmon filters.

To create a full memory dump when `NullReferenceException` occurs use the following command:

```
procdump -ma -e 1 -f "E0434F4D.System.NullReferenceException" 8012
```

From some time procdump uses a managed debugger engine when attaching to .NET Framework processes. This is great because we can filter exceptions based on their managed names. Unfortunately, that works only for 1st chance exceptions (at least for .NET 4.0). 2nd chance exceptions are raised out of the .NET Framework and must be handled by a native debugger. Starting from .NET 4.0 it is no longer possible to attach both managed and native engine to the same process. Thus, if we want to make a dump on the 2nd chance exception for a .NET application, we need to use the **-g** option in order to force procdump to use the native engine.

### Using Windows Error Reporting (WER)

By default WER takes dump only when necessary, but this behavior can be configured and we can force WER to always create a dump by modifying `HKLM\Software\Microsoft\Windows\Windows Error Reporting\ForceQueue=1` or (`HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting\ForceQueue=1`). The reports are usually saved at `%LocalAppData%\Microsoft\Windows\WER`, in two directories: `ReportArchive`, when a server is available or `ReportQueue`, when the server is unavailable.  If you want to keep the data locally, just set the server to a non-existing machine (for example, `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\CorporateWERServer=NonExistingServer`). For **system processes** you need to look at `C:\ProgramData\Microsoft\Windows\WER`. In Windows 2003 Server R2 Error Reporting stores errors in the signed-in user's directory (for example, `C:\Documents and Settings\me\Local Settings\Application Data\PCHealth\ErrorRep`).

Starting with Windows Server 2008 and Windows Vista with Service Pack 1 (SP1), Windows Error Reporting can be configured to [collect full memory dumps on application crash](https://learn.microsoft.com/en-us/windows/win32/wer/collecting-user-mode-dumps). The registry key enabling this behavior is `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\Windows Error Reporting\LocalDumps`. An example configuration for saving full-memory dumps to the %SYSTEMDRIVE%\dumps folder when the test.exe application fails looks as follows:

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps]

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\test.exe]
"DumpFolder"=hex(2):25,00,53,00,59,00,53,00,54,00,45,00,4d,00,44,00,52,00,49,\
  00,56,00,45,00,25,00,5c,00,64,00,75,00,6d,00,70,00,73,00,00,00
"DumpType"=dword:00000002
```

With the help of [the WER API](https://learn.microsoft.com/en-us/windows/win32/wer/wer-reference), you may also force WER reports in your custom application or even
[register a custom crash handler](https://minidump.net/windows-error-reporting/).

To **completely disable WER**, create a DWORD Value under the `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting` key, named `Disabled` and set its value to `1`. For 32-bit apps use the `HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\Windows Error Reporting` key.

### Automatic dump collection using AeDebug registry key

There is a special [AeDebug](https://learn.microsoft.com/en-us/windows/win32/debug/configuring-automatic-debugging) key in the registry defining what should happen when an unhandled exception occurs in an application. You may find it under the `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion` key (or `HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion` for 32-bit apps). Its important value keys include:

- `Debugger` : REG_SZ - application which will be called to handle the problematic process (example value: `procdump.exe -accepteula -j "c:\dumps" %ld %ld %p`), the first %ld parameter is replaced with the process ID and the second with the event handle
- `Auto` : REG_SZ - defines if the debugger runs automatically, without prompting the user (example value: 1)
- `UserDebuggerHotKey` : REG_DWORD - not sure, but it looks it enables the Debug button on the exception handling message box (example value: 1)

To set **WinDbg** as your default AeDebug debugger, run `windbg -I`. After running this command, WinDbg will launch on application crashes. You may also automate WinDbg to create a memory dump and then allow process to terminate, for example: `windbg -c ".dump /ma /u c:\dumps\crash.dmp; qd" -p %ld -e %ld -g`.

My favourite tool to use as the automatic debugger is **procdump**. The command line to install it is `procdump -mp -i c:\dumps`, where c:\dumps is the folder where I would like to store the dumps of crashing apps.

Diagnosing waits or high CPU usage
----------------------------------

There are two ways of tracing CPU time. We could either use CPU sampling or Thread Time profiling. CPU sampling is about collecting samples in intervals: each CPU sample contains an instruction pointer to the currently executing code. Thus, this technique is excellent when diagnosing high CPU usage of an application. It won't work for analyzing waits in the applications. For such scenarios, we should rely on Thread Time profiling. It uses the system scheduler/dispatcher events to get detailed information about application CPU time. When combined with CPU sampling, it is the best non-invasive profiling solution.

### Collecting ETW trace

We may use **PerfView** or **wpr.exe** to collect CPU samples and Thread Time events.

When collecting CPU samples, PerfView relies on Profile events coming from the Kernel ETW provider which has very low impact on the system overall performance. An example command to start the CPU sampling:

```shell
perfview collect -NoGui -KernelEvents:Profile,ImageLoad,Process,Thread -ClrEvents:JITSymbols cpu-collect.etl
```

Alternatively, you may use the Collect dialog. Make sure the Cpu Samples checkbox is selected.

To collect Thread Time events, you may use the following command:

```shell
perfview collect -NoGui -ThreadTime thread-time-collect.etl
```

The Collect dialog has also the Thread Time checkbox.

### Anaysing the collected traces

For analyzing **CPU Samples**, use the **CPU Stacks** view. Always check the number of samples if it corresponds to the tracing time (CPU sampling works when we have enough events). If necessary, zoom into the interesting period using a histogram (select the time and press Alt + R). Checking the **By Name** tab could be enough to find the method responsible for the high CPU Usage (look at the inclusive time and make sure you use correct grouping patterns).

When analyzing waits in an application, we should use the **Thread Time Stacks** views. The default one, **with StartStop activities**, tries to group the tasks under activities and helps diagnose application activities, such as HTTP requests or database queries. Remember that the exclusive time in the activities view is a sum of all the child tasks. The thread under the activity is the thread on which the task started, not necessarily the one on which it continued. The **with ReadyThread** view can help when we are looking for thread interactions. For example, we want to find the thread that released a lock on which a given thread was waiting. The **Thread Time Stacks** view (with no grouping) is the best one to visualize the application's sequence of actions. Expanding thread nodes in the CallTree could take lots of time, so make sure you use other events (for example, from the Events view) to set the time ranges. As usual, check the grouping patterns.

Diagnosing issues with DLL loading
----------------------------------

An invaluable source of information when dealing with DLL loading issues are Windows Loader snaps. Those are detailed logs of the steps that Windows Loader takes to resolve the application library dependencies. They are one of the available Global Flags that we can set for an executable, so we may use the **gflags.exe** tool to enable them.

![gflags - loader snaps](/assets/img/gflags-loader-snaps.png)

Alternatively, you may modify the process IFEO registry key, for example:

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\winver.exe]
"GlobalFlag"=dword:000000002
```

Once enabled, you need to start the failing application under a debugger and the Loader logs should appear in the debug output.

Alternatively, you may collect a procmon or ETW trace and search for any failure in the file events.

Diagnosing window functions (user32)
------------------------------------

The code snippet below contains example commands creating breakpoints to trace window functions:

```cpp
# 32-bit
bp user32!NtUserSetWindowPos ".printf \"SetWindowPos( hWnd: %p, hWndInsertAfter: %p, X: %d, Y: %d, cx: %d, cy: %d, uFlags: %x )\\n\", poi(@esp+4), poi(@esp+8), poi(@esp+0xC), poi(@esp+0x10), poi(@esp+0x14), poi(@esp+0x18), poi(@esp+0x1C); g"
bp user32!NtUserShowWindow ".printf \"ShowWindow( hWnd: %p, nCmdShow: %d )\\n\", poi(@esp+4), poi(@esp+8); g"
bp user32!SetWindowLongW ".printf \"SetWindowLongW( hWnd: %p, nIndex: %d, dwNewLong: %p )\\n\", poi(@esp+4), poi(@esp+8), poi(@esp+0xC); g"
bp user32!SetForegroundWindow ".printf \"SetForegroundWindow( hWnd: %p )\\n\", poi(@esp+4); g"
bp user32!NtUserSetParent ".printf \"SetParent( hWndChild: %p, hWndNewParent: %p )\\n\", poi(@esp+4), poi(@esp+8); g"

# 32-bit, but using dx
bp user32!NtUserSetWindowPos "dx new { function = \"SetWindowPos\", hWnd = *(void **)(@esp+4), hWndInsertAfter = *(void **)(@esp+8), X = *(int *)(@esp+0xC), Y = *(int *)(@esp+0x10), cx = *(int *)(@esp+0x14), cy = *(int *)(@esp+0x18), uFlags = *(unsigned int *)(@esp+0x1C) }; g"
bp user32!NtUserSetForegroundWindow "dx new { function = \"SetForegroundWindow\", hWnd = *(void **)(@esp+4) }; g"
bp user32!NtUserShowWindow "dx new { function = \"ShowWindow\", hWnd = *(void **)(@esp+4), nCmdShow = *(int *)(@esp+8) }; g"
bp user32!NtUserSetParent "dx new { function = \"SetParent\", hWndChild = *(void **)(@esp+4), hWndNewParent = *(void **)(@esp+8) }; g"
bp user32!NtUserSetWindowLong "dx new { function = \"SetWindowLongW\", hWnd = *(void **)(@esp+4), nIndex = *(int *)(@esp+8), dwNewLong = *(long *)(@esp+0xC) }; g"

# 64-bit
bp user32!NtUserSetWindowPos ".printf \"SetWindowPos( hWnd: %p, hWndInsertAfter: %p, X: %d, Y: %d, cx: %d, cy: %d, uFlags: %x )\\n\", @rcx, @rdx, @r8, @r9, poi(@rsp+0x20), poi(@rsp+0x28), poi(@rsp+0x30); g"
bp user32!NtUserShowWindow ".printf \"ShowWindow( hWnd: %p, nCmdShow: %d )\\n\", @rcx, @rdx; g"
bp user32!SetWindowLongW ".printf \"SetWindowLongW( hWnd: %p, nIndex: %d, dwNewLong: %p )\\n\", @rcx, @rdx, @r8; g"
bp user32!SetForegroundWindow ".printf \"SetForegroundWindow( hWnd: %p )\\n\", @rcx; g"
bp user32!NtUserSetParent ".printf \"SetParent( hWndChild: %p, hWndNewParent: %p )\\n\", @rcx, @rdx; g"

# 64-bit, but using dx
bp user32!NtUserSetWindowPos "dx new { function = \"SetWindowPos\", hWnd = (void *)@rcx, hWndInsertAfter = (void *)@rdx, X = (int)@r8, Y = (int)@r9, cx = *(int *)(@rsp+0x28), cy = *(int *)(@rsp+0x30), uFlags = *(unsigned int *)(@rsp+0x38) }; g"
bp user32!SetForegroundWindow "dx new { function = \"SetForegroundWindow\", hWnd = (void *)@rcx }; g"
bp user32!NtUserShowWindow "dx new { function = \"ShowWindow\", hWnd = (void *)@rcx, nCmdShow = (int)@rdx }; g"
bp user32!_imp_NtUserSetParent "dx new { function = \"SetParent\", hWndChild = (void *)@rcx, hWndNewParent = (void *)@rdx }; g"
bp user32!SetWindowLongW "dx new { function = \"SetWindowLongW\", hWnd = (void *)@rcx, nIndex = (int)@rdx, dwNewLong = (long)@r8 }; g"

# conditional breakpoints
bp user32!PeekMessageW "r $t1 = poi(@esp+4); bp /1 @$ra \".lastevent; dt (combase!tagMSG)@$t1; g\"; g"
bp user32!PeekMessageW ".lastevent; r $t1 = poi(@esp+4); r $t2 = poi(@esp+8); .printf \"PeekMessageW(%x, %x)\n\", @$t1, @$t2; ba e1 /1 @$ra \".if (poi(@$t1) == 0x40526) { .lastevent; dt (combase!tagMSG)@$t1; g } .else { g }\"; g"
bp user32!PeekMessageW "r $t1 = poi(@esp+4); ba e1 /1 @$ra \".if (poi(@$t1) == 0x7049c) { .lastevent; dt (combase!tagMSG)@$t1; g } .else { g }\"; g"
bp user32!SetWindowLongW ".lastevent; dps @esp L4; r $t0 = poi(@esp+c); .if ($t0 = 0) { g }"
bp user32!SetWindowLongW ".lastevent; dps @esp L4; r $t0 = poi(@esp+8); .if ($t0 = 0xffffffeb) { r @eip; } .else { g }"
bp user32!SetWindowLongW ".lastevent; dps @esp L4; .if (poi(@esp+8) = -2) { r @eip; } .else { g }"
```

When analyzing a TTD trace, it is quicker to list the function calls while extracting their parameters to anonymous objects, for example:

```cpp
dx -g @$cursession.TTD.Calls("user32!NtUserSetWindowPos").Select(c => new { HWND = c.Parameters[0], WClass = @$scriptContents.findWindow(c.Parameters[0]).className, X = c.Parameters[2], Y = c.Parameters[3], TimeStart = c.TimeStart, SystemTime = c.SystemTimeStart })

dx -g @$cursession.TTD.Calls("user32!SetParentStub").Select(c => new { Child = c.Parameters[0], ChildClass = @$scriptContents.findWindow(c.Parameters[0]).className, Parent = c.Parameters[1], ParentClass = @$scriptContents.findWindow(c.Parameters[1]).className, TimeStart = c.TimeStart, SystemTime = c.SystemTimeStart })
```

I also created a [**winapi-user32.ps1**](/assets/other/winapi-user32.ps1.txt) script, which decodes some of the window flag values to their text representation, for example:

```sh
# load script
. winapi-user32.ps1

# decode GWL_STYLE flag
Get-EnumFlagsFromMask -Enum ([GWL_STYLE]) -Mask 382664704
# WS_MAXIMIZEBOX
# WS_MINIMIZEBOX
# WS_THICKFRAME
# WS_SYSMENU
# WS_DLGFRAME
# WS_BORDER
# WS_CAPTION
# WS_CLIPCHILDREN
# WS_CLIPSIBLINGS
# WS_VISIBLE

# decode GWL_EXSTYLE flag
Get-EnumFlagsFromMask -Enum ([GWL_EXSTYLE]) -Mask 262400
# WS_EX_WINDOWEDGE
# WS_EX_APPWINDOW

Get-EnumFlagsFromMask ([SWP]) 20
# SWP_NOZORDER
# SWP_NOACTIVATE
```

{% endraw %}
