
Analyzing waits with ETW
========================

Collecting traces
-----------------

In **perfview** you need to select the **Thread Time** checkbox in the collect window.

To collect traces with **xperf** run:

    xperf -on PROC_THREAD+LOADER+PROFILE+INTERRUPT+DPC+DISPATCHER+CSWITCH -stackwalk Profile+CSwitch+ReadyThread
    xperf -stop -d merged.etl

Analyzing traces
----------------

Event Tracing for Windows is probably the best option when we need to analyse the thread waits. In the paragraphs below you can find information

### Using PerfView

You need to select the ThreadTime in the collection dialog. With this setting PerfView will record context switch events as well as the usual stack dumps every 100ms.

When analyzing blocks use any of the **Thread Time** views. It's best to start with the **Call Stack** view, exclude threads which seem not interesting and locate blocks which might be connected with your investigation. Then for each block time narrow the time to its start and try to guess the flow of the commands that fire it (what was executed last on each thread and what might be the cause of the wait).

### Using WPA

You then need to look at the **CPU Usage (Precise)** graph in WPA. It's worth to add stack columns to the graph (NewThreadStack, ReadyThreadStack). Ready thread is the thread that woke the thread that was sleeping.

FIXME

We should start from our hanging thread and found its readying thread. Then check which thread readied this thread and so on. This chain should bring to us to the final thread which might be a system thread performing some I/O operations.

When working with this view it's always worth to have in mind the thread states diagram from MSDN:

![thread states](thread-states.jpg)


FIXME: DPCs

Links
-----

- [Understanding the Thread Time view in PerfView](https://lowleveldesign.wordpress.com/2015/10/01/understanding-the-thread-time-view-in-perfview/)
- [Diagnosing a Windows Service timeout with PerfView](https://lowleveldesign.wordpress.com/2015/09/01/diagnosing-windows-service-timeout-with-perfview/)
- [Two More Ways for Diagnosing For Which Synchronization Object Your Thread Is Waiting](http://blogs.microsoft.co.il/blogs/sasha/archive/2013/04/24/two-more-ways-for-diagnosing-for-which-synchronization-object-your-thread-is-waiting.aspx?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+sashag+%28All+Your+Base+Are+Belong+To+Us%29)
- [Interesting problem to diagnose (wait on a context thread)](http://blog.stephencleary.com/2012/07/dont-block-on-async-code.html?m=1)
- [A case of a deadlock in a .NET application](https://lowleveldesign.wordpress.com/2015/04/30/a-case-of-a-deadlock-in-a-net-application/)
- [The C# Memory Model in Theory and Practice](http://msdn.microsoft.com/en-us/magazine/jj863136.aspx)
