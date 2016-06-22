
Diagnosing managed memory leaks
==============================

Collect memory snapshot
-----------------------

To create a memory dump you may use [procdump](https://live.sysinternals.com) or [minidumper](https://github.com/goldshtn/minidumper) - a tool from Sasha Goldshtein (with my contribution):

    procdump -ma <your-app-name-or-pid>

    minidumper -ma <your-app-name-or-pid>

For a GC heap snapshot use **a perfview snapshot**:

    perfview heapsnapshot <pid|name>

You may also use the menu option: **Memory -&gt; Take Heap Snapshot**.

Analyse collected snapshots
---------------------------

### Using perfview (dumps and snapshots) ###

You may convert a memory dump file to perfview snapshot using `PerfView HeapSnapshotFromProcessDump ProcessDumpFile [DataFile]` or using the GUI options **Memory -&gt; Take Heap Snapshot from Dump**.

I would like to bring your attention to an excellent diffing option available for heap snapshots. Imagine you made two heap snapshots of the leaking process:

- first named LeakingProcess.gcdump
- second (taken a minute later) named LeakingProcess.1.gcdump

You may now run PerfView, open two collected snapshots, switch to the LeakingProcess.1.gcdump and under the Diff menu you should see an option to diff this snapshot with the baseline:

![diff option under the menu](perfview-snapshots-diff.png)

After you choose it a new window will pop up with a tree of objects which have changed between the snapshots. Of course, if you have more snapshots you can generate diffs between them all. A really powerful feature!

### Using windbg (dumps only) ###

    windbg -z <dump-file>

_Make sure that bitness of the dump matches bitness of the debugger._

When dump was not taken with a full memory you may receive an error similar to the one below:

    0:000> .loadby sos clr
    The call to LoadLibrary(d:\symbols\mss\clr.dll\4DA3FDF5670000\sos) failed, Win32 error 0n126
        "The specified module could not be found."
    Please check your debugger configuration and/or network access.

You can then try loading `psscor4` but still many commands won't be working.

Identify object which used most of the memory using **!DumpHeap -stat**.

Load necessary **plugins**:

```
.load procdumpext
!loadsos
!loadsosex (or .load sosex)
```

**SOS commands:**

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

**SOSEX commands:**

```
!bhi (build heap index) !lhi <file> (load heap index) !chi (close heap index)

!mdt [typename | paramname | localname | MT] [ADDR] [-r[:level]] [-e[:level]]

!mroot
!refs <ObjectAddr> [-target|-source]

!gch [-HandleType]
```

**netext commands:**

```
!windex [/quiet] [/enumtypes] [/tree] [/flush] [/short] [/ignorestate]
        [/withpointer] [/type <string>] [/fieldname <string>]
        [/fieldtype <string>] [/implement <string>] [/save <string>]
        [/load <string>] [/mt <string>]

!wfrom [/nofield] [/withpointer] [/type <string>]
       [/mt <string>] [/fieldname <string>] [/fieldtype <string>]
       [/implement <string>] [/obj <expr>]
       [where (<condition>)] select <expr1>, ..., <exprN>

!wselect [mt <expr>] <field1>, ..., <fieldN> from <obj-expr> | <array-expr>
<field1>, ..., <fieldN> List of fields to display (accepts * and ?)

!wgchandle [-handletype <partial-name-of-handle-type>] [-type <partial-name-of-handle-type>] [-summary]
```

Links
-----

- [Tracking down managed memory leaks (how to find a GC leak)](http://blogs.msdn.com/b/ricom/archive/2004/12/10/279612.aspx)
  [CLR Profiler: Detecting High Memory consuming functions in .NET code](http://www.dotnetspark.com/kb/772-net-best-practice-no-1--detecting-high-memory.aspx)
- [How to detect and avoid memory and resources leaks in .NET applications](http://madgeek.com/Articles/Leaks/Leaks.en.html)
- [Investigating Memory Issues](http://msdn.microsoft.com/en-us/magazine/cc163528.aspx)
- Some tools found on [https://skydrive.live.com/?cid=2b879b9ac7a9e117&sc=documents&id=2B879B9AC7A9E117%21466](https://skydrive.live.com/?cid=2b879b9ac7a9e117&sc=documents&id=2B879B9AC7A9E117%21466)

### Testing ###

- [NBench Testing – Garbage collection](http://www.dotnetalgorithms.com/2016/02/nbench-testing-garbage-collection/)
- [dotMemory - .NET memory usage monitoring with unit tests](https://www.jetbrains.com/dotmemory/unit/)
- [WMemoryProfiler - wraps cdbg to collect GC data](https://wmemoryprofiler.codeplex.com/)
- [Visualising the .NET Garbage Collector](http://mattwarren.org/2016/06/20/Visualising-the-dotNET-Garbage-Collector/)

### GC ###

- [.NET Memory Basics](http://www.simple-talk.com/dotnet/.net-framework/.net-memory-management-basics/)
- [Large Obect Heap compaction - should I use it?](https://www.simple-talk.com/dotnet/.net-framework/large-object-heap-compaction-should-you-use-it/)
- [Garbage Collection: Automatic Memory Management in the Microsoft .NET Framework](http://msdn.microsoft.com/en-us/magazine/bb985010.aspx)
  [Garbage Collection Part 2: Automatic Memory Management in the Microsoft .NET Framework](http://msdn.microsoft.com/en-us/magazine/bb985011.aspx)
- [Learning How Garbage Collectors Work - Part 1](http://mattwarren.github.io/2016/02/04/learning-how-garbage-collectors-work-part-1/)
- [Large Object Heap Uncovered (an old MSDN article)](https://blogs.msdn.microsoft.com/maoni/2016/05/31/large-object-heap-uncovered-from-an-old-msdn-article/)

### Dumps ###

- [Minidumper - a better way to create managed memory dumps](http://www.codeproject.com/Articles/1102423/Minidumper-a-better-way-to-create-managed-memory-d)
- [Creating Smaller, But Still Usable, Dumps of .NET Applications](http://blogs.microsoft.co.il/sasha/2015/08/19/minidumper-smaller-dumps-net-applications/)
- [StackDump - stack dumps for .Net Applications](http://stackdump.codeplex.com/)


### ETW ###

- [Defrag Tools: #33 - CLR GC - Part 1](http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-33-CLR-GC-Part-1)
- [Defrag Tools: #34 - CLR GC - Part 2](http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-34-CLR-GC-Part-2)
- [GC ETW events](http://blogs.msdn.com/b/maoni/archive/2014/12/22/gc-etw-events.aspx)
- [GC ETW events - 2](http://blogs.msdn.com/b/maoni/archive/2014/12/25/gc-etw-events-2.aspx)
- [GC ETW Events - 3](http://blogs.msdn.com/b/maoni/archive/2014/12/25/gc-etw-events-3.aspx)
- [GC ETW Events - 4](http://blogs.msdn.com/b/maoni/archive/2014/12/30/gc-etw-events-4.aspx)
- [Measure GC Allocations and Collections using TraceEvent](http://naveensrinivasan.com/2015/05/11/measure-gc-allocations-and-collections-using-traceevent/)
- [ProfBugging - How to find leaks with allocation profiling](http://geekswithblogs.net/akraus1/archive/2015/03/22/161982.aspx)
- [Make WPA Simple - Garbage Collection and JIT Times](http://geekswithblogs.net/akraus1/archive/2015/08/16/166270.aspx)
- [Does Garbage Collection Hurt?](http://geekswithblogs.net/akraus1/archive/2014/02/17/155442.aspx) - PerfView usage to examine GC activities
