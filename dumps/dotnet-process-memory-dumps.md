
Search .NET memory dumps for memory issues
==========================================

Collect memory
--------------

You may use any tool which works for the native process: <windows-process-memory-dumps.md>.

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

- [StackDump - stack dumps for .Net Applications](http://stackdump.codeplex.com/)
- [Creating Smaller, But Still Usable, Dumps of .NET Applications](http://blogs.microsoft.co.il/sasha/2015/08/19/minidumper-smaller-dumps-net-applications/)
