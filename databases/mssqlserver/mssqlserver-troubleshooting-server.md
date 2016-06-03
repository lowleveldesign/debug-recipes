
Profiling MS SQL Server
=======================

Try the following steps to start investigating general issues with SQL Server.

Check server configuration
--------------------------

### Version

    SELECT SERVERPROPERTY('Edition');
    Express Edition with Advanced Services (64-bit)

    SELECT SERVERPROPERTY('EngineEdition');
    4

3 is Enterprise, 2 is Standard, 4 is Express

    SELECT SERVERPROPERTY('EngineId');
    NULL

You can use the `xp_msver` system procedure to return information on your SQL Server version:

    /*------------------------
    xp_msver
    ------------------------*/
    SQL Server parse and compile time:
       CPU time = 0 ms, elapsed time = 0 ms.
    Index  Name                             Internal_Value Character_Value
    ------ -------------------------------- -------------- ----------------------------------------
    1      ProductName                      NULL           Microsoft SQL Server
    2      ProductVersion                   720896         11.0.2100.60
    3      Language                         1033           English (United States)
    4      Platform                         NULL           NT x64
    5      Comments                         NULL           SQL
    6      CompanyName                      NULL           Microsoft Corporation
    7      FileDescription                  NULL           SQL Server Windows NT - 64 Bit
    8      FileVersion                      NULL           2011.0110.2100.060 ((SQL11_RTM).120210-1
    9      InternalName                     NULL           SQLSERVR
    10     LegalCopyright                   NULL           Microsoft Corp. All rights reserved.
    11     LegalTrademarks                  NULL           Microsoft SQL Server is a registered tra
    12     OriginalFilename                 NULL           SQLSERVR.EXE
    13     PrivateBuild                     NULL           NULL
    14     SpecialBuild                     137625660      NULL
    15     WindowsVersion                   602931718      6.2 (9200)
    16     ProcessorCount                   2              2
    17     ProcessorActiveMask              NULL                          3
    18     ProcessorType                    8664           NULL
    19     PhysicalMemory                   6143           6143 (6441582592)
    20     Product ID                       NULL           NULL

You can also use the `@@version` variable:

    select @@version

    Microsoft SQL Server 2008 R2 (SP1) - 10.50.2500.0 (X64)   Jun 17 2011 00:54:03   Copyright (c) Microsoft Corporation  Express Edition with Advanced Services (64-bit) on Windows NT 6.1 <X64> (Build 7601: Service Pack 1)

### Configuration options

To show all available configuration options use:

    EXEC sp_configure 'show advanced options', 1;
    GO
    RECONFIGURE;
    GO

After a configuration change we need to either call `RECONFIGURE [WITH OVERRRIDE]` or restart the SQL Server. When `is_dynamic` column is set to 1, the variable that takes effect when the RECONFIGURE statement is executed (otherwise server restart is required). Before taking any of the above-mentioned actions the new value appears only in the `value` column (and not yet in the `vlue_in_use_column`).

### Get information about OS

    select * from sys.dm_os_sys_info

    cpu_ticks            ms_ticks             cpu_count   cpu_ticks_in_ms      hyperthread_ratio physical_memory_in_bytes virtual_memory_in_bytes bpool_committed bpool_commit_target bpool_visible stack_size_in_bytes os_quantum           os_error_mode os_priority_class max_workers_count scheduler_count scheduler_total_count deadlock_monitor_serial_number
    -------------------- -------------------- ----------- -------------------- ----------------- ------------------------ ----------------------- --------------- ------------------- ------------- ------------------- -------------------- ------------- ----------------- ----------------- --------------- --------------------- ------------------------------
    29676598751590       2967659856           12          10000                12                51527311360              8796092891136           5767168         5767168             5767168       2093056             40000                5             32                640               12              23                    4898958


MS SQL Server troubleshooting variables
----------------------------------------

After: <http://technet.microsoft.com/en-us/magazine/dd402107.aspx>

Built-In Functions for Monitoring SQL Server Performance and Activity:

- **@@connections** Returns the number of connections or attempted connections `select @@connections as 'Total Login Attempts'`
- **@@cpu_busy** Returns CPU processing time in milliseconds for SQL Server activity `select @@cpu_busy as 'CPU Busy', getdate() as 'Since'`
- **@@idle** Returns SQL Server idle time in milliseconds `select @@idle as 'Idle Time', getdate() as 'Since'`
- **@@io_busy** Returns I/O processing time in milliseconds `select @@io_busy as 'IO Time', getdate() as 'Since' for SQL Server`
- **@@pack_received** Returns the number of input packets read from the network by SQL Server `select @@pack_received as 'Packets Received'`
- **@@pack_sent** Returns the number of output packets written to the network by SQL Server `select @@pack_sent as 'Packets Sent'`
- **@@packet_errors** Returns the number of network packet errors for SQL Server connections `select @@packet_errors as 'Packet Errors'`
- **@@timeticks** Returns the number of microseconds per CPU clock tick `select @@timeticks as 'Clock Ticks'`
- **@@total_errors** Returns the number of disk read/write errors encountered by SQL Server `select @@total_errors as 'Total Errors', getdate() as 'Since'`
- **@@total_read** Returns the number of disk reads by SQL Server `select @@total_read as 'Reads', getdate() as 'Since'`
- **@@total_write** Returns the number of disk writes by SQL Server `select @@total_write as 'Writes', getdate() as 'Since'`
- **fn_virtualfilestats** Returns input/output statistics for data and log files `select * from fn_virtualfilestats(null,null)`

MS SQL SERVER Error Log
-----------------------

### Links ###

- [Analyze SQL Server logs](http://www.karaszi.com/SQLServer/util_analyze_sql_server_logs.asp)
- [SQL Server Performance - The Crib Sheet (list of things to check when measuring SQL Server performance](https://www.simple-talk.com/sql/performance/sql-server-performance-crib-sheet)

Performance counters (PAL)
--------------------------

### Prepare collector template ###

To extract perfmon templates from the PAL - just click `Export to Perfmon template file...` on the threshold tab. Then I replace '<Counter>\` with `<Counter>\\srv-name\` and start collection.

Then you need to import those templates into perfmon and creat user-defined Data Collector Set - run perfmon, new data collector set and then Create new from template. Remember to set a valid domain account in the security settings of the collector.

### Links ###

- PAL <http://pal.codeplex.com/>
- Automation of PAL (Performance Analysis of Logs) Tool for SQL Server Using Powershell
  <http://tracyboggiano.com/archive/2012/03/automation-of-pal-performance-analysis-of-logs-tool-for-sql-server-using-powershell-part-1/>
- Load Perfmon Log Data into SQL Server with PowerShell
  <http://sqlblog.com/blogs/allen_white/archive/2012/03/03/load-perfmon-log-data-into-sql-server-with-powershell.aspx>
- Setup Perfmon with PowerShell and Logman
  <http://sqlblog.com/blogs/allen_white/archive/2012/03/02/setup-perfmon-with-powershell-and-logman.aspx>
- Load Perfmon Log Data into SQL Server with PowerShell
  <http://sqlblog.com/blogs/allen_white/archive/2012/03/03/load-perfmon-log-data-into-sql-server-with-powershell.aspx>
- [5 Monitoring Queries for SQL Server](https://www.simple-talk.com/sql/database-administration/5-monitoring-queries-for-sql-server/)

SQLDiag
-------

A tool to collect traces from SQL Server. You may configure what you would like to gather using <http://diagmanager.codeplex.com/>.

Tools
-----

- [SQLPSX - powershell modules for SQL Server](http://sqlpsx.codeplex.com/)
- [Express profiler - a standalone, basic SQL Server profiler](https://expressprofiler.codeplex.com/)
- [A tool for SQL Server query stress-testing](http://www.datamanipulation.net/sqlquerystress/)

