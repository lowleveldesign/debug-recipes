
CLR Memory
=========

Configuring the Garbage Collector
---------------------------------

### Registry ###

Based on <http://blogs.msdn.com/b/sudeepg/archive/2009/02/26/catching-a-memory-dump-on-system-outofmemoryexception.aspx> and advanced .net debugging (<http://www.informit.com/articles/article.aspx?p=1409801&seqNum=5>). To configure how GC handles `OutOfMemoryException` you can use the registry key: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\GCBreakOnOOM` of type `DWORD`. Possible values are:

- 1 - event log message is logged
- 2 - OOM causes a break in the debugger
- 4 - a more extensive event log is written that includes memory statistics at the point where the out of memory was encountered.

Memory Model
-----------

Based on <http://msdn.microsoft.com/en-us/magazine/jj863136.aspx>

According to the ECMA specification, when a thread reads a memory location in C# that was written to by a different thread, the reader might see a stale value.

    public class DataInit {
      private int _data = 0;
      private bool _initialized = false;
      void Init() {
        _data = 42;            // Write 1
        _initialized = true;   // Write 2
      }
      void Print() {
        if (_initialized)            // Read 1
          Console.WriteLine(_data);  // Read 2
        else
          Console.WriteLine("Not initialized");
      }
    }

Suppose Init and Print are called in parallel (that is, on different threads) on a new instance of DataInit. If you examine the code of Init and Print, it may seem that Print can only output 42 or `Not initialized.` However, Print can also output 0. **The C# memory model permits reordering of memory operations in a method, as long as the behavior of single-threaded execution doesn’t change.** For example, the compiler and the processor are free to reorder the Init method operations as follows:

    void Init() {
      _initialized = true;   // Write 2
      _data = 42;            // Write 1
    }

### volatile keyword ###

The C# programming language provides **volatile** fields that constrain how memory operations can be reordered. A read of a volatile field has acquire semantics, which means it can’t be reordered with subsequent operations. The volatile read forms a one-way fence: preceding operations can pass it, but subsequent operations can’t. A write of a volatile field, on the other hand, has release semantics, and so it can’t be reordered with prior operations.

The following example shows how to syncghronize code blocks in a multithreaded application using volatile keyword:

    public class DataInit {
      private int _data = 0;
      private volatile bool _initialized = false;
      void Init() {
        _data = 42;            // Write 1
        _initialized = true;   // Write 2
      }
      void Print() {
        if (_initialized) {          // Read 1
          Console.WriteLine(_data);  // Read 2
        }
        else {
          Console.WriteLine("Not initialized");
        }
      }
    }

Object pinning
-------------

GCHandle holds pointer to the object on the Garbage Collector heap.


Garbage Collector
----------------

Sample project that implements CLR Host with non-paged memory model is available here: <http://nonpagedclrhost.codeplex.com/>

There was a major change in inner-working of the GC in .NET 4.5. New Backgroud GC threads were introduced that collect information about disposed object in Gen2 asynchronously and block other threads for much shorter periods than previously.

### Workstation and server garbage collection ###

After: <http://msdn.microsoft.com/library/ee787088(v=vs.110).aspx#background_server_garbage_collection>

The following are threading and performance considerations for **workstation garbage collection**:

- The collection occurs on the user thread that triggered the garbage collection and remains at the same priority. Because user threads typically run at normal priority, the garbage collector (which runs on a normal priority thread) must compete with other threads for CPU time.  Threads that are running native code are not suspended.
- Workstation garbage collection is always used on a computer that has only one processor, regardless of the <gcServer> setting. If you specify server garbage collection, the CLR uses workstation garbage collection with concurrency disabled.

![workstation gc](gc-workstation.png)

The following are threading and performance considerations for **server garbage collection**:

- The collection occurs on multiple dedicated threads that are running at THREAD\_PRIORITY\_HIGHEST priority level.
- A heap and a dedicated thread to perform garbage collection are provided for each CPU, and the heaps are collected at the same time. Each heap contains a small object heap and a large object heap, and all heaps can be accessed by user code. Objects on different heaps can refer to each other.
- Because multiple garbage collection threads work together, server garbage collection is faster than workstation garbage collection on the same size heap.
- Server garbage collection often has larger size segments.
- Server garbage collection can be resource-intensive. For example, if you have 12 processes running on a computer that has 4 processors, there will be 48 dedicated garbage collection threads if they are all using server garbage collection. In a high memory load situation, if all the processes start doing garbage collection, the garbage collector will have 48 threads to schedule.

If you are running hundreds of instances of an application, consider using workstation garbage collection with concurrent garbage collection disabled. This will result in less context switching, which can improve performance.

![server gc](gc-server.png)

### Concurrent garbage collection ###

Concurrent garbage collection is performed on a dedicated thread and it suspends threads for much shorter periods of time:

![concurrent gc](gc-concurrent.png)

With .NET4.5 it was replaced by background garbage collection.

### Background workstation garbage collection ###

There is no setting for it - it is automatically enabled with concurrent GC. Background garbage collection removes allocation restrictions imposed by concurrent garbage collection, because ephemeral garbage collections can occur during background garbage collection. This means that background garbage collection can remove dead objects in ephemeral generations and can also expand the heap if needed during a generation 1 garbage collection.

![background workstation gc](gc-background-workstation.png)

