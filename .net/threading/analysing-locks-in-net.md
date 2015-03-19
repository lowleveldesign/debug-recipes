
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
