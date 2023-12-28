---
layout: page
title: Windows performance counters - field notes
---

WIP

**Table of contents:**

<!-- MarkdownTOC -->

- [General information](#general-information)
- [Listing performance counters](#listing-performance-counters)
    - [Using powershell](#using-powershell)
    - [Using typeperf](#using-typeperf)
    - [Using lodctr /q](#using-lodctr-q)
- [Collecting performance data](#collecting-performance-data)
    - [Using powershell \(Get-Counter and Export-Counter\)](#using-powershell-get-counter-and-export-counter)
    - [Using typeperf](#using-typeperf_1)
    - [Using perfmon](#using-perfmon)
- [Examining performance data](#examining-performance-data)
    - [Show performance data in perfmon](#show-performance-data-in-perfmon)
    - [Analyze performance data using relog and logparser](#analyze-performance-data-using-relog-and-logparser)
    - [Save performance data in SQL Server](#save-performance-data-in-sql-server)
    - [Import / export performance data](#import-export-performance-data)
- [Fix problems with performance counters](#fix-problems-with-performance-counters)
    - [Corrupted counters](#corrupted-counters)
- [Performance counter configuration](#performance-counter-configuration)
    - [HKLM\SYSTEM\CurrentControlSet\Services\appname\Performance](#hklmsystemcurrentcontrolsetservicesappnameperformance)
    - [HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib](#hklmsoftwaremicrosoftwindows-ntcurrentversionperflib)

<!-- /MarkdownTOC -->

## General information

The performance counter selection uses following syntax: `\\Computer\PerfObject(ParentInstance/ObjectInstance#InstanceIndex)\Counter`.

In order to match the process instance index with a PID you may use a special counter `\Process(*)\ID Process`. Similar counter exists for the .net provider. If we want to track performance data for a particular process we should start with collecting data from those two counters:

    typeperf -c "\Process(*)\ID Process" -si 1 -sc 1 -f CSV -o pids.txt
    typeperf -c "\.NET CLR Memory(*)\Process ID" -si 1 -sc 1 -f CSV -o clr-pids.txt

## Listing performance counters

### Using powershell

List performance counters for a `processor` set:

    PS > get-counter -listset processor

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

or just show the possible paths:

    PS > (get-counter -listset processor).Paths

    \Processor(*)\% Processor Time
    \Processor(*)\% User Time
    \Processor(*)\% Privileged Time
    \Processor(*)\Interrupts/sec
    \Processor(*)\% DPC Time
    \Processor(*)\% Interrupt Time
    \Processor(*)\DPCs Queued/sec
    \Processor(*)\DPC Rate
    \Processor(*)\% Idle Time
    \Processor(*)\% C1 Time
    \Processor(*)\% C2 Time
    \Processor(*)\% C3 Time
    \Processor(*)\C1 Transitions/sec
    \Processor(*)\C2 Transitions/sec
    \Processor(*)\C3 Transitions/sec

This command accepts also **wildcards** and is case insensitive so to list performance counter sets which starts with `.net` you may issue command:

    get-counter -listset .net*

### Using typeperf

Find **all performance counters for the `.NET CLR Memory` object**:

    PS > typeperf -q ".NET CLR Memory"
    \.NET CLR Memory(*)\# Gen 0 Collections
    \.NET CLR Memory(*)\# Gen 1 Collections
    \.NET CLR Memory(*)\# Gen 2 Collections
    \.NET CLR Memory(*)\Promoted Memory from Gen 0
    \.NET CLR Memory(*)\Promoted Memory from Gen 1
    \.NET CLR Memory(*)\Gen 0 Promoted Bytes/Sec
    \.NET CLR Memory(*)\Gen 1 Promoted Bytes/Sec
    \.NET CLR Memory(*)\Promoted Finalization-Memory from Gen 0
    \.NET CLR Memory(*)\Process ID
    \.NET CLR Memory(*)\Gen 0 heap size
    \.NET CLR Memory(*)\Gen 1 heap size
    \.NET CLR Memory(*)\Gen 2 heap size
    \.NET CLR Memory(*)\Large Object Heap size
    \.NET CLR Memory(*)\Finalization Survivors
    \.NET CLR Memory(*)\# GC Handles
    \.NET CLR Memory(*)\Allocated Bytes/sec
    \.NET CLR Memory(*)\# Induced GC
    \.NET CLR Memory(*)\% Time in GC
    \.NET CLR Memory(*)\# Bytes in all Heaps
    \.NET CLR Memory(*)\# Total committed Bytes
    \.NET CLR Memory(*)\# Total reserved Bytes
    \.NET CLR Memory(*)\# of Pinned Objects
    \.NET CLR Memory(*)\# of Sink Blocks in use

List **all performance counters with instance information for the `.NET CLR Memory` object**:

    PS > typeperf -qx ".NET CLR Memory"
    \.NET CLR Memory(_Global_)\# Gen 0 Collections
    \.NET CLR Memory(powershell)\# Gen 0 Collections
    \.NET CLR Memory(powershell#1)\# Gen 0 Collections
    \.NET CLR Memory(_Global_)\# Gen 1 Collections
    \.NET CLR Memory(powershell)\# Gen 1 Collections
    \.NET CLR Memory(powershell#1)\# Gen 1 Collections
    ...
    \.NET CLR Memory(_Global_)\# of Pinned Objects
    \.NET CLR Memory(powershell)\# of Pinned Objects
    \.NET CLR Memory(powershell#1)\# of Pinned Objects
    \.NET CLR Memory(_Global_)\# of Sink Blocks in use
    \.NET CLR Memory(powershell)\# of Sink Blocks in use
    \.NET CLR Memory(powershell#1)\# of Sink Blocks in use

Find all performance counters with .NET in their names:

    typeperf -q | findstr /i "\.net"

    \.NET CLR Networking(*)\Connections Established
    \.NET CLR Networking(*)\Bytes Received
    \.NET CLR Networking(*)\Bytes Sent
    \.NET CLR Networking(*)\Datagrams Received
    \.NET CLR Networking(*)\Datagrams Sent
    \.NET CLR Networking 4.0.0.0(*)\Connections Established
    \.NET CLR Networking 4.0.0.0(*)\Bytes Received
    \.NET CLR Networking 4.0.0.0(*)\Bytes Sent
    \.NET CLR Networking 4.0.0.0(*)\Datagrams Received
    \.NET CLR Networking 4.0.0.0(*)\Datagrams Sent
    \.NET CLR Networking 4.0.0.0(*)\HttpWebRequests Created/Sec
    \.NET CLR Networking 4.0.0.0(*)\HttpWebRequests Average Lifetime
    \.NET CLR Networking 4.0.0.0(*)\HttpWebRequests Queued/Sec
    \.NET CLR Networking 4.0.0.0(*)\HttpWebRequests Average Queue Time
    \.NET CLR Networking 4.0.0.0(*)\HttpWebRequests Aborted/Sec
    \.NET CLR Networking 4.0.0.0(*)\HttpWebRequests Failed/Sec
    ...
    \ASP.NET Apps v2.0.50727(*)\Request Execution Time
    \ASP.NET Apps v2.0.50727(*)\Requests Disconnected
    \ASP.NET Apps v2.0.50727(*)\Requests Rejected
    \ASP.NET Apps v2.0.50727(*)\Request Wait Time
    \ASP.NET Apps v2.0.50727(*)\Cache % Machine Memory Limit Used
    \ASP.NET Apps v2.0.50727(*)\Cache % Process Memory Limit Used
    \ASP.NET Apps v2.0.50727(*)\Cache Total Trims
    \ASP.NET Apps v2.0.50727(*)\Cache API Trims
    \ASP.NET Apps v2.0.50727(*)\Output Cache Trims
    \ASP.NET State Service\State Server Sessions Active
    \ASP.NET State Service\State Server Sessions Abandoned
    \ASP.NET State Service\State Server Sessions Timed Out
    \ASP.NET State Service\State Server Sessions Total
    \.NET CLR Data(*)\SqlClient: Current # pooled and nonpooled connections
    \.NET CLR Data(*)\SqlClient: Current # pooled connections
    \.NET CLR Data(*)\SqlClient: Current # connection pools
    \.NET CLR Data(*)\SqlClient: Peak # pooled connections
    \.NET CLR Data(*)\SqlClient: Total # failed connects
    \.NET CLR Data(*)\SqlClient: Total # failed commands

### Using lodctr /q

Query performance counters data saved in the registry for the `.NET CLR Data` service:

    >lodctr /q:".NET CLR Data"
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

## Collecting performance data

### Using powershell (Get-Counter and Export-Counter)

List counters (with instances) in the `process` counter set and save them to the counters.txt file:

    > (get-counter -listset process).PathsWithInstances > counters.txt

Collect performance data provided by the counters defined in the `counters.txt` file:

    > New-Item -type file counters.txt
    > notepad counters.txt

    (add performance counters here), eg.
    \.NET CLR Exceptions(*)\# of Exceps Thrown
    \.NET CLR Exceptions(*)\# of Exceps Thrown / sec
    \.NET CLR Exceptions(*)\# of Filters / sec
    \.NET CLR Exceptions(*)\# of Finallys / sec
    \.NET CLR Exceptions(*)\Throw To Catch Depth / sec

Collect 50 samples with interval 1s and save them to the binary file (overwrite the output file if alread exists):

    > Get-Counter (gc .\counters.txt) -sampleinterval 1 -maxsamples 20 | export-counter testdata.blg -FileFormat BLG  -Force

Collect samples with interval 2s until ctrl-c is pressed:

    > Get-Counter (gc .\counters.txt) -sampleinterval 2 -continuous /

### Using typeperf

List counters in the `memory` counter set (if x added the command will show also information about instances):

    > typeperf -q[x] memory

To collect 20 samples (-sc) from the process counter with interval 1s (-si) use the following command:

    > typeperf -c "\process(*)\% Processor Time" -si 1 -sc 20 -o testdata.blg -f BIN

Collect 20 samples with interval 1s and save them to the `testdata.blg` file (using BINARY format):

    typeperf -cf .\counters.txt -si 1 -o testdata.blg -f BIN -sc 20

Collect total CPU:

    typeperf "\Processor Information(_Total)\% Processor Time" -si 1 -sc 20

### Using perfmon

Normally you would add counters to the Performance Counter view. The dialogs allow you to filter in which counters you are interested.

Additionally you may fire actions (from the task scheduler) when a specific counter threshold is met. You just need to manually create an User-Created Data Collector of type `Performance Counter Alert`. You will then be able select which counter values are interesting for you.

## Examining performance data

### Show performance data in perfmon

To open the binary performance counter data in perfmon use the command:

    > perfmon /sys /open "c:\temp\testdata.blg"

REMARK: Remember to specify full path to the file in the `/open` switch.

### Analyze performance data using relog and logparser

To list the performance counters which data was collected in the input file run the following command:

    > relog -q testdata.blg

logparser does not understand the BLG format so before we can look into the data we need to convert the BLG file to CSV format:

    > relog -f CSV testdata.blg -o testdata.csv

Additionally we may filter the counters collected (look at the relog syntax). Finally we can use logparser to parse the data:

    > logparser "select * from testdata.csv" -o:DATAGRID

    > logparser "select top 2 [Event Name], Type, [User Data] into c:\temp\test.csv from dumpfile.csv"

To draw a chart presenting the performance counters data use the following syntax:

    > logparser "select [time], [\\pecet\process(system)\% user time],[\\pecet\process(_total)\% user time] into test.gif from testdata.csv" -o:CHART

    > logparser "select to_timestamp(time, 'MM/dd/yyyy HH:mm:ss.ll'), [\\pecet\process(system)\% user time],[\\pecet\process(_total)\% user time] into test.gif from testdata.csv" -o:CHART

### Save performance data in SQL Server

You need to create a new Data Source (ODBC) using the SQL Server driver (SQLSRV32.dll).

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

More information:

- Relog Syntax Examples (for SQL Server)
  <http://www.resquel.com/ssb/2009/02/26/RelogSyntaxExamplesForSQLServer.aspx>
- SQL Log File Schema
  <http://msdn.microsoft.com/en-us/library/aa373198(v=vs.85).aspx>

### Import / export performance data

`Import-Counter` reads performance data generated by any performance counter tool and converts it to the performance data objects (the same as generated by the `Get-Counter` command).

Collect performance counter binary data and convert it using the `Import-Counter` command::

    > typeperf -cf .\counters.txt -si 1 -o testdata.blg -f BIN -sc 20
    > Import-Counter .\testdata.blg

Show statistics for the performance data file:

    PS C:\temp> Import-Counter .\testdata.blg -summary

    OldestRecord                   NewestRecord                   SampleCount
    ------------                   ------------                   -----------
    2012-03-31 15:54:27            2012-03-31 15:54:46            20

`Export-counter` cmdlet exports performance counter data (PerformanceCounterSampleSet objects) as counter log files.

Collect the performance data objects and save them to the binary file (overwrite the output file if alread exists):

    > Get-Counter (gc .\counters.txt) -sampleinterval 1 -maxsamples 20 | export-counter testdata.blg -FileFormat BLG  -Force

## Fix problems with performance counters

### Corrupted counters ###

Performance counters sometimes might become corrupted - in such a case try to locate last performance counter data backup in `C:\Windows\System32` folder. It should have a name similar to **PerfStringBackup.ini**. Before making any changes make backup of your current perf counters:

    lodctr /S:PerfStringBackup_broken.ini

and then restore the counters:

    lodctr /R:PerfStringBackup.ini

## Performance counter configuration

### HKLM\SYSTEM\CurrentControlSet\Services\appname\Performance

An application that supports performance counters must have a Performance key under the Services key. The following example shows the values that you must include for this key.

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

### HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib

The performance counter names and descriptions are stored in the following location in the registry.

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
