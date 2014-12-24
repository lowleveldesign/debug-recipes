
Search .NET memory dumps for memory issues
==========================================

Collect memory
--------------

You can collect either **a memory dump** (using procdump or any other tool):

    procdump -ma <pid|name>

or **a perfview snapshot**:

    procdump heapsnapshot <pid|name>

Analyse collected snapshots
---------------------------

### Using perfview (dumps and snapshots) ###

You may convert a memory dump file to perfview snapshot using `PerfView HeapSnapshotFromProcessDump ProcessDumpFile [DataFile]`.

For further steps check perfview excellent help. FIXME: analysis example

### Using windbg (dumps only) ###

    windbg -z <dump-file>

_Make sure that bitness of the dump matches bitness of the debugger._

Identify object which used most of the memory using **!DumpHeap -stat**.

Load necessary **plugins**:

```
.load procdumpext
!loadsos
!loadsosex (or .load sosex)
```

Build heap index for SOSEX: `!bhi`

SOS commands:

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

SOSEX commands:

```
!bhi (build heap index) !lhi <file> (load heap index) !chi (close heap index)

!mdt [typename | paramname | localname | MT] [ADDR] [-r[:level]] [-e[:level]]

!mroot
!refs <ObjectAddr> [-target|-source]

!gch [-HandleType]
```
