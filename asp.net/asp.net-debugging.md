
Debugging ASP.NET
=================

In the **diag-pages** you may find pages displaying information about the ASP.NET environment (MvcDiagnostics.aspx is copied from the [MvcDiagnostics nuget package](https://www.nuget.org/packages/MvcDiagnostics/)). You may copy them to an application folder and verify if the environment is configured accordingly to your specification.

## Examining ASP.NET process memory (and dumps) ##

[PSSCOR4](http://www.microsoft.com/en-us/download/details.aspx?id=21255) commands for ASP.NET:

```
!ProcInfo [-env] [-time] [-mem]

FindDebugTrue

!FindDebugModules [-full]

!DumpHttpContext dumps the HttpContexts in the heap.  It shows the status of the request and the return code, etc.  It also prints out the start time

!ASPXPages just calls !DumpHttpContext to print out information on the ASPX pages  running on threads.

!DumpASPNETCache [-short] [-stat] [-s]

!DumpRequestTable [-a] [-p] [-i] [-c] [-m] [-q] [-n] [-e] [-w] [-h]                   [-r] [-t] [-x] [-dw] [-dh] [-de] [-dx]

!DumpHistoryTable [-a]
!DumpHistoryTable dumps the aspnet_wp history table.

!DumpBuckets dumps entire request table buckets.

!GetWorkItems given a CLinkListNode, print out request & work items.
```

[Netext](http://netext.codeplex.com/) commands for ASP.NET:

```
!whttp [/order] [/running] [/withthread] [/status <decimal>] [/notstatus <decimal>] [/verb <string>] [<expr>] - dump HttpContext objects

!wconfig - dump configuration sections loaded into memory

!wruntime - dump all active Http Runtime information
```

## Links ##

- [The strange case of the Application Pool recycling causing high CPU](http://blogs.msdn.com/b/rodneyviana/archive/2015/03/12/the-strange-case-of-the-application-pool-recycling-causing-high-cpu.aspx)
- [Debugging ASP.NET WebAPI with route debugger](http://blogs.msdn.com/b/webdev/archive/2013/04/04/debugging-asp-net-web-api-with-route-debugger.aspx)
- [Using ASP.Net Module to Debug Async Calls](http://blogs.msdn.com/b/webdev/archive/2015/12/29/using-asp-net-module-to-debug-async-calls.aspx)
