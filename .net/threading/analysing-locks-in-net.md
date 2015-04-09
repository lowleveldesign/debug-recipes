
Analysing locks in .NET applications
====================================

Useful WinDbg commands
----------------------

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

### Iterate through execution context assigned to threads ###

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
