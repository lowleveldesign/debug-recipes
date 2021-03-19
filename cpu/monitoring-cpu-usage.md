
Troubleshooting CPU problems in .NET applications
=================================================

In this recipe:

- [Enumerating processes and threads](#enumerating-processes-and-threads)
  - [Usage examples (Windows)](#usage-examples-windows)
  - [Usage examples (Linux)](#usage-examples-linux)
- [Collecting process traces](#collecting-process-traces)
  - [Using dotnet-trace](#using-dotnet-trace)
  - [Using PerfView (Windows)](#using-perfview-windows)
  - [Using perfcollect (Linux)](#using-perfcollect-linux)
- [Analyzing traces](#analyzing-traces)
  - [Using PerfView (Windows)](#using-perfview-windows-1)
  - [Using perfcollect (Linux)](#using-perfcollect-linux-1)
- [Links](#links)

## Enumerating processes and threads

There are several tools that you can use to monitor processes running on the system. I list my favorite ones in the sections below.

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

There are two ways of tracing CPU time. We could either use CPU sampling or Thread Time profiling. CPU sampling is about collecting samples in intervals: each CPU sample contains an instruction pointer to the currently executing code. Thus, this technique is excellent when diagnosing high CPU usage of an application. It won't work for analyzing waits in the applications. For such scenarios, we should rely on Thread Time profiling. It uses the system scheduler/dispatcher events to get detailed information about application CPU time. When combined with CPU sampling, it is the best non-invasive profiling solution.

### Using dotnet-trace

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

### Using PerfView (Windows)

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

### Using perfcollect (Linux)

The [perfcollect](https://docs.microsoft.com/en-us/dotnet/core/diagnostics/trace-perfcollect-lttng) script is the easiest way to use Linux Kernel perf_events in diagnosing .NET apps. In my tests, however, I found that quite often, it did not correctly resolve .NET stacks. Dotnet-trace, mentioned already in this recipe, provides a more reliable way for collecting traces on Linux. But it has its downsides, so check both and see how they work in your environment.

To collect CPU samples with perfcollect, use the following command:

```bash
sudo perfcollect collect sqrt
```

To also enable the Thread Time events, add the `-threadtime` option:

```bash
sudo perfcollect collect sqrt -threadtime
```

## Analyzing traces

### Using PerfView (Windows)

For analyzing **CPU Samples**, use the **CPU Stacks** view. Always check the number of samples if it corresponds to the tracing time (CPU sampling works when we have enough events). If necessary, zoom into the interesting period using a histogram (select the time and press Alt + R). Checking the **By Name** tab could be enough to find the method responsible for the high CPU Usage (look at the inclusive time and make sure you use correct grouping patterns).

When analyzing waits in an application, we should use the **Thread Time Stacks** views. The default one, **with StartStop activities**, tries to group the tasks under activities and helps diagnose application activities, such as HTTP requests or database queries. Remember that the exclusive time in the activities view is a sum of all the child tasks. The thread under the activity is the thread on which the task started, not necessarily the one on which it continued. The **with ReadyThread** view can help when we are looking for thread interactions. For example, we want to find the thread that released a lock on which a given thread was waiting. The **Thread Time Stacks** view (with no grouping) is the best one to visualize the application's sequence of actions. Expanding thread nodes in the CallTree could take lots of time, so make sure you use other events (for example, from the Events view) to set the time ranges. As usual, check the grouping patterns.

### Using perfcollect (Linux)

If only possible, I would recommend opening the traces (even the ones from Linux) in PerfView. But if it's impossible, try the **view** command of the perfcollect script:

```bash
perfcollect view sqrt.trace.zip -graphtype caller
```

Using the **-graphtype** option, we may switch from the top-down view (`caller`) to the bottom-up view (`callee`).

## Links

- [.Net contention scenario using PerfView](http://blogs.msdn.com/b/rihamselim/archive/2014/02/25/net-contention-scenario-using-perfview.aspx)
- [The Lost Xperf Documentation–CPU Scheduling](http://randomascii.wordpress.com/2012/05/11/the-lost-xperf-documentationcpu-scheduling)
- [Great CPU diagnostics case (showing a way how to print information about all threads working on a given CPU](http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-77-WPT-Example)
- [Understanfding the Thread Time view in PerfView](https://lowleveldesign.wordpress.com/2015/10/01/understanding-the-thread-time-view-in-perfview/)
- <http://samsaffron.com/archive/2009/11/11/Diagnosing+runaway+CPU+in+a+Net+production+application>
