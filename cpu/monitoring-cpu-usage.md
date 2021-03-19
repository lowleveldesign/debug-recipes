
Troubleshooting CPU problems in .NET applications
=================================================

In this recipe:

FIXME

## Enumerating processes and threads

There are several tools which you can use to monitor processes running on the system and I list my favorite ones in the sections below.

Tools on Windows:

- Task manager (system)
- tasklist.exe (system)
- [Process Explorer](https://docs.microsoft.com/en-us/sysinternals/downloads/process-explorer) (part of Sysinternals)
- [Process Hacker](http://processhacker.sourceforge.net/) - **my favourite GUI tool**
- [pslist](https://docs.microsoft.com/en-us/sysinternals/downloads/pslist) (part of Sysinternals](https://technet.microsoft.com/en-us/sysinternals/)) - **my favourite command line tool**

Tools on Linux:

- top, ps, pgrep (from procps package)
- pidstat (from sysstat package)
- [htop](https://htop.dev/)

### Usage examples (Windows)

The easiest way is to just call pslist with the process name (wildcards are supported)

```powershell
# find processes named notepad
pslist notepad
tasklist /FI "IMAGENAME eq notepad.exe"

# list processes remotely
pslist -s 5 \\test-server -u myaccount

# show detailed information about a process
pslist -x notepad
```

### Usage examples (Linux)

```bash
# show all processes (-e) running in the system with some details (-F)
ps -eF

# show all processes in a tree (--forest)
ps -e --forest

# show processes whose effective user ID (-u) is root and select only specific columns (-o)
ps -u root -o pid,%cpu,cmd

# sort all processes (--sort) by their CPU usage (from highest to lowest)
ps -e -o pid,%cpu,rss,cmd --sort -%cpu

# filter processes with pgrep and show their info with ps
pgrep bash | xargs ps -F -p

# show CPU usage for all the processes (-p ALL) and refresh every second
pidstat -p ALL 1
```

## Collecting process traces

The are two tracing 

### Using dotnet-trace



dotnet-trace collect --providers='FolderWatcher:0x3:5' -- .\FolderWatcher.exe d:\temp

### Using PerfView (Windows)

We can use PerfView to collect traces when CPU usage is higher than 90%:

    perfview collect /merge /zip /AcceptEULA "/StopOnPerfCounter=Processor:% Processor Time:_Total>90" /nogui /NoNGenRundown /DelayAfterTriggerSec=30

In **PerfView** you need to select the **Thread Time** checkbox in the collect window.

### :floppy_disk: Using xperf (Windows)

A simple way would be to just collect the CPU profiling events (adding necessary flags for call stacks):

    PS temp> xperf -on PROFILE+PROC_THREAD+LOADER -stackwalk Profile
    PS temp> xperf -stop -d profile2.etl
    Merged Etl: profile2.etl

The created .etl file you can then open in any .etl files viewer (xperfview or wpa).

In order to investigate further (in case of hardware/drivers problem) you should add additional flags:

    xperf.exe -on PROC_THREAD+LOADER+PROFILE+INTERRUPT+DPC -StackWalk Profile
    xper -stop -d profile.etl

To collect traces with **xperf** run:

    xperf -on PROC_THREAD+LOADER+PROFILE+INTERRUPT+DPC+DISPATCHER+CSWITCH -stackwalk Profile+CSwitch+ReadyThread
    xperf -stop -d merged.etl

## Analyzing traces

Event Tracing for Windows is probably the best option when we need to analyze the thread waits. In the paragraphs below you can find information

### Using PerfView

You need to select the ThreadTime in the collection dialog. With this setting PerfView will record context switch events as well as the usual stack dumps every 100ms.

When analyzing blocks use any of the **Thread Time** views. It's best to start with the **Call Stack** view, exclude threads which seem not interesting and locate blocks which might be connected with your investigation. Then for each block time narrow the time to its start and try to guess the flow of the commands that fire it (what was executed last on each thread and what might be the cause of the wait).

You may check [the post](https://lowleveldesign.wordpress.com/2015/10/01/understanding-the-thread-time-view-in-perfview/) on my blog explaining in details Thread Time view in PerfView.

### Using WPA

There are two interesting groups of graphs to analyze in WPA: **CPU Usage (Sample)** and **CPU Usage (Precise)**. You may download my [WPA Profile](async-analysis-profile.wpaProfile) or use one of the predefined ones. 

On the **CPU Usage (Precise)** graph, we should start from our hanging thread and found its readying thread. Then check which thread readied this thread and so on. This chain should bring to us to the final thread which might be a system thread performing some I/O operations.

When working with this view it's always worth to have in mind the thread states diagram from MSDN:

![thread states](thread-states.jpg)

## Links

- <http://samsaffron.com/archive/2009/11/11/Diagnosing+runaway+CPU+in+a+Net+production+application>
- [.Net contention scenario using PerfView](http://blogs.msdn.com/b/rihamselim/archive/2014/02/25/net-contention-scenario-using-perfview.aspx)
- [The Lost Xperf Documentation–CPU Scheduling](http://randomascii.wordpress.com/2012/05/11/the-lost-xperf-documentationcpu-scheduling)
- [Great CPU diagnostics case (showing a way how to print information about all threads working on a given CPU](http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-77-WPT-Example)

