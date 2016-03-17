
Profiling MS SQL Server
=======================

Try the following steps to start investigating general issues with SQL Server.

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

SQLDiag
-------

A tool to collect traces from SQL Server. You may configure what you would like to gather using <http://diagmanager.codeplex.com/>.

Tools
-----

- [SQLPSX - powershell modules for SQL Server](http://sqlpsx.codeplex.com/)
- [Express profiler - a standalone, basic SQL Server profiler](https://expressprofiler.codeplex.com/)
- [A tool for SQL Server query stress-testing](http://www.datamanipulation.net/sqlquerystress/)

Links
-----

- [Great article on how to build a SQL Server monitoring solution can be found here (It lists all the places where you can look for interesting diagnosing information)](https://www.simple-talk.com/sql/database-administration/eight-steps-to-effective-sql-server-monitoring/)
- [Using sys.dm\_os\_performance\_counters to measure Transactions Per Second](http://www.sqlservercurry.com/2012/02/using-sysdmosperformancecounters-to.html)
- [The SQL Server Instance That Will not Start](http://www.simple-talk.com/sql/backup-and-recovery/the-sql-server-instance-that-will-not-start/)
- [SQL Server Services fail to start - FAIL\_PAGE\_ALLOCATION](http://blogs.lessthandot.com/index.php/DataMgmt/DBAdmin/sql-server-services-fail-to)
- [SQL Server Performance Survival Guide](http://social.technet.microsoft.com/wiki/contents/articles/5957.sql-server-performance-survival-guide.aspx)
- [Troubleshooting SQL Server CPU Performance Issues](http://www.sqlperformance.com/2013/05/io-subsystem/cpu-troubleshooting?utm_source=feedly)
- [The Accidental DBA series](site:www.sqlskills.com intitle:the accidental dba)
- Microsoft® SQL Server 2012 Best Practices Analyzer
  <http://www.microsoft.com/download/en/details.aspx?id=29302>
  <http://blogs.msdn.com/b/sqlsecurity/archive/2012/04/19/sql-server-2012-best-practices-analyzer.aspx>
- [SQL Diagnostics Project Part 1 – Configuring Custom SQL Data Collections](http://blogs.msdn.com/b/sql_pfe_blog/archive/2013/11/21/sql-performance-diagnostics-part-1-configuring-custom-sql-data-collections.aspx)
- [SQL Server Diagnostic Information Queries by Glenn Berry](https://sqlserverperformance.wordpress.com/)
