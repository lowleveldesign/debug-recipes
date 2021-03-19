
Troubleshooting CPU problems in .NET applications
=================================================

## Enumerating processes and threads

There are several tools which you can use to enumerate processes running on the system, including:

- Task manager (system)
- tasklist.exe (system)
- Process Explorer ([Sysinternals](https://technet.microsoft.com/en-us/sysinternals/))
- [Process Hacker](http://processhacker.sourceforge.net/) - **my favourite GUI tool**
- pslist.exe ([Sysinternals](https://technet.microsoft.com/en-us/sysinternals/)) - **my favourite command line tool**

### Filter processes by the process name (command line)

The easiest way is to just call pslist with the process name (wildcards are supported)

    PS temp> pslist notepad

You may as well use the sysytem util tasklist.exe, but the syntax is much less friendly:

    PS temp> tasklist /FI "IMAGENAME eq notepad.exe"

### List processes remotely (command line)

pslist is able to list the processes remotely:

    PS powershell> pslist -s 5 \\test-server -u myaccount

    pslist v1.3 - Sysinternals PsList
    Copyright (C) 2000-2012 Mark Russinovich
    23:45:22 2013-09-29 Process information for test-server

    Name                Pid CPU Thd  Hnd   Priv        CPU Time    Elapsed Time
    w3wp               9892  96 324 4483 1313512    15:13:27.546     1:16:50.323
    System                4   0 134 6757     44     6:10:54.515   345:35:56.865
    smss                360   0   4   29    284     0:00:00.125   345:35:56.865
    ...

### Show detailed information about a process (command line)

List notead processes with threads and memory info:

    PS temp> pslist -x notepad

    PsList v1.4 - Process information lister
    Copyright (C) 2000-2016 Mark Russinovich
    Sysinternals - www.sysinternals.com

    Process and thread information for TEMP:

    Name                Pid      VM      WS    Priv Priv Pk   Faults   NonP Page
    notepad            2588   68860    6676    3056    3056     1736      7  134
     Tid Pri    Cswtch            State     User Time   Kernel Time   Elapsed Time
    9048  10   1387934   Wait:Executive  0:00:00.000   0:00:14.710    1:16:43.577

## Collecting data

### Using PerfView ###

We can use PerfView to collect traces when CPU usage is higher than 90%:

    perfview collect /merge /zip /AcceptEULA "/StopOnPerfCounter=Processor:% Processor Time:_Total>90" /nogui /NoNGenRundown /DelayAfterTriggerSec=30

### Using xperf ###

A simple way would be to just collect the CPU profiling events (adding necessary flags for call stacks):

    PS temp> xperf -on PROFILE+PROC_THREAD+LOADER -stackwalk Profile
    PS temp> xperf -stop -d profile2.etl
    Merged Etl: profile2.etl

The created .etl file you can then open in any .etl files viewer (xperfview or wpa).

In order to investigate further (in case of hardware/drivers problem) you should add additional flags:

    xperf.exe -on PROC_THREAD+LOADER+PROFILE+INTERRUPT+DPC -StackWalk Profile
    xper -stop -d profile.etl

### Using procdump ###

To create a full memory dump when CPU reaches 80%:

    procdump -ma -c 80 Test.exe


## Collecting ETW traces

In **PerfView** you need to select the **Thread Time** checkbox in the collect window.

To collect traces with **xperf** run:

    xperf -on PROC_THREAD+LOADER+PROFILE+INTERRUPT+DPC+DISPATCHER+CSWITCH -stackwalk Profile+CSwitch+ReadyThread
    xperf -stop -d merged.etl

## Analyzing ETW traces

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



## Analyzing data

FIXME

## Links

- <http://samsaffron.com/archive/2009/11/11/Diagnosing+runaway+CPU+in+a+Net+production+application>
- [.Net contention scenario using PerfView](http://blogs.msdn.com/b/rihamselim/archive/2014/02/25/net-contention-scenario-using-perfview.aspx)
- [The Lost Xperf Documentation–CPU Scheduling](http://randomascii.wordpress.com/2012/05/11/the-lost-xperf-documentationcpu-scheduling)
- [Great CPU diagnostics case (showing a way how to print information about all threads working on a given CPU](http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-77-WPT-Example)

