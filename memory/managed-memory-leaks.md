
Diagnosing managed memory leaks
==============================

In this recipe:

- [Collect memory snapshot](#collect-memory-snapshot)
- [Analyze collected snapshots](#analyze-collected-snapshots)
  - [Using perfview (memory dumps and GC snapshots)](#using-perfview-memory-dumps-and-gc-snapshots)
  - [Using windbg (memory dumps)](#using-windbg-memory-dumps)
  - [Using dotnet-gcdump (GC dumps)](#using-dotnet-gcdump-gc-dumps)

## Collect memory snapshot

If we are interested only in GC Heaps, we may create the GC Heap snapshot using **PerfView**:

    perfview heapsnapshot <pid|name>

In GUI, we may use the menu option: **Memory -&gt; Take Heap Snapshot**.

For .NET Core applications, we have a CLI tool: **dotnet-gcdump**, which you may get from the `https://aka.ms/dotnet-gcdump/<TARGET PLATFORM RUNTIME IDENTIFIER>` URL, for example, https://aka.ms/dotnet-gcdump/linux-x64. And to collect the GC dump we need to run one of the commands:

    dotnet-gcdump -p <process-id>
    dotnet-gcdump -n <process-name>

Sometimes managed heap is not enough to diagnose the memory leak. In such situations, we need to create a memory dump, as described in the [deadlocks recipe](deadlocks/diagnosing-deadlocks.md). 

## Analyze collected snapshots

### Using perfview (memory dumps and GC snapshots)

PerfView can open GC Heap snapshots and dumps. If you have only a memory dump, you may convert a memory dump file to perfview snapshot using `PerfView HeapSnapshotFromProcessDump ProcessDumpFile [DataFile]` or using the GUI options **Memory -&gt; Take Heap Snapshot from Dump**.

I would like to bring your attention to an excellent diffing option available for heap snapshots. Imagine you made two heap snapshots of the leaking process:

- first named LeakingProcess.gcdump
- second (taken a minute later) named LeakingProcess.1.gcdump

You may now run PerfView, open two collected snapshots, switch to the LeakingProcess.1.gcdump and under the Diff menu you should see an option to diff this snapshot with the baseline:

![diff option under the menu](perfview-snapshots-diff.png)

After you choose it a new window will pop up with a tree of objects which have changed between the snapshots. Of course, if you have more snapshots you can generate diffs between them all. A really powerful feature!

### Using windbg (memory dumps)

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

### Using dotnet-gcdump (GC dumps)

dotnet-gcdump has a **report** command that lists the objects recorded in the GC heaps. The output resembles output from the SOS `!dumpheap` command.
