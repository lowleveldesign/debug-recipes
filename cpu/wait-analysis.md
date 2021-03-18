Analyzing locks
===============

In this recipe:

  - [Collecting ETW traces](#collecting-etw-traces)
  - [Analyzing ETW traces](#analyzing-etw-traces)
    - [Using PerfView](#using-perfview)
    - [Using WPA](#using-wpa)
  - [Diagnosing locks in a debugger (including dumps)](#diagnosing-locks-in-a-debugger-including-dumps)
    - [Automatic detection of the dead-locks (managed)](#automatic-detection-of-the-dead-locks-managed)
    - [Correlate thread ids with thread objects (managed)](#correlate-thread-ids-with-thread-objects-managed)
    - [Iterate through execution contexts assigned to threads (managed)](#iterate-through-execution-contexts-assigned-to-threads-managed)
    - [List locks (managed)](#list-locks-managed)
    - [Check locks in kernel mode](#check-locks-in-kernel-mode)
    - [Examine threadpools](#examine-threadpools)
    - [Examine critical sections](#examine-critical-sections)

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
