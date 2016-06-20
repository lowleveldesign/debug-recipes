
Analysing locks in .NET applications
====================================

Using PerfView (ETW traces)
---------------------------

You need to select the ThreadTime in the collection dialog. With this setting PerfView will record context switch events as well as the usual stack dumps every 100ms.

When analyzing blocks use any of the **Thread Time** views. It's best to start with the **Call Stack** view, exclude threads which seem not interesting and locate blocks which might be connected with your investigation. Then for each block time narrow the time to its start and try to guess the flow of the commands that fire it (what was executed last on each thread and what might be the cause of the wait).

Using windbg (live debugging and dumps)
---------------------------------------

### Automatic detection of the dead-locks ###

Try running the **!dlk** command from the SOSEX extension. It is pretty good in detecting dead-locks, example:

```
0:007> .load sosex
0:007> !dlk
Examining SyncBlocks...
Scanning for ReaderWriterLock(Slim) instances...
Scanning for holders of ReaderWriterLock locks...
Scanning for holders of ReaderWriterLockSlim locks...
Examining CriticalSections...
Scanning for threads waiting on SyncBlocks...
Scanning for threads waiting on ReaderWriterLock locks...
Scanning for threads waiting on ReaderWriterLocksSlim locks...
*** WARNING: Unable to verify checksum for C:\WINDOWS\assembly\NativeImages_v4.0.30319_32\System\3a4f0a84904c4b568b6621b30306261c\System.ni.dll
*** WARNING: Unable to verify checksum for C:\WINDOWS\assembly\NativeImages_v4.0.30319_32\System.Transactions\ebef418f08844f99287024d1790a62a4\System.Transactions.ni.dll
Scanning for threads waiting on CriticalSections...
*DEADLOCK DETECTED*
CLR thread 0x1 holds the lock on SyncBlock 011e59b0 OBJ:02e93410[System.Object]
...and is waiting on CriticalSection 01216a58
CLR thread 0x3 holds CriticalSection 01216a58
...and is waiting for the lock on SyncBlock 011e59b0 OBJ:02e93410[System.Object]
CLR Thread 0x1 is waiting at clr!CrstBase::SpinEnter+0x92
CLR Thread 0x3 is waiting at System.Threading.Monitor.Enter(System.Object, Boolean ByRef)(+0x17 Native)
```

### Correlate thread ids with thread objects ###

The `!Threads` commands does not unfortunately show addresses of the managed thread objects on the heap. So first you need to find the MT of the `Thread` class in your appdomain, eg.

```
0:036> !Name2EE mscorlib.dll System.Threading.Thread
Module:      72551000
Assembly:    mscorlib.dll
Token:       020001d1
MethodTable: 72954960
EEClass:     725bc0c4
Name:        System.Threading.Thread
```

Then run this script written by Naveen (<http://stackoverflow.com/questions/4616584/windbg-sos-how-to-correlate-managed-threads-from-threads-command-with-system-t>):

```
.foreach ($t {!dumpheap -mt 72954960 -short}) {  .printf " Thread Obj ${$t} and the Thread Id is %N \n",poi(${$t}+28) }
```

The printed ids corresond to the values of the ID column in `!Threads` output, eg:

```
       ID OSID ThreadOBJ    State GC Mode     GC Alloc Context  Domain   Count Apt Exception
   9    1 17dc 05146278     28220 Preemptive  1DF58070:00000000 050d8b18 0     Ukn
  31    2 1544 05162618     2b220 Preemptive  00000000:00000000 050d8b18 0     MTA (Finalizer)
  33    3 16b8 05193430   102a220 Preemptive  00000000:00000000 050d8b18 0     MTA (Threadpool Worker)
  34    4 1388 05198440     21220 Preemptive  00000000:00000000 050d8b18 0     Ukn
```

### Iterate through execution contexts assigned to threads ###

When debugging locks in code that is using tasks it is often necessary to examine execution contexts assigned to the running threads. I prepared a simple script which lists threads with their execution contexts. You only need (as in previous script) find the MT of the `Thread` class in your appdomain, eg.

```
0:036> !Name2EE mscorlib.dll System.Threading.Thread
Module:      72551000
Assembly:    mscorlib.dll
Token:       020001d1
MethodTable: 72954960
EEClass:     725bc0c4
Name:        System.Threading.Thread
```

And then paste it in the scripts below:

```
x86:

.foreach ($addr {!DumpHeap -short -mt <METHODTABLE> }) { .printf /D "Thread: %i; Execution context: <link cmd=\"!do %p\">%p</link>\n", poi(${$addr}+28), poi(${$addr}+8), poi(${$addr}+8) }

x64:

.foreach ($addr {!DumpHeap -short -mt <METHODTABLE> }) { .printf /D "Thread: %i; Execution context: <link cmd=\"!do %p\">%p</link>\n", poi(${$addr}+4c), poi(${$addr}+10), poi(${$addr}+10) }
```

Notice that the thread number from the output is a managed thread id and to map it to the windbg thread number you need to use the `!Threads` command.

### List locks ###

You may examine thin locks using **!DumpHeap -thinlocks**.  To find all hard locks (the ones that were created after the object header was full) use **!SyncBlk -all** command.

Using ConcurrencyVisualizer (ETW traces)
----------------------------------------

Under the ANALYZE menu in Visual Studio there is a great tool to observe concurrency execution of .NET applications. It allows you to monitor what each thread of the application was doing during a given period of time. By zooming to a particular point in time you may even examine a stack of a waiting thread.

Concurrency Visualizer under the hood uses ETW infrastructure and generates 2 .etl files: user.etl and kernel.etl. You can then merge them:

    xperf -merge user.etl kernel.etl merged.etl

and load the merged.etl file into WPR or XPerfView.

### Command line ###

Launch application:

    PS temp> & 'C:\Program Files (x86)\Microsoft Concurrency Visualizer Collection Tools\CvCollectionCmd.exe' /Launch c:\temp\AsyncGrep1.exe /LaunchArgs c:\temp

Query status:

    PS temp> & 'C:\Program Files (x86)\Microsoft Concurrency Visualizer Collection Tools\CvCollectionCmd.exe' /Query
    Microsoft (R) Concurrency Visualizer Collection Tool Version 12.0.21005.1
    Copyright (C) Microsoft Corp. All rights reserved.

    Not collecting, ready to start.

You may as well attach and detach to the currently running process.

Links
-----

- [Diagnosing a Windows Service timeout with PerfView](https://lowleveldesign.wordpress.com/2015/09/01/diagnosing-windows-service-timeout-with-perfview/)
- [Two More Ways for Diagnosing For Which Synchronization Object Your Thread Is Waiting](http://blogs.microsoft.co.il/blogs/sasha/archive/2013/04/24/two-more-ways-for-diagnosing-for-which-synchronization-object-your-thread-is-waiting.aspx?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+sashag+%28All+Your+Base+Are+Belong+To+Us%29)
- [Interesting problem to diagnose (wait on a context thread)](http://blog.stephencleary.com/2012/07/dont-block-on-async-code.html?m=1)
- [A case of a deadlock in a .NET application](https://lowleveldesign.wordpress.com/2015/04/30/a-case-of-a-deadlock-in-a-net-application/)
- [The C# Memory Model in Theory and Practice](http://msdn.microsoft.com/en-us/magazine/jj863136.aspx)
