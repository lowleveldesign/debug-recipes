
PERFVIEW.EXE
============

Usage instructions
------------------

### Grouping stack calls ###

The following keywords define groupings in call stack view:

- * - Represents any number (0 or more) of any character (like .NET .*). This is not unlike what * means in Windows command line
- % - Represents any number (0 or more) of any alpha-numeric characters or the '.' character (like .NET [\w\d.]*)
- ^ - Matches the beginning of the pattern (like .NET ^)
- | - is an 'or' operator that allows the text on either side (like .NET |)
- {} - Forms groups for pattern replacement (like .NET ())

Groups can be created using one of the following syntax:

- `PAT->GROUPNAME` - Replace any frame names matching PAT with the text GROUPNAME.
- `PAT=>GROUPNAME` - Like `PAT->GROUPNAME` but remember the 'entry point' into the group.

### Checking process rundown information ###

There is a special `Windows Kernel/Process/PerfCtrRundown` event which contains a lot of interesting information for each of the processes available in the trace, such PeakWorkingSetSize, PrivateMemory etc.

### Checking process memory usage over time ###

Each 0.5 second there is a special event `Microsoft-Windows-Kernel-Memory/Memory/MemoryProcessInfo` which collects information about the processes memory. You can pick counters which are interesting to you, filter through process and you will see how memory usage was changing over time.

PerfView command line
---------------------

See perfview /?

### Collect traces from the command line ###

To collect traces into a 500MB file (in circular mode) run the following command:

```
perfview -AcceptEULA -ThreadTime -CircularMB:500 -Circular:1 -LogFile:perf.output -Merge:TRUE -Zip:TRUE -noView  collect
```

A new console window will open with the following text:

```
Pre V4.0 .NET Rundown enabled, Type 'D' to disable and speed up .NET Rundown.
Do NOT close this console window.   It will leave collection on!
Type S to stop collection, 'A' will abort.  (Also consider /MaxCollectSec:N)
```

Type 'S' when you are done with tracing and wait (DO NOT CLOSE THE WINDOW) till you see `Press enter to close window`. Then copy the files: **PerfViewData.etl.zip** and **perf.output** to the machine when you will perform analysis.

If you are also interested in the network traces append the **-NetMonCapture** option. This will generate additional **PerfViewData\_netmon.cab** file which you may open in the Message Analyzer.

### Open Perfview trace in WPA ###

    perfview /wpr unzip test.etl.zip

This should create two files (.etl and .etl.ngenpdb)

    wpa test.etl

Issues
------

### (0x800700B7): Cannot create a file when that file already exists ###

If you receive:

    [Kernel Log: C:\tools\PerfViewData.kernel.etl]
    Kernel keywords enabled: Default
    Aborting tracing for sessions 'NT Kernel Logger' and 'PerfViewSession'.
    Insuring .NET Allocation profiler not installed.
    Completed: Collecting data C:\tools\PerfViewData.etl   (Elapsed Time: 0,858 sec)
    Exception Occured: System.Runtime.InteropServices.COMException (0x800700B7): Cannot create a file when that file already exists. (Exception from HRESULT: 0x800700B7)
       at System.Runtime.InteropServices.Marshal.ThrowExceptionForHRInternal(Int32 errorCode, IntPtr errorInfo)
       at Microsoft.Diagnostics.Tracing.Session.TraceEventSession.EnableKernelProvider(Keywords flags, Keywords stackCapture)
       at PerfView.CommandProcessor.Start(CommandLineArgs parsedArgs)
       at PerfView.CommandProcessor.Collect(CommandLineArgs parsedArgs)
       at PerfView.MainWindow.<>c__DisplayClass9.<ExecuteCommand>b__7()
       at PerfView.StatusBar.<>c__DisplayClass8.<StartWork>b__6(Object param0)
    An exceptional condition occurred, see log for details.

make sure that no kernel log is running:

    perfview listsessions

and eventually kill it:

    perfview abort

Links
-----

- [Great PerfView video casts](http://channel9.msdn.com/Series/PerfView-Tutorial)
- [A Lab on investigating Memory Performance with PerfView](http://blogs.msdn.com/b/vancem/archive/2013/02/27/a-lab-on-investigating-memory-performance-with-perfview.aspx)
- [Defrag Tools - search for perfview](http://channel9.msdn.com/Shows/Defrag-Tools/)

