
Debug Recipes
=============

This is a repository of my notes collected while debugging various application problems. You can find here commands with example usages, scripts and other debugging materials. Try using **the project search box** while looking for a particular subject.

I hope you will find the materials useful. Any contribution is welcome.

**The :floppy_disk: icon before a section name means that materials in a given section are no longer updated and may be outdated.**

## General advice

Make sure you have [valid symbols configuration](windows-debugging-configuration.md#environment-variables) in your system. If you are debugging a .NET application you may first [check the .NET debugging tips](clr-debugging-tips.md).

## Troubleshooting

### Application execution problems

- [Exceptions and Windows errors](exceptions/exceptions.md)
- [Network connectivity problems](network/network-tracing.md)
- [Managed memory leaks](memory/managed-memory-leaks.md)
- [Monitoring CPU usage (on- and off-CPU time)](cpu/monitoring-cpu-usage.md)
- [(Dead)locks](deadlocks/diagnosing-deadlocks.md)
- [Assembly loading issues](assemblies/clr-assemblies.md)

### Database connectivity

- :floppy_disk: [Debugging ADO.NET](ado.net/ado.net-debugging.md)
- :floppy_disk: [Tracing MySql connector](databases/mysql/mysql.net-connector-usage.md)

### .NET Web Applications

- :floppy_disk: [Profiling ASP.NET](asp.net/asp.net-profiling.md)
- :floppy_disk: [Diagnosing Nancy](nancy/nancy-diagnostics.md)
- :floppy_disk: [Debugging ASP.NET](asp.net/asp.net-debugging.md)

### System

- [Debugging Windows kernel](windows/kernel-debugging.md)

### Databases

|     | MS SQL Server | MySQL |
| --- | --- | --- |
| Slow queries | [X](databases/mssqlserver/mssqlserver-querying.md) | [X](databases/mysql/mysql-querying.md) |
| Blocked requests | [X](databases/mssqlserver/mssqlserver-concurrency.md) | [X](databases/mysql/mysql-concurrency.md) |
| Indexes problems | [X](databases/mssqlserver/mssqlserver-indexes.md) | [X](databases/mysql/mysql-indexes.md) |
| I/O problems | [X](databases/mssqlserver/mssqlserver-troubleshooting-io.md) |  |
| Server problems | [X](databases/mssqlserver/mssqlserver-troubleshooting-server.md) | [X](databases/mysql/mysql-troubleshooting-server.md) |

### IIS

- :floppy_disk: [Troubleshooting IIS7+](iis/iis7up.md)
- :floppy_disk: [Troubleshooting IIS6](iis/iis6.md)
- :floppy_disk: [Troubleshooting IIS Express](iis/iisexpress.md)

## Tools

- [WinDbg](debugging-using-windbg/windbg-field-notes.md)
- [LLDB](debugging-using-lldb/lldb-field-notes.md)
- :floppy_disk: [Visual Studio (debugging)](debugging-using-vs/README.md)
