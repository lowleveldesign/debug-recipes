
Diagnosing manager memory leaks
==============================

FIXME

Collect memory
--------------

You may use [any tool which works for the native process](windows-process-memory-dumps.md).

Other option is to use the [minidumper](https://github.com/goldshtn/minidumper) tool from Sasha Goldshtein:

    FIXME

For a GC heap snapshot use **a perfview snapshot**:

    perfview heapsnapshot <pid|name>


Analyse collected snapshots
---------------------------

### Using perfview (dumps and snapshots) ###

You may convert a memory dump file to perfview snapshot using `PerfView HeapSnapshotFromProcessDump ProcessDumpFile [DataFile]`.

For further steps check perfview excellent help. FIXME: analysis example

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

Links
-----

- [.NET Memory Basics](http://www.simple-talk.com/dotnet/.net-framework/.net-memory-management-basics/)
- [Large Obect Heap compaction - should I use it?](https://www.simple-talk.com/dotnet/.net-framework/large-object-heap-compaction-should-you-use-it/)
- [Garbage Collection: Automatic Memory Management in the Microsoft .NET Framework](http://msdn.microsoft.com/en-us/magazine/bb985010.aspx)
  [Garbage Collection Part 2: Automatic Memory Management in the Microsoft .NET Framework](http://msdn.microsoft.com/en-us/magazine/bb985011.aspx)
- [Tracking down managed memory leaks (how to find a GC leak)](http://blogs.msdn.com/b/ricom/archive/2004/12/10/279612.aspx)
  [CLR Profiler: Detecting High Memory consuming functions in .NET code](http://www.dotnetspark.com/kb/772-net-best-practice-no-1--detecting-high-memory.aspx)
- [How to detect and avoid memory and resources leaks in .NET applications](http://madgeek.com/Articles/Leaks/Leaks.en.html)
- [Investigating Memory Issues](http://msdn.microsoft.com/en-us/magazine/cc163528.aspx)
- [Learning How Garbage Collectors Work - Part 1](http://mattwarren.github.io/2016/02/04/learning-how-garbage-collectors-work-part-1/)
- [NBench Testing – Garbage collection](http://www.dotnetalgorithms.com/2016/02/nbench-testing-garbage-collection/)
- [StackDump - stack dumps for .Net Applications](http://stackdump.codeplex.com/)
- [Creating Smaller, But Still Usable, Dumps of .NET Applications](http://blogs.microsoft.co.il/sasha/2015/08/19/minidumper-smaller-dumps-net-applications/)

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
