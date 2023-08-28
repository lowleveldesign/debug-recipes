
Debug Recipes
=============

It is a repository of my field notes collected while debugging various .NET application problems on Windows (mainly) and Linux. They do not contain much theory but rather describe tools and scripts with some usage examples.

**The :floppy_disk: icon before a section name means that materials in a given section are no longer updated and may be outdated.**

I hope you will find the materials helpful. Any contribution is welcome.

:point_right: I also authored the **[.NET Diagnostics Expert](https://diagnosticsexpert.com/?utm_source=debugrecipes&utm_medium=banner&utm_campaign=general) course**, available at  Dotnetos :hot_pepper: Academy. Apart from the theory, it contains lots of demos and troubleshooting guidelines. Check it out if you're interested in learning .NET troubleshooting. 👈

## General advice

I prepared a short guide on configuring Windows for effective troubleshooting, so please [check it out](https://wtrace.net/guides/configuring-windows-for-effective-troubleshooting/). If you are debugging a .NET application you may also [check the .NET debugging tips](clr-debugging-tips.md).

## Tools & techniques

- [WinDbg](debugging-using-windbg/windbg-field-notes.md)
- [LLDB](debugging-using-lldb/lldb-field-notes.md)
- [PowerShell](powershell/powershell-recipes.md)
- :floppy_disk: [Visual Studio debugger](debugging-using-vs/README.md)

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

- [Diagnosing ASP.NET Core](asp.net-core/asp.net-core-troubleshooting.md)
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
