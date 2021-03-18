
Troubleshooting deadlocks
=========================

In this recipe:

- [Dump collection](#dump-collection)
  - [Procdump](#procdump)
  - [minidumper (.NET Framework)](#minidumper-net-framework)
  - [dotnet-dump (.NET Core)](#dotnet-dump-net-core)
  - [createdump (.NET Core)](#createdump-net-core)
- [Analysis](#analysis)
  - [Show threads call stacks](#show-threads-call-stacks)
  - [List locks in user mode](#list-locks-in-user-mode)
  - [Iterate through execution contexts assigned to threads (managed)](#iterate-through-execution-contexts-assigned-to-threads-managed)
  - [Check locks in kernel mode](#check-locks-in-kernel-mode)

## Dump collection

There are many tools you may use to collect the memory dump. Below I list the ones I use most often.

### Procdump

To create a full memory dump you may use [procdump](https://live.sysinternals.com):

    procdump -ma <process-name-or-id>

### minidumper (.NET Framework)

[Minidumper](https://github.com/goldshtn/minidumper) is a tool from Sasha Goldshtein (with my contribution). It has options very similar to procdump, but may create more compact memory dumps.

To create a full memory dump, run:

    minidumper -ma <process-name-or-id>

To create a managed heap memory dump, run:

    minidumper -mh <process-name-or-id>

### dotnet-dump (.NET Core)

[dotnet-dump](https://docs.microsoft.com/en-us/dotnet/core/diagnostics/dotnet-dump) is one of the .NET diagnostics CLI tools.

You may download it using curl or wget, for example: `curl -JLO https://aka.ms/dotnet-dump/win-x64`.

To create a full memory dump, run one of the commands:

    dotnet-dump collect -p <process-id>
    dotnet-dump collect -n <process-name>

You may create a heap-only memory dump by adding a `--type=Heap` option.

### createdump (.NET Core)

Createdump shares the location with the coreclr library, for example, for .NET 5: `/usr/share/dotnet/shared/Microsoft.NETCore.App/5.0.3/createdump` or `c:\Program Files\dotnet\shared\Microsoft.NETCore.App\5.0.3\createdump.exe`.

To create a full memory dump, run:

    createdump --full <process-id>

With no options provided, it creates a memory dump with heap, which equals to `createdump --withheap <pid>`

## Analysis

We usually start the analysis by looking at the threads running in a process. The call stacks help us identify blocked threads. In the next step, we need to find the lock objects and relations between threads.

### Listing threads call stacks

To list native stacks for all the threads in **WinDbg**, run: `~*k` or `~*e!dumpstack`. If you are interested only in managed stacks, you may use the `~*e!clrstack` SOS command. There is also a great `!pstacks` command from the [gsose extension](https://github.com/chrisnas/DebuggingExtensions) that groups call stacks for managed threads.

```
0:011> .load gsose.dll
0:011> !pstacks
    ~~~~ 5cd8
       1 System.Threading.Monitor.Enter(Object, Boolean ByRef)
       1 deadlock.Program.Lock2()
    ~~~~ 3e58
       1 System.Threading.Monitor.Enter(Object, Boolean ByRef)
       1 deadlock.Program.Lock1()
  2 System.Threading.Tasks.Task.InnerInvoke()
  ...
  2 System.Threading.ThreadPoolWorkQueue.Dispatch()
  2 System.Threading._ThreadPoolWaitCallback.PerformWaitCallback()
```

In **LLDB**, we may show native call stacks for all the threads with the `bt all` command. Unfortunately, if we want to use `dumpstack` or `clrstack` commands, we need to manually switch between threads with the `thread select` command.

### Finding locks in memory dumps

You may examine thin locks using **!DumpHeap -thinlocks**.  To find all sync blocks, use the **!SyncBlk -all** command.

There are many types of objects that the thread can wait on. You usually see many `WaitOnMultipleObjects` on many threads.

If you see RtlWaitForCriticalSection or other method connected with a critical section it might indicate that the program hang. In order to find the cause of this situation you may use following commands:

    !locks shows the contained lock, use ~~[<thread>] to switch to a given thread
    !cs shows all critical sections in the program (dump)
    !timers presents all timers running in system

Use **!cs** comman to examine details of a critical section:

    0:033> !cs -s 000000001a496f50
    -----------------------------------------
    Critical section   = 0x000000001a496f50 (+0x1A496F50)
    DebugInfo          = 0x0000000013c9bee0
    LOCKED
    LockCount          = 0x0
    WaiterWoken        = No
    OwningThread       = 0x0000000000001b04
    RecursionCount     = 0x1
    LockSemaphore      = 0x0
    SpinCount          = 0x00000000020007d0

`LockCount` tells you how many threads are currently waiting on a given cs. The `OwningThread` is a thread that owns the cs at the time the command is run. You can easily identify the thread that is waiting on a given cs by issuing `kv` command and looking for critical section identifier in the call parameters.

On .NET Framework, you may use the **!dlk** command from the SOSEX extension. It is pretty good in detecting dead-locks, example:

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

    x86:

    .foreach ($addr {!DumpHeap -short -mt <METHODTABLE> }) { .printf /D "Thread: %i; Execution context: <link cmd=\"!do %p\">%p</link>\n", poi(${$addr}+28), poi(${$addr}+8), poi(${$addr}+8) }

    x64:

    .foreach ($addr {!DumpHeap -short -mt <METHODTABLE> }) { .printf /D "Thread: %i; Execution context: <link cmd=\"!do %p\">%p</link>\n", poi(${$addr}+4c), poi(${$addr}+10), poi(${$addr}+10) }

Notice that the thread number from the output is a managed thread id and to map it to the windbg thread number you need to use the `!Threads` command.

### Find locks in kernel mode

Another command that can be useful here is **!locks**. With **-v** parameter will display all locks accessed by threads in a process.
