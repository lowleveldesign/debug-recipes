
Profiling ASP.NET
=================

## Application instrumentation ##

Interesting tools and libraries:

- [ASP.NET 4.5 page instrumentation mechanism - PageExecutionListener](http://weblogs.asp.net/imranbaloch/archive/2013/11/23/page-instrumentation-in-asp-net-4-5.aspx)
- [Glimpse](http://getglimpse.com/)
- [MiniProfiler](http://miniprofiler.com/)
- [Elmah](http://elmah.github.io/)
- [Route Debugger](https://www.nuget.org/packages/routedebugger)

## ASP.NET ETW providers ##

ASP.NET ETW providers are defined in the aspnet.mof file in the main .NET Framework folder. They should be installed with the framework:

```
> logman query /providers "ASP.NET Events"

Provider                                 GUID
-------------------------------------------------------------------------------
ASP.NET Events                           {AFF081FE-0247-4275-9C4E-021F3DC1DA35}

Value               Keyword              Description
-------------------------------------------------------------------------------
0x0000000000000001  Infrastructure       Infrastructure Events
0x0000000000000002  Module               Pipeline Module Events
0x0000000000000004  Page                 Page Events
0x0000000000000008  AppServices          Application Services Events

Value               Level                Description
-------------------------------------------------------------------------------
0x01                Fatal                Abnormal exit or termination
0x02                Error                Severe errors
0x03                Warning              Warnings
0x04                Information          Information
0x05                Verbose              Detailed information
```


If they are not, use mofcomp to install them.

### Collect events using logman ###

To start collecting trace events from the ASP.NET and IIS providers run the following command:

    logman start aspnettrace -pf ctrl-iis-aspnet.guids -ct perf -o aspnet.etl -ets

And stop it with the command:

    logman stop aspnettrace -ets

The **ctrl-iis-aspnet.guids** file is available in the [etw-tracing folder](etw-tracing). You may later load the aspnet.etl file into **perfview** or **wpa** and examine the collected events.

### Collect events using Perfecto tool ###

Perfecto is a tool that creates an ASP.NET data collector in the system and allows you to generate nice reports of requests made to your ASP.NET application. Download it from <http://blogs.msdn.com/b/josere/archive/2010/04/09/taking-a-quick-peek-at-the-performance-of-your-asp-net-app.aspx>, unzip, run setup.cmd. After installing you can either use the **perfmon** to start the report generation:

1. On perfmon, navigate to the "Performance\Data Collector Sets\User Defined\ASPNET Perfecto" node.
2. Click the "Start the Data Collector Set" button on the tool bar.
3. Wait for/or make requests to the server (more than 10 seconds).
4. Click the "Stop the Data Collector Set" button on the tool bar.
5. Click the "View latest report" button on the tool bar or navigate to the last report at "Performance\Reports\User Defined\ASPNET Perfecto"

or **logman**:

    logman.exe start -n "Service\ASPNET Perfecto"

    logman.exe stop -n "Service\ASPNET Perfecto"

Note: The View commands are also available as toolbar buttons.
Sometimes you can see an error like below:

    Error Code: 0xc0000bf8
    Error Message: At least one of the input binary log files contain fewer than two data samples.

This usually happens when you collected data too fast. The performance counters are set by default to collect every 10 seconds. So a fast start/stop sequence may end without enough counter data being collected. Always allow more than 10 seconds between a start and stop commands. Or otherwise delete the performance counters collector or change the sample interval.

Requirements:

1. Windows >= Vista
2. Installed IIS tracing (`dism /online /enable-feature /featurename:IIS-HttpTracing`)

### Collect events using FREB ###

New IIS servers (7.0 up) contain a nice diagnostics functionality called Failed Request Tracing (or **FREB**). You may find a lot of information how to enable it on the [IIS official site](https://www.iis.net/learn/troubleshoot/using-failed-request-tracing/troubleshooting-failed-requests-using-tracing-in-iis) and in my [iis debugging recipe](asp.net/troubleshooting-iis.md).

## Links ##

- [Debugging ASP.NET WebAPI with route debugger](http://blogs.msdn.com/b/webdev/archive/2013/04/04/debugging-asp-net-web-api-with-route-debugger.aspx)
- [Performance Counters for your HttpClient](http://byterot.blogspot.com/2014/09/Performance-Counters-for-your-HttpClient-aspnet-webapi-monitoring-api-rest.html)
- [Building Performance Metrics into ASP.NET MVC Applications](https://www.simple-talk.com/dotnet/performance/building-performance-metrics-into-asp.net-mvc-applications/)
- [ASP.NET Health Monitoring](https://lowleveldesign.wordpress.com/2012/07/11/asp-net-health-monitoring/)
