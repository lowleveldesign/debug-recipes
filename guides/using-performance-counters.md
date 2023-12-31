---
layout: page
title: Using Windows Performance Counters
---

{% raw %}

**Table of contents:**

<!-- MarkdownTOC -->

- [General information](#general-information)
- [Listing Performance Counters installed in the system](#listing-performance-counters-installed-in-the-system)
- [Collecting performance data](#collecting-performance-data)
- [Examining the collected performance data](#examining-the-collected-performance-data)
    - [Using system tools](#using-system-tools)
    - [Using Log Parser](#using-log-parser)
    - [Save performance data in SQL Server](#save-performance-data-in-sql-server)
- [Fix problems with Performance Counters](#fix-problems-with-performance-counters)
    - [Corrupted counters](#corrupted-counters)

<!-- /MarkdownTOC -->

## General information

The Performance Counter selection uses following syntax: `\\Computer\PerfObject(ParentInstance/ObjectInstance#InstanceIndex)\Counter`.

In order to match the process instance index with a PID you may use a special counter `\Process(*)\ID Process`. Similar counter (`\.NET CLR Memory(*)\Process ID`) exists for .NET Framework apps. If we want to track performance data for a particular process, we should start with collecting data from those two counters, for example:

```shell
typeperf -c "\Process(*)\ID Process" -si 1 -sc 1 -f CSV -o pids.txt
typeperf -c "\.NET CLR Memory(*)\Process ID" -si 1 -sc 1 -f CSV -o clr-pids.txt
```

An application that supports Performance Counters must have a **Performance** key under the **HKLM\SYSTEM\CurrentControlSet\Services\appname** key. The following example shows the values that you must include for this key.

    HKEY_LOCAL_MACHINE
       \SYSTEM
          \CurrentControlSet
             \Services
                \application-name
                   \Linkage
                      Export = a REG_MULTI_SZ value that will be passed to the `OpenPerformanceData` function
                   \Performance
                      Library = Name of your performance DLL
                      Open = Name of your Open function in your DLL
                      Collect = Name of your Collect function in your DLL
                      Close = Name of your Close function in your DLL
                      Open Timeout = Timeout when waiting for the `OpenPerformanceData` to finish
                      Collect Timeout = Timeout when waiting for the `CollectPerformanceData` to finish
                      Disable Performance Counters = A value added by system if something is wrong with the library

The Performance Counter names and descriptions are stored under the **HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib** key in the registry.

    HKEY_LOCAL_MACHINE
       \SOFTWARE
          \Microsoft
             \Windows NT
                \CurrentVersion
                   \Perflib
                      Last Counter = highest counter index
                      Last Help = highest help index
                      \009
                         Counters = 2 System 4 Memory...
                         Help = 3 The System Object Type...
                      \supported language, other than English
                         Counters = ...
                         Help = ...

## Listing Performance Counters installed in the system

To list the available Performance Counters we may use the **Get-Counter** cmdlet in **PowerShell** or the **typeperf** command.

For example, below, we look for Performance Counters in the `processor` set:

```
PS> Get-Counter -listset processor

CounterSetName     : Processor
MachineName        : .
CounterSetType     : MultiInstance
Description        : The Processor performance object consists of counters that measure aspects of processor activity.
                     The processor is the part of the computer that performs arithmetic and logical computations, initi
                     ates operations on peripherals, and runs the threads of processes.  A computer can have multiple p
                     rocessors.  The processor object represents each processor as an instance of the object.
Paths              : {\Processor(*)\% Processor Time, \Processor(*)\% User Time, \Processor(*)\% Privileged Time, \Proc
                     essor(*)\Interrupts/sec...}
PathsWithInstances : {\Processor(0)\% Processor Time, \Processor(1)\% Processor Time, \Processor(_Total)\% Processor Ti
                     me, \Processor(0)\% User Time...}
Counter            : {\Processor(*)\% Processor Time, \Processor(*)\% User Time, \Processor(*)\% Privileged Time, \Proc
                     essor(*)\Interrupts/sec...}
```

The Get-Counter cmdlet accepts also **wildcards** and is case insensitive so to list Performance Counter sets which starts with `.net` you may issue command: `Get-Counter -listset .net*`. 

To find all Performance Counters for the `.NET CLR Memory` object using **typeperf**, we could run:

```
> typeperf -q ".NET CLR Memory"
\.NET CLR Memory(*)\# Gen 0 Collections
\.NET CLR Memory(*)\# Gen 1 Collections
...
```

If we also want to include instance information:

```
> typeperf -qx ".NET CLR Memory"
\.NET CLR Memory(_Global_)\# Gen 0 Collections
\.NET CLR Memory(powershell)\# Gen 0 Collections
\.NET CLR Memory(powershell#1)\# Gen 0 Collections
\.NET CLR Memory(_Global_)\# Gen 1 Collections
\.NET CLR Memory(powershell)\# Gen 1 Collections
...
```

Finally, the **lodctr** extracts Performance Counters information from the registry:

```
> lodctr /q:".NET CLR Data"
Performance Counter ID Queries [PERFLIB]:
    Base Index: 0x00000737 (1847)
    Last Counter Text ID: 0x0000435A (17242)
    Last Help Text ID: 0x0000435B (17243)

[.NET CLR Data] Performance Counters (Enabled)
    DLL Name: netfxperf.dll
    Open Procedure: OpenPerformanceData
    Collect Procedure: CollectPerformanceData
    Close Procedure: ClosePerformanceData
    First Counter ID: 0x000013A4 (5028)
    Last Counter ID: 0x000013B0 (5040)
    First Help ID: 0x000013A5 (5029)
    Last Help ID: 0x000013B1 (5041)
```

## Collecting performance data

We could use the same tools we used for querying also to collect Performance Counters data. In **PowerShell**, to collect 50 samples (with 1s interval) from all the process counters and save them to a binary file we could run the following set of commands: 

```shell
(Cet-Counter -listset process).Paths > counters.txt
Get-Counter (gc .\counters.txt) -sampleinterval 1 -maxsamples 20 | Export-Counter testdata.blg -FileFormat BLG  -Force
```

Another example shows how to collect samples with interval 2s until ctrl-c is pressed:

```shell
Get-Counter (gc .\counters.txt) -sampleinterval 2 -continuous /
```

We may achieve the same results with **typeperf**, for example:

```shell
typeperf -cf .\counters.txt -si 1 -o testdata.blg -f BIN -sc 20
typeperf -cf .\counters.txt -si 1
```

Of course, with both PowerShell or typeperf, we may also retrieve only one counter data:

```shell
typeperf -c "\process(*)\% Processor Time" -si 1 -sc 20 -o testdata.blg -f BIN
```

Finally, we have a gui tool, **perfmon** that allows us to pick the interesting counters and present their values in a graph. We may also trigger a scheduled task when a specific counter threshold is met. You just need to manually create a **User-Created Data Collector** of type **Performance Counter Alert**. You will then be able select which counter values are interesting for you.

## Examining the collected performance data

### Using system tools

If we saved the counters data to a binary file, we can open it with **perfmon**:

```shell
perfmon /sys /open "c:\temp\testdata.blg"
```

*REMARK: Remember to specify full path to the binary file.*

A command line tool to query the collected performance data is **relog**. For example, to list the Performance Counters available in the input file, run the following command:

```shell
relog -q testdata.blg
```

In PowerShell, the **Import-Counter** cmdlet reads performance data generated by any Performance Counter tool and converts it to the performance data objects (the same as generated by the **Get-Counter** command).

Collect Performance Counter binary data and convert it using the **Import-Counter** cmdlet:

```shell
typeperf -cf .\counters.txt -si 1 -o testdata.blg -f BIN -sc 20
Import-Counter .\testdata.blg
```

The Import-Counter cmdlet may show statistics for the performance data file, for example:

```
PS C:\temp> Import-Counter .\testdata.blg -summary

OldestRecord                   NewestRecord                   SampleCount
------------                   ------------                   -----------
2012-03-31 15:54:27            2012-03-31 15:54:46            20
```

### Using Log Parser

**[Log Parser Studio](https://techcommunity.microsoft.com/t5/exchange-team-blog/introducing-log-parser-studio/ba-p/601131)** and the command line **[logparser](https://www.microsoft.com/en-in/download/details.aspx?id=24659)** tool (and library) are great data analysing tools and we may use them to query Performance Counters data as well. They do not understand the BLG format so before we can look into the data we need to convert the BLG file to CSV format (additional filtering is possible):

```shell
relog -f CSV testdata.blg -o testdata.csv
```

And we are ready to use logparser to parse the data, for example:

```shell
logparser "select * from testdata.csv" -o:DATAGRID

logparser "select top 2 [Event Name], Type, [User Data] into c:\temp\test.csv from dumpfile.csv"
```

To draw a chart presenting the Performance Counters data use the following syntax:

```shell
logparser "select [time], [\\pecet\process(system)\% user time],[\\pecet\process(_total)\% user time] into test.gif from testdata.csv" -o:CHART

logparser "select to_timestamp(time, 'MM/dd/yyyy HH:mm:ss.ll'), [\\pecet\process(system)\% user time],[\\pecet\process(_total)\% user time] into test.gif from testdata.csv" -o:CHART
```

### Save performance data in SQL Server

To save Performance Counters data in SQL Server, you need to create a new Data Source (ODBC) using the SQL Server driver (SQLSRV32.dll). Then run the relog tool, for example:

```
> relog -f SQL -o SQL:Test!fd .\memperfdata-blog.csv

Input
----------------
File(s):
     .\memperfdata-blog.csv (CSV)

Begin:    2012-4-17 6:44:15
End:      2012-4-17 6:44:25
Samples:  10

100.00%

Output
----------------
File:     SQL:Test!fd

Begin:    2012-4-17 6:44:15
End:      2012-4-17 6:44:25
Samples:  4

The command completed successfully.
```

More information:

- Relog Syntax Examples (for SQL Server)
  <http://www.resquel.com/ssb/2009/02/26/RelogSyntaxExamplesForSQLServer.aspx>
- SQL Log File Schema
  <http://msdn.microsoft.com/en-us/library/aa373198(v=vs.85).aspx>

## Fix problems with Performance Counters

### Corrupted counters

Performance Counters sometimes might become corrupted - in such a case try to locate last Performance Counter data backup in C:\Windows\System32 folder. It should have a name similar to **PerfStringBackup.ini**. Before making any changes make backup of your current perf counters:

```
lodctr /S:PerfStringBackup_broken.ini
```

and then restore the counters:

```
lodctr /R:PerfStringBackup.ini
```

{% endraw %}
