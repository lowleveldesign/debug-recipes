
Debug Recipes
=============

This is a repository of my notes collected while debugging various application problems. You can find here commands with example usages, scripts and other debugging materials. Try using **the project search box** while looking for a particular subject.

I hope you will find the materials useful. Any contribution is welcome.

## General advice

Make sure you have [valid symbols configuration](windows-debugging-configuration.md#environment-variables) in your system. If you are debugging a .NET application you may first [check the .NET debugging tips](clr-debugging-tips.md).

## Troubleshooting

### Native and managed

### Applications

- [Exceptions and Windows errors](exceptions/exceptions.md)
- [Managed memory leaks](memory/managed-memory-leaks.md)
- [High CPU usage](cpu/analyzing-high-cpu-usage.md)
- [Wait analysis (deadlocks)](threading/analyzing-waits.md)
- [Networking problems](network/network-tracing.md)
- [Assembly not found](assemblies/clr-assemblies.md)
- Slow database queries:
  - [using ADO.NET](ado.net/ado.net-debugging.md)
  - [using MySql connector](databases/mysql/mysql.net-connector-usage.md)

### .NET Web Applications

- Slow requests / tracing: [ASP.NET](asp.net/asp.net-profiling.md), [Nancy](nancy/nancy-diagnostics.md)
- Unknown errors: [ASP.NET](asp.net/asp.net-debugging.md)

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

### IIS (Archived)

- [Troubleshooting IIS7+](iis/iis7up.md)
- [Troubleshooting IIS6](iis/iis6.md)
- [Troubleshooting IIS Express](iis/iisexpress.md)

## Tools

- [WinDbg](debugging-using-windbg/windbg-field-notes.md)
- [LLDB](debugging-using-lldb/lldb-field-notes.md)
- [Visual Studio (debugging)](debugging-using-vs/README.md) (Archived)
