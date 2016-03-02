
Intellitrace
============

Collecting trace data
---------------------

### Using Microsoft Monitoring Agent [RECOMMENDED] ###

Based on: [Introducing Microsoft Monitoring Agent](http://blogs.msdn.com/b/visualstudioalm/archive/2013/09/20/introducing-microsoft-monitoring-agent.aspx)

Download and install Microsoft Monitoring Agent. Then run:

    Start-WebApplicationMonitoring

To produce an intellitrace file run:

    Checkpoint-WebApplicationMonitoring

### Powershell [Obsolete] ###

Intellitrace in Visual Studio 11 can be used as a standalone tool to collect traces on a production server. You can then futher anlyze the generated file and look for problems that may have appeared during the tracing session.

The tool can be downloaded from: <http://www.microsoft.com/download/en/details.aspx?id=29036>

Unpack the .cab file using the `expand.exe` command:

    expand.exe /f:* IntelliTraceCollection.cab IntelliTraceExecutableDirectory

Create and configure a log file directory - granting a full access to the application pool that hosts the application:

    icacls D:\IntelliTraceLogs /grant “IIS APPPOOL\DefaultAppPool”:(F)

Import the IntelliTrace module:

    Import-Module IntelliTraceExecutableDirectory \Microsoft.VisualStudio.IntelliTrace.PowerShell.dll

Start collecting IntelliTrace data:

    Start-IntelliTraceCollection ApplicationPool CollectionPlan OutputPath

where `ApplicationPool` is a pool that you would like to trace, `CollectionPlan` is a path to the .xml file that specifies the colletion plan (there are two default ones in the IntelliTrace directory: `collection_plan.ASP.NET.default.xml - only intellitrace events, `collection_plan.ASP.NET.trace.xml` - function calls + intellitrace events) and `OutputPath` is a path to the log directory that we have just created.

Additionally you may take a snapshot of the current log:

    Checkpoint-IntelliTraceCollection AppPoolName

Finally to stop the trace use:

    Stop-IntelliTraceCollection AppPoolName

### Command line ###

    Intellitrace.exe launch /cp: CollectionPlanXml /f:OutputFile ExecutableFile

Links
-----

- [True Short War Story and Then IntelliTrace - Dev, Test, Production - Capture it Anywhere](http://blogs.msdn.com/b/jasonsingh/archive/2013/02/28/intellitrace-dev-test-production-capture-it-anywhere-replay-in-dev-environment.aspx)
- [Why IntelliTrace and Architecture Tools Are More Important Than Ever For Developers](http://blogs.msdn.com/b/jasonsingh/archive/2013/02/27/why-intellitrace-and-architecture-tools-are-more-important-than-ever.aspx)
- [Learn IntelliTrace - great page with links to Intellitrace resources](http://blogs.msdn.com/b/visualstudioalm/archive/2013/04/22/learn-intellitrace.aspx)
- [Guest Post: IntelliTrace Tips and Tricks: The Basics–Part 1–Colin Dembovsky](http://blogs.msdn.com/b/southafrica/archive/2013/05/13/guest-post-intellitrace-tips-and-tricks-the-basics-part-1-colin-dembovsky.aspx)
- [Performance Details in Intellitrace](http://blogs.msdn.com/b/visualstudioalm/archive/2013/09/20/performance-details-in-intellitrace.aspx)
- <http://msdn.microsoft.com/en-us/library/hh398365(v=vs.110).aspx>
- <http://blogs.msdn.com/b/ianhu/archive/2012/04/05/intellitrace-web-requests.aspx>
- [IntelliTrace MVC Navigation](http://blogs.msdn.com/b/visualstudioalm/archive/2014/02/12/intellitrace-mvc-navigation.aspx)
- [IntelliTrace standalone collector is back!](http://blogs.msdn.com/b/visualstudioalm/archive/2014/08/07/intellitrace-standalone-collector-is-back.aspx)
- [Custom TraceSource and debugging using IntelliTrace](http://blogs.msdn.com/b/visualstudioalm/archive/2014/12/17/custom-tracesource-and-debugging-using-intellitrace.aspx)
