
Diagnosing managed memory leaks
==============================

In this recipe:

- [Collect memory snapshot](#collect-snapshot)
- [Analyze collected snapshots](#analyze-snapshots)
  - [Using PerfView (dumps and snapshots)](#perfview)
  - [Using WinDbg (dumps only)](#windbg)

## <a name="collect-snapshot">Collect memory snapshot</a>

To create a memory dump you may use [procdump](https://live.sysinternals.com) or [minidumper](https://github.com/goldshtn/minidumper) - a tool from Sasha Goldshtein (with my contribution):

    procdump -ma <your-app-name-or-pid>

    minidumper -ma <your-app-name-or-pid>

For a GC heap snapshot use **a perfview snapshot**:

    perfview heapsnapshot <pid|name>

You may also use the menu option: **Memory -&gt; Take Heap Snapshot**.

## <a name="analyze-snapshots">Analyze collected snapshots</a>

### <a name="perfview">Using perfview (dumps and snapshots)</a>

You may convert a memory dump file to perfview snapshot using `PerfView HeapSnapshotFromProcessDump ProcessDumpFile [DataFile]` or using the GUI options **Memory -&gt; Take Heap Snapshot from Dump**.

I would like to bring your attention to an excellent diffing option available for heap snapshots. Imagine you made two heap snapshots of the leaking process:

- first named LeakingProcess.gcdump
- second (taken a minute later) named LeakingProcess.1.gcdump

You may now run PerfView, open two collected snapshots, switch to the LeakingProcess.1.gcdump and under the Diff menu you should see an option to diff this snapshot with the baseline:

![diff option under the menu](perfview-snapshots-diff.png)

After you choose it a new window will pop up with a tree of objects which have changed between the snapshots. Of course, if you have more snapshots you can generate diffs between them all. A really powerful feature!

### Using windbg (dumps only) ###

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
