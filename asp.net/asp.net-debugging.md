
Debugging ASP.NET
=================

In the **diag-pages** you may find pages displaying information about the ASP.NET environment. You may copy them to an application folder and verify if the environment is configured accordingly to your specification.

## Examining ASP.NET process memory (and dumps) ##

FIXME describe SOS and netext commands

```
!ProcInfo [-env] [-time] [-mem]

FindDebugTrue

!FindDebugModules [-full]

`!DumpHttpContext` dumps the HttpContexts in the heap.  It shows the status of the request and the return code, etc.  It also prints out the start time

`!ASPXPages` just calls !DumpHttpContext to print out information on the ASPX pages  running on threads.

!DumpASPNETCache [-short] [-stat] [-s]

!DumpRequestTable [-a] [-p] [-i] [-c] [-m] [-q] [-n] [-e] [-w] [-h]                   [-r] [-t] [-x] [-dw] [-dh] [-de] [-dx]

!DumpHistoryTable [-a]
!DumpHistoryTable dumps the aspnet_wp history table.

!DumpBuckets dumps entire request table buckets.

!GetWorkItems given a CLinkListNode, print out request & work items.
```

## Links ##

- [The strange case of the Application Pool recycling causing high CPU](http://blogs.msdn.com/b/rodneyviana/archive/2015/03/12/the-strange-case-of-the-application-pool-recycling-causing-high-cpu.aspx)
- [Debugging ASP.NET WebAPI with route debugger](http://blogs.msdn.com/b/webdev/archive/2013/04/04/debugging-asp-net-web-api-with-route-debugger.aspx)
