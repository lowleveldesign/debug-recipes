---
layout: page
title: Diagnosing native Windows applications
---

{% raw %}

**Table of contents:**

<!-- MarkdownTOC -->

- [Diagnosing abnormal termination or erroneous behavior](#diagnosing-abnormal-termination-or-erroneous-behavior)
    - [Using Time Travel Debugging \(TTD\) or live debugging](#using-time-travel-debugging-ttd-or-live-debugging)
        - [Break on a specific exception event](#break-on-a-specific-exception-event)
        - [Break on a specific Windows Error](#break-on-a-specific-windows-error)
    - [Collecting memory dumps on errors](#collecting-memory-dumps-on-errors)
        - [Using procdump](#using-procdump)
        - [Using Windows Error Reporting \(WER\)](#using-windows-error-reporting-wer)
        - [Automatic dump collection using AeDebug registry key](#automatic-dump-collection-using-aedebug-registry-key)
    - [Analyzing exceptions](#analyzing-exceptions)
        - [Reading the exception record](#reading-the-exception-record)
        - [Find the C++ exception object in the SEH exception record](#find-the-c-exception-object-in-the-seh-exception-record)
        - [Read the Last Windows Error value](#read-the-last-windows-error-value)
        - [Scanning the stack for native exception records](#scanning-the-stack-for-native-exception-records)
        - [Finding exception handlers](#finding-exception-handlers)
        - [Decoding error numbers](#decoding-error-numbers)
- [Diagnosing waits or high CPU usage](#diagnosing-waits-or-high-cpu-usage)
    - [Collecting ETW trace](#collecting-etw-trace)
    - [Anaysing the collected traces](#anaysing-the-collected-traces)
- [Diagnosing issues with DLL loading](#diagnosing-issues-with-dll-loading)
- [Diagnosing dead-locks and hangs](#diagnosing-dead-locks-and-hangs)
    - [Listing threads call stacks](#listing-threads-call-stacks)
    - [Finding locks in memory dumps](#finding-locks-in-memory-dumps)

<!-- /MarkdownTOC -->

## Diagnosing abnormal termination or erroneous behavior

### Using Time Travel Debugging (TTD) or live debugging

Time Travel Debugging is an excellent way of troubleshooting errors and exceptions. We can step through the code causing the problems at our own pace. I describe TTD in [the WinDbg usage guide](/guides/using-windbg#time-travel-debugging-ttd). It is my preferred way of debugging issues in applications and I highly recommend giving it a try.

#### Break on a specific exception event

The **sx-** commands define how WinDbg handles exception events that happen in the process lifetime. For example, to stop the debugger when a C++ exception is thrown (1st change exception) we would use the **sxe eh** command. If we only need information that an exception occurred, we could use the **sxn eh** command. Additionally, the **-c** parameter gives us a possibility to run our custom command on error, for example: `sxe -c ".lastevent;!pe;!clrstack;g" clr`.

#### Break on a specific Windows Error

There is a special global variable in ntdll: **g_dwLastErrorToBreakOn** that you may set to cause a break whenever a given last error code is set by the application. For example, to break the application execution whenever it reports the 0x4cf (ERROR_NETWORK_UNREACHABLE) error, run:

```
ed ntdll!g_dwLastErrorToBreakOn 0x4cf
```

You may find the list of errors in [the Windows documentation](https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes).


### Collecting memory dumps on errors

#### Using procdump

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

#### Using Windows Error Reporting (WER)

By default WER takes dump only when necessary, but this behavior can be configured and we can force WER to always create a dump by modifying **HKLM\Software\Microsoft\Windows\Windows Error Reporting\ForceQueue=1** or (**HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting\ForceQueue=1**). The reports are usually saved at **%LocalAppData%\Microsoft\Windows\WER**, in two directories: ReportArchive, when a server is available or ReportQueue, when the server is unavailable.  If you want to keep the data locally, just set the server to a non-existing machine (for example, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\CorporateWERServer=NonExistingServer). For **system processes** you need to look at **c:\ProgramData\Microsoft\Windows\WER**. In Windows 2003 Server R2 Error Reporting stores errors in the signed-in user's directory (for example, C:\Documents and Settings\me\Local Settings\Application Data\PCHealth\ErrorRep).

Starting with Windows Server 2008 and Windows Vista with Service Pack 1 (SP1), Windows Error Reporting can be configured to [collect full memory dumps on application crash](https://learn.microsoft.com/en-us/windows/win32/wer/collecting-user-mode-dumps). The registry key enabling this behavior is **HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\Windows Error Reporting\LocalDumps**. An example configuration for saving full-memory dumps to the %SYSTEMDRIVE%\dumps folder when the test.exe application fails looks as follows:

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps]

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\test.exe]
"DumpFolder"=hex(2):25,00,53,00,59,00,53,00,54,00,45,00,4d,00,44,00,52,00,49,\
  00,56,00,45,00,25,00,5c,00,64,00,75,00,6d,00,70,00,73,00,00,00
"DumpType"=dword:00000002
```

With the help of [the WER API](https://learn.microsoft.com/en-us/windows/win32/wer/wer-reference), you may also force WER reports in your custom application.

To **completely disable WER**, create a DWORD Value under the **HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting** key, named **Disabled** and set its value to 1. For 32-bit apps use the **HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\Windows Error Reporting** key.

#### Automatic dump collection using AeDebug registry key

There is a special **[AeDebug](https://learn.microsoft.com/en-us/windows/win32/debug/configuring-automatic-debugging)** key in the registry defining what should happen when an unhandled exception occurs in an application. You may find it under the **HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion** key (or **HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion** for 32-bit apps). Its important value keys include:

- **Debugger** : REG_SZ - application which will be called to handle the problematic process (example value: `procdump.exe -accepteula -j "c:\dumps" %ld %ld %p`), the first %ld parameter is replaced with the process ID and the second with the event handle
- **Auto** : REG_SZ - defines if the debugger runs automatically, without prompting the user (example value: 1)
- **UserDebuggerHotKey** : REG_DWORD - not sure, but it looks it enables the Debug button on the exception handling message box (example value: 1)

To set **WinDbg** as your default AeDebug debugger, run **windbg -I**. After running this command, WinDbg will launch on application crashes. You may also automate WinDbg to create a memory dump and then allow process to terminate, for example: `windbg -c ".dump /ma /u c:\dumps\crash.dmp; qd" -p %ld -e %ld -g`.

My favourite tool to use as the automatic debugger is **procdump**. The command line to install it is `procdump -mp -i c:\dumps`, where c:\dumps is the folder where I would like to store the dumps of crashing apps.

### Analyzing exceptions

#### Reading the exception record

The  **.ecxr** debugger command instructs the debugger to restore the thread context to its state when the initial fault happened. When dispatching a SEH exception, the OS builds an internal structure called an **exception record**. It also conveniently saves the thread context at the time of the initial fault in a context record structure.

```cpp
typedef struct _EXCEPTION_RECORD {
  DWORD                    ExceptionCode;
  DWORD                    ExceptionFlags;
  struct _EXCEPTION_RECORD *ExceptionRecord;
  PVOID                    ExceptionAddress;
  DWORD                    NumberParameters;
  ULONG_PTR                ExceptionInformation[EXCEPTION_MAXIMUM_PARAMETERS];
} EXCEPTION_RECORD;
```

**.lastevent** will also show you information about the last error that occured (if the debugger stopped because of an error). You may then examine the exception record using the **.exr** command, for example:

```
0:049> .lastevent
Last event: 15ae8.133b4: CLR exception - code e0434f4d (first/second chance not available)
  debugger time: Thu Jul 30 19:23:53.169 2015 (UTC + 2:00)

0:049> .exr -1
ExceptionAddress: 000007fe9b17f963
   ExceptionCode: e0434f4d (CLR exception)
  ExceptionFlags: 00000000
NumberParameters: 0
```

If we look at the raw memory, we will find that **.exr** changes the order of the EXCEPTION_RECORD fields, for example:

```
0:049> .exr 0430af24
ExceptionAddress: abe8f04d
   ExceptionCode: c0000005 (Access violation)
  ExceptionFlags: 00000000
NumberParameters: 2
   Parameter[0]: 00000000
   Parameter[1]: abe8f04d
```

```
0430af24  c0000005 <- exception code
0430af28  00000000
0430af2c  00000000
0430af30  abe8f04d <- exception address (code address)
0430af34  00000002 <- parameters number
0430af38  00000000
0430af3c  abe8f04d
```

If you need to diagnose **Windows Runtime Error**, for example:

```
(2f88.3358): Windows Runtime Originate Error - code 40080201 (first chance)
```

You may enable first chance notification for this error: `sxe 40080201`. When stopped, retrieve the exception context and the third parameter should contain an error message, for exmple:

```
0:008> .exr -1
ExceptionAddress: 77942822 (KERNELBASE!RaiseException+0x00000062)
   ExceptionCode: 40080201 (Windows Runtime Originate Error)
  ExceptionFlags: 00000000
NumberParameters: 3
   Parameter[0]: 80040155
   Parameter[1]: 00000052
   Parameter[2]: 0dddf680

0:008> du 0dddf680
0dddf680  "Failed to find proxy registratio"
0dddf6c0  "n for IID: {xxxxxxxx-xxxx-xxxx-x"
0dddf700  "xxx-xxxxxxxxxxxx}."
```

We may automate this step by using the **$exr_param2** pseudo-register, for example `sxe -c "du @$exr_param1 L40; g" eh"`

#### Find the C++ exception object in the SEH exception record

*(Tested on MSVC140)*

The second parameter of the exception record parameters should contain the C++ exception object. Let's have a look at an example debugging session of a 32-bit application:

```
0:000> sxe eh

0:000> g
(1884.3e6c): C++ EH exception - code e06d7363 (first/second chance not available)
First chance exceptions are reported before any exception handling.
This exception may be expected and handled.
Time Travel Position: 71:0
eax=00f3fb30 ebx=00c1d000 ecx=00000003 edx=00000000 esi=009a1019 edi=009a1019
eip=76f48cd0 esp=00f3fb28 ebp=00f3fb8c iopl=0         nv up ei pl nz ac pe nc
cs=0023  ss=002b  ds=002b  es=002b  fs=0053  gs=002b             efl=00000216
ntdll!RtlRaiseException:
76f48cd0 55              push    ebp

0:000> .exr -1
ExceptionAddress: 76f48cd0 (ntdll!RtlRaiseException)
   ExceptionCode: e06d7363 (C++ EH exception)
  ExceptionFlags: 00000001
NumberParameters: 3
   Parameter[0]: 19930520
   Parameter[1]: 00f3fbd8
   Parameter[2]: 009ab96c
  pExceptionObject: 00000000
  _s_ThrowInfo    : 00000000
```

If it's the first chance exception, we can find the exception record at the top of the stack:

```
0:000> dps @esp
00f3fb28  7657ec52 KERNELBASE!RaiseException+0x62
00f3fb2c  00f3fb30
00f3fb30  e06d7363
00f3fb34  00000001
00f3fb38  00000000
00f3fb3c  7657ebf0 KERNELBASE!RaiseException
00f3fb40  00000003
00f3fb44  19930520
00f3fb48  00f3fbd8
00f3fb4c  009ab96c exceptions!_TI3?AVinvalid_argumentstd
```

With dx and the `MSVCP140D!EHExceptionRecord` symbol, we may decode the exception record parameters:

```
0:000> dx -r2 (MSVCP140D!EHExceptionRecord*)0x00f3fb30
(MSVCP140D!EHExceptionRecord*)0x00f3fb30                 : 0xf3fb30 [Type: EHExceptionRecord *]
    [+0x000] ExceptionCode    : 0xe06d7363 [Type: unsigned long]
    [+0x004] ExceptionFlags   : 0x1 [Type: unsigned long]
    [+0x008] ExceptionRecord  : 0x0 [Type: _EXCEPTION_RECORD *]
    [+0x00c] ExceptionAddress : 0x7657ebf0 [Type: void *]
    [+0x010] NumberParameters : 0x3 [Type: unsigned long]
    [+0x014] params           [Type: EHExceptionRecord::EHParameters]
        [+0x000] magicNumber      : 0x19930520 [Type: unsigned long]
        [+0x004] pExceptionObject : 0xf3fbd8 [Type: void *]
        [+0x008] pThrowInfo       : 0x9ab96c [Type: _s_ThrowInfo *]
```

As you can see, the second parameter points to the C++ exception object. If we know its type, we may dump its properties, for example:

```
0:000> dt exceptions!std::invalid_argument 00f3fbd8 
   +0x000 __VFN_table : 0x009a9db8 
   +0x004 _Data            : __std_exception_data

0:000> dx -r1 (*((exceptions!__std_exception_data *)0xf3fbdc))
(*((exceptions!__std_exception_data *)0xf3fbdc))                 [Type: __std_exception_data]
    [+0x000] _What            : 0x1449748 : "arg1" [Type: char *]
    [+0x004] _DoFree          : true [Type: bool]
```

#### Read the Last Windows Error value

We may use the **!gle** command (or **!teb**) to get the last error value for the current thread. An additional **-all** parameter shows the last errors for all the threads, eg.

```
0:001> !gle -all
Last error for thread 0:
LastErrorValue: (Win32) 0 (0) - The operation completed successfully.
LastStatusValue: (NTSTATUS) 0xc0000034 - Object Name not found.

Last error for thread 1:
LastErrorValue: (Win32) 0 (0) - The operation completed successfully.
LastStatusValue: (NTSTATUS) 0 - STATUS_SUCCESS
```

#### Scanning the stack for native exception records

Sometimes, when the memory dump was incorrectly collected, we may not see the exception information and the `.exr -1` does not work. When this happens, there is still a chance that the original exception is somewhere in the stack. Using the `.foreach` command, we may scan the stack and try all the addresses to see if any of them is a valid exception record. For example:

```
.foreach /ps1 ($addr { dp /c1 @$csp L100 }) { .echo $addr; .exr $addr }

0430af24
ExceptionAddress: abe8f04d
   ExceptionCode: c0000005 (Access violation)
  ExceptionFlags: 00000000
NumberParameters: 2
   Parameter[0]: 00000000
   Parameter[1]: abe8f04d
```

#### Finding exception handlers

To list exception handlers for the currently running method use **!exchain** command, eg.:

```
0072ef74: clr!_except_handler4+0 (744048b9)
  CRT scope  0, filter: clr!RaiseTheExceptionInternalOnly+233 (74405e1c)
                func:   clr!RaiseTheExceptionInternalOnly+263 (7451c86b)
0072f04c: clr! ?? ::FNODOBFM::`string'+2a7f9 (74405714)
0072f0d0: clr!COMPlusFrameHandler+0 (7440619f)
0072f108: clr!_except_handler4+0 (744048b9)
  CRT scope  1, func:   clr!CallDescrWorkerWithHandler+7e (742715d8)
  CRT scope  0, filter: clr!CallDescrWorkerWithHandler+84 (745b019d)
                func:   clr!CallDescrWorkerWithHandler+90 (745b01a9)
```

Managed exception handlers can be listed using the **!EHInfo** command from the SOS extenaion. I present how to use this command to list ASP.NET MVC exception handlers [on my blog](https://lowleveldesign.wordpress.com/2013/04/26/life-of-exception-in-asp-net/).

In 32-bit application, pointer to the exception handler is kept in fs:[0]. The prolog for a method with exception handling has the following structure:

```
mov     eax,fs:[00000000]
push    eax
mov     fs:[00000000],esp
```

An Example session of retrieving the exception handler:

```
0:000> dd /c1 fs:[0]-8 L10
0053:fffffff8  00000000
0053:fffffffc  00000000
0053:00000000  0072ef74 <-- this is our first exception pointer to a handler
0053:00000004  00730000
0053:00000008  0072c000

0:000> dd /c1 0072ef74-8 L10
0072ef6c  0072eefc
0072ef70  74275582
0072ef74  0072f04c <-- previous handler
0072ef78  744048b9 <-- handler address
0072ef7c  2778008f
0072ef80  00000000
0072ef84  0072f058
0072ef88  744064f9
```

In 64-bit applications, information about exception handlers is stored in the PE file. We can list them using, for example, the **dumpbin /unwindinfo** command.

#### Decoding error numbers

If you receive an error message with a cryptic error number like this:

```
Compiler Error Message: The compiler failed with error code -1073741502.
```

You need to find its corresponding error message. An invaluable tool for this purpose is **[err.exe or Error Code Look-up](https://www.microsoft.com/en-us/download/details.aspx?id=985)**. It looks for the specific value in Windows headers, additionally performing the convertion to hex, for example:

```
> err -1073741502
# for decimal -1073741502 / hex 0xc0000142 :
  STATUS_DLL_INIT_FAILED                                        ntstatus.h
# {DLL Initialization Failed}
# Initialization of the dynamic link library %hs failed. The
# process is terminating abnormally.
...
```

If you are in WinDbg, you may use the **!error** command:

```
0:000> !error c0000142
Error code: (NTSTATUS) 0xc0000142 (3221225794) - {DLL Initialization Failed} Initialization of the dynamic link library %hs failed. The process is terminating abnormally.
```

Even more error codes and error messages are contained in the **!pde.err** command from the PDE extension.

Finally, there is a subcommand in the **net** command to decode Windows error numbers (and only error numbers), for example:

```
> net helpmsg 2
The system cannot find the file specified.
```

If you need to convert HRESULT to Windows Error, the following pseudo-code might help:

```
a = hresult & 0x1FF0000
if (a == 0x70000) {
    winerror = hresult & 0xFFFF
} else {
    winerror = hresult
}
```

Converting Windows Error to HRESULT is straightforward: `hresult = 0x80070000 | winerror`.

## Diagnosing waits or high CPU usage

There are two ways of tracing CPU time. We could either use CPU sampling or Thread Time profiling. CPU sampling is about collecting samples in intervals: each CPU sample contains an instruction pointer to the currently executing code. Thus, this technique is excellent when diagnosing high CPU usage of an application. It won't work for analyzing waits in the applications. For such scenarios, we should rely on Thread Time profiling. It uses the system scheduler/dispatcher events to get detailed information about application CPU time. When combined with CPU sampling, it is the best non-invasive profiling solution.

### Collecting ETW trace

We may use **PerfView** or **wpr.exe** to collect CPU samples and Thread Time events.

When collecting CPU samples, PerfView relies on Profile events coming from the Kernel ETW provider which has very low impact on the system overall performance. An example command to start the CPU sampling:

```shell
perfview collect -NoGui -KernelEvents:Profile,ImageLoad,Process,Thread -ClrEvents:JITSymbols cpu-collect.etl
```

Alternatively, you may use the **Collect** dialog. Make sure the **Cpu Samples** checkbox is selected.

To collect Thread Time events, you may use the following command:

```shell
perfview collect -NoGui -ThreadTime thread-time-collect.etl
```

The **Collect** dialog has also the **Thread Time** checkbox.

### Anaysing the collected traces

For analyzing **CPU Samples**, use the **CPU Stacks** view. Always check the number of samples if it corresponds to the tracing time (CPU sampling works when we have enough events). If necessary, zoom into the interesting period using a histogram (select the time and press Alt + R). Checking the **By Name** tab could be enough to find the method responsible for the high CPU Usage (look at the inclusive time and make sure you use correct grouping patterns).

When analyzing waits in an application, we should use the **Thread Time Stacks** views. The default one, **with StartStop activities**, tries to group the tasks under activities and helps diagnose application activities, such as HTTP requests or database queries. Remember that the exclusive time in the activities view is a sum of all the child tasks. The thread under the activity is the thread on which the task started, not necessarily the one on which it continued. The **with ReadyThread** view can help when we are looking for thread interactions. For example, we want to find the thread that released a lock on which a given thread was waiting. The **Thread Time Stacks** view (with no grouping) is the best one to visualize the application's sequence of actions. Expanding thread nodes in the CallTree could take lots of time, so make sure you use other events (for example, from the Events view) to set the time ranges. As usual, check the grouping patterns.

## Diagnosing issues with DLL loading

An invaluable source of information when dealing with DLL loading issues are Windows Loader snaps. Those are detailed logs of the steps that Windows Loader takes to resolve the application library dependencies. They are one of the available Global Flags that we can set for an executable, so we may use the **gflags.exe** tool to enable them.

![gflags - loader snaps](gflags-loader-snaps.png)

Once enabled, you need to start the failing application under a debugger and the Loader logs should appear in the debug output.

Alternatively, you may collect a procmon or ETW trace and search for any failure in the file events.

## Diagnosing dead-locks and hangs

We usually start the analysis by looking at the threads running in a process. The call stacks help us identify blocked threads. We can use TTD, thread-time trace, or memory dumps to learn about what threads are doing. In the follow-up sections, I will describe how to find lock objects and relations between threads in memory dumps.

### Listing threads call stacks

To list native stacks for all the threads in **WinDbg**, run: **~\*k** or **!uniqstacks**. 

### Finding locks in memory dumps

There are many types of objects that the thread can wait on. You usually see WaitOnMultipleObjects on many threads.

If you see RtlWaitForCriticalSection it might indicate that the thread is **waiting on a critical section**. Its adress should be in the call stack. And we may list the critical sections using the **!cs** command. With the **-s** option, we may examine details of a specific critical section:

```
0:033> !cs -s 000000001a496f50
-----------------------------------------
Critical section   = 0x000000001a496f50 (+0x1A496F50)
DebugInfo          = 0x0000000013c9bee0
LOCKED
LockCount          = 0x0
WaiterWoken        = No
OwningThread       = 0x0000000000001b04
RecursionCount     = 0x1
LockSemaphore      = 0x0
SpinCount          = 0x00000000020007d0
```

LockCount tells you how many threads are currently waiting on a given cs. The OwningThread is a thread that owns the cs at the time the command is run. You can easily identify the thread that is waiting on a given cs by issuing kv command and looking for critical section identifier in the call parameters.

We can also look for **synchronization object handles** using the **!handle** command. For example, we may list all the Mutant objects in a process by using the `!handle 0 f Mutant` command.

{% endraw %}