### Background server garbage collection ###

Background workstation garbage collection uses one dedicated background garbage collection thread, whereas background server garbage collection uses multiple threads, typically a dedicated thread for each logical processor. Unlike the workstation background garbage collection thread, these threads do not time out.

![background server gc](gc-background-server.png)

Tracing Garbage Collector
-------------------------

Based on <http://geekswithblogs.net/akraus1/archive/2014/02/17/155442.aspx>

CLR ETW provider gives us a way to trace GC (and not only) activities. The most interesting keywords are:

    logman query providers ".NET Common Language Runtime"

    Keyword (Hex)	Name	Description
    0x0000000000000001	GCKeyword	GC
    0x0000000000000004 	FusionKeyword
    Binder (Log assembly loading attempts from various locations)
    0x0000000000000008 	LoaderKeyword       	Loader (Assembly Load events)
    0x0000000000008000     	ExceptionKeyword	Exception

ParfView is auomatically using this provides as well as the NT Kernel Trace, but you may also collect those events manually using gcEvents.cmd script. You may also use WPA to examine GC regions (start/stop events) - there is a gcRegions.xml file that load an adequate profile into WPA.

Tools
-----
- Some tools found on [https://skydrive.live.com/?cid=2b879b9ac7a9e117&sc=documents&id=2B879B9AC7A9E117%21466](https://skydrive.live.com/?cid=2b879b9ac7a9e117&sc=documents&id=2B879B9AC7A9E117%21466)
- WMemoryProfiler
  <https://wmemoryprofiler.codeplex.com/>

Links
-----

- [.NET Memory Basics](http://www.simple-talk.com/dotnet/.net-framework/.net-memory-management-basics/)
- [The C# Memory Model in Theory and Practice](http://msdn.microsoft.com/en-us/magazine/jj863136.aspx)
- [Defrag Tools: #33 - CLR GC - Part 1](http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-33-CLR-GC-Part-1)
- [Defrag Tools: #34 - CLR GC - Part 2](http://channel9.msdn.com/Shows/Defrag-Tools/Defrag-Tools-34-CLR-GC-Part-2)
- [Large Obect Heap compaction - should I use it?](https://www.simple-talk.com/dotnet/.net-framework/large-object-heap-compaction-should-you-use-it/)
- [Does Garbage Collection Hurt?](http://geekswithblogs.net/akraus1/archive/2014/02/17/155442.aspx) - PerfView usage to examine GC activities
- [Identify And Prevent Memory Leaks In Managed Code](http://msdn.microsoft.com/en-us/magazine/cc163491.aspx)
- [Garbage Collection: Automatic Memory Management in the Microsoft .NET Framework](http://msdn.microsoft.com/en-us/magazine/bb985010.aspx)
  [Garbage Collection Part 2: Automatic Memory Management in the Microsoft .NET Framework](http://msdn.microsoft.com/en-us/magazine/bb985011.aspx)
- [GC ETW events](http://blogs.msdn.com/b/maoni/archive/2014/12/22/gc-etw-events.aspx)
- [GC ETW events - 2](http://blogs.msdn.com/b/maoni/archive/2014/12/25/gc-etw-events-2.aspx)
- [GC ETW Events - 3](http://blogs.msdn.com/b/maoni/archive/2014/12/25/gc-etw-events-3.aspx)
- [GC ETW Events - 4](http://blogs.msdn.com/b/maoni/archive/2014/12/30/gc-etw-events-4.aspx)
- [Measure GC Allocations and Collections using TraceEvent](http://naveensrinivasan.com/2015/05/11/measure-gc-allocations-and-collections-using-traceevent/)

### Troubleshooting ###

- [ProfBugging - How to find leaks with allocation profiling](http://geekswithblogs.net/akraus1/archive/2015/03/22/161982.aspx)
- [Memory Leak Detection in .NET](http://www.codeproject.com/KB/dotnet/Memory_Leak_Detection.aspx)
- [Tracking down managed memory leaks (how to find a GC leak)](http://blogs.msdn.com/b/ricom/archive/2004/12/10/279612.aspx)
- [Best Practices No 5: - Detecting .NET application memory leaks](http://www.dotnetspark.com/kb/878-best-practices-no-5---detecting-net-application.aspx)
  [Best Practice No: 1:- Detecting High Memory consuming functions in .NET code](http://www.dotnetspark.com/kb/772-net-best-practice-no-1--detecting-high-memory.aspx)
- [How to detect and avoid memory and resources leaks in .NET applications](http://madgeek.com/Articles/Leaks/Leaks.en.html)
- [Best Practices No. 5: Detecting .NET application memory leaks](http://www.codeproject.com/Articles/42721/Best-Practices-No-5-Detecting-NET-application-memo)
- [Intro to Debugging a Memory Dump](http://blogs.msdn.com/b/psssql/archive/2012/03/15/intro-to-debugging-a-memory-dump.aspx)
- [LeakShell or how to (almost) automatically find managed leaks](http://codenasarre.wordpress.com/2011/05/18/leakshell-or-how-to-automatically-find-managed-leaks/)
- [Investigating Memory Issues](http://msdn.microsoft.com/en-us/magazine/cc163528.aspx)
- [Make WPA Simple - Garbage Collection and JIT Times](http://geekswithblogs.net/akraus1/archive/2015/08/16/166270.aspx)
