---
layout: page
title: Using Event Tracing for Windows (ETW)
---

{% raw %}

*-- WORK IN PROGRESS --*

**Table of contents:**

<!-- MarkdownTOC -->

- [Description](#description)
- [Getting information on sessions and providers](#getting-information-on-sessions-and-providers)
    - [Query providers installed in the system](#query-providers-installed-in-the-system)
    - [Query running ETW sessions](#query-running-etw-sessions)
- [Configuring a tracing session](#configuring-a-tracing-session)
    - [Configure an ad-hoc tracing session](#configure-an-ad-hoc-tracing-session)
    - [Live view of events \(PerfView\)](#live-view-of-events-perfview)
    - [Configure an Autologger session \(starting when system boots\)](#configure-an-autologger-session-starting-when-system-boots)
    - [Configure a system boot trace](#configure-a-system-boot-trace)
- [Analyzing collected traces](#analyzing-collected-traces)
    - [Converting .etl file](#converting-etl-file)
    - [Reading stack](#reading-stack)
    - [Useful PerfView call stack groupings](#useful-perfview-call-stack-groupings)
- [Issues](#issues)
    - [\(0x800700B7\): Cannot create a file when that file already exists](#0x800700b7-cannot-create-a-file-when-that-file-already-exists)

<!-- /MarkdownTOC -->

## Description

For **manifest-based** providers set MatchAnyKeywords to 0x00 to receive all events. Otherwise you need to create a bitmask which will be or-ed with event keywords. Additionally when MatchAllKeywords is set, its value is used for events that passed the MatchAnyKeywords test and providers additional and filtering.

For **classic providers** set MatchAnyKeywords to 0xFFFFFFFF to receive all events.

Up to 8 sessions may collect manifest-based provider events, but only 1 session may be created for a classic provider (when a new session is created the provider switches to the session).

When creating a session we may also specify the event's level:

- `TRACE_LEVEL_CRITICAL 0x1`
- `TRACE_LEVEL_ERROR 0x2`
- `TRACE_LEVEL_WARNING 0x3`
- `TRACE_LEVEL_INFORMATION 0x4`
- `TRACE_LEVEL_VERBOSE 0x5`

> To improve stack walking on Win7 64-bit disable paging of the drivers and kernel-mode system code: `reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" -v DisablePagingExecutive -d 0x1 -t REG\_DWORD -f` or `wpr -disablepagingexecutive`.

## Getting information on sessions and providers

### Query providers installed in the system

List all providers: **logman query providers**

List provider details: `logman query providers ".NET Common Language Runtime"`

With logman you can also query providers in a given process: 

```
logman query providers -pid 808
```

You use logman or wevtutil: `wevtutil ep`

Find MSMQ publishers: `wevtutil ep | findstr /i msmq`

using Powershell: `Get-WinEvent -ListProvider`


Extract details about a given provider: `wevtutil gp Microsoft-Windows-MSMQ /ge /gm /f:xml`

To see the available Kernel provider options, you may run:

```
> logman query providers "Windows Kernel Trace"

Provider                                 GUID
-------------------------------------------------------------------------------
Windows Kernel Trace                     {9E814AAD-3204-11D2-9A82-006008A86939}

Value               Keyword              Description
-------------------------------------------------------------------------------
0x0000000000000001  process              Process creations/deletions
0x0000000000000002  thread               Thread creations/deletions
0x0000000000000004  img                  Image load
0x0000000000000008  proccntr             Process counters
0x0000000000000010  cswitch              Context switches
0x0000000000000020  dpc                  Deferred procedure calls
0x0000000000000040  isr                  Interrupts
0x0000000000000080  syscall              System calls
0x0000000000000100  disk                 Disk IO
0x0000000000000200  file                 File details
0x0000000000000400  diskinit             Disk IO entry
0x0000000000000800  dispatcher           Dispatcher operations
0x0000000000001000  pf                   Page faults
0x0000000000002000  hf                   Hard page faults
0x0000000000004000  virtalloc            Virtual memory allocations
0x0000000000010000  net                  Network TCP/IP
0x0000000000020000  registry             Registry details
0x0000000000100000  alpc                 ALPC
0x0000000000200000  splitio              Split IO
0x0000000000800000  driver               Driver delays
0x0000000001000000  profile              Sample based profiling
0x0000000002000000  fileiocompletion     File IO completion
0x0000000004000000  fileio               File IO
```

### Query running ETW sessions

To find active WPR recording you can run: `wpr -status profiles`

## Configuring a tracing session

### Configure an ad-hoc tracing session

To start profiling with CPU,FileIO and DiskIO profile run: 

`wpr -start CPU -start FileIO -start DiskIO`

To save the results run: 

`wpr -stop C:\temp\result.etl`

To completely turn off wpr logging run: `wpr -cancel`.

To trace the system using a custom profile:

`wpr.exe -start GeneralProfile -start Audio -start circular-audio-glitches.wprp!MediaProfile -filemode`

Stop tracing and save the results to a file (say, my-wpr-glitches.etl):  

`wpr.exe -stop my-wpr-glitches.etl` 

(Optional) if you want to cancel tracing: `wpr.exe -cancel`

(Optional) if you want to see whether tracing is currently active:  `wpr.exe -status`

For kernel tracing you just need to specify kernel flags or a kernel group: `xperf -on DiagEasy`

In user-mode tracing you may still use kernel flags and groups, but for each user-trace provider you need to add some additional parameters: `-on (GUID|KnownProviderName)[:Flags[:Level[:0xnnnnnnnn|'stack|[,]sid|[,]tsid']]]`

To stop run: `xperf -stop [session-name] -d c:\temp\trace.etl`

The best option is to combine all the commands together, eg.:

`xperf -on latency -stackwalk profile -buffersize 2048 -MaxFile 1024 -FileMode Circular && timeout -1 && xperf stop -d C:\highCPUUsage.etl`


The following commands start and stop a tracing session that is using one provider:

`logman start mysession -p {9744AD71-6D44-4462-8694-46BD49FC7C0C} -o c:\temp\test.etl -ets & timeout -1 & logman stop mysession -ets`

For the provider options you may additionally specify the keywords (flags) and levels that will be logged:  -p provider [flags [level]]

You may also use a file with a list of providers:

`logman start mysession -pf providers.guids -o c:\temp\test.etl -ets & timeout -1 & logman stop mysession -ets`

And the providers.guids file content is: {guid} {flags} {level} [provider name]

Example for ASP.NET:

<code>{AFF081FE-0247-4275-9C4E-021F3DC1DA35} 0xf    5  ASP.NET Events
{3A2A4E84-4C21-4981-AE10-3FDA0D9B0F83} 0x1ffe 5  IIS: WWW Server</code>

If you want to record events from the kernel provider you need to name the session: "NT Kernel Logger", eg.:

`logman start "NT Kernel Logger" -p "Windows Kernel Trace" "(process,thread,file,fileio,net)" -o c:\kernel.etl -ets & timeout -1 & logman stop "NT Kernel Logger" -ets`


To collect traces into a 500MB file (in circular mode) run the following command:

`perfview -AcceptEULA -ThreadTime -CircularMB:500 -Circular:1 -LogFile:perf.output -Merge:TRUE -Zip:TRUE -noView  collect`

A new console window will open with the following text:

<code>Pre V4.0 .NET Rundown enabled, Type 'D' to disable and speed up .NET Rundown.
Do NOT close this console window.   It will leave collection on!
Type S to stop collection, 'A' will abort.  (Also consider /MaxCollectSec:N)</code>

Type 'S' when you are done with tracing and wait (DO NOT CLOSE THE WINDOW) till you see `Press enter to close window`. Then copy the files: PerfViewData.etl.zip and perf.output to the machine when you will perform analysis.

If you are also interested in the network traces append the -NetMonCapture option. This will generate additional PerfViewData_netmon.cab file which you may open in the Message Analyzer.

Open Perfview trace in WPA: `perfview /wpr unzip test.etl.zip`

This should create two files (.etl and .etl.ngenpdb): `wpa test.etl`

### Live view of events (PerfView)

The **Listen** user command enables a live view dump of events in the PerfView log. Example commands:

```
PerfView.exe UserCommand Listen Microsoft-JScript:0x7:Verbose

# inspired by Konrad Kokosa
PerfView.exe UserCommand Listen Microsoft-Windows-DotNETRuntime:0x1:Verbose:@EventIDsToEnable="1 2"
```

### Configure an Autologger session (starting when system boots)

wpr -boottrace -addboot FileIO

### Configure a system boot trace

To collect general profile traces use: 

`wpr -start generalprofile -onoffscenario boot -numiterations 1`

## Analyzing collected traces

### Converting .etl file

Convert etl file to evtx: `tracerpt -of EVTX test.etl -o test.evtx -summary test-summary.xml`

Dump events to an XML file:  `tracerpt test.etl -o test.xml -summary test-summary.xml`

Dump events to a text file: `xperf -i test.etl -o test.csv`

Dump events to a HTML file: `tracerpt.exe '.\NT Kernel Logger.etl' -o -report -f html`

The default stacktag file is here: `c:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\Catalog\default.stacktags`

### Reading stack

Copy dbghelp.dll and symsrv.dll from the Debugging Tools for Windows to the WPA installation folder (remember about the correct bitness).

When analyzing traces we have the usual stack available, but you may often see an option to display stack tags. Those are special values which replace the well-known stack frames with tags. This way we can group the events by a stack tag and have a better understand which types of operation built a given request.

### Useful PerfView call stack groupings

The table below contains grouping patterns for various analysis targets

Scenario |  Pattern | Remarks
-------- | -------- | -------
Group requests | `^Request ID->ALL Requests` | Useful when we want to group all requests to analyze, for example, CPU times
Group requests by URL | `Request ID * URL:{*}->$1` | Useful when we want to group requests by URL to analyze, for example, CPU times
Group threads | `^Thread (%)-> ALL Threads` | Useful when we don't want to split the call stacks by threads in the call tree
Group async calls | `{%}!{%}+<>c__DisplayClass*+<<{%}>b__*>d.MoveNext()->($1) $2 async $3` | Christophe Nasarre presented this grouping pattern

## Issues

### (0x800700B7): Cannot create a file when that file already exists

If you receive:

<code>[Kernel Log: C:\tools\PerfViewData.kernel.etl]
    Kernel keywords enabled: Default
    Aborting tracing for sessions 'NT Kernel Logger' and 'PerfViewSession'.
    Insuring .NET Allocation profiler not installed.
    Completed: Collecting data C:\tools\PerfViewData.etl   (Elapsed Time: 0,858 sec)
    Exception Occured: System.Runtime.InteropServices.COMException (0x800700B7): Cannot create a file when that file already exists. (Exception from HRESULT: 0x800700B7)
       at System.Runtime.InteropServices.Marshal.ThrowExceptionForHRInternal(Int32 errorCode, IntPtr errorInfo)
       at Microsoft.Diagnostics.Tracing.Session.TraceEventSession.EnableKernelProvider(Keywords flags, Keywords stackCapture)
       at PerfView.CommandProcessor.Start(CommandLineArgs parsedArgs)
       at PerfView.CommandProcessor.Collect(CommandLineArgs parsedArgs)
       at PerfView.MainWindow.c__DisplayClass9.b__7()
       at PerfView.StatusBar.c__DisplayClass8.b__6(Object param0)
    An exceptional condition occurred, see log for details.
</code>

make sure that no kernel log is running: `perfview listsessions`

and eventually kill it: `perfview abort`

{% endraw %}