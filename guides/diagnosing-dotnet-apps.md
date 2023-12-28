---
layout: page
title: Diagnosing .NET applications
---

WIP

:point_right: I also authored the **[.NET Diagnostics Expert](https://diagnosticsexpert.com/?utm_source=debugrecipes&utm_medium=banner&utm_campaign=general) course**, available at  Dotnetos :hot_pepper: Academy. Apart from the theory, it contains lots of demos and troubleshooting guidelines. Check it out if you're interested in learning .NET troubleshooting. 👈


**Table of contents:**

<!-- MarkdownTOC -->

- [General .NET debugging tips](#general-net-debugging-tips)
    - [CLR debugging in WinDbg](#clr-debugging-in-windbg)
        - [Loading SOS](#loading-sos)
        - [Get help for commands in .NET WinDbg extensions](#get-help-for-commands-in-net-windbg-extensions)
        - [Manually loading symbol files for .NET Core](#manually-loading-symbol-files-for-net-core)
    - [Disabling JIT optimization](#disabling-jit-optimization)
    - [Decoding managed stacks in Sysinternals](#decoding-managed-stacks-in-sysinternals)
    - [Check framework version \(.NET Framework\)](#check-framework-version-net-framework)
    - [Debugging/tracing a containerized .NET application \(Docker\)](#debuggingtracing-a-containerized-net-application-docker)
- [Diagnosing waits or high CPU usage](#diagnosing-waits-or-high-cpu-usage)
    - [Collecting traces](#collecting-traces)
        - [Using dotnet-trace](#using-dotnet-trace)
        - [Using PerfView \(Windows\)](#using-perfview-windows)
        - [Using perfcollect \(Linux\)](#using-perfcollect-linux)
    - [Analyzing traces](#analyzing-traces)
        - [Using PerfView \(Windows\)](#using-perfview-windows_1)
        - [Using perfcollect \(Linux\)](#using-perfcollect-linux_1)
- [Diagnosing managed memory leaks](#diagnosing-managed-memory-leaks)
    - [Collecting memory snapshots](#collecting-memory-snapshots)
    - [Analyzing collected snapshots](#analyzing-collected-snapshots)
        - [Using perfview \(memory dumps and GC snapshots\)](#using-perfview-memory-dumps-and-gc-snapshots)
        - [Using windbg \(memory dumps\)](#using-windbg-memory-dumps)
        - [Using dotnet-gcdump \(GC dumps\)](#using-dotnet-gcdump-gc-dumps)
- [Diagnosing issues with assembly loading](#diagnosing-issues-with-assembly-loading)
    - [Troubleshooting loading with EventPipes/ETW \(.NET\)](#troubleshooting-loading-with-eventpipesetw-net)
    - [Troubleshooting loading using ETW \(.NET Framework\)](#troubleshooting-loading-using-etw-net-framework)
    - [Troubleshooting loading using Fusion log \(.NET Framework\)](#troubleshooting-loading-using-fusion-log-net-framework)
        - [Log to exception text](#log-to-exception-text)
        - [Log failures to disk](#log-failures-to-disk)
        - [Log all binds to disk](#log-all-binds-to-disk)
        - [Log disabled](#log-disabled)
    - [GAC \(.NET Framework\)](#gac-net-framework)
        - [Find assembly in cache](#find-assembly-in-cache)
        - [Uninstall assembly from cache](#uninstall-assembly-from-cache)
- [Diagnosing network connectivity issues](#diagnosing-network-connectivity-issues)
    - [.NET Core](#net-core)
    - [Full .NET Framework](#full-net-framework)
- [ASP.NET Core](#aspnet-core)
    - [Collecting ASP.NET Core logs](#collecting-aspnet-core-logs)
        - [ILogger logs](#ilogger-logs)
        - [DiagnosticSource logs](#diagnosticsource-logs)
    - [Collecting ASP.NET Core performance counters](#collecting-aspnet-core-performance-counters)
- [ASP.NET \(.NET Framework\)](#aspnet-net-framework)
    - [Examining ASP.NET process memory \(and dumps\)](#examining-aspnet-process-memory-and-dumps)
    - [Profiling ASP.NET](#profiling-aspnet)
    - [Application instrumentation](#application-instrumentation)
    - [ASP.NET ETW providers](#aspnet-etw-providers)
    - [Collect events using Perfecto tool](#collect-events-using-perfecto-tool)
    - [Collect events using FREB](#collect-events-using-freb)

<!-- /MarkdownTOC -->

## General .NET debugging tips

### CLR debugging in WinDbg

#### Loading SOS

When you are debugging on the same machine on which you collected the dump use the following commands:

```
.loadby sos mscorwks (.NET 2.0/3.5)
.loadby sos clr      (.NET 4.0+)
.loadby sos coreclr  (.NET Core)
```

Windbg Preview should load the SOS extension automatically for .NET Core apps/dumps. Check with the `.chain` command if it is there.

If it's not loaded, try using `!analyze -v`. On latest windbg versions it should detect a managed application and load the correct SOS version. If it does not work, load SOS from your .NET installation and try to download a correct mscordacwks as described [here](http://blogs.microsoft.co.il/blogs/sasha/archive/2012/05/19/obtaining-mscordacwks-dll-for-clr-versions-you-don-t-have.aspx).

Other issues:

- [Failed to load data access DLL, 0x80004005 – OR – What is mscordacwks.dll?](http://blogs.msdn.com/b/dougste/archive/2009/02/18/failed-to-load-data-access-dll-0x80004005-or-what-is-mscordacwks-dll.aspx)
- [How to load the specified mscordacwks.dll for managed debugging when multiple .NET runtime are loaded in one process](http://blogs.msdn.com/b/asiatech/archive/2010/09/10/how-to-load-the-specified-mscordacwks-dll-for-managed-debugging-when-multiple-net-runtime-are-loaded-in-one-process.aspx)

#### Get help for commands in .NET WinDbg extensions

SOS commands sometimes get overriden by other extensions help files. In such a case just use `!sos.help <cmd>` command, eg.

    0:000> !sos.help !savemodule
    -------------------------------------------------------------------------------
    !SaveModule <Base address> <Filename>
    ...

SOSEX help can be seen using the `!sosexhelp [command]` command.

Netext help can be nicely rendered in the command window: `.browse !whelp`.

#### Manually loading symbol files for .NET Core

I noticed that sometimes Microsoft public symbol servers do not have .NET Core dlls symbols. That does not allow WinDbg to decode native .NET stacks. Fortunately, we may solve this problem by precaching symbol files using the [dotnet-symbol](https://github.com/dotnet/symstore/tree/master/src/dotnet-symbol) tool. Assuming we set our `_NT_SYMBOL_PATH` to `SRV*C:\symbols\dbg*http://msdl.microsoft.com/download/symbols`, we need to run dotnet-symbol with the **--cache-directory** parameter pointing to our symbol cache folder (for example, `C:\symbols\dbg`):

```
dotnet-symbol --recurse-subdirectories --cache-directory c:\symbols\dbg -o C:\temp\toremove "C:\Program Files\dotnet\shared\Microsoft.NETCore.App\3.0.0\*"
```

We may later remove the `C:\temp\toremove` folder as all PDB files are indexed in the cache directory. The output folder contains both DLL and PDB files, takes lots of space, and is often not required.

### Disabling JIT optimization

For **.NET Core**, set the `COMPlus_JITMinOpts` variable:

```
export COMPlus_JITMinOpts=1
```

For **.NET Framework**, you need to create an ini file. The ini file must have the same name as the executable with only extension changed to ini, eg. my.ini file will work with my.exe application.

    [.NET Framework Debugging Control]
    GenerateTrackingInfo=1
    AllowOptimize=0

### Decoding managed stacks in Sysinternals

As of version 16.22 version, **Process Explorer** understands managed stacks and should display them correctly when you double click on a thread in a process.

**Process Monitor**, unfortunately, lacks this feature. Pure managed modules will appear as `<unknown>` in the call stack view. However, we may fix the problem for the ngened assemblies. First, you need to generate a .pdb file for the ngened assembly, for example, `ngen createPDB c:\Windows\assembly\NativeImages_v4.0.30319_64\mscorlib\e2c5db271896923f5450a77229fb2077\mscorlib.ni.dll c:\symbols\private`. Then make sure you have this path in your `_NT_SYMBOL_PATH` variable, for example, `C:\symbols\private;SRV*C:\symbols\dbg*http://msdl.microsoft.com/download/symbols`. If procmon still does not resolve the symbols, go to Options - Configure Symbols and reload the dbghelp.dll. I observe this issue in version 3.50.

### Check framework version (.NET Framework)

For .NET2.0 you could check the version of mscorwks in the file properties or, if in debugger, using lmmv:

    0:000> lmv m mscorwks
    start             end                 module name
    00000642`7f330000 00000642`7fcdc000   mscorwks   (deferred)
        Image path: C:\WINDOWS\Microsoft.NET\Framework64\v2.0.50727\mscorwks.dll
        Image name: mscorwks.dll
        Timestamp:        Wed May 12 00:13:32 2010 (4BEA38FC)
        CheckSum:         0099D95F
        ImageSize:        009AC000
        File version:     2.0.50727.4455
        Product version:  2.0.50727.4455
        File flags:       0 (Mask 3F)
        File OS:          4 Unknown Win32
        File type:        2.0 Dll
        File date:        00000000.00000000
        Translations:     0409.04b0
        CompanyName:      Microsoft Corporation
        ProductName:      Microsoft .NET Framework
        InternalName:     mscorwks.dll
        OriginalFilename: mscorwks.dll
        ProductVersion:   2.0.50727.4455
        FileVersion:      2.0.50727.4455 (QFE.050727-4400)
        FileDescription:  Microsoft .NET Runtime Common Language Runtime - WorkStation
        LegalCopyright:   Š Microsoft Corporation.  All rights reserved.
        Comments:         Flavor=Retail

For .NET4.x you need to check clr.dll (or the Release value under the `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full` key) and find it in the [Microsoft Docs](https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/versions-and-dependencies).

### Debugging/tracing a containerized .NET application (Docker)

With the introduction of EventPipes in .NET Core 2.1, the easiest approach is to create a shared `/tmp` volume and use a sidecar diagnostics container. A sample Dockerfile.netdiag may look as follows:

```
FROM mcr.microsoft.com/dotnet/sdk:5.0 AS base

RUN apt-get update && apt-get install -y lldb; \
    dotnet tool install -g dotnet-symbol; \
    dotnet tool install -g dotnet-sos; \
    /root/.dotnet/tools/dotnet-sos install

RUN dotnet tool install -g dotnet-counters; \
  dotnet tool install -g dotnet-trace; \
  dotnet tool install -g dotnet-dump; \
  dotnet tool install -g dotnet-gcdump; \
  echo 'export PATH="$PATH:/root/.dotnet/tools"' >> /root/.bashrc

ENTRYPOINT ["/bin/bash"]
```

You may use it to create a .NET diagnostics Docker image, for example:

```
$ docker build -t netdiag -f .\Dockerfile.netdiag .
```

Then, create a `/tmp` volume and mount it into your .NET application container, for example:

```
$ docker volume create dotnet-tmp

$ docker run --rm --name helloserver --mount "source=dotnet-tmp,target=/tmp" -p 13000:13000 helloserver 13000
```

And you are ready to run the diagnostics container and diagnose the remote application:

```
$ docker run --rm -it --mount "source=dotnet-tmp,target=/tmp" --pid=container:helloserver netdiag

root@d4bfaa3a9322:/# dotnet-trace ps
         1 dotnet     /usr/share/dotnet/dotnet 
```

If you only want to trace the application with **dotnet-trace**, consider using a shorter Dockerfile.nettrace file:

```
FROM mcr.microsoft.com/dotnet/sdk:5.0 AS base

RUN dotnet tool install -g dotnet-trace

ENTRYPOINT ["/root/.dotnet/tools/dotnet-trace", "collect", "-n", "dotnet", "-o", "/work/trace.nettrace", "@/work/input.rsp"]
```

where input.rsp:

```
--providers Microsoft-Windows-DotNETRuntime:0x14C14FCCBD:4,Microsoft-DotNETCore-SampleProfiler:0xF00000000000:4
```

The nettrace container will automatically start the tracing session enabling the providers from the input.rsp file. It also assumes the destination process name is dotnet:

```
$ docker build -t nettrace -f .\Dockerfile.nettrace .

$ docker run --rm --pid=container:helloserver --mount "source=dotnet-tmp,target=/tmp" -v "$pwd/:/work" -it nettrace

Provider Name                           Keywords            Level               Enabled By
Microsoft-Windows-DotNETRuntime         0x00000014C14FCCBD  Informational(4)    --providers
Microsoft-DotNETCore-SampleProfiler     0x0000F00000000000  Informational(4)    --providers

Process        : /usr/share/dotnet/dotnet
Output File    : /work/trace.nettrace
[00:00:00:02]   Recording trace 261.502  (KB)
Press <Enter> or <Ctrl+C> to exit...11   (KB)
Stopping the trace. This may take up to minutes depending on the application being traced.
```

## Diagnosing waits or high CPU usage

There are two ways of tracing CPU time. We could either use CPU sampling or Thread Time profiling. CPU sampling is about collecting samples in intervals: each CPU sample contains an instruction pointer to the currently executing code. Thus, this technique is excellent when diagnosing high CPU usage of an application. It won't work for analyzing waits in the applications. For such scenarios, we should rely on Thread Time profiling. It uses the system scheduler/dispatcher events to get detailed information about application CPU time. When combined with CPU sampling, it is the best non-invasive profiling solution.

### Collecting traces

#### Using dotnet-trace

Dotnet-trace allows us to enable the runtime CPU sampling provider (`Microsoft-DotNETCore-SampleProfiler`). However, using it might impact application performance as it internally calls `ThreadSuspend::SuspendEE` to suspend managed code execution while collecting the samples. Although it is a sampling profiler, it is a bit special. It runs on a separate thread and collects stacks of all the managed threads, even the waiting ones. This behavior resembles the thread time profiler. Probably that's the reason why PerfView shows us the **Thread Time** view when opening the .nettrace file.

Sample collect examples:

```bash
dotnet-trace collect --profile cpu-sampling -p 12345
dotnet-trace collect --profile cpu-sampling -- myapp.exe
```

Different from PerfView, dotnet-trace does not automatically enable DiagnosticSource or TPL providers. Therefore, if we want to see activities in PerfView, we need to turn them on manually, for example:

```bash
dotnet-trace collect --profile cpu-sampling --providers "Microsoft-Diagnostics-DiagnosticSource:0xFFFFFFFFFFFFF7FF:4:FilterAndPayloadSpecs=HttpHandlerDiagnosticListener/System.Net.Http.Request@Activity2Start:Request.RequestUri\nHttpHandlerDiagnosticListener/System.Net.Http.Response@Activity2Stop:Response.StatusCode,System.Threading.Tasks.TplEventSource:1FF:5" -n testapp
```

#### Using PerfView (Windows)

We can use PerfView to collect CPU samples and Thread Time events.

When collecting CPU samples, PerfView relies on Profile events coming from the Kernel ETW provider and it has very low impact on the system performance. An example command to start the CPU sampling:

```powershell
perfview collect -NoGui -KernelEvents:Profile,ImageLoad,Process,Thread -ClrEvents:JITSymbols cpu-collect.etl
```

Alternatively, you may use the **Collect** dialog. Make sure the **Cpu Samples** checkbox is selected.

To collect Thread Time events, you may use the following command:

```powershell
perfview collect -NoGui -ThreadTime thread-time-collect.etl
```

The **Collect** dialog has also the **Thread Time** checkbox.

#### Using perfcollect (Linux)

The [perfcollect](https://docs.microsoft.com/en-us/dotnet/core/diagnostics/trace-perfcollect-lttng) script is the easiest way to use Linux Kernel perf_events in diagnosing .NET apps. In my tests, however, I found that quite often, it did not correctly resolve .NET stacks. Dotnet-trace, mentioned already in this recipe, provides a more reliable way for collecting traces on Linux. But it has its downsides, so check both and see how they work in your environment.

To collect CPU samples with perfcollect, use the following command:

```bash
sudo perfcollect collect sqrt
```

To also enable the Thread Time events, add the `-threadtime` option:

```bash
sudo perfcollect collect sqrt -threadtime
```

### Analyzing traces

#### Using PerfView (Windows)

For analyzing **CPU Samples**, use the **CPU Stacks** view. Always check the number of samples if it corresponds to the tracing time (CPU sampling works when we have enough events). If necessary, zoom into the interesting period using a histogram (select the time and press Alt + R). Checking the **By Name** tab could be enough to find the method responsible for the high CPU Usage (look at the inclusive time and make sure you use correct grouping patterns).

When analyzing waits in an application, we should use the **Thread Time Stacks** views. The default one, **with StartStop activities**, tries to group the tasks under activities and helps diagnose application activities, such as HTTP requests or database queries. Remember that the exclusive time in the activities view is a sum of all the child tasks. The thread under the activity is the thread on which the task started, not necessarily the one on which it continued. The **with ReadyThread** view can help when we are looking for thread interactions. For example, we want to find the thread that released a lock on which a given thread was waiting. The **Thread Time Stacks** view (with no grouping) is the best one to visualize the application's sequence of actions. Expanding thread nodes in the CallTree could take lots of time, so make sure you use other events (for example, from the Events view) to set the time ranges. As usual, check the grouping patterns.

#### Using perfcollect (Linux)

If only possible, I would recommend opening the traces (even the ones from Linux) in PerfView. But if it's impossible, try the **view** command of the perfcollect script:

```bash
perfcollect view sqrt.trace.zip -graphtype caller
```

Using the **-graphtype** option, we may switch from the top-down view (`caller`) to the bottom-up view (`callee`).

## Diagnosing managed memory leaks

### Collecting memory snapshots

If we are interested only in GC Heaps, we may create the GC Heap snapshot using **PerfView**:

    perfview heapsnapshot <pid|name>

In GUI, we may use the menu option: **Memory -&gt; Take Heap Snapshot**.

For .NET Core applications, we have a CLI tool: **dotnet-gcdump**, which you may get from the `https://aka.ms/dotnet-gcdump/<TARGET PLATFORM RUNTIME IDENTIFIER>` URL, for example, https://aka.ms/dotnet-gcdump/linux-x64. And to collect the GC dump we need to run one of the commands:

    dotnet-gcdump -p <process-id>
    dotnet-gcdump -n <process-name>

Sometimes managed heap is not enough to diagnose the memory leak. In such situations, we need to create a memory dump, as described in the [deadlocks recipe](../deadlocks/diagnosing-deadlocks.md#dump-collection). 

### Analyzing collected snapshots

#### Using perfview (memory dumps and GC snapshots)

PerfView can open GC Heap snapshots and dumps. If you have only a memory dump, you may convert a memory dump file to perfview snapshot using `PerfView HeapSnapshotFromProcessDump ProcessDumpFile [DataFile]` or using the GUI options **Memory -&gt; Take Heap Snapshot from Dump**.

I would like to bring your attention to an excellent diffing option available for heap snapshots. Imagine you made two heap snapshots of the leaking process:

- first named LeakingProcess.gcdump
- second (taken a minute later) named LeakingProcess.1.gcdump

You may now run PerfView, open two collected snapshots, switch to the LeakingProcess.1.gcdump and under the Diff menu you should see an option to diff this snapshot with the baseline:

![diff option under the menu](perfview-snapshots-diff.png)

After you choose it a new window will pop up with a tree of objects which have changed between the snapshots. Of course, if you have more snapshots you can generate diffs between them all. A really powerful feature!

#### Using windbg (memory dumps)

    windbg -z <dump-file>

**Make sure that bitness of the dump matches bitness of the debugger.**

Then load the SOS extension:

- .NET Framework: `.loadby sos clr`
- .NET Core: `.loadby sos coreclr`

Identify object which use most of the memory using **!DumpHeap -stat**. Later, analyze the references using the **!GCRoot** command.

Other SOS commands for analyzing the managed heap:

```
!EEHeap [-gc] [-loader]
!HeapStat [-inclUnrooted | -iu]

!DumpHeap [-stat]
          [-strings]
          [-short]
          [-min <size>]
          [-max <size>]
          [-live]
          [-dead]
          [-thinlock]
          [-startAtLowerBound]
          [-mt <MethodTable address>]
          [-type <partial type name>]
          [start [end]]

!ObjSize [<Object address>]
!GCRoot [-nostacks] <Object address>
!DumpObject <address> | !DumpArray <address> | !DumpVC <mt> <address>
```

#### Using dotnet-gcdump (GC dumps)

dotnet-gcdump has a **report** command that lists the objects recorded in the GC heaps. The output resembles output from the SOS `!dumpheap` command.

## Diagnosing issues with assembly loading

### Troubleshooting loading with EventPipes/ETW (.NET)

The **Loader** keyword (`0x8`) in the **Microsoft-Windows-DotNETRuntime** provider enables events relating to **loading and unloading** of **appdomains**, **assemblies** and **modules**.

Starting with **.NET 5**, the new **AssemblyLoader** keyword (`0x4`) gives us a detailed view of the **assembly resolution process**. Additionally, we can group the activity events per assembly using the `ActivityID`.

    dotnet-trace collect --providers Microsoft-Windows-DotNETRuntime:C -- testapp.exe

### Troubleshooting loading using ETW (.NET Framework)

I think that currently the most efficient way to diagnose problems with assembly loading is to collect ETW events from the .NET ETW provider. There is a bunch of them under the **Microsoft-Windows-DotNETRuntimePrivate/Binding/** category.

For this purpose you may use the [**PerfView**](https://www.microsoft.com/en-us/download/details.aspx?id=28567) util. Just make sure that you have the .NET check box selected in the collection dialog (it should be by default). Start collection and stop it after the loading exception occurs. Then open the .etl file, go to the **Events** screen and filter them by *binding* as you can see on the screenshot below:

![events](perfview-binding-events.png)

Select all of the events and press ENTER. PerfView will immediately print the instances of the selected events in the grid on the right. You may later search or filter the grid with the help of the search boxes above it.

### Troubleshooting loading using Fusion log (.NET Framework)

Fusion log is available in all versions of the .NET Framework. There is a tool named **fuslogvw** in .NET SDK, which you may use to set the Fusion log configuration. Andreas Wäscher implemented an easier-to-use version of this tool, with a modern UI, named [Fusion++](https://github.com/awaescher/Fusion). You may download the precompiled version from the [release page](https://github.com/awaescher/Fusion/releases/).

If using neither of the above tools is possible (for example, you are in a restricted environment), you may configure the Fusion log through registry settings.

The root of all the Fusion log settings is `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Fusion`.

It is possible to log bindings also of the native images - you need to select the Native Images checkbox.

When writing to a folder on a hard drive fusion logs are split among categories and processes, eg.:

```
C:\TEMP\FUSLOGVW
├───Default
│   └───powershell.exe
└───NativeImage
    └───powershell.exe
```

#### Log to exception text

    HKEY_LOCAL_MACHINE\software\microsoft\fusion
        EnableLog    REG_DWORD    0x1

Command:

    reg delete HKLM\Software\Microsoft\Fusion /va
    reg add HKLM\Software\Microsoft\Fusion /v EnableLog /t REG_DWORD /d 0x1

#### Log failures to disk

    HKEY_LOCAL_MACHINE\software\microsoft\fusion
        LogFailures    REG_DWORD    0x1
        LogPath    REG_SZ    c:\logs\fuslogvw

Command:

    reg delete HKLM\Software\Microsoft\Fusion /va
    reg add HKLM\Software\Microsoft\Fusion /v LogFailures /t REG_DWORD /d 0x1
    reg add HKLM\Software\Microsoft\Fusion /v LogPath /t REG_SZ /d "C:\logs\fuslogvw"

#### Log all binds to disk

    HKEY_LOCAL_MACHINE\software\microsoft\fusion
        LogPath    REG_SZ    c:\logs\fuslogvw
        ForceLog    REG_DWORD    0x1

Command:

    reg delete HKLM\Software\Microsoft\Fusion /va
    reg add HKLM\Software\Microsoft\Fusion /v ForceLog /t REG_DWORD /d 0x1
    reg add HKLM\Software\Microsoft\Fusion /v LogPath /t REG_SZ /d "C:\logs\fuslogvw"

#### Log disabled

    HKEY_LOCAL_MACHINE\software\microsoft\fusion
        LogPath    REG_SZ    c:\logs\fuslogvw

Command:

    reg delete HKLM\Software\Microsoft\Fusion /va

### GAC (.NET Framework)

For .NET2.0/3.5 gac was located in **c:\Windows\assembly** folder with a drag/drop option for installing/uninstalling assemblies. According to <http://stackoverflow.com/questions/10013047/gacutil-vs-manually-editing-c-windows-assembly>:

This functionality is provided by a custom shell extension, shfusion.dll. It flattens the GAC and makes it look like a single folder. And takes care of automatically un/registering the assemblies for you when you manipulate the explorer window. So you’re fine doing this.

Note that this will no longer work for .NET 4, it uses a GAC in a different folder (**c:\windows\microsoft.net\assembly**) and that folder does not have a the same kind of shell extension, you see the raw content of the GAC folders. Don’t mess with that one.

For .NET4.0 GAC was moved to **c:\Windows\Microsoft.NET\assembly** and no longer supports drag&drop functionality - so it’s best to just use gacutil to manipulate GAC content. To **disable GAC viewer in Windows Explorer**, add a DWORD value **DisableCacheViewer** set to 1 under the **HKLM\Software\Microsoft\Fusion** key. Though it’s possible to install assembly in both GAC folders as stated here: <http://stackoverflow.com/questions/7095887/registering-the-same-version-of-an-assembly-but-with-different-target-frameworks>, but I would not consider it a good practice as framework tools can’t deal with it.

.NET GAC settings are stored under the registry key: HKLM\Software\Microsoft\Fusion.

#### Find assembly in cache

Work only with full assembly name provided. If no name is provided lists all the assemblies in cache.

    gacutil /l System.Core

    The Global Assembly Cache contains the following assemblies:
      System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089, processorArchitecture=MSIL
      System.Core, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089, processorArchitecture=MSIL

    Number of items = 2

#### Uninstall assembly from cache

    gacutil /u MyTest.exe

## Diagnosing network connectivity issues

I created a [**dotnet-wtrace**](https://github.com/lowleveldesign/dotnet-wtrace) tool to facilitate the collection of .NET events, including network traces. The paragraphs below describe in details what the application is doing.

### .NET Core

.NET Core provides a number of ETW and EventPipes providers to collect the network tracing events. Enabling the providers could be done in dotnet-trace, PerfView, or dotnet-wtrace. They use only two keywords (`Default = 0x1` and `Debug = 0x2`) and, as usual, we may filter the events by the log level (from 1 (critical) to 5 (verbose)).

In **.NET 5**, the providers were renamed and currently we can use the following names:

- `Private.InternalDiagnostics.System.Net.Primitives` - cookie container, cache credentials logs
- `Private.InternalDiagnostics.System.Net.Sockets` - logs describing operations on sockets, connection status events, 
- `Private.InternalDiagnostics.System.Net.NameResolution`
- `Private.InternalDiagnostics.System.Net.Mail`
- `Private.InternalDiagnostics.System.Net.Requests` - logs from `System.Net.Requests` classes
- `Private.InternalDiagnostics.System.Net.HttpListener`
- `Private.InternalDiagnostics.System.Net.WinHttpHandler`
- `Private.InternalDiagnostics.System.Net.Http` - `HttpClient` and HTTP handler logs, authentication events
- `Private.InternalDiagnostics.System.Net.Security` - `SecureChannel` (TLS) events, Windows SSPI logs

For previous .NET Core versions, the names were as follows:

- `Microsoft-System-Net-Primitives`
- `Microsoft-System-Net-Sockets`
- `Microsoft-System-Net-NameResolution`
- `Microsoft-System-Net-Mail`
- `Microsoft-System-Net-Requests`
- `Microsoft-System-Net-HttpListener`
- `Microsoft-System-Net-WinHttpHandler`
- `Microsoft-System-Net-Http`
- `Microsoft-System-Net-Security`

FIXME:
I prepared sample network.rsp:

```
--providers Microsoft-System-Net-Primitives,Microsoft-System-Net-Sockets,Microsoft-System-Net-NameResolution,Microsoft-System-Net-Mail,Microsoft-System-Net-Requests,Microsoft-System-Net-HttpListener,Microsoft-System-Net-WinHttpHandler,Microsoft-System-Net-Http,Microsoft-System-Net-Security,Microsoft-AspNetCore-Server-Kestrel
```
 and network5.rsp:

```
--providers
Private.InternalDiagnostics.System.Net.Primitives,Private.InternalDiagnostics.System.Net.Sockets,Private.InternalDiagnostics.System.Net.NameResolution,Private.InternalDiagnostics.System.Net.Mail,Private.InternalDiagnostics.System.Net.Requests,Private.InternalDiagnostics.System.Net.HttpListener,Private.InternalDiagnostics.System.Net.WinHttpHandler,Private.InternalDiagnostics.System.Net.Http,Private.InternalDiagnostics.System.Net.Security,Microsoft-AspNetCore-Server-Kestrel
```

  that enable all these event sources and the Kestrel one. You may use these files with **dotnet-trace**, for example:

```
$ dotnet-trace collect -n dotnet @network.rsp
```

### Full .NET Framework

All classes from `System.Net`, if configured properly, may provide a lot of interesting logs through the default System.Diagnostics mechanisms. The list of the available trace sources is available in [Microsoft docs](https://docs.microsoft.com/en-us/dotnet/framework/network-programming/how-to-configure-network-tracing).

This is a configuration sample which writes network traces to a file:

```xml
<system.diagnostics>
    <trace autoflush="true" />
    <sharedListeners>
      <add name="file" initializeData="C:\logs\network.log" type="System.Diagnostics.TextWriterTraceListener" />
    </sharedListeners>
    <sources>
      <source name="System.Net.Http" switchValue="Verbose">
        <listeners>
          <add name="file" />
        </listeners>
      </source>
      <source name="System.Net.HttpListener" switchValue="Verbose">
        <listeners>
          <add name="file" />
        </listeners>
      </source>
      <source name="System.Net" switchValue="Verbose">
        <listeners>
          <add name="file" />
        </listeners>
      </source>
      <source name="System.Net.Sockets" switchValue="Verbose">
        <listeners>
          <add name="file" />
        </listeners>
      </source>
    </sources>
</system.diagnostics>
```

## ASP.NET Core

### Collecting ASP.NET Core logs

For low-level network traces, you may enable .NET network providers, as described in the previous section. ASP.NET Core framework logs events either through `DiagnosticSource` using `Microsoft.AspNetCore` as the source name or through the `ILogger` interface.

#### ILogger logs

The `CreateDefaultBuilder` method adds `LoggingEventSource` (named `Microsoft-Extensions-Logging`) as one of the log outputs. The `FilterSpecs` argument makes it possible to filter the events by logger name and level, for example:

```
Microsoft-Extensions-Logging:5:5:FilterSpecs=webapp.Pages.IndexModel:0
```

We may define the log message format with keywords (pick one):

- `0x1` - enable meta events
- `0x2` - enable events with raw arguments
- `0x4` - enable events with formatted message (the most readable)
- `0x8` - enable events with data seriazlied to JSON

For example, to collect `ILogger` info messages: `dotnet-trace collect -p PID --providers "Microsoft-Extensions-Logging:0x4:0x4"`

#### DiagnosticSource logs 

To listen to `DiagnosticSource` events, we should enable the `Microsoft-Diagnostics-DiagnosticSource` event source. `DiagnosticSource` events often contain complex types and we need to use [parser specifications](https://github.com/dotnet/runtime/blob/main/src/libraries/System.Diagnostics.DiagnosticSource/src/System/Diagnostics/DiagnosticSourceEventSource.cs) to extract the interesting properties.

The `Microsoft-Diagnostics-DiagnosticSource` event source some special keywords:

- `0x1` - enable diagnostic messages
- `0x2` - enable regular events
- `0x0800` - disable the shortcuts keywords, listed below
- `0x1000` - enable activity tracking and basic hosting events (ASP.NET Core)
- `0x2000` - enable activity tracking and basic command events (EF Core)

Also, we should enable the minimal logging from the `System.Threading.Tasks.TplEventSource` provider to profit from the [activity tracking](https://docs.microsoft.com/en-us/archive/blogs/vancem/exploring-eventsource-activity-correlation-and-causation-features).

When our application is hosted on the Kestrel server, we may enable the `Microsoft-AspNetCore-Server-Kestrel` provider to get Kestrel events.

An example command that enables all ASP.NET Core event traces and some other useful network event providers. It also adds activity tracking for `HttpClient` requests:

```
> dotnet-trace collect --providers "Private.InternalDiagnostics.System.Net.Security,Private.InternalDiagnostics.System.Net.Sockets,Microsoft-AspNetCore-Server-Kestrel,Microsoft-Diagnostics-DiagnosticSource:0x1003:5:FilterAndPayloadSpecs=\"Microsoft.AspNetCore\nHttpHandlerDiagnosticListener\nHttpHandlerDiagnosticListener/System.Net.Http.Request@Activity2Start:Request.RequestUri\nHttpHandlerDiagnosticListener/System.Net.Http.Response@Activity2Stop:Response.StatusCode\",System.Threading.Tasks.TplEventSource:0x80:4,Microsoft-Extensions-Logging:4:5" -n webapp
```

### Collecting ASP.NET Core performance counters

ASP.NET Core provides some basic performance counters through the `Microsoft.AspNetCore.Hosting` event source. If we are also using Kestrel, we may add some interesting counters by enabling `Microsoft-AspNetCore-Server-Kestrel`:

```
> dotnet-counters monitor "Microsoft.AspNetCore.Hosting" "Microsoft-AspNetCore-Server-Kestrel" -n testapp

Press p to pause, r to resume, q to quit.
    Status: Running

[Microsoft.AspNetCore.Hosting]
    Current Requests                                                0
    Failed Requests                                                 0
    Request Rate (Count / 1 sec)                                    0
    Total Requests                                                  0
[Microsoft-AspNetCore-Server-Kestrel]
    Connection Queue Length                                        0
    Connection Rate (Count / 1 sec)                                0
    Current Connections                                            1
    Current TLS Handshakes                                         0
    Current Upgraded Requests (WebSockets)                         0
    Failed TLS Handshakes                                          2
    Request Queue Length                                           0
    TLS Handshake Rate (Count / 1 sec)                             0
    Total Connections                                              7
    Total TLS Handshakes                                           7
```

## ASP.NET (.NET Framework)

### Examining ASP.NET process memory (and dumps)

[PSSCOR4](http://www.microsoft.com/en-us/download/details.aspx?id=21255) commands for ASP.NET:

```
!ProcInfo [-env] [-time] [-mem]

FindDebugTrue

!FindDebugModules [-full]

!DumpHttpContext dumps the HttpContexts in the heap.  It shows the status of the request and the return code, etc.  It also prints out the start time

!ASPXPages just calls !DumpHttpContext to print out information on the ASPX pages  running on threads.

!DumpASPNETCache [-short] [-stat] [-s]

!DumpRequestTable [-a] [-p] [-i] [-c] [-m] [-q] [-n] [-e] [-w] [-h]                   [-r] [-t] [-x] [-dw] [-dh] [-de] [-dx]

!DumpHistoryTable [-a]
!DumpHistoryTable dumps the aspnet_wp history table.

!DumpBuckets dumps entire request table buckets.

!GetWorkItems given a CLinkListNode, print out request & work items.
```

[Netext](http://netext.codeplex.com/) commands for ASP.NET:

```
!whttp [/order] [/running] [/withthread] [/status <decimal>] [/notstatus <decimal>] [/verb <string>] [<expr>] - dump HttpContext objects

!wconfig - dump configuration sections loaded into memory

!wruntime - dump all active Http Runtime information
```

### Profiling ASP.NET

### Application instrumentation

Interesting tools and libraries:

- [ASP.NET 4.5 page instrumentation mechanism - PageExecutionListener](http://weblogs.asp.net/imranbaloch/archive/2013/11/23/page-instrumentation-in-asp-net-4-5.aspx)
- [Glimpse](https://github.com/glimpse/glimpse)
- [MiniProfiler](https://miniprofiler.com/)
- [Elmah](https://elmah.github.io/)

FIXME: trace listener

```xml
<?xml version="1.0"?>
<configuration>
  <system.diagnostics>
    <trace autoflush="true" />
    <sharedListeners>
      <add name="WebPageTraceListener" type="System.Web.WebPageTraceListener, System.Web, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" />
    </sharedListeners>
    <sources>
      <source name="Performance" switchValue="Verbose">
        <listeners>
          <add name="WebPageTraceListener" />
        </listeners>
      </source>
    </sources>
  </system.diagnostics>
  
  <system.web>
    <trace enabled="true" localOnly="true" pageOutput="false" />

    <customErrors mode="Off">
    </customErrors>
    
    <compilation debug="true" targetFramework="4.0">
    </compilation>
  </system.web>
</configuration>
```

### ASP.NET ETW providers

ASP.NET ETW providers are defined in the aspnet.mof file in the main .NET Framework folder. They should be installed with the framework:

```
> logman query /providers "ASP.NET Events"

Provider                                 GUID
-------------------------------------------------------------------------------
ASP.NET Events                           {AFF081FE-0247-4275-9C4E-021F3DC1DA35}

Value               Keyword              Description
-------------------------------------------------------------------------------
0x0000000000000001  Infrastructure       Infrastructure Events
0x0000000000000002  Module               Pipeline Module Events
0x0000000000000004  Page                 Page Events
0x0000000000000008  AppServices          Application Services Events

Value               Level                Description
-------------------------------------------------------------------------------
0x01                Fatal                Abnormal exit or termination
0x02                Error                Severe errors
0x03                Warning              Warnings
0x04                Information          Information
0x05                Verbose              Detailed information
```

If they are not, use mofcomp to install them:

```
```

To start collecting trace events from the ASP.NET and IIS providers run the following command:

    logman start aspnettrace -pf ctrl-iis-aspnet.guids -ct perf -o aspnet.etl -ets

And stop it with the command:

    logman stop aspnettrace -ets

The **ctrl-iis-aspnet.guids** file is available in the [etw-tracing folder](etw-tracing). You may later load the aspnet.etl file into **perfview** or **wpa** and examine the collected events.

### Collect events using Perfecto tool

Perfecto is a tool that creates an ASP.NET data collector in the system and allows you to generate nice reports of requests made to your ASP.NET application. Download it from <http://blogs.msdn.com/b/josere/archive/2010/04/09/taking-a-quick-peek-at-the-performance-of-your-asp-net-app.aspx>, unzip, run setup.cmd. After installing you can either use the **perfmon** to start the report generation:

1. On perfmon, navigate to the "Performance\Data Collector Sets\User Defined\ASPNET Perfecto" node.
2. Click the "Start the Data Collector Set" button on the tool bar.
3. Wait for/or make requests to the server (more than 10 seconds).
4. Click the "Stop the Data Collector Set" button on the tool bar.
5. Click the "View latest report" button on the tool bar or navigate to the last report at "Performance\Reports\User Defined\ASPNET Perfecto"

or **logman**:

    logman.exe start -n "Service\ASPNET Perfecto"

    logman.exe stop -n "Service\ASPNET Perfecto"

Note: The View commands are also available as toolbar buttons.
Sometimes you can see an error like below:

    Error Code: 0xc0000bf8
    Error Message: At least one of the input binary log files contain fewer than two data samples.

This usually happens when you collected data too fast. The performance counters are set by default to collect every 10 seconds. So a fast start/stop sequence may end without enough counter data being collected. Always allow more than 10 seconds between a start and stop commands. Or otherwise delete the performance counters collector or change the sample interval.

Requirements:

1. Windows >= Vista
2. Installed IIS tracing (`dism /online /enable-feature /featurename:IIS-HttpTracing`)

### Collect events using FREB

New IIS servers (7.0 up) contain a nice diagnostics functionality called Failed Request Tracing (or **FREB**). You may find a lot of information how to enable it on the [IIS official site](https://www.iis.net/learn/troubleshoot/using-failed-request-tracing/troubleshooting-failed-requests-using-tracing-in-iis) and in my [iis debugging recipe](asp.net/troubleshooting-iis.md).
