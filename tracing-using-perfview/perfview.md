
# PerfView

<!-- MarkdownTOC -->

- [Collect traces from the command line](#collect-traces-from-the-command-line)
- [Live view of events](#live-view-of-events)
- [Grouping call stacks](#grouping-call-stacks)
- [Issues](#issues)
    - [\(0x800700B7\): Cannot create a file when that file already exists](#0x800700b7-cannot-create-a-file-when-that-file-already-exists)

<!-- /MarkdownTOC -->

## Collect traces from the command line

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

## Live view of events

The **Listen** user command enables a live view dump of events in the PerfView log. Example commands:

```
PerfView.exe UserCommand Listen Microsoft-JScript:0x7:Verbose

# inspired by Konrad Kokosa
PerfView.exe UserCommand Listen Microsoft-Windows-DotNETRuntime:0x1:Verbose:@EventIDsToEnable="1 2"
```

## Grouping call stacks

Christophe Nasarre presented this grouping pattern for working with **async calls**:

`{%}!{%}+<>c__DisplayClass*+<<{%}>b__*>d.MoveNext()->($1) $2 async $3`

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
